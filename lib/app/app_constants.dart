class AppConstants {
  static const String appName = 'NOTIFY';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String eventsBoxName = 'important_events';
  static const String settingsBoxName = 'app_settings';
  
  // Notification channels
  static const String criticalAlarmChannelId = 'critical_alarms';
  static const String criticalAlarmChannelName = 'Critical Alarms';
  static const String reminderChannelId = 'reminders';
  static const String reminderChannelName = 'Reminders';
  
  // Shared preferences keys
  static const String keyDefaultVibration = 'default_vibration';
  static const String keyDefaultSnooze = 'default_snooze_minutes';
  static const String keyDefaultSound = 'default_sound';
  static const String keyPreviewBeforeSave = 'preview_before_save';
  static const String keyKeepAliveBackground = 'keep_alive_background';
  
  // Snooze durations (in minutes)
  static const List<int> snoozeOptions = [5, 10, 15, 30];
  
  // Default values
  static const int defaultSnoozeMinutes = 5;
  static const String defaultSound = 'alarm_sound.mp3';
  
  // Maximum events
  static const int maxEvents = 500;
  
  // Recurrence patterns
  static const List<String> recurrencePatterns = [
    'Never',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];
}