import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/important_event.dart';
import '../models/event_type.dart';
import '../screens/alarm_ringing_screen.dart';
import 'alarm_handler.dart';
import '../main.dart'; // For navigatorKey

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const String criticalAlarmChannelId = 'critical_alarms';
  static const String criticalAlarmChannelName = 'Critical Alarms';
  static const String normalChannelId = 'reminders';
  static const String normalChannelName = 'Reminders';

  Future<void> init() async {
    // Initialize local notifications for Android only
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: null, // No iOS support
    );
    
    await _localNotifications.initialize(settings);
    
    // Create notification channels
    await _createNotificationChannels();
    
    // Request critical permissions
    await _requestPermissions();
    
    // Initialize Android Alarm Manager
    await AndroidAlarmManager.initialize();
    
    print('✅ Notification service initialized for Android');
  }

  Future<void> _createNotificationChannels() async {
    // Critical alarm channel (bypasses DND)
    const AndroidNotificationChannel criticalChannel = AndroidNotificationChannel(
      criticalAlarmChannelId,
      criticalAlarmChannelName,
      description: 'Critical alarms that bypass Do Not Disturb mode',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );
    
    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(criticalChannel);
    
    // Normal reminders channel
    const AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
      normalChannelId,
      normalChannelName,
      description: 'Normal reminders',
      importance: Importance.high,
    );
    
    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(normalChannel);
  }

  Future<void> _requestPermissions() async {
    // Android permissions (vibration permission not needed)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    
    // Note: Vibration works automatically on Android without permission
  }

  // Schedule an alarm for an important event
 // Schedule an alarm for an important event
Future<void> scheduleAlarm(ImportantEvent event) async {
  final DateTime alarmTime = event.dateTime;
  
  // For Android: Full-screen intent configuration
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    criticalAlarmChannelId,
    criticalAlarmChannelName,
    channelDescription: '🔔 IMPORTANT: ${event.title}',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true, // This is KEY for alarm behavior
    enableVibration: event.vibrateEnabled,
    playSound: true,
    ongoing: true,
    autoCancel: false,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    actions: [
      const AndroidNotificationAction('stop', '⛔ STOP', showsUserInterface: true),
      const AndroidNotificationAction('snooze_5', '⏸️ SNOOZE 5min'),
      const AndroidNotificationAction('snooze_10', '⏸️ SNOOZE 10min'),
    ],
  );
  
  final NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );
  
  // Calculate the scheduled time
  final scheduledDate = tz.TZDateTime.from(alarmTime, tz.local);
  
  // Schedule the notification
 await _localNotifications.zonedSchedule(
  event.id.hashCode,
  '🔔 ${event.eventType.displayName}',
  event.title,
  scheduledDate,
  platformDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: null, // NO automatic recurrence
  payload: jsonEncode({
    'eventId': event.id,
    'title': event.title,
    'description': event.description ?? '',
    'type': event.eventType.toString(),
  }),
);
  
  // Also schedule with Android Alarm Manager for reliable background execution
  await _scheduleWithAlarmManager(event);
  
  print('✅ Alarm scheduled for ${event.title} at $alarmTime');
}
  // Use Android Alarm Manager for true alarm clock behavior
  Future<void> _scheduleWithAlarmManager(ImportantEvent event) async {
    final int alarmId = event.id.hashCode;
    final DateTime alarmTime = event.dateTime;
    final now = DateTime.now();
    final Duration delay = alarmTime.difference(now);
    
    if (delay.isNegative) {
      print('⚠️ Alarm time is in the past, not scheduling');
      return;
    }
    
    // Store event data in shared preferences for retrieval
    await AlarmHandler.storeEventData(event);
    
    // Schedule one-time alarm
    await AndroidAlarmManager.oneShot(
      delay,
      alarmId,
      AlarmHandler.alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true, // This makes it a real alarm clock
      allowWhileIdle: true,
    );
    
    print('✅ Android Alarm Manager scheduled for ${event.title} in ${delay.inMinutes} minutes');
  }

  // Cancel an alarm
  Future<void> cancelAlarm(ImportantEvent event) async {
    await _localNotifications.cancel(event.id.hashCode);
    await AndroidAlarmManager.cancel(event.id.hashCode);
    print('❌ Alarm cancelled for ${event.title}');
  }

  // Snooze an alarm
  Future<void> snoozeAlarm(ImportantEvent event, {int minutes = 5}) async {
    // Cancel current alarm
    await cancelAlarm(event);
    
    // Create new event with snoozed time
    final snoozedEvent = event.copyWith(
      dateTime: DateTime.now().add(Duration(minutes: minutes)),
    );
    
    // Schedule new alarm
    await scheduleAlarm(snoozedEvent);
    
    // Show confirmation notification
    await showSimpleNotification(
      'Snoozed',
      'Will remind you again in $minutes minutes',
    );
  }

  // Show immediate full-screen alert (for testing or manual triggers)
  Future<void> showFullScreenAlert(ImportantEvent event) async {
    // Navigate to full-screen alarm screen
    await _navigateToAlarmScreen(event);
    
    // Also show notification as backup
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      criticalAlarmChannelId,
      criticalAlarmChannelName,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
    );
    
    await _localNotifications.show(
      event.id.hashCode,
      '🔔 ${event.title}',
      event.description ?? 'Important moment!',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _navigateToAlarmScreen(ImportantEvent event) async {
    // Use global navigator key to show full-screen dialog
    if (navigatorKey.currentContext != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => AlarmRingingScreen(event: event),
        ),
      );
    }
  }

  // Simple notification for non-critical updates
  Future<void> showSimpleNotification(String title, String body) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      normalChannelId,
      normalChannelName,
      importance: Importance.low,
      priority: Priority.low,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
  
  // Check if we have all permissions
  Future<bool> hasCriticalPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    
    return notificationStatus.isGranted && alarmStatus.isGranted;
  }
  
  // Open app settings for manual permission granting
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}