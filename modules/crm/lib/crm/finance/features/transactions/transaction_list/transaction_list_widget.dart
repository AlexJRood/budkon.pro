
import 'package:crm/crm/finance/features/transactions/columns_transactions.dart';
import 'package:crm/crm/finance/features/transactions/transaction_list/selected_transaction_status_provider.dart';
import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

import '../../../../../pie_menu/revenue_crm.dart';

const defaultAvatarUrl = '\$configUrl/media/avatars/avatar.jpg';

class TransactionListWidget extends ConsumerWidget {
  final TransactionState data;
  final bool isMobile;
  const TransactionListWidget({
    super.key,
    required this.data,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final transactionsMap = {for (var tx in data.transactions) tx.id: tx};
    final selectedStatusName = ref.watch(selectedTransactionStatusProvider);

    final List<AgentTransactionModel> filteredTransactions;

    if (selectedStatusName == 'All') {
      filteredTransactions =
          data.statuses
              .expand((status) => status.transactionIndex)
              .map((id) => transactionsMap[id])
              .where((tx) => tx != null)
              .cast<AgentTransactionModel>()
              .toList();
    } else {
      filteredTransactions =
          data.statuses
              .where((status) => status.statusName == selectedStatusName)
              .expand((status) => status.transactionIndex)
              .map((id) => transactionsMap[id])
              .where((tx) => tx != null)
              .cast<AgentTransactionModel>()
              .toList();
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.dashboardContainer,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.textFieldColor,
                ),
                child: Row(
                  children: [
                    const SizedBox(width:50),
                    Expanded(
                      flex: 3,
                      child: Text('Name'.tr, style: _headerTextStyle(theme)),
                    ),
                    Expanded(
                      child: Text('Type'.tr, style: _headerTextStyle(theme)),
                    ),
                    Expanded(
                      child: Text('Status'.tr, style: _headerTextStyle(theme)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Email'.tr, style: _headerTextStyle(theme)),
                    ),
                    Expanded(
                      child: Text(
                        'Phone Number'.tr,
                        style: _headerTextStyle(theme),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
            Expanded(
              child:
                  filteredTransactions.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppLottie.noResults(size: 450),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 300,
                              height: 45,
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: () {},
                                child: AppIcons.add(color: theme.textColor),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView(
                        children: [
                          ...filteredTransactions.map((transaction) {
                            if (isMobile) {
                              return _buildMobileTile(transaction, theme);
                            }
                            return _buildDesktopTile(
                              context,
                              ref,
                              transaction,
                              theme,
                            );
                          }),
                          const SizedBox(height: 8),
                          Center(
                            child: SizedBox(
                              width: 300,
                              height: 45,
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: () {},
                                child: AppIcons.add(color: theme.textColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
            ),
            if (!isMobile)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.textFieldColor,
                ),
                child: Row(
                  children: [
                    Text(
                      'Showing ${filteredTransactions.length} out of ${filteredTransactions.length}'
                          .tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.85).toInt()),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: AppIcons.iosArrowLeft(
                        color: theme.textColor.withAlpha((255 * 0.85).toInt()),
                      ),
                      onPressed: () {},
                    ),
                    Text('1', style: TextStyle(color: theme.textColor)),
                    IconButton(
                      icon: AppIcons.iosArrowRight(
                        color: theme.textColor.withAlpha((255 * 0.85).toInt()),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerTextStyle(ThemeColors theme) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: theme.textColor,
    );
  }

  Widget _buildMobileTile(
    AgentTransactionModel transaction,
    ThemeColors theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.dashboardBoarder,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        collapsedBackgroundColor: theme.textFieldColor,
        backgroundColor: const Color.fromRGBO(87, 148, 221, 0.1),
        iconColor: theme.textColor.withAlpha((255 * 0.5).toInt()),
        leading: const Icon(
          Icons.arrow_forward_ios,
          color: Color.fromRGBO(145, 145, 145, 1),
        ),
        showTrailingIcon: false,
        collapsedIconColor: theme.textColor.withAlpha((255 * 0.5).toInt()),
        title: Text(
          transaction.name,
          style: TextStyle(color: theme.textColor, fontSize: 16),
        ),
        children: [
          _buildMobileInfoTile('Status', transaction.transactionType, theme),
          _buildMobileInfoTile('Email', transaction.client.name, theme),
          _buildMobileInfoTile('Phone', transaction.client.phoneNumber, theme),
          const Divider(),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_red_eye, color: theme.textColor),
                  Text(
                    "View profile".tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildMobileInfoTile(
    String title,
    String? value,
    ThemeColors theme,
  ) {
    return ListTile(
      title: Text(
        title.tr,
        style: TextStyle(color: theme.textColor.withAlpha((255 * 0.5).toInt())),
      ),
      trailing: Text(
        value ?? '-',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color.fromRGBO(161, 236, 230, 1),
        ),
      ),
    );
  }

  Widget _buildDesktopTile(
    BuildContext context,
    WidgetRef ref,
    AgentTransactionModel transaction,
    ThemeColors theme,
  ) {

    return Stack(
      children: [
        PieMenu(
           theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
          onPressedWithDevice: (kind){
            ref.read(isNavigateFromFinanceDraggableProvider.notifier)
                .state = (triggered: true, id: transaction.id);
            final routeName = ref.read(navigationService).currentPath;
            final baseRoute = removeContactSegment(routeName);

            if (routeName.contains('contact') &&
                routeName.contains('dashboard')) {
              ref.read(navigationService).beamPop();
              ref
                  .read(navigationService)
                  .openPopup(
                '$baseRoute/contact/${transaction.client.id}/dashboard',
                data: {'clientViewPop': transaction.client},
              );
            } else {
              ref
                  .read(navigationService)
                  .openPopup(
                '$baseRoute/contact/${transaction.client.id}/dashboard',
                data: {'clientViewPop': transaction.client},
              );
            }

          },
          actions: pieMenuCrmRevenues(
            ref: ref,
            action: transaction,
            actionId: transaction.id,
            context: context,
            textColor: theme.textColor,
          ),

          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: theme.textFieldColor,
            ),
            child: Row(
              children: [
                SizedBox(
                  child:
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        transaction.client.avatar ?? defaultAvatarUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        cacheWidth: 250,
                  ),
                ),
                ),
                const SizedBox(width:10),

                Expanded(
                  flex: 3,
                  child: Text(
                    transaction.name,
                    style: TextStyle(fontSize: 14, color: theme.textColor),
                  ),
                ),
                Expanded(
                  child: Text(
                    transaction.transactionType ?? '-',
                    style: TextStyle(fontSize: 14,
                     color: theme.textColor,
                    overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TransactionStatusDropdownField(
                        transactionId: transaction.id,
                        haveBorder: false,
                        haveLabel: false,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    transaction.client.email ?? '-',
                    style: TextStyle(fontSize: 14, color: theme.textColor,),
                  ),
                ),
                Expanded(
                  child: Text(
                    transaction.client.phoneNumber ?? '-',
                    style: TextStyle(fontSize: 14, color: theme.textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String removeContactSegment(String path) {
    // This removes the last '/contact/:id/dashboard' from the path
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }
}






class TransactionStatusDropdownField extends ConsumerWidget {
  final int transactionId;
  final bool haveBorder;
  final bool haveLabel;

  const TransactionStatusDropdownField({
    super.key,
    required this.transactionId,
    this.haveBorder = true,
    this.haveLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(transactionProvider);

    return SizedBox(
      height: 50,
      width: 250,
      child: state.when(
        data: (data) {
          final List<TransactionStatus> statuses = data.statuses;

          // bieżąca kolumna (status), w której jest transakcja
          final currentStatus = statuses.firstWhereOrNull(
            (s) => s.transactionIndex.contains(transactionId),
          );

          // pełny obiekt transakcji (potrzebny do moveTransaction)
          final AgentTransactionModel? tx =
              data.transactions.firstWhereOrNull((t) => t.id == transactionId);

          if (tx == null) {
            return Text('⚠️ Transaction not found', style: TextStyle(color: theme.textColor, 
                            overflow: TextOverflow.ellipsis,));
          }
          if (statuses.isEmpty) {
            return Text('⚠️ No statuses available', style: TextStyle(color: theme.textColor, 
                            overflow: TextOverflow.ellipsis,));
          }

          return DropdownButtonFormField<int?>(
            value: currentStatus?.id,
            borderRadius: BorderRadius.circular(10),
            dropdownColor: theme.dashboardContainer,
              icon: AppIcons.iosArrowDown(color: theme.textColor),
            decoration: InputDecoration(
              label: haveLabel
                  ? Text('Transaction status', style: TextStyle(color: theme.textColor, 
                            overflow: TextOverflow.ellipsis,))
                  : null,
              border: haveBorder
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                  : null,
              filled: false,
            ),
            items: [
              // Jeżeli chcesz wspierać "brak statusu", trzeba mieć kolumnę na "Unassigned"
              // albo dodać w notifierze metodę do zdjęcia statusu. Na razie pomijam NULL.
              ...statuses.map(
                (s) => DropdownMenuItem<int?>(
                  value: s.id,
                  child: Text(s.statusName, style: TextStyle(color: theme.textColor, 
                            overflow: TextOverflow.ellipsis,)),
                ),
              ),
            ],
            onChanged: (int? selectedId) async {
              if (selectedId == null) {
                // Jeśli chcesz obsłużyć "brak statusu" — daj znać, dorzucę wariant.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Brak statusu nieobsługiwany w tej wersji')),
                );
                return;
              }

              final newStatus = statuses.firstWhereOrNull((s) => s.id == selectedId);
              final oldStatus = currentStatus;

              // brak zmian
              if (newStatus == null || oldStatus?.id == newStatus.id) return;

              // używamy gotowej funkcji – backend domyślnie doda na koniec listy
              ref
                  .read(transactionProvider.notifier)
                  .moveTransaction(tx, newStatus.statusName, null);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('❌ Błąd: $err', style: TextStyle(color: theme.textColor)),
      ),
    );
  }
}
