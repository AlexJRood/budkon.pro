import 'dart:ui' as ui;
import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/tabs/dashboard/new_clients_view_full.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
  if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';

import 'package:core/common/chrome/back_button.dart';


// ⬇️ Twoje providery i model transakcji
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/contact_panel/tabs/transactions/tx_client_provider.dart';

class AppBarMobileTransaction extends ConsumerWidget {
  final bool isTransactionSection;
  final bool showTransactions;
  final int clientId;

  const AppBarMobileTransaction({
    super.key,
    required this.clientId,
    this.isTransactionSection = false,
    this.showTransactions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    final screenWidth = MediaQuery.of(context).size.width;

    const double maxWidth = 1920, minWidth = 480;
    const double maxLogoSize = 30, minLogoSize = 22;
    double logoSize = ((screenWidth - minWidth) / (maxWidth - minWidth)) *
            (maxLogoSize - minLogoSize) +
        minLogoSize;
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);

    final theme = ref.read(themeColorsProvider);
    final color = theme.textColor;

    final selectedTx = showTransactions ? ref.watch(selectedTransactionProvider(clientId)) : null;
    final txAsync = showTransactions
        ? ref.watch(transactionListProvider(clientId))
        : const AsyncValue<List<AgentTransactionModel>>.data([]);

    String txLabel(AgentTransactionModel? tx) {
      if (tx == null) return 'Select transaction'.tr;
      return '${tx.name} • ${tx.isSeller ? 'sell'.tr : 'buy'.tr}';
    }

    Future<void> applyTransaction(AgentTransactionModel tx) async {
      // 1) zapisz wybór transakcji (scoped per client)
      ref.read(selectedTransactionIdProvider(clientId).notifier).state = tx.id;

      // 2) ustaw "otwartą" transakcję – wiele widoków słucha tego providera
      ref.read(openTransactionIdProvider.notifier).state = tx.id.toString();

      // 3) upewnij się, że jesteśmy w sekcji transakcji
      ref.read(activeSectionProvider.notifier).state = 'transakcje';

      // 4) Twoja logika filtrów (jak było)
      if (!tx.isSeller) {
        final notifier = ref.read(filterProvider.notifier);
        notifier.setClientId('', ref);
        notifier.filteredScope(clientId, tx.id, ref);
        notifier.setSavedSearches(null, ref, tx.id);
      }

      // 5) URL
      updateUrl('/pro/clients/$clientId/transakcje/${tx.id}');
    }

    Future<void> openTxPicker() async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) => ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Material(
                color: theme.dashboardContainer,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 42, height: 4,
                      decoration: BoxDecoration(
                        color: theme.dashboardBoarder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text('Select transaction'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 16, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: theme.textColor),
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: txAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('${'error_message'.tr}$e', style: TextStyle(color: theme.textColor))),
                        data: (transactions) {
                          if (transactions.isEmpty) {
                            return Center(child: Text('no_transactions'.tr, style: TextStyle(color: theme.textColor)));
                          }
                          return ListView.separated(
                            controller: controller,
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: theme.dashboardBoarder),
                            itemBuilder: (_, i) {
                              final tx = transactions[i];
                              final isSel = selectedTx?.id == tx.id;
                              return ListTile(
                                title: Text(
                                  txLabel(tx),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                onTap: () async {
                                  await applyTransaction(tx);
                                  Navigator.pop(context);
                                },
                                trailing: isSel
                                  ? Icon(Icons.check, color: theme.textColor)
                                  : null,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: () {
                            final routeName = ref.read(navigationService).currentPath;
                            ref.read(navigationService).pushNamedScreen('$routeName${Routes.addClientForm}');
                          },
                          child: AppIcons.add(color: theme.textColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    Widget? maybeCenterDropdown() {
      if (!isTransactionSection) return null;
      return SizedBox(
        height: 60,
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10,
          onPressed: openTxPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz, color: color, size: 18),
              const SizedBox(width: 8),
              txAsync.when(
                loading: () => Text('Loading...'.tr, style: TextStyle(color: color)),
                error:  (_, __) => Text('loading_error'.tr, style: TextStyle(color: color)),
                data:  (_) => Text(txLabel(selectedTx), style: TextStyle(color: color, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more, color: color, size: 18),
            ],
          ),
        ),
      );
    }

    return Container(
      height: TopAppBarSize.resolve(context),
      width: screenWidth,
      color: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: theme.sidebar,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BackButtonHously(),

                if (isTransactionSection) ...[
                  const Spacer(),
                  maybeCenterDropdown()!,
                  const Spacer(),
                  const SizedBox(width:60, height:60),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
