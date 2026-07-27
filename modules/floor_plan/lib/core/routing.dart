// =====================================================================
// lib/router_web/modules/floor_plan_routes.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';

import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:core/platform/route_constant.dart';

// =================== deferred imports ===================
import 'package:floor_plan/pages/floor_plan_builder_page.dart'
    deferred as floor_plan_builder;

import 'package:floor_plan/pages/floor_plan_projects_page.dart'
    deferred as floor_plan_projects;

// =====================================================================
// HELPERS
// =====================================================================
String? _routeStringArg(
  dynamic data,
  BeamState state,
  String key,
) {
  if (data is Map) {
    final value = data[key];

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  final queryValue = state.uri.queryParameters[key];

  if (queryValue != null && queryValue.trim().isNotEmpty) {
    return queryValue;
  }

  final pathValue = state.pathParameters[key];

  if (pathValue != null && pathValue.trim().isNotEmpty) {
    return pathValue;
  }

  return null;
}

// =====================================================================
// FLOOR PLAN ROUTES
// =====================================================================
final Map<Pattern, BeamRouteBuilder> floorPlanRoutes = {
  // ---------- Floor Plan Projects ----------
  Routes.floorPlanProjects: (context, state, data) {
    final targetObjectId = _routeStringArg(data, state, 'targetObjectId');
    final targetAppLabel = _routeStringArg(data, state, 'targetAppLabel');
    final targetModel = _routeStringArg(data, state, 'targetModel');
    final title =
        _routeStringArg(data, state, 'title') ?? 'Plany nieruchomości';

    return BeamPage(
      key: ValueKey(
        '${Routes.floorPlanProjects}_${targetObjectId ?? 'all'}',
      ),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        floor_plan_projects.loadLibrary,
        () => floor_plan_projects.FloorPlanProjectsPage(
          targetObjectId: targetObjectId,
          targetAppLabel: targetAppLabel,
          targetModel: targetModel,
          title: title,
        ),
      ),
    );
  },

  // ---------- Floor Plan Builder ----------
  Routes.floorPlanBuilder: (context, state, data) {
    final projectId = _routeStringArg(data, state, 'projectId');
    final targetObjectId = _routeStringArg(data, state, 'targetObjectId');
    final targetAppLabel = _routeStringArg(data, state, 'targetAppLabel');
    final targetModel = _routeStringArg(data, state, 'targetModel');
    final title =
        _routeStringArg(data, state, 'title') ?? 'Plan nieruchomości';

    return BeamPage(
      key: ValueKey(
        '${Routes.floorPlanBuilder}_${projectId ?? 'new'}',
      ),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        floor_plan_builder.loadLibrary,
        () => floor_plan_builder.FloorPlanBuilderCrmPage(
          projectId: projectId,
          targetObjectId: targetObjectId,
          targetAppLabel: targetAppLabel,
          targetModel: targetModel,
          title: title,
        ),
      ),
    );
  },
};