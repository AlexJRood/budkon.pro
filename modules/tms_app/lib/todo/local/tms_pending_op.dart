enum TmsPendingOpType {
  createTask,
  patchTask,
  moveTask,
  reorderTasks,
  deleteTask,
}

enum TmsPendingOpStatus {
  pending,
  syncing,
  failed,
  conflict,
}

class TmsPendingOp {
  final String opId;
  final TmsPendingOpType type;
  final int? entityId;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  final TmsPendingOpStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final int? baseVersion;
  final Map<String, dynamic>? serverSnapshot;

  const TmsPendingOp({
    required this.opId,
    required this.type,
    required this.createdAt,
    required this.payload,
    this.entityId,
    this.status = TmsPendingOpStatus.pending,
    this.retryCount = 0,
    this.lastError,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.baseVersion,
    this.serverSnapshot,
  });

  factory TmsPendingOp.fromJson(Map<String, dynamic> json) {
    return TmsPendingOp(
      opId: json['op_id']?.toString() ?? '',
      type: TmsPendingOpType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TmsPendingOpType.patchTask,
      ),
      entityId: json['entity_id'] is int
          ? json['entity_id'] as int
          : int.tryParse('${json['entity_id']}'),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'])
          : <String, dynamic>{},
      status: TmsPendingOpStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TmsPendingOpStatus.pending,
      ),
      retryCount: json['retry_count'] is int
          ? json['retry_count'] as int
          : int.tryParse('${json['retry_count']}') ?? 0,
      lastError: json['last_error']?.toString(),
      lastAttemptAt: json['last_attempt_at'] == null
          ? null
          : DateTime.tryParse('${json['last_attempt_at']}'),
      nextRetryAt: json['next_retry_at'] == null
          ? null
          : DateTime.tryParse('${json['next_retry_at']}'),
      baseVersion: json['base_version'] is int
          ? json['base_version'] as int
          : int.tryParse('${json['base_version']}'),
      serverSnapshot: json['server_snapshot'] is Map
          ? Map<String, dynamic>.from(json['server_snapshot'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'op_id': opId,
      'type': type.name,
      'entity_id': entityId,
      'created_at': createdAt.toIso8601String(),
      'payload': payload,
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'base_version': baseVersion,
      'server_snapshot': serverSnapshot,
    };
  }

  TmsPendingOp copyWith({
    String? opId,
    TmsPendingOpType? type,
    int? entityId,
    bool clearEntityId = false,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
    TmsPendingOpStatus? status,
    int? retryCount,
    String? lastError,
    bool clearLastError = false,
    DateTime? lastAttemptAt,
    bool clearLastAttemptAt = false,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    int? baseVersion,
    bool clearBaseVersion = false,
    Map<String, dynamic>? serverSnapshot,
    bool clearServerSnapshot = false,
  }) {
    return TmsPendingOp(
      opId: opId ?? this.opId,
      type: type ?? this.type,
      entityId: clearEntityId ? null : (entityId ?? this.entityId),
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      lastAttemptAt: clearLastAttemptAt
          ? null
          : (lastAttemptAt ?? this.lastAttemptAt),
      nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      baseVersion: clearBaseVersion ? null : (baseVersion ?? this.baseVersion),
      serverSnapshot: clearServerSnapshot
          ? null
          : (serverSnapshot ?? this.serverSnapshot),
    );
  }
}