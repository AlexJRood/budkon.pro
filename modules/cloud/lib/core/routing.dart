import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import 'package:cloud/cloud.dart' deferred as cloud;

final Map<Pattern, BeamRouteBuilder> cloudRoutes = {
  Routes.cloudStorage: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.cloudStorage),
        title: Routes.getWebsiteTitle(context),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
        child: buildDeferredScreen(
          cloud.loadLibrary,
          () => cloud.CloudStoragePage(),
      ),
  ),
    

  // Docs with Quill sample (non-deferred – lekka konfiguracja),
};
