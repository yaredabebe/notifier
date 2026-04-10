import 'dart:async';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/hive_service.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';

// Background task name
const String backgroundSyncTask = "syncAlarmsTask";
const String alarmCheckerTask = "alarmCheckerTask";

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Timer? _periodicTimer;
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();
  final SchedulerService _schedulerService = SchedulerService();
  
  // Initialize background service
  Future<void> init() async {
    // Initialize WorkManager for periodic tasks
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Register periodic task (every 15 minutes)
    await Workmanager().registerPeriodicTask(
      "alarm-checker",
      alarmCheckerTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
    
    print('✅ Background service initialized');
  }
  
  // Start periodic alarm check (for when app is in foreground)
  void startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndRescheduleAlarms();
    });
    print('✅ Periodic alarm check started');
  }
  
  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    print('⏹️ Periodic alarm check stopped');
  }
  
  // Check and reschedule any missed alarms
  Future<void> _checkAndRescheduleAlarms() async {
    try {
      final events = _hiveService.getAllEvents();
      final now = DateTime.now();
      
      for (final event in events) {
        // Check if alarm should have rung but didn't
        if (event.dateTime.isBefore(now) && 
            event.dateTime.isAfter(now.subtract(const Duration(minutes: 30)))) {
          print('⚠️ Missed alarm detected: ${event.title}');
          
          // Show missed alarm notification
          await _notificationService.showSimpleNotification(
            'Missed: ${event.title}',
            'Your alarm was missed. Tap to reschedule.',
          );
          
          // Reschedule if recurring
          if (event.isRecurring) {
            await _schedulerService.checkAndRescheduleEvents();
          }
        }
        
        // Check if alarm is coming up soon and not scheduled
        final timeUntil = event.dateTime.difference(now);
        if (timeUntil.inMinutes <= 60 && timeUntil.inMinutes > 0) {
          // Ensure alarm is scheduled
          // This is handled by the main scheduler
        }
      }
    } catch (e) {
      print('Error in background check: $e');
    }
  }
  
  // Reschedule all alarms (called on app restart)
  Future<void> rescheduleAllAlarms() async {
    await _schedulerService.scheduleAllEvents();
    print('✅ All alarms rescheduled');
  }
  
  // Handle boot completed (Android)
  Future<void> onBootCompleted() async {
    await Future.delayed(const Duration(seconds: 10)); // Wait for system
    await rescheduleAllAlarms();
    print('📱 Boot completed - alarms rescheduled');
  }
}

// Callback dispatcher for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final backgroundService = BackgroundService();
    
    switch (task) {
      case alarmCheckerTask:
        await backgroundService._checkAndRescheduleAlarms();
        break;
      default:
        print('Unknown background task: $task');
    }
    
    return Future.value(true);
  });
}