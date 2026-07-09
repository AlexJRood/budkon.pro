import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_docs_view.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_view.dart';
import 'package:crm/contact_panel/tabs/transactions/view_provider.dart';
import 'package:crm/data/add_field/edit_sell_offer_provider.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/screens/feed_pop/nm_feed_pop_full_page.dart';
import 'package:core/platform/api/api_buttons.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'tx_client_provider.dart';

final isDropdownExpandedProvider = StateProvider<bool>((ref) => false);

class TransactionSectionMobile extends ConsumerStatefulWidget {
  final int id;
  final String activeSection;
  final String? selectedTransactionId; // opcjonalny preselect z URL
  final String? activeAd;

  const TransactionSectionMobile({
    super.key,
    required this.id,
    required this.activeSection,
    this.selectedTransactionId,
    this.activeAd,
  });

  @override
  ConsumerState<TransactionSectionMobile> createState() =>
      TransactionSectionMobileState();
}

class TransactionSectionMobileState
    extends ConsumerState<TransactionSectionMobile> {
  bool _prefilled = false; // ← strażnik, żeby wykonać tylko raz
  ProviderSubscription? _txSub;
  @override
  void initState() {
    super.initState();

    // Odrocz modyfikację providera (po buildzie) – BEZ didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _prefilled) return;
      _prefilled = true;

      final preselect =
          (widget.selectedTransactionId?.trim().isNotEmpty ?? false)
              ? widget.selectedTransactionId!.trim()
              : widget.activeAd?.trim();

      final id = int.tryParse(preselect ?? '');
      debugPrint('This is the id =========> $id');

      if (id != null) {
        ref.read(selectedTransactionIdProvider(widget.id).notifier).state = id;
      }
    });
  }

  @override
  void dispose() {
    _txSub?.close();
    super.dispose();
  }

  Future<void> setTransaction(AgentTransactionModel transaction) async {
    if (!mounted) return;
    // Set selected tx in Riverpod
    ref.read(selectedTransactionIdProvider(widget.id).notifier).state =
        transaction.id;
    if (!mounted) return;
    if (transaction.isSeller == false) {
      final notifier = ref.read(filterProvider.notifier);
      if (!mounted) return;
      notifier.setClientId('', ref);
      if (!mounted) return;
      notifier.filteredScope(widget.id, transaction.id, ref);
      if (!mounted) return;
      notifier.setSavedSearches(null, ref, transaction.id);
    }
    if (!mounted) return;
    // Keep URL in sync
    updateUrl('/pro/clients/${widget.id}/transakcje/${transaction.id}');
  }

  @override
  Widget build(BuildContext context) {
    // Watch the transaction list to handle loading/error states
    final transactionsAsync = ref.watch(transactionListProvider(widget.id));
    final selectedTxId = ref.watch(selectedTransactionIdProvider(widget.id));
    debugPrint('TransactionSectionMobile - Client ID: ${widget.id}');
    debugPrint('TransactionSectionMobile - Selected Tx ID: $selectedTxId');

    debugPrint(
      'TransactionSectionMobile - Preselect from props: ${widget.selectedTransactionId}',
    );
    debugPrint('TransactionSectionMobile - Active Ad: ${widget.activeAd}');
    return transactionsAsync.when(
      data: (transactions) {
        // If we have a preselected ID but no transaction object yet, find it
        debugPrint(
          '[TransactionSectionMobile] txIds=${transactions.map((e) => e.id).toList()} selectedTxId=$selectedTxId',
        );

        if (selectedTxId != null) {
          final selectedTx = transactions.firstWhereOrNull(
            (t) => t.id == selectedTxId,
          );
          debugPrint('This is the value =====> $selectedTx');
          if (selectedTx != null) {
            return TransactionView(
              isMobile: true,
              key: ValueKey(selectedTx.id),
              transaction: selectedTx,
              clientId: widget.id,
              type:
                  selectedTx.isSeller
                      ? TransactionType.sell
                      : TransactionType.buy,
            );
          }
        }

        // Check if we should auto-select first transaction when none is selected
        if (widget.selectedTransactionId == null &&
            widget.activeAd == null &&
            transactions.isNotEmpty) {
          // Optionally auto-select first transaction
          return Center(child: Text('select_transaction_from_list'.tr));
        }

        return Center(child: Text('no_transaction_selected'.tr));
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) =>
              Center(child: Text('${'error_loading_transactions'.tr} $error'.tr)),
    );
  }
}

class AdActionsPanel extends ConsumerWidget {
  final int? offerId; // ← może być null
  final double buttonHeight;
  final double spacing;
  final String baseUrl;

  const AdActionsPanel({
    super.key,
    required this.offerId,
    this.buttonHeight = 40,
    this.spacing = 10,
    this.baseUrl = 'https://www.superbee.cloud',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final vm = ref.watch(viewModeControllerProvider(TransactionType.sell));
    final mode = vm.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (mode == TransactionViewMode.draft) ...[
          MobileFloatingActions(
            adId: offerId!.toInt(), // the same id you pass on desktop
            theme: theme,
          ),

          SizedBox(height: 2),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(6)),
              color: theme.textFieldColor,
            ),
            height: 45,
            width: 45,
            child: ApiButton(
              buttonHeight: 45,
              endpoint: '$baseUrl/portal/draft/publish/${offerId ?? ""}/',
              icon: AppIcons.sendAbove(color: theme.textColor),
              // label: 'Publish',
              hasToken: true,
              method: ApiMethod.post,
            ),
          ),

          /// Version 2.0 ///

          // SizedBox(height: 2),

          // Container(
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.all(Radius.circular(6)),
          //   color: theme.textFieldColor,
          //   ),
          //   height: 45,
          //   width: 45,
          //   child: ApiButton(
          //     buttonHeight: 45,
          //     endpoint: '$baseUrl/portal/draft/publish-swo/${offerId ?? ""}',
          //     icon: AppIcons.check(color: theme.textColor),
          //     // label: 'Add to swo',
          //     hasToken: true,
          //     method: ApiMethod.post,
          //   ),
          // ),
        ],

        if (mode == TransactionViewMode.docs) ...[],

        SizedBox(height: 2),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            color: theme.textFieldColor,
          ),
          height: 45,
          width: 45,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: () => _openViewSheet(context, ref),
            child: SizedBox(
              height: 25,
              width: 25,
              child: AppIcons.viewList(color: theme.textColor),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openViewSheet(BuildContext context, WidgetRef ref) async {
  await showHouslyBottomSheet(
    context: context,
    ref: ref,
    title: 'View'.tr,
    initialChildSize: 0.75,
    minChildSize: 0.35,
    maxChildSize: 0.92,
    bodyBuilder: (ctx, ref, controller) {
      // Non-scrollable content? Wrap in SingleChildScrollView to enable sheet drag + internal scroll.
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ViewModeTransaction(
              isMobile: true,
              isClientView: true,
              type:
                  TransactionType
                      .sell, // lub sell w innym miejscu (patrz AdActionsPanel)
            ),

            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

class MobileFloatingActions extends ConsumerWidget {
  const MobileFloatingActions({
    super.key,
    required this.adId,
    required this.theme,
    this.adFeedPop,
  });

  final int adId;
  final ThemeColors theme;
  final dynamic adFeedPop; // optional, not used here but kept for parity

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = ref.watch(adEditingProvider(adId));

    // NOT EDITING → one small pencil button (enter edit + preload form data)
    if (!isEditing) {
      return _RoundIconButton(
        theme: theme,
        icon: AppIcons.pencil(color: theme.textColor),
        onPressed: () async {
          debugPrint('This is the Id Mobile $adId');
          ref.read(adEditingProvider(adId).notifier).state = true;
          await ref
              .read(crmEditSellOfferProvider(adId).notifier)
              .loadOfferData(adId, ref);
        },
      );
    }

    // EDITING → two small buttons: Save and Cancel
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          theme: theme,
          icon: AppIcons.check(color: theme.textColor),
          onPressed: () async {
            final ok = await ref
                .read(crmEditSellOfferProvider(adId).notifier)
                .sendData(context, adId);

            if (ok == true) {
              await ref
                  .read(crmEditSellOfferProvider(adId).notifier)
                  .loadOfferData(adId, ref);

              final newState = ref.read(crmEditSellOfferProvider(adId));
              if (newState.serverImageUrls.isNotEmpty) {
                ref.read(adMainImageUrlProvider(adId).notifier).state =
                    newState.serverImageUrls.first;
              } else {
                ref.read(adMainImageUrlProvider(adId).notifier).state = '';
              }

              // Exit edit mode only on success
              ref.read(adEditingProvider(adId).notifier).state = false;
            }
            // On error: stays in edit mode (state.fieldErrors already populated)
          },
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          theme: theme,
          icon: AppIcons.close(color: theme.textColor),
          onPressed: () {
            ref.read(adEditingProvider(adId).notifier).state = false;
            context.showSnackBar('edit_cancelled_message'.tr);
          },
        ),
      ],
    );
  }
}

/// Small rounded square button used above
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.theme,
    required this.icon,
    required this.onPressed,
  });

  final ThemeColors theme;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      height: 45,
      child: Container(
        decoration: BoxDecoration(
          color: theme.textFieldColor,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10.copyWith(
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(theme.textFieldColor),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          onPressed: onPressed,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
