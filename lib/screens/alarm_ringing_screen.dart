import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../models/important_event.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';
import '../database/hive_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  final ImportantEvent event;
  
  const AlarmRingingScreen({
    super.key,
    required this.event,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isVibrating = false;
  
  @override
  void initState() {
    super.initState();
    
    // Keep screen on
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    });
    
    // Pulsing animation for attention
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start vibration if enabled
    _startVibration();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _stopVibration();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
  
  Future<void> _startVibration() async {
    if (!widget.event.vibrateEnabled) return;
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      _isVibrating = true;
      // Vibrate with pattern: 1s on, 0.5s off, 1s on, 0.5s off (repeating)
      Vibration.vibrate(pattern: [1000, 500, 1000, 500], repeat: 0);
    }
  }
  
  Future<void> _stopVibration() async {
    if (_isVibrating) {
      await Vibration.cancel();
      _isVibrating = false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.event.eventType.icon,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Event title
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description if exists
            if (widget.event.description != null && widget.event.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.event.description!,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Event type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.event.eventType.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // STOP button (large, red)
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _stopAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'STOP',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Snooze options row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSnoozeButton(5, Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSnoozeButton(10, Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSnoozeButton(15, Colors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSnoozeButton(int minutes, Color color) {
    return ElevatedButton(
      onPressed: () => _snoozeAlarm(minutes),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.alarm, size: 24),
          const SizedBox(height: 4),
          Text(
            '$minutes min',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  void _stopAlarm() async {
    // Stop vibration
    await _stopVibration();
    
    // Cancel the alarm
    await NotificationService().cancelAlarm(widget.event);
    
    // If recurring event, schedule next occurrence
    if (widget.event.isRecurring) {
      await _scheduleNextRecurringEvent();
    }
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm stopped')),
      );
      
      // Go back after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }
  
  void _snoozeAlarm(int minutes) async {
    // Stop current vibration
    await _stopVibration();
    
    // Show snooze confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snoozed for $minutes minutes')),
      );
    }
    
    // Snooze the alarm
    await NotificationService().snoozeAlarm(widget.event, minutes: minutes);
    
    // Close the alarm screen
    if (mounted) Navigator.pop(context);
  }
  
  Future<void> _scheduleNextRecurringEvent() async {
    try {
      // Calculate next year's date for birthday
      final nextDate = DateTime(
        widget.event.dateTime.year + 1,
        widget.event.dateTime.month,
        widget.event.dateTime.day,
        widget.event.dateTime.hour,
        widget.event.dateTime.minute,
      );
      
      // Create updated event
      final updatedEvent = widget.event.copyWith(dateTime: nextDate);
      
      // Save to database
      final hiveService = HiveService();
      await hiveService.updateEvent(updatedEvent);
      
      // Schedule new alarm
      final notificationService = NotificationService();
      await notificationService.scheduleAlarm(updatedEvent);
      
      print('✅ Next occurrence scheduled for ${updatedEvent.title} on $nextDate');
    } catch (e) {
      print('❌ Failed to schedule next occurrence: $e');
    }
  }
}