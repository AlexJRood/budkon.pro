class PublishedAdMatchingSettings {
  const PublishedAdMatchingSettings({
    required this.enabled,
    required this.showOverlay,
    required this.autoFindAfterPublish,
    required this.minConfidence,
    required this.maxCandidates,
    required this.onlyActiveNmAds,
  });

  final bool enabled;
  final bool showOverlay;
  final bool autoFindAfterPublish;
  final double minConfidence;
  final int maxCandidates;
  final bool onlyActiveNmAds;

  factory PublishedAdMatchingSettings.fromJson(Map<String, dynamic> json) {
    return PublishedAdMatchingSettings(
      enabled: json['enabled'] != false,
      showOverlay: json['show_overlay'] != false,
      autoFindAfterPublish: json['auto_find_after_publish'] != false,
      minConfidence: _readDouble(json['min_confidence'], fallback: 0.8),
      maxCandidates: _readInt(json['max_candidates'], fallback: 12),
      onlyActiveNmAds: json['only_active_nm_ads'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'show_overlay': showOverlay,
      'auto_find_after_publish': autoFindAfterPublish,
      'min_confidence': minConfidence,
      'max_candidates': maxCandidates,
      'only_active_nm_ads': onlyActiveNmAds,
    };
  }

  PublishedAdMatchingSettings copyWith({
    bool? enabled,
    bool? showOverlay,
    bool? autoFindAfterPublish,
    double? minConfidence,
    int? maxCandidates,
    bool? onlyActiveNmAds,
  }) {
    return PublishedAdMatchingSettings(
      enabled: enabled ?? this.enabled,
      showOverlay: showOverlay ?? this.showOverlay,
      autoFindAfterPublish:
          autoFindAfterPublish ?? this.autoFindAfterPublish,
      minConfidence: minConfidence ?? this.minConfidence,
      maxCandidates: maxCandidates ?? this.maxCandidates,
      onlyActiveNmAds: onlyActiveNmAds ?? this.onlyActiveNmAds,
    );
  }
}

class PublishedAdNetworkLink {
  const PublishedAdNetworkLink({
    required this.id,
    required this.url,
    required this.portalCode,
    required this.portalName,
    required this.confidence,
    required this.matchStatus,
    required this.matchReasons,
    required this.isActive,
    required this.lastCheckedAt,
    required this.rejectedReason,
    required this.createdAt,
    required this.updatedAt,
    required this.nmTitle,
    required this.nmPrice,
    required this.nmArea,
    required this.nmCity,
    required this.nmIsActive,
  });

  final int id;
  final String url;
  final String portalCode;
  final String portalName;
  final double confidence;
  final String matchStatus;
  final Map<String, dynamic> matchReasons;
  final bool? isActive;
  final DateTime? lastCheckedAt;
  final String rejectedReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String nmTitle;
  final dynamic nmPrice;
  final dynamic nmArea;
  final String nmCity;
  final bool? nmIsActive;

  bool get isSuggested => matchStatus == 'suggested';
  bool get isConfirmed => matchStatus == 'confirmed';
  bool get isManual => matchStatus == 'manual';
  bool get isRejected => matchStatus == 'rejected';

  String get displayPortal {
    if (portalName.trim().isNotEmpty) return portalName;
    if (portalCode.trim().isNotEmpty) return portalCode;
    return 'Network Monitoring';
  }

  String get displayTitle {
    if (nmTitle.trim().isNotEmpty) return nmTitle;
    return url;
  }

  int get confidencePercent => (confidence * 100).round().clamp(0, 100);

  factory PublishedAdNetworkLink.fromJson(Map<String, dynamic> json) {
    return PublishedAdNetworkLink(
      id: _readInt(json['id'], fallback: 0),
      url: _readString(json['url']),
      portalCode: _readString(json['portal_code']),
      portalName: _readString(json['portal_name']),
      confidence: _readDouble(json['confidence'], fallback: 0),
      matchStatus: _readString(json['match_status'], fallback: 'suggested'),
      matchReasons: _readMap(json['match_reasons']),
      isActive: _readNullableBool(json['is_active']),
      lastCheckedAt: _readDate(json['last_checked_at']),
      rejectedReason: _readString(json['rejected_reason']),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
      nmTitle: _readString(json['nm_title']),
      nmPrice: json['nm_price'],
      nmArea: json['nm_area'],
      nmCity: _readString(json['nm_city']),
      nmIsActive: _readNullableBool(json['nm_is_active']),
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _readInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _readDouble(dynamic value, {required double fallback}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool? _readNullableBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;

  final normalized = value.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }

  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }

  return null;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}