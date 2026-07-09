import 'package:crm/data/finance/expenses_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedExpensesStatusNotifier extends StateNotifier<String?> {
  SelectedExpensesStatusNotifier(super.initialStatus);

  void setStatus(String? statusName) => state = statusName;
}

final selectedExpensesStatusProvider =
    StateNotifierProvider<SelectedExpensesStatusNotifier, String?>((ref) {
      final transactionState = ref.watch(expensesTransactionProvider);

      if (transactionState is AsyncData &&
          transactionState.value!.statuses.isNotEmpty) {
        return SelectedExpensesStatusNotifier('All');
      }

      return SelectedExpensesStatusNotifier(null);
    });
