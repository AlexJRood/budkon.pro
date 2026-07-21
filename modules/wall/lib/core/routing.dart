// =====================================================================
// Unified wall routes — single registration for native AND web.
// Deferred (code-split) screen loading on web; eager on native. Selected at
// compile time by the conditional `router_utils` import: the web variant's
// `buildDeferredScreen` code-splits, the native variant builds immediately.
// Route map, patterns, meta tags and transitions live here ONCE.
// =====================================================================
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';

import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:wall/wall_screen/wall_screen.dart' deferred as wall_page;
import 'package:wall/wall_screen/providers/single_post_fetcher.dart'
    deferred as wall_provider;
import 'package:wall/wall_screen/screens/widgets/create_post_dialog/post_create_screen.dart'
    deferred as wall_create_post;


final Map<Pattern, BeamRouteBuilder> wallRoutes = {
  Routes.wall: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.wall),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        wall_page.loadLibrary,
        () => wall_page.WallScreen(),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  },

  // Keep before singlePost when patterns could conflict.
  Routes.createPostWall: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.createPostWall),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        wall_create_post.loadLibrary,
        () => wall_create_post.PostCreateScreen(),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  },

  Routes.singlePost: (context, state, data) {
    final idStr = state.pathParameters['id'] ?? '';
    final postId = int.tryParse(idStr) ?? -1;

    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.singlePost),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        wall_provider.loadLibrary,
        () => wall_provider.SinglePostFetcher(postId: postId),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  },

};
