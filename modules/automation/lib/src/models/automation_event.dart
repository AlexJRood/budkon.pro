class AutomationEventLog {
  final String id;
  final String signalKey;
  final String status;
  final Map<String, dynamic> payload;
  final String errorMessage;
  final DateTime? createdAt;
  final DateTime? processedAt;

  const AutomationEventLog({
    required this.id,
    required this.signalKey,
    this.status = '',
    this.payload = const {},
    this.errorMessage = '',
    this.createdAt,
    this.processedAt,
  });

  factory AutomationEventLog.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key]?.toString();
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return AutomationEventLog(
      id: json['id']?.toString() ?? '',
      signalKey: json['signal_key']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      errorMessage: json['error_message']?.toString() ?? '',
      createdAt: parseDate('created_at'),
      processedAt: parseDate('processed_at'),
    );
  }
}
