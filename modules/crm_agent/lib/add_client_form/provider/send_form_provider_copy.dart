import 'package:crm_agent/crm_agent_urls.dart';
// import 'dart:convert';
// import 'package:crm_agent/add_client_form/components/usercontact/contact_list.dart';
// import 'package:crm_agent/models/transaction/agent_transaction_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:core/platform/url.dart';
// import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
// import 'package:core/platform/api_services.dart';
// import 'package:flutter/foundation.dart';
//
// import 'package:get/get_utils/get_utils.dart';
//
// final selectedTabProvider = StateProvider<String>((ref) => 'VIEW'.tr);
//
// class AddClientFormState {
//   // Client
//   final TextEditingController clientNameController;
//   final TextEditingController clientLastNameController;
//   final TextEditingController clientPhoneNumberController;
//   final TextEditingController clientEmailController;
//   final TextEditingController clientDescriptionController;
//   final TextEditingController clientNoteController;
//
//   // Transaction
//   final ValueNotifier<bool> transactionIsSellerController;
//   final ValueNotifier<bool> transactionIsBuyerController;
//   final TextEditingController transactionNameController;
//   final TextEditingController transactionCommissionController;
//   final TextEditingController transactionAmountController;
//   final TextEditingController transactionTitleController;
//   final TextEditingController transactionCurrencyController;
//   final TextEditingController transactionTypeController;
//   final TextEditingController transactionPaymentDateController;
//   final TextEditingController transactionNoteController;
//
//   // Saved Search
//   final TextEditingController savedSearchTitleController;
//   final TextEditingController savedSearchDescriptionController;
//   final TextEditingController savedSearchTagsController;
//   final TextEditingController savedSearchSearchQueryController;
//   final TextEditingController savedSearchPriceMinController;
//   final TextEditingController savedSearchPriceMaxController;
//   final TextEditingController savedSearchRoomsController;
//
//   // Draft
//   final TextEditingController draftTitleController;
//   final TextEditingController draftPriceController;
//   final TextEditingController draftCurrencyController;
//   final TextEditingController draftDescriptionController;
//   final TextEditingController draftStreetController;
//   final TextEditingController draftCityController;
//   final TextEditingController draftStateController;
//   final TextEditingController draftCountryController;
//   final TextEditingController draftRoomsController;
//   final TextEditingController draftBathroomsController;
//   final TextEditingController draftSquareFootageController;
//   final TextEditingController draftOfferTypeController;
//   final List<Uint8List> imagesData;
//
//   // Event
//   final TextEditingController eventTitleController;
//   final TextEditingController eventDescriptionController;
//   final TextEditingController eventLocationController;
//
//   final bool isLoading;
//   final String? errorMessage;
//   final bool success;
//
//   AddClientFormState({
//     this.imagesData = const [],
//     // Client
//     TextEditingController? clientNameController,
//     TextEditingController? clientLastNameController,
//     TextEditingController? clientPhoneNumberController,
//     TextEditingController? clientEmailController,
//     TextEditingController? transactionTitleController,
//     TextEditingController? clientDescriptionController,
//     TextEditingController? clientNoteController,
//
//     // Transaction
//     ValueNotifier<bool>? transactionIsSellerController,
//     ValueNotifier<bool>? transactionIsBuyerController,
//     TextEditingController? transactionNameController,
//     TextEditingController? transactionCommissionController,
//     TextEditingController? transactionAmountController,
//     TextEditingController? transactionCurrencyController,
//     TextEditingController? transactionTypeController,
//     TextEditingController? transactionPaymentDateController,
//     TextEditingController? transactionNoteController,
//
//     // Saved Search
//     TextEditingController? savedSearchTitleController,
//     TextEditingController? savedSearchDescriptionController,
//     TextEditingController? savedSearchTagsController,
//     TextEditingController? savedSearchSearchQueryController,
//     TextEditingController? savedSearchPriceMinController,
//     TextEditingController? savedSearchPriceMaxController,
//     TextEditingController? savedSearchRoomsController,
//
//     // Draft
//     TextEditingController? draftTitleController,
//     TextEditingController? draftPriceController,
//     TextEditingController? draftCurrencyController,
//     TextEditingController? draftDescriptionController,
//     TextEditingController? draftStreetController,
//     TextEditingController? draftCityController,
//     TextEditingController? draftStateController,
//     TextEditingController? draftCountryController,
//     TextEditingController? draftRoomsController,
//     TextEditingController? draftBathroomsController,
//     TextEditingController? draftSquareFootageController,
//     TextEditingController? draftOfferTypeController,
//
//     // Event
//     TextEditingController? eventTitleController,
//     TextEditingController? eventDescriptionController,
//     TextEditingController? eventLocationController,
//     this.isLoading = false,
//     this.errorMessage,
//     this.success = false,
//   }) : // Client
//        clientNameController = clientNameController ?? TextEditingController(),
//        clientLastNameController =
//            clientLastNameController ?? TextEditingController(),
//        transactionTitleController =
//            transactionTitleController ?? TextEditingController(),
//        clientPhoneNumberController =
//            clientPhoneNumberController ?? TextEditingController(),
//        clientEmailController = clientEmailController ?? TextEditingController(),
//        clientDescriptionController =
//            clientDescriptionController ?? TextEditingController(),
//        clientNoteController = clientNoteController ?? TextEditingController(),
//
//        // Transaction
//        transactionIsSellerController =
//            transactionIsSellerController ?? ValueNotifier(false),
//        transactionIsBuyerController =
//            transactionIsBuyerController ?? ValueNotifier(false),
//        transactionNameController =
//            transactionNameController ?? TextEditingController(),
//        transactionCommissionController =
//            transactionCommissionController ?? TextEditingController(),
//        transactionAmountController =
//            transactionAmountController ?? TextEditingController(),
//        transactionCurrencyController =
//            transactionCurrencyController ?? TextEditingController(),
//        transactionTypeController =
//            transactionTypeController ?? TextEditingController(),
//        transactionPaymentDateController =
//            transactionPaymentDateController ?? TextEditingController(),
//        transactionNoteController =
//            transactionNoteController ?? TextEditingController(),
//
//        // Saved Search
//        savedSearchTitleController =
//            savedSearchTitleController ?? TextEditingController(),
//        savedSearchDescriptionController =
//            savedSearchDescriptionController ?? TextEditingController(),
//        savedSearchTagsController =
//            savedSearchTagsController ?? TextEditingController(),
//        savedSearchSearchQueryController =
//            savedSearchSearchQueryController ?? TextEditingController(),
//        savedSearchPriceMinController =
//            savedSearchPriceMinController ?? TextEditingController(),
//        savedSearchPriceMaxController =
//            savedSearchPriceMaxController ?? TextEditingController(),
//        savedSearchRoomsController =
//            savedSearchRoomsController ?? TextEditingController(),
//
//        // Draft
//        draftTitleController = draftTitleController ?? TextEditingController(),
//        draftPriceController = draftPriceController ?? TextEditingController(),
//        draftCurrencyController =
//            draftCurrencyController ?? TextEditingController(),
//        draftDescriptionController =
//            draftDescriptionController ?? TextEditingController(),
//        draftStreetController = draftStreetController ?? TextEditingController(),
//        draftCityController = draftCityController ?? TextEditingController(),
//        draftStateController = draftStateController ?? TextEditingController(),
//        draftCountryController =
//            draftCountryController ?? TextEditingController(),
//        draftRoomsController = draftRoomsController ?? TextEditingController(),
//        draftBathroomsController =
//            draftBathroomsController ?? TextEditingController(),
//        draftSquareFootageController =
//            draftSquareFootageController ?? TextEditingController(),
//        draftOfferTypeController =
//            draftOfferTypeController ?? TextEditingController(),
//
//        // Event
//        eventTitleController = eventTitleController ?? TextEditingController(),
//        eventDescriptionController =
//            eventDescriptionController ?? TextEditingController(),
//        eventLocationController =
//            eventLocationController ?? TextEditingController();
//
//   /// CopyWith Method - Ensures TextEditingController instances are not replaced
//   AddClientFormState copyWith({
//     bool? isLoading,
//     String? errorMessage,
//     bool? success,
//     List<Uint8List>? imagesData,
//   }) {
//     return AddClientFormState(
//       isLoading: isLoading ?? this.isLoading,
//       errorMessage: errorMessage ?? this.errorMessage,
//       success: success ?? this.success,
//       imagesData: imagesData ?? this.imagesData,
//
//       // Use the existing controllers
//       clientNameController: clientNameController,
//       clientLastNameController: clientLastNameController,
//       clientPhoneNumberController: clientPhoneNumberController,
//       clientEmailController: clientEmailController,
//       clientDescriptionController: clientDescriptionController,
//       clientNoteController: clientNoteController,
//
//       transactionIsSellerController: transactionIsSellerController,
//       transactionIsBuyerController: transactionIsBuyerController,
//       transactionNameController: transactionNameController,
//       transactionCommissionController: transactionCommissionController,
//       transactionAmountController: transactionAmountController,
//       transactionCurrencyController: transactionCurrencyController,
//       transactionTypeController: transactionTypeController,
//       transactionPaymentDateController: transactionPaymentDateController,
//       transactionNoteController: transactionNoteController,
//
//       savedSearchTitleController: savedSearchTitleController,
//       savedSearchDescriptionController: savedSearchDescriptionController,
//       savedSearchTagsController: savedSearchTagsController,
//       savedSearchSearchQueryController: savedSearchSearchQueryController,
//       savedSearchPriceMinController: savedSearchPriceMinController,
//       savedSearchPriceMaxController: savedSearchPriceMaxController,
//       savedSearchRoomsController: savedSearchRoomsController,
//
//       draftTitleController: draftTitleController,
//       draftPriceController: draftPriceController,
//       draftCurrencyController: draftCurrencyController,
//       draftDescriptionController: draftDescriptionController,
//       draftStreetController: draftStreetController,
//       draftCityController: draftCityController,
//       draftStateController: draftStateController,
//       draftCountryController: draftCountryController,
//       draftRoomsController: draftRoomsController,
//       draftBathroomsController: draftBathroomsController,
//       draftSquareFootageController: draftSquareFootageController,
//       draftOfferTypeController: draftOfferTypeController,
//
//       eventTitleController: eventTitleController,
//       eventDescriptionController: eventDescriptionController,
//       eventLocationController: eventLocationController,
//     );
//   }
// }
//
// class AddClientFormNotifier extends StateNotifier<AddClientFormState> {
//   AddClientFormNotifier() : super(AddClientFormState());
//
//   void updateTextField(TextEditingController controller, String value) {
//     controller.value = controller.value.copyWith(
//       text: value,
//       selection: TextSelection.collapsed(
//         offset: value.length,
//       ), // Maintain cursor position
//     );
//     if (kDebugMode) print(value);
//   }
//
//   Future<void> sellTransAction(ref) async {
//     try {
//       state = state.copyWith(isLoading: true, errorMessage: null);
//
//       final requestBody = {
//         "client": {
//           "name": state.clientNameController.text,
//           "last_name": state.clientLastNameController.text,
//           "email": state.clientEmailController.text,
//           "phone_number": state.clientPhoneNumberController.text,
//           "description": state.clientDescriptionController.text,
//           "note": state.clientNoteController.text
//         },
//         "draft": {
//           "title": state.draftTitleController.text,
//           "price": int.tryParse(state.draftPriceController.text) ?? 0,
//           "currency": state.draftCurrencyController.text,
//           "description": state.draftDescriptionController.text,
//           "street": state.draftStreetController.text,
//           "city": state.draftCityController.text,
//           "state": state.draftStateController.text,
//           "country": state.draftCountryController.text,
//           "rooms": int.tryParse(state.draftRoomsController.text) ?? 0,
//           "bathrooms": int.tryParse(state.draftBathroomsController.text) ?? 0,
//           "square_footage": state.draftSquareFootageController.text,
//           "offer_type": state.draftOfferTypeController.text,
//           "images": state.imagesData
//         },
//         "event": {
//           "title": state.eventTitleController.text.isEmpty
//               ? 'Meeting with Buyer'
//               : state.eventTitleController.text,
//           "description": state.eventDescriptionController.text.isEmpty
//               ? 'Discussing contract details.'
//               : state.eventDescriptionController.text,
//           "location": state.eventLocationController.text.isEmpty
//               ? 'Main Office'
//               : state.eventLocationController.text
//         },
//         "transaction": {
//           "is_seller": state.transactionIsSellerController.value,
//           "is_buyer": state.transactionIsBuyerController.value,
//           "name": state.transactionNameController.text,
//           "commission":
//           int.tryParse(state.transactionCommissionController.text) ?? 0,
//           "amount": int.tryParse(state.transactionAmountController.text) ?? 0,
//           "currency": state.transactionCurrencyController.text,
//           "transaction_type": state.transactionTypeController.text,
//           "note": state.transactionNoteController.text
//         }
//       };
//       if (kDebugMode) print(requestBody);
//
//       final response = await ApiServices.post(
//         CrmAgentUrls.sellTransAction,
//         hasToken: true,
//         data: requestBody,
//       );
//
//       if (response != null &&
//           (response.statusCode == 200 || response.statusCode == 201)) {
//         state = state.copyWith(success: true);
//         if (kDebugMode) print('✅ Sell transaction added successfully');
//         if (kDebugMode) print('Response Data: ${jsonEncode(response.data)}');
//       } else {
//         state = state.copyWith(errorMessage: 'Failed to add sell transaction');
//         if (kDebugMode) print('❌ Failed to add sell transaction');
//       }
//     } catch (e) {
//       state = state.copyWith(errorMessage: 'Error: $e'.tr);
//       if (kDebugMode) print('⚠️ Error while adding sell transaction: $e');
//     } finally {
//       state = state.copyWith(isLoading: false);
//     }
//   }
//   Future<void> sellTransActionTest(
//       WidgetRef ref, {
//         int? draftId,
//         Map<String, dynamic>? transactionCache,
//       }) async {
//     try {
//       state = state.copyWith(isLoading: true, errorMessage: null);
//
//       final cache = transactionCache ?? {};
//       final selectedCLient = ref.read(selectedClientProvider);
//
//       final client = selectedCLient?.id ?? {
//         "name": state.clientNameController.text,
//         "last_name": state.clientLastNameController.text,
//         "email": state.clientEmailController.text,
//         "phone_number": state.clientPhoneNumberController.text,
//         "description": state.clientDescriptionController.text,
//         "note": state.clientNoteController.text,
//       };
//
//
//       final transactionData = cache;
//       final requestBody = {
//         "client": client,
//         "draft": draftId ?? cache['draft'],
//         "transaction": {
//           "is_seller": transactionData['is_seller'] ?? state.transactionIsSellerController.value,
//           "is_buyer": transactionData['is_buyer'] ?? state.transactionIsBuyerController.value,
//           "name": transactionData['name'] ?? state.transactionNameController.text,
//           "commission": double.tryParse(transactionData['commission']?.toString() ?? '') ??
//               int.tryParse(state.transactionCommissionController.text) ??
//               0,
//           "amount": int.tryParse(transactionData['amount']?.toString() ?? '') ??
//               int.tryParse(state.transactionAmountController.text) ??
//               0,
//           "currency":'PLN',
//           "transaction_type": transactionData['transaction_type'] ??
//               state.transactionTypeController.text,
//           "note": transactionData['note'] ?? state.transactionNoteController.text,
//           "payment_methods": transactionData['payment_methods'] ?? [],
//           "draft": draftId ?? transactionData['draft'],
//         }
//       };
//
//       print('✅ Final Request Body: $requestBody');
//
//       final response = await ApiServices.post(
//         CrmAgentUrls.sellTransAction,
//         hasToken: true,
//         data: requestBody,
//       );
//
//       if (response != null) {
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           state = state.copyWith(success: true);
//           print('✅ Sell transaction added successfully');
//         } else if (response.statusCode == 400) {
//           final errorData = response.data;
//           state = state.copyWith(errorMessage: errorData.toString());
//           print('❌ Validation Error from API: $errorData');
//         } else {
//           state = state.copyWith(errorMessage: '❌ Failed to add sell transaction');
//           print('❌ Failed to add sell transaction with status: ${response.statusCode}');
//         }
//       }
//
//     } catch (e) {
//       state = state.copyWith(errorMessage: '❌ Error: $e');
//       print('❌ Error while adding sell transaction: $e');
//     } finally {
//       state = state.copyWith(isLoading: false);
//     }
//   }
//   Future<void> buyTransAction(WidgetRef ref) async {
//     try {
//       state = state.copyWith(isLoading: true, errorMessage: null);
//
//       final savedSearchFilters = ref.read(buyOfferFilterCacheProvider);
//
//       final requestBody = {
//         "client": {
//           "name": state.clientNameController.text,
//           "last_name": state.clientLastNameController.text,
//           "email": state.clientEmailController.text,
//           "phone_number": state.clientPhoneNumberController.text,
//           "description": state.clientDescriptionController.text,
//           "note": state.clientNoteController.text,
//         },
//         "transaction": {
//           "is_seller": state.transactionIsSellerController.value,
//           "is_buyer": state.transactionIsBuyerController.value,
//           "name": state.transactionNameController.text,
//           "commission":
//               int.tryParse(state.transactionCommissionController.text) ?? 0,
//           "amount": int.tryParse(state.transactionAmountController.text) ?? 0,
//           "currency": state.transactionCurrencyController.text,
//           "transaction_type": state.transactionTypeController.text,
//           "note": state.transactionNoteController.text,
//         },
//         "saved_search": savedSearchFilters['filters'] ?? {},
//         "event": {
//           "title":
//               state.eventTitleController.text.isEmpty
//                   ? 'Meeting with Buyer'
//                   : state.eventTitleController.text,
//           "description":
//               state.eventDescriptionController.text.isEmpty
//                   ? 'Discussing contract details.'
//                   : state.eventDescriptionController.text,
//           "location":
//               state.eventLocationController.text.isEmpty
//                   ? 'Main Office'
//                   : state.eventLocationController.text,
//         },
//       };
//       if (kDebugMode) print(requestBody);
//
//       final response = await ApiServices.post(
//         CrmAgentUrls.buyTransAction,
//         hasToken: true,
//         data: requestBody,
//       );
//
//       if (response != null &&
//           (response.statusCode == 200 || response.statusCode == 201)) {
//         state = state.copyWith(success: true);
//         if (kDebugMode) print('✅ Buy transaction added successfully');
//       } else {
//         state = state.copyWith(errorMessage: 'Failed to add buy transaction');
//         if (kDebugMode) print('❌ Failed to add buy transaction');
//       }
//     } catch (e) {
//       state = state.copyWith(errorMessage: 'Error: $e'.tr);
//       if (kDebugMode) print('⚠️ Error while adding buy transaction: $e');
//     } finally {
//       state = state.copyWith(isLoading: false);
//     }
//   }
//
//   Future<void> estateViewing() async {
//     try {
//       state = state.copyWith(isLoading: true, errorMessage: null);
//
//       final requestBody = {
//         "client": {
//           "name": state.clientNameController.text,
//           "last_name": state.clientLastNameController.text,
//           "email": state.clientEmailController.text,
//           "phone_number": state.clientPhoneNumberController.text,
//           "description": state.clientDescriptionController.text,
//           "note": state.clientNoteController.text,
//         },
//         "event": {
//           "title":
//               state.eventTitleController.text.isEmpty
//                   ? 'Meeting with Buyer'
//                   : state.eventTitleController.text,
//           "description":
//               state.eventDescriptionController.text.isEmpty
//                   ? 'Discussing contract details.'
//                   : state.eventDescriptionController.text,
//           "location":
//               state.eventLocationController.text.isEmpty
//                   ? 'Main Office'
//                   : state.eventLocationController.text,
//         },
//       };
//       if (kDebugMode) print(requestBody);
//
//       final response = await ApiServices.post(
//         CrmAgentUrls.estateViewing,
//         hasToken: true,
//         data: requestBody,
//       );
//
//       if (response != null &&
//           (response.statusCode == 200 || response.statusCode == 201)) {
//         state = state.copyWith(success: true);
//         if (kDebugMode) print('✅ Estate viewing added successfully');
//       } else {
//         state = state.copyWith(errorMessage: 'Failed to add estate viewing');
//         if (kDebugMode) print('❌ Failed to add estate viewing');
//       }
//     } catch (e) {
//       state = state.copyWith(errorMessage: 'Error: $e'.tr);
//       if (kDebugMode) print('⚠️ Error while adding estate viewing: $e');
//     } finally {
//       state = state.copyWith(isLoading: false);
//     }
//   }
//
//   void clearForm() {
//     // Clear Client Fields
//     state.clientNameController.clear();
//     state.clientLastNameController.clear();
//     state.clientPhoneNumberController.clear();
//     state.clientEmailController.clear();
//     state.clientDescriptionController.clear();
//     state.clientNoteController.clear();
//
//     // Clear Transaction Fields
//     state.transactionNameController.clear();
//     state.transactionCommissionController.clear();
//     state.transactionAmountController.clear();
//     state.transactionCurrencyController.clear();
//     state.transactionTypeController.clear();
//     state.transactionPaymentDateController.clear();
//     state.transactionNoteController.clear();
//     state.transactionIsSellerController.value = false;
//     state.transactionIsBuyerController.value = false;
//
//     // Clear Saved Search Fields
//     state.savedSearchTitleController.clear();
//     state.savedSearchDescriptionController.clear();
//     state.savedSearchTagsController.clear();
//     state.savedSearchSearchQueryController.clear();
//     state.savedSearchPriceMinController.clear();
//     state.savedSearchPriceMaxController.clear();
//     state.savedSearchRoomsController.clear();
//
//     // Clear Draft Fields
//     state.draftTitleController.clear();
//     state.draftPriceController.clear();
//     state.draftCurrencyController.clear();
//     state.draftDescriptionController.clear();
//     state.draftStreetController.clear();
//     state.draftCityController.clear();
//     state.draftStateController.clear();
//     state.draftCountryController.clear();
//     state.draftRoomsController.clear();
//     state.draftBathroomsController.clear();
//     state.draftSquareFootageController.clear();
//     state.draftOfferTypeController.clear();
//
//     // Clear Event Fields
//     state.eventTitleController.clear();
//     state.eventDescriptionController.clear();
//     state.eventLocationController.clear();
//
//     // Reset State
//     state = state.copyWith(imagesData: [], success: false, errorMessage: null);
//   }
// }
//
// final addClientFormProvider =
//     StateNotifierProvider<AddClientFormNotifier, AddClientFormState>(
//       (ref) => AddClientFormNotifier(),
//     );
