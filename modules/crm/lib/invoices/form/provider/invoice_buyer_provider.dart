import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/gus.dart';

enum InvoiceBuyerMode {
  existingContact,
  newContactFromGus,
  oneTime,
}

extension InvoiceBuyerModeX on InvoiceBuyerMode {
  String get backendValue {
    switch (this) {
      case InvoiceBuyerMode.existingContact:
        return 'existing_contact';
      case InvoiceBuyerMode.newContactFromGus:
        return 'new_contact_from_gus';
      case InvoiceBuyerMode.oneTime:
        return 'one_time';
    }
  }
}

class InvoiceBuyerDraft {
  final InvoiceBuyerMode mode;

  final int? clientId;
  final int? clientInvoiceId;
  final int? contractorId;

  final String legalName;
  final String nip;
  final String regon;
  final String email;
  final String phone;
  final String website;
  final String contactPerson;
  final String bankAccount;

  final String country;
  final String city;
  final String street;
  final String postalCode;

  final bool fromGus;

  const InvoiceBuyerDraft({
    this.mode = InvoiceBuyerMode.oneTime,
    this.clientId,
    this.clientInvoiceId,
    this.contractorId,
    this.legalName = '',
    this.nip = '',
    this.regon = '',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.contactPerson = '',
    this.bankAccount = '',
    this.country = 'Poland',
    this.city = '',
    this.street = '',
    this.postalCode = '',
    this.fromGus = false,
  });

  bool get hasBuyerData {
    return legalName.trim().isNotEmpty ||
        nip.trim().isNotEmpty ||
        regon.trim().isNotEmpty ||
        email.trim().isNotEmpty ||
        phone.trim().isNotEmpty ||
        city.trim().isNotEmpty ||
        street.trim().isNotEmpty ||
        postalCode.trim().isNotEmpty;
  }

  bool get hasData => hasBuyerData;

  bool get shouldCreateContact => mode == InvoiceBuyerMode.newContactFromGus;

  bool get isOneTimeInvoice => mode == InvoiceBuyerMode.oneTime;

  bool get isExistingContact => mode == InvoiceBuyerMode.existingContact;

  Map<String, dynamic> toBuyerInvoiceDataPayload() {
    final payload = <String, dynamic>{
      'legal_name': legalName.trim(),
      'company_name': legalName.trim(),
      'name': legalName.trim(),
      'nip': nip.trim(),
      'tax_number': nip.trim(),
      'regon': regon.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'phone_number': phone.trim(),
      'website': website.trim(),
      'contact_person': contactPerson.trim(),
      'bank_account': bankAccount.trim(),
      'country': country.trim(),
      'city': city.trim(),
      'street': street.trim(),
      'postal_code': postalCode.trim(),
      'registered_country': country.trim(),
      'registered_city': city.trim(),
      'registered_street': street.trim(),
      'registered_postal_code': postalCode.trim(),
      'source': fromGus ? 'gus' : 'manual',
    };

    payload.removeWhere((_, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    return payload;
  }

  // Backward compatibility if some old widgets still call this.
  Map<String, dynamic> toBuyerSnapshotPayload() => toBuyerInvoiceDataPayload();

  // Backward compatibility if old code still uses direct contact creation.
  // New create invoice provider does NOT call this anymore.
  Map<String, dynamic> toContactPayload() {
    return {
      'name': legalName.trim(),
      'email': email.trim(),
      'phone_number': phone.trim(),
      'note': fromGus
          ? 'Kontakt przygotowany z danych GUS podczas wystawiania faktury.'
          : 'Kontakt przygotowany podczas wystawiania faktury.',
      'invoice_data': toBuyerInvoiceDataPayload(),
    }..removeWhere((_, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        if (value is Map && value.isEmpty) return true;
        return false;
      });
  }

  InvoiceBuyerDraft copyWith({
    InvoiceBuyerMode? mode,
    int? clientId,
    bool clearClientId = false,
    int? clientInvoiceId,
    bool clearClientInvoiceId = false,
    int? contractorId,
    bool clearContractorId = false,
    String? legalName,
    String? nip,
    String? regon,
    String? email,
    String? phone,
    String? website,
    String? contactPerson,
    String? bankAccount,
    String? country,
    String? city,
    String? street,
    String? postalCode,
    bool? fromGus,
  }) {
    return InvoiceBuyerDraft(
      mode: mode ?? this.mode,
      clientId: clearClientId ? null : clientId ?? this.clientId,
      clientInvoiceId:
          clearClientInvoiceId ? null : clientInvoiceId ?? this.clientInvoiceId,
      contractorId: clearContractorId ? null : contractorId ?? this.contractorId,
      legalName: legalName ?? this.legalName,
      nip: nip ?? this.nip,
      regon: regon ?? this.regon,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      contactPerson: contactPerson ?? this.contactPerson,
      bankAccount: bankAccount ?? this.bankAccount,
      country: country ?? this.country,
      city: city ?? this.city,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      fromGus: fromGus ?? this.fromGus,
    );
  }
}

class InvoiceBuyerNotifier extends StateNotifier<InvoiceBuyerDraft> {
  InvoiceBuyerNotifier() : super(const InvoiceBuyerDraft());

  String _string(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  String _firstValue(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      for (final key in keys) {
        final value = _string(map[key]);
        if (value.isNotEmpty) return value;
      }
    }

    return '';
  }

  String _joinParts(List<String> parts) {
    return parts
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty && v.toLowerCase() != 'null')
        .join(' ')
        .trim();
  }

  void setMode(InvoiceBuyerMode mode) {
    state = state.copyWith(
      mode: mode,
      clearClientId: mode != InvoiceBuyerMode.existingContact,
      clearClientInvoiceId: mode != InvoiceBuyerMode.existingContact,
      clearContractorId: mode != InvoiceBuyerMode.existingContact,
    );
  }

  void setExistingContact({
    required int? clientId,
    int? clientInvoiceId,
    int? contractorId,
  }) {
    state = state.copyWith(
      mode: InvoiceBuyerMode.existingContact,
      clientId: clientId,
      clientInvoiceId: clientInvoiceId,
      contractorId: contractorId,
    );
  }

  void setExistingContactId(int? clientId) {
    setExistingContact(clientId: clientId);
  }

  void setManual({
    String? legalName,
    String? nip,
    String? regon,
    String? email,
    String? phone,
    String? website,
    String? contactPerson,
    String? bankAccount,
    String? country,
    String? city,
    String? street,
    String? postalCode,
  }) {
    state = state.copyWith(
      legalName: legalName,
      nip: nip,
      regon: regon,
      email: email,
      phone: phone,
      website: website,
      contactPerson: contactPerson,
      bankAccount: bankAccount,
      country: country,
      city: city,
      street: street,
      postalCode: postalCode,
      fromGus: false,
    );
  }

  void applyGusSuggestion(CoreGusSuggestion suggestion) {
    final invoice = suggestion.invoiceDataPrefill;
    final contractor = suggestion.contractorPrefill;
    final company = suggestion.companyPrefill;

    final maps = <Map<String, dynamic>>[
      invoice,
      contractor,
      company,
    ];

    String first(List<String> keys) => _firstValue(maps, keys);

    final legalName = first([
      'legal_name',
      'company_name',
      'name',
      'Nazwa',
    ]);

    final nip = first([
      'nip',
      'Nip',
      'tax_number',
    ]);

    final regon = first([
      'regon',
      'Regon',
    ]);

    final country = first([
      'registered_country',
      'reg_country',
      'country',
      'Kraj',
    ]);

    final city = first([
      'registered_city',
      'reg_city',
      'city',
      'Miejscowosc',
      'miejscowosc',
    ]);

    final directStreet = first([
      'registered_street',
      'street',
      'address',
      'reg_address',
    ]);

    final streetName = first([
      'reg_street',
      'street_name',
      'Ulica',
      'ulica',
    ]);

    final buildingNumber = first([
      'reg_street_number',
      'street_number',
      'building_number',
      'NrNieruchomosci',
      'nr_nieruchomosci',
    ]);

    final apartmentNumber = first([
      'apartment_number',
      'NrLokalu',
      'nr_lokalu',
    ]);

    final street = directStreet.isNotEmpty
        ? directStreet
        : _joinParts([
            streetName,
            buildingNumber,
            if (apartmentNumber.isNotEmpty) '/$apartmentNumber',
          ]);

    final postalCode = first([
      'registered_postal_code',
      'reg_postal_code',
      'postal_code',
      'KodPocztowy',
      'kod_pocztowy',
    ]);

    final website = first([
      'website',
      'www',
      'adres_strony_internetowej',
    ]);

    state = state.copyWith(
      legalName: legalName,
      nip: nip.isNotEmpty ? nip : suggestion.nip,
      regon: regon.isNotEmpty ? regon : suggestion.regon,
      country: country.isNotEmpty ? country : 'Poland',
      city: city,
      street: street,
      postalCode: postalCode,
      website: website,
      fromGus: true,
    );
  }

  void clearBuyerData({bool keepMode = true}) {
    final mode = keepMode ? state.mode : InvoiceBuyerMode.oneTime;

    state = InvoiceBuyerDraft(mode: mode);
  }

  void clear() {
    state = const InvoiceBuyerDraft();
  }
}

final invoiceBuyerProvider =
    StateNotifierProvider<InvoiceBuyerNotifier, InvoiceBuyerDraft>(
  (ref) => InvoiceBuyerNotifier(),
);