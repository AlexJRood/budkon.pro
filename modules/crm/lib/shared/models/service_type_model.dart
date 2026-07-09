import 'package:flutter/foundation.dart';

@immutable
class ServiceTypeModel {
  final int id;
  final String serviceType; // API: "service_type"
  final String label;       // API: "label"
  final int? index;         // API: "index"
  final int? user;          // API: "user"

  const ServiceTypeModel({
    required this.id,
    required this.serviceType,
    required this.label,
    this.index,
    this.user,
  });

  /// Prefer label; fallback to `serviceType` if label is empty
  String get displayLabel => (label.isNotEmpty ? label : serviceType);
  String get idAsString => id.toString();

  ServiceTypeModel copyWith({
    int? id,
    String? serviceType,
    String? label,
    int? index,
    int? user,
  }) {
    return ServiceTypeModel(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      label: label ?? this.label,
      index: index ?? this.index,
      user: user ?? this.user,
    );
  }

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    String _asString(dynamic v) => v?.toString() ?? '';
    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    final id = _asInt(json['id']) ?? 0;
    final serviceType = _asString(json['service_type']);
    final label = _asString(json['label']);
    final index = _asInt(json['index']);
    final user = _asInt(json['user']);

    return ServiceTypeModel(
      id: id,
      serviceType: serviceType,
      label: label,
      index: index,
      user: user,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_type': serviceType,
        'label': label,
        'index': index,
        'user': user,
      };

  @override
  String toString() =>
      'ServiceTypeModel(id: $id, serviceType: $serviceType, label: $label, index: $index, user: $user)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceTypeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceType == other.serviceType &&
          label == other.label &&
          index == other.index &&
          user == other.user;

  @override
  int get hashCode =>
      id.hashCode ^ serviceType.hashCode ^ label.hashCode ^ index.hashCode ^ user.hashCode;
}
