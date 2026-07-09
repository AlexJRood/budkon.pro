import 'package:core/platform/url.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
// Model danych użytkownika (sprzedającego)
class AdvertisementListResponse {
  final int count;
  final int page;
  final int pageSize;
  final String? next;
  final String? previous;
  final List<AdsListViewModel> results;

  const AdvertisementListResponse({
    required this.count,
    required this.page,
    required this.pageSize,
    this.next,
    this.previous,
    required this.results,
  });

  factory AdvertisementListResponse.fromJson(Map<String, dynamic> json) {
    log("ad dat ${json.toString()}");
    final results = (json['results'] as List<dynamic>? ?? []).map((item) {
      // Map advertisement_images to images for AdsListViewModel compatibility
      final Map<String, dynamic> mappedItem = Map<String, dynamic>.from(item);
      if (mappedItem.containsKey('advertisement_images')) {
        mappedItem['images'] = mappedItem['advertisement_images'];
      }
      log("Mapped advertisement item: ${mappedItem['id']} - Images: ${mappedItem['images']}");
      return AdsListViewModel.fromJson(mappedItem);
    }).toList();
    
    return AdvertisementListResponse(
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      next: json['next'],
      previous: json['previous'],
      results: results,
    );
  }
}

class Seller {
  final String userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? avatarUrl;
  final String? backgroundImage;
  final AdvertisementListResponse? advertisements;
  final dynamic company;

  const Seller({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.avatarUrl,
    this.backgroundImage,
    this.advertisements,
    this.company,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    String? avatarPath = json['avatar'] ?? json['avatar_url'];
    String? fullAvatarUrl;

    if (avatarPath != null) {
      if (avatarPath.startsWith('/media/avatars') || avatarPath.startsWith('http')) {
        fullAvatarUrl = avatarPath;
      } else {
        fullAvatarUrl = '${URLs.baseUrl}/media/$avatarPath';
      }
    }

    String? backgroundImage = json['backround_image'];
    if (backgroundImage != null && !backgroundImage.startsWith('http')) {
      backgroundImage = '${URLs.baseUrl}/media/$backgroundImage';
    }

    // Convert advertisements if they exist
    AdvertisementListResponse? advertisements;
    if (json['advertisements'] != null) {
      try {
        advertisements = AdvertisementListResponse.fromJson(
          Map<String, dynamic>.from(json['advertisements'])
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing advertisements: $e');
        }
      }
    }

    return Seller(
      userId: json['id'].toString(),
      username: json['username'] ?? 'Nieznany',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? 'Imię',
      lastName: json['last_name'] ?? 'Nazwisko',
      phoneNumber: json['phone_number'] ?? '',
      avatarUrl: fullAvatarUrl,
      backgroundImage: backgroundImage,
      advertisements: advertisements,
      company: json['company'],
    );
  }

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  bool get hasAds => advertisements?.results.isNotEmpty ?? false;
  
  int get adsCount => advertisements?.count ?? 0;
}
