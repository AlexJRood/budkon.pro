class NetworkBrowseListModel {
  final int id;
  final BoolFields boolFields;
  final OfferData offerData;
  final AdditionalInfo additionalInfo;
  final String? address;
  final Images images;
  final Offerer offerer;
  final OffererPhone offererPhone;
  final ListingCounter listingCounter;
  final String url;
  final String estateType;
  final String? offerType;
  final String price;
  final String? currency;
  final String pricePerM2;
  final String? rent;
  final String title;
  final String description;
  final double squareFootage;  // changed to double
  final int? rooms;
  final int? bathroomNumber;
  final int? floor;
  final int? floorsNum;
  final String? estateCondition;
  final String? heatingType;
  final String? landArea;
  final String? buildingType;
  final String? energyCertificate;
  final String marketType;
  final int? buildYear;

  NetworkBrowseListModel({
    required this.id,
    required this.boolFields,
    required this.offerData,
    required this.additionalInfo,
    required this.address,
    required this.images,
    required this.offerer,
    required this.offererPhone,
    required this.listingCounter,
    required this.url,
    required this.estateType,
    required this.offerType,
    required this.price,
    required this.currency,
    required this.pricePerM2,
    required this.rent,
    required this.title,
    required this.description,
    required this.squareFootage,
    required this.rooms,
    required this.bathroomNumber,
    required this.floor,
    required this.floorsNum,
    required this.estateCondition,
    required this.heatingType,
    required this.landArea,
    required this.buildingType,
    required this.energyCertificate,
    required this.marketType,
    required this.buildYear,
  });

  factory NetworkBrowseListModel.fromJson(Map<String, dynamic> json) {
    return NetworkBrowseListModel(
      id: _safeParseInt(json['id']) ?? 0,
      boolFields: BoolFields.fromJson(json['bool_fields']),
      offerData: OfferData.fromJson(json['offer_data']),
      additionalInfo: AdditionalInfo.fromJson(json['additional_info']),
      address: json['address'],
      images: Images.fromJson(json['images']),
      offerer: Offerer.fromJson(json['offerer']),
      offererPhone: OffererPhone.fromJson(json['offerer_phone']),
      listingCounter: ListingCounter.fromJson(json['listing_counter']),
      url: json['url'] ?? '',
      estateType: json['estate_type'] ?? '',
      offerType: json['offer_type'],
      price: json['price'] ?? '',
      currency: json['currency'],
      pricePerM2: json['price_per_m2'] ?? '',
      rent: json['rent'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      squareFootage: _parseSquareFootage(json['square_footage']),
      rooms: _safeParseInt(json['rooms']),
      bathroomNumber: _safeParseInt(json['bathrooms']),
      floor: _safeParseInt(json['floor']),
      floorsNum: _safeParseInt(json['floors_num']),
      estateCondition: json['estate_condition'],
      heatingType: json['heating_type'],
      landArea: json['land_area'],
      buildingType: json['building_type'],
      energyCertificate: json['energy_certificate'],
      marketType: json['market_type'] ?? '',
      buildYear: _safeParseInt(json['build_year']),
    );
  }
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _parseSquareFootage(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}

class BoolFields {
  final bool? garden;

  BoolFields({this.garden});

  factory BoolFields.fromJson(Map<String, dynamic> json) {
    return BoolFields(
      garden: json['garden'],
    );
  }
}

class OfferData {
  final String siteId;

  OfferData({required this.siteId});

  factory OfferData.fromJson(Map<String, dynamic> json) {
    return OfferData(
      siteId: json['site_id'] ?? '',
    );
  }
}

class AdditionalInfo {
  final String? location;
  final String? plotType;

  AdditionalInfo({this.location, this.plotType});

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) {
    return AdditionalInfo(
      location: json['location'],
      plotType: json['plot_type'],
    );
  }
}

class Images {
  final List<String> images;

  Images({required this.images});

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class Offerer {
  final String advertiserName;

  Offerer({required this.advertiserName});

  factory Offerer.fromJson(Map<String, dynamic> json) {
    return Offerer(
      advertiserName: json['advertiser_name'] ?? '',
    );
  }
}

class OffererPhone {
  final String advertiserPhone;

  OffererPhone({required this.advertiserPhone});

  factory OffererPhone.fromJson(Map<String, dynamic> json) {
    return OffererPhone(
      advertiserPhone: json['advertiser_phone'] ?? '',
    );
  }
}

class ListingCounter {
  final int? viewCount;

  ListingCounter({this.viewCount});

  factory ListingCounter.fromJson(Map<String, dynamic> json) {
    return ListingCounter(
      viewCount: json['view_count'],
    );
  }
}
