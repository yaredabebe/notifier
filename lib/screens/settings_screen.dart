import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';
import '../database/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final SchedulerService _schedulerService = SchedulerService();
  final HiveService _hiveService = HiveService();
  
  // Settings values
  bool _defaultVibration = true;
  int _defaultSnoozeMinutes = 5;
  String _defaultSound = 'alarm_sound.mp3';
  bool _showPreviewBeforeSave = true;
  bool _keepAliveInBackground = true;
  
  // Permission statuses
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _alarmStatus = PermissionStatus.denied;
  PermissionStatus _batteryStatus = PermissionStatus.denied;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultVibration = prefs.getBool('default_vibration') ?? true;
      _defaultSnoozeMinutes = prefs.getInt('default_snooze_minutes') ?? 5;
      _defaultSound = prefs.getString('default_sound') ?? 'alarm_sound.mp3';
      _showPreviewBeforeSave = prefs.getBool('show_preview_before_save') ?? true;
      _keepAliveInBackground = prefs.getBool('keep_alive_background') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('default_vibration', _defaultVibration);
    await prefs.setInt('default_snooze_minutes', _defaultSnoozeMinutes);
    await prefs.setString('default_sound', _defaultSound);
    await prefs.setBool('show_preview_before_save', _showPreviewBeforeSave);
    await prefs.setBool('keep_alive_background', _keepAliveInBackground);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }
  
  Future<void> _checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    
    setState(() {
      _notificationStatus = notificationStatus;
      _alarmStatus = alarmStatus;
      _batteryStatus = batteryStatus;
    });
  }
  
  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() {});
    
    if (mounted && status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${permission.toString()} permission granted')),
      );
    }
  }
  
  Future<void> _exportEvents() async {
    try {
      final events = _hiveService.getAllEvents();
      final jsonString = events.map((e) => {
        'id': e.id,
        'title': e.title,
        'description': e.description,
        'dateTime': e.dateTime.toIso8601String(),
        'eventType': e.eventType.toString(),
        'isRecurring': e.isRecurring,
        'snoozeDuration': e.snoozeDuration,
        'soundAsset': e.soundAsset,
        'vibrateEnabled': e.vibrateEnabled,
        'createdAt': e.createdAt.toIso8601String(),
      }).toList();
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString.toString()));
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Success'),
            content: Text('${events.length} events exported to clipboard'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
  
  Future<void> _clearAllEvents() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Events'),
        content: const Text(
          'This will delete ALL events and alarms. This action cannot be undone.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final events = _hiveService.getAllEvents();
      for (final event in events) {
        await _notificationService.cancelAlarm(event);
        await _hiveService.deleteEvent(event.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All events cleared')),
        );
        Navigator.pop(context, true); // Return to home to refresh
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Permissions Section
          _buildSectionHeader('Permissions', Icons.security),
          _buildPermissionTile(
            'Notifications',
            'Required to show alerts and reminders',
            _notificationStatus,
            Icons.notifications_active,
            () => _requestPermission(Permission.notification),
          ),
          _buildPermissionTile(
            'Exact Alarms',
            'For precise timing of reminders',
            _alarmStatus,
            Icons.alarm,
            () => _requestPermission(Permission.scheduleExactAlarm),
          ),
          _buildPermissionTile(
            'Ignore Battery Optimization',
            'Prevents Android from killing alarms',
            _batteryStatus,
            Icons.battery_charging_full,
            () => _requestPermission(Permission.ignoreBatteryOptimizations),
          ),
          
          const Divider(height: 32),
          
          // Default Settings Section
          _buildSectionHeader('Default Settings', Icons.settings),
          
          // Default Vibration
          SwitchListTile(
            title: const Text('Enable Vibration'),
            subtitle: const Text('Vibrate when alarm rings (default)'),
            secondary: const Icon(Icons.vibration),
            value: _defaultVibration,
            onChanged: (value) {
              setState(() => _defaultVibration = value);
            },
          ),
          
          // Default Snooze Duration
          ListTile(
            title: const Text('Default Snooze Duration'),
            subtitle: Text('$_defaultSnoozeMinutes minutes'),
            leading: const Icon(Icons.snooze),
            trailing: DropdownButton<int>(
              value: _defaultSnoozeMinutes,
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 min')),
                DropdownMenuItem(value: 10, child: Text('10 min')),
                DropdownMenuItem(value: 15, child: Text('15 min')),
                DropdownMenuItem(value: 30, child: Text('30 min')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _defaultSnoozeMinutes = value);
                }
              },
            ),
          ),
          
          // Default Sound
          ListTile(
            title: const Text('Default Alarm Sound'),
            subtitle: Text(_defaultSound.replaceAll('.mp3', '').replaceAll('_', ' ')),
            leading: const Icon(Icons.volume_up),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                // Play sound preview
                _playSoundPreview(_defaultSound);
              },
            ),
            onTap: () {
              _showSoundPicker();
            },
          ),
          
          // Preview before save
          SwitchListTile(
            title: const Text('Preview Before Saving'),
            subtitle: const Text('Show alarm preview when creating events'),
            secondary: const Icon(Icons.preview),
            value: _showPreviewBeforeSave,
            onChanged: (value) {
              setState(() => _showPreviewBeforeSave = value);
            },
          ),
          
          // Keep alive in background
          SwitchListTile(
            title: const Text('Keep Alive in Background'),
            subtitle: const Text('Run background service for reliable alarms'),
            secondary: const Icon(Icons.brightness_low),
            value: _keepAliveInBackground,
            onChanged: (value) {
              setState(() => _keepAliveInBackground = value);
              if (value) {
                _startBackgroundService();
              } else {
                _stopBackgroundService();
              }
            },
          ),
          
          const Divider(height: 32),
          
          // Data Management Section
          _buildSectionHeader('Data Management', Icons.storage),
          
          ListTile(
            title: const Text('Export Events'),
            subtitle: const Text('Export all events to clipboard'),
            leading: const Icon(Icons.upload_file),
            trailing: const Icon(Icons.arrow_forward),
            onTap: _exportEvents,
          ),
          
          ListTile(
            title: const Text('Clear All Events'),
            subtitle: const Text('Delete all events and alarms'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            trailing: const Icon(Icons.warning, color: Colors.red),
            onTap: _clearAllEvents,
          ),
          
          const Divider(height: 32),
          
          // About Section
          _buildSectionHeader('About', Icons.info),
          
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.code),
          ),
          
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () => _showPrivacyPolicy(),
          ),
          
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            onTap: () => _showTerms(),
          ),
          
          const SizedBox(height: 32),
          Center(
            child: Text(
              'NOTIFY - Never miss important moments',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionTile(
    String title,
    String subtitle,
    PermissionStatus status,
    IconData icon,
    VoidCallback onRequest,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(icon),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: status.isGranted ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.isGranted ? 'Granted' : 'Required',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      onTap: status.isGranted ? null : onRequest,
    );
  }
  
  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Alarm Sound',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSoundOption('alarm_sound.mp3', 'Classic Alarm'),
            _buildSoundOption('gentle_reminder.mp3', 'Gentle Reminder'),
            _buildSoundOption('urgent_bell.mp3', 'Urgent Bell'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSoundOption(String soundFile, String displayName) {
    return ListTile(
      title: Text(displayName),
      leading: const Icon(Icons.music_note),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () => _playSoundPreview(soundFile),
      ),
      onTap: () {
        setState(() => _defaultSound = soundFile);
        Navigator.pop(context);
      },
    );
  }
  
  void _playSoundPreview(String soundFile) {
    // TODO: Implement sound preview using audio players
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing: $soundFile')),
    );
  }
  
  void _startBackgroundService() {
    // TODO: Implement background service start
    print('Starting background service...');
  }
  
  void _stopBackgroundService() {
    // TODO: Implement background service stop
    print('Stopping background service...');
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'NOTIFY respects your privacy.\n\n'
            '• All data is stored locally on your device\n'
            '• No data is sent to any server\n'
            '• Notifications are processed locally\n'
            '• You can export/delete your data anytime\n'
            '• No tracking or analytics\n\n'
            'Your events remain completely private.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using NOTIFY, you agree to:\n\n'
            '• Use the app for personal reminders only\n'
            '• NOTIFY is not responsible for missed events\n'
            '• Alarms depend on device permissions and settings\n'
            '• The app requires background permissions to function\n'
            '• You can stop using the app and delete your data anytime',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}