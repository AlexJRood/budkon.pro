// =====================================================================
// lib/router_web/modules/network_monitoring_routes.dart
// =====================================================================
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'nm_ad_pages.dart';


// nasz helper: transparentRouteBuilder + buildDeferredScreen
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:core/platform/route_constant.dart';

// =================== deferred imports (strony ciężkie) ===================
import 'package:notification/notification_screen.dart'
    deferred as notification_page;

import 'package:network_monitoring/screens/nm_feed.dart'
    deferred as nm_feed;

import 'package:network_monitoring/screens/nm_home.dart'
    deferred as nm_home;

import 'package:network_monitoring/screens/nm_saved_searches.dart'
    deferred as nm_saved;

import 'package:network_monitoring/screens/map/network_monitoring_map_view_pc_page.dart'
    deferred as nm_map;

import 'package:network_monitoring/widgets/nm_full_screen_image.dart'
    deferred as nm_full_img;

import 'package:fav_board/screens/fav_screen.dart' deferred as fav;
import 'package:network_monitoring/screens/saved_search_new_screens/sort_pop_mobile_page.dart'
    deferred as nm_sort_pop_mobile;
import 'package:network_monitoring/filters/new_screens/new_filter_pop_page.dart'
    deferred as nm_filter_pop;



int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

// =====================================================================
// MAPA TRAS (każda child wczytywana leniwie przez buildDeferredScreen)
// =====================================================================
final Map<Pattern, BeamRouteBuilder> networkMonitoringRoutes = {
  Routes.sortPopMobile: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.sortPopMobile),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          nm_sort_pop_mobile.loadLibrary,
          () => nm_sort_pop_mobile.SortPopMobilePage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.filters: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.filters),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          nm_filter_pop.loadLibrary,
          () => nm_filter_pop.NewFilterPopPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  // ---------- Notifications (modal fade, półprzezroczysty overlay) ----------

  // Favorites / GoPro / Payments
  Routes.nmFav: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.fav),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          fav.loadLibrary,
          () => fav.FavScreen(appModule: AppModule.networkMonitoring,),
      ),
  ),


  Routes.notifications: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.notifications),
        title: Routes.getWebsiteTitle(context),
        type: BeamPageType.fadeTransition,
        child: buildDeferredScreen(
          notification_page.loadLibrary,
          () => notification_page.NotificationScreen(),
        ),
        routeBuilder: (context, settings, child) => PageRouteBuilder(
          settings: settings,
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black.withAlpha(76),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          ),
        ),
      ),

  // ---------- /nm (feed) ----------
  Routes.networkMonitoring: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.networkMonitoring),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          nm_feed.loadLibrary,
          () => nm_feed.NMFeedPage(),
        ),
      ),

  // ---------- /nm/saved ----------

    Routes.saveNetworkMonitoring: (context, state, data) {
      final map = data is Map
          ? data.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{};

      return BeamPage(
        key: const ValueKey(Routes.saveNetworkMonitoring),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
        child: buildDeferredScreen(
          nm_saved.loadLibrary,
          () => nm_saved.ListWithSaveSearchScreen(
            
          initialSavedSearchId: _asInt(
            map['saved_search_id'] ?? map['savedSearchId'],
          ),
          initialAdId: _asInt(
            map['ad_id'] ?? map['adId'],
          ),
          fromNotification: map['from_notification'] == true,
        ),
        ),
      );
    },




  // ---------- /nm/home ----------
  Routes.homeNetworkMonitoring: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.homeNetworkMonitoring),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          nm_home.loadLibrary,
          () => nm_home.MonitoringHomeScreen(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),




  Routes.mapNetworkMonitoring: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.mapNetworkMonitoring),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          nm_map.loadLibrary,
          () => nm_map.NetworkMonitoringMapViewPcPage(),
        ),
      ),


  // ---------- full screen image viewer (używany też poza NM) ----------
  Routes.imageView: (context, state, data) {
    final map = (data is Map) ? data as Map : const {};
    final tag = (map['tag'] as String?) ?? '';
    final initialPage = (map['initialPage'] as int?) ?? 0;
    final images = (map['images'] as List<String>?) ?? const <String>[];

    return BeamPage(
      key: const ValueKey(Routes.imageView),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        nm_full_img.loadLibrary,
        () => nm_full_img.NMFullScreenImageView(
          tag: tag,
          images: images,
          initialPage: initialPage,
        ),
      ),
      type: BeamPageType.fadeTransition,
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  },

  // ---------- NM ad view (delegowane do strony z PAGES) ----------
  Routes.networkMonitoringSingle: nmAdViewPage,
  Routes.nmAdHomePage: nmAdViewPage,
};
