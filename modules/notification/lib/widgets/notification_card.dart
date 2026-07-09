// notification/widgets/notification_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import '../model/notification_model.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
  
    IconData typeIcon = Icons.notifications_none;
    Color? iconColor;
    
    if (notification.contentType == 77) { 
      typeIcon = Icons.assignment;
      iconColor = Colors.orange;
    } else if (notification.contentType == 62) { 
      typeIcon = Icons.chat_bubble_outline;
      iconColor = Colors.blue;
    } else if (notification.contentType == 267) { 
      typeIcon = Icons.email_outlined;
      iconColor = Colors.green;
    } else if (notification.contentType == 120 || notification.contentType == 122) { // Wall
      typeIcon = Icons.wallpaper;
      iconColor = Colors.purple;
    } else if (notification.contentType == 50) { 
      typeIcon = Icons.search;
      iconColor = Colors.teal;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left section - Icon
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  typeIcon,
                  size: 20,
                  color: iconColor ?? theme.dashboardContainer,
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textColor.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: theme.textColor.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notification.createAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (notification.image != null && notification.image!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    notification.image!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.withOpacity(0.2),
                      child: const Icon(Icons.broken_image, size: 24),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 7) {
        return DateFormat('MMM d').format(dateTime);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }
}