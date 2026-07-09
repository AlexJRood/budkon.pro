import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/kernel/kernel.dart';

import 'package:tms_app/todo/board/provider/board_provider.dart';

/// Registration surface for the tms_app (todo/boards) module. Currently only
/// clears its board state on logout via the session-reset seam.
class TmsAppModule extends AppModule {
  @override
  String get id => 'tms_app';

  @override
  void resetSession(WidgetRef ref) {
    ref.invalidate(boardManagementProvider);
  }
}
