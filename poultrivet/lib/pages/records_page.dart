import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav.dart';
import 'alerts_page.dart';
import 'home_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  static const Color primary    = Color.fromARGB(255, 19, 97, 39);
  static const Color lightBg    = Color(0xFFf6f8f7);
  static const Color darkText   = Color(0xFF1a1a2e);
  static const Color greyText   = Color(0xFF6b7280);
  static const Color cardColor  = Colors.white;
  static const Color redRisk    = Color(0xFFE74C3C);
  static const Color orangeRisk = Color(0xFFF39C12);

  static const String _lastScanKey   = 'last_scan_timestamp';
  static const String _queueFileName = 'scan_queue.json';

  List<Map<String, dynamic>> _scans = [];
  bool _loading = true;

  int _daysSinceScan = 0;
  DateTime? _lastScanDate;

  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startClock();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _recalcDays();
    });
  }

  void _recalcDays() {
    if (_lastScanDate == null) return;
    setState(() {
      _daysSinceScan =
          DateTime.now().difference(_lastScanDate!).inDays;
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // ── Last scan time from SharedPreferences ──────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_lastScanKey);
      if (lastMs != null) {
        _lastScanDate =
            DateTime.fromMillisecondsSinceEpoch(lastMs);
        _daysSinceScan =
            DateTime.now().difference(_lastScanDate!).inDays;
      }

      // ── Scan records from local queue JSON ─────────────────────────────────
      final cacheDir = await getApplicationCacheDirectory();
      final queueFile =
          File('${cacheDir.path}/$_queueFileName');

      List<Map<String, dynamic>> scans = [];

      if (await queueFile.exists()) {
        try {
          final content = await queueFile.readAsString();
          final List decoded = jsonDecode(content);
          scans = decoded.cast<Map<String, dynamic>>().toList();
        } catch (_) {
          scans = [];
        }
      }

      // Sort newest first
      scans.sort((a, b) {
        final ta = a['timestamp'] as int? ?? 0;
        final tb = b['timestamp'] as int? ?? 0;
        return tb.compareTo(ta);
      });

      // Sync last scan date if SharedPreferences is empty
      if (scans.isNotEmpty && _lastScanDate == null) {
        final latestMs =
            scans.first['timestamp'] as int? ?? 0;
        if (latestMs > 0) {
          _lastScanDate =
              DateTime.fromMillisecondsSinceEpoch(latestMs);
          _daysSinceScan =
              DateTime.now().difference(_lastScanDate!).inDays;
          await prefs.setInt(_lastScanKey, latestMs);
        }
      }

      setState(() {
        _scans   = scans;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Banner helpers ─────────────────────────────────────────────────────────
  Color get _bannerColor {
    if (_lastScanDate == null) return orangeRisk;
    if (_daysSinceScan < 3)    return primary;
    if (_daysSinceScan == 3)   return orangeRisk;
    return redRisk;
  }

  IconData get _bannerIcon {
    if (_lastScanDate == null) return Icons.notification_important;
    if (_daysSinceScan < 3)    return Icons.check_circle_outline;
    if (_daysSinceScan == 3)   return Icons.schedule;
    return Icons.warning_amber_rounded;
  }

  String get _bannerTitle {
    if (_lastScanDate == null) return 'No scans yet';
    if (_daysSinceScan == 0)   return 'Scanned today ✓';
    if (_daysSinceScan == 1)   return '1 day since last scan';
    if (_daysSinceScan < 3)    return '$_daysSinceScan days since last scan';
    if (_daysSinceScan == 3)   return 'Time to scan your flock!';
    return '$_daysSinceScan days overdue — scan now!';
  }

  String get _bannerSubtitle {
    if (_lastScanDate == null) {
      return 'Take your first fecal image scan to start tracking your flock\'s health.';
    }
    if (_daysSinceScan < 3) {
      final daysLeft = 3 - _daysSinceScan;
      final nextScan =
          _lastScanDate!.add(const Duration(days: 3));
      return 'Next scan due in $daysLeft day${daysLeft == 1 ? '' : 's'} '
          '(${_formatDate(nextScan)}). Your flock is being monitored.';
    }
    if (_daysSinceScan == 3) {
      return 'It has been 3 days since your last scan. '
          'Take a fecal image now to check for disease.';
    }
    return 'Your flock has not been checked in $_daysSinceScan days. '
        'Disease can spread quickly — scan now!';
  }

  bool get _showScanButton =>
      _daysSinceScan >= 3 || _lastScanDate == null;

  // ── Label helpers ──────────────────────────────────────────────────────────
  Color _labelColor(String? label) {
    switch (label) {
      case 'Coccidiosis':       return redRisk;
      case 'Newcastle Disease': return const Color(0xFF8E44AD);
      case 'Salmonella':        return orangeRisk;
      case 'Healthy':           return primary;
      default:                  return greyText;
    }
  }

  IconData _labelIcon(String? label) {
    if (label == 'Healthy')      return Icons.check_circle_outline;
    if (label == 'No Detection') return Icons.help_outline;
    return Icons.warning_amber_rounded;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h   = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m   = dt.minute.toString().padLeft(2, '0');
    final per = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m $per';
  }

  String _timeAgo(int? ms) {
    if (ms == null) return '';
    final dt   = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays == 1)    return 'Yesterday';
    if (diff.inDays < 7)     return '${diff.inDays} days ago';
    return _formatDate(dt);
  }

  String _actionAdvice(String label) {
    switch (label) {
      case 'Coccidiosis':
        return '💊 Treat with Amprolium in drinking water. Keep litter dry and isolate affected birds.';
      case 'Newcastle Disease':
        return '🚨 No cure — isolate immediately. Vaccinate unaffected birds. Contact a vet.';
      case 'Salmonella':
        return '⚠️ Strict biosecurity required. Clean water, proper feed. Handle birds with care.';
      default:
        return '📋 Consult a veterinarian for diagnosis confirmation and treatment advice.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: lightBg,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('PoulVet',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primary,
                fontSize: 20)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AlertsScreen()),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: const Text('3',
                      style: TextStyle(
                          color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReminderBanner(),
                    const SizedBox(height: 24),
                    if (_scans.isNotEmpty) ...[
                      _buildSummaryRow(),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Scan History',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkText)),
                        Text(
                          '${_scans.length} scan${_scans.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 13, color: greyText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_scans.isEmpty)
                      _buildEmptyState()
                    else
                      ..._scans.map(_buildScanCard),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }

  Widget _buildReminderBanner() {
    final color = _bannerColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_bannerIcon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_bannerTitle,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    if (_lastScanDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Last scan: ${_formatDate(_lastScanDate!)}',
                        style: const TextStyle(
                            fontSize: 11, color: greyText),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _bannerSubtitle,
            style: TextStyle(
                fontSize: 13,
                color: color == primary
                    ? Colors.green[700]
                    : Colors.grey[700],
                height: 1.5),
          ),
          if (_showScanButton) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Scan Your Flock Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomePage()),
                  (_) => false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final total   = _scans.length;
    final healthy =
        _scans.where((s) => s['label'] == 'Healthy').length;
    final diseased = total - healthy;
    return Row(
      children: [
        _summaryTile('Total Scans', total.toString(),
            Icons.history, greyText),
        const SizedBox(width: 10),
        _summaryTile('Healthy', healthy.toString(),
            Icons.check_circle_outline, primary),
        const SizedBox(width: 10),
        _summaryTile('Disease Found', diseased.toString(),
            Icons.warning_amber_rounded, redRisk),
      ],
    );
  }

  Widget _summaryTile(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    color: greyText,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final label      = scan['label'] as String? ?? 'Unknown';
    final confidence =
        (scan['confidence'] as num? ?? 0.0).toDouble();
    final timestamp  = scan['timestamp'] as int?;
    final district   = scan['district'] as String? ?? '';
    final labelColor = _labelColor(label);
    final isHealthy  = label == 'Healthy';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            left: BorderSide(color: labelColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_labelIcon(label),
                    color: labelColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: labelColor)),
                    const SizedBox(height: 2),
                    Text(_timeAgo(timestamp),
                        style: const TextStyle(
                            fontSize: 11, color: greyText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: labelColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor:
                  labelColor.withValues(alpha: 0.1),
              valueColor:
                  AlwaysStoppedAnimation<Color>(labelColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 11, color: greyText),
              const SizedBox(width: 4),
              Text(
                timestamp != null
                    ? _formatDate(
                        DateTime.fromMillisecondsSinceEpoch(
                            timestamp))
                    : '—',
                style: const TextStyle(
                    fontSize: 11, color: greyText),
              ),
              if (district.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on,
                    size: 11, color: greyText),
                const SizedBox(width: 3),
                Text(district,
                    style: const TextStyle(
                        fontSize: 11, color: greyText)),
              ],
            ],
          ),
          if (!isHealthy &&
              label != 'Unknown' &&
              label != 'No Detection') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _actionAdvice(label),
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.camera_alt_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No scans yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkText)),
          const SizedBox(height: 8),
          const Text(
            'Your scan history will appear here after\nyou take your first fecal image.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: greyText, height: 1.5),
          ),
        ],
      ),
    );
  }
}
