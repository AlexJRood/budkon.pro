import 'dart:async';
import 'package:tms_app/tms_app_urls.dart';
import 'dart:convert' as convert;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/local/tms_sync_service.dart';
import 'package:tms_app/todo/provider/task_labels_provider.dart';
import 'package:tms_app/todo/provider/task_management_provider.dart';

import '../../models/tasks_model.dart';
import '../../models/board_details_model.dart';

enum BoardDetailsState { idle, loading, success, error }

final boardDetailsManagementProvider =
    StateNotifierProvider<BoardDetailsNotifier, BoardDetailsWrapper>((ref) {
  return BoardDetailsNotifier(ref);
});

final addTaskBoardDetailsProvider =
    StateNotifierProvider<BoardDetailsNotifier, BoardDetailsWrapper>((ref) {
  return BoardDetailsNotifier(ref);
});

class BoardDetailsWrapper {
  final BoardDetailsModel boardDetails;
  final BoardDetailsState state;

  BoardDetailsWrapper({
    required this.boardDetails,
    required this.state,
  });

  BoardDetailsWrapper copyWith({
    BoardDetailsModel? boardDetails,
    BoardDetailsState? state,
  }) {
    return BoardDetailsWrapper(
      boardDetails: boardDetails ?? this.boardDetails,
      state: state ?? this.state,
    );
  }
}

final BoardDetailsWrapper defaultBoardDetailsWrapper = BoardDetailsWrapper(
  boardDetails: boardDetailsModelDefault,
  state: BoardDetailsState.idle,
);

class BoardDetailsNotifier extends StateNotifier<BoardDetailsWrapper> {
  BoardDetailsNotifier(this.ref) : super(defaultBoardDetailsWrapper);

  final Ref ref;
  String? _inFlightProjectId;

  Future<void> fetchBoardDetails(String projectId) async {
    try {
      if (kDebugMode) {
        debugPrint('fetchBoardDetails called');
      }

      final id = int.tryParse(projectId.trim());
      if (id == null || id <= 0) {
        if (kDebugMode) {
          debugPrint(
            '⛔ fetchBoardDetails skipped: invalid projectId="$projectId"',
          );
        }
        return;
      }

      if (_inFlightProjectId == id.toString()) {
        if (kDebugMode) {
          debugPrint(
            '⏳ fetchBoardDetails skipped: already fetching projectId="$id"',
          );
        }
        return;
      }

      _inFlightProjectId = id.toString();
      state = state.copyWith(state: BoardDetailsState.loading);

      final sync = ref.read(tmsSyncServiceProvider);
      await sync.init();

      final local = sync.getLocalBoardDetails(id);
      if (local != null) {
        state = state.copyWith(
          boardDetails: local,
          state: BoardDetailsState.success,
        );

        ref.read(boardDetailsStateProvider.notifier).state = local;
        ref.read(tasksDetailsProvider.notifier).state = local.projectProgresses
            ?.map((projectProgress) => projectProgress.tasks)
            .toList();
        ref.read(taskManagementProvider.notifier).syncShowAddTaskStateWithBoard();

        unawaited(ref.read(taskLabelsProvider.notifier).fetchLabels());
      }

      final fresh = await sync.syncBoard(id);
      if (fresh != null) {
        state = state.copyWith(
          boardDetails: fresh,
          state: BoardDetailsState.success,
        );

        ref.read(boardDetailsStateProvider.notifier).state = fresh;
        ref.read(tasksDetailsProvider.notifier).state = fresh.projectProgresses
            ?.map((projectProgress) => projectProgress.tasks)
            .toList();
        ref.read(taskManagementProvider.notifier).syncShowAddTaskStateWithBoard();

        unawaited(ref.read(taskLabelsProvider.notifier).fetchLabels());

        if (kDebugMode) {
          debugPrint('Board details fetched successfully');
        }
      } else if (local == null) {
        state = state.copyWith(state: BoardDetailsState.error);
      }
    } catch (e) {
      state = state.copyWith(state: BoardDetailsState.error);
      if (kDebugMode) debugPrint('$e');
    } finally {
      _inFlightProjectId = null;
    }
  }

  void resetBoardDetails() {
    state = defaultBoardDetailsWrapper;
  }

  Future<BoardDetailsModel?> getBoardDetailsRaw(String projectId) async {
    try {
      final id = int.tryParse(projectId.trim());
      if (id == null || id <= 0) {
        if (kDebugMode) {
          debugPrint(
            '⛔ getBoardDetailsRaw skipped: invalid projectId="$projectId"',
          );
        }
        return null;
      }

      final local = ref.read(tmsSyncServiceProvider).getLocalBoardDetails(id);
      if (local != null) return local;

      final resp = await ApiServices.get(
        ref: ref,
        TmsAppUrls.projectDetails(id.toString()),
        hasToken: true,
      );

      if (resp != null && resp.statusCode == 200) {
        final decoded = convert.utf8.decode(resp.data);
        final map = convert.jsonDecode(decoded) as Map<String, dynamic>;
        return BoardDetailsModel.fromJson(map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('$e');
    }
    return null;
  }
}

final boardDetailsStateProvider = StateProvider<BoardDetailsModel>((ref) {
  return boardDetailsModelDefault;
});

final tasksDetailsProvider = StateProvider<List<List<Tasks>?>?>((ref) {
  return [[Tasks()]];
});