// tms_app/todo/provider/move_task_provider.dart


import 'dart:convert' as convert;
import 'package:tms_app/tms_app_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';

enum MoveScope { withinBoard, anotherBoard }

final moveScopeProvider = StateProvider.autoDispose<MoveScope>(
  (_) => MoveScope.withinBoard,
);

final withinBoardTargetProgressProvider = StateProvider.autoDispose<int?>(
  (ref) => ref.read(selectedProgressIdProvider),
);

final targetBoardProvider = StateProvider.autoDispose<SimpleBoard?>(
  (_) => null,
);

final otherBoardTargetProgressProvider = StateProvider.autoDispose<int?>(
  (_) => null,
);

final otherBoardDetailsProvider =
    FutureProvider.autoDispose<BoardDetailsModel?>((ref) async {
      final b = ref.watch(targetBoardProvider);
      if (b == null) return null;
      return ref
          .read(boardDetailsManagementProvider.notifier)
          .getBoardDetailsRaw(b.id.toString());
    });

final boardsListProvider = FutureProvider<List<SimpleBoard>>((ref) async {
  final resp = await ApiServices.get(TmsAppUrls.apiTask, ref: ref, hasToken: true);

  if (resp == null || resp.statusCode != 200) return const <SimpleBoard>[];

  dynamic body = resp.data;

  if (body is List<int>) body = convert.utf8.decode(body);
  if (body is String) body = convert.jsonDecode(body);

  if (body is List) {
    return body
        .whereType<Map<String, dynamic>>()
        .map(SimpleBoard.fromJson)
        .toList();
  }
  if (body is Map && body['results'] is List) {
    return (body['results'] as List)
        .whereType<Map<String, dynamic>>()
        .map(SimpleBoard.fromJson)
        .toList();
  }
  return const <SimpleBoard>[];
});

class SimpleBoard {
  final int id;
  final String name;
  const SimpleBoard({required this.id, required this.name});

  factory SimpleBoard.fromJson(Map<String, dynamic> j) =>
      SimpleBoard(id: j['id'] as int, name: (j['name'] ?? '').toString());
}
