import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class AutomationPaletteDraggableItem extends ConsumerWidget {
  final String type;
  final String label;
  final String subtitle;
  final IconData icon;
  final Map<String, dynamic> data;
  final VoidCallback? onTapAdd;
  final bool longPressOnly;
  final bool enabled;

  const AutomationPaletteDraggableItem({
    super.key,
    required this.type,
    required this.label,
    this.subtitle = '',
    this.icon = Icons.play_circle_fill_rounded,
    this.data = const {},
    this.onTapAdd,
    this.longPressOnly = false,
    this.enabled = true,
  });

  Map<String, dynamic> get payload {
    return {
      'node_type': type,
      'type': type,
      'label': label,
      'data': {
        ...data,
        'label': label,
      },
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    final child = _PaletteTileBody(
      theme: theme,
      label: label,
      subtitle: subtitle,
      icon: icon,
      enabled: enabled,
      onTapAdd: onTapAdd,
    );

    if (!enabled) return child;

    final feedback = Material(
      color: Colors.transparent,
      child: Transform.translate(
        offset: const Offset(-18, -18),
        child: _DragFeedbackCard(
          theme: theme,
          label: label,
          subtitle: subtitle,
          icon: icon,
        ),
      ),
    );

    if (longPressOnly) {
      return LongPressDraggable<Map<String, dynamic>>(
        data: payload,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.42, child: child),
        child: child,
      );
    }

    return Draggable<Map<String, dynamic>>(
      data: payload,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.42, child: child),
      child: child,
    );
  }
}

class _PaletteTileBody extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTapAdd;

  const _PaletteTileBody({
    required this.theme,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.grab : SystemMouseCursors.basic,
      child: InkWell(
        onTap: enabled ? onTapAdd : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dashboardBoarder.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.themeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DefaultTextStyle(
                  style: TextStyle(color: theme.textColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.textColor.withValues(alpha: 0.58),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: theme.textColor.withValues(alpha: 0.44),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragFeedbackCard extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final String subtitle;
  final IconData icon;

  const _DragFeedbackCard({
    required this.theme,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.94,
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.themeColor.withValues(alpha: 0.72), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: theme.themeColor.withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.themeColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(color: theme.textColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.textColor.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
