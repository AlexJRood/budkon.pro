import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Klasa przechowująca kontrolery tekstowe oraz stan transakcji agenta
class AgentTransactionControllers {
  // Pola tekstowe związane z transakcją
  final TextEditingController nameController;
  final TextEditingControllerWithDecimal commissionController;
  final TextEditingControllerWithDecimal amountController;
  final TextEditingController currencyController;
  final TextEditingController transactionTypeController;
  final TextEditingController paymentDateController;
  final TextEditingController whenMonthlyPaymentIsOverController;
  final TextEditingController noteController;
  final TextEditingController transactionNameController;
  final TextEditingController invoiceNumberController;
  final TextEditingController statusController;
  final TextEditingController taxAmountController;

  // Adres
  final TextEditingController countryController;
  final TextEditingController cityController;
  final TextEditingController streetController;
  final TextEditingController postalCodeController;

  // JSON Fields
  final TextEditingController invoiceDataController;
  final TextEditingController documentsController;
  final TextEditingController tagsController;
  final TextEditingController paymentMethodsController;

  // Flagi
  final ValueNotifier<bool> isSellerController;
  final ValueNotifier<bool> isBuyerController;
  final ValueNotifier<bool> isMonthlyPaymentController;
  final ValueNotifier<bool> sendInvoiceEmailController;
  final ValueNotifier<bool> isPayedController;
  final ValueNotifier<bool> isCommisssionPercentage;
  final ValueNotifier<bool> isCommissionNetValue;


  /// Konstruktor domyślny
  AgentTransactionControllers({
    TextEditingController? nameController,
    TextEditingControllerWithDecimal? commissionController,
    TextEditingControllerWithDecimal? amountController,
    TextEditingController? currencyController,
    TextEditingController? transactionTypeController,
    TextEditingController? paymentDateController,
    TextEditingController? whenMonthlyPaymentIsOverController,
    TextEditingController? noteController,
    TextEditingController? transactionNameController,
    TextEditingController? invoiceNumberController,
    TextEditingController? statusController,
    TextEditingController? taxAmountController,
    TextEditingController? countryController,
    TextEditingController? cityController,
    TextEditingController? streetController,
    TextEditingController? postalCodeController,
    TextEditingController? invoiceDataController,
    TextEditingController? documentsController,
    TextEditingController? tagsController,
    TextEditingController? paymentMethodsController,
    ValueNotifier<bool>? isSellerController,
    ValueNotifier<bool>? isBuyerController,
    ValueNotifier<bool>? isMonthlyPaymentController,
    ValueNotifier<bool>? sendInvoiceEmailController,
    ValueNotifier<bool>? isPayedController,
    ValueNotifier<bool>? isCommisssionPercentage,
    ValueNotifier<bool>? isCommissionNetValue,
  })  : nameController = nameController ?? TextEditingController(),
        commissionController = commissionController ?? TextEditingControllerWithDecimal(),
        amountController = amountController ?? TextEditingControllerWithDecimal(),
        currencyController = currencyController ?? TextEditingController(),
        transactionTypeController = transactionTypeController ?? TextEditingController(),
        paymentDateController = paymentDateController ?? TextEditingController(),
        whenMonthlyPaymentIsOverController = whenMonthlyPaymentIsOverController ?? TextEditingController(),
        noteController = noteController ?? TextEditingController(),
        transactionNameController = transactionNameController ?? TextEditingController(),
        invoiceNumberController = invoiceNumberController ?? TextEditingController(),
        statusController = statusController ?? TextEditingController(),
        taxAmountController = taxAmountController ?? TextEditingController(),
        countryController = countryController ?? TextEditingController(),
        cityController = cityController ?? TextEditingController(),
        streetController = streetController ?? TextEditingController(),
        postalCodeController = postalCodeController ?? TextEditingController(),
        invoiceDataController = invoiceDataController ?? TextEditingController(),
        documentsController = documentsController ?? TextEditingController(),
        tagsController = tagsController ?? TextEditingController(),
        paymentMethodsController = paymentMethodsController ?? TextEditingController(),
        isSellerController = isSellerController ?? ValueNotifier<bool>(false),
        isBuyerController = isBuyerController ?? ValueNotifier<bool>(false),
        isMonthlyPaymentController = isMonthlyPaymentController ?? ValueNotifier<bool>(false),
        sendInvoiceEmailController = sendInvoiceEmailController ?? ValueNotifier<bool>(false),
        isPayedController = isPayedController ?? ValueNotifier<bool>(false),
        isCommisssionPercentage = isCommisssionPercentage ?? ValueNotifier<bool>(false),
        isCommissionNetValue = isCommissionNetValue ?? ValueNotifier<bool>(false);


  /// Metoda `dispose()` zwalniająca zasoby
  void dispose() {
    nameController.dispose();
    commissionController.dispose();
    amountController.dispose();
    currencyController.dispose();
    transactionTypeController.dispose();
    paymentDateController.dispose();
    whenMonthlyPaymentIsOverController.dispose();
    noteController.dispose();
    transactionNameController.dispose();
    invoiceNumberController.dispose();
    statusController.dispose();
    taxAmountController.dispose();
    countryController.dispose();
    cityController.dispose();
    streetController.dispose();
    postalCodeController.dispose();
    invoiceDataController.dispose();
    documentsController.dispose();
    tagsController.dispose();
    paymentMethodsController.dispose();
    isCommisssionPercentage.dispose();
    isCommissionNetValue.dispose();
  }
  void clear() {
    nameController.clear();
    commissionController.clear();
    amountController.clear();
    currencyController.clear();
    transactionTypeController.clear();
    paymentDateController.clear();
    whenMonthlyPaymentIsOverController.clear();
    noteController.clear();
    transactionNameController.clear();
    invoiceNumberController.clear();
    statusController.clear();
    taxAmountController.clear();

    countryController.clear();
    cityController.clear();
    streetController.clear();
    postalCodeController.clear();

    invoiceDataController.clear();
    documentsController.clear();
    tagsController.clear();
    paymentMethodsController.clear();

    // Reset boolean toggles
    isSellerController.value = false;
    isBuyerController.value = false;
    isMonthlyPaymentController.value = false;
    sendInvoiceEmailController.value = false;
    isPayedController.value = false;
    isCommisssionPercentage.value = true;
    isCommissionNetValue.value = true;
  }

}


/// Kontroler umożliwiający wpisywanie liczb z maksymalnie dwoma miejscami po przecinku
class TextEditingControllerWithDecimal extends TextEditingController {
  TextEditingControllerWithDecimal({super.text}) {
    addListener(_formatText);
  }

  void _formatText() {
    String text = this.text;

    // Jeśli pusty, nie rób nic
    if (text.isEmpty) return;

    // Wymuś poprawny format liczbowy z maks. dwoma miejscami po przecinku
    final formatted = _formatDecimal(text);
    if (formatted != text) {
      value = value.copyWith(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
    }
  }

  static String _formatDecimal(String value) {
    // Usuń niepotrzebne znaki
    value = value.replaceAll(RegExp(r'[^0-9.]'), '');

    // Upewnij się, że jest tylko jedna kropka dziesiętna
    List<String> parts = value.split('.');
    if (parts.length > 2) {
      value = "${parts[0]}.${parts.sublist(1).join('')}";
    }

    // Ogranicz do dwóch miejsc po przecinku
    if (parts.length == 2 && parts[1].length > 2) {
      value = "${parts[0]}.${parts[1].substring(0, 2)}";
    }

    return value;
  }

  @override
  void dispose() {
    removeListener(_formatText);
    super.dispose();
  }
}








/// Provider dla AgentSellControllers
final transactionControllersProvider = StateProvider<AgentTransactionControllers>((ref) {
  final state = AgentTransactionControllers();
  ref.onDispose(state.dispose);
  return state;
});



//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
/////////////////////// How to use that //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// class AddOfferScreen extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final offerState = ref.watch(addOfferProvider);

//     return Scaffold(
//       appBar: AppBar(title: Text("Add Offer".tr)),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: offerState.titleController,
//               decoration: InputDecoration(labelText: "Tytuł".tr),
//             ),
//             TextField(
//               controller: offerState.descriptionController,
//               decoration: InputDecoration(labelText: "Opis".tr),
//             ),
//             TextField(
//               controller: offerState.priceController,
//               decoration: InputDecoration(labelText: "Price".tr),
//             ),
//             SwitchListTile(
//               title: Text("Czy jest balkon?".tr),
//               value: offerState.balconyController.value,
//               onChanged: (value) {
//                 offerState.balconyController.value = value;
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
