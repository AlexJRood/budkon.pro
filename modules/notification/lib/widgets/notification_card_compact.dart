// notification/widgets/notification_card_compact.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';

class NotificationCardCompact extends ConsumerWidget {
  final String title;
  final String subtitle;
  final DateTime? time;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  const NotificationCardCompact({
    super.key,
    required this.title,
    required this.subtitle,
    this.time,
    this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null)
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: (iconColor ?? theme.dashboardContainer).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor ?? theme.dashboardContainer),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textColor.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (time != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('MMM d').format(time!),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}