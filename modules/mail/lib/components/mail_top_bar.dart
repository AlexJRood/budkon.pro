import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import '../utils/api_services.dart';
import '../utils/mail_filters.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/navigation_service.dart';

class MailTopBar extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool isTablet;
  final bool enableBulkSelection;

  const MailTopBar({
    super.key,
    required this.isMobile,
    this.isTablet = false,
    this.enableBulkSelection = false,
  });

  @override
  ConsumerState<MailTopBar> createState() => _MailTopBarState();
}

class _MailTopBarState extends ConsumerState<MailTopBar> {
  @override
  void dispose() {
    // Clear any snack bars when this widget is removed to avoid animation callbacks
    if (mounted) {
      scaffoldMessengerKey.currentState?.clearSnackBars();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final selectionMode = ref.watch(mailSelectionModeProvider);
    final selectedCount = ref.watch(selectedMailIdsProvider).length;
    final isSidebarVisible = ref.watch(mailSidebarVisibleProvider);
    final isTabletView = widget.isTablet;

    // Define common widgets for reuse
    // Hidden on mobile: sidebar toggle is not needed on small screens
    final sidebarToggle = widget.isMobile
        ? null
        : IconButton(
            onPressed: () {
              ref.read(mailSidebarVisibleProvider.notifier).state = !isSidebarVisible;
            },
            icon: Icon(
              isSidebarVisible ? Icons.menu_open : Icons.menu,
              color: theme.textColor,
            ),
            tooltip: isSidebarVisible ? 'Hide sidebar'.tr : 'Show sidebar'.tr,
          );

    final searchField = TextField(
      onChanged: (val) {
        ref.read(mailSearchProvider.notifier).state = val;
        ref.read(mailPageProvider.notifier).state = 1;
      },
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.dashboardContainer,
        hintText: 'Search...'.tr,
        hintStyle: TextStyle(color: theme.textColor, fontSize: 13),
        prefixIcon: Icon(Icons.search, color: theme.textColor, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.textColor.withAlpha(120)),
        ),
      ),
    );

    final selectionToggle = widget.enableBulkSelection
        ? IconButton(
            key: const ValueKey('email_selection_toggle'),
            icon: Icon(
              selectionMode ? Icons.check_box : Icons.check_box_outline_blank,
              color: selectionMode ? theme.themeColor : theme.textColor,
            ),
            tooltip: 'Toggle selection mode'.tr,
            onPressed: () {
              final newMode = !selectionMode;
              ref.read(mailSelectionModeProvider.notifier).state = newMode;
              if (!newMode) {
                ref.read(selectedMailIdsProvider.notifier).state = {};
              }
            },
          )
        : null;

    final refreshButton = !widget.isMobile
        ? IconButton(
            onPressed: () async {
              try {
                await ref.read(syncEmailsProvider.future);
                ref.invalidate(filteredEmailsProvider);

                final messengerState = scaffoldMessengerKey.currentState;
                if (messengerState != null && messengerState.mounted) {
                  messengerState.showSnackBar(
                    SnackBar(content: Text('✅ Synchronization completed'.tr)),
                  );
                }
              } catch (e) {
                final messengerState = scaffoldMessengerKey.currentState;
                if (messengerState != null && messengerState.mounted) {
                  messengerState.showSnackBar(
                    SnackBar(content: Text('${"❌ Sync error:".tr} $e')),
                  );
                }
              }
            },
            icon:
                AppIcons.refresh(color: theme.textColor, height: 20, width: 20),
            tooltip: 'Refresh'.tr,
          )
        : null;

    if (isTabletView) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                if (sidebarToggle != null) sidebarToggle,
                const Spacer(),
                if (selectionToggle != null) selectionToggle,
                if (refreshButton != null) refreshButton,
              ],
            ),
            const SizedBox(height: 8),
            searchField,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          if (sidebarToggle != null) sidebarToggle,
          const SizedBox(width: 8),
          Expanded(child: searchField),
          const SizedBox(width: 8),
          if (selectionToggle != null) selectionToggle,
          if (refreshButton != null) ...[
            const SizedBox(width: 8),
            refreshButton,
          ],
        ],
      ),
    );
  }
}
