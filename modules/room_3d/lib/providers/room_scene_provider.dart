/// Single source of truth for the active [RoomScene]. Per
/// docs/sims_mode/ARCHITECTURE.md section 6: the three.js viewer never holds
/// authoritative state — every mutation flows through
/// `actions/room_scene_actions.dart`, which updates this notifier AND sends
/// the matching JS bridge command. Undo/redo, persistence, and (Faza 3) Emma
/// only ever read/write this provider.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/room_scene.dart';

class RoomSceneState {
  final RoomScene? scene;
  final List<RoomScene> undoStack;
  final List<RoomScene> redoStack;

  /// Which `scene.floors` entry the viewer currently renders/edits. View
  /// state, not scene data — deliberately NOT part of undo/redo history
  /// (switching floors isn't a mutation), and reset whenever a new scene is
  /// loaded via [RoomSceneNotifier.loadScene].
  final int activeFloorIndex;

  /// "Sąsiednie piętra" toolbar toggle (FINAL_VISION.md §6's true floor
  /// stacking) — whether the floor below/above the active one render as
  /// dimmed 3D context. View state like `activeFloorIndex`, not scene data;
  /// resets to the default on a fresh `loadScene` for the same reason
  /// `activeFloorIndex` does.
  final bool showAdjacentFloors;

  const RoomSceneState({
    this.scene,
    this.undoStack = const [],
    this.redoStack = const [],
    this.activeFloorIndex = 0,
    this.showAdjacentFloors = true,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  /// The floor every panel/tool actually reads/edits — clamped defensively
  /// against `activeFloorIndex` ever drifting out of range (e.g. mid-render
  /// right after `removeFloor` shrank the list, before the clamp in
  /// `setActiveFloorIndex` below has run).
  RoomFloor? get activeFloor {
    final floors = scene?.floors;
    if (floors == null || floors.isEmpty) return null;
    return floors[activeFloorIndex.clamp(0, floors.length - 1)];
  }

  RoomSceneState copyWith({
    RoomScene? scene,
    List<RoomScene>? undoStack,
    List<RoomScene>? redoStack,
    int? activeFloorIndex,
    bool? showAdjacentFloors,
  }) {
    return RoomSceneState(
      scene: scene ?? this.scene,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      activeFloorIndex: activeFloorIndex ?? this.activeFloorIndex,
      showAdjacentFloors: showAdjacentFloors ?? this.showAdjacentFloors,
    );
  }
}

class RoomSceneNotifier extends StateNotifier<RoomSceneState> {
  RoomSceneNotifier() : super(const RoomSceneState());

  /// Loads a freshly-built scene (e.g. from `RoomSceneBuilder.fromFloorPlan`)
  /// and resets history — this is a structural change, not a mutation.
  void loadScene(RoomScene scene) {
    state = RoomSceneState(scene: scene);
  }

  /// Applies a mutation produced by [RoomSceneActions], pushing the previous
  /// scene onto the undo stack and clearing the redo stack (standard
  /// linear-history undo/redo, matching floor_plan's convention).
  void applyMutation(RoomScene Function(RoomScene current) mutate) {
    final current = state.scene;
    if (current == null) return;

    final next = mutate(current);

    state = state.copyWith(
      scene: next,
      undoStack: [...state.undoStack, current],
      redoStack: const [],
    );
  }

  void undo() {
    if (state.undoStack.isEmpty || state.scene == null) return;

    final previous = state.undoStack.last;
    final remainingUndo = state.undoStack.sublist(0, state.undoStack.length - 1);

    state = state.copyWith(
      scene: previous,
      undoStack: remainingUndo,
      redoStack: [...state.redoStack, state.scene!],
    );
  }

  void redo() {
    if (state.redoStack.isEmpty || state.scene == null) return;

    final next = state.redoStack.last;
    final remainingRedo = state.redoStack.sublist(0, state.redoStack.length - 1);

    state = state.copyWith(
      scene: next,
      undoStack: [...state.undoStack, state.scene!],
      redoStack: remainingRedo,
    );
  }

  /// Switches which floor is being viewed/edited. Clamped to the scene's
  /// current floor count rather than validated/thrown, since a stale index
  /// (e.g. after `removeFloor` shrank the list) is easy to end up with
  /// transiently and clamping is the harmless recovery.
  void setActiveFloorIndex(int index) {
    final floorCount = state.scene?.floors.length ?? 0;
    if (floorCount == 0) return;
    final clamped = index.clamp(0, floorCount - 1);
    state = state.copyWith(activeFloorIndex: clamped);
  }

  void setShowAdjacentFloors(bool value) {
    state = state.copyWith(showAdjacentFloors: value);
  }
}

final roomSceneProvider =
    StateNotifierProvider<RoomSceneNotifier, RoomSceneState>(
  (ref) => RoomSceneNotifier(),
);
