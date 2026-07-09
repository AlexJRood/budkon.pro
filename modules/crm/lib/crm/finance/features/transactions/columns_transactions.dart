// ignore_for_file: deprecated_member_use

import 'package:crm/crm/finance/features/transactions/transaction_card.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:crm/pie_menu/revenue_crm.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

import '../../components/custom_vertical_divider.dart';

final isNavigateFromFinanceDraggableProvider =
    StateProvider<({bool triggered, int? id})>(
      (ref) => (triggered: false, id: null),
    );

class DraggableColumn extends StatelessWidget {
  final String status;
  final List<AgentTransactionModel> transactions;
  final void Function(String) onAcceptColumn;
  final void Function(AgentTransactionModel transaction, int newIndex)
  onReorder;
  final void Function(
    AgentTransactionModel transaction,
    String newStatus,
    int? newIndex,
  )
  onMove;
  final WidgetRef ref;
  final void Function(AgentTransactionModel transaction)
  onTransactionSelected; // Dodajemy ten parametr

  const DraggableColumn({
    super.key,
    required this.status,
    required this.transactions,
    required this.onAcceptColumn,
    required this.onReorder,
    required this.onMove,
    required this.ref,
    required this.onTransactionSelected, // Dodajemy ten parametr
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double quarterScreenHeight = screenHeight / 4 * 3;
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final theme = ref.read(themeColorsProvider);
    final nav = ref.read(navigationService);
    final path = nav.currentPath == '/' ? '' : nav.currentPath;
    double screenWidth = MediaQuery.of(context).size.width;

    // Użycie:
    final double halfScreenSize = calculateDynamicSize(screenWidth);

    return DragTarget<String>(
      onAccept: onAcceptColumn,
      builder: (context, candidateData, rejectedData) {
        return Row(
          children: [
            if (candidateData.isNotEmpty)
              Container(
                color: AppColors.light50,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Material(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: AppColors.light25,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.dark50,
                            offset: Offset(0, 4),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 50,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              gradient:
                                  candidateData.isNotEmpty
                                      ? CrmGradients.loginGradient
                                      : CrmGradients.adGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                status,
                                style: AppTextStyles.interMedium14.copyWith(
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ),
                          ...transactions.map((transaction) {
                            return SizedBox(
                              width: 300,
                              // height: 50,
                              child: TransactionCard(
                                transaction: transaction,
                                hasDelete: false,
                                key: ValueKey(
                                  transaction.id,
                                ), // Unique key for each transaction
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            LongPressDraggable<String>(
              data: status,
              feedback: Material(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppColors.light25,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.dark50,
                        offset: Offset(0, 4),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          gradient:
                              candidateData.isNotEmpty
                                  ? CrmGradients.loginGradient
                                  : CrmGradients.adGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            status,
                            style: AppTextStyles.interMedium14.copyWith(
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ),
                      ...transactions.map((transaction) {
                        return SizedBox(
                          width: 300,
                          // height: 50,
                          child: TransactionCard(
                            transaction: transaction,
                            hasDelete: false,
                            key: ValueKey(
                              transaction.id,
                            ), // Unique key for each transaction
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              child: Row(
                children: [
                  DragTarget<AgentTransactionModel>(
                    onWillAccept: (transaction) => true,
                    onAccept:
                        (transaction) => onMove(
                          transaction,
                          status,
                          null,
                        ), // Null oznacza, że element trafi na koniec listy
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        width: 300,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color:
                              candidateData.isNotEmpty
                                  ? AppColors.light50
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Text(
                                status,
                                style: AppTextStyles.interMedium14.copyWith(
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    ...transactions.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final transaction = entry.value;

                                      final card = SizedBox(
                                        width: 300,
                                        child: TransactionCard(
                                          transaction: transaction,
                                          key: ValueKey(transaction.id),
                                          hasDelete: false,
                                        ),
                                      );

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
                                            key: ValueKey(transaction.id),
                                            onPressedWithDevice: (kind) {
                                              if (kind ==
                                                      PointerDeviceKind.mouse ||
                                                  kind ==
                                                      PointerDeviceKind.touch) {
                                                ref
                                                    .read(
                                                      isNavigateFromFinanceDraggableProvider
                                                          .notifier,
                                                    )
                                                    .state = (
                                                  triggered: true,
                                                  id: transaction.id,
                                                );

                                                final notifier = ref.read(
                                                  filterProvider.notifier,
                                                );
                                                notifier.setClientId('', ref);
                                                notifier.filteredScope(
                                                  transaction.client.id,
                                                  transaction.id,
                                                  ref,
                                                );
                                                notifier.setSavedSearches(
                                                  null,
                                                  ref,
                                                  transaction.id,
                                                );

                                                final routeName =
                                                    ref
                                                        .read(navigationService)
                                                        .currentPath;
                                                final baseRoute =
                                                    removeContactSegment(
                                                      routeName,
                                                    );

                                                if (routeName.contains(
                                                      'contact',
                                                    ) &&
                                                    routeName.contains(
                                                      'dashboard',
                                                    )) {
                                                  ref
                                                      .read(navigationService)
                                                      .beamPop();
                                                  ref
                                                      .read(navigationService)
                                                      .pushNamedScreen(
                                                        '$baseRoute/contact/${transaction.client.id}/dashboard',
                                                        data: {
                                                          'clientViewPop':
                                                              transaction
                                                                  .client,
                                                        },
                                                      );
                                                } else {
                                                  ref
                                                      .read(navigationService)
                                                      .openPopup(
                                                        '$baseRoute/contact/${transaction.client.id}/dashboard',
                                                        data: {
                                                          'clientViewPop':
                                                              transaction
                                                                  .client,
                                                        },
                                                      );
                                                }
                                              }
                                            },

                                            actions: pieMenuCrmRevenues(
                                              ref: ref,
                                              action: transaction,
                                              actionId: transaction.id,
                                              context: context,
                                              textColor: theme.textColor,
                                            ),
                                            child: DragTarget<
                                              AgentTransactionModel
                                            >(
                                              onWillAccept: (incoming) => true,
                                              onAccept: (incomingTransaction) {
                                                // Przenosimy transakcję na nową pozycję
                                                onMove(
                                                  incomingTransaction,
                                                  status,
                                                  index,
                                                );
                                              },
                                              builder: (
                                                context,
                                                candidateData,
                                                rejectedData,
                                              ) {
                                                return Column(
                                                  children: [
                                                    if (candidateData
                                                        .isNotEmpty)
                                                      IgnorePointer(
                                                        ignoring:
                                                            true, // placeholder nieklikalny
                                                        child: Opacity(
                                                          opacity:
                                                              0.8, // delikatnie „ghost”
                                                          child: SizedBox(
                                                            width: 300,
                                                            child: TransactionCard(
                                                              transaction:
                                                                  candidateData
                                                                      .first!, // ← to jest ta przeciągana karta
                                                              hasDelete: false,
                                                              key: ValueKey(
                                                                'ghost-${candidateData.first!.id}',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                    isMobile
                                                        ? LongPressDraggable<
                                                          AgentTransactionModel
                                                        >(
                                                          data: transaction,
                                                          feedback: Material(
                                                            color:
                                                                Colors
                                                                    .transparent,
                                                            child: Opacity(
                                                              opacity: 0.7,
                                                              child: card,
                                                            ),
                                                          ),
                                                          childWhenDragging:
                                                              Opacity(
                                                                opacity: 0.5,
                                                                child: card,
                                                              ),
                                                          child: card,
                                                        )
                                                        : Draggable<
                                                          AgentTransactionModel
                                                        >(
                                                          data: transaction,
                                                          feedback: Material(
                                                            color:
                                                                Colors
                                                                    .transparent,
                                                            child: Opacity(
                                                              opacity: 0.7,
                                                              child: card,
                                                            ),
                                                          ),
                                                          childWhenDragging:
                                                              Opacity(
                                                                opacity: 0.5,
                                                                child: card,
                                                              ),
                                                          child: card,
                                                        ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 45,
                                      child: ElevatedButton(
                                        style: elevatedButtonStyleRounded10,
                                        onPressed: () {
                                          ref
                                              .read(navigationService)
                                              .pushNamedScreen(
                                                Routes.proDraggableAddClient,
                                                data: {'state': 'SELL'},
                                              );
                                        },
                                        child: AppIcons.add(
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DragTarget<AgentTransactionModel>(
                              onWillAccept: (_) => true,
                              onAccept: (incomingTransaction) {
                                onMove(
                                  incomingTransaction,
                                  status,
                                  transactions.length,
                                );
                              },
                              builder: (context, candidateData, rejectedData) {
                                if (candidateData.isEmpty)
                                  return const SizedBox.shrink();
                                return IgnorePointer(
                                  ignoring: true,
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: SizedBox(
                                      width: 300,
                                      child: TransactionCard(
                                        transaction:
                                            candidateData
                                                .first!, // ← przeciągana karta jako ghost
                                        hasDelete: false,
                                        key: ValueKey(
                                          'ghost-end-${candidateData.first!.id}',
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const CustomVerticalDivider(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String removeContactSegment(String path) {
    // This removes the last '/contact/:id/dashboard' from the path
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }

  double calculateDynamicSize(double screenWidth) {
    if (screenWidth <= 400) return screenWidth; // Pełna szerokość dla < 400px
    if (screenWidth >= 1440) {
      return screenWidth / 2 > 1500
          ? 1500
          : screenWidth / 2; // Połowa ekranu, max 1500px
    }

    // Liniowa interpolacja między 400px a 1440px
    double factor =
        (screenWidth - 400) / (1440 - 400); // Normalizacja do zakresu 0-1
    double interpolatedSize =
        screenWidth * (1 - (factor * 0.5)); // Zmniejszanie od 100% do 50%

    return interpolatedSize;
  }
}
