// =====================================================================
// lib/router_web/pages/crm_add_client_form_page.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';

import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

// DEFERRED
import 'package:crm_agent/add_client_form/add_client_form_page.dart'
    deferred as crm_add_client_form;

// zgodne z: typedef BeamRouteBuilder = dynamic Function(BuildContext, BeamState, Object?)
BeamPage crmAddClientForm(BuildContext context, BeamState state, Object? data) {
  String? pageState;
  if (data is Map && data['state'] is String) {
    pageState = data['state'] as String;
  }

  setupMetaTag(context);

  return BeamPage(
    key: ValueKey(state.uri.toString()),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      crm_add_client_form.loadLibrary,
      () => crm_add_client_form.AddClientFormScreen(state: pageState),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}
