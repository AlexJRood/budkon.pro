import 'dart:convert';
import 'dart:typed_data';
import 'package:crm/crm_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_provider.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

class InvoiceFormState {
  final TextEditingController companyNameController;
  final TextEditingController taxIdController;
  final TextEditingController addressController;
  final TextEditingController zipCodeController;
  final TextEditingController cityController;
  final TextEditingController countryController;
  final TextEditingController notesController;
  final TextEditingController legalNameController;
  final TextEditingController regonController;
  final TextEditingController websiteController;
  final TextEditingController contactPersonController;
  final TextEditingController bankAccountController;
  final TextEditingController registeredCountryController;
  final TextEditingController registeredCityController;
  final TextEditingController registeredStreetController;
  final TextEditingController registeredPostalCodeController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController genderController;
  final TextEditingController nationalityController;
  final TextEditingController nipController;
  DateTime? birthDate;
  String gender;
  String country;
  final List<FocusNode> focusNodes;
  final List<FocusNode> reqNodes;

  InvoiceFormState({
    TextEditingController? companyName,
    TextEditingController? taxId,
    TextEditingController? address,
    TextEditingController? zipCode,
    TextEditingController? city,
    TextEditingController? countryController,
    TextEditingController? notes,
    TextEditingController? legalName,
    TextEditingController? regon,
    TextEditingController? website,
    TextEditingController? contactPerson,
    TextEditingController? bankAccount,
    TextEditingController? registeredCountry,
    TextEditingController? registeredCity,
    TextEditingController? registeredStreet,
    TextEditingController? registeredPostalCode,
    TextEditingController? nip,
    TextEditingController? firstName,
    TextEditingController? lastName,
    TextEditingController? email,
    TextEditingController? phone,
    TextEditingController? genderController,
    TextEditingController? nationality,
    List<FocusNode>? focusNodes,
    List<FocusNode>? reqNodes,

    this.birthDate,
    this.gender = '',
    this.country = '',
  }) : companyNameController = companyName ?? TextEditingController(),
       taxIdController = taxId ?? TextEditingController(),
       addressController = address ?? TextEditingController(),
       zipCodeController = zipCode ?? TextEditingController(),
       cityController = city ?? TextEditingController(),
       countryController = countryController ?? TextEditingController(),
       notesController = notes ?? TextEditingController(),
       legalNameController = legalName ?? TextEditingController(),
       regonController = regon ?? TextEditingController(),
       websiteController = website ?? TextEditingController(),
       contactPersonController = contactPerson ?? TextEditingController(),
       bankAccountController = bankAccount ?? TextEditingController(),
       registeredCountryController =
           registeredCountry ?? TextEditingController(),
       registeredCityController = registeredCity ?? TextEditingController(),
       registeredStreetController = registeredStreet ?? TextEditingController(),
       registeredPostalCodeController =
           registeredPostalCode ?? TextEditingController(),
       firstNameController = firstName ?? TextEditingController(),
       lastNameController = lastName ?? TextEditingController(),
       emailController = email ?? TextEditingController(),
       phoneController = phone ?? TextEditingController(),
       genderController = genderController ?? TextEditingController(),
       nationalityController = nationality ?? TextEditingController(),
       focusNodes = focusNodes ?? List.generate(25, (_) => FocusNode()),
       nipController = nip ?? TextEditingController(),
       reqNodes = reqNodes ?? List.generate(25, (_) => FocusNode());

  InvoiceFormState copyWith({
    TextEditingController? companyName,
    TextEditingController? taxId,
    TextEditingController? address,
    TextEditingController? zipCode,
    TextEditingController? city,
    TextEditingController? countryController,
    TextEditingController? notes,
    TextEditingController? legalName,
    TextEditingController? regon,
    TextEditingController? website,
    TextEditingController? contactPerson,
    TextEditingController? bankAccount,
    TextEditingController? registeredCountry,
    TextEditingController? registeredCity,
    TextEditingController? registeredStreet,
    TextEditingController? registeredPostalCode,
    TextEditingController? firstName,
    TextEditingController? lastName,
    TextEditingController? email,
    TextEditingController? phone,
    TextEditingController? genderController,
    TextEditingController? nationality,
    List<FocusNode>? focusNodes,
    List<FocusNode>? reqNodes,
    DateTime? birthDate,
    String? gender,
    String? country,
    TextEditingController? nip,
  }) {
    return InvoiceFormState(
      nip: nip ?? nipController,
      companyName: companyName ?? companyNameController,
      taxId: taxId ?? taxIdController,
      address: address ?? addressController,
      zipCode: zipCode ?? zipCodeController,
      city: city ?? cityController,
      countryController: countryController ?? this.countryController,
      notes: notes ?? notesController,
      legalName: legalName ?? legalNameController,
      regon: regon ?? regonController,
      website: website ?? websiteController,
      contactPerson: contactPerson ?? contactPersonController,
      bankAccount: bankAccount ?? bankAccountController,
      registeredCountry: registeredCountry ?? registeredCountryController,
      registeredCity: registeredCity ?? registeredCityController,
      registeredStreet: registeredStreet ?? registeredStreetController,
      registeredPostalCode:
          registeredPostalCode ?? registeredPostalCodeController,
      firstName: firstName ?? firstNameController,
      lastName: lastName ?? lastNameController,
      email: email ?? emailController,
      phone: phone ?? phoneController,
      genderController: genderController ?? this.genderController,
      nationality: nationality ?? nationalityController,
      focusNodes: focusNodes ?? this.focusNodes,
      reqNodes: reqNodes ?? this.reqNodes,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      country: country ?? this.country,
    );
  }
}

class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  InvoiceFormNotifier() : super(InvoiceFormState());

  void clear() {
    for (final c in [
      state.companyNameController,
      state.taxIdController,
      state.addressController,
      state.zipCodeController,
      state.cityController,
      state.countryController,
      state.notesController,
      state.legalNameController,
      state.regonController,
      state.websiteController,
      state.contactPersonController,
      state.bankAccountController,
      state.registeredCountryController,
      state.registeredCityController,
      state.registeredStreetController,
      state.registeredPostalCodeController,
      state.firstNameController,
      state.lastNameController,
      state.emailController,
      state.phoneController,
      state.genderController,
      state.nationalityController,
      state.nipController,
    ]) {
      c.clear();
    }

    state = state.copyWith(birthDate: null, gender: '', country: '');
  }

  void initFrom(UserContactModel user) {
    state.firstNameController.text = user.name;
    state.lastNameController.text = user.lastName ?? '';
    state.emailController.text = user.email ?? '';
    state.phoneController.text = user.phoneNumber ?? '';
    state.gender = user.gender ?? '';
    state.country = user.nationality ?? '';
    state.birthDate = user.birthDate;

    final inv = user.invoiceData;
    state.legalNameController.text = inv?.legalName ?? '';
    state.nipController.text = inv?.nip ?? '';
    state.regonController.text = inv?.regon ?? '';
    state.notesController.text = inv?.notes ?? '';
    state.contactPersonController.text = inv?.contactPerson ?? '';
    state.bankAccountController.text = inv?.bankAccount ?? '';
    state.websiteController.text = inv?.website ?? '';
    state.registeredCountryController.text = inv?.registeredCountry ?? '';
    state.registeredCityController.text = inv?.registeredCity ?? '';
    state.registeredStreetController.text = inv?.registeredStreet ?? '';
    state.registeredPostalCodeController.text = inv?.registeredPostalCode ?? '';
  }

  void setRegisteredCountry(String value) {
    state.registeredCountryController.text = value;
    state = state.copyWith();
  }
}

final invoiceFormProvider =
    StateNotifierProvider<InvoiceFormNotifier, InvoiceFormState>(
      (ref) => InvoiceFormNotifier(),
    );

class ActiveContactNotifier extends StateNotifier<UserContactModel?> {
  final Ref ref;

  ActiveContactNotifier(this.ref) : super(null);

  Future<void> fetchUserContactData(String clientId) async {
    try {
      final response = await ApiServices.get(
        CrmUrls.singleUserContacts(clientId),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final rawData = response.data;

        final decoded =
            rawData is Uint8List ? jsonDecode(utf8.decode(rawData)) : rawData;

        state = UserContactModel.fromJson(decoded);
      } else {
        state = null;
      }
    } catch (e) {
      debugPrint('❌ fetchUserContactData error: $e');
      state = null;
    }
  }

  Future<void> updateUserContactData({
    required String clientId,
    required InvoiceFormState form,
    required WidgetRef ref,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "name": form.firstNameController.text.trim(),
        "last_name": form.lastNameController.text.trim(),
        "email": form.emailController.text.trim(),
        "phone_number": form.phoneController.text.trim(),
        "gender": form.gender.isNotEmpty ? form.gender : null,
        "birth_date": form.birthDate?.toIso8601String(),
        "nationality": form.country.isNotEmpty ? form.country : null,
      };

      final response = await ApiServices.patch(
        CrmUrls.updateUserContactData(clientId),
        data: data,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ User contact data updated successfully!');
        ref.invalidate(recentContactsProvider);
        ref.read(contactEditStateProvider.notifier).state = false;
      } else {
        debugPrint('❌ Failed to update user contact: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ updateUserContactData error: $e');
    }
  }

  Future<void> updateInvoiceData({
    required String invoiceDataId,
    required String clientId,
    required InvoiceFormState form,
    required WidgetRef ref,
  }) async {
    try {
      final data = _invoicePayload(
        clientId: clientId,
        form: form,
      );

      data.remove('client');

      final response = await ApiServices.patch(
        CrmUrls.updateInvoiceData(invoiceDataId),
        data: data,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Invoice data updated successfully!');

        await fetchUserContactData(clientId);

        ref.invalidate(recentContactsProvider);
        ref.read(invoiceEditStateProvider.notifier).state = false;
      } else {
        debugPrint('❌ Failed to update invoice data: ${response?.statusCode}');
        debugPrint('❌ Response data: ${response?.data}');
      }
    } catch (e) {
      debugPrint('❌ updateInvoiceData error: $e');
    }
  }


    String _normalizeBankAccountForSave(String value) {
    var raw = value.trim().toUpperCase();
    raw = raw.replaceAll(' ', '').replaceAll('-', '');

    if (raw.startsWith('PL')) {
      raw = raw.substring(2);
    }

    return raw.replaceAll(RegExp(r'\D'), '');
  }

  Map<String, dynamic> _invoicePayload({
    required String clientId,
    required InvoiceFormState form,
  }) {
    return {
      "client": int.tryParse(clientId) ?? clientId,
      "legal_name": form.legalNameController.text.trim(),
      "nip": form.nipController.text.trim(),
      "regon": form.regonController.text.trim(),
      "website": form.websiteController.text.trim(),
      "contact_person": form.contactPersonController.text.trim(),
      "bank_account": _normalizeBankAccountForSave(
        form.bankAccountController.text,
      ),
      "notes": form.notesController.text.trim(),
      "registered_country": form.registeredCountryController.text.trim(),
      "registered_city": form.registeredCityController.text.trim(),
      "registered_street": form.registeredStreetController.text.trim(),
      "registered_postal_code":
          form.registeredPostalCodeController.text.trim(),

      // Optionalnie wypełniamy też zwykły adres tym samym,
      // bo model ma country/city/street/postal_code osobno.
      "country": form.registeredCountryController.text.trim(),
      "city": form.registeredCityController.text.trim(),
      "street": form.registeredStreetController.text.trim(),
      "postal_code": form.registeredPostalCodeController.text.trim(),

      "is_verified": true,
    };
  }

  Future<void> createInvoiceData({
    required String clientId,
    required InvoiceFormState form,
    required WidgetRef ref,
  }) async {
    try {
      final data = _invoicePayload(
        clientId: clientId,
        form: form,
      );

      final response = await ApiServices.post(
        '${URLs.baseUrl}/contacts/invoice-data/',
        data: data,
        hasToken: true,
        ref: ref,
      );

      if (response != null &&
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('✅ Invoice data created successfully!');

        await fetchUserContactData(clientId);

        ref.invalidate(recentContactsProvider);
        ref.read(invoiceEditStateProvider.notifier).state = false;
      } else {
        debugPrint('❌ Failed to create invoice data: ${response?.statusCode}');
        debugPrint('❌ Response data: ${response?.data}');
      }
    } catch (e) {
      debugPrint('❌ createInvoiceData error: $e');
    }
  }
}

final activeContactProvider =
    StateNotifierProvider<ActiveContactNotifier, UserContactModel?>(
      (ref) => ActiveContactNotifier(ref),
    );

final contactEditStateProvider = StateProvider<bool>((ref) => false);
final invoiceEditStateProvider = StateProvider<bool>((ref) => false);
