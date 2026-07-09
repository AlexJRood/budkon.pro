import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/provider/urls_tms.dart';

enum MemberTmsTaskScope {
  assigned,
  involved,
  created,
}

extension MemberTmsTaskScopeX on MemberTmsTaskScope {
  String get apiValue => name;

  String get label {
    switch (this) {
      case MemberTmsTaskScope.assigned:
        return 'Przypisane';
      case MemberTmsTaskScope.involved:
        return 'Powiązane';
      case MemberTmsTaskScope.created:
        return 'Utworzone';
    }
  }
}

class MemberTmsBoardSummary {
  final int id;
  final String name;
  final String? description;
  final String? avatar;
  final int taskCount;
  final int openTaskCount;
  final int overdueTaskCount;
  final DateTime? updatedAt;

  const MemberTmsBoardSummary({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    this.taskCount = 0,
    this.openTaskCount = 0,
    this.overdueTaskCount = 0,
    this.updatedAt,
  });

  factory MemberTmsBoardSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MemberTmsBoardSummary(
      id: asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      avatar: json['avatar']?.toString(),
      taskCount: asInt(json['task_count']),
      openTaskCount: asInt(json['open_task_count']),
      overdueTaskCount: asInt(json['overdue_task_count']),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')
          ?.toLocal(),
    );
  }
}

class MemberTmsState {
  final List<MemberTmsBoardSummary> boards;
  final int? selectedBoardId;
  final BoardDetailsModel? boardDetails;
  final MemberTmsTaskScope scope;
  final bool isLoadingBoards;
  final bool isLoadingBoard;
  final bool forbidden;
  final String? error;

  const MemberTmsState({
    this.boards = const [],
    this.selectedBoardId,
    this.boardDetails,
    this.scope = MemberTmsTaskScope.assigned,
    this.isLoadingBoards = false,
    this.isLoadingBoard = false,
    this.forbidden = false,
    this.error,
  });

  MemberTmsState copyWith({
    List<MemberTmsBoardSummary>? boards,
    int? selectedBoardId,
    bool clearSelectedBoardId = false,
    BoardDetailsModel? boardDetails,
    bool clearBoardDetails = false,
    MemberTmsTaskScope? scope,
    bool? isLoadingBoards,
    bool? isLoadingBoard,
    bool? forbidden,
    String? error,
    bool clearError = false,
  }) {
    return MemberTmsState(
      boards: boards ?? this.boards,
      selectedBoardId: clearSelectedBoardId
          ? null
          : (selectedBoardId ?? this.selectedBoardId),
      boardDetails:
          clearBoardDetails ? null : (boardDetails ?? this.boardDetails),
      scope: scope ?? this.scope,
      isLoadingBoards: isLoadingBoards ?? this.isLoadingBoards,
      isLoadingBoard: isLoadingBoard ?? this.isLoadingBoard,
      forbidden: forbidden ?? this.forbidden,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final memberTmsProvider = StateNotifierProvider.autoDispose
    .family<MemberTmsNotifier, MemberTmsState, int>(
  (ref, memberId) => MemberTmsNotifier(ref, memberId),
);

class MemberTmsNotifier extends StateNotifier<MemberTmsState> {
  MemberTmsNotifier(this.ref, this.memberId)
      : super(const MemberTmsState()) {
    Future.microtask(loadBoards);
  }

  final Ref ref;
  final int memberId;
  bool _disposed = false;
  bool _loadingBoards = false;
  int _boardRequestVersion = 0;

  String get _boardsUrl => TmsURLs.memberBoards(memberId);

  String _boardDetailsUrl(int projectId) =>
      TmsURLs.memberBoardDetails(memberId, projectId);

  dynamic _decode(dynamic raw) {
    if (raw is Uint8List) return jsonDecode(utf8.decode(raw));
    if (raw is List<int>) return jsonDecode(utf8.decode(raw));
    if (raw is String) return jsonDecode(raw);
    return raw;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadBoards({bool keepSelection = true}) async {
    if (_disposed || _loadingBoards || memberId <= 0) return;

    _loadingBoards = true;
    state = state.copyWith(
      isLoadingBoards: true,
      forbidden: false,
      clearError: true,
    );

    try {
      final response = await ApiServices.get(
        _boardsUrl,
        ref: ref,
        hasToken: true,
        queryParameters: {
          'task_scope': state.scope.apiValue,
          'ordering': '-updated_at',
        },
      );

      if (_disposed) return;

      if (response?.statusCode == 403) {
        state = state.copyWith(
          isLoadingBoards: false,
          forbidden: true,
          error: 'Nie masz dostępu do zadań tego pracownika.',
          boards: const [],
          clearSelectedBoardId: true,
          clearBoardDetails: true,
        );
        return;
      }

      if (response == null || response.statusCode != 200) {
        throw StateError(
          'Failed to load member boards: ${response?.statusCode}',
        );
      }

      final decoded = _decode(response.data);
      if (decoded is! Map) {
        throw const FormatException('Invalid member boards response.');
      }

      final map = Map<String, dynamic>.from(decoded);
      final rawResults = map['results'] is List
          ? map['results'] as List
          : const <dynamic>[];

      final boards = rawResults
          .whereType<Map>()
          .map((e) => MemberTmsBoardSummary.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .where((e) => e.id > 0)
          .toList();

      final previousId = keepSelection ? state.selectedBoardId : null;
      final selectedId = previousId != null &&
              boards.any((board) => board.id == previousId)
          ? previousId
          : (boards.isNotEmpty ? boards.first.id : null);

      state = state.copyWith(
        boards: boards,
        selectedBoardId: selectedId,
        clearSelectedBoardId: selectedId == null,
        clearBoardDetails: selectedId == null,
        isLoadingBoards: false,
        forbidden: false,
        clearError: true,
      );

      if (selectedId != null) {
        await selectBoard(selectedId, force: true);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MemberTmsNotifier.loadBoards error: $e');
        debugPrintStack(stackTrace: st);
      }
      if (!_disposed) {
        state = state.copyWith(
          isLoadingBoards: false,
          error: e.toString(),
        );
      }
    } finally {
      _loadingBoards = false;
    }
  }

  Future<void> selectBoard(int boardId, {bool force = false}) async {
    if (_disposed || boardId <= 0) return;

    if (!force &&
        state.selectedBoardId == boardId &&
        state.boardDetails?.id == boardId) {
      return;
    }

    final requestVersion = ++_boardRequestVersion;
    state = state.copyWith(
      selectedBoardId: boardId,
      isLoadingBoard: true,
      clearError: true,
    );

    try {
      final response = await ApiServices.get(
        _boardDetailsUrl(boardId),
        ref: ref,
        hasToken: true,
        queryParameters: {
          'task_scope': state.scope.apiValue,
        },
      );

      if (_disposed || requestVersion != _boardRequestVersion) return;

      if (response?.statusCode == 403) {
        state = state.copyWith(
          isLoadingBoard: false,
          forbidden: true,
          error: 'Nie masz dostępu do tej tablicy.',
          clearBoardDetails: true,
        );
        return;
      }

      if (response == null || response.statusCode != 200) {
        throw StateError(
          'Failed to load member board: ${response?.statusCode}',
        );
      }

      final decoded = _decode(response.data);
      if (decoded is! Map) {
        throw const FormatException('Invalid member board response.');
      }

      final board = BoardDetailsModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      state = state.copyWith(
        selectedBoardId: boardId,
        boardDetails: board,
        isLoadingBoard: false,
        forbidden: false,
        clearError: true,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MemberTmsNotifier.selectBoard error: $e');
        debugPrintStack(stackTrace: st);
      }
      if (!_disposed && requestVersion == _boardRequestVersion) {
        state = state.copyWith(
          isLoadingBoard: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> setScope(MemberTmsTaskScope scope) async {
    if (_disposed || state.scope == scope) return;

    state = state.copyWith(
      scope: scope,
      clearBoardDetails: true,
      clearError: true,
    );
    await loadBoards(keepSelection: true);
  }

  Future<void> refresh() async {
    await loadBoards(keepSelection: true);
  }
}
