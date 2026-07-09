class FreshnessCheckResult {
  final bool isActive;
  final double confidence;
  final String? reason;
  final String? checkedAt;

  const FreshnessCheckResult({
    required this.isActive,
    required this.confidence,
    this.reason,
    this.checkedAt,
  });

  factory FreshnessCheckResult.fromJson(Map<String, dynamic> json) {
    return FreshnessCheckResult(
      isActive: json['is_active'] as bool? ?? true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String?,
      checkedAt: json['checked_at'] as String?,
    );
  }

  /// True when we are at least 85 % sure the listing is gone.
  bool get isConfidentlyInactive => !isActive && confidence >= 0.85;

  @override
  String toString() =>
      'FreshnessCheckResult(isActive=$isActive, confidence=$confidence, reason=$reason)';
}
