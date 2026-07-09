import 'user_model.dart';

const boardModelDefault = BoardModel(
  count: 0,
  next: null,
  previous: null,
  results: [],
);

class BoardModel {
  final int? count;
  final String? next;
  final String? previous;
  final List<BoardResults>? results;

  const BoardModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory BoardModel.fromJson(Map json) {
    final map = Map<String, dynamic>.from(json);

    final rawResults = map['results'];
    final List<BoardResults> parsedResults =
        rawResults is List
            ? rawResults
                .whereType<Map>()
                .map((v) => BoardResults.fromJson(Map<String, dynamic>.from(v)))
                .toList()
            : <BoardResults>[];

    return BoardModel(
      count: map['count'] is int
          ? map['count'] as int
          : int.tryParse('${map['count']}') ?? 0,
      next: map['next']?.toString(),
      previous: map['previous']?.toString(),
      results: parsedResults,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results?.map((v) => v.toJson()).toList(),
    };
  }

  BoardModel copyWith({
    int? count,
    String? next,
    String? previous,
    List<BoardResults>? results,
  }) {
    return BoardModel(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }
}

class BoardResults {
  final int? id;
  final User? user;
  final String? name;
  final String? timestamp;
  final String? updatedAt;
  final int? version;
  final String? avatar;

  const BoardResults({
    required this.id,
    required this.user,
    required this.name,
    required this.timestamp,
    required this.updatedAt,
    required this.version,
    required this.avatar,
  });

  factory BoardResults.fromJson(Map json) {
    final map = Map<String, dynamic>.from(json);

    String? rawAvatar = map['avatar']?.toString();
    if (rawAvatar != null && rawAvatar.startsWith('http://')) {
      rawAvatar = rawAvatar.replaceFirst('http://', 'https://');
    }

    return BoardResults(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      user: map['user'] is Map
          ? User.fromJson(Map<String, dynamic>.from(map['user']))
          : null,
      name: map['name']?.toString(),
      timestamp: map['timestamp']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      version: map['version'] is int
          ? map['version'] as int
          : int.tryParse('${map['version']}'),
      avatar: rawAvatar ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'name': name,
      'timestamp': timestamp,
      'updated_at': updatedAt,
      'version': version,
      'avatar': avatar,
    };
  }

  BoardResults copyWith({
    int? id,
    User? user,
    String? name,
    String? timestamp,
    String? updatedAt,
    int? version,
    String? avatar,
  }) {
    return BoardResults(
      id: id ?? this.id,
      user: user ?? this.user,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      avatar: avatar ?? this.avatar,
    );
  }
}