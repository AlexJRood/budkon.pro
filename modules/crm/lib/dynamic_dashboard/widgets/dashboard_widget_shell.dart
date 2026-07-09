import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

enum _DashboardWidgetShellAction {
  settings,
  duplicate,
  remove,
}

class DashboardWidgetShell extends ConsumerWidget {
  const DashboardWidgetShell({
    super.key,
    required this.title,
    required this.child,
    required this.isEditMode,
    required this.onRemove,
    required this.onDuplicate,
    required this.handles,
    this.onSettings,
  });

  final String title;
  final Widget child;
  final bool isEditMode;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final VoidCallback? onSettings;
  final List<Widget> handles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final bool isRail = width < 135;
        final double pad = isRail ? 4 : 10;

        final chipColor = theme.adPopBackground.withAlpha(200);
        final iconColor = theme.textColor;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Widget content — always at full cell size.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 0,
                      left: pad,
                      right: pad,
                      bottom: pad,
                    ),
                    child: AbsorbPointer(
                      absorbing: isEditMode,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),

            // Semi-transparent overlay so the widget reads as inactive.
            if (isEditMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.adPopBackground.withAlpha(77),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

            // Drag indicator — top-left corner chip.
            if (isEditMode && !isRail)
              Positioned(
                top: 8,
                left: 8,
                child: _Chip(
                  color: chipColor,
                  iconColor: iconColor,
                  child: const Icon(Icons.drag_indicator_rounded, size: 14),
                ),
              ),

            // Action buttons — top-right corner chip.
            if (isEditMode)
              Positioned(
                top: 8,
                right: 8,
                child: isRail
                    ? _RailMenu(
                        onSettings: onSettings,
                        onDuplicate: onDuplicate,
                        onRemove: onRemove,
                        color: chipColor,
                        iconColor: iconColor,
                      )
                    : _ActionButtons(
                        onSettings: onSettings,
                        onDuplicate: onDuplicate,
                        onRemove: onRemove,
                        color: chipColor,
                        iconColor: iconColor,
                      ),
              ),

            ...handles,
          ],
        );
      },
    );
  }
}

// Small rounded chip used as the floating button background.
class _Chip extends StatelessWidget {
  const _Chip({required this.child, required this.color, this.iconColor});

  final Widget child;
  final Color color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: iconColor != null
              ? IconTheme(data: IconThemeData(color: iconColor), child: child)
              : child,
        ),
      ),
    );
  }
}

// Three action icon buttons grouped in a chip — shown on all non-rail widgets.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onSettings,
    required this.onDuplicate,
    required this.onRemove,
    required this.color,
    required this.iconColor,
  });

  final VoidCallback? onSettings;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      color: color,
      iconColor: iconColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.tune_rounded, onTap: onSettings),
          const SizedBox(width: 2),
          _Btn(icon: Icons.copy_rounded, onTap: onDuplicate),
          const SizedBox(width: 2),
          _Btn(icon: Icons.delete_outline_rounded, onTap: onRemove),
        ],
      ),
    );
  }
}

// Popup menu for rail-width widgets where there's no room for separate buttons.
class _RailMenu extends StatelessWidget {
  const _RailMenu({
    required this.onSettings,
    required this.onDuplicate,
    required this.onRemove,
    required this.color,
    required this.iconColor,
  });

  final VoidCallback? onSettings;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      color: color,
      iconColor: iconColor,
      child: PopupMenuButton<_DashboardWidgetShellAction>(
        tooltip: '',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert_rounded, size: 16),
        constraints: const BoxConstraints(minWidth: 160),
        onSelected: (action) {
          switch (action) {
            case _DashboardWidgetShellAction.settings:
              onSettings?.call();
              break;
            case _DashboardWidgetShellAction.duplicate:
              onDuplicate();
              break;
            case _DashboardWidgetShellAction.remove:
              onRemove();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _DashboardWidgetShellAction.settings,
            enabled: onSettings != null,
            child: _PopupRow(icon: Icons.tune_rounded, label: 'Settings'.tr),
          ),
          PopupMenuItem(
            value: _DashboardWidgetShellAction.duplicate,
            child: _PopupRow(icon: Icons.copy_rounded, label: 'duplicate_label'.tr),
          ),
          PopupMenuItem(
            value: _DashboardWidgetShellAction.remove,
            child: _PopupRow(icon: Icons.delete_outline_rounded, label: 'Remove'.tr),
          ),
        ],
      ),
    );
  }
}

class _PopupRow extends StatelessWidget {
  const _PopupRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// Small square icon button — disabled (faded) when onTap is null.
class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.35,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(child: Icon(icon, size: 15)),
          ),
        ),
      ),
    );
  }
}
