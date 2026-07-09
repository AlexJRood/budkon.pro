import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crm/data/finance/dio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/revenue/crm_revenue_upload_model.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:core/platform/navigation_service.dart';

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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final revenueListProvider = ref.read(crmRevenueProvider.notifier);

    return Stack(
      children: [
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withAlpha(102),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        GestureDetector(onTap: () {
          ref.read(navigationService).beamPop();
        }),
        Hero(
          tag: 'addRevenuePop-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag 
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: screenWidth * 0.5,
              height: screenHeight * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:  CustomBackgroundGradients.appBarGradientcustom(context, ref),
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKeyAddRevenue,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Amount',
                        badRequestLabel: 'Please enter an amount',
                        controllerName: _amountController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Note',
                        badRequestLabel: 'Please enter a note',
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
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Text('No clients available');
                          } else {
                            final clients = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              value: selectedClient,
                              focusColor: AppColors.superbee,
                              style: AppTextStyles.interMedium14_50,
                              dropdownColor: AppColors.dark50,
                              iconDisabledColor: AppColors.superbee,
                              iconEnabledColor: AppColors.superbee,
                              decoration:
                                  const InputDecoration(labelText: 'Client'),
                              items: clients.map((client) {
                                return DropdownMenuItem<String>(
                                  value: client.id.toString(),
                                  child:
                                      Text('${client.name} ${client.lastName}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedClient = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a client';
                                }
                                return null;
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Transaction Name',
                        badRequestLabel: 'Please enter a transaction name',
                        controllerName: _transactionNameController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Invoice Number',
                        badRequestLabel: 'Please enter an invoice number',
                        controllerName: _invoiceNumberController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Invoice Data',
                        badRequestLabel: 'Please enter invoice data',
                        controllerName: _invoiceDataController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Documents',
                        badRequestLabel: 'Please enter documents',
                        controllerName: _documentsController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Tags',
                        badRequestLabel: 'Please enter tags',
                        controllerName: _tagsController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Payment Methods',
                        badRequestLabel: 'Please enter payment methods',
                        controllerName: _paymentMethodsController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Status',
                        badRequestLabel: 'Please enter a status',
                        controllerName: _statusController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Address',
                        badRequestLabel: 'Please enter an address',
                        controllerName: _addressController,
                      ),
                      const SizedBox(height: 10),
                      Textlebelfield(
                        label: 'Tax Amount',
                        badRequestLabel: 'Please enter a tax amount',
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
                        child: const Text('Add Revenue'),
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

class Textlebelfield extends StatefulWidget {
  final TextEditingController controllerName;
  final String label;
  final String badRequestLabel;

  const Textlebelfield({
    Key? key,
    required this.label,
    required this.badRequestLabel,
    required this.controllerName,
  }) : super(key: key);

  @override
  _TextlebelfieldState createState() => _TextlebelfieldState();
}

class _TextlebelfieldState extends State<Textlebelfield> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controllerName,
      style: AppTextStyles.interMedium16,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppTextStyles.interMedium14_50,
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
          borderSide: const BorderSide(color: Colors.white54),
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
