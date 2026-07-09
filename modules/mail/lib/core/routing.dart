import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import 'package:mail/mail.dart' deferred as mail hide ContextExtension;
import 'package:crm_agent/models/clients_model.dart';

final Map<Pattern, BeamRouteBuilder> mailRoutes = {
  Routes.leadEmailView: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);
    final lead = data is UserContactModel ? data : null;
    return BeamPage(
      key: const ValueKey(Routes.leadEmailView),
      title: Routes.getWebsiteTitle(context),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
      child: buildDeferredScreen(
        mail.loadLibrary,
        () => mail.EmailView(leadId: id, lead: lead),
      ),
    );
  },
  Routes.emailView: (context, state, data) => BeamPage(
        key: const ValueKey(Routes.emailView),
        title: Routes.getWebsiteTitle(context),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
        child: buildDeferredScreen(
          mail.loadLibrary,
          () => mail.EmailView(leadId: null),
        ),
      ),
};
