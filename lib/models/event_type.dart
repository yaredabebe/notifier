import 'package:flutter/material.dart';

enum EventType {
  birthday,
  appointment,
  meeting,
  anniversary,
  custom;

  String get displayName {
    switch (this) {
      case EventType.birthday:
        return 'Birthday';
      case EventType.appointment:
        return 'Appointment';
      case EventType.meeting:
        return 'Meeting';
      case EventType.anniversary:
        return 'Anniversary';
      case EventType.custom:
        return 'Important';
    }
  }
  
  String get icon {
    switch (this) {
      case EventType.birthday:
        return '🎂';
      case EventType.appointment:
        return '📅';
      case EventType.meeting:
        return '💼';
      case EventType.anniversary:
        return '💝';
      case EventType.custom:
        return '⭐';
    }
  }
  
  Color get color {
    switch (this) {
      case EventType.birthday:
        return Colors.pink;
      case EventType.appointment:
        return Colors.blue;
      case EventType.meeting:
        return Colors.orange;
      case EventType.anniversary:
        return Colors.purple;
      case EventType.custom:
        return Colors.red;
    }
  }
  
  Color get lightColor {
    switch (this) {
      case EventType.birthday:
        return Colors.pink.shade100;
      case EventType.appointment:
        return Colors.blue.shade100;
      case EventType.meeting:
        return Colors.orange.shade100;
      case EventType.anniversary:
        return Colors.purple.shade100;
      case EventType.custom:
        return Colors.red.shade100;
    }
  }
}