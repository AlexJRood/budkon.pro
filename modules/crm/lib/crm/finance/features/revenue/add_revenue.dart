import 'dart:convert';
import 'dart:ui' as ui;

import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/data/finance/dio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/revenue/crm_revenue_upload_model.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:get/get_utils/get_utils.dart';

class CrmAddRevenuePopPc extends ConsumerStatefulWidget {
  const CrmAddRevenuePopPc({super.key});

  @override
  CrmAddRevenuePopPcState createState() => CrmAddRevenuePopPcState();
}

class CrmAddRevenuePopPcState extends ConsumerState<CrmAddRevenuePopPc> {
  final _formKeyAddRevenue = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _transactionNameController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _invoiceDataController = TextEditingController();
  final _documentsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _paymentMethodsController = TextEditingController();
  final _statusController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _sendInvoiceEmail = false;

  String? selectedClient;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _transactionNameController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDataController.dispose();
    _documentsController.dispose();
    _tagsController.dispose();
    _paymentMethodsController.dispose();
    _statusController.dispose();
    _addressController.dispose();
    _taxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revenueListProvider = ref.read(crmRevenueProvider.notifier);
    final theme = ref.read(themeColorsProvider);

    return PopPageManager(
      tag: 'addRevenuePop-${UniqueKey().toString()}',
      isBig: true,
      child:  Expanded(
        child: SingleChildScrollView(
                    child: Form(
                      key: _formKeyAddRevenue,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Amount'.tr,
                            badRequestLabel: 'Please enter an amount'.tr,
                            controllerName: _amountController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Note'.tr,
                            badRequestLabel: 'Please enter a note'.tr,
                            controllerName: _noteController,
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<List<UserContactModel>>(
                            future: ref
                                .read(clientProvider.notifier)
                                .fetchClientsList(), // Fetch clients
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}'.tr);
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Text('No clients available'.tr);
                              } else {
                                final clients = snapshot.data!;
                                return DropdownButtonFormField<String>(
                                  value: selectedClient,
                                  focusColor: Colors.transparent,
                                  style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                  dropdownColor: theme.textFieldColor,
                                  iconDisabledColor: Colors.transparent,
                                  iconEnabledColor: Colors.transparent,
                                  decoration:
                                      InputDecoration(
                                        fillColor: Colors.transparent,
                                          labelText: 'Client'.tr,
                                          floatingLabelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                          labelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                      ),
                                  items: clients.map((client) {
                                    return DropdownMenuItem<String>(
                                      value: client.id.toString(),
                                      child:
                                          Text('${client.name} ${client.lastName}',
                                          style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                          ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedClient = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a client'.tr;
                                    }
                                    return null;
                                  },
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Transaction Name'.tr,
                            badRequestLabel: 'Please enter a transaction name'.tr,
                            controllerName: _transactionNameController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Invoice Number'.tr,
                            badRequestLabel: 'Please enter an invoice number'.tr,
                            controllerName: _invoiceNumberController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Invoice Data'.tr,
                            badRequestLabel: 'Please enter invoice data'.tr,
                            controllerName: _invoiceDataController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Documents'.tr,
                            badRequestLabel: 'Please enter documents'.tr,
                            controllerName: _documentsController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Tags'.tr,
                            badRequestLabel: 'Please enter tags'.tr,
                            controllerName: _tagsController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Payment Methods'.tr,
                            badRequestLabel: 'Please enter payment methods'.tr,
                            controllerName: _paymentMethodsController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Status',
                            badRequestLabel: 'Please enter a status'.tr,
                            controllerName: _statusController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Address'.tr,
                            badRequestLabel: 'Please enter an address'.tr,
                            controllerName: _addressController,
                          ),
                          const SizedBox(height: 10),
                          Textlebelfield(
                            label: 'Tax Amount'.tr,
                            badRequestLabel: 'Please enter a tax amount'.tr,
                            controllerName: _taxAmountController,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKeyAddRevenue.currentState!.validate()) {
                                final revenue = CrmRevenueUploadModel(
                                  amount: _amountController.text,
                                  dateCreate: DateTime.now(),
                                  dateUpdate: DateTime.now(),
                                  note: _noteController.text,
                                  client: int.parse(
                                      selectedClient!), // Use selected client ID
                                  transactionName: _transactionNameController.text,
                                  invoiceNumber: _invoiceNumberController.text,
                                  invoiceData:
                                      _parseJson(_invoiceDataController.text),
                                  sendInvoiceEmail: _sendInvoiceEmail,
                                  documents:
                                      _parseJsonList(_documentsController.text),
                                  tags: _parseJsonList(_tagsController.text),
                                  paymentMethods: _parseJsonList(
                                      _paymentMethodsController.text),
                                  status: _statusController.text,
                                  address: _parseJson(_addressController.text),
                                  taxAmount:
                                      double.parse(_taxAmountController.text),
                                );
                                revenueListProvider.addRevenue(revenue);
                                ref.read(navigationService).beamPop();
                              }
                            },
                            child: Text('Add Revenue'.tr),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _parseJson(String jsonString) {
    if (jsonString.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Handle error, e.g. show a dialog
      return null;
    }
  }

  List<dynamic>? _parseJsonList(String jsonString) {
    if (jsonString.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      // Handle error, e.g. show a dialog
      return null;
    }
  }
}






class Textlebelfield extends ConsumerStatefulWidget {
  final TextEditingController controllerName;
  final String label;
  final String badRequestLabel;

  const Textlebelfield({
    super.key,
    required this.label,
    required this.badRequestLabel,
    required this.controllerName,
  });

  @override
  ConsumerState<Textlebelfield> createState() => TextLabelFieldState();
}

class TextLabelFieldState extends ConsumerState<Textlebelfield> {
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
