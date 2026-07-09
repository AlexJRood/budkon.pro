// Sorting State
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tms_app/todo/board/enum/board_sort_type.dart';
import 'package:tms_app/todo/models/get_user_board_model.dart';

final boardSortNotifierProvider =
    StateNotifierProvider<BoardSortNotifier, BoardSortType>(
  (ref) => BoardSortNotifier(),
);

class BoardSortNotifier extends StateNotifier<BoardSortType> {
  BoardSortNotifier() : super(BoardSortType.createdDate);

  void setSort(BoardSortType sortType) => state = sortType;

  List<BoardResults> sortBoards(List<BoardResults>? boards) {
    if (boards == null) return [];

    final sorted = [...boards];

    switch (state) {
      case BoardSortType.createdDate:
        sorted.sort((a, b) {
          final dateA = _parseDateTime(a.timestamp);
          final dateB = _parseDateTime(b.timestamp);
          return dateB.compareTo(dateA);
        });
        break;
      case BoardSortType.aToZ:
        sorted.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
    }

    return sorted;
  }

  DateTime _parseDateTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return DateTime(0);
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return DateTime(0);
    }
  }
}
