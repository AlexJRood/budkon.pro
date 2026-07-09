import 'package:core/platform/url.dart';

/// wall feature API endpoints, decentralized out of core's URLs God-package.
class WallUrls {
  const WallUrls._();

static String commentGetPost(int postId) =>
      URLs.appendBaseUrl("/community/comments/?post=$postId");
static final communityCommentPost = URLs.appendBaseUrl('/community/comments/');
static String communityPostAddLike(int postId) =>
      URLs.appendBaseUrl("/community/like/post/$postId/");
static final communityPosts = URLs.appendBaseUrl('/community/posts/upload-post/');
static final communityPostsList = URLs.appendBaseUrl('/community/posts/');
static final communityPostsListAgents = URLs.appendBaseUrl(
    '/community/posts/?wall_type=agents',
  );
static final communityPostsListDevelopers = URLs.appendBaseUrl(
    '/community/posts/?wall_type=developers',
  );
static final communityPostsListFavorites = URLs.appendBaseUrl(
    '/community/posts/?wall_type=favourites',
  );
static final communityPostsListFlipers = URLs.appendBaseUrl(
    '/community/posts/?wall_type=flipers',
  );
static final communityPostsListGroups = URLs.appendBaseUrl(
    '/community/posts/?wall_type=groups',
  );
static String deletePost(int postId) =>
      URLs.appendBaseUrl("/community/posts/$postId/");
static String editPost(int postId) =>
      URLs.appendBaseUrl("/community/posts/$postId/edit/");
static String likeToComment(int commentId) =>
      URLs.appendBaseUrl("/community/like/comment/$commentId/");
static String singlePost(int postId) =>
      URLs.appendBaseUrl("/community/posts/$postId/");
}
