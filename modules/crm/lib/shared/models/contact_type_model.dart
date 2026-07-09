import 'package:flutter/foundation.dart';

@immutable
class ContactTypeModel {
  final int id;
  final String contactType;                     // API: "contact_type"
  final String label;                           // API: "label"
  final int? index;                             // API: "index"
  final Map<String, dynamic>? contactIndex;     // API: "contact_index"
  final int? user;                              // API: "user"

  const ContactTypeModel({
    required this.id,
    required this.contactType,
    required this.label,
    this.index,
    this.contactIndex,
    this.user,
  });

  /// Prefer label; fallback to `contactType` if label is empty
  String get displayLabel => (label.isNotEmpty ? label : contactType);
  String get idAsString => id.toString();

  ContactTypeModel copyWith({
    int? id,
    String? contactType,
    String? label,
    int? index,
    Map<String, dynamic>? contactIndex,
    int? user,
  }) {
    return ContactTypeModel(
      id: id ?? this.id,
      contactType: contactType ?? this.contactType,
      label: label ?? this.label,
      index: index ?? this.index,
      contactIndex: contactIndex ?? this.contactIndex,
      user: user ?? this.user,
    );
  }

  factory ContactTypeModel.fromJson(Map<String, dynamic> json) {
    String _asString(dynamic v) => v?.toString() ?? '';
    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    final id = _asInt(json['id']) ?? 0;
    final contactType = _asString(json['contact_type']);
    final label = _asString(json['label']);
    final index = _asInt(json['index']);
    final user = _asInt(json['user']);
    final contactIndex =
        (json['contact_index'] is Map<String, dynamic>) ? json['contact_index'] as Map<String, dynamic> : null;

    return ContactTypeModel(
      id: id,
      contactType: contactType,
      label: label,
      index: index,
      contactIndex: contactIndex,
      user: user,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contact_type': contactType,
        'label': label,
        'index': index,
        'contact_index': contactIndex,
        'user': user,
      };

  @override
  String toString() =>
      'ContactTypeModel(id: $id, contactType: $contactType, label: $label, index: $index, contactIndex: $contactIndex, user: $user)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactTypeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contactType == other.contactType &&
          label == other.label &&
          index == other.index &&
          mapEquals(contactIndex, other.contactIndex) &&
          user == other.user;

  @override
  int get hashCode =>
      id.hashCode ^ contactType.hashCode ^ label.hashCode ^ index.hashCode ^ (contactIndex?.hashCode ?? 0) ^ user.hashCode;
}
