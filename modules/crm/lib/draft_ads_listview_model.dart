import 'dart:convert';

import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';

class DraftAdsListViewModel {
  final int id;
  final String address;
  final String title;
  final double price;
  final String currency;
  final String description;
  final List<String> images;

  final int? floor;
  final int? totalFloors;

  final String street;
  final String city;
  final String district;
  final String state;
  final String zipcode;

  final int? rooms;
  final int? bathrooms;
  final double squareFootage;
  final double? lotSize;

  final String propertyForm;
  final String marketType;
  final String offerType;
  final String country;
  final String? phoneNumber;

  final double latitude;
  final double longitude;

  final String? heatingType;
  final String? buildingMaterial;
  final int? buildYear;

  final bool? balcony;
  final bool? terrace;
  final bool? sauna;
  final bool? jacuzzi;
  final bool? basement;
  final bool? elevator;
  final bool? garden;
  final bool? airConditioning;
  final bool? garage;
  final bool? parkingSpace;

  final String? status;

  const DraftAdsListViewModel({
    required this.id,
    required this.address,
    required this.title,
    required this.price,
    required this.currency,
    required this.description,
    required this.images,
    required this.floor,
    required this.totalFloors,
    required this.street,
    required this.city,
    required this.district,
    required this.state,
    required this.zipcode,
    required this.rooms,
    required this.bathrooms,
    required this.squareFootage,
    required this.lotSize,
    required this.propertyForm,
    required this.marketType,
    required this.offerType,
    required this.country,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.heatingType,
    this.buildingMaterial,
    this.buildYear,
    this.balcony,
    this.terrace,
    this.sauna,
    this.jacuzzi,
    this.basement,
    this.elevator,
    this.garden,
    this.airConditioning,
    this.garage,
    this.parkingSpace,
    this.status,
  });

  factory DraftAdsListViewModel.fromJson(Map<String, dynamic> json) {
    final imagesList = _readImages(json['images']);

    return DraftAdsListViewModel(
      id: _toInt(json['id']) ?? 0,
      address: _toStringSafe(
        json['address'] ?? json['adrress'] ?? json['full_address'],
      ),
      title: _toStringSafe(json['title']),
      price: _toDouble(json['price']) ?? 0.0,
      currency: _toStringSafe(json['currency'], fallback: 'PLN'),
      description: _toStringSafe(json['description']),
      images: imagesList,
      floor: _toInt(json['floor']),
      totalFloors: _toInt(json['total_floors']),
      street: _toStringSafe(json['street']),
      city: _toStringSafe(json['city']),
      district: _toStringSafe(json['district']),
      state: _toStringSafe(json['state']),
      zipcode: _toStringSafe(json['zipcode']),
      rooms: _toInt(json['rooms']),
      bathrooms: _toInt(json['bathrooms']),
      squareFootage: _toDouble(
            json['square_footage'] ?? json['squareFootage'] ?? json['area'],
          ) ??
          0.0,
      lotSize: _toDouble(json['lot_size']),
      propertyForm: _toStringSafe(json['property_form']),
      marketType: _toStringSafe(json['market_type']),
      offerType: _toStringSafe(json['offer_type']),
      country: _toStringSafe(json['country']),
      phoneNumber: json['phone_number']?.toString(),
      latitude: _toDouble(json['latitude']) ?? 0.0,
      longitude: _toDouble(json['longitude']) ?? 0.0,
      heatingType: _nullableString(json['heating_type']),
      buildingMaterial: _nullableString(json['building_material']),
      buildYear: _toInt(json['build_year']),
      balcony: _toBool(json['balcony']),
      terrace: _toBool(json['terrace']),
      sauna: _toBool(json['sauna']),
      jacuzzi: _toBool(json['jacuzzi']),
      basement: _toBool(json['basement']),
      elevator: _toBool(json['elevator']),
      garden: _toBool(json['garden']),
      airConditioning: _toBool(json['air_conditioning']),
      garage: _toBool(json['garage']),
      parkingSpace: _toBool(json['parking_space']),
      status: _nullableString(json['status']),
    );
  }

  String? get mainImageUrl => images.isNotEmpty ? images.first : null;

  List<String> get advertisementImages => images;

  double get pricePerSquareMeter {
    if (squareFootage <= 0) return 0.0;
    return price / squareFootage;
  }

  String get fullAddress {
    final parts = <String>[
      if (street.trim().isNotEmpty) street.trim(),
      if (district.trim().isNotEmpty) district.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (zipcode.trim().isNotEmpty) zipcode.trim(),
      if (country.trim().isNotEmpty) country.trim(),
    ];
    return parts.join(', ');
  }

  static List<String> _readImages(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        return [raw];
      }
    }

    return <String>[];
  }

  static String _toStringSafe(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }

    return null;
  }
}

AgentTransactionModel convertDraftToTransaction(DraftAdsListViewModel draft) {
  return AgentTransactionModel(
    id: 0,
    client: UserContactModel(
      id: 0,
      lastName: '',
      email: '',
      phoneNumber: '',
      avatar: null,
      name: '',
    ),
    isSeller: true,
    isBuyer: false,
    name: draft.title,
    commission: '0.00',
    amount: draft.price.toString(),
    currency: draft.currency,
    transactionType: draft.offerType,
    dateCreate: DateTime.now(),
    dateUpdate: DateTime.now(),
    paymentDate: null,
    isMonthlyPayment: false,
    whenMonthlyPaymentIsOver: null,
    note: draft.description,
    transactionName: draft.title,
    invoiceNumber: null,
    invoiceData: const {},
    sendInvoiceEmail: false,
    documents: draft.images,
    tags: const [],
    paymentMethods: null,
    status: 'draft',
    isPaid: false,
    country: draft.country,
    city: draft.city,
    street: draft.street,
    postalCode: draft.zipcode,
    taxAmount: null,
    draft: draft.id,
    isCommisssionPercentage: true,
    createdBy: 1,
    isComplete: false,
    isArchive: false,
  );
}