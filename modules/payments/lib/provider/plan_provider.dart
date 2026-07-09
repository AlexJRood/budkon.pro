// payments/provider/plan_provider.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:payments/models/stripe_models.dart';
import 'package:core/platform/api_services.dart';

/// month | year
final billingIntervalProvider = StateProvider<String>((_) => 'month');

/// =====================================================
/// ============  RESPONSE MODELS (CATEGORIES) =========
/// =====================================================

class ApiCategoryOption {
  final int id;
  final String key;        // e.g. "agent"
  final String label;      // e.g. "Agent"
  final String description;
  final bool isActive;
  final int sortIndex;     // 👈 NOWE

  ApiCategoryOption({
    required this.id,
    required this.key,
    required this.label,
    required this.description,
    required this.isActive,
    required this.sortIndex,
  });

  factory ApiCategoryOption.fromJson(Map<String, dynamic> json) {
    return ApiCategoryOption(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      sortIndex: json['index'] ?? 0,
    );
  }
}


/// Model kategorii używany tylko w UI (taby)
class CategoryTab {
  final String key;   // raw key for API ("agent", "Landlord")
  final String label; // label na UI
  const CategoryTab(this.key, this.label);
}

/// =====================================================
/// ============  PRODUCTS API PROVIDER  ===============
/// =====================================================

/// Zwraca po prostu List<StripeProduct>, bez dodatkowych wrapperów.
final subscriptionProductsProvider =
    FutureProvider<List<StripeProduct>>((ref) async {
  final resp = await ApiServices.get(
    ref: ref,
    "https://www.superbee.cloud/stripe/products/?placement=subscription&ordering=name",
  );

  dynamic data;
  try {
    data = (resp as dynamic).data ?? resp;
  } catch (_) {
    data = resp;
  }

  // Obsługa Uint8List / List<int> -> JSON
  if (data is Uint8List || data is List<int>) {
    final bytes = data is Uint8List ? data : Uint8List.fromList(data as List<int>);
    final jsonString = utf8.decode(bytes);
    debugPrint('[DEBUG] Products decoded jsonString=$jsonString');
    try {
      data = jsonDecode(jsonString);
    } catch (e, st) {
      debugPrint('[DEBUG] Products jsonDecode(bytes) error: $e\n$st');
      return [];
    }
  } else if (data is String) {
    // fallback gdyby kiedyś było Stringiem
    try {
      data = jsonDecode(data);
    } catch (e, st) {
      debugPrint('[DEBUG] Products jsonDecode(string) error: $e\n$st');
      return [];
    }
  }

  debugPrint('[DEBUG] Products data.runtimeType=${data.runtimeType}');
  debugPrint('[DEBUG] Products data=$data');

  // oczekujemy:
  // {
  //   "count": 3,
  //   "next": null,
  //   "previous": null,
  //   "results": [ {...}, {...}, {...} ]
  // }
  if (data is! Map<String, dynamic>) {
    debugPrint('[DEBUG] Products: data is not a Map -> ${data.runtimeType}');
    return [];
  }

  final rawList = data['results'];
  if (rawList is! List) {
    debugPrint('[DEBUG] Products: "results" is not a List -> $rawList');
    return [];
  }

  final products = rawList
      .whereType<Map<String, dynamic>>()
      .map(StripeProduct.fromJson)
      .toList();

  debugPrint('[DEBUG] subscriptionProductsProvider products.length=${products.length}');
  debugPrint('[DEBUG] subscriptionProductsProvider cats=${products.map((p) => p.category).toList()}');

  return products;
});

/// =====================================================
/// ============  CATEGORIES API PROVIDERS =============
/// =====================================================

/// Surowe kategorie z osobnego API
final subscriptionCategoriesProvider =
    FutureProvider<List<ApiCategoryOption>>((ref) async {
  final resp = await ApiServices.get(
    ref: ref,
    "https://www.superbee.cloud/stripe/products/options/",
  );

  dynamic payload;
  try {
    payload = (resp as dynamic).data ?? resp;
  } catch (_) {
    payload = resp;
  }

  // Obsługa Uint8List / List<int> -> JSON
  if (payload is Uint8List || payload is List<int>) {
    final bytes = payload is Uint8List ? payload : Uint8List.fromList(payload as List<int>);
    final jsonString = utf8.decode(bytes);
    debugPrint('[DEBUG] Categories decoded jsonString=$jsonString');
    try {
      payload = jsonDecode(jsonString);
    } catch (e, st) {
      debugPrint('[DEBUG] Categories jsonDecode(bytes) error: $e\n$st');
      return [];
    }
  } else if (payload is String) {
    try {
      payload = jsonDecode(payload);
    } catch (e, st) {
      debugPrint('[DEBUG] Categories jsonDecode(string) error: $e\n$st');
      return [];
    }
  }

  debugPrint('[DEBUG] Categories payload.runtimeType=${payload.runtimeType}');
  debugPrint('[DEBUG] Categories payload=$payload');

  if (payload is! Map<String, dynamic>) {
    debugPrint('[DEBUG] Categories: payload is not Map -> ${payload.runtimeType}');
    return [];
  }

  // oczekujemy:
  // {
  //   "categories": [ {...}, {...} ],
  //   "placements": [...],
  //   "tags": [],
  //   "feature_tags": []
  // }
  final rawList = payload['categories'];
  if (rawList is! List) {
    debugPrint('[DEBUG] Categories: "categories" is not a List -> $rawList');
    return [];
  }

  final cats = rawList
      .whereType<Map<String, dynamic>>()
      .map(ApiCategoryOption.fromJson)
      .toList();

  debugPrint('[DEBUG] subscriptionCategoriesProvider length=${cats.length}');
  return cats;
});



final categoryTabsProvider = FutureProvider<List<CategoryTab>>((ref) async {
  final cats = await ref.watch(subscriptionCategoriesProvider.future);
  final products = await ref.watch(subscriptionProductsProvider.future);

  // Zbiór kategorii, które REALNIE występują w produktach
  final productCats = <String>{};
  for (final p in products) {
    final raw = (p.category ?? '').toString();
    if (raw.isNotEmpty) {
      productCats.add(raw.toLowerCase());
    }
  }

  // Filtrowanie: tylko aktywne kategorie, które mają produkty
  final activeWithProducts = cats.where((c) {
    if (!c.isActive) return false;
    final keyNorm = c.key.toLowerCase();
    return productCats.contains(keyNorm);
  }).toList();

  // 👇 Uporządkuj po sortIndex, potem po label – na wszelki wypadek
  int _cmp(ApiCategoryOption a, ApiCategoryOption b) {
    final byIndex = a.sortIndex.compareTo(b.sortIndex);
    if (byIndex != 0) return byIndex;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  }

  if (activeWithProducts.isNotEmpty) {
    activeWithProducts.sort(_cmp);
    final tabs = activeWithProducts
        .map((c) => CategoryTab(c.key, c.label.tr))
        .toList();
    debugPrint('[DEBUG] categoryTabsProvider using activeWithProducts=${tabs.length}');
    return tabs;
  }

  final fallback = cats.where((c) => c.isActive).toList();
  if (fallback.isNotEmpty) {
    fallback.sort(_cmp);
    final tabs = fallback
        .map((c) => CategoryTab(c.key, c.label.tr))
        .toList();
    debugPrint('[DEBUG] categoryTabsProvider using fallback=${tabs.length}');
    return tabs;
  }

  debugPrint('[DEBUG] categoryTabsProvider -> []');
  return const [];
});

