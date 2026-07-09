import 'dart:ui' as ui;

import 'package:crm/data/finance/api_servises_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/expense/expenses_model_new.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/data/clients/client_provider.dart';

import 'package:get/get_utils/get_utils.dart';

class CrmAddExpensesPopPc extends ConsumerStatefulWidget {
  const CrmAddExpensesPopPc({super.key});

  @override
  CrmAddExpensesPopPcState createState() => CrmAddExpensesPopPcState();
}

class CrmAddExpensesPopPcState extends ConsumerState<CrmAddExpensesPopPc> {
  final _formKeyAddExpenses = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _statusController;
  late TextEditingController _taxAmountController;
  int? selectedClient;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _invoiceNumberController = TextEditingController();
    _statusController = TextEditingController();
    _taxAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _invoiceNumberController.dispose();
    _statusController.dispose();
    _taxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final theme = ref.read(themeColorsProvider);

    return Stack(
      children: [
        // Ta część odpowiada za efekt rozmycia tła
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withAlpha((255 * 0.5).toInt()),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Obsługa dotknięcia w dowolnym miejscu aby zamknąć modal
        GestureDetector(onTap: () {          
                    Navigator.of(context).pop();
        }),
        Hero(
          tag: 'addExpensesPagePop-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag 
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: screenWidth * 0.5,
              height: screenHeight * 0.5,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: CustomBackgroundGradients.appBarGradientcustom(context, ref),
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKeyAddExpenses,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Consumer(
                        builder: (context, ref, _) {
                          return FutureBuilder<List<UserContactModel>>(
                            future:
                                ref.read(clientProvider.notifier).fetchClientsList(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}'.tr);
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Text('No clients available'.tr);
                              } else {
                                final clients = snapshot.data!;
                                return DropdownButtonFormField<int>(
                                  value: selectedClient,
                                  focusColor: Colors.transparent,
                                  style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                  dropdownColor: theme.textFieldColor,
                                  decoration: InputDecoration(
                                        fillColor: Colors.transparent,
                                    labelText: 'Client'.tr,
                                    floatingLabelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                    labelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                    ),
                                  items: clients.map((client) {
                                    return DropdownMenuItem<int>(
                                      value: client.id,
                                      child: Text('${client.name} ${client.lastName}',
                                  style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                  ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedClient = value;
                                    });
                                  },
                                  // validator: (value) {
                                  //   if (value == null || value.isEmpty) {
                                  //     return 'Please select a client'.tr;
                                  //   }
                                  //   return null;
                                  // },
                                );
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextLabelField(
                        label: 'Amount'.tr,
                        badRequestLabel: 'Please enter an amount'.tr,
                        controllerName: _amountController,
                      ),
                      const SizedBox(height: 10),
                      TextLabelField(
                        label: 'Note'.tr,
                        badRequestLabel: 'Please enter a note'.tr,
                        controllerName: _noteController,
                      ),
                      const SizedBox(height: 10),
                      TextLabelField(
                        label: 'Invoice Number'.tr,
                        badRequestLabel: 'Please enter an invoice number'.tr,
                        controllerName: _invoiceNumberController,
                      ),
                      const SizedBox(height: 10),
                      TextLabelField(
                        label: 'Status',
                        badRequestLabel: 'Please enter a status'.tr,
                        controllerName: _statusController,
                      ),
                      const SizedBox(height: 10),
                      TextLabelField(
                        label: 'Tax Amount'.tr,
                        badRequestLabel: 'Please enter a tax amount'.tr,
                        controllerName: _taxAmountController,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        child: Text('Add Expense'.tr),
                        onPressed: () {
                          if (_formKeyAddExpenses.currentState!.validate()) {
                            // Create an Expense object
                            final expense = ExpenseModelNew(
                              clientId: selectedClient,
                              amount: double.parse(_amountController.text),
                              note: _noteController.text,
                              invoiceNumber: _invoiceNumberController.text,
                              status: _statusController.text,
                              taxAmount: double.parse(_taxAmountController.text),
                              // Add other fields here if necessary
                            );

                            Navigator.of(context).pop();

                            ref.read(expensesProvider.notifier).createExpense(expense);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}





class TextLabelField extends ConsumerStatefulWidget {
  final TextEditingController controllerName;
  final String label;
  final String badRequestLabel;

  const TextLabelField({
    super.key,
    required this.label,
    required this.badRequestLabel,
    required this.controllerName,
  });

  @override
  ConsumerState<TextLabelField> createState() => TextLabelFieldState();
}

class TextLabelFieldState extends ConsumerState<TextLabelField> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider); // <- teraz działa

    return TextFormField(
      controller: widget.controllerName,
      style: AppTextStyles.interMedium16.copyWith(color: theme.textColor),
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
        labelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color:  theme.textColor),
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
      selectionHeightStyle: ui.BoxHeightStyle.tight,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.badRequestLabel;
        }
        return null;
      },
    );
  }
}
