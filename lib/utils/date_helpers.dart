import 'package:intl/intl.dart';

class DateHelpers {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }
  
  static String getTimeRemaining(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Now';
    }
  }
  
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  static DateTime getNextYearSameDate(DateTime date) {
    return DateTime(date.year + 1, date.month, date.day);
  }
  
  static List<DateTime> getDatesBetween(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    DateTime current = start;
    
    while (current.isBefore(end) || isSameDay(current, end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
}