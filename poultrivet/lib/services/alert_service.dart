import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../pages/api_service.dart';

/// Handles daily district risk checks and local push notifications.
///
/// Call AlertService.checkAndNotify() from:
///   - home_page.dart initState (on app launch, respects 24h cooldown)
///   - alerts_page.dart initState (always fetches fresh, no cooldown)

class AlertService {
  static const String _lastCheckKey = 'last_district_check';
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _notificationsInitialized = false;

  // ── Initialize local notifications (call once in main.dart) ───────────────
  static Future<void> init() async {
    if (_notificationsInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    _notificationsInitialized = true;
  }

  // ── Check district risk — called from home_page on app launch ──────────────
  /// Lightweight check — workmanager handles the 2h background schedule.
  /// This just does one check on foreground launch so the farmer sees
  /// up-to-date risk when they open the app.
  static Future<void> checkAndNotify() async {
    final prefs = await SharedPreferences.getInstance();
    await _fetchAndNotify(prefs: prefs);
  }

  // ── Force check — no cooldown ─────────────────────────────────────────────
  /// Call from alerts_page initState.
  /// Always fetches fresh regardless of last check time.
  /// Returns the district data map for the page to display.
  static Future<Map<String, dynamic>?> forceCheckAndNotify() async {
    final prefs = await SharedPreferences.getInstance();
    return await _fetchAndNotify(prefs: prefs);
  }

  // ── Core fetch + notify logic ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> _fetchAndNotify({
    required SharedPreferences prefs,
  }) async {
    try {
      // Get farmer's district
      User? user = FirebaseAuth.instance.currentUser;
      user ??= await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null, orElse: () => null);
      if (user == null) return null;

      final farmer = await AuthService().getFarmerProfile(user.uid);
      if (farmer == null || farmer.district.trim().isEmpty) return null;

      // Fetch satellite data for their district
      final data = await ApiService.getDistrict(farmer.district.trim());
      final riskLevel =
          (data['risk_level'] ?? '').toString().toUpperCase();
      final diseases =
          data['diseases_flagged'] ?? 'unknown diseases';

      // Save last check time
      await prefs.setInt(
          _lastCheckKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint(
          'AlertService: ${farmer.district} → $riskLevel');

      // Only notify if HIGH or MEDIUM
      if (riskLevel == 'HIGH' || riskLevel == 'MEDIUM') {
        await _sendNotification(
          district: farmer.district,
          riskLevel: riskLevel,
          diseases: diseases,
        );
      }

      return data;
    } catch (e) {
      debugPrint('AlertService error: $e');
      return null;
    }
  }

  // ── Fire local notification ────────────────────────────────────────────────
  static Future<void> _sendNotification({
    required String district,
    required String riskLevel,
    required String diseases,
  }) async {
    await init();

    final isHigh = riskLevel == 'HIGH';
    final title = isHigh
        ? '⚠️ High Risk Alert — $district'
        : '🔔 Disease Watch — $district';
    final body = isHigh
        ? 'Your district has a HIGH disease risk. Watch for: $diseases'
        : 'Moderate conditions in $district. Monitor your flock. Watch for: $diseases';

    const androidDetails = AndroidNotificationDetails(
      'poulvet_alerts',
      'Disease Alerts',
      channelDescription:
          'Satellite-based poultry disease risk notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.show(
      0, // notification ID — same ID means it replaces the previous one
      title,
      body,
      const NotificationDetails(
          android: androidDetails, iOS: iosDetails),
    );

    debugPrint('AlertService: notification sent for $district ($riskLevel)');
  }
}
