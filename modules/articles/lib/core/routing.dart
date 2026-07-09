

// =====================================================================
// lib/router_web/modules/articles_routes.dart
// =====================================================================
import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'article_pages.dart';
import 'package:articles/all_articles.dart' deferred as all_article_page;
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';


final Map<Pattern, BeamRouteBuilder> articlesRoutes = {
  Routes.singleArticlePop: articleViewPage,
  Routes.articlePagePop: articleViewPage,
  Routes.articlePage: (context, state, data) {
          return BeamPage(
              key: const ValueKey(Routes.articlePage),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  all_article_page.loadLibrary,
                  () => all_article_page.ArticlesPage()
                     ));
        },

  // Chat (custom fade+slide overlay) – deferred,
};