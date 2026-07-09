import 'dart:convert';

class YourAdsListViewModel {
  final int id;
  final int sellerId;
  final String title;
  final double price;
  final String currency;
  final String description;
  final List<String> images;
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

  const YourAdsListViewModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.price,
    required this.currency,
    required this.description,
    required this.images,
    required this.floor,
    required this.totalFloors,
    required this.street,
    required this.city,
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
  });

  factory YourAdsListViewModel.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];

    if (json['advertisement_images'] != null) {
      // Sprawdź, czy json['images'] jest listą czy zakodowanym JSON-em
      if (json['advertisement_images'] is List) {
        // Jeśli już jest listą, rzutuj bezpośrednio
        imagesList = (json['advertisement_images'] as List).map((image) {
          return  image.toString();
        }).toList();
      } else if (json['advertisement_images'] is String) {
        // Jeśli to string (zakodowany JSON), zdekoduj
        imagesList = List<String>.from(
          jsonDecode(json['advertisement_images']).map((image) => image),
        );
      }
    }

    return YourAdsListViewModel(
      sellerId: json['user'] ?? 0,
      id: json['id'],
      title: json['title'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      currency: json['currency'] ?? '',
      description: json['description'] ?? '',
      images: imagesList,
      floor: json['floor'] ?? 0,
      totalFloors: json['total_floors'] ?? 0,
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipcode: json['zipcode'] ?? '',
      rooms: json['rooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      squareFootage: double.tryParse(json['square_footage']?.toString() ?? '0') ?? 0.0,
      lotSize: double.tryParse(json['lot_size']?.toString() ?? '0') ?? 0.0,
      propertyForm: json['property_form'] ?? '',
      marketType: json['market_type'] ?? '',
      offerType: json['offer_type'] ?? '',
      country: json['country'] ?? '',
      phoneNumber: json['phone_number'] ?? ' brak numeru',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
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
    );
  }
}
