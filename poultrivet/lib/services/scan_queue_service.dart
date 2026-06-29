import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Scan queue — saves scans locally then uploads to Django warehouse when online.
///
/// Flow:
///   After scan     → image copied to cache + entry added to local JSON queue
///   When online    → image + metadata POSTed to Django /api/scans/upload/
///                    scan ID also saved to Firestore for the farmer's history
///   After 15 days  → local image deleted even if never uploaded

class ScanQueueService {
  // ── Change this to your Render URL once deployed ───────────────────────────
  // During local development use your machine's IP e.g. http://192.168.1.x:8000
  static const String _baseUrl = 'https://poulvet-backend.onrender.com';
  static const String _uploadEndpoint = '$_baseUrl/api/scans/upload/';

  static const String _queueFileName = 'scan_queue.json';
  static const int _maxAgeDays = 15;

  // ── Queue file ─────────────────────────────────────────────────────────────
  Future<File> _queueFile() async {
    final dir = await getApplicationCacheDirectory();
    return File('${dir.path}/$_queueFileName');
  }

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final file = await _queueFile();
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final List decoded = jsonDecode(content);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> queue) async {
    final file = await _queueFile();
    await file.writeAsString(jsonEncode(queue));
  }

  // ── Enqueue after inference ────────────────────────────────────────────────
  Future<void> enqueueScan({
    required File imageFile,
    required String label,
    required double confidence,
    String? district,             // pass farmer's district if available
    Map<String, dynamic>? envData, // optional satellite env data
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cacheDir = await getApplicationCacheDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cachedPath = '${cacheDir.path}/scan_$timestamp.jpg';
      await imageFile.copy(cachedPath);

      // Save last scan time — used by RecordsPage 3-day reminder
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_scan_timestamp', timestamp);

      final queue = await _readQueue();
      queue.add({
        'uid':        user.uid,
        'imagePath':  cachedPath,
        'label':      label,
        'confidence': confidence,
        'district':   district ?? '',
        'timestamp':  timestamp,
        'scannedAt':  DateTime.now().toIso8601String(),
        'envData':    envData ?? {},
        'synced':     false,
      });
      await _writeQueue(queue);

      debugPrint('ScanQueue: enqueued $label');
      unawaited(flushQueue());
    } catch (e) {
      debugPrint('ScanQueue enqueue error: $e');
    }
  }

  // ── Upload to Django ───────────────────────────────────────────────────────
  Future<void> flushQueue() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      debugPrint('ScanQueue: offline, skipping flush');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final queue = await _readQueue();
    if (queue.isEmpty) return;

    final List<Map<String, dynamic>> remaining = [];

    for (final entry in queue) {
      final timestamp  = entry['timestamp'] as int;
      final imagePath  = entry['imagePath'] as String;
      final imageFile  = File(imagePath);

      // ── Expired — delete and drop ─────────────────────────────────────────
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
      if (age.inDays >= _maxAgeDays) {
        if (await imageFile.exists()) await imageFile.delete();
        debugPrint('ScanQueue: expired entry purged');
        continue;
      }

      // ── Already synced ────────────────────────────────────────────────────
      if (entry['synced'] == true) {
        if (await imageFile.exists()) await imageFile.delete();
        continue;
      }

      // ── Upload to Django ──────────────────────────────────────────────────
      try {
        final uid      = entry['uid'] as String;
        final envData  = entry['envData'] as Map<String, dynamic>? ?? {};

        final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));

        // Text fields
        request.fields['farmer_uid'] = uid;
        request.fields['label']      = entry['label'] as String;
        request.fields['confidence'] = (entry['confidence'] as num).toString();
        request.fields['district']   = entry['district'] as String? ?? '';
        request.fields['scanned_at'] = entry['scannedAt'] as String;

        // Optional environmental fields
        if (envData['temperature'] != null)
          request.fields['temperature'] = envData['temperature'].toString();
        if (envData['humidity'] != null)
          request.fields['humidity'] = envData['humidity'].toString();
        if (envData['vegetation_ndvi'] != null)
          request.fields['vegetation_ndvi'] = envData['vegetation_ndvi'].toString();
        if (envData['moisture_index'] != null)
          request.fields['moisture_index'] = envData['moisture_index'].toString();
        if (envData['water_presence_pct'] != null)
          request.fields['water_presence_pct'] = envData['water_presence_pct'].toString();

        // Image file
        if (await imageFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            imagePath,
            filename: 'scan_$timestamp.jpg',
          ));
        }

        final streamedResponse = await request.send()
            .timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final scanId = data['id'] as int;

          debugPrint('ScanQueue: uploaded to Django — scan ID $scanId ✓');

          // Also record scan ID in Firestore for the farmer's history
          await FirebaseFirestore.instance
              .collection('scans')
              .doc('${uid}_$timestamp')
              .set({
            'uid':       uid,
            'django_id': scanId,
            'label':     entry['label'],
            'confidence': entry['confidence'],
            'scannedAt': entry['scannedAt'],
            'syncedAt':  DateTime.now().toIso8601String(),
          });

          // Delete local image
          if (await imageFile.exists()) await imageFile.delete();

        } else {
          debugPrint('ScanQueue: Django returned ${response.statusCode} — will retry');
          remaining.add(entry);
        }
      } catch (e) {
        debugPrint('ScanQueue upload error: $e — will retry');
        remaining.add(entry);
      }
    }

    await _writeQueue(remaining);
  }

  // ── Purge expired on app start ─────────────────────────────────────────────
  Future<void> purgeExpired() async {
    final queue = await _readQueue();
    final List<Map<String, dynamic>> valid = [];

    for (final entry in queue) {
      final timestamp = entry['timestamp'] as int;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));

      if (age.inDays >= _maxAgeDays) {
        final file = File(entry['imagePath'] as String);
        if (await file.exists()) await file.delete();
        debugPrint('ScanQueue: purged expired entry');
      } else {
        valid.add(entry);
      }
    }

    await _writeQueue(valid);
  }

  Future<int> pendingCount() async {
    final queue = await _readQueue();
    return queue.where((e) => e['synced'] != true).length;
  }
}
