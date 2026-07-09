// =====================================================================
// lib/router_web/pages/article_pages.dart
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/common/shared_widgets/article_model.dart';
import 'package:core/platform/route_constant.dart';

// typedef + transparentRouteBuilder + buildDeferredScreen
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

// === deferred imports dla widoków artykułu ===
import 'package:articles/article_provider.dart'
    deferred as article_provider;
import 'package:articles/articles_pop_page/article_pop_page.dart'
    deferred as article_pop;

// zgodne z: typedef BeamRouteBuilder = dynamic Function(BuildContext, BeamState, Object?)
BeamPage articleViewPage(BuildContext context, BeamState state, Object? data) {
  final articleSlug = state.pathParameters['slug'] ?? '';
  final route       = state.pathParameters['route'] ?? '';

  // Brak data => odpal fetcher (deferred)
  if (data == null) {
    if (kDebugMode) debugPrint('open article fetcher, non tag');
    return BeamPage(
      key:   ValueKey('commonPage-$route-$articleSlug'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        article_provider.loadLibrary,
        () => article_provider.ArticleFetcher(articleSlug: articleSlug, tag: ''),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  final map            = (data is Map) ? data as Map : const {};
  final articles       = map['articles'] as Article?;
  final tagArticlesPop = (map['tagArticlesPop'] as String?) ?? '';

  // Jeśli brak tagu lub modelu — również fetcher (deferred)
  if (tagArticlesPop.isEmpty || articles == null) {
    if (kDebugMode) debugPrint('open article fetcher');
    return BeamPage(
      key:   ValueKey('commonPage-$route-$articleSlug'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        article_provider.loadLibrary,
        () => article_provider.ArticleFetcher(
          articleSlug: articleSlug,
          tag:         tagArticlesPop,
        ),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  // Inaczej — pop z artykułem (deferred)
  return BeamPage(
    key:    ValueKey(Routes.articlePop),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      article_pop.loadLibrary,
      () => article_pop.ArticlePop(
        articlePop:    articles,
        tagArticlePop: tagArticlesPop,
      ),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}
