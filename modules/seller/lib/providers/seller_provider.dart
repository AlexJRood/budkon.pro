import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seller/models/seller_model.dart';
import 'package:core/platform/url.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SellerApiService {
  Future<Seller?> fetchSellerById(int sellerId, {int page = 1, int pageSize = 10}) async {
    try {
      final response = await ApiServices.get(
        ref: null, // You'll need to pass ref from the provider
        '${URLs.singleSeller('$sellerId')}?page=$page&page_size=$pageSize',
      );
      
      if (response != null && response.statusCode == 200) {        
        final decodedBody = utf8.decode(response.data);
        final sellerJson = json.decode(decodedBody) as Map<String, dynamic>;

        //log(decodedBody);
        return Seller.fromJson(sellerJson);        
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching seller data: $e');
      }
    }
    return null;
  }

  Future<AdvertisementListResponse?> fetchSellerAdvertisements(
    int sellerId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await ApiServices.get(
        ref: null, // You'll need to pass ref from the provider
        '${URLs.singleSeller('$sellerId')}?page=$page&page_size=$pageSize',
      );

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final jsonData = json.decode(decodedBody) as Map<String, dynamic>;
        
        if (jsonData.containsKey('advertisements')) {
          return AdvertisementListResponse.fromJson(jsonData['advertisements']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching seller advertisements: $e');
      }
    }
    return null;
  }
}

// Provider for seller data with pagination support
final sellerProvider = StateNotifierProvider.autoDispose.family<SellerNotifier, AsyncValue<Seller?>, int>(
  (ref, sellerId) => SellerNotifier(sellerId: sellerId),
);

class SellerNotifier extends StateNotifier<AsyncValue<Seller?>> {
  final SellerApiService _apiService = SellerApiService();
  final int sellerId;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;

  SellerNotifier({required this.sellerId}) : super(const AsyncValue.loading()) {
    loadSeller();
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<void> loadSeller() async {
    if (_isLoading) return;
    
    _isLoading = true;
    state = const AsyncValue.loading();
    
    try {
      final seller = await _apiService.fetchSellerById(sellerId);
      state = AsyncValue.data(seller);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMoreAdvertisements() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    _currentPage++;
    
    try {
      final currentSeller = state.value;
      if (currentSeller == null) return;
      
      final response = await _apiService.fetchSellerAdvertisements(
        sellerId,
        page: _currentPage,
      );
      
      if (response == null || response.results.isEmpty) {
        _hasMore = false;
        return;
      }
      
      // Update the seller with the new advertisements
      final updatedSeller = currentSeller;
      final currentAds = updatedSeller.advertisements?.results ?? [];
      final updatedAds = [...currentAds, ...response.results];
      
      state = AsyncValue.data(updatedSeller.copyWith(
        advertisements: AdvertisementListResponse(
          count: response.count,
          page: response.page,
          pageSize: response.pageSize,
          next: response.next,
          previous: response.previous,
          results: updatedAds,
        ),
      ));
      
      _hasMore = response.next != null;
    } catch (error, stackTrace) {
      _currentPage--; // Revert page increment on error
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }
  
  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await loadSeller();
  }
}

// Extension to make it easier to copy the seller with updated advertisements
extension SellerCopyWith on Seller {
  Seller copyWith({
    String? userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarUrl,
    String? backgroundImage,
    AdvertisementListResponse? advertisements,
    dynamic company,
  }) {
    return Seller(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      advertisements: advertisements ?? this.advertisements,
      company: company ?? this.company,
    );
  }
}
