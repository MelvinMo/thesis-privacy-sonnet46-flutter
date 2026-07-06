// MIGRATION: services/BackgroundTaskManager.ts → Dart BackgroundSensorService.
//
//            HARD RULE 11: Android 8+ requires ForegroundService + persistent
//            notification for background sensor collection.
//            expo-background-fetch / expo-task-manager → flutter_background_service ^5.
//
//            Architecture:
//              - Main isolate: starts the service, updates config.
//              - Background isolate: runs inside flutter_background_service,
//                instantiates lightweight sensor polling, writes to DB.
//
//            NOTE: The source code has a TODO noting background tasks don't
//            truly run in the background yet. This implementation adds the
//            proper Flutter ForegroundService scaffolding.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants/sensor_config.dart';

// ---------------------------------------------------------------------------
// Notification channel constants (Android 8+ requirement)
// ---------------------------------------------------------------------------
const _notifChannelId = 'sleep_tracker_sensor_channel';
const _notifChannelName = 'Sleep Tracker Sensors';
const _notifId = 888;

class BackgroundSensorService {
  static final _bgService = FlutterBackgroundService();

  // ---------------------------------------------------------------------------
  // initializeService — call once from main().
  // MIGRATION: Replaces expo-task-manager TaskManager.defineTask().
  // ---------------------------------------------------------------------------
  static Future<void> initialize() async {
    final notifications = FlutterLocalNotificationsPlugin();

    // MIGRATION: Android 8+ requires a notification channel for ForegroundService.
    const androidChannel = AndroidNotificationChannel(
      _notifChannelId,
      _notifChannelName,
      description: 'Monitors sleep-related sensors in the background.',
      importance: Importance.low,
    );

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _bgService.configure(
      // ── Android ForegroundService (Rule 11) ───────────────────────────
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true, // Mandatory for Android 8+ background sensors
        notificationChannelId: _notifChannelId,
        initialNotificationTitle: 'Sleep Tracker',
        initialNotificationContent: 'Monitoring your sleep environment…',
        foregroundServiceNotificationId: _notifId,
      ),
      // ── iOS background fetch (best-effort, limited by OS) ─────────────
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Entry point for the background isolate.
  // MIGRATION: expo-task-manager task callback → flutter_background_service
  //            background isolate onStart handler.
  // ---------------------------------------------------------------------------
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // MIGRATION: Background isolate cannot access Riverpod or BLoC directly.
    //            It uses SendData/on() to communicate with the main isolate.
    service.on('stopService').listen((_) async {
      await service.stopSelf();
    });

    service.on('updateConfig').listen((data) {
      // Config updates from the main isolate.
      // MIGRATION_FLAG: Implement lightweight sensor polling here once
      //                 the sensor service can be instantiated in the isolate.
    });

    // Update notification periodically (shows sensor status).
    // MIGRATION: BackgroundTaskManager.ts TODO about true background mode.
    //            This ForegroundService satisfies Android 8+ requirement (Rule 11).
    service.invoke('update', {
      'status': 'monitoring',
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    // MIGRATION: iOS background processing is best-effort and limited.
    //            Return true to keep the service alive if possible.
    return true;
  }

  // ---------------------------------------------------------------------------
  // Public API (mirrors BackgroundTaskManager.ts updateConfig)
  // ---------------------------------------------------------------------------
  static Future<void> startService() async {
    await _bgService.startService();
  }

  static Future<void> stopService() async {
    _bgService.invoke('stopService');
  }

  static Future<bool> isRunning() async {
    return _bgService.isRunning();
  }

  static void updateConfig(SensorServiceConfig config) {
    _bgService.invoke('updateConfig', {
      'audioEnabled': config.audioEnabled,
      'lightEnabled': config.lightEnabled,
      'accelerometerEnabled': config.accelerometerEnabled,
      'useSimulation': config.useSimulation,
    });
  }
}
