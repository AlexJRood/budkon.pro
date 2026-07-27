import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';

import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:core/platform/route_constant.dart';

import 'package:room_3d/editor/room_3d_editor_page.dart' deferred as room_3d_editor;

String? _routeStringArg(dynamic data, BeamState state, String key) {
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

final Map<Pattern, BeamRouteBuilder> room3dRoutes = {
  Routes.room3dEditor: (context, state, data) {
    final projectId = _routeStringArg(data, state, 'projectId');
    final floorPlanProjectId = _routeStringArg(data, state, 'floorPlanProjectId');

    return BeamPage(
      key: ValueKey(
        '${Routes.room3dEditor}_${projectId ?? floorPlanProjectId ?? 'new'}',
      ),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        room_3d_editor.loadLibrary,
        () => room_3d_editor.Room3dEditorPage(
          projectId: projectId,
          floorPlanProjectId: floorPlanProjectId,
        ),
      ),
    );
  },
};
