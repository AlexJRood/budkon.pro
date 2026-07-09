// tms_app/todo/provider/copy_task_provider.dart

import 'dart:convert' as convert;
import 'package:tms_app/tms_app_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/provider/move_task_provider.dart';

enum CopyScope { withinBoard, anotherBoard }

final boardDetailsByIdProvider = FutureProvider.family<BoardDetailsModel?, int>(
  (ref, boardId) async {
    final resp = await ApiServices.get(
      TmsAppUrls.projectDetails(boardId.toString()),
      ref: ref,
      hasToken: true,
    );
    if (resp == null || resp.statusCode != 200) return null;

    dynamic body = resp.data;
    if (body is List<int>) body = convert.utf8.decode(body);
    if (body is String) body = convert.jsonDecode(body);

    if (body is Map<String, dynamic>) {
      return BoardDetailsModel.fromJson(body);
    }
    return null;
  },
);

final copyScopeProvider = StateProvider<CopyScope>(
  (_) => CopyScope.withinBoard,
);
final targetBoardProvider = StateProvider<SimpleBoard?>((_) => null);
final targetProgressIdProvider = StateProvider<int?>((_) => null);
