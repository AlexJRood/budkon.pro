import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:portal/models/seller_model.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';



class SellerApiService {
  Future<Seller?> fetchSellerById(int sellerId,dynamic ref) async {
    try {
      final response = await ApiServices.get(ref:ref,URLs.singleSeller('$sellerId'));
      if (response != null && response.statusCode == 200) {        
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as Map<String, dynamic>;
        return Seller.fromJson(listingsJson);        
      }
    } catch (e) {
      // ignore: avoid_print
      if (kDebugMode) print('Błąd podczas pobierania danych sprzedającego: $e');
    }
    return null;
  }
}

// Provider dla danych sprzedającego
final sellerProviderFamily =
    FutureProvider.autoDispose.family<Seller?, int>((ref, sellerId) async {
  final apiService = SellerApiService();
  return apiService.fetchSellerById(sellerId,ref);
});
