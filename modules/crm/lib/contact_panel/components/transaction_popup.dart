import 'package:crm/contact_panel/tabs/dashboard/new_clients_view_full.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_history_provider.dart';
// ✅ correct conditional import syntax in one line:
import 'package:core/platform/platforms/html_utils_stub.dart'
if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

Future<void> showCustomMenutransaction(
    BuildContext context,
    GlobalKey transactionkey,
    WidgetRef ref,
    String clientId,
    String transactionId
    ) async {
  final theme = ref.read(themeColorsProvider);

  final RenderBox button =
  transactionkey.currentContext!.findRenderObject() as RenderBox;
  final RenderBox overlay =
  Overlay.of(context).context.findRenderObject() as RenderBox;

  final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
  final double leftPosition = buttonPosition.dx;
  final double topPosition = buttonPosition.dy + button.size.height;

  final selected = await showMenu<String>(
    context: context,
    menuPadding: const EdgeInsets.symmetric(vertical: 4),
    position: RelativeRect.fromLTRB(leftPosition, topPosition, leftPosition, topPosition),
    color: theme.adPopBackground,
    items: [
      PopupMenuItem<String>(
        value: 'details',
        child: Row(
          children: [
            AppIcons.sort(height: 15, width: 15, color: theme.textColor),
            const SizedBox(width: 4),
            Text("View details".tr,
              style: AppTextStyles.interMedium.copyWith(color: theme.textColor),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            AppIcons.pencil(height: 15, width: 15, color: theme.textColor),
            const SizedBox(width: 4),
            Text("Edit".tr,
              style: AppTextStyles.interMedium.copyWith(color: theme.textColor),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'invoice',
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right_rounded, size: 15),
            const SizedBox(width: 4),
            Text("Send Invoice".tr,
              style: AppTextStyles.interMedium.copyWith(color: theme.textColor),
            ),
          ],
        ),
      ),
    ],
  );

  // Handle selection AFTER the menu auto-closes
  switch (selected) {
    case 'details':
      ref.read(activeSectionProvider.notifier).state = 'komentarze';
      ref.read(navigationHistoryProvider.notifier).addPage('komentarze');
      updateUrl('/pro/clients/$clientId/komentarze');
      break;
    case 'edit':
    // TODO: open edit flow
      ref.read(activeSectionProvider.notifier).state = 'transakcje';
      ref.read(navigationHistoryProvider.notifier).addPage('transakcje');
      updateUrl('/pro/clients/$clientId/transakcje/$transactionId');
      break;
    case 'invoice':
    // TODO: open invoice flow
      ref.read(activeSectionProvider.notifier).state = 'transakcje';
      ref.read(navigationHistoryProvider.notifier).addPage('transakcje');
      updateUrl('/pro/clients/$clientId/transakcje/$transactionId');
      break;
  }
}

class Customiconbuttom extends ConsumerWidget {
  final String clientId;
  final String transactionId;
  const Customiconbuttom({super.key, required this.clientId,required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final key = GlobalKey();
    return SizedBox(
      child: IconButton(
        key: key,
        onPressed: () => showCustomMenutransaction(context, key, ref, clientId,transactionId),
        icon: AppIcons.moreVertical(color: theme.textColor),
      ),
    );
  }
}
