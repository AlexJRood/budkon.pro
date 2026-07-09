
import 'dart:convert';

class Board {
  final int? id;
  final String? title;
  final String? description;
  final DateTime? dataDodania;
  final int? boardIndex;
  final bool? isLocked;
  final int? user;
  final dynamic client;
  final dynamic savedSearch;
  final List<BoardDetails>? advertisements;
  final List<String>? sharedToUsers;

  Board({
    this.id,
    this.title,
    this.description,
    this.dataDodania,
    this.boardIndex,
    this.isLocked,
    this.user,
    this.client,
    this.savedSearch,
    this.advertisements,
    this.sharedToUsers,
  });

  String get formattedDate {
    final diff = DateTime.now().difference(dataDodania ?? DateTime.now());
    if (diff.inDays >= 1) return '${diff.inDays} days';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: _safeParseInt(json['id']),
      title: json['title'],
      description: json['description'],
      dataDodania: json['data_dodania'] != null ? DateTime.parse(json['data_dodania']) : null,
      boardIndex:  json['board_index'] != null
          ? int.tryParse(json['board_index'].toString())
          : null,
      isLocked: json['is_locked'],
      user: _safeParseInt(json['user']),
      client: json['client'],
      savedSearch: json['saved_search'],
      advertisements: (json['advertisements'] is List)
          ? (json['advertisements'] as List)
          .whereType<Map<String, dynamic>>()
          .map((x) => BoardDetails.fromJson(x))
          .toList()
          : [],
      sharedToUsers: (json['shared_to_users'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'data_dodania': dataDodania?.toIso8601String(),
      'board_index': boardIndex,
      'is_locked': isLocked,
      'user': user,
      'client': client,
      'saved_search': savedSearch,
      'shared_to_users': sharedToUsers,
    };
  }
  Map<String, dynamic> toEditJson() {
    return {
      'title': title,
      'description': description?.isEmpty == true ? null : description,
      'board_index': boardIndex ?? 0,
    };
  }

  Board copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dataDodania,
    int? boardIndex,
    bool? isLocked,
    int? user,
    dynamic client,
    dynamic savedSearch,
    List<BoardDetails>? advertisements,
    List<String>? sharedToUsers,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dataDodania: dataDodania ?? this.dataDodania,
      boardIndex: boardIndex ?? this.boardIndex,
      isLocked: isLocked ?? this.isLocked,
      user: user ?? this.user,
      client: client ?? this.client,
      savedSearch: savedSearch ?? this.savedSearch,
      advertisements: advertisements ?? this.advertisements,
      sharedToUsers: sharedToUsers ?? this.sharedToUsers,
    );
  }
}

class BoardsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Board> results;

  BoardsResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory BoardsResponse.fromJson(Map<String, dynamic> json) {
    return BoardsResponse(
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count'].toString()) ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List)
          .map((e) => Board.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

class BoardDetails {
  final int id;
  final int sellerId;
  final String title;
  final double price;
  final String currency;
  final String description;
  final List<String> images;
  final List<String> advertisementImages;
  final int floor;
  final int totalFloors;
  final String street;
  final String city;
  final String state;
  final String zipcode;
  final int rooms;
  final int bathrooms;
  final double squareFootage;
  final double lotSize;
  final String propertyForm;
  final String marketType;
  final String offerType;
  final String country;
  final String phoneNumber;
  final double latitude;
  final double longitude;

  final String? heatingType;
  final String? buildingMaterial;
  final int? buildYear;
  final bool balcony;
  final bool terrace;
  final bool sauna;
  final bool jacuzzi;
  final bool basement;
  final bool elevator;
  final bool garden;
  final bool airConditioning;
  final bool garage;
  final bool parkingSpace;
  final bool isPro;

  final bool isPremium2;
  final bool isRenewable;
  final bool isActive;
  final DateTime activeValidityDate;
  final DateTime createdAt;
  final int? viewCount;
  final String? pricePerMeter;
  final String? estateType;
  final String? buildingType;
  final String? rent;
  final bool isPremium;
  final String slug;

  const BoardDetails({
    this.id = 0,
    this.sellerId = 0,
    this.title = '',
    this.price = 0.0,
    this.currency = '',
    this.description = '',
    this.images = const [],
    this.advertisementImages = const [],
    this.floor = 0,
    this.totalFloors = 0,
    this.street = '',
    this.city = '',
    this.state = '',
    this.zipcode = '',
    this.rooms = 0,
    this.bathrooms = 0,
    this.squareFootage = 0.0,
    this.lotSize = 0.0,
    this.propertyForm = '',
    this.marketType = '',
    this.offerType = '',
    this.country = '',
    this.phoneNumber = 'brak numeru',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.heatingType,
    this.buildingMaterial,
    this.buildYear,
    this.balcony = false,
    this.terrace = false,
    this.sauna = false,
    this.jacuzzi = false,
    this.basement = false,
    this.elevator = false,
    this.garden = false,
    this.airConditioning = false,
    this.garage = false,
    this.parkingSpace = false,
    this.isPro = false,
    this.isPremium2 = false,
    this.isRenewable = false,
    this.isActive = false,
    required this.activeValidityDate,
    required this.createdAt,
    this.viewCount,
    this.pricePerMeter,
    this.estateType,
    this.buildingType,
    this.rent,
    this.isPremium = false,
    this.slug = '',
  });

  factory BoardDetails.fromJson(Map<String, dynamic> json) {
    final adImages = <String>[];
    if (json['advertisement_images'] is List) {
      adImages.addAll(List<String>.from(json['advertisement_images'].map((e) => e.toString())));
    } else if (json['advertisement_images'] is String) {
      try {
        adImages.addAll(List<String>.from(jsonDecode(json['advertisement_images'])));
      } catch (_) {}
    }

    return BoardDetails(
      id: json['id'] ?? 0,
      sellerId: json['user'] ?? 0,
      title: json['title'] ?? '',
      price: parseStringToDouble(json['price']),
      currency: json['currency'] ?? '',
      description: json['description'] ?? '',
      images: adImages,
      advertisementImages: adImages,
      floor: json['floor'] ?? 0,
      totalFloors: json['total_floors'] ?? 0,
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipcode: json['zipcode'] ?? '',
      rooms: json['rooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      squareFootage: parseStringToDouble(json['square_footage']),
      lotSize: parseStringToDouble(json['lot_size']),
      propertyForm: json['property_form'] ?? '',
      marketType: json['market_type'] ?? '',
      offerType: json['offer_type'] ?? '',
      country: json['country'] ?? '',
      phoneNumber: json['phone_number'] ?? 'brak numeru',
      latitude: parseStringToDouble(json['latitude']),
      longitude: parseStringToDouble(json['longitude']),
      heatingType: json['heating_type'],
      buildingMaterial: json['building_material'],
      buildYear: json['build_year'],
      balcony: json['balcony'] ?? false,
      terrace: json['terrace'] ?? false,
      sauna: json['sauna'] ?? false,
      jacuzzi: json['jacuzzi'] ?? false,
      basement: json['basement'] ?? false,
      elevator: json['elevator'] ?? false,
      garden: json['garden'] ?? false,
      airConditioning: json['air_conditioning'] ?? false,
      garage: json['garage'] ?? false,
      parkingSpace: json['parking_space'] ?? false,
      isPro: json['is_premium'] ?? false,
      isPremium2: json['isPremium2'] ?? false,
      isRenewable: json['is_renewable'] ?? false,
      isActive: json['is_active'] ?? false,
      activeValidityDate: DateTime.tryParse(json['active_validity_date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      viewCount: json['view_count'],
      pricePerMeter: json['price_per_meter'],
      estateType: json['estate_type'],
      buildingType: json['building_type'],
      rent: json['rent'],
      isPremium: json['is_premium'] ?? false,
      slug: json['slug'] ?? '',
    );
  }
}

double parseStringToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
}