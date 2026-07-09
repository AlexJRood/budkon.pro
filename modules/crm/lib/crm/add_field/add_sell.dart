import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/revenue/crm_revenue_upload_model.dart';
import '../../data/finance/dio_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'add_client.dart';
import 'package:crm/crm/add_field/add_field.dart';
import 'package:crm/crm/add_field/add_offer_section.dart';

import 'package:get/get_utils/get_utils.dart';

class AddSellForm extends ConsumerStatefulWidget {
  final List<FocusNode> focusNodes;
  const AddSellForm({super.key, required this.focusNodes});

  @override
  _AddSellFormState createState() => _AddSellFormState();
}

class _AddSellFormState extends ConsumerState<AddSellForm> with AutomaticKeepAliveClientMixin{
  // Controllers for the form fields
  final _amountController = TextEditingController();
  final _transactionNameController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _invoiceDataController = TextEditingController();
  final _documentsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _paymentMethodsController = TextEditingController();
  final _statusController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxAmountController = TextEditingController();
late FocusNode _focusNode;
  String? selectedClient;
  final _sendInvoiceEmail = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
   WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionNameController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDataController.dispose();
    _documentsController.dispose();
    _tagsController.dispose();
    _paymentMethodsController.dispose();
    _statusController.dispose();
    _addressController.dispose();
    _taxAmountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
 
   @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
     super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    double screenSpace = screenHeight * 0.9;
  final ScrollController scrollController = ScrollController();
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        KeyBoardShortcuts().handleKeyEvent(event, scrollController, 100, 100);
        
      },
      child: Container(
        height: screenSpace,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient:  CustomBackgroundGradients.appBarGradientcustom(context, ref),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Form(
            // key: _formKeySell, // Unique form key to handle form state
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const AddClientForm(), // Assuming this form manages client info
                const SizedBox(
                  height: 70,
                ),
                Text('ad_data_title'.tr, style: AppTextStyles.houslyAiLogo24),
                const SizedBox(
                  height: 20,
                ),
                AddOfferCrm(),
                const SizedBox(
                  height: 70,
                ),
                Text('transaction_data_title'.tr, style: AppTextStyles.houslyAiLogo24),
                const SizedBox(
                  height: 20,
                ),
                // Form fields
                Textlebelfield(
                  focusNode: widget.focusNodes[0],
                  reqNode: widget.focusNodes[1],
                  label: 'Amount'.tr,
                  badRequestLabel: 'Please enter an amount'.tr,
                  controllerName: _amountController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[1],
                  reqNode: widget.focusNodes[2],
                  label: 'Transaction Name'.tr,
                  badRequestLabel: 'Please enter a transaction name'.tr,
                  controllerName: _transactionNameController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[2],
                  reqNode: widget.focusNodes[3],
                  label: 'Invoice Number'.tr,
                  badRequestLabel: 'Please enter an invoice number'.tr,
                  controllerName: _invoiceNumberController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[3],
                  reqNode: widget.focusNodes[4],
                  label: 'Invoice Data'.tr,
                  badRequestLabel: 'Please enter invoice data'.tr,
                  controllerName: _invoiceDataController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[4],
                  reqNode: widget.focusNodes[5],
                  label: 'Documents'.tr,
                  badRequestLabel: 'Please enter documents'.tr,
                  controllerName: _documentsController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[5],
                  reqNode: widget.focusNodes[6],
                  label: 'Tags'.tr,
                  badRequestLabel: 'Please enter tags'.tr,
                  controllerName: _tagsController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[6],
                  reqNode: widget.focusNodes[7],
                  label: 'Payment Methods'.tr,
                  badRequestLabel: 'Please enter payment methods'.tr,
                  controllerName: _paymentMethodsController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[7],
                  reqNode: widget.focusNodes[8],
                  label: 'Status'.tr,
                  badRequestLabel: 'Please enter a status'.tr,
                  controllerName: _statusController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[8],
                  reqNode: widget.focusNodes[9],
                  label: 'Address'.tr,
                  badRequestLabel: 'Please enter an address'.tr,
                  controllerName: _addressController,
                ),
                const SizedBox(height: 10),
                Textlebelfield(
                  focusNode: widget.focusNodes[9],
                  reqNode: widget.focusNodes[10],
                  label: 'Tax Amount'.tr,
                  badRequestLabel: 'Please enter a tax amount'.tr,
                  controllerName: _taxAmountController,
                ),

                const SizedBox(height: 20),
                Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () {
                        final revenueListProvider =
                            ref.read(crmRevenueProvider.notifier);
                        final revenue = CrmRevenueUploadModel(
                          amount: _amountController.text,
                          dateCreate: DateTime.now(),
                          dateUpdate: DateTime.now(),
                          client: int.parse(
                              selectedClient!), // Use selected client ID
                          transactionName: _transactionNameController.text,
                          invoiceNumber: _invoiceNumberController.text,
                          invoiceData: _parseJson(_invoiceDataController.text),
                          sendInvoiceEmail: _sendInvoiceEmail,
                          documents: _parseJsonList(_documentsController.text),
                          tags: _parseJsonList(_tagsController.text),
                          paymentMethods:
                              _parseJsonList(_paymentMethodsController.text),
                          status: _statusController.text,
                          address: _parseJson(_addressController.text),
                          taxAmount: double.parse(_taxAmountController.text),
                        );
                        revenueListProvider.addRevenue(revenue);
                        ref.read(navigationService).beamPop();
                      },
                      child: Text('Add Revenue'.tr),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Parse JSON helpers
  Map<String, dynamic>? _parseJson(String jsonString) {
    if (jsonString.isEmpty) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  List<dynamic>? _parseJsonList(String jsonString) {
    if (jsonString.isEmpty) return null;
    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }
}
