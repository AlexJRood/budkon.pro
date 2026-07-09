class FlipperDraftAdvertisement {
  final int? id;
  final String? title;
  final String? price;
  final String? pricePerMeter;
  final String? description;
  final String url;
  final String? estateType;
  final String? buildingType;
  final int? floor;
  final int? totalFloors;
  final int? rooms;
  final int? bathrooms;
  final String? squareFootage;
  final String? lotSize;
  final String? marketType;
  final String? offerType;
  final int? user;
  final String? zipcode;
  final String? phoneNumber;
  final String? currency;
  final String? windows;
  final String? atticType;
  final String? buildingMaterial;
  final String? security;
  final String? premisesLocation;
  final String? purpose;
  final String? roof;
  final String? recreationalHouse;
  final String? roofCovering;
  final String? lighting;
  final bool? isPremium2;
  final bool? isRenewable;
  final bool? isActive;
  final int? viewCount;
  final String? construction;
  final String? height;
  final String? officeRooms;
  final String? socialFacilities;
  final String? parking;
  final String? ramp;
  final String? floorMaterial;
  final String? fencing;
  final String? accessRoad;
  final String? plotType;
  final String? dimensions;
  final String? heatingType;
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
  final String? street;
  final String? district;
  final String? city;
  final String? state;
  final String? country;
  final String? latitude;
  final String? longitude;
  final bool? electricity;
  final bool? water;
  final bool? gas;
  final bool? phone;
  final bool? internet;
  final bool? sewerage;
  final bool? equipment;
  final Map<String, dynamic>? images;
  final String? propertyForm;
  final String? landAndMortgageRegister;
  final String? estateCondition;
  final String? remoteService;
  final String? rent;
  final String? siteId;

  FlipperDraftAdvertisement({
    this.id,
    this.title,
    this.price,
    this.pricePerMeter,
    this.description,
    required this.url,
    this.estateType,
    this.buildingType,
    this.floor,
    this.totalFloors,
    this.rooms,
    this.bathrooms,
    this.squareFootage,
    this.lotSize,
    this.marketType,
    this.offerType,
    this.user,
    this.zipcode,
    this.phoneNumber,
    this.currency,
    this.windows,
    this.atticType,
    this.buildingMaterial,
    this.security,
    this.premisesLocation,
    this.purpose,
    this.roof,
    this.recreationalHouse,
    this.roofCovering,
    this.lighting,
    this.isPremium2,
    this.isRenewable,
    this.isActive,
    this.viewCount,
    this.construction,
    this.height,
    this.officeRooms,
    this.socialFacilities,
    this.parking,
    this.ramp,
    this.floorMaterial,
    this.fencing,
    this.accessRoad,
    this.plotType,
    this.dimensions,
    this.heatingType,
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
    this.street,
    this.district,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.electricity,
    this.water,
    this.gas,
    this.phone,
    this.internet,
    this.sewerage,
    this.equipment,
    this.images,
    this.propertyForm,
    this.landAndMortgageRegister,
    this.estateCondition,
    this.remoteService,
    this.rent,
    this.siteId,
  });

  factory FlipperDraftAdvertisement.fromJson(Map<String, dynamic> json) {
    return FlipperDraftAdvertisement(
      id: json['id'],
      title: json['title'],
      price: json['price']?.toString(),
      pricePerMeter: json['price_per_meter']?.toString(),
      description: json['description'],
      url: json['url'],
      estateType: json['estate_type'],
      buildingType: json['building_type'],
      floor: json['floor'],
      totalFloors: json['total_floors'],
      rooms: json['rooms'],
      bathrooms: json['bathrooms'],
      squareFootage: json['square_footage']?.toString(),
      lotSize: json['lot_size']?.toString(),
      marketType: json['market_type'],
      offerType: json['offer_type'],
      user: json['user'],
      zipcode: json['zipcode'],
      phoneNumber: json['phone_number'],
      currency: json['currency'],
      windows: json['windows'],
      atticType: json['attic_type'],
      buildingMaterial: json['building_material'],
      security: json['security'],
      premisesLocation: json['premises_location'],
      purpose: json['purpose'],
      roof: json['roof'],
      recreationalHouse: json['recreational_house'],
      roofCovering: json['roof_covering'],
      lighting: json['lighting'],
      isPremium2: json['isPremium2'],
      isRenewable: json['is_renewable'],
      isActive: json['is_active'],
      viewCount: json['view_count'],
      construction: json['construction'],
      height: json['height'],
      officeRooms: json['office_rooms'],
      socialFacilities: json['social_facilities'],
      parking: json['parking'],
      ramp: json['ramp'],
      floorMaterial: json['floor_material'],
      fencing: json['fencing'],
      accessRoad: json['access_road'],
      plotType: json['plot_type'],
      dimensions: json['dimensions'],
      heatingType: json['heating_type'],
      buildYear: json['build_year'],
      balcony: json['balcony'],
      terrace: json['terrace'],
      sauna: json['sauna'],
      jacuzzi: json['jacuzzi'],
      basement: json['basement'],
      elevator: json['elevator'],
      garden: json['garden'],
      airConditioning: json['air_conditioning'],
      garage: json['garage'],
      parkingSpace: json['parking_space'],
      street: json['street'],
      district: json['district'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      electricity: json['electricity'],
      water: json['water'],
      gas: json['gas'],
      phone: json['phone'],
      internet: json['internet'],
      sewerage: json['sewerage'],
      equipment: json['equipment'],
      images: json['images'],
      propertyForm: json['property_form'],
      landAndMortgageRegister: json['land_and_mortgage_register'],
      estateCondition: json['estate_condition'],
      remoteService: json['remote_service'],
      rent: json['rent']?.toString(),
      siteId: json['site_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'price_per_meter': pricePerMeter,
    'description': description,
    'url': url,
    'estate_type': estateType,
    'building_type': buildingType,
    'floor': floor,
    'total_floors': totalFloors,
    'rooms': rooms,
    'bathrooms': bathrooms,
    'square_footage': squareFootage,
    'lot_size': lotSize,
    'market_type': marketType,
    'offer_type': offerType,
    'user': user,
    'zipcode': zipcode,
    'phone_number': phoneNumber,
    'currency': currency,
    'windows': windows,
    'attic_type': atticType,
    'building_material': buildingMaterial,
    'security': security,
    'premises_location': premisesLocation,
    'purpose': purpose,
    'roof': roof,
    'recreational_house': recreationalHouse,
    'roof_covering': roofCovering,
    'lighting': lighting,
    'isPremium2': isPremium2,
    'is_renewable': isRenewable,
    'is_active': isActive,
    'view_count': viewCount,
    'construction': construction,
    'height': height,
    'office_rooms': officeRooms,
    'social_facilities': socialFacilities,
    'parking': parking,
    'ramp': ramp,
    'floor_material': floorMaterial,
    'fencing': fencing,
    'access_road': accessRoad,
    'plot_type': plotType,
    'dimensions': dimensions,
    'heating_type': heatingType,
    'build_year': buildYear,
    'balcony': balcony,
    'terrace': terrace,
    'sauna': sauna,
    'jacuzzi': jacuzzi,
    'basement': basement,
    'elevator': elevator,
    'garden': garden,
    'air_conditioning': airConditioning,
    'garage': garage,
    'parking_space': parkingSpace,
    'street': street,
    'district': district,
    'city': city,
    'state': state,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
    'electricity': electricity,
    'water': water,
    'gas': gas,
    'phone': phone,
    'internet': internet,
    'sewerage': sewerage,
    'equipment': equipment,
    'images': images,
    'property_form': propertyForm,
    'land_and_mortgage_register': landAndMortgageRegister,
    'estate_condition': estateCondition,
    'remote_service': remoteService,
    'rent': rent,
    'site_id': siteId,
  };
}

class FlipperDraftAdvertisementResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FlipperDraftAdvertisement> results;

  FlipperDraftAdvertisementResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FlipperDraftAdvertisementResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return FlipperDraftAdvertisementResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List)
          .map((e) => FlipperDraftAdvertisement.fromJson(e))
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

  FlipperDraftAdvertisementResponse copyWith({
    int? count,
    String? next,
    String? previous,
    List<FlipperDraftAdvertisement>? results,
  }) {
    return FlipperDraftAdvertisementResponse(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }
}
