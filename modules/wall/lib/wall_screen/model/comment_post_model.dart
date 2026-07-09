
// Added import for MediaType

import 'community_post_model.dart';

class CommentUser {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;

  const CommentUser({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'avatar': avatar,
  };
}

class CommunityComment {
  final int id;
  final int post;
  final CommentUser user;
  final String content;
  final List<CommunityMedia> media;
  final DateTime createdAt;
  final int totalLikes; // Added total_likes field
  final bool hasUserLiked;

  const CommunityComment({
    required this.id,
    required this.post,
    required this.user,
    required this.content,
    required this.media,
    required this.createdAt,
    required this.totalLikes,
    required this.hasUserLiked,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? mediaList = json['media'];
    return CommunityComment(
      id: json['id'],
      post: json['post'],
      user: CommentUser.fromJson(json['user']),
      content: json['content'] ?? '',
      media: mediaList != null
          ? mediaList.map((e) => CommunityMedia.fromJson(e)).toList()
          : [],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      totalLikes: json['total_likes'] ?? 0, // Handle total_likes from JSON
      hasUserLiked:
          json['has_user_liked'] ?? false, // Handle total_likes from JSON
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post': post,
    'user': user.toJson(),
    'content': content,
    'media': media.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'total_likes': totalLikes, // Include total_likes in JSON output
    
  };

  // Helper getter to get user ID
  int get userId {
    return user.email.hashCode; // Using email hash as a unique identifier
  }

  // Helper getter to get user info
  CommentUser get userInfo {
    return user;
  }
}
