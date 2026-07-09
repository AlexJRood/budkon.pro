import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

/// Shared card container used across CRM panel screens.
class CrmDashboardCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CrmDashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.textColor),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.textColor),
          child: child,
        ),
      ),
    );
  }
}

/// Small icon badge used in card headers.
class CrmDashboardIconBubble extends ConsumerWidget {
  final IconData icon;

  const CrmDashboardIconBubble({super.key, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: theme.textColor),
    );
  }
}

/// Inline info pill with icon + label. Labels are NOT auto-translated; callers handle `.tr`.
class CrmDashboardPill extends ConsumerWidget {
  final String label;
  final IconData icon;

  const CrmDashboardPill({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact pill without icon, used for tags and labels. Labels are NOT auto-translated.
class CrmDashboardMiniPill extends ConsumerWidget {
  final String label;

  const CrmDashboardMiniPill({super.key, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor.withAlpha(190),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Interactive tab / selector pill — shared between employee panel tabs and settlement tabs.
class CrmDashboardTabPill extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const CrmDashboardTabPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final color = selected ? theme.themeColor : theme.textColor;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? theme.themeColor.withAlpha(28) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? theme.themeColor.withAlpha(140) : theme.dashboardBoarder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
