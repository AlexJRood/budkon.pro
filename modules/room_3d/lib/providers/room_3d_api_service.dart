/// REST client for `RoomSceneProject` persistence (`/room-3d/projects/` on
/// the hously.cloud backend — see docs/sims_mode/IMPLEMENTATION_CHECKLIST.md
/// Faza 1 "Zapis sceny"). Deliberately slimmer than
/// `floor_plan/providers/floor_plan_api_service.dart` (no HTML-error-page
/// sniffing, no field-name-variant fallbacks) — this is a fresh endpoint we
/// control end to end, unlike floor_plan's, which had to tolerate an older
/// API's inconsistent field naming.
library;

import 'package:core/platform/api_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'urls.dart';

final room3dApiServiceProvider = Provider<Room3dApiService>((ref) {
  return const Room3dApiService(baseUrl: URLsRoom3d.baseUrl);
});

class RoomSceneProjectDto {
  final String id;
  final String title;
  final Map<String, dynamic> sceneDocument;
  final int revision;
  final String? targetObjectId;

  const RoomSceneProjectDto({
    required this.id,
    required this.title,
    required this.sceneDocument,
    required this.revision,
    this.targetObjectId,
  });

  factory RoomSceneProjectDto.fromJson(Map<String, dynamic> json) {
    return RoomSceneProjectDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Scena 3D',
      sceneDocument: json['scene_document'] is Map
          ? Map<String, dynamic>.from(json['scene_document'] as Map)
          : const {},
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      targetObjectId: json['target_object_id']?.toString(),
    );
  }
}

class Room3dApiService {
  final String baseUrl;

  const Room3dApiService({required this.baseUrl});

  String get _projectsUrl => '${baseUrl}projects/';
  String _projectUrl(String id) => '${baseUrl}projects/${id.trim()}/';
  String _saveUrl(String id) => '${baseUrl}projects/${id.trim()}/save/';

  Future<RoomSceneProjectDto> createProject({
    required WidgetRef ref,
    required String title,
    String? targetObjectId,
    String? targetAppLabel,
    String? targetModel,
  }) async {
    final response = await ApiServices.post(
      _projectsUrl,
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: {
        'title': title,
        if (targetObjectId != null) 'target_object_id': targetObjectId,
        if (targetAppLabel != null) 'target_app_label': targetAppLabel,
        if (targetModel != null) 'target_model': targetModel,
      },
    );

    return RoomSceneProjectDto.fromJson(_requireMap(response, 'createProject'));
  }

  Future<RoomSceneProjectDto> getProject({
    required WidgetRef ref,
    required String projectId,
  }) async {
    final response = await ApiServices.get(
      _projectUrl(projectId),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );

    return RoomSceneProjectDto.fromJson(_requireMap(response, 'getProject'));
  }

  Future<RoomSceneProjectDto> saveScene({
    required WidgetRef ref,
    required String projectId,
    required Map<String, dynamic> sceneDocument,
  }) async {
    final response = await ApiServices.post(
      _saveUrl(projectId),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      data: {'scene_document': sceneDocument},
    );

    return RoomSceneProjectDto.fromJson(_requireMap(response, 'saveScene'));
  }

  Map<String, dynamic> _requireMap(dynamic response, String context) {
    final statusCode = response is Response ? response.statusCode : null;

    if (statusCode == null || statusCode >= 400) {
      final body = response is Response ? response.data : null;
      throw Exception('room_3d $context failed (HTTP $statusCode): $body');
    }

    final data = response is Response ? response.data : null;

    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw Exception('room_3d $context: expected a JSON object, got ${data.runtimeType}');
  }
}
