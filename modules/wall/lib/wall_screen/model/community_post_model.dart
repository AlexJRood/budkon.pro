

class CommunityAuthor { final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;

  CommunityAuthor({     
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  factory CommunityAuthor.fromJson(Map<String, dynamic> json) {
    return CommunityAuthor(
      userId: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

    factory CommunityAuthor.empty() {
      return CommunityAuthor(
        userId: 0,
        username: '',
        email: '',
        firstName: '',
        lastName: '',
        avatar: '',
      );
    }

  Map<String, dynamic> toJson() {
    return {
      "id": userId,
      "username": username,
      "email": email,
      "first_name": firstName,
      "last_name": lastName,
      "avatar": avatar,
    };
  }
}

class CommunityMedia {
  final int id;
  final String url;
  final String mediaType; // e.g., "image", "video", "pdf"
  final int order;

  CommunityMedia({
    required this.id,
    required this.url,
    required this.mediaType,
    required this.order,
  });

  factory CommunityMedia.fromJson(Map<String, dynamic> json) {
    return CommunityMedia(
      id: int.tryParse(json['id'].toString()) ?? 0,
      url: json['url'] ?? '',
      mediaType: json['media_type'] ?? 'unknown',
      order: int.tryParse(json['order'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'url': url, 'media_type': mediaType, 'order': order};
  }

  bool get isImage => mediaType == 'image';

  bool get isVideo => mediaType == 'video';

  bool get isPdf => mediaType == 'pdf';
}

class CommunityPost {
  final int id;
  final CommunityAuthor author;
  final String content;
  final List<CommunityMedia> media;
  final String wallType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalLikes;
  final int totalComments;
  final bool hasUserLiked;

  // New fields
  final String? location;
  final double? lat;
  final double? lon;
  final List<int> taggedUsers;
  final List<TaggedUserData> taggedUsersData;

  CommunityPost({
    required this.id,
    required this.author,
    required this.content,
    required this.media,
    required this.wallType,
    required this.createdAt,
    required this.updatedAt,
    required this.totalLikes,
    required this.totalComments,
    required this.hasUserLiked,
    this.location,
    this.lat,
    this.lon,
    this.taggedUsers = const [],
    this.taggedUsersData = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? mediaList = json['media'];
    final List<dynamic>? taggedUserList = json['tagged_users'];
    final List<dynamic>? taggedUserDataList = json['tagged_users_data'];

    return CommunityPost(
      id: int.tryParse(json['id'].toString()) ?? 0,
      author: CommunityAuthor.fromJson(json['author'] ?? {}),
      content: json['content'] ?? '',
      hasUserLiked: json['has_this_user_liked'] ?? false,
      media: mediaList != null
          ? mediaList.map((e) => CommunityMedia.fromJson(e)).toList()
          : [],
      wallType: json['wall_type'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      totalLikes: int.tryParse(json['total_likes'].toString()) ?? 0,
      totalComments: int.tryParse(json['total_comments'].toString()) ?? 0,
      location: json['location'],
      lat: (json['lat'] != null)
          ? double.tryParse(json['lat'].toString())
          : null,
      lon: (json['lon'] != null)
          ? double.tryParse(json['lon'].toString())
          : null,
      taggedUsers: taggedUserList != null
          ? taggedUserList.map((e) => int.tryParse(e.toString()) ?? 0).toList()
          : [],
      taggedUsersData: taggedUserDataList != null
          ? taggedUserDataList.map((e) => TaggedUserData.fromJson(e)).toList()
          : [],
    );
  }

  factory CommunityPost.empty() {
    return CommunityPost(
      id: 0,
      author: CommunityAuthor.empty(),
      content: '',
      media: [],
      wallType: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalLikes: 0,
      totalComments: 0,
      hasUserLiked: false,
      location: null,
      lat: null,
      lon: null,
      taggedUsers: [],
      taggedUsersData: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "content": content,
      "wall_type": wallType,
      "media": media.map((e) => e.toJson()).toList(),
      "author": author.toJson(), // optional for uploads
      "location": location,
      "lat": lat,
      "lon": lon,
      "tagged_users": taggedUsers,
      "tagged_users_data": taggedUsersData.map((e) => e.toJson()).toList(),
    };
  }
}





class TaggedUserData {
  final int id;
  final String firstName;
  final String lastName;
  final String avatar;

  TaggedUserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  factory TaggedUserData.fromJson(Map<String, dynamic> json) {
    return TaggedUserData(
      id: int.tryParse(json['id'].toString()) ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "avatar": avatar,
    };
  }
}
