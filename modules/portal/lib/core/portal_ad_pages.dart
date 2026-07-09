// =====================================================================
// lib/router_web/pages/portal_ad_pages.dart
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:portal/screens/feed/widgets/feed_pop/feed_pop.dart';
import 'package:portal/screens/feed/provider/feed_pop/ad_provider.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import 'package:core/platform/route_constant.dart';

// Sygnatura zgodna z naszym typedefem BeamRouteBuilder:
// typedef BeamRouteBuilder = dynamic Function(BuildContext, BeamState, Object?);
BeamPage adViewPage(BuildContext context, BeamState state, Object? data) {
  final feedAdSlug = state.pathParameters['slug'] ?? '';
  final route = state.pathParameters['route'] ?? '';

  // Brak data -> tryb fetchera bez taga
  if (data == null) {
    if (kDebugMode) debugPrint('open fp with ad fetcher, non tag');
    return BeamPage(
      key: ValueKey('commonPage-$route-$feedAdSlug'),
      title: Routes.getWebsiteTitle(context),
      child: AdFetcher(feedAdSlug: feedAdSlug, tag: ''),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  // Mamy data -> bezpieczne rzutowanie
  final map = (data is Map) ? data as Map : const {};
  final tag = (map['tag'] as String?) ?? '';
  final feedAd = map['ad'] as AdsListViewModel?;
  final isChat = (map['isChat'] as bool?) ?? false;

  if (tag.isNotEmpty && feedAd != null) {
    if (kDebugMode) {
      debugPrint('open feed pop page');
      debugPrint(tag);
    }
    return BeamPage(
      key: ValueKey('commonPage-$route-$feedAdSlug'),
      title: Routes.getWebsiteTitle(context),
      child: FeedPopPage(adFeedPop: feedAd, tagFeedPop: tag,isChat: isChat,),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  // Domyślnie: fetch po slugu z (ew.) pustym tagiem
  if (kDebugMode) debugPrint('open fp with ad fetcher');
  return BeamPage(
    key: ValueKey('commonPage-$route-$feedAdSlug'),
    title: Routes.getWebsiteTitle(context),
    child: AdFetcher(feedAdSlug: feedAdSlug, tag: tag),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}
