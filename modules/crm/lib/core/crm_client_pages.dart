// =====================================================================
// lib/router_web/pages/crm_client_pages.dart
// (extracted builders from bottom of original file) — DEFERRED VERSION
// =====================================================================
import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:crm_agent/models/clients_model.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart'; // transparentRouteBuilder + buildDeferredScreen

// ===== deferred imports (cięższe UI) =====
import 'package:crm/data/clients/single_clients_provider.dart'
    deferred as client_fetcher; // -> ClientsFetcher
import 'package:crm/data/clients/statuses_clients/contact_status_list.dart'
    deferred as client_status;  // -> UserContactStatusPopUp
import 'package:crm/data/clients/statuses_clients/contact_type.dart'
    deferred as client_type;    // -> UserContactTypesPopUp
import 'package:crm/crm/clients/clients_view_page.dart'
    deferred as clients_view;   // -> ClientsViewPop

// typedef BeamRouteBuilder = dynamic Function(BuildContext, BeamState, Object?);

BeamPage clientViewPage(BuildContext context, BeamState state, Object? data) {
  final clientIdStr = state.pathParameters['clientId'] ?? '';
  final clientId = int.tryParse(clientIdStr) ?? -1;

  final activeSectionFetch = state.pathParameters['activeSection'] ?? 'dashboard';
  final activeAdFetch = state.pathParameters['activeAd'] ?? 'dashboard';
final pageKey = ValueKey('${Routes.proSingleClient}-$clientId'); 
  if (data == null) {
    return BeamPage(
        key: pageKey,
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        client_fetcher.loadLibrary,
        () => client_fetcher.ClientsFetcher(
          clientId: clientId,
          tagClientViewPop: '',
          activeSection: activeSectionFetch,
          activeAd: activeAdFetch,
        ),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  final map = (data is Map) ? data as Map : const {};
  final activeSection = (map['activeSection'] as String?) ?? activeSectionFetch;
  final activeAd = (map['activeAd'] as String?) ?? activeAdFetch;
  final tagClientViewPop = (map['tagClientViewPop'] as String?) ?? '';
  final contactType = (map['contactType'] as ContactType?) ?? ContactType.client;


  if (tagClientViewPop.isEmpty) {
    return BeamPage(
        key: pageKey,
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        client_fetcher.loadLibrary,
        () => client_fetcher.ClientsFetcher(
          clientId: clientId,
          tagClientViewPop: '',
          activeSection: activeSectionFetch,
          activeAd: activeAdFetch,
          contactType: contactType,
        ),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  } else {
    final clientViewPop = map['clientViewPop'] as UserContactModel;
    return BeamPage(
       key: pageKey,
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        clients_view.loadLibrary,
        () => clients_view.ClientsViewPop(
          clientViewPop: clientViewPop,
          tagClientViewPop: tagClientViewPop,
          activeSection: activeSection,
          activeAd: activeAd,
          contactType: contactType,
        ),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }
}

BeamPage clientStatusPop(BuildContext context, BeamState state, Object? data) {
  final map = (data is Map) ? data as Map : const {};
  final contact = map['contact'] as UserContactModel?;
  final isFilter = (map['isFilter'] as bool?) ?? false;

  return BeamPage(
    key: const ValueKey(Routes.statusPopExpenses),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      client_status.loadLibrary,
      () => client_status.UserContactStatusPopUp(contact: contact, isFilter: isFilter),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}

BeamPage clientTypesPop(BuildContext context, BeamState state, Object? data) {
  final map = (data is Map) ? data as Map : const {};
  final contact = map['contact'] as UserContactModel?;
  final isFilter = (map['isFilter'] as bool?) ?? false;

  return BeamPage(
    key: const ValueKey(Routes.contactTypeContacts),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      client_type.loadLibrary,
      () => client_type.UserContactTypesPopUp(contact: contact, isFilter: isFilter),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}
