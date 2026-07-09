import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tms_app/todo/local/tms_pending_op.dart';

enum TmsSyncUiKind {
  synced,
  pending,
  syncing,
  failed,
  conflict,
}

class TmsSyncUiState {
  final TmsSyncUiKind kind;
  final int pendingCount;
  final int syncingCount;
  final int failedCount;
  final int conflictCount;
  final DateTime? lastSyncedAt;
  final String? message;

  const TmsSyncUiState({
    required this.kind,
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.lastSyncedAt,
    this.message,
  });

  TmsSyncUiState copyWith({
    TmsSyncUiKind? kind,
    int? pendingCount,
    int? syncingCount,
    int? failedCount,
    int? conflictCount,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? message,
    bool clearMessage = false,
  }) {
    return TmsSyncUiState(
      kind: kind ?? this.kind,
      pendingCount: pendingCount ?? this.pendingCount,
      syncingCount: syncingCount ?? this.syncingCount,
      failedCount: failedCount ?? this.failedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  String get label {
    switch (kind) {
      case TmsSyncUiKind.synced:
        return 'All changes synced';
      case TmsSyncUiKind.pending:
        return pendingCount <= 0
            ? 'Local changes pending'
            : '$pendingCount local change${pendingCount == 1 ? '' : 's'} pending';
      case TmsSyncUiKind.syncing:
        return syncingCount <= 0
            ? 'Syncing...'
            : 'Syncing $syncingCount change${syncingCount == 1 ? '' : 's'}...';
      case TmsSyncUiKind.failed:
        return failedCount <= 0
            ? 'Sync failed'
            : '$failedCount change${failedCount == 1 ? '' : 's'} waiting to retry';
      case TmsSyncUiKind.conflict:
        return conflictCount <= 0
            ? 'Conflict detected'
            : '$conflictCount conflict${conflictCount == 1 ? '' : 's'} need attention';
    }
  }
}

class TmsSyncUiNotifier extends StateNotifier<TmsSyncUiState> {
  TmsSyncUiNotifier()
      : super(const TmsSyncUiState(kind: TmsSyncUiKind.synced));

  void refreshFromOps(List<TmsPendingOp> ops) {
    final pendingCount = ops
        .where((e) => e.status == TmsPendingOpStatus.pending)
        .length;
    final syncingCount = ops
        .where((e) => e.status == TmsPendingOpStatus.syncing)
        .length;
    final failedCount = ops
        .where((e) => e.status == TmsPendingOpStatus.failed)
        .length;
    final conflictCount = ops
        .where((e) => e.status == TmsPendingOpStatus.conflict)
        .length;

    final kind = conflictCount > 0
        ? TmsSyncUiKind.conflict
        : syncingCount > 0
            ? TmsSyncUiKind.syncing
            : failedCount > 0
                ? TmsSyncUiKind.failed
                : pendingCount > 0
                    ? TmsSyncUiKind.pending
                    : TmsSyncUiKind.synced;

    state = state.copyWith(
      kind: kind,
      pendingCount: pendingCount,
      syncingCount: syncingCount,
      failedCount: failedCount,
      conflictCount: conflictCount,
      clearMessage: true,
    );
  }

  void markSyncedNow() {
    state = state.copyWith(
      kind: TmsSyncUiKind.synced,
      pendingCount: 0,
      syncingCount: 0,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: DateTime.now(),
      clearMessage: true,
    );
  }

  void setMessage(String message) {
    state = state.copyWith(message: message);
  }
}

final tmsSyncUiStateProvider =
    StateNotifierProvider<TmsSyncUiNotifier, TmsSyncUiState>((ref) {
  return TmsSyncUiNotifier();
});