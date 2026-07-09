import 'dart:convert';
import 'package:intl/intl.dart';
import 'fav_status.dart';

/// ---------- HELPERY PARSUJĄCE ----------

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) {
    final s = v.replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(',', '.').trim();
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }
  return null;
}

int? _asInt(dynamic v) => _asNum(v)?.toInt();

bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  if (['1', 'true', 'tak', 'yes'].contains(s)) return true;
  if (['0', 'false', 'nie', 'no', 'null', ''].contains(s)) return false;
  return null;
}

String? _asString(dynamic v) => v == null ? null : v.toString();


List<String>? _parseImages(dynamic v) {
  if (v == null) return null;

  // String: może być zwykłym URL-em lub JSON-em (list/map)
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    try {
      final decoded = jsonDecode(s);
      return _parseImages(decoded); // rekurencyjnie znormalizuj
    } catch (_) {
      return [s]; // zwykły URL w stringu
    }
  }

  // List: elementy mogą być String lub Map
  if (v is List) {
    final out = <String>[];
    for (final item in v) {
      if (item is String && item.trim().isNotEmpty) {
        out.add(item.trim());
      } else if (item is Map) {
        for (final k in const ['main', 'url', 'src', 'href']) {
          final val = item[k];
          if (val is String && val.trim().isNotEmpty) {
            out.add(val.trim());
            break;
          }
        }
      }
    }
    final seen = <String>{};
    return out.where((e) => seen.add(e)).toList();
  }

  // Map: spróbuj wyciągnąć jeden URL
  if (v is Map) {
    for (final k in const ['main', 'url', 'src', 'href']) {
      final val = v[k];
      if (val is String && val.trim().isNotEmpty) {
        return [val.trim()];
      }
    }
  }

  return null;
}

List<FavoriteMeta>? _parseFavoriteMeta(dynamic v) {
  if (v == null) return null;
  dynamic raw = v;

  // bywa, że backend wyśle JSON jako string
  if (raw is String) {
    try { raw = jsonDecode(raw); } catch (_) { return null; }
  }
  if (raw is! List) return null;

  final out = <FavoriteMeta>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      out.add(FavoriteMeta.fromJson(item));
    }
  }
  return out;
}


/// =======================================

class MonitoringAdsModel {
  final int id;
  final String url;

  // Główne
  final String? estateType;
  final String? offerType;

  final num? price;
  final String? currency;
  final num? pricePerM2;
  final num? rent;

  final String? title;
  final String? description;
  final String? address;

  final num? squareFootage;
  final int? rooms;
  final int? bathrooms;

  final int? floor;
  final int? floorsNum;

  final String? estateCondition;
  final String? heatingType;
  final num? landArea;
  final String? buildingType;
  final String? energyCertificate;
  final String? marketType;
  final String? buildYear;

  // Media opisowe
  final String? media;

  // Booleany
  final bool? elevator;
  final bool? electricity;
  final bool? water;
  final bool? gas;
  final bool? phone;
  final bool? internet;
  final bool? sewerage;
  final bool? equipment;
  final bool? garden;
  final bool? garage;
  final bool? basement;
  final bool? attic;
  final bool? terraces;
  final bool? sepreteKitchen;
  final bool? furnished;

  // Tekstowe flagi
  final String? balcony;
  final String? parkingSpace;

  // Dane oferty
  final String? siteId;
  final String? landAndMortgageRegister;
  final String? createdAt;
  final String? ownershipForm;
  final String? availableFrom;

  // Informacje dodatkowe
  final String? windows;
  final String? atticType;
  final String? buildingMaterial;
  final String? security;
  final String? fencing;
  final String? accessRoad;
  final String? location;
  final String? plotType;
  final String? dimensions;
  final String? premisesLocation;
  final String? purpose;
  final String? locationInfo;
  final String? roof;
  final String? recreationalHouse;
  final String? roofCovering;
  final String? construction;
  final double? height;
  final int? officeRooms;
  final String? socialFacilities;
  final String? parking;
  final String? ramp;
  final String? floorMaterial;
  final String? lighting;

  // Adres szczegółowy
  final String? country;
  final String? state;
  final String? province;
  final String? commune;
  final String? city;
  final String? district;
  final String? street;
  final String? housingEstate;
  final String? zipcode;
  final String? neighborhood;
  final double? lon;
  final double? lat;

  // Obrazy
  final List<String> images;

  // Ogłoszeniodawca
  final String? advertiserName;
  final String? advertiserType;
  final String? remoteService;
  final String? advertiserPhone;

  // Liczniki / status
  final int? viewCount;
  final bool? isActive;
  final String? inactiveDate;
  final bool? isSendToMainServer;
  final bool? isArchived;
  final String? listingDate;
  final bool? isMerged;
  final String? downloadManagment;
  final int? workerNumber;
  final bool? isProFlag;
  final List<FavoriteMeta> favoriteMeta;

  // ---------- WYGODNE GETTERY DLA UI (bez NPE / bez isNegative na null) ----------

  bool get isPro => isProFlag ?? false;

  String get mainImageUrl => images.isNotEmpty ? images.first : 'default_image_url';


  String get safeTitle =>
      (title == null || title!.trim().isEmpty) ? 'Brak tytułu' : title!;

  String _formatNum(num? v, {int fractionDigits = 0}) {
    if (v == null) return '-';
    final n = (fractionDigits <= 0) ? v.round() : v;
    return NumberFormat.decimalPattern('fr').format(n);
  }

  String _formatMoney(num? v, String? curr, {int fractionDigits = 0}) {
    final left = _formatNum(v, fractionDigits: fractionDigits);
    final c = (curr == null || curr.trim().isEmpty) ? '' : ' $curr';
    return '$left$c';
  }

  String _formatDouble(num? v, {int fractionDigits = 2}) {
    if (v == null) return '-';
    return v.toStringAsFixed(fractionDigits);
  }

  String get priceText => _formatMoney(price, currency, fractionDigits: 0);
  String get pricePerM2Text => _formatMoney(pricePerM2, currency, fractionDigits: 0);
  String get rentText => _formatMoney(rent, currency, fractionDigits: 0);

  String get squareFootageText => _formatNum(squareFootage, fractionDigits: 2);
  String get roomsText => rooms?.toString() ?? '-';
  String get bathroomsText => bathrooms?.toString() ?? '-';
  String get floorText => floor?.toString() ?? '-';
  String get floorsNumText => floorsNum?.toString() ?? '-';
  String get heightText => _formatDouble(height, fractionDigits: 2);
  String get landAreaText => _formatNum(landArea, fractionDigits: 2);

  String get viewCountText => viewCount?.toString() ?? '-';

  String get lonText => (lon == null || lon == 0) ? '-' : _formatDouble(lon, fractionDigits: 6);
  String get latText => (lat == null || lat == 0) ? '-' : _formatDouble(lat, fractionDigits: 6);

  bool get canShowNearby => (lon ?? 0) != 0 && (lat ?? 0) != 0;

  // ------------------------------------------------------------------------------

  MonitoringAdsModel({
    required this.id,
    required this.url,
    this.estateType,
    this.offerType,
    this.price,
    this.currency,
    this.pricePerM2,
    this.rent,
    this.title,
    this.description,
    this.address,
    this.squareFootage,
    this.rooms,
    this.bathrooms,
    this.floor,
    this.floorsNum,
    this.estateCondition,
    this.heatingType,
    this.landArea,
    this.buildingType,
    this.energyCertificate,
    this.marketType,
    this.buildYear,
    this.media,
    this.elevator,
    this.electricity,
    this.water,
    this.gas,
    this.phone,
    this.internet,
    this.sewerage,
    this.equipment,
    this.garden,
    this.garage,
    this.basement,
    this.attic,
    this.terraces,
    this.sepreteKitchen,
    this.furnished,
    this.balcony,
    this.parkingSpace,
    this.siteId,
    this.landAndMortgageRegister,
    this.createdAt,
    this.ownershipForm,
    this.availableFrom,
    this.windows,
    this.atticType,
    this.buildingMaterial,
    this.security,
    this.fencing,
    this.accessRoad,
    this.location,
    this.plotType,
    this.dimensions,
    this.premisesLocation,
    this.purpose,
    this.locationInfo,
    this.roof,
    this.recreationalHouse,
    this.roofCovering,
    this.construction,
    this.height,
    this.officeRooms,
    this.socialFacilities,
    this.parking,
    this.ramp,
    this.floorMaterial,
    this.lighting,
    this.country,
    this.state,
    this.province,
    this.commune,
    this.city,
    this.district,
    this.street,
    this.housingEstate,
    this.zipcode,
    this.neighborhood,
    this.lon,
    this.lat,
    this.images = const [],
    this.advertiserName,
    this.advertiserType,
    this.remoteService,
    this.advertiserPhone,
    this.viewCount,
    this.isActive,
    this.inactiveDate,
    this.isSendToMainServer,
    this.isArchived,
    this.listingDate,
    this.isMerged,
    this.downloadManagment,
    this.workerNumber,
    this.isProFlag,
    this.favoriteMeta = const [],

  });

  factory MonitoringAdsModel.fromJson(Map<String, dynamic> json) {
    return MonitoringAdsModel(
      id: _asInt(json['id']) ?? 0,
      url: _asString(json['url']) ?? '',

      estateType: _asString(json['estate_type']),
      offerType: _asString(json['offer_type']),

      price: _asNum(json['price']),
      currency: _asString(json['currency']),
      pricePerM2: _asNum(json['price_per_m2']),
      rent: _asNum(json['rent']),

      title: _asString(json['title']),
      description: _asString(json['description']),
      address: _asString(json['address']),

      squareFootage: _asNum(json['square_footage']),
      rooms: _asInt(json['rooms']),
      bathrooms: _asInt(json['bathrooms']),
      floor: _asInt(json['floor']),
      floorsNum: _asInt(json['floors_num']),

      estateCondition: _asString(json['estate_condition']),
      heatingType: _asString(json['heating_type']),
      landArea: _asNum(json['land_area']),
      buildingType: _asString(json['building_type']),
      energyCertificate: _asString(json['energy_certificate']),
      marketType: _asString(json['market_type']),
      buildYear: _asString(json['build_year']),

      media: _asString(json['media']),

      elevator: _parseBool(json['elevator']),
      electricity: _parseBool(json['electricity']),
      water: _parseBool(json['water']),
      gas: _parseBool(json['gas']),
      phone: _parseBool(json['phone']),
      internet: _parseBool(json['internet']),
      sewerage: _parseBool(json['sewerage']),
      equipment: _parseBool(json['equipment']),
      garden: _parseBool(json['garden']),
      garage: _parseBool(json['garage']),
      basement: _parseBool(json['basement']),
      attic: _parseBool(json['attic']),
      terraces: _parseBool(json['terraces']),
      sepreteKitchen: _parseBool(json['seprete_kitchen']),
      furnished: _parseBool(json['furnished']),

      balcony: _asString(json['balcony']),
      parkingSpace: _asString(json['parking_space']),

      siteId: _asString(json['site_id']),
      landAndMortgageRegister: _asString(json['land_and_mortgage_register']),
      createdAt: _asString(json['created_at']),
      ownershipForm: _asString(json['ownership_form']),
      availableFrom: _asString(json['available_from']),

      windows: _asString(json['windows']),
      atticType: _asString(json['attic_type']),
      buildingMaterial: _asString(json['building_material']),
      security: _asString(json['security']),
      fencing: _asString(json['fencing']),
      accessRoad: _asString(json['access_road']),
      location: _asString(json['location']),
      plotType: _asString(json['plot_type']),
      dimensions: _asString(json['dimensions']),
      premisesLocation: _asString(json['premises_location']),
      purpose: _asString(json['purpose']),
      locationInfo: _asString(json['location_info']),
      roof: _asString(json['roof']),
      recreationalHouse: _asString(json['recreational_house']),
      roofCovering: _asString(json['roof_covering']),
      construction: _asString(json['construction']),

      height: _asNum(json['height'])?.toDouble(),
      officeRooms: _asInt(json['office_rooms']),
      socialFacilities: _asString(json['social_facilities']),
      parking: _asString(json['parking']),
      ramp: _asString(json['ramp']),
      floorMaterial: _asString(json['floor_material']),
      lighting: _asString(json['lighting']),

      country: _asString(json['country']),
      state: _asString(json['state']),
      province: _asString(json['province']),
      commune: _asString(json['commune']),
      city: _asString(json['city']),
      district: _asString(json['district']),
      street: _asString(json['street']),
      housingEstate: _asString(json['housing_estate']),
      zipcode: _asString(json['zipcode']),
      neighborhood: _asString(json['neighborhood']),

      // przyjmujemy także stringi "53.4289"
      lon: _asNum(json['lon'])?.toDouble(),
      lat: _asNum(json['lat'])?.toDouble(),

      images: _parseImages(json['images']) ?? const [],

      advertiserName: _asString(json['advertiser_name']),
      advertiserType: _asString(json['advertiser_type']),
      remoteService: _asString(json['remote_service']),
      advertiserPhone: _asString(json['advertiser_phone']),

      viewCount: _asInt(json['view_count']),
      isActive: _parseBool(json['is_active']),
      inactiveDate: _asString(json['inactive_date']),
      isSendToMainServer: _parseBool(json['isSendToMainServer']),
      isArchived: _parseBool(json['isArchived']),
      listingDate: _asString(json['listing_date']),
      isMerged: _parseBool(json['isMerged']),
      downloadManagment: _asString(json['DownloadManagment']),
      workerNumber: _asInt(json['worker_number']),
      isProFlag: _parseBool(json['isProFlag']),
      favoriteMeta: _parseFavoriteMeta(json['favorite_meta']) ?? const [],

    );
  }
}
