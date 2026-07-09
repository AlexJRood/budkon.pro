// =====================================================================
// lib/router_web/modules/crm_add_client_form_routes.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import 'package:crm/invoices/screen/template_generator.dart' deferred as invoice_generator;
import 'package:crm/invoices/screen/list.dart' deferred as invoice_template_list;
import 'package:crm/invoices/screen/items.dart' deferred as invoice_items;



final Map<Pattern, BeamRouteBuilder> invoiceGeneratorRoutes = {


  Routes.invoiceItems: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.invoiceItems),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        invoice_items.loadLibrary,
        () => invoice_items.InvoiceItemPresetsScreen(),
      ),
    );
  }, 

  
  Routes.invoiceTemplateList: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.invoiceTemplateList),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        invoice_template_list.loadLibrary,
        () => invoice_template_list.InvoiceTemplateListScreen(),
      ),
    );
  }, 

  
  Routes.invoiceGenerator: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.invoiceGenerator),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        invoice_generator.loadLibrary,
        () => invoice_generator.InvoiceTemplateGeneratorScreen(),
      ),
    );
  }
};