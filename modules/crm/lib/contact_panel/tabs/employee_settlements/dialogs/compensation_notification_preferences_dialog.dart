import 'package:crm/contact_panel/tabs/employee_settlements/widgets/compensation_notification_preferences_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

Future<void> showCompensationNotificationPreferencesDialog({
  required BuildContext context,
  required bool isMobile,
  required ThemeColors theme,
}) async {
  final useBottomSheet =
      isMobile || MediaQuery.sizeOf(context).width < 720;

  if (useBottomSheet) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.94,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return _NotificationPreferencesSurface(
              theme: theme,
              useDialogShape: false,
              onClose: () => Navigator.of(context).pop(),
              scrollController: scrollController,
            );
          },
        );
      },
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 28,
          
        ),
        backgroundColor: theme.dashboardContainer,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 820,
            maxHeight: 860,
          ),
          child: _NotificationPreferencesSurface(
            theme: theme,
            useDialogShape: true,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
    },
  );
}

class _NotificationPreferencesSurface extends StatelessWidget {
  final bool useDialogShape;
  final VoidCallback onClose;
  final ThemeColors theme;
  final ScrollController? scrollController;

  const _NotificationPreferencesSurface({
    required this.useDialogShape,
    required this.onClose,
    required this.theme,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(22),
        bottom: Radius.circular(useDialogShape ? 22 : 0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'compensation_notification_settings'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'close'.tr,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: const CompensationNotificationPreferencesCard(),
            ),
          ),
        ],
      ),
    );
  }
}
