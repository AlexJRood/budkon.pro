import 'dart:convert';
import 'package:crm/crm/finance/pop_details/expeses_pop.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:flutter/material.dart';


final singleExpenseProvider =
    FutureProvider.family<TransactionExpensesModel, String>((ref, articleSlug) async {
  final response = await ApiServices.get(
    ref: ref,
    '${CrmUrls.financeAppExpenses}/?id=$articleSlug',
  );

  if (response != null && response.statusCode == 200) {
    final decodedBody = utf8.decode(response.data);
    final expenseJson = json.decode(decodedBody) as Map<String, dynamic>;

    return TransactionExpensesModel.fromJson(expenseJson);
  } else {
    throw Exception('Failed to load article');
  }
});



class ExpensesFetcher extends ConsumerWidget {
  final String id;
  final String tag;

  const ExpensesFetcher({required this.id, required this.tag, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsyncValue = ref.watch(singleExpenseProvider(id));

    return articleAsyncValue.when(
      data: (expense) => ExpensesPop(expense: expense, tag: tag),
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.transparent,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error'.tr)),
      ),
    );
  }
}
