import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/important_event.dart';
import '../app/app_colors.dart';

class EventCard extends StatelessWidget {
  final ImportantEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPast = event.isPast;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Dismissible(
        key: Key(event.id),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Event type icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: event.eventType.lightColor.withOpacity(isPast ? 0.3 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        event.eventType.icon,
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.black.withOpacity(isPast ? 0.5 : 1), // Fixed: Use color with opacity
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                            color: isPast 
                                ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isPast 
                                  ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                                  : AppColors.lightSubtext,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(event.dateTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: isPast 
                                    ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                                    : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                        if (event.description != null && event.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              event.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isPast 
                                    ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                                    : AppColors.lightSubtext,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status indicator
                  if (!isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.isToday ? Colors.red.shade700 : Colors.green.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.isToday ? 'Today' : _getTimeUntil(event),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (event.isRecurring)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.repeat,
                        size: 16,
                        color: isPast 
                            ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                            : AppColors.accentGreen,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  String _getTimeUntil(ImportantEvent event) {
    final difference = event.timeRemaining;
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Soon';
    }
  }
}