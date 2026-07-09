import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';


enum OfflineCityPackStatus {
  idle,
  estimating,
  readyToDownload,
  downloading,
  downloaded,
  failed,
}

@immutable
class OfflineCityPack {
  final String id;
  final String sourceProviderId;
  final String title;
  final LatLngBounds bounds;
  final int minZoom;
  final int maxZoom;

  final OfflineCityPackStatus status;
  final double progress01;
  final int? estimatedTiles;
  final int? downloadedTiles;
  final String? errorMessage;
  final DateTime? lastDownloadedAt;
  final bool enabledForBrowsing;

  const OfflineCityPack({
    required this.id,
    required this.sourceProviderId,
    required this.title,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    this.status = OfflineCityPackStatus.idle,
    this.progress01 = 0,
    this.estimatedTiles,
    this.downloadedTiles,
    this.errorMessage,
    this.lastDownloadedAt,
    this.enabledForBrowsing = true,
  });

  OfflineCityPack copyWith({
    String? id,
    String? sourceProviderId,
    String? title,
    LatLngBounds? bounds,
    int? minZoom,
    int? maxZoom,
    OfflineCityPackStatus? status,
    double? progress01,
    int? estimatedTiles,
    int? downloadedTiles,
    String? errorMessage,
    DateTime? lastDownloadedAt,
    bool? enabledForBrowsing,
    bool clearErrorMessage = false,
  }) {
    return OfflineCityPack(
      id: id ?? this.id,
      sourceProviderId: sourceProviderId ?? this.sourceProviderId,
      title: title ?? this.title,
      bounds: bounds ?? this.bounds,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      status: status ?? this.status,
      progress01: progress01 ?? this.progress01,
      estimatedTiles: estimatedTiles ?? this.estimatedTiles,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      lastDownloadedAt: lastDownloadedAt ?? this.lastDownloadedAt,
      enabledForBrowsing: enabledForBrowsing ?? this.enabledForBrowsing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceProviderId': sourceProviderId,
      'title': title,
      'bounds': {
        'west': bounds.west,
        'south': bounds.south,
        'east': bounds.east,
        'north': bounds.north,
      },
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'status': status.name,
      'progress01': progress01,
      'estimatedTiles': estimatedTiles,
      'downloadedTiles': downloadedTiles,
      'errorMessage': errorMessage,
      'lastDownloadedAt': lastDownloadedAt?.millisecondsSinceEpoch,
      'enabledForBrowsing': enabledForBrowsing,
    };
  }

  factory OfflineCityPack.fromJson(Map<String, dynamic> json) {
    final boundsMap = Map<String, dynamic>.from(json['bounds'] as Map);
    return OfflineCityPack(
      id: json['id'] as String,
      sourceProviderId: json['sourceProviderId'] as String,
      title: json['title'] as String,
      bounds: LatLngBounds(
        LatLng(
          (boundsMap['south'] as num).toDouble(),
          (boundsMap['west'] as num).toDouble(),
        ),
        LatLng(
          (boundsMap['north'] as num).toDouble(),
          (boundsMap['east'] as num).toDouble(),
        ),
      ),
      minZoom: (json['minZoom'] as num).toInt(),
      maxZoom: (json['maxZoom'] as num).toInt(),
      status: OfflineCityPackStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OfflineCityPackStatus.idle,
      ),
      progress01: (json['progress01'] as num?)?.toDouble() ?? 0,
      estimatedTiles: (json['estimatedTiles'] as num?)?.toInt(),
      downloadedTiles: (json['downloadedTiles'] as num?)?.toInt(),
      errorMessage: json['errorMessage'] as String?,
      lastDownloadedAt: json['lastDownloadedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (json['lastDownloadedAt'] as num).toInt(),
            ),
      enabledForBrowsing: json['enabledForBrowsing'] as bool? ?? true,
    );
  }
}