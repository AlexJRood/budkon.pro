
// association_member_model.dart

import 'package:crm_agent/models/clients_model.dart';
import 'package:core/user/user/user_model.dart';


/// Member status enum mirroring Django choices
enum MemberStatus {
  active,
  suspended,
  pending,
  former;

  // Parse from API string
  static MemberStatus fromString(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'active':
        return MemberStatus.active;
      case 'suspended':
        return MemberStatus.suspended;
      case 'former':
        return MemberStatus.former;
      case 'pending':
      default:
        return MemberStatus.pending;
    }
  }

  // Convert to API string
  String get apiValue {
    switch (this) {
      case MemberStatus.active:
        return 'active';
      case MemberStatus.suspended:
        return 'suspended';
      case MemberStatus.former:
        return 'former';
      case MemberStatus.pending:
        return 'pending';
    }
  }
}

/// AssociationMember model aligned with Django model.
/// Uses existing CompanyModel (association) and UserContactModel (user).
class AssociationMemberModel {
  /// UUID from backend
  final String id;

  /// Full association object (if embedded) or null when only id is provided
  final CompanyModel? association;

  /// Fallback association id when backend returns only an integer
  final int? associationId;

  /// Full user contact object (if embedded) or null when only id is provided
  final UserContactModel? user;

  /// Fallback user id when backend returns only an integer
  final int? userId;

  /// Optional label fields
  final String? companyName;
  final String? phone;
  final String? address;
  final String? location;

  /// Status mapped to enum
  final MemberStatus status;

  /// Joined at (tz-aware in API)
  final DateTime? joinedAt;

  /// Free text fields
  final String? history;
  final String? notes;

  const AssociationMemberModel({
    required this.id,
    this.association,
    this.associationId,
    this.user,
    this.userId,
    this.companyName,
    this.phone,
    this.address,
    this.location,
    this.status = MemberStatus.pending,
    this.joinedAt,
    this.history,
    this.notes,
  });

  /// Parse flexible int/obj for association
  static (CompanyModel?, int?) _parseAssociation(dynamic raw) {
    if (raw == null) return (null, null);
    if (raw is Map<String, dynamic>) {
      return (CompanyModel.fromJson(raw), _intOrNull(raw['id']));
    }
    return (null, _intOrNull(raw));
  }

  /// Parse flexible int/obj for user contact
  static (UserContactModel?, int?) _parseUser(dynamic raw) {
    if (raw == null) return (null, null);
    if (raw is Map<String, dynamic>) {
      return (UserContactModel.fromJson(raw), _intOrNull(raw['id']));
    }
    return (null, _intOrNull(raw));
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
    // Note: if you use UTC conversion, apply .toLocal() depending on UI needs
  }

  /// Factory that accepts either embedded objects or ids for association/user
  factory AssociationMemberModel.fromJson(Map<String, dynamic> json) {
    final (assocObj, assocId) = _parseAssociation(json['association']);
    final (userObj, uId) = _parseUser(json['user']);

    return AssociationMemberModel(
      id: '${json['id']}', // uuid to string
      association: assocObj,
      associationId: assocId ?? _intOrNull(json['association_id']),
      user: userObj,
      userId: uId ?? _intOrNull(json['user_id']),
      companyName: json['company_name'],
      phone: json['phone'],
      address: json['address'],
      location: json['location'],
      status: MemberStatus.fromString(json['status']),
      joinedAt: _parseDate(json['joined_at']),
      history: json['history'],
      notes: json['notes'],
    );
  }

  /// toJson:
  /// - For write operations we usually send IDs, not embedded objects.
  /// - If you need to send nested objects, extend this method or add a flag.
  Map<String, dynamic> toJson({
    bool sendEmbedded = false,
  }) {
    return {
      'id': id,
      // send ids by default
      'association': sendEmbedded ? association?.toJson() : (associationId ?? association?.id),
      'user': sendEmbedded ? user?.toJson() : (userId ?? user?.id),
      'company_name': companyName,
      'phone': phone,
      'address': address,
      'location': location,
      'status': status.apiValue,
      'joined_at': joinedAt?.toIso8601String(),
      'history': history,
      'notes': notes,
    };
  }

  AssociationMemberModel copyWith({
    String? id,
    CompanyModel? association,
    int? associationId,
    UserContactModel? user,
    int? userId,
    String? companyName,
    String? phone,
    String? address,
    String? location,
    MemberStatus? status,
    DateTime? joinedAt,
    String? history,
    String? notes,
  }) {
    return AssociationMemberModel(
      id: id ?? this.id,
      association: association ?? this.association,
      associationId: associationId ?? this.associationId,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      location: location ?? this.location,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      history: history ?? this.history,
      notes: notes ?? this.notes,
    );
  }
}
