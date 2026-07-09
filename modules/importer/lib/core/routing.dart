// =====================================================================
// lib/router_web/modules/crm_add_client_form_routes.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import 'package:importer/importer.dart' deferred as data_importer;



final Map<Pattern, BeamRouteBuilder> dataImporterRoutes = {

  Routes.dataImporter: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.dataImporter),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        data_importer.loadLibrary,
        () => data_importer.ImportDataPage(),
      ),
    );
  }
};