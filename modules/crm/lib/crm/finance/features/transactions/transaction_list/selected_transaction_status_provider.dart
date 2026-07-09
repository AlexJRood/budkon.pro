import 'package:crm/data/finance/transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedTransactionStatusNotifier extends StateNotifier<String?> {
  SelectedTransactionStatusNotifier(super.initialStatus);

  void setStatus(String? statusName) => state = statusName;
}
final selectedTransactionStatusProvider =
StateNotifierProvider<SelectedTransactionStatusNotifier, String?>(
      (ref) {
    final transactionState = ref.watch(transactionProvider);

    if (transactionState is AsyncData &&
        transactionState.value!.statuses.isNotEmpty) {
      return SelectedTransactionStatusNotifier(
        'All',
      );
    }

    return SelectedTransactionStatusNotifier(null);
  },
);
