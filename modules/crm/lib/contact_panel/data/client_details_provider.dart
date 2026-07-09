import 'dart:convert';
import 'package:crm/crm_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

/// ✅ Model Class
class ClientDetailsModel {
  final double totalProfit;
  final int activeProjects;
  final int totalProjects;
  final double averageTransaction;

  ClientDetailsModel({
    required this.totalProfit,
    required this.activeProjects,
    required this.totalProjects,
    required this.averageTransaction,
  });

  factory ClientDetailsModel.fromJson(Map<String, dynamic> json) {
    return ClientDetailsModel(
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      activeProjects: (json['active_projects'] as num?)?.toInt() ?? 0,
      totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
      averageTransaction:
      (json['average_transaction'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// ✅ Notifier
class ClientDetailsNotifier extends StateNotifier<AsyncValue<ClientDetailsModel?>> {
  final Ref ref;
  final int clientId;

  ClientDetailsNotifier(this.ref, {required this.clientId})
      : super(const AsyncValue.loading()) {
    // ✅ Auto-fetch immediately when provider is created
    Future.microtask(() => fetchClientDetails());
  }

  Future<void> fetchClientDetails() async {
    try {
      state = const AsyncValue.loading();

      final response = await ApiServices.get(
        CrmUrls.clientDetails,
        ref: ref,
        hasToken: true,
        queryParameters: {'client_id': clientId.toString()},
      );

      if (response != null && response.statusCode == 200 && response.data != null) {
        dynamic decoded = response.data;

        // Handle bytes
        if (decoded is List<int>) {
          decoded = jsonDecode(utf8.decode(decoded));
        }

        // Handle string JSON
        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }

        if (decoded is Map<String, dynamic>) {
          final details = ClientDetailsModel.fromJson(decoded);
          state = AsyncValue.data(details);
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
      } else {
        throw Exception('Failed to fetch client details');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// ✅ Provider (FAMILY)
final clientDetailsProvider = StateNotifierProvider.family<
    ClientDetailsNotifier,
    AsyncValue<ClientDetailsModel?>,
    int>(
      (ref, clientId) => ClientDetailsNotifier(ref, clientId: clientId),
);
