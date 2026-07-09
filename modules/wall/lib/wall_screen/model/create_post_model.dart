

import 'dart:typed_data';

class CreatePostState {
  final String content;
  final String wallType;
  final String? location;
  final double? lat;
  final double? lon;
  final List<Uint8List>? imagesData;
  final List<int> taggedUserIds;
  final List<int> deleteMediaIds; // IDs of existing media to delete (edit mode only)

  CreatePostState({
    required this.content,
    required this.wallType,
    this.location,
    this.lat,
    this.lon,
    this.imagesData,
    this.taggedUserIds = const [3],
    this.deleteMediaIds = const [],
  });

  CreatePostState copyWith({
    String? content,
    String? wallType,
    String? location,
    double? lat,
    double? lon,
    List<Uint8List>? imagesData,
    List<int>? taggedUserIds,
    List<int>? deleteMediaIds,
  }) {
    return CreatePostState(
      content: content ?? this.content,
      wallType: wallType ?? this.wallType,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      imagesData: imagesData ?? this.imagesData,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      deleteMediaIds: deleteMediaIds ?? this.deleteMediaIds,
    );
  }
}


