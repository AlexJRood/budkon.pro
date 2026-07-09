import 'package:crm/crm/finance/features/revenue/revenue_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedRevenueStatusNotifier extends StateNotifier<String?> {
  SelectedRevenueStatusNotifier(super.initialStatus);

  void setStatus(String? statusName) => state = statusName;
}
final selectedRevenueStatusProvider =
StateNotifierProvider<SelectedRevenueStatusNotifier, String?>(
      (ref) {
    final transactionState = ref.watch(revenueProvider);

    if (transactionState is AsyncData &&
        transactionState.value!.statuses.isNotEmpty) {
      return SelectedRevenueStatusNotifier(
        'All',
      );
    }

    return SelectedRevenueStatusNotifier(null);
  },
);