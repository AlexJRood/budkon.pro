/// Installs room_3d's 7 real Emma tool executors (`emma_tool_executors.dart`)
/// into `core`'s `localToolExecutorRegistryProvider` — the missing half of
/// FINAL_VISION.md's Faza 3 blocker (executors existed and were logically
/// correct, but nothing in `emma` ever called them). Spread into every
/// entrypoint's overrides next to `emmaSeamOverrides`, same pattern as
/// `emma_seam.dart` itself.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/kernel/kernel.dart';

import 'room_3d.dart';

final List<Override> room3dEmmaToolSeamOverrides = [
  localToolExecutorRegistryProvider.overrideWith(
    (ref) => buildRoomSceneToolExecutors(ref.read(roomSceneActionsProvider)),
  ),
];
