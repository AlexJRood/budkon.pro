import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:notes/notes.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/kernel/kernel.dart';

final Map<Pattern, BeamRouteBuilder> notesRoutes = {
  Routes.notes: (context, state, data) {
    return BeamPage(
      key: const ValueKey(Routes.notes),
      title: Routes.getWebsiteTitle(context),
      child: const NotesScreen(),
    );
  },
};
