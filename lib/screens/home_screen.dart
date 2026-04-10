import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/hive_service.dart';
import '../models/important_event.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';
import '../widgets/event_card.dart';  // Add this import
import 'add_event_screen.dart';
import 'alarm_ringing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();
  final SchedulerService _schedulerService = SchedulerService();
  
  List<ImportantEvent> _events = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = _hiveService.getAllEvents();
    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }
  
  Future<void> _deleteEvent(ImportantEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _notificationService.cancelAlarm(event);
      await _hiveService.deleteEvent(event.id);
      await _loadEvents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${event.title}"')),
        );
      }
    }
  }
  
  void _showEventDetails(ImportantEvent event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  event.eventType.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, 'Date & Time', 
                DateFormat('MMMM dd, yyyy').format(event.dateTime)),
            _buildDetailRow(Icons.access_time, 'Time', 
                DateFormat('hh:mm a').format(event.dateTime)),
            if (event.description != null && event.description!.isNotEmpty)
              _buildDetailRow(Icons.description, 'Description', event.description!),
            _buildDetailRow(Icons.repeat, 'Recurring', event.isRecurring ? 'Yes (Yearly)' : 'No'),
            _buildDetailRow(Icons.volume_up, 'Sound', event.soundAsset.split('/').last),
            _buildDetailRow(Icons.vibration, 'Vibration', event.vibrateEnabled ? 'Enabled' : 'Disabled'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditEvent(event);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _testAlarm(event);
                    },
                    icon: const Icon(Icons.alarm),
                    label: const Text('Test Alarm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _testAlarm(ImportantEvent event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AlarmRingingScreen(event: event),
      ),
    );
  }
  
  void _navigateToAddEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEventScreen()),
    );
    if (result == true) {
      await _loadEvents();
      await _schedulerService.scheduleAllEvents();
    }
  }
  
  void _navigateToEditEvent(ImportantEvent event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(event: event),
      ),
    );
    if (result == true) {
      await _loadEvents();
      await _schedulerService.scheduleAllEvents();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFY'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPermissionsInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    // USING THE EVENT_CARD WIDGET HERE
                    return EventCard(
                      event: event,
                      onTap: () => _showEventDetails(event),
                      onDelete: () => _deleteEvent(event),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEvent(),
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Text(
              '🔔',
              style: TextStyle(fontSize: 64, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Important Events Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add birthdays, appointments, or\nimportant moments to remember',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddEvent(),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Event'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPermissionsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('For alarm to work properly, please grant:'),
            SizedBox(height: 12),
            Text('• Notifications - To show alerts'),
            Text('• Exact Alarms - For precise timing'),
            Text('• Full Screen Intent - To wake screen'),
            Text('• Ignore Battery Optimization - Prevent delays'),
            SizedBox(height: 12),
            Text(
              'Without these, alarms may not work correctly!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
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
              await NotificationService().openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}