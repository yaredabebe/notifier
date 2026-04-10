import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class PermissionsHelper {
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    final permissions = [
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.ignoreBatteryOptimizations,
    ];
    
    Map<Permission, PermissionStatus> statuses = {};
    
    for (var permission in permissions) {
      final status = await permission.status;
      statuses[permission] = status;
      
      if (!status.isGranted) {
        final result = await permission.request();
        statuses[permission] = result;
      }
    }
    
    final allGranted = statuses.values.every((status) => status.isGranted);
    
    // Check vibration capability (no permission needed)
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    final hasVibrationSupport = await Vibration.hasCustomVibrationsSupport() ?? false;
    
    if (!allGranted && context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For the app to work properly, please grant these permissions:',
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                'Notifications', 
                statuses[Permission.notification] ?? PermissionStatus.denied,
                'Required for alarm alerts'
              ),
              _buildPermissionItem(
                'Exact Alarms', 
                statuses[Permission.scheduleExactAlarm] ?? PermissionStatus.denied,
                'For precise alarm timing'
              ),
              _buildPermissionItem(
                'Battery Optimization', 
                statuses[Permission.ignoreBatteryOptimizations] ?? PermissionStatus.denied,
                'Prevent Android from killing alarms'
              ),
              const SizedBox(height: 8),
              Text(
                hasVibrator 
                    ? '✅ Vibration is available on this device'
                    : '⚠️ Vibration is not available on this device',
                style: TextStyle(
                  fontSize: 12,
                  color: hasVibrator ? Colors.green : Colors.orange.shade700,
                ),
              ),
              if (hasVibrator && hasVibrationSupport)
                const Text(
                  '✓ Custom vibration patterns supported',
                  style: TextStyle(fontSize: 11, color: Colors.green),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
    
    return allGranted;
  }
  
  static Widget _buildPermissionItem(String name, PermissionStatus status, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            status.isGranted ? Icons.check_circle : Icons.warning,
            color: status.isGranted ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            status.isGranted ? 'Granted' : 'Required',
            style: TextStyle(
              fontSize: 12,
              color: status.isGranted ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static Future<bool> hasCriticalPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    
    return notificationStatus.isGranted && 
           alarmStatus.isGranted && 
           batteryStatus.isGranted;
  }
  
  // Vibration methods using the vibration package
  static Future<bool> hasVibrator() async {
    return await Vibration.hasVibrator() ?? false;
  }
  
  static Future<bool> hasAmplitudeControl() async {
    return await Vibration.hasAmplitudeControl() ?? false;
  }
  
  static Future<bool> hasCustomVibrationsSupport() async {
    return await Vibration.hasCustomVibrationsSupport() ?? false;
  }
  
  static Future<void> vibrate({
    int duration = 500,
    int? amplitude,
    List<int>? pattern,
  }) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;
    
    if (pattern != null) {
      // Custom pattern
      await Vibration.vibrate(pattern: pattern);
    } else if (amplitude != null && await hasAmplitudeControl()) {
      // With amplitude control (Android 8.0+)
      await Vibration.vibrate(duration: duration, amplitude: amplitude);
    } else {
      // Simple vibration
      await Vibration.vibrate(duration: duration);
    }
  }
  
  static Future<void> vibrateAlarm() async {
    // Custom alarm pattern: long-short-long
    await vibrate(pattern: [1000, 500, 1000]);
  }
  
  static Future<void> vibrateStop() async {
    // Short vibration for stop action
    await vibrate(duration: 100);
  }
  
  static Future<void> cancelVibration() async {
    await Vibration.cancel();
  }
  
  static String getPermissionStatusMessage(PermissionStatus status) {
    if (status.isGranted) return 'Granted';
    if (status.isDenied) return 'Denied';
    if (status.isPermanentlyDenied) return 'Permanently Denied';
    if (status.isRestricted) return 'Restricted';
    if (status.isLimited) return 'Limited';
    return 'Unknown';
  }
  
  static Color getPermissionStatusColor(PermissionStatus status) {
    if (status.isGranted) return Colors.green;
    if (status.isDenied) return Colors.orange;
    if (status.isPermanentlyDenied) return Colors.red;
    return Colors.grey;
  }
}