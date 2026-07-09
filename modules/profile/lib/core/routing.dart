// =====================================================================
// lib/router_web/modules/profile_routes.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart'; // <- buildDeferredScreen + setupMetaTag + transparentRouteBuilder
import 'package:core/platform/route_constant.dart';

// ================== DEFERRED IMPORTS ==================
import 'package:seller/screens/seller_profile_screen.dart' 
    deferred as seller_profile;

import 'package:profile/screens/company/company_screen.dart'
    deferred as company_screen;
import 'package:profile/providers/public_profile_fetcher.dart'
    deferred as public_profile_fetcher;
import 'package:profile/providers/public_company_fetcher.dart'
    deferred as public_company_fetcher;
// import 'package:profile/widgets/promotion_package_ui/promotion_package_ui_widget.dart'
//     deferred as promotion_package_ui_widget;
import 'package:profile/screens/user_profile_default_screen.dart'
    deferred as profile;

// =====================================================================
// MAPA TRAS
// =====================================================================
final Map<Pattern, BeamRouteBuilder> profileRoutes = {
  
      Routes.singleSeller: (context, state, data) {
        final sellerId = int.parse(state.pathParameters['id']!);

        setupMetaTag(context);
        return BeamPage(
          key: const ValueKey(Routes.singleSeller),
          title: Routes.getWebsiteTitle(context),
          child: buildDeferredScreen(
            seller_profile.loadLibrary,
            () => seller_profile.SellerProfileScreen(sellerId: sellerId),
          ),
        );
      },




          Routes.company: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.company),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  company_screen.loadLibrary,
                  () => company_screen.CompanyScreen()),
            );
          },


          Routes.publicCompany: (context, state, data) {
            final companyId = state.pathParameters['id']!;
            
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.publicCompany),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                public_company_fetcher.loadLibrary,
                () => public_company_fetcher.PublicCompanyFetcher(companyId: companyId),
              ),
            );
          },

          Routes.publicProfile: (context, state, data) {
            final userId = state.pathParameters['id'];

            if (userId == null || userId.isEmpty || userId == 'offer') {
              return const BeamPage(
                key: ValueKey('public-profile-invalid'),
                child: Scaffold(
                  body: Center(child: Text('Invalid profile route')),
                ),
              );
            }
            
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.publicProfile),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                public_profile_fetcher.loadLibrary,
                () => public_profile_fetcher.PublicProfileFetcher(userId: userId),
              ),
            );
          },

          Routes.profile: (context, state, data) {

            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.profile),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  profile.loadLibrary,
                  () => profile.UserProfileDefaultScreen()),
            );
          },




};
