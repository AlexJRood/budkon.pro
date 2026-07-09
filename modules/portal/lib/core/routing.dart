// =====================================================================
// lib/router_web/modules/portal_routes.dart
// =====================================================================
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'portal_ad_pages.dart';

// ENTRY / FEED (NO DEFERRED)
import 'package:portal/screens/feed/widgets/basic_view/ads_view_pc.dart';
import 'package:portal/screens/landing_page/landing_page.dart';

// router utils
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import 'package:core/platform/route_constant.dart';

// ---------------------------------------------------------------------
// DEFERRED imports — everything except entry + feed view + adViewPage
// ---------------------------------------------------------------------

// portal pages
import 'package:portal/screens/add_offer/add_offer_page.dart' deferred as p_add_offer;
import 'package:portal/screens/edit_offer/edit_offer_page.dart' deferred as p_edit_offer;
import 'package:portal/screens/feed/widgets/about_us/about_us_main.dart' deferred as p_about_us;
import 'package:portal/screens/feed/widgets/map/map_view_page.dart' deferred as p_map_view;
import 'package:portal/screens/feed/widgets/map/pv_mobile_page.dart' deferred as p_pv_mobile;

// filters / pop pages
import 'package:portal/screens/pop_pages/pages/mobile_pop_appbar_page.dart' deferred as p_mobile_pop;
import 'package:portal/screens/pop_pages/pages/sort_pop_page.dart' deferred as p_sort_pop;
// import 'package:portal/screens/pop_pages/pages/sort_pop_mobile_page.dart' deferred as p_sort_pop_mobile;

// fav board
import 'package:fav_board/screens/fav_screen.dart' deferred as fav_screen;
import 'package:fav_board/screens/board_details_screen.dart' deferred as fav_board_details;

// payments / pro
import 'package:payments/go_pro/go_pro_page.dart' deferred as pay_go_pro;
import 'package:payments/go_pro/checkout/checkout_page.dart' deferred as pay_checkout;
import 'package:payments/go_pro/checkout/success_page.dart' deferred as pay_success;

// profile promo
import 'package:profile/widgets/promotion_package_ui/promotion_package_ui_widget.dart'
    deferred as promo_pkg;

// crm / dashboard / tms
import 'package:crm_agent/screens/agent_dashboard.dart' deferred as crm_dash;
import 'package:crm_agent/screens/agent_clients.dart' deferred as crm_clients;
import 'package:crm_agent/crm/finance_crm_page.dart' deferred as crm_finance;
import 'package:crm_agent/crm/agent_financial_plans_page.dart' deferred as crm_plans;
import 'package:tms_app/todo/todo_page.dart' deferred as tms_todo;
import 'package:tms_app/todo/board/board_page.dart' deferred as tms_board;

final Map<Pattern, BeamRouteBuilder> portalRoutes = {
  // App entry / landing (eager — it's the first paint, no code-split benefit).
  Routes.entry: (context, state, data) {
    return BeamPage(
      key: ValueKey('${Routes.entry}|${state.uri.path}?${state.uri.query}'),
      title: Routes.getWebsiteTitle(context),
      child: const LandingPage(),
    );
  },
  // ===================================================================
  // FEED VIEW (NO DEFERRED)
  // ===================================================================
  Routes.feedView: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.feedView),
        title: Routes.getWebsiteTitle(context),
        child: AdsViewPage(),
      ),


  Routes.singeEditOffer: (context, state, data) {
    final offerId = int.parse(state.pathParameters['offerId']!);
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.singeEditOffer),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(p_edit_offer.loadLibrary,
          () => p_edit_offer.EditOfferPage(offerId: offerId)),
    );
  },



  // ===================================================================
  // PORTAL PAGES (DEFERRED)
  // ===================================================================

  Routes.aboutusview: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.aboutusview),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          p_about_us.loadLibrary,
          () => p_about_us.BasicAboutUsPage(),
        ),
      ),

  Routes.fullmap: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.fullmap),
        child: buildDeferredScreen(
          p_pv_mobile.loadLibrary,
          () => p_pv_mobile.PvMobilePage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.mapView: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.mapView),
        child: buildDeferredScreen(
          p_map_view.loadLibrary,
          () => p_map_view.MapViewPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  // Routes.fullSize: (context, state, data) => BeamPage(
  //       key: const ValueKey(Routes.fullSize),
  //       child: buildDeferredScreen(
  //         p_full_size.loadLibrary,
  //         () => p_full_size.FullSizePage(),
  //       ),
  //       routeBuilder: (ctx, settings, child) =>
  //           transparentRouteBuilder(ctx, settings, child),
  //     ),

  // Routes.listview: (context, state, data) => BeamPage(
  //       key: const ValueKey(Routes.listview),
  //       child: buildDeferredScreen(
  //         p_list_view.loadLibrary,
  //         () => p_list_view.ListViewPage(),
  //       ),
  //       routeBuilder: (ctx, settings, child) =>
  //           transparentRouteBuilder(ctx, settings, child),
  //     ),

  // ===================================================================
  // Favorites / GoPro / Payments (DEFERRED)
  // ===================================================================

  Routes.fav: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.fav),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          fav_screen.loadLibrary,
          () => fav_screen.FavScreen(),
        ),
      ),

  Routes.favBoardDetailsPattern: (context, state, data) {
    return BeamPage(
      key: ValueKey('board-details-${state.pathParameters['id']}'),
      child: buildDeferredScreen(
        fav_board_details.loadLibrary,
        () => fav_board_details.BoardDetailsScreen(),
      ),
    );
  },

  Routes.goPro: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.goPro),
        child: buildDeferredScreen(
          pay_go_pro.loadLibrary,
          () => pay_go_pro.GoProPage(),
        ),
      ),

  Routes.checkOut: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.checkOut),
        child: buildDeferredScreen(
          pay_checkout.loadLibrary,
          () => pay_checkout.CheckoutPage(),
        ),
      ),

  Routes.success: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.success),
        child: buildDeferredScreen(
          pay_success.loadLibrary,
          () => pay_success.PaymentSuccessPage(),
        ),
      ),

  // ===================================================================
  // Promo / Dashboard / CRM / TMS (DEFERRED)
  // ===================================================================

  Routes.promotionPackage: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.promotionPackage),
        child: buildDeferredScreen(
          promo_pkg.loadLibrary,
          () => promo_pkg.PromotionPackageUiWidget(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.proDashboard: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.proDashboard),
        child: buildDeferredScreen(
          crm_dash.loadLibrary,
          () => crm_dash.NewDashboardScreen(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.proClients: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.proClients),
        child: buildDeferredScreen(
          crm_clients.loadLibrary,
          () => crm_clients.ClientsPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.proFinance: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.proFinance),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          crm_finance.loadLibrary,
          () => crm_finance.FinanceCrmPage(appModule: AppModule.agentCrm, companyId: null),
        ),
      ),

  Routes.proPlans: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.proPlans),
        child: buildDeferredScreen(
          crm_plans.loadLibrary,
          () => crm_plans.AgentFinancialPlansPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.proTodo: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.proTodo),
        child: buildDeferredScreen(
          tms_todo.loadLibrary,
          () => tms_todo.ToDoPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.proBoard: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.proBoard),
        child: buildDeferredScreen(
          tms_board.loadLibrary,
          () => tms_board.BoardPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  // ===================================================================
  // Sort / mobile pop (DEFERRED)
  // ===================================================================

  Routes.sortPop: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.sortPop),
        type: BeamPageType.fadeTransition,
        child: buildDeferredScreen(
          p_sort_pop.loadLibrary,
          () => p_sort_pop.SortPopPage(),
        ),
        routeBuilder: (context, s, child) => PageRouteBuilder(
          pageBuilder: (_, animation, __) =>
              FadeTransition(opacity: animation, child: child),
          opaque: false,
        ),
      ),

  Routes.mobilePop: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.mobilePop),
        type: BeamPageType.fadeTransition,
        child: buildDeferredScreen(
          p_mobile_pop.loadLibrary,
          () => p_mobile_pop.MobilePopAppBarPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.add: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.add),
        type: BeamPageType.fadeTransition,
        child: buildDeferredScreen(
          p_add_offer.loadLibrary,
          () => p_add_offer.AddOfferPage(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  // ===================================================================
  // AD routes -> keep as-is (NO DEFERRED), handled by adViewPage
  // ===================================================================
  Routes.adProfile: adViewPage,
  Routes.adCompany: adViewPage,
  Routes.adFav: adViewPage,
  Routes.adMapView: adViewPage,
  Routes.adListView: adViewPage,
  Routes.adFullSize: adViewPage,
  Routes.feedViewAd: adViewPage,
  Routes.entryAd: adViewPage,
  Routes.fullmapAd: adViewPage,
  Routes.adFavBoardDetailsPattern: adViewPage,
  Routes.publicProfileAd: adViewPage,
  Routes.publicCompanyAd: adViewPage,
};
