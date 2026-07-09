import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:articles/articles_pop_page/article_pop_page.dart';
import 'package:core/platform/url.dart';
import 'package:core/common/shared_widgets/article_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:flutter/material.dart';



// Definicja providera
final articleProvider = FutureProvider<List<Article>>((ref) async {
  final response = await ApiServices.get(URLs.apiArticles,ref: ref);
  if (response != null && response.statusCode == 200) {
    // Dekodowanie odpowiedzi z użyciem UTF-8
    final responseBody = utf8.decode(response.data);
    List<dynamic> data = (json.decode(responseBody)['results']) as List;
    return data
        .map<Article>((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  } else {
    throw Exception('Failed to load articles');
  }
});


final singleArticleProvider =
    FutureProvider.family<Article, String>((ref, articleSlug) async {
  final response = await ApiServices.get(
    ref: ref,
    '${URLs.apiArticles}search_by_slug/?slug=$articleSlug',
  );

  if (response != null && response.statusCode == 200) {
    final decodedBody = utf8.decode(response.data);
    final articleJson = json.decode(decodedBody) as Map<String, dynamic>;

    return Article.fromJson(articleJson);
  } else {
    throw Exception('Failed to load article');
  }
});



class ArticleFetcher extends ConsumerWidget {
  final String articleSlug;
  final String tag;

  const ArticleFetcher({required this.articleSlug, required this.tag, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsyncValue = ref.watch(singleArticleProvider(articleSlug));

    return articleAsyncValue.when(
      data: (article) => ArticlePop(articlePop: article, tagArticlePop: tag),
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.transparent,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error'.tr)),
      ),
    );
  }
}
