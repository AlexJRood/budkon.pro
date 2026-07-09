class CompensationNotificationEventOption {
  final String key;
  final String label;

  const CompensationNotificationEventOption({
    required this.key,
    required this.label,
  });

  factory CompensationNotificationEventOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompensationNotificationEventOption(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}




class CompensationNotificationPreferencesModel {
  final int? id;
  final int? company;
  final int? user;
  final bool enabled;
  final bool pushEnabled;
  final bool showAmounts;
  final Map<String, bool> events;
  final List<String> eventTypes;
  final List<CompensationNotificationEventOption> availableEvents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompensationNotificationPreferencesModel({
    this.id,
    this.company,
    this.user,
    required this.enabled,
    required this.pushEnabled,
    required this.showAmounts,
    required this.events,
    required this.eventTypes,
    required this.availableEvents,
    this.createdAt,
    this.updatedAt,
  });

  factory CompensationNotificationPreferencesModel.empty() {
    return const CompensationNotificationPreferencesModel(
      enabled: true,
      pushEnabled: true,
      showAmounts: true,
      events: {
        'agreement_available': true,
        'agreement_status_changed': true,
        'compensation_event_created': true,
        'settlement_published': true,
        'payment_received': true,
      },
      eventTypes: [],
      availableEvents: [
        CompensationNotificationEventOption(
          key: 'agreement_available',
          label: 'Agreement became available',
        ),
        CompensationNotificationEventOption(
          key: 'agreement_status_changed',
          label: 'Agreement status changed',
        ),
        CompensationNotificationEventOption(
          key: 'compensation_event_created',
          label: 'New compensation event',
        ),
        CompensationNotificationEventOption(
          key: 'settlement_published',
          label: 'Settlement published',
        ),
        CompensationNotificationEventOption(
          key: 'payment_received',
          label: 'Payment recorded',
        ),
      ],
    );
  }

  factory CompensationNotificationPreferencesModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final fallback = CompensationNotificationPreferencesModel.empty();
    final parsedEvents = <String, bool>{};

    final rawEvents = json['events'];
    if (rawEvents is Map) {
      rawEvents.forEach((key, value) {
        parsedEvents[key.toString()] = value == true;
      });
    }

    final parsedEventTypes = <String>[];
    final rawEventTypes = json['event_types'];
    if (rawEventTypes is List) {
      for (final value in rawEventTypes) {
        final normalized = value.toString().trim();
        if (normalized.isNotEmpty && !parsedEventTypes.contains(normalized)) {
          parsedEventTypes.add(normalized);
        }
      }
    }

    final parsedAvailableEvents = <CompensationNotificationEventOption>[];
    final rawAvailableEvents = json['available_events'];
    if (rawAvailableEvents is List) {
      for (final item in rawAvailableEvents) {
        if (item is Map) {
          parsedAvailableEvents.add(
            CompensationNotificationEventOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return CompensationNotificationPreferencesModel(
      id: _intOrNull(json['id']),
      company: _intOrNull(json['company']),
      user: _intOrNull(json['user']),
      enabled: json['enabled'] != false,
      pushEnabled: json['push_enabled'] != false,
      showAmounts: json['show_amounts'] != false,
      events: parsedEvents.isEmpty ? fallback.events : parsedEvents,
      eventTypes: parsedEventTypes,
      availableEvents: parsedAvailableEvents.isEmpty
          ? fallback.availableEvents
          : parsedAvailableEvents,
      createdAt: _dateOrNull(json['created_at']),
      updatedAt: _dateOrNull(json['updated_at']),
    );
  }

  CompensationNotificationPreferencesModel copyWith({
    int? id,
    int? company,
    int? user,
    bool? enabled,
    bool? pushEnabled,
    bool? showAmounts,
    Map<String, bool>? events,
    List<String>? eventTypes,
    List<CompensationNotificationEventOption>? availableEvents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompensationNotificationPreferencesModel(
      id: id ?? this.id,
      company: company ?? this.company,
      user: user ?? this.user,
      enabled: enabled ?? this.enabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      showAmounts: showAmounts ?? this.showAmounts,
      events: events ?? this.events,
      eventTypes: eventTypes ?? this.eventTypes,
      availableEvents: availableEvents ?? this.availableEvents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toPatchJson() {
    return {
      'enabled': enabled,
      'push_enabled': pushEnabled,
      'show_amounts': showAmounts,
      'events': events,
      'event_types': eventTypes,
    };
  }

  bool eventEnabled(String key) => events[key] ?? true;

  CompensationNotificationPreferencesModel toggleEvent(
    String key,
    bool value,
  ) {
    final updated = Map<String, bool>.from(events);
    updated[key] = value;
    return copyWith(events: updated);
  }

  CompensationNotificationPreferencesModel addEventType(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || eventTypes.contains(normalized)) return this;
    return copyWith(eventTypes: [...eventTypes, normalized]);
  }

  CompensationNotificationPreferencesModel removeEventType(String value) {
    return copyWith(
      eventTypes: eventTypes.where((item) => item != value).toList(),
    );
  }
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _dateOrNull(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
