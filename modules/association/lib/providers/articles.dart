// lib/article/article_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class ArticleApi {
  static const String baseUrl = 'https://www.superbee.cloud';

  // LIST by association
  static Future<Map<String, dynamic>> listAssociationArticles({
    required Ref ref,
    required int associationId,
    int page = 1,
    int pageSize = 10,
    String? search,
    String? ordering, // e.g. '-published_date' or 'title'
  }) async {
    final url = '$baseUrl/article/';
    final query = <String, dynamic>{
      'publisher': associationId,
      'page': page,
      'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
    };
    final res = await ApiServices.get(
      url,
      hasToken: true,
      ref: ref,
      queryParameters: query,
      responseType: ResponseType.json,
    );
    if (res == null) throw Exception('No response');
    if (res.statusCode != 200) {
      throw Exception('List failed (${res.statusCode}): ${res.data}');
    }
    return res.data is Map ? res.data as Map : jsonDecode(utf8.decode(res.data));
  }

  // DETAIL
  static Future<Map<String, dynamic>> getArticle({
    required Ref ref,
    required int articleId,
  }) async {
    final url = '$baseUrl/article/$articleId/';
    final res = await ApiServices.get(
      url,
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Get failed (${res?.statusCode ?? "no response"})');
    }
    return res.data is Map ? res.data as Map : jsonDecode(utf8.decode(res.data));
  }

  // CREATE (association)
  static Future<Map<String, dynamic>> createAssociationArticle({
    required Ref ref,
    required int associationId,
    required String title,
    required String body,
    String status = 'draft',
    String? seoTitle,
    List<int>? tagIds,
    List<int>? seoTagIds,
  }) async {
    final url = '$baseUrl/article/association/$associationId/create/';
    final payload = {
      'title': title,
      'body': body,
      'status': status,
      if (seoTitle != null) 'seoTitle': seoTitle,
      'tags': tagIds ?? <int>[],
      'seoTags': seoTagIds ?? <int>[],
    };
    final res = await ApiServices.post(
      url,
      data: payload,
      hasToken: true,
      ref: ref,
    );
    if (res == null) throw Exception('No response');
    if (res.statusCode != 201) {
      throw Exception('Create failed (${res.statusCode}): ${res.data}');
    }
    if (res.data is Map<String, dynamic>) return res.data;
    if (res.data is String) return jsonDecode(res.data);
    return jsonDecode(utf8.decode(res.data));
  }

  // UPDATE (PATCH)
  static Future<Map<String, dynamic>> updateArticle({
    required Ref ref,
    required int articleId,
    String? title,
    String? body,
    String? status,
    String? seoTitle,
    List<int>? tagIds,
    List<int>? seoTagIds,
  }) async {
    final url = '$baseUrl/article/$articleId/';
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (seoTitle != null) 'seoTitle': seoTitle,
      if (tagIds != null) 'tags': tagIds,
      if (seoTagIds != null) 'seoTags': seoTagIds,
    };
    final res = await ApiServices.patch(
      url,
      hasToken: true,
      ref: ref,
      data: payload,
    );
    if (res == null) throw Exception('No response');
    if (res.statusCode != 200) {
      throw Exception('Update failed (${res.statusCode}): ${res.data}');
    }
    return res.data is Map ? res.data as Map : jsonDecode(utf8.decode(res.data));
  }

  // DELETE
  static Future<void> deleteArticle({
    required Ref ref,
    required int articleId,
  }) async {
    final url = '$baseUrl/article/$articleId/';
    final res = await ApiServices.delete(
      url,
      hasToken: true,
    );
    if (res == null || (res.statusCode != 204 && res.statusCode != 200)) {
      throw Exception('Delete failed: ${res?.statusCode} ${res?.data}');
    }
  }

  // THUMBNAIL (optional ImageField)
  static Future<void> uploadThumbnail({
    required WidgetRef ref,
    required int articleId,
    required File file,
    void Function(int, int)? onSendProgress,
  }) async {
    final url = '$baseUrl/article/$articleId/';
    final form = FormData.fromMap({
      'thumbnail': await MultipartFile.fromFile(file.path),
    });
    final res = await ApiServices.patch(
      url,
      hasToken: true,
      ref: ref,
      formData: form,
      data: null,
      // onSendProgress available in ApiServices.post; patch też obsługuje via Dio
    );
    if (res == null || (res.statusCode != 200 && res.statusCode != 202)) {
      throw Exception('Thumbnail upload failed: ${res?.statusCode} ${res?.data}');
    }
  }
}



// lib/article/article_api.dart (tam gdzie masz klasę zdefiniowaną)
class ArticleListArgs {
  final int associationId;
  final int page;
  final int pageSize;
  final String? search;
  final String? ordering;

  const ArticleListArgs({
    required this.associationId,
    this.page = 1,
    this.pageSize = 10,
    this.search,
    this.ordering,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArticleListArgs &&
        other.associationId == associationId &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.search == search &&
        other.ordering == ordering;
  }

  @override
  int get hashCode => Object.hash(
        associationId,
        page,
        pageSize,
        search,
        ordering,
      );
}


final associationArticlesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, ArticleListArgs>((ref, args) {
  return ArticleApi.listAssociationArticles(
    ref: ref,
    associationId: args.associationId,
    page: args.page,
    pageSize: args.pageSize,
    search: args.search,
    ordering: args.ordering ?? '-published_date',
  );
});


/// Create
class CreateArticleController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  CreateArticleController(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<Map<String, dynamic>> create({
    required int associationId,
    required String title,
    required String body,
    String status = 'draft',
    String? seoTitle,
    List<int>? tagIds,
    List<int>? seoTagIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final created = await ArticleApi.createAssociationArticle(
        ref: ref,
        associationId: associationId,
        title: title,
        body: body,
        status: status,
        seoTitle: seoTitle,
        tagIds: tagIds,
        seoTagIds: seoTagIds,
      );
      state = AsyncValue.data(created);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final createArticleControllerProvider =
    StateNotifierProvider<CreateArticleController, AsyncValue<Map<String, dynamic>?>>(
  (ref) => CreateArticleController(ref),
);

/// Update
class UpdateArticleController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  UpdateArticleController(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<Map<String, dynamic>> update({
    required int articleId,
    String? title,
    String? body,
    String? status,
    String? seoTitle,
    List<int>? tagIds,
    List<int>? seoTagIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = await ArticleApi.updateArticle(
        ref: ref,
        articleId: articleId,
        title: title,
        body: body,
        status: status,
        seoTitle: seoTitle,
        tagIds: tagIds,
        seoTagIds: seoTagIds,
      );
      state = AsyncValue.data(updated);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final updateArticleControllerProvider =
    StateNotifierProvider<UpdateArticleController, AsyncValue<Map<String, dynamic>?>>(
  (ref) => UpdateArticleController(ref),
);

/// Delete
final deleteArticleProvider = FutureProvider.family<void, int>((ref, articleId) async {
  await ArticleApi.deleteArticle(ref: ref, articleId: articleId);
});





// Reuses your existing associationArticlesProvider; no new API calls.
final recentAssocArticlesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, associationId) async {
  final args = ArticleListArgs(
    associationId: associationId,
    page: 1,
    pageSize: 5,
    ordering: '-published_date',
  );
  final data = await ref.watch(associationArticlesProvider(args).future);
  final results = (data['results'] as List?) ?? const [];
  return results.cast<Map<String, dynamic>>();
});
