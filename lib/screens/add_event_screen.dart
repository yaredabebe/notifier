import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/important_event.dart';
import '../models/event_type.dart';
import '../database/hive_service.dart';
import '../services/notification_service.dart';
import 'alarm_ringing_screen.dart';  // Add this import

class AddEventScreen extends StatefulWidget {
  final ImportantEvent? event;
  
  const AddEventScreen({super.key, this.event});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  EventType _selectedType = EventType.birthday;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  bool _isRecurring = false;
  int _snoozeDuration = 5;
  String _selectedSound = 'assets/sounds/alarm_sound.mp3';
  bool _vibrateEnabled = true;
  
  final List<String> _availableSounds = [
    'assets/sounds/alarm_sound.mp3',
    'assets/sounds/gentle_reminder.mp3',
    'assets/sounds/urgent_bell.mp3',
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _loadEventData();
    }
  }
  
  void _loadEventData() {
    final event = widget.event!;
    _titleController.text = event.title;
    _descriptionController.text = event.description ?? '';
    _selectedType = event.eventType;
    _selectedDateTime = event.dateTime;
    _isRecurring = event.isRecurring;
    _snoozeDuration = event.snoozeDuration;
    _selectedSound = event.soundAsset;
    _vibrateEnabled = event.vibrateEnabled;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    final event = ImportantEvent(
      id: widget.event?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      dateTime: _selectedDateTime,
      eventType: _selectedType,
      isRecurring: _isRecurring,
      snoozeDuration: _snoozeDuration,
      soundAsset: _selectedSound,
      vibrateEnabled: _vibrateEnabled,
    );
    
    final hiveService = HiveService();
    final notificationService = NotificationService();
    
    // Cancel old alarm if editing
    if (widget.event != null) {
      await notificationService.cancelAlarm(widget.event!);
    }
    
    // Save to database
    await hiveService.saveEvent(event);
    
    // Schedule new alarm (only if future date)
    if (event.dateTime.isAfter(DateTime.now())) {
      await notificationService.scheduleAlarm(event);
    } else if (event.isRecurring) {
      // For past recurring events, show warning
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Past Date'),
            content: const Text('This event date is in the past. For recurring events, it will be scheduled for next year.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
  
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Mom\'s Birthday, Doctor Appointment',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add notes or details',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Event type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: EventType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(type.displayName),
                          avatar: Text(type.icon),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: type == EventType.birthday
                              ? Colors.pink.shade100
                              : type == EventType.appointment
                                  ? Colors.blue.shade100
                                  : Colors.purple.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date & Time
            Card(
              child: InkWell(
                onTap: _selectDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today, color: Colors.red.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date & Time',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDateTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(_selectedDateTime),
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Recurring switch
            Card(
              child: SwitchListTile(
                title: const Text('Recurring Event'),
                subtitle: Text(
                  _selectedType == EventType.birthday 
                      ? 'Remind me every year on this date'
                      : 'Remind me weekly',
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.repeat, color: Colors.green.shade700),
                ),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() => _isRecurring = value);
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Snooze duration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Snooze Duration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 5, label: Text('5 min')),
                              ButtonSegment(value: 10, label: Text('10 min')),
                              ButtonSegment(value: 15, label: Text('15 min')),
                              ButtonSegment(value: 30, label: Text('30 min')),
                            ],
                            selected: {_snoozeDuration},
                            onSelectionChanged: (Set<int> selection) {
                              setState(() => _snoozeDuration = selection.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sound selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alarm Sound',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSound,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.volume_up),
                      ),
                      items: _availableSounds.map((sound) {
                        return DropdownMenuItem(
                          value: sound,
                          child: Text(sound.split('/').last.replaceAll('_', ' ').replaceAll('.mp3', '')),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSound = value!);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Add custom sound picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Custom sound picker coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.music_note),
                      label: const Text('Add Custom Sound'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Vibration toggle
            Card(
              child: SwitchListTile(
                title: const Text('Enable Vibration'),
                subtitle: const Text('Vibrate when alarm rings'),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.vibration, color: Colors.orange.shade700),
                ),
                value: _vibrateEnabled,
                onChanged: (value) {
                  setState(() => _vibrateEnabled = value);
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Preview button
            ElevatedButton.icon(
              onPressed: () {
                _showPreview();
              },
              icon: const Icon(Icons.preview),
              label: const Text('Preview Alarm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showPreview() {
    final tempEvent = ImportantEvent(
      id: 'preview',
      title: _titleController.text.trim().isEmpty ? 'Test Event' : _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      dateTime: DateTime.now(),
      eventType: _selectedType,
      isRecurring: false,
      snoozeDuration: _snoozeDuration,
      soundAsset: _selectedSound,
      vibrateEnabled: _vibrateEnabled,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AlarmRingingScreen(event: tempEvent),
      ),
    );
  }
}