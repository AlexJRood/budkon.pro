import 'package:core/kernel/kernel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/services/dnd_service.dart';


import 'client_tile.dart';

/// CRM "add client" button for the mobile top app bar. Extracted out of the
/// generic [AppBarMobile] so the shared bar carries no crm/crm_agent coupling;
/// resolved via the widget-slot registry only when `showClientToggle` is on.
class CrmAddClientButton extends ConsumerWidget {
  const CrmAddClientButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return SizedBox(
      height: 60,
      width: 60,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: () => showModalBottomSheet(
          backgroundColor: theme.dashboardContainer,
          context: context,
          isScrollControlled: true,
          builder: (_) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollController) {
                return moduleRegistry.slot('crm.addClientFormMobile')?.call(ctx, {'isClientView': false, 'sheetScrollController': scrollController}) ?? const SizedBox.shrink();
              },
            );
          },
        ),
        child: Icon(
          Icons.add_box_rounded,
          color: theme.textColor,
          size: 25,
        ),
      ),
    );
  }
}

/// Dock-styled variant of [CrmAddClientButton] for [TopBarDockRenderer].
/// The dock renderer passes [wrapIcon] so the button matches the dock style
/// without CRM needing to import private dock widget classes.
class CrmAddClientDockButton extends ConsumerWidget {
  final Widget Function(Widget icon, VoidCallback onTap, String label) wrapIcon;

  const CrmAddClientDockButton({super.key, required this.wrapIcon});

  void _open(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    showModalBottomSheet(
      backgroundColor: theme.dashboardContainer,
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) =>
            moduleRegistry.slot('crm.addClientFormMobile')?.call(ctx, {
              'isClientView': false,
              'sheetScrollController': scrollController,
            }) ??
            const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return wrapIcon(
      const Icon(Icons.add_box_rounded, size: 25),
      () => _open(context, ref),
      '',
    );
  }
}

/// CRM drag-to-reveal client list rendered below the mobile top app bar.
/// Extracted out of the generic [AppBarMobile]; resolved via the widget-slot
/// registry only when `showClientToggle` is on.
class CrmMobileClientList extends ConsumerWidget {
  const CrmMobileClientList({super.key});

  bool _shouldShowClientsForPayload(DndPayload? payload) {
    if (payload == null) return false;

    final dndService = DndService();

    return dndService.canDropOnAnyTarget(
      payload,
      const [
        DndTargetType.clientAppbar,
        DndTargetType.clientTransaction,
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final openTransactionClientId =
        ref.watch(clientTransactionsOpenForClientIdProvider);
    final dndService = DndService();

    return ValueListenableBuilder<DndPayload?>(
      valueListenable: dndService.activeDragPayload,
      builder: (context, activeDragPayload, _) {
        final shouldShowClientList =
            _shouldShowClientsForPayload(activeDragPayload);

        final hasOpenTransactionPanel = shouldShowClientList &&
            activeDragPayload != null &&
            openTransactionClientId != null;

        final clientListHeight = shouldShowClientList
            ? hasOpenTransactionPanel
                ? kClientListMobileExpandedWithTransactionsHeight
                : kClientListMobileCollapsedHeight
            : 0.0;

        return AnimatedContainer(
          duration: hasOpenTransactionPanel
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: clientListHeight,
          width: screenWidth,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: IgnorePointer(
            ignoring: !shouldShowClientList,
            child: SizedBox(
              height: clientListHeight,
              child: const ClientListAppBar(),
            ),
          ),
        );
      },
    );
  }
}
