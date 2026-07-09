import 'dart:convert';
import 'package:crm_agent/crm_agent_urls.dart';

import 'package:crm_agent/add_client_form/components/sell/advertisment_information_image_widget.dart';
import 'package:crm_agent/add_client_form/components/transaction/transaction_custom_drop_down.dart';
import 'package:crm_agent/add_client_form/components/usercontact/contact_list.dart';
import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';
import 'package:crm_agent/models/viewer_provider.dart';
import 'package:crm_agent/add_client_form/widgets/transaction_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_utils/get_utils.dart';

final selectedTabProvider = StateProvider<String>((ref) => 'VIEW'.tr);

class AddClientFormState {
  final String? selectedServiceType;
  final String? selectedContactStatus;
  final String? selectedContactType;
  final String? selectedResponsiblePerson;

  // ✅ NEW: extra client fields
  final String? clientPhoneNumberPrefix; // "+48"
  final DateTime? clientBirthDate; // DateTime from date picker
  final String? clientGender; // '1'/'2'/'3' from dropdown
  final String? clientNationality; // country name (e.g. "Poland")

  // Client
  final TextEditingController clientNameController;
  final TextEditingController clientLastNameController;
  final TextEditingController clientPhoneNumberController;
  final TextEditingController clientEmailController;
  final TextEditingController clientDescriptionController;
  final TextEditingController clientNoteController;
  final int? selectedClientId;

  // Transaction
  final ValueNotifier<bool> transactionIsSellerController;
  final ValueNotifier<bool> transactionIsBuyerController;
  final TextEditingController transactionNameController;
  final TextEditingController transactionCommissionController;
  final TextEditingController transactionAmountController;
  final TextEditingController transactionTitleController;
  final TextEditingController transactionCurrencyController;
  final TextEditingController transactionTypeController;
  final TextEditingController transactionPaymentDateController;
  final TextEditingController transactionNoteController;

  // Saved Search
  final TextEditingController savedSearchTitleController;
  final TextEditingController savedSearchDescriptionController;
  final TextEditingController savedSearchTagsController;
  final TextEditingController savedSearchSearchQueryController;
  final TextEditingController savedSearchPriceMinController;
  final TextEditingController savedSearchPriceMaxController;
  final TextEditingController savedSearchRoomsController;

  // Draft
  final TextEditingController draftTitleController;
  final TextEditingController draftPriceController;
  final TextEditingController draftCurrencyController;
  final TextEditingController draftDescriptionController;
  final TextEditingController draftStreetController;
  final TextEditingController draftCityController;
  final TextEditingController draftStateController;
  final TextEditingController draftCountryController;
  final TextEditingController draftRoomsController;
  final TextEditingController draftBathroomsController;
  final TextEditingController draftSquareFootageController;
  final TextEditingController draftOfferTypeController;
  final List<Uint8List> imagesData;

  // Event
  final TextEditingController eventTitleController;
  final TextEditingController eventDescriptionController;
  final TextEditingController eventLocationController;
  final TimeOfDay? eventStartTime;
  final TimeOfDay? eventEndTime;

  // State
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  AddClientFormState({
    this.imagesData = const [],
    this.selectedServiceType,
    this.selectedContactStatus,
    this.selectedContactType,
    this.selectedResponsiblePerson,

    this.clientPhoneNumberPrefix,
    this.clientBirthDate,
    this.clientGender,
    this.clientNationality,

    // Client
    TextEditingController? clientNameController,
    TextEditingController? clientLastNameController,
    TextEditingController? clientPhoneNumberController,
    TextEditingController? clientEmailController,
    TextEditingController? clientDescriptionController,
    TextEditingController? clientNoteController,
    this.selectedClientId,

    // Transaction
    ValueNotifier<bool>? transactionIsSellerController,
    ValueNotifier<bool>? transactionIsBuyerController,
    TextEditingController? transactionNameController,
    TextEditingController? transactionCommissionController,
    TextEditingController? transactionAmountController,
    TextEditingController? transactionTitleController,
    TextEditingController? transactionCurrencyController,
    TextEditingController? transactionTypeController,
    TextEditingController? transactionPaymentDateController,
    TextEditingController? transactionNoteController,

    // Saved Search
    TextEditingController? savedSearchTitleController,
    TextEditingController? savedSearchDescriptionController,
    TextEditingController? savedSearchTagsController,
    TextEditingController? savedSearchSearchQueryController,
    TextEditingController? savedSearchPriceMinController,
    TextEditingController? savedSearchPriceMaxController,
    TextEditingController? savedSearchRoomsController,

    // Draft
    TextEditingController? draftTitleController,
    TextEditingController? draftPriceController,
    TextEditingController? draftCurrencyController,
    TextEditingController? draftDescriptionController,
    TextEditingController? draftStreetController,
    TextEditingController? draftCityController,
    TextEditingController? draftStateController,
    TextEditingController? draftCountryController,
    TextEditingController? draftRoomsController,
    TextEditingController? draftBathroomsController,
    TextEditingController? draftSquareFootageController,
    TextEditingController? draftOfferTypeController,

    // Event
    TextEditingController? eventTitleController,
    TextEditingController? eventDescriptionController,
    TextEditingController? eventLocationController,
    this.eventStartTime,
    this.eventEndTime,

    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  })  : clientNameController = clientNameController ?? TextEditingController(),
        clientLastNameController =
            clientLastNameController ?? TextEditingController(),
        clientPhoneNumberController =
            clientPhoneNumberController ?? TextEditingController(),
        clientEmailController = clientEmailController ?? TextEditingController(),
        clientDescriptionController =
            clientDescriptionController ?? TextEditingController(),
        clientNoteController = clientNoteController ?? TextEditingController(),

        transactionIsSellerController =
            transactionIsSellerController ?? ValueNotifier(false),
        transactionIsBuyerController =
            transactionIsBuyerController ?? ValueNotifier(false),
        transactionNameController =
            transactionNameController ?? TextEditingController(),
        transactionCommissionController =
            transactionCommissionController ?? TextEditingController(),
        transactionAmountController =
            transactionAmountController ?? TextEditingController(),
        transactionTitleController =
            transactionTitleController ?? TextEditingController(),
        transactionCurrencyController =
            transactionCurrencyController ?? TextEditingController(),
        transactionTypeController =
            transactionTypeController ?? TextEditingController(),
        transactionPaymentDateController =
            transactionPaymentDateController ?? TextEditingController(),
        transactionNoteController =
            transactionNoteController ?? TextEditingController(),

        savedSearchTitleController =
            savedSearchTitleController ?? TextEditingController(),
        savedSearchDescriptionController =
            savedSearchDescriptionController ?? TextEditingController(),
        savedSearchTagsController =
            savedSearchTagsController ?? TextEditingController(),
        savedSearchSearchQueryController =
            savedSearchSearchQueryController ?? TextEditingController(),
        savedSearchPriceMinController =
            savedSearchPriceMinController ?? TextEditingController(),
        savedSearchPriceMaxController =
            savedSearchPriceMaxController ?? TextEditingController(),
        savedSearchRoomsController =
            savedSearchRoomsController ?? TextEditingController(),

        draftTitleController = draftTitleController ?? TextEditingController(),
        draftPriceController = draftPriceController ?? TextEditingController(),
        draftCurrencyController =
            draftCurrencyController ?? TextEditingController(),
        draftDescriptionController =
            draftDescriptionController ?? TextEditingController(),
        draftStreetController = draftStreetController ?? TextEditingController(),
        draftCityController = draftCityController ?? TextEditingController(),
        draftStateController = draftStateController ?? TextEditingController(),
        draftCountryController =
            draftCountryController ?? TextEditingController(),
        draftRoomsController = draftRoomsController ?? TextEditingController(),
        draftBathroomsController =
            draftBathroomsController ?? TextEditingController(),
        draftSquareFootageController =
            draftSquareFootageController ?? TextEditingController(),
        draftOfferTypeController =
            draftOfferTypeController ?? TextEditingController(),

        eventTitleController = eventTitleController ?? TextEditingController(),
        eventDescriptionController =
            eventDescriptionController ?? TextEditingController(),
        eventLocationController =
            eventLocationController ?? TextEditingController();

  AddClientFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
    List<Uint8List>? imagesData,
    int? selectedClientId,
    TimeOfDay? eventStartTime,
    TimeOfDay? eventEndTime,
    String? selectedServiceType,
    String? selectedContactStatus,
    String? selectedContactType,
    String? selectedResponsiblePerson,

    String? clientPhoneNumberPrefix,
    DateTime? clientBirthDate,
    String? clientGender,
    String? clientNationality,
  }) {
    return AddClientFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      success: success ?? this.success,
      imagesData: imagesData ?? this.imagesData,
      selectedClientId: selectedClientId ?? this.selectedClientId,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      selectedServiceType: selectedServiceType ?? this.selectedServiceType,
      selectedContactStatus: selectedContactStatus ?? this.selectedContactStatus,
      selectedContactType: selectedContactType ?? this.selectedContactType,
      selectedResponsiblePerson:
          selectedResponsiblePerson ?? this.selectedResponsiblePerson,

      clientPhoneNumberPrefix:
          clientPhoneNumberPrefix ?? this.clientPhoneNumberPrefix,
      clientBirthDate: clientBirthDate ?? this.clientBirthDate,
      clientGender: clientGender ?? this.clientGender,
      clientNationality: clientNationality ?? this.clientNationality,

      // keep controllers
      clientNameController: clientNameController,
      clientLastNameController: clientLastNameController,
      clientPhoneNumberController: clientPhoneNumberController,
      clientEmailController: clientEmailController,
      clientDescriptionController: clientDescriptionController,
      clientNoteController: clientNoteController,

      transactionIsSellerController: transactionIsSellerController,
      transactionIsBuyerController: transactionIsBuyerController,
      transactionNameController: transactionNameController,
      transactionCommissionController: transactionCommissionController,
      transactionAmountController: transactionAmountController,
      transactionTitleController: transactionTitleController,
      transactionCurrencyController: transactionCurrencyController,
      transactionTypeController: transactionTypeController,
      transactionPaymentDateController: transactionPaymentDateController,
      transactionNoteController: transactionNoteController,

      savedSearchTitleController: savedSearchTitleController,
      savedSearchDescriptionController: savedSearchDescriptionController,
      savedSearchTagsController: savedSearchTagsController,
      savedSearchSearchQueryController: savedSearchSearchQueryController,
      savedSearchPriceMinController: savedSearchPriceMinController,
      savedSearchPriceMaxController: savedSearchPriceMaxController,
      savedSearchRoomsController: savedSearchRoomsController,

      draftTitleController: draftTitleController,
      draftPriceController: draftPriceController,
      draftCurrencyController: draftCurrencyController,
      draftDescriptionController: draftDescriptionController,
      draftStreetController: draftStreetController,
      draftCityController: draftCityController,
      draftStateController: draftStateController,
      draftCountryController: draftCountryController,
      draftRoomsController: draftRoomsController,
      draftBathroomsController: draftBathroomsController,
      draftSquareFootageController: draftSquareFootageController,
      draftOfferTypeController: draftOfferTypeController,

      eventTitleController: eventTitleController,
      eventDescriptionController: eventDescriptionController,
      eventLocationController: eventLocationController,
    );
  }
}

class AddClientFormNotifier extends StateNotifier<AddClientFormState> {
  AddClientFormNotifier() : super(AddClientFormState());

  void setServiceType(String? v) =>
      state = state.copyWith(selectedServiceType: v);

  void setContactStatus(String? v) =>
      state = state.copyWith(selectedContactStatus: v);

  void setContactType(String? v) =>
      state = state.copyWith(selectedContactType: v);

  void setResponsiblePerson(String? v) =>
      state = state.copyWith(selectedResponsiblePerson: v);

  void setPhoneNumberPrefix(String? v) {
    final cleaned = (v ?? '').trim();
    state = state.copyWith(
      clientPhoneNumberPrefix: cleaned.isEmpty ? null : cleaned,
    );
  }

  
  void setStartTime(TimeOfDay time) {
    if (kDebugMode) debugPrint('start time $time');
    state = state.copyWith(eventStartTime: time);
  }

  void setEndTime(TimeOfDay time) {
    if (kDebugMode) debugPrint('ent time $time');
    state = state.copyWith(eventEndTime: time);
  }

  String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void setBirthDate(DateTime? date) {
    state = state.copyWith(clientBirthDate: date);
  }

  void setGender(String? key) {
    final cleaned = (key ?? '').trim();
    state = state.copyWith(clientGender: cleaned.isEmpty ? null : cleaned);
  }

  void setNationality(String? countryName) {
    final cleaned = (countryName ?? '').trim();
    state = state.copyWith(clientNationality: cleaned.isEmpty ? null : cleaned);
  }

  void updateTextField(TextEditingController controller, String value) {
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    if (kDebugMode) debugPrint(value);
  }

  void setSelectedClientId(int? clientId) {
    state = state.copyWith(selectedClientId: clientId);
  }

  String _formatDateOnly(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic> _clientMapPayload() {
    // NOTE: birth_date empty string is sometimes rejected by APIs.
    // If your serializer accepts null, you can send null instead.
    final birth = state.clientBirthDate == null ? null : _formatDateOnly(state.clientBirthDate);

    return {
      "name": state.clientNameController.text,
      "last_name": state.clientLastNameController.text,
      "email": state.clientEmailController.text,
      "phone_number_prefix": state.clientPhoneNumberPrefix,
      "phone_number": state.clientPhoneNumberController.text,
      "gender": state.clientGender,
      "birth_date": birth,
      "nationality": state.clientNationality,
      "description": state.clientDescriptionController.text,
      "note": state.clientNoteController.text,
      // service_type belongs to AgentTransaction, not UserContact — removed
      if (state.selectedContactStatus != null)
        "contact_status": state.selectedContactStatus,
      if (state.selectedContactType != null)
        "contact_type": state.selectedContactType,
      if (state.selectedResponsiblePerson != null)
        "responsible_person": state.selectedResponsiblePerson,
    };
  }

  String _extractErrors(dynamic body) {
    try {
      dynamic decoded;
      if (body is List<int>) {
        decoded = json.decode(utf8.decode(body));
      } else if (body is String) {
        decoded = json.decode(body);
      } else {
        decoded = body;
      }

      if (decoded is Map<String, dynamic>) {
        final parts = <String>[];
        if (decoded['detail'] is String) parts.add(decoded['detail'] as String);

        if (decoded['errors'] is Map) {
          (decoded['errors'] as Map).forEach((k, v) {
            if (v is List) {
              parts.add('$k: ${v.join(", ")}');
            } else {
              parts.add('$k: $v');
            }
          });
        }

        decoded.forEach((k, v) {
          if (k == 'detail' || k == 'errors') return;
          if (v is List) {
            parts.add('$k: ${v.join(", ")}');
          } else if (v is Map) {
            final inner = v.entries
                .map((e) =>
                    '${e.key}: ${e.value is List ? (e.value as List).join(", ") : e.value}')
                .join('; ');
            parts.add('$k: $inner');
          } else {
            parts.add('$k: $v');
          }
        });

        return parts.isEmpty ? decoded.toString() : parts.join(' | ');
      } else if (decoded is List) {
        return decoded.join(' | ');
      } else {
        return decoded?.toString() ?? 'Unknown error';
      }
    } catch (_) {
      if (body is List<int>) return utf8.decode(body);
      return body?.toString() ?? 'Unknown error';
    }
  }

  Future<bool> sellTransAction(WidgetRef ref) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final sellOfferDraftData = ref.read(sellOfferFilterCacheProvider);
      final transactionCache = ref.read(agentTransactionCacheProvider);

      final selectedImages = ref.read(advertisementSelectedImagesProvider);
      final List<String> base64Images = [];
      for (final image in selectedImages) {
        final bytes = await image.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      final clientId = state.selectedClientId;

      final draft = Map<String, dynamic>.from(sellOfferDraftData['draft'] ?? {});
          final roomsValue = draft['rooms']?.toString();
          if (roomsValue != null && roomsValue.isNotEmpty) {
           draft['rooms'] = int.tryParse(roomsValue.replaceAll('+', ''));
      }
      // Nie wstrzykuj 0.0 gdy rent nie jest ustawiony — null semantycznie poprawny
      draft.putIfAbsent('rent', () => null);

      final existing =
          (draft['images'] is List) ? List<String>.from(draft['images']) : <String>[];
      draft['images'] = [...existing, ...base64Images];

      final tx = Map<String, dynamic>.from(transactionCache['transaction'] ?? {});
      tx['is_seller'] = true;
      tx['is_buyer'] = false;

      final String title = state.eventTitleController.text.trim();
      final String description = state.eventDescriptionController.text.trim();
      final String location = state.eventLocationController.text.trim();

      final Map<String, dynamic> event = {};
      if (title.isNotEmpty) event['title'] = title;
      if (description.isNotEmpty) event['description'] = description;
      if (location.isNotEmpty) event['location'] = location;

      final requestBody = {
        "client": clientId ?? _clientMapPayload(),
        "draft": draft,
        if (event.isNotEmpty) "event": event,
        "transaction": tx,
      };

      final response = await ApiServices.post(
        CrmAgentUrls.sellTransAction,
        hasToken: true,
        data: requestBody,
      );

      final ok = response != null && (response.statusCode == 200 || response.statusCode == 201);
      if (!ok) {
        final msg = response == null
            ? 'No response from server'
            : 'HTTP ${response.statusCode}: ${_extractErrors(response.data)}';
        state = state.copyWith(success: false, errorMessage: msg);
        return false;
      }

      state = state.copyWith(success: true, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error: $e'.tr);
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sellTransActionTest(WidgetRef ref, {int? draftId}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final selectedCLient = ref.read(selectedClientProvider);
      final transactionData = ref.watch(transactionControllersProvider);
      final dropdownMap = ref.read(agentTransactionDropDownProvider);
      final currency = dropdownMap[8]?.selectedValue ?? '';
      final paymentMethods = dropdownMap[7]?.selectedValue ?? '';

      final client = selectedCLient?.id ?? _clientMapPayload();

      final requestBody = {
        "client": client,
        "draft": draftId,
        "transaction": {
          "is_seller": transactionData.isSellerController.value,
          "is_buyer": transactionData.isBuyerController.value,
          "name": transactionData.nameController.text,
          "commission": int.tryParse(transactionData.commissionController.text) ?? 0,
          "amount": int.tryParse(transactionData.amountController.text) ?? 0,
          "currency": currency,
          "transaction_type": transactionData.transactionTypeController.text,
          "note": transactionData.noteController.text,
          "payment_methods": paymentMethods,
        }
      };

      if (kDebugMode) debugPrint('✅ Final Request Body: $requestBody');

      final response = await ApiServices.post(
        CrmAgentUrls.sellTransAction,
        hasToken: true,
        data: requestBody,
      );

      if (response != null) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          state = state.copyWith(success: true);
          if (kDebugMode) debugPrint('✅ Sell transaction added successfully');
        } else if (response.statusCode == 400) {
          final errorData = response.data;
          state = state.copyWith(errorMessage: errorData.toString());
          if (kDebugMode) debugPrint('❌ Validation Error from API: $errorData');
        } else {
          state = state.copyWith(errorMessage: '❌ Failed to add sell transaction');
          if (kDebugMode) {
            debugPrint('❌ Failed with status: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: '❌ Error: $e');
      if (kDebugMode) debugPrint('❌ Error while adding sell transaction: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> buyTransAction(WidgetRef ref) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final savedSearchState = ref.read(buyOfferFilterCacheProvider);
      final transactionData = ref.read(agentTransactionCacheProvider);

      final clientId = state.selectedClientId;
      final savedSearch = Map<String, dynamic>.from(
        (savedSearchState['saved_search'] as Map?)?.cast<String, dynamic>() ?? {},
      );
      // Fix: SavedSearch.title jest CharField bez blank=True — backend odrzuci pusty string
      if ((savedSearch['title'] as String? ?? '').trim().isEmpty) {
        final now = DateTime.now();
        savedSearch['title'] =
            'Search ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      }

      final String title = state.eventTitleController.text.trim();
      final String description = state.eventDescriptionController.text.trim();
      final String location = state.eventLocationController.text.trim();

      final Map<String, dynamic> event = {};
      if (title.isNotEmpty) event['title'] = title;
      if (description.isNotEmpty) event['description'] = description;
      if (location.isNotEmpty) event['location'] = location;

      final requestBody = {
        "client": clientId ?? _clientMapPayload(),
        "transaction": transactionData['transaction'] ?? {},
        "saved_search": savedSearch,
        if (event.isNotEmpty) "event": event,
      };

      if (kDebugMode) debugPrint('🚀 Final Request Body: $requestBody');

      final response = await ApiServices.post(
        CrmAgentUrls.buyTransAction,
        hasToken: true,
        data: requestBody,
      );

      final ok = response != null && (response.statusCode == 200 || response.statusCode == 201);
      if (!ok) {
        final msg = response == null
            ? 'No response from server'
            : 'HTTP ${response.statusCode}: ${_extractErrors(response.data)}';
        state = state.copyWith(success: false, errorMessage: msg);
        if (kDebugMode) debugPrint('❌ Failed to add buy transaction -> $msg');
        return false;
      }

      state = state.copyWith(success: true, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error: $e'.tr);
      if (kDebugMode) debugPrint('⚠️ Error while adding buy transaction: $e');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> estateViewing(WidgetRef ref) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final transactionId = ref.read(selectedTransactionProvider)?.id;

      final String title = state.eventTitleController.text.trim();
      final String description = state.eventDescriptionController.text.trim();
      final String location = state.eventLocationController.text.trim();

      final Map<String, dynamic> event = {};
      if (title.isNotEmpty) event['title'] = title;
      if (description.isNotEmpty) event['description'] = description;
      if (location.isNotEmpty) event['location'] = location;

      final clientId = state.selectedClientId;
      final clientPayload = clientId ?? _clientMapPayload();

      final Map<String, dynamic> requestBody = {
        "client": clientPayload,
        "transaction_id": transactionId,
        if (event.isNotEmpty) "event": event,
      };

      if (kDebugMode) debugPrint(requestBody.toString());

      final response = await ApiServices.post(
        CrmAgentUrls.estateViewing,
        hasToken: true,
        data: requestBody,
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        state = state.copyWith(success: true);
        if (transactionId != null) {
          ref.invalidate(viewersForTransactionProvider(transactionId));
        }
        if (kDebugMode) debugPrint('✅ Estate viewing added successfully');
      } else {
        final status = response?.statusCode;
        final msg = response == null
            ? 'No response from server'
            : 'HTTP $status: ${_extractErrors(response.data)}';

        state = state.copyWith(errorMessage: msg);
        if (kDebugMode) debugPrint('❌ Failed to add estate viewing -> $msg');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error: $e'.tr);
      if (kDebugMode) debugPrint('⚠️ Error while adding estate viewing: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearForm() {
    state.clientNameController.clear();
    state.clientLastNameController.clear();
    state.clientPhoneNumberController.clear();
    state.clientEmailController.clear();
    state.clientDescriptionController.clear();
    state.clientNoteController.clear();

    state.eventTitleController.clear();
    state.eventDescriptionController.clear();
    state.eventLocationController.clear();

    state = state.copyWith(
      selectedClientId: null,
      imagesData: [],
      success: false,
      errorMessage: null,
      clientPhoneNumberPrefix: null,
      clientBirthDate: null,
      clientGender: null,
      clientNationality: null,
    );
  }
}

final addClientFormProvider =
    StateNotifierProvider<AddClientFormNotifier, AddClientFormState>(
  (ref) => AddClientFormNotifier(),
);
