import 'dart:typed_data';
import 'package:tms_app/tms_app_urls.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/local/tms_sync_service.dart';
import '../../models/get_user_board_model.dart';

final boardManagementProvider =
    StateNotifierProvider<BoardManagementNotifier, BoardModel>((ref) {
  return BoardManagementNotifier(ref);
});

class BoardManagementNotifier extends StateNotifier<BoardModel> {
  BoardManagementNotifier(this.ref) : super(boardModelDefault);

  final Ref ref;

  void updateBoard(BoardResults updatedBoard) {
    final updatedResults = state.results?.map((board) {
      if (board.id == updatedBoard.id) {
        return updatedBoard;
      }
      return board;
    }).toList();

    state = BoardModel(
      count: state.count,
      next: state.next,
      previous: state.previous,
      results: updatedResults,
    );
  }

  Future<void> fetchBoards([dynamic _]) async {
    try {
      final sync = ref.read(tmsSyncServiceProvider);
      await sync.init();

      final localBoards = sync.getLocalBoards();
      if (localBoards.isNotEmpty) {
        state = BoardModel(
          count: localBoards.length,
          next: null,
          previous: null,
          results: localBoards,
        );
      }

      final freshBoards = await sync.refreshBoards();
      state = BoardModel(
        count: freshBoards.length,
        next: null,
        previous: null,
        results: freshBoards,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error fetching boards: $e');
        debugPrint(st.toString());
      }
    }
  }

  Future<void> editBoard(
    String boardId,
    String boardName,
    Uint8List? avatarBytes,
  ) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry("name", boardName));

      if (avatarBytes != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(
              avatarBytes,
              filename: 'avatar.png',
              contentType: MediaType('image', 'png'),
            ),
          ),
        );
      }

      final response = await ApiServices.patch(
        TmsAppUrls.editBoard(boardId),
        data: formData,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final boards = [...?state.results];
        final index = boards.indexWhere((b) => b.id.toString() == boardId);

        if (index != -1) {
          final updatedAvatarUrl = response.data['avatar']?? boards[index].avatar;
          final updated = boards[index].copyWith(
            name: boardName,
            avatar: updatedAvatarUrl,
          );
          boards[index] = updated;
          state = BoardModel(
            count: state.count,
            next: state.next,
            previous: state.previous,
            results: boards,
          );
        }

        final freshBoards = await ref.read(tmsSyncServiceProvider).refreshBoards();

        state = BoardModel(
          count: freshBoards.length,
          next: null,
          previous: null,
          results: freshBoards,
        );
      } else {
        debugPrint('❌ Board update failed: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('🔥 Error updating board: $e');
    }
  }

  Future<void> deleteBoard(String boardId, WidgetRef widgetRef) async {
    try {
      final response = await ApiServices.delete(
        TmsAppUrls.editBoard(boardId),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        debugPrint('Board delete successfully');

        final updatedResults = [...?state.results]
          ..removeWhere((board) => board.id.toString() == boardId);

        state = BoardModel(
          count: updatedResults.length,
          next: state.next,
          previous: state.previous,
          results: updatedResults,
        );

        final selectedId = widgetRef.read(boardIdProvider);

        if (selectedId?.toString() == boardId) {
          widgetRef.read(boardIdProvider.notifier).state =
          updatedResults.isNotEmpty ? updatedResults.first.id : null;
        }

        await ref.read(tmsSyncServiceProvider).refreshBoards();
      } else {
        debugPrint('Board delete failed: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting board: $e');
    }
  }

  Future<bool> reorderProjects(List<int> projectIds) async {
    try {
      final response = await ApiServices.post(
        TmsAppUrls.reorderProjects,
        hasToken: true,
        data: {"project_ids": projectIds},
      );

      if (response == null) return false;

      if (response.statusCode == 200) {
        await ref.read(tmsSyncServiceProvider).refreshBoards();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ Exception while reordering: $e");
      return false;
    }
  }
}

final boardIdProvider = StateProvider<int?>((ref) => null);

final boardEditImageProvider = StateProvider<Uint8List?>((ref) => null);
final boardEditChangedProvider = StateProvider<bool>((ref) => false);
final boardsOrderProvider = StateProvider<List<BoardResults>>((ref) => []);
final boardEditLoadingProvider = StateProvider<bool>((ref) => false);