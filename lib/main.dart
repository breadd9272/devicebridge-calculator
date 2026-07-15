import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/utils/app_settings.dart';
import 'core/utils/logger.dart';
import 'services/background_service.dart';
import 'app.dart';

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app settings
  await AppSettings.init();

  // Initialize local notifications for background service
  await _initializeNotifications();

  // Configure background service
  await BackgroundServiceManager().initialize();

  AppLogger.i('Main', 'App initialized');

  runApp(const ProviderScope(child: DeviceBridgeApp()));
}

Future<void> _initializeNotifications() async {
  final notifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await notifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (_) {},
  );

  // Create notification channels
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'calculator_service',
        'Calculator Service',
        description: 'Keeps the calculator running in background',
        importance: Importance.low,
        showBadge: false,
      ));

  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'commands_channel',
        'Commands',
        description: 'Notifications for received commands',
        importance: Importance.low,
      ));

  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'connection_channel',
        'Connection Status',
        description: 'Connection status changes',
        importance: Importance.high,
      ));
}