import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'alert_service.dart';

// ── Task name constants ────────────────────────────────────────────────────
const String kDistrictCheckTask = 'districtRiskCheck';

/// Called by the OS when a background task fires.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Firebase must be initialized in the background isolate too
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AlertService.init();

      if (taskName == kDistrictCheckTask) {
        // Force check regardless of cooldown — workmanager handles the schedule
        await AlertService.forceCheckAndNotify();
      }
    } catch (e) {
      debugPrint('Background task error: $e');
    }
    return Future.value(true);
  });
}

/// Call this once from main.dart to register the background task.
class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Register a periodic task that fires every 2 hours.
  /// Safe to call on every app launch — workmanager replaces existing task.
  static Future<void> scheduleDistrictCheck() async {
    await Workmanager().registerPeriodicTask(
      kDistrictCheckTask,        // unique task ID
      kDistrictCheckTask,        // task name passed to callbackDispatcher
      frequency: const Duration(hours: 2),
      constraints: Constraints(
        networkType: NetworkType.connected, // only run when online
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
