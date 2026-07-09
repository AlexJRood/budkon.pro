import 'dart:convert';
import 'package:crm/crm_urls.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class FilterTaskByClientModel {
  final int id;
  final double? progress;
  final int ordering;
  final String name;
  final String description;
  final bool isCompleted;
  final String priority;
  final Map<String, dynamic> metaFields;
  final DateTime timestamp;
  final int? transactionObjectId;
  final int project;
  final int assignedTo;
  final int? client;
  final int? transactionContentType;
  final List<dynamic> tags;

  FilterTaskByClientModel({
    required this.id,
    this.progress,
    required this.ordering,
    required this.name,
    required this.description,
    required this.isCompleted,
    required this.priority,
    required this.metaFields,
    required this.timestamp,
    this.transactionObjectId,
    required this.project,
    required this.assignedTo,
    this.client,
    this.transactionContentType,
    required this.tags,
  });

  factory FilterTaskByClientModel.fromJson(Map<String, dynamic> json) {
    return FilterTaskByClientModel(
      id: json['id'] ?? 0,
      progress: json['progress'] != null ? (json['progress'] as num).toDouble() : null,
      ordering: json['ordering'] ?? 0,
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No Description',
      isCompleted: json['is_completed'] ?? false,
      priority: json['priority'] ?? 'L',
      metaFields: json['meta_fields'] ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      transactionObjectId: json['transaction_object_id'],
      project: json['project'] ?? 0,
      assignedTo: json['assigned_to'] ?? 0,
      client: json['client'],
      transactionContentType: json['transaction_content_type'],
      tags: json['tags'] ?? [],
    );
  }

  static List<FilterTaskByClientModel> fromList(List<dynamic> list) =>
      list.map((j) => FilterTaskByClientModel.fromJson(j)).toList();
}

class FilterTaskByClientNotifier
    extends StateNotifier<List<FilterTaskByClientModel>> {
  final Ref ref;
  FilterTaskByClientNotifier(this.ref) : super([]);

  Future<void> filterTaskByClient(String clientId) async {
    try {
      final response = await ApiServices.get(
        CrmUrls.filterTaskByClient(clientId),
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        if (response.data == null || response.data.isEmpty) {
          state = [];
          return;
        }
        try {
          final List<dynamic> decoded = jsonDecode(utf8.decode(response.data));
          state = FilterTaskByClientModel.fromList(decoded);
        } catch (_) {
          state = [];
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FilterTaskByClient error: $e');
    }
  }
}

final filterTaskByClientProvider =
    StateNotifierProvider<FilterTaskByClientNotifier, List<FilterTaskByClientModel>>(
  (ref) => FilterTaskByClientNotifier(ref),
);
