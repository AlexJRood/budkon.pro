// =====================================================================
// lib/router_web/pages/nm_ad_pages.dart
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart'; // transparentRouteBuilder + buildDeferredScreen

// deferred: ciężkie UI ładujemy na żądanie
import 'package:network_monitoring/screens/feed_pop/nm_feed_pop.dart'
    deferred as nm_feed_pop; // -> NMFeedPop
import 'package:network_monitoring/screens/feed_pop/providers/nm_ad_provider.dart'
    deferred as nm_ad_provider; // -> NMAdFetcher

import 'package:network_monitoring/models/monitoring_ads_model.dart';

// zgodne z: typedef BeamRouteBuilder = dynamic Function(BuildContext, BeamState, Object?)
BeamPage nmAdViewPage(BuildContext context, BeamState state, Object? data) {
  final route = state.pathParameters['route'] ?? '';
  final idStr = state.pathParameters['id'] ?? '';
  final networkId = int.tryParse(idStr) ?? -1;

  if (kDebugMode) {
    debugPrint('route $route');
    debugPrint('id $networkId (raw: $idStr)');
    debugPrint('data $data');
  }

  // 1) brak danych -> fetcher (tag = '')
  if (data == null) {
    return BeamPage(
      key: ValueKey('commonPage-$route-$networkId'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        nm_ad_provider.loadLibrary,
        () => nm_ad_provider.NMAdFetcher(adNetworkPop: networkId, tagNetworkPop: ''),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  final map = (data is Map) ? data as Map : const {};
  final tag = (map['tag'] as String?) ?? '';

  // 2) pusty tag -> nadal fetcher (może inny stan)
  if (tag.isEmpty) {
    return BeamPage(
      key: ValueKey('commonPage-$route-$networkId'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        nm_ad_provider.loadLibrary,
        () => nm_ad_provider.NMAdFetcher(adNetworkPop: networkId, tagNetworkPop: tag),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  // 3) jest tag — spróbujmy NMFeedPop, ale tylko gdy jest też 'ad'
  final feedAd = map['ad'] as MonitoringAdsModel?;
  if (feedAd == null) {
    // brak modelu -> fallback do fetchera (zapobiegnie NPE)
    return BeamPage(
      key: ValueKey('commonPage-$route-$networkId'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        nm_ad_provider.loadLibrary,
        () => nm_ad_provider.NMAdFetcher(adNetworkPop: networkId, tagNetworkPop: tag),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  // 4) normalny pop
  return BeamPage(
    key: ValueKey('commonPage-$route-$networkId'),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      nm_feed_pop.loadLibrary,
      () => nm_feed_pop.NMFeedPop(adNetworkPop: feedAd, tagNetworkPop: tag),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}
