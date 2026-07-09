import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:payments/settings/add_payment_screen.dart' deferred as add_payment_screen;

final Map<Pattern, BeamRouteBuilder> paymentsRoutes = {
  Routes.addCard: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.addCard),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          add_payment_screen.loadLibrary,
          () => add_payment_screen.AddcardScreen(isCard: true),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),
  Routes.addpayment: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.addpayment),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          add_payment_screen.loadLibrary,
          () => add_payment_screen.AddPaymentScreen(),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),
};
