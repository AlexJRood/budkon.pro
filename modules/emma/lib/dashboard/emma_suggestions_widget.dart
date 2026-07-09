import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/user/user/user_provider.dart';

import 'package:emma/provider/urls.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _PendingEvent {
  final int id;
  final String title;
  final String? startTime;
  final String? location;
  final String? summary;
  final int? emailId;
  final int? viewerId;

  const _PendingEvent({
    required this.id,
    required this.title,
    this.startTime,
    this.location,
    this.summary,
    this.emailId,
    this.viewerId,
  });

  factory _PendingEvent.fromJson(Map<String, dynamic> j) => _PendingEvent(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '').toString(),
        startTime: j['start_time']?.toString(),
        location: j['location']?.toString(),
        summary: j['emma_summary']?.toString(),
        emailId: j['emma_email_id'] is num
            ? (j['emma_email_id'] as num).toInt()
            : null,
        viewerId: j['viewer'] is num
            ? (j['viewer'] as num).toInt()
            : (j['assigned_to'] is num
                ? (j['assigned_to'] as num).toInt()
                : null),
      );
}

class _PendingTask {
  final int id;
  final String name;
  final String? description;
  final String? deadline;
  final String? summary;
  final int? emailId;
  final int? assignedToId;

  const _PendingTask({
    required this.id,
    required this.name,
    this.description,
    this.deadline,
    this.summary,
    this.emailId,
    this.assignedToId,
  });

  factory _PendingTask.fromJson(Map<String, dynamic> j) => _PendingTask(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        deadline: j['deadline']?.toString(),
        summary: j['emma_summary']?.toString(),
        emailId: j['emma_email_id'] is num
            ? (j['emma_email_id'] as num).toInt()
            : null,
        assignedToId: j['assigned_to'] is num
            ? (j['assigned_to'] as num).toInt()
            : (j['viewer'] is num ? (j['viewer'] as num).toInt() : null),
      );
}

class _ListingMatch {
  final int id;
  final String title;
  final String address;
  final bool isActive;
  final String? price;
  final String currency;
  final String? estateType;
  final String? squareFootage;
  final int? rooms;
  final int? floor;
  final int? totalFloors;
  final double confidence;

  const _ListingMatch({
    required this.id,
    required this.title,
    required this.address,
    required this.isActive,
    this.price,
    required this.currency,
    this.estateType,
    this.squareFootage,
    this.rooms,
    this.floor,
    this.totalFloors,
    required this.confidence,
  });

  factory _ListingMatch.fromJson(Map<String, dynamic> j) => _ListingMatch(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        isActive: (j['is_active'] as bool?) ?? true,
        price: j['price']?.toString(),
        currency: (j['currency'] ?? 'PLN').toString(),
        estateType: j['estate_type']?.toString(),
        squareFootage: j['square_footage']?.toString(),
        rooms: j['rooms'] is num ? (j['rooms'] as num).toInt() : null,
        floor: j['floor'] is num ? (j['floor'] as num).toInt() : null,
        totalFloors: j['total_floors'] is num ? (j['total_floors'] as num).toInt() : null,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
      );

  String get displayAddress =>
      address.isNotEmpty ? address : title;

  String get detailLine {
    final parts = <String>[];
    if (squareFootage != null) parts.add('$squareFootage m²');
    if (rooms != null) parts.add('$rooms pok.');
    if (floor != null && totalFloors != null) parts.add('p. $floor/$totalFloors');
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// Generic email suggestion model (all types except listing_inquiry)
// ---------------------------------------------------------------------------

class _SlotSuggestion {
  final String start;
  final String end;
  final String label;
  final String reason;

  const _SlotSuggestion({
    required this.start,
    required this.end,
    required this.label,
    required this.reason,
  });

  factory _SlotSuggestion.fromJson(Map<String, dynamic> j) => _SlotSuggestion(
        start:  (j['start']  ?? '').toString(),
        end:    (j['end']    ?? '').toString(),
        label:  (j['label']  ?? '').toString(),
        reason: (j['reason'] ?? '').toString(),
      );
}

class _EmailSuggestion {
  final int id;
  final String suggestionType;
  final String status;
  final String senderName;
  final String senderEmail;
  final String subject;
  final Map<String, dynamic> payload;
  final String replyDraft;
  final int? emailMessageId;
  final bool needsRedaction;
  final List<String> detectedSensitiveLabels;
  final String maskedText;

  const _EmailSuggestion({
    required this.id,
    required this.suggestionType,
    required this.status,
    required this.senderName,
    required this.senderEmail,
    required this.subject,
    required this.payload,
    required this.replyDraft,
    this.emailMessageId,
    this.needsRedaction = false,
    this.detectedSensitiveLabels = const [],
    this.maskedText = '',
  });

  factory _EmailSuggestion.fromJson(Map<String, dynamic> j) => _EmailSuggestion(
        id:             (j['id'] as num).toInt(),
        suggestionType: (j['suggestion_type'] ?? '').toString(),
        status:         (j['status']          ?? 'pending').toString(),
        senderName:     (j['sender_name']     ?? '').toString(),
        senderEmail:    (j['sender_email']    ?? '').toString(),
        subject:        (j['subject']         ?? '').toString(),
        payload:        Map<String, dynamic>.from((j['payload'] as Map?) ?? {}),
        replyDraft:     (j['reply_draft']     ?? '').toString(),
        emailMessageId: j['email_message_id'] is num
            ? (j['email_message_id'] as num).toInt()
            : null,
        needsRedaction: (j['needs_redaction'] as bool?) ?? false,
        detectedSensitiveLabels: (j['detected_sensitive_labels'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        maskedText: (j['masked_text'] ?? '').toString(),
      );

  List<_SlotSuggestion> get suggestedSlots {
    final raw = (payload['suggested_slots'] as List?) ?? [];
    return raw.whereType<Map>()
        .map((s) => _SlotSuggestion.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  List<_ListingMatch> get listings {
    final raw = (payload['listings'] as List?) ?? [];
    return raw.whereType<Map>()
        .map((m) => _ListingMatch.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

class _PendingInquiry {
  final int id;
  final String senderName;
  final String senderEmail;
  final String subject;
  final String extractedAddress;
  final List<_ListingMatch> matches;
  final String replyDraft;
  final int? emailMessageId;

  const _PendingInquiry({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.subject,
    required this.extractedAddress,
    required this.matches,
    required this.replyDraft,
    this.emailMessageId,
  });

  factory _PendingInquiry.fromJson(Map<String, dynamic> j) {
    final rawMatches = (j['matches'] as List?) ?? [];
    return _PendingInquiry(
      id: (j['id'] as num).toInt(),
      senderName: (j['sender_name'] ?? '').toString(),
      senderEmail: (j['sender_email'] ?? '').toString(),
      subject: (j['subject'] ?? '').toString(),
      extractedAddress: (j['extracted_address'] ?? '').toString(),
      matches: rawMatches
          .whereType<Map>()
          .map((m) => _ListingMatch.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      replyDraft: (j['reply_draft'] ?? '').toString(),
      emailMessageId: j['email_message_id'] is num
          ? (j['email_message_id'] as num).toInt()
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _emmaPendingProvider = FutureProvider.autoDispose<
    ({
      List<_PendingEvent> events,
      List<_PendingTask> tasks,
      List<_PendingInquiry> inquiries,
      List<_EmailSuggestion> suggestions,
    })>(
  (ref) async {
    final resp = await ApiServices.get(
      URLsEmma.emmaProactivePending,
      hasToken: true,
      ref: ref,
    );
    if (resp == null) {
      return (
        events: <_PendingEvent>[],
        tasks: <_PendingTask>[],
        inquiries: <_PendingInquiry>[],
        suggestions: <_EmailSuggestion>[],
      );
    }

    Map<String, dynamic> body;
    if (resp.data is String) {
      try {
        body = Map<String, dynamic>.from(
          (jsonDecode(resp.data as String) as Map?) ?? {},
        );
      } catch (_) {
        body = {};
      }
    } else if (resp.data is Map) {
      body = Map<String, dynamic>.from(resp.data as Map);
    } else {
      body = {};
    }

    final rawEvents      = (body['events']      as List?) ?? [];
    final rawTasks       = (body['tasks']       as List?) ?? [];
    final rawInquiries   = (body['inquiries']   as List?) ?? [];
    final rawSuggestions = (body['suggestions'] as List?) ?? [];

    return (
      events: rawEvents
          .whereType<Map>()
          .map((e) => _PendingEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      tasks: rawTasks
          .whereType<Map>()
          .map((t) => _PendingTask.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
      inquiries: rawInquiries
          .whereType<Map>()
          .map((i) => _PendingInquiry.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      suggestions: rawSuggestions
          .whereType<Map>()
          .map((s) => _EmailSuggestion.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  },
);

// Today's availability color per user ID – from the employee management dashboard.
final _teamAvailabilityProvider =
    FutureProvider.autoDispose<Map<int, Color>>((ref) async {
  const url =
      'https://www.superbee.cloud/finance/compensation/employee-management-dashboard/';
  try {
    final resp = await ApiServices.get(url, hasToken: true, ref: ref);
    if (resp == null) return {};

    Map<String, dynamic> body;
    if (resp.data is String) {
      try {
        body = Map<String, dynamic>.from(
          (jsonDecode(resp.data as String) as Map?) ?? {},
        );
      } catch (_) {
        return {};
      }
    } else if (resp.data is Map) {
      body = Map<String, dynamic>.from(resp.data as Map);
    } else {
      return {};
    }

    final result = <int, Color>{};
    final employees = (body['employees'] as List?) ?? [];
    for (final emp in employees) {
      if (emp is! Map) continue;
      final userJson = emp['user'];
      if (userJson is! Map) continue;
      final userId = (userJson['id'] as num?)?.toInt();
      if (userId == null) continue;
      final summary = emp['availability_summary'];
      if (summary is! Map) continue;
      final hex = summary['today_status_color']?.toString() ?? '#64748B';
      result[userId] = _hexColor(hex);
    }
    return result;
  } catch (_) {
    return {};
  }
});

Color _hexColor(String value) {
  var hex = value.trim();
  if (!hex.startsWith('#')) hex = '#$hex';
  if (hex.length == 4) {
    hex = '#${hex[1]}${hex[1]}${hex[2]}${hex[2]}${hex[3]}${hex[3]}';
  }
  try {
    if (hex.length == 7) return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    if (hex.length == 9) return Color(int.parse(hex.replaceFirst('#', '0x')));
  } catch (_) {}
  return const Color(0xFF64748B);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class EmmaSuggestionsDashboardWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool isEditMode;

  const EmmaSuggestionsDashboardWidget({
    super.key,
    required this.isMobile,
    this.isEditMode = false,
  });

  @override
  ConsumerState<EmmaSuggestionsDashboardWidget> createState() =>
      _EmmaSuggestionsDashboardWidgetState();
}

class _EmmaSuggestionsDashboardWidgetState
    extends ConsumerState<EmmaSuggestionsDashboardWidget> {
  static const _emmaAccent = Color(0xFF37B6FF);
  static const _inquiryAccent = Color(0xFFFF9800);

  final Map<String, bool> _accepting = {};
  final Map<String, bool> _rejecting = {};
  final Set<String> _dismissed = {};

  // Selected listing per inquiry (for disambiguation)
  final Map<int, int> _selectedListingId = {};
  // Expanded draft view per inquiry or suggestion
  final Set<int> _draftExpanded = {};
  // Selected slot per suggestion (viewing_request)
  final Map<int, int> _selectedSlotIndex = {};
  // Accepting/rejecting per suggestion
  String _suggestionKey(int id) => 'suggestion_$id';

  // null = show all members
  int? _selectedMemberId;

  String _eventKey(int id) => 'event_$id';
  String _taskKey(int id) => 'task_$id';
  String _inquiryKey(int id) => 'inquiry_$id';

  Future<void> _acceptEvent(_PendingEvent e) async {
    final key = _eventKey(e.id);
    setState(() => _accepting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'suggestion_event',
          'data': {'event_id': e.id},
          'mode': 'confirm',
        },
        hasToken: true,
        ref: ref,
      );
      setState(() => _dismissed.add(key));
    } catch (_) {
    } finally {
      setState(() => _accepting.remove(key));
    }
  }

  Future<void> _rejectEvent(_PendingEvent e) async {
    final key = _eventKey(e.id);
    setState(() => _rejecting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveDismiss,
        data: {'type': 'suggestion_event', 'event_id': e.id},
        hasToken: true,
        ref: ref,
      );
      setState(() => _dismissed.add(key));
    } catch (_) {
    } finally {
      setState(() => _rejecting.remove(key));
    }
  }

  Future<void> _acceptTask(_PendingTask t) async {
    final key = _taskKey(t.id);
    setState(() => _accepting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'suggestion_task',
          'data': {'task_id': t.id},
          'mode': 'confirm',
        },
        hasToken: true,
        ref: ref,
      );
      setState(() => _dismissed.add(key));
    } catch (_) {
    } finally {
      setState(() => _accepting.remove(key));
    }
  }

  Future<void> _rejectTask(_PendingTask t) async {
    final key = _taskKey(t.id);
    setState(() => _rejecting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveDismiss,
        data: {'type': 'suggestion_task', 'task_id': t.id},
        hasToken: true,
        ref: ref,
      );
      setState(() => _dismissed.add(key));
    } catch (_) {
    } finally {
      setState(() => _rejecting.remove(key));
    }
  }

  Future<void> _replyInquiry(_PendingInquiry inq) async {
    final key = _inquiryKey(inq.id);
    setState(() => _accepting[key] = true);
    try {
      final listingId = _selectedListingId[inq.id] ??
          (inq.matches.isNotEmpty ? inq.matches.first.id : null);
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'listing_inquiry',
          'data': {
            'inquiry_id': inq.id,
            if (listingId != null) 'listing_id': listingId,
          },
          'mode': 'draft',
        },
        hasToken: true,
        ref: ref,
      );
      setState(() => _draftExpanded.add(inq.id));
    } catch (_) {
    } finally {
      setState(() => _accepting.remove(key));
    }
  }

  Future<void> _dismissInquiry(_PendingInquiry inq) async {
    final key = _inquiryKey(inq.id);
    setState(() => _rejecting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveDismiss,
        data: {'type': 'listing_inquiry', 'inquiry_id': inq.id},
        hasToken: true,
        ref: ref,
      );
      setState(() => _dismissed.add(key));
    } catch (_) {
    } finally {
      setState(() => _rejecting.remove(key));
    }
  }

  Future<void> _acceptSuggestion(_EmailSuggestion s, String mode, {Map<String, dynamic> extra = const {}}) async {
    final key = _suggestionKey(s.id);
    setState(() => _accepting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'email_suggestion',
          'data': {'suggestion_id': s.id, ...extra},
          'mode': mode,
        },
        hasToken: true,
        ref: ref,
      );
      if (mode == 'draft') {
        setState(() => _draftExpanded.add(s.id));
      } else {
        setState(() => _dismissed.add(key));
      }
    } catch (_) {
    } finally {
      setState(() => _accepting.remove(key));
    }
  }

  Future<void> _confirmRedaction(_EmailSuggestion s) async {
    final key = _suggestionKey(s.id);
    setState(() => _accepting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaConfirmRedaction,
        data: {'suggestion_id': s.id},
        hasToken: true,
        ref: ref,
      );
      // Refresh the list so the suggestion transitions to pending
      ref.invalidate(_emmaPendingProvider);
    } catch (_) {
    } finally {
      setState(() => _accepting.remove(key));
    }
  }

  Future<void> _dismissSuggestion(_EmailSuggestion s) async {
    final key = _suggestionKey(s.id);
    setState(() => _rejecting[key] = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveDismiss,
        data: {'type': 'email_suggestion', 'suggestion_id': s.id},
        hasToken: true,
        ref: ref,
      );
      setState(() => _dismissed.add(key));
    } catch (_) {
    } finally {
      setState(() => _rejecting.remove(key));
    }
  }

  Map<int, CompanyMemberModel> _buildMemberMap(UserModel? user) {
    final members = user?.companyMembers ?? [];
    return {for (final m in members) m.id: m};
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final pendingAsync = ref.watch(_emmaPendingProvider);
    final user = ref.watch(userStateProvider);
    final memberMap = _buildMemberMap(user);

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(color: theme.dashboardBoarder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(theme, pendingAsync, memberMap, user),
          Expanded(child: _body(theme, pendingAsync, memberMap, user)),
        ],
      ),
    );
  }

  Set<int> _memberIdsInData(
    AsyncValue<({
      List<_PendingEvent> events,
      List<_PendingTask> tasks,
      List<_PendingInquiry> inquiries,
      List<_EmailSuggestion> suggestions,
    })> async,
    UserModel? user,
  ) {
    final ids = <int>{};
    if (user != null) ids.add(user.idInt);
    async.whenData((data) {
      for (final e in data.events) {
        if (e.viewerId != null) ids.add(e.viewerId!);
      }
      for (final t in data.tasks) {
        if (t.assignedToId != null) ids.add(t.assignedToId!);
      }
    });
    return ids;
  }

  Widget _header(
    ThemeColors theme,
    AsyncValue<({
      List<_PendingEvent> events,
      List<_PendingTask> tasks,
      List<_PendingInquiry> inquiries,
      List<_EmailSuggestion> suggestions,
    })> pendingAsync,
    Map<int, CompanyMemberModel> memberMap,
    UserModel? user,
  ) {
    final count = pendingAsync.whenOrNull(
      data: (d) {
        final filtered = _applyFilter(d.events, d.tasks, user);
        final inquiryCount = d.inquiries
            .where((i) => !_dismissed.contains(_inquiryKey(i.id)))
            .length;
        final suggestionCount = d.suggestions
            .where((s) => !_dismissed.contains(_suggestionKey(s.id)))
            .length;
        return filtered.events
                .where((e) => !_dismissed.contains(_eventKey(e.id)))
                .length +
            filtered.tasks
                .where((t) => !_dismissed.contains(_taskKey(t.id)))
                .length +
            inquiryCount +
            suggestionCount;
      },
    );

    final memberIds = _memberIdsInData(pendingAsync, user);
    final availAsync = ref.watch(_teamAvailabilityProvider);
    final availMap = availAsync.whenOrNull(data: (m) => m) ?? {};

    final showFilter =
        memberMap.isNotEmpty && memberIds.length > 1 && pendingAsync.hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: _emmaAccent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Sugestie Emmy',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (count != null && count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _emmaAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: _emmaAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Odśwież',
                icon: Icon(Icons.refresh_rounded,
                    size: 18, color: theme.textColor.withAlpha(160)),
                onPressed: () {
                  ref.invalidate(_emmaPendingProvider);
                  ref.invalidate(_teamAvailabilityProvider);
                },
              ),
            ],
          ),
        ),
        if (showFilter)
          _memberFilterRow(theme, memberIds, memberMap, availMap, user),
      ],
    );
  }

  Widget _memberFilterRow(
    ThemeColors theme,
    Set<int> memberIds,
    Map<int, CompanyMemberModel> memberMap,
    Map<int, Color> availMap,
    UserModel? user,
  ) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        children: [
          _MemberChip(
            label: 'Wszyscy',
            avatarUrl: null,
            initials: null,
            availabilityColor: null,
            selected: _selectedMemberId == null,
            emmaAccent: _emmaAccent,
            theme: theme,
            onTap: () => setState(() => _selectedMemberId = null),
          ),
          ...memberIds.map((id) {
            final member = memberMap[id];
            final fullName = member != null
                ? '${member.firstName} ${member.lastName}'.trim().isNotEmpty
                    ? '${member.firstName} ${member.lastName}'.trim()
                    : member.username
                : (id == user?.idInt
                    ? ('${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim().isNotEmpty
                        ? '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim()
                        : user?.username ?? 'Ja')
                    : 'Użytkownik');
            final shortName = fullName.split(' ').first;
            return _MemberChip(
              label: shortName,
              avatarUrl: member?.avatar ?? (id == user?.idInt ? user?.avatarUrl : null),
              initials: _initials(fullName),
              availabilityColor: availMap[id],
              selected: _selectedMemberId == id,
              emmaAccent: _emmaAccent,
              theme: theme,
              onTap: () => setState(
                () => _selectedMemberId = _selectedMemberId == id ? null : id,
              ),
            );
          }),
        ],
      ),
    );
  }

  ({List<_PendingEvent> events, List<_PendingTask> tasks})  _applyFilter(
    List<_PendingEvent> events,
    List<_PendingTask> tasks,
    UserModel? user,
  ) {
    if (_selectedMemberId == null) {
      return (events: events, tasks: tasks);
    }
    final id = _selectedMemberId!;
    final currentUserId = user?.idInt;

    return (
      events: events.where((e) {
        if (e.viewerId == null) return id == currentUserId;
        return e.viewerId == id;
      }).toList(),
      tasks: tasks.where((t) {
        if (t.assignedToId == null) return id == currentUserId;
        return t.assignedToId == id;
      }).toList(),
    );
  }

  Widget _body(
    ThemeColors theme,
    AsyncValue<({
      List<_PendingEvent> events,
      List<_PendingTask> tasks,
      List<_PendingInquiry> inquiries,
      List<_EmailSuggestion> suggestions,
    })> pendingAsync,
    Map<int, CompanyMemberModel> memberMap,
    UserModel? user,
  ) {
    return pendingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text(
          'Błąd ładowania sugestii',
          style:
              TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12),
        ),
      ),
      data: (data) {
        final filtered = _applyFilter(data.events, data.tasks, user);

        final visibleEvents = filtered.events
            .where((e) => !_dismissed.contains(_eventKey(e.id)))
            .toList();
        final visibleTasks = filtered.tasks
            .where((t) => !_dismissed.contains(_taskKey(t.id)))
            .toList();
        final visibleInquiries = data.inquiries
            .where((i) => !_dismissed.contains(_inquiryKey(i.id)))
            .toList();
        final visibleSuggestions = data.suggestions
            .where((s) => !_dismissed.contains(_suggestionKey(s.id)))
            .toList();

        if (visibleEvents.isEmpty && visibleTasks.isEmpty &&
            visibleInquiries.isEmpty && visibleSuggestions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_outlined,
                    size: 28, color: theme.textColor.withAlpha(60)),
                const SizedBox(height: 8),
                Text(
                  'Brak aktywnych sugestii',
                  style: TextStyle(
                      color: theme.textColor.withAlpha(100), fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          children: [
            if (visibleSuggestions.isNotEmpty || visibleInquiries.isNotEmpty) ...[
              _sectionLabel('Z maili', Icons.mark_email_unread_outlined, theme,
                  color: _inquiryAccent),
              ...visibleInquiries.map((i) => _inquiryCard(i, theme)),
              ...visibleSuggestions.map((s) => _emailSuggestionCard(s, theme)),
            ],
            if (visibleEvents.isNotEmpty) ...[
              _sectionLabel('Wydarzenia', Icons.event_outlined, theme),
              ...visibleEvents
                  .map((e) => _eventCard(e, theme, memberMap, user)),
            ],
            if (visibleTasks.isNotEmpty) ...[
              _sectionLabel('Zadania', Icons.task_alt_outlined, theme),
              ...visibleTasks
                  .map((t) => _taskCard(t, theme, memberMap, user)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String label, IconData icon, ThemeColors theme, {Color? color}) {
    final c = color ?? theme.textColor.withAlpha(120);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inquiryCard(_PendingInquiry inq, ThemeColors theme) {
    final key = _inquiryKey(inq.id);
    final isReplying = _accepting[key] == true;
    final isDismissing = _rejecting[key] == true;
    final busy = isReplying || isDismissing;
    final selectedId = _selectedListingId[inq.id];
    final isDraftOpen = _draftExpanded.contains(inq.id);

    return _InquiryCard(
      theme: theme,
      inq: inq,
      inquiryAccent: _inquiryAccent,
      selectedListingId: selectedId,
      isDraftOpen: isDraftOpen,
      isReplying: isReplying,
      isDismissing: isDismissing,
      onSelectListing: busy
          ? null
          : (id) => setState(() {
                _selectedListingId[inq.id] = id;
                _draftExpanded.remove(inq.id);
              }),
      onReply: busy ? null : () => _replyInquiry(inq),
      onDismiss: busy ? null : () => _dismissInquiry(inq),
    );
  }

  Widget _eventCard(
    _PendingEvent e,
    ThemeColors theme,
    Map<int, CompanyMemberModel> memberMap,
    UserModel? user,
  ) {
    final key = _eventKey(e.id);
    final isAccepting = _accepting[key] == true;
    final isRejecting = _rejecting[key] == true;
    final busy = isAccepting || isRejecting;

    String? dateLabel;
    if (e.startTime != null) {
      final dt = DateTime.tryParse(e.startTime!);
      if (dt != null) {
        final local = dt.toLocal();
        dateLabel =
            '${local.day}.${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }
    }

    final (avatarUrl, memberName) =
        _resolveMember(e.viewerId, memberMap, user);

    return _SuggestionCard(
      theme: theme,
      icon: Icons.event_outlined,
      title: e.title,
      subtitle:
          dateLabel ?? (e.location?.isNotEmpty == true ? e.location! : null),
      summary: e.summary,
      userAvatarUrl: avatarUrl,
      userInitials: _initials(memberName ?? ''),
      isAccepting: isAccepting,
      isRejecting: isRejecting,
      onAccept: busy ? null : () => _acceptEvent(e),
      onReject: busy ? null : () => _rejectEvent(e),
    );
  }

  Widget _taskCard(
    _PendingTask t,
    ThemeColors theme,
    Map<int, CompanyMemberModel> memberMap,
    UserModel? user,
  ) {
    final key = _taskKey(t.id);
    final isAccepting = _accepting[key] == true;
    final isRejecting = _rejecting[key] == true;
    final busy = isAccepting || isRejecting;

    final (avatarUrl, memberName) =
        _resolveMember(t.assignedToId, memberMap, user);

    return _SuggestionCard(
      theme: theme,
      icon: Icons.task_alt_outlined,
      title: t.name,
      subtitle: t.deadline != null
          ? 'Termin: ${t.deadline!.substring(0, 10)}'
          : null,
      summary: t.summary,
      userAvatarUrl: avatarUrl,
      userInitials: _initials(memberName ?? ''),
      isAccepting: isAccepting,
      isRejecting: isRejecting,
      onAccept: busy ? null : () => _acceptTask(t),
      onReject: busy ? null : () => _rejectTask(t),
    );
  }

  (String? avatarUrl, String? name) _resolveMember(
    int? userId,
    Map<int, CompanyMemberModel> memberMap,
    UserModel? user,
  ) {
    final targetId = userId ?? user?.idInt;
    if (targetId == null) return (null, null);

    if (targetId == user?.idInt) {
      final name = '${user!.firstName} ${user.lastName}'.trim().isNotEmpty
          ? '${user.firstName} ${user.lastName}'.trim()
          : user.username;
      return (user.avatarUrl, name);
    }

    final member = memberMap[targetId];
    if (member != null) {
      final name = '${member.firstName} ${member.lastName}'.trim().isNotEmpty
          ? '${member.firstName} ${member.lastName}'.trim()
          : member.username;
      return (member.avatar, name);
    }

    return (null, null);
  }

  Widget _emailSuggestionCard(_EmailSuggestion s, ThemeColors theme) {
    final key = _suggestionKey(s.id);
    final isAccepting = _accepting[key] == true;
    final isDismissing = _rejecting[key] == true;
    final busy = isAccepting || isDismissing;

    // ── Redaction gate card ───────────────────────────────────────────────
    if (s.needsRedaction) {
      return _RedactionReviewCard(
        theme: theme,
        suggestion: s,
        isConfirming: isAccepting,
        isDismissing: isDismissing,
        onConfirm: busy ? null : () => _confirmRedaction(s),
        onDismiss: busy ? null : () => _dismissSuggestion(s),
      );
    }

    final isDraftOpen = _draftExpanded.contains(s.id);
    final selectedSlot = _selectedSlotIndex[s.id] ?? 0;

    return _EmailSuggestionCard(
      theme: theme,
      suggestion: s,
      accent: _inquiryAccent,
      isDraftOpen: isDraftOpen,
      selectedSlotIndex: selectedSlot,
      isAccepting: isAccepting,
      isDismissing: isDismissing,
      onSelectSlot: busy ? null : (i) => setState(() => _selectedSlotIndex[s.id] = i),
      onPrimaryAction: busy
          ? null
          : () {
              final stype = s.suggestionType;
              if (stype == 'viewing_request') {
                final slots = s.suggestedSlots;
                if (slots.isNotEmpty) {
                  final slot = slots[selectedSlot];
                  _acceptSuggestion(s, 'create_event', extra: {
                    'slot': {'start': slot.start, 'end': slot.end, 'label': slot.label},
                  });
                }
              } else if (stype == 'price_offer' || stype == 'document_request' || stype == 'referral') {
                if (isDraftOpen) {
                  _acceptSuggestion(s, 'send');
                } else {
                  _acceptSuggestion(s, 'draft');
                }
              } else if (stype == 'portal_lead' || stype == 'referral') {
                _acceptSuggestion(s, 'create_contact');
              } else if (stype == 'payment_confirmation') {
                _acceptSuggestion(s, 'create_revenue');
              } else if (stype == 'maintenance_request' || stype == 'notary_appointment') {
                _acceptSuggestion(s, 'create_task');
              } else {
                _acceptSuggestion(s, 'resolve');
              }
            },
      onDismiss: busy ? null : () => _dismissSuggestion(s),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '';
  }
}

// ---------------------------------------------------------------------------
// Member filter chip
// ---------------------------------------------------------------------------

class _MemberChip extends StatelessWidget {
  final String label;
  final String? avatarUrl;
  final String? initials;
  final Color? availabilityColor;
  final bool selected;
  final Color emmaAccent;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _MemberChip({
    required this.label,
    required this.avatarUrl,
    required this.initials,
    required this.availabilityColor,
    required this.selected,
    required this.emmaAccent,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? emmaAccent.withAlpha(30)
              : theme.dashboardContainer,
          border: Border.all(
            color: selected ? emmaAccent : theme.dashboardBoarder,
            width: selected ? 1.2 : 0.8,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initials != null && initials!.isNotEmpty) ...[
              Stack(
                children: [
                  _MiniAvatar(
                    avatarUrl: avatarUrl,
                    initials: initials!,
                    size: 18,
                    accent: emmaAccent,
                  ),
                  if (availabilityColor != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: availabilityColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dashboardContainer,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? emmaAccent
                    : theme.textColor.withAlpha(180),
                fontSize: 11.5,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini avatar – used by chip and card
// ---------------------------------------------------------------------------

class _MiniAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double size;
  final Color accent;

  const _MiniAvatar({
    required this.avatarUrl,
    required this.initials,
    required this.size,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent.withAlpha(55);

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsBox(bg),
        ),
      );
    }
    return _initialsBox(bg);
  }

  Widget _initialsBox(Color bg) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: TextStyle(
            color: accent,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Shared suggestion card
// ---------------------------------------------------------------------------

class _SuggestionCard extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? summary;
  final String? userAvatarUrl;
  final String? userInitials;
  final bool isAccepting;
  final bool isRejecting;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  static const _emmaAccent = Color(0xFF37B6FF);

  const _SuggestionCard({
    required this.theme,
    required this.icon,
    required this.title,
    this.subtitle,
    this.summary,
    this.userAvatarUrl,
    this.userInitials,
    required this.isAccepting,
    required this.isRejecting,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = userInitials != null && userInitials!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: _emmaAccent.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _emmaAccent.withAlpha(40), width: 0.7),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: _emmaAccent.withAlpha(180)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasAvatar) ...[
                const SizedBox(width: 6),
                _MiniAvatar(
                  avatarUrl: userAvatarUrl,
                  initials: userInitials!,
                  size: 22,
                  accent: _emmaAccent,
                ),
              ],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: theme.textColor.withAlpha(130),
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (summary != null && summary!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(
                summary!,
                style: TextStyle(
                  color: _emmaAccent.withAlpha(180),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 7),
          Row(
            children: [
              _ActionBtn(
                label: 'Zatwierdź',
                loading: isAccepting,
                color: const Color(0xFF4CAF50),
                onTap: onAccept,
              ),
              const SizedBox(width: 6),
              _ActionBtn(
                label: 'Odrzuć',
                loading: isRejecting,
                color: Colors.redAccent,
                onTap: onReject,
                outlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final Color color;
  final VoidCallback? onTap;
  final bool outlined;

  const _ActionBtn({
    required this.label,
    required this.loading,
    required this.color,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: loading
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color),
              )
            : Text(label),
      );
    }
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: loading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// Email suggestion card – universal card for all non-listing-inquiry types
// ---------------------------------------------------------------------------

class _EmailSuggestionCard extends StatelessWidget {
  final ThemeColors theme;
  final _EmailSuggestion suggestion;
  final Color accent;
  final bool isDraftOpen;
  final int selectedSlotIndex;
  final bool isAccepting;
  final bool isDismissing;
  final void Function(int index)? onSelectSlot;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onDismiss;

  const _EmailSuggestionCard({
    required this.theme,
    required this.suggestion,
    required this.accent,
    required this.isDraftOpen,
    required this.selectedSlotIndex,
    required this.isAccepting,
    required this.isDismissing,
    this.onSelectSlot,
    this.onPrimaryAction,
    this.onDismiss,
  });

  static const _typeConfig = <String, (IconData, String, String)>{
    // type: (icon, label, primaryBtnLabel)
    'viewing_request':     (Icons.calendar_today_outlined,  'Prośba o oglądanie',    'Utwórz termin'),
    'price_offer':         (Icons.handshake_outlined,        'Oferta cenowa',          'Odpowiedz'),
    'portal_lead':         (Icons.person_add_outlined,       'Nowy lead z portalu',    'Dodaj kontakt'),
    'payment_confirmation':(Icons.payments_outlined,         'Potwierdzenie płatności','Zapisz wpłatę'),
    'document_request':    (Icons.folder_outlined,           'Prośba o dokumenty',     'Odpowiedz'),
    'referral':            (Icons.group_add_outlined,        'Polecenie klienta',       'Dodaj kontakt'),
    'maintenance_request': (Icons.build_outlined,            'Zgłoszenie usterki',     'Utwórz zadanie'),
    'notary_appointment':  (Icons.gavel_outlined,            'Wizyta u notariusza',    'Utwórz zadanie'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[suggestion.suggestionType]
        ?? (Icons.mail_outlined, suggestion.suggestionType, 'Zatwierdź');
    final (icon, typeLabel, primaryLabel) = cfg;

    final slots = suggestion.suggestedSlots;
    final listings = suggestion.listings;
    final payload = suggestion.payload;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: accent.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(50), width: 0.7),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Type badge + sender ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: accent.withAlpha(200)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.senderName.isNotEmpty
                          ? suggestion.senderName
                          : suggestion.senderEmail,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (suggestion.subject.isNotEmpty)
                      Text(
                        suggestion.subject,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(140),
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Type-specific content ──────────────────────────────────────

          // VIEWING REQUEST: slot suggestions
          if (suggestion.suggestionType == 'viewing_request' && slots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Emma proponuje termin prezentacji:',
              style: TextStyle(
                color: theme.textColor.withAlpha(150),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...slots.asMap().entries.map((e) {
              final idx = e.key;
              final slot = e.value;
              final selected = selectedSlotIndex == idx;
              return GestureDetector(
                onTap: onSelectSlot == null ? null : () => onSelectSlot!(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? accent.withAlpha(20) : theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? accent.withAlpha(120) : theme.dashboardBoarder,
                      width: selected ? 1.0 : 0.7,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 14,
                        color: selected ? accent : theme.textColor.withAlpha(80),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.label,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              slot.reason,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(120),
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (listings.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                listings.first.displayAddress,
                style: TextStyle(
                  color: theme.textColor.withAlpha(130),
                  fontSize: 11,
                ),
              ),
            ],
          ],

          // PRICE OFFER: offered price + listing
          if (suggestion.suggestionType == 'price_offer') ...[
            const SizedBox(height: 6),
            if (payload['offered_price'] != null)
              _infoRow(
                theme, Icons.monetization_on_outlined,
                'Oferta: ${_fmtPrice(payload['offered_price'])} zł',
              ),
            if (listings.isNotEmpty)
              _infoRow(theme, Icons.home_outlined, listings.first.displayAddress),
          ],

          // PORTAL LEAD: source + phone
          if (suggestion.suggestionType == 'portal_lead') ...[
            const SizedBox(height: 6),
            if (payload['source_portal'] != null && payload['source_portal'] != 'unknown')
              _infoRow(theme, Icons.public_outlined, 'Portal: ${payload['source_portal']}'),
            if (payload['phone'] != null)
              _infoRow(theme, Icons.phone_outlined, payload['phone'].toString()),
          ],

          // PAYMENT: amount
          if (suggestion.suggestionType == 'payment_confirmation') ...[
            const SizedBox(height: 6),
            if (payload['amount'] != null)
              _infoRow(theme, Icons.payments_outlined,
                  'Kwota: ${_fmtPrice(payload['amount'])} zł'),
            if (payload['period'] != null)
              _infoRow(theme, Icons.calendar_month_outlined, payload['period'].toString()),
          ],

          // MAINTENANCE: urgency
          if (suggestion.suggestionType == 'maintenance_request') ...[
            const SizedBox(height: 6),
            _infoRow(
              theme,
              payload['urgency'] == 'high' ? Icons.warning_amber_rounded : Icons.build_outlined,
              payload['urgency'] == 'high' ? 'Pilne zgłoszenie' : 'Standardowe zgłoszenie',
            ),
          ],

          // REFERRAL: referred_by
          if (suggestion.suggestionType == 'referral' && payload['referred_by'] != null) ...[
            const SizedBox(height: 6),
            _infoRow(theme, Icons.person_outlined, 'Z polecenia: ${payload['referred_by']}'),
          ],

          // Draft preview
          if (isDraftOpen && suggestion.replyDraft.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withAlpha(60)),
              ),
              child: Text(
                suggestion.replyDraft,
                style: TextStyle(
                  color: theme.textColor.withAlpha(180),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── Actions ────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionBtn(
                label: isDraftOpen ? 'Wyślij' : primaryLabel,
                loading: isAccepting,
                color: accent,
                onTap: onPrimaryAction,
              ),
              const SizedBox(width: 6),
              _ActionBtn(
                label: 'Odrzuć',
                loading: isDismissing,
                color: Colors.redAccent,
                onTap: onDismiss,
                outlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeColors theme, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(icon, size: 12, color: theme.textColor.withAlpha(120)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: theme.textColor.withAlpha(160), fontSize: 11.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  static String _fmtPrice(dynamic raw) {
    final n = double.tryParse(raw.toString());
    if (n == null) return raw.toString();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)} M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)} tys.';
    return n.toStringAsFixed(0);
  }
}

// ---------------------------------------------------------------------------
// Inquiry card – handles 0, 1, or multiple listing matches
// ---------------------------------------------------------------------------

class _InquiryCard extends StatelessWidget {
  final ThemeColors theme;
  final _PendingInquiry inq;
  final Color inquiryAccent;
  final int? selectedListingId;
  final bool isDraftOpen;
  final bool isReplying;
  final bool isDismissing;
  final void Function(int listingId)? onSelectListing;
  final VoidCallback? onReply;
  final VoidCallback? onDismiss;

  const _InquiryCard({
    required this.theme,
    required this.inq,
    required this.inquiryAccent,
    required this.selectedListingId,
    required this.isDraftOpen,
    required this.isReplying,
    required this.isDismissing,
    this.onSelectListing,
    this.onReply,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final hasMatches = inq.matches.isNotEmpty;
    final isAmbiguous = inq.matches.length > 1;
    final effectiveId = selectedListingId ??
        (hasMatches ? inq.matches.first.id : null);
    final effectiveListing = hasMatches
        ? inq.matches.firstWhere(
            (m) => m.id == effectiveId,
            orElse: () => inq.matches.first,
          )
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: inquiryAccent.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: inquiryAccent.withAlpha(50), width: 0.7),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: sender + subject ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mark_email_unread_outlined,
                  size: 14, color: inquiryAccent.withAlpha(200)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inq.senderName.isNotEmpty
                          ? inq.senderName
                          : inq.senderEmail,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (inq.subject.isNotEmpty)
                      Text(
                        inq.subject,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(140),
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── No matches: unknown listing ───────────────────────────────
          if (!hasMatches) ...[
            const SizedBox(height: 6),
            Text(
              'Nie znaleziono pasującej oferty',
              style: TextStyle(
                color: theme.textColor.withAlpha(120),
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // ── Single clear match ────────────────────────────────────────
          if (hasMatches && !isAmbiguous && effectiveListing != null) ...[
            const SizedBox(height: 8),
            _ListingMatchTile(
              match: effectiveListing,
              theme: theme,
              accent: inquiryAccent,
              selected: true,
              onTap: null,
            ),
          ],

          // ── Multiple matches: disambiguation list ─────────────────────
          if (isAmbiguous) ...[
            const SizedBox(height: 6),
            Text(
              'Wybierz ofertę której dotyczy zapytanie:',
              style: TextStyle(
                color: theme.textColor.withAlpha(150),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...inq.matches.map(
              (m) => _ListingMatchTile(
                match: m,
                theme: theme,
                accent: inquiryAccent,
                selected: (selectedListingId ?? inq.matches.first.id) == m.id,
                onTap: onSelectListing == null ? null : () => onSelectListing!(m.id),
              ),
            ),
          ],

          // ── Draft preview (after "Odpowiedz" is tapped) ──────────────
          if (isDraftOpen && inq.replyDraft.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: inquiryAccent.withAlpha(60)),
              ),
              child: Text(
                inq.replyDraft,
                style: TextStyle(
                  color: theme.textColor.withAlpha(180),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── Actions ───────────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionBtn(
                label: isDraftOpen ? 'Wyślij' : 'Odpowiedz',
                loading: isReplying,
                color: inquiryAccent,
                onTap: hasMatches ? onReply : null,
              ),
              const SizedBox(width: 6),
              _ActionBtn(
                label: 'Odrzuć',
                loading: isDismissing,
                color: Colors.redAccent,
                onTap: onDismiss,
                outlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingMatchTile extends StatelessWidget {
  final _ListingMatch match;
  final ThemeColors theme;
  final Color accent;
  final bool selected;
  final VoidCallback? onTap;

  const _ListingMatchTile({
    required this.match,
    required this.theme,
    required this.accent,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(20) : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? accent.withAlpha(100) : theme.dashboardBoarder,
            width: selected ? 1.0 : 0.7,
          ),
        ),
        child: Row(
          children: [
            // Availability dot
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                color: match.isActive
                    ? const Color(0xFF4CAF50)
                    : Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.displayAddress,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (match.detailLine.isNotEmpty)
                    Text(
                      match.detailLine,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(130),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (match.price != null) ...[
              const SizedBox(width: 6),
              Text(
                '${_formatPrice(match.price!)} ${match.currency}',
                style: TextStyle(
                  color: accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 14,
                color: selected ? accent : theme.textColor.withAlpha(80),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatPrice(String raw) {
    final n = double.tryParse(raw);
    if (n == null) return raw;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)} M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)} tys.';
    return n.toStringAsFixed(0);
  }
}

// ---------------------------------------------------------------------------
// Redaction review card
// ---------------------------------------------------------------------------

class _RedactionReviewCard extends StatefulWidget {
  final ThemeColors theme;
  final _EmailSuggestion suggestion;
  final bool isConfirming;
  final bool isDismissing;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;

  const _RedactionReviewCard({
    required this.theme,
    required this.suggestion,
    required this.isConfirming,
    required this.isDismissing,
    this.onConfirm,
    this.onDismiss,
  });

  @override
  State<_RedactionReviewCard> createState() => _RedactionReviewCardState();
}

class _RedactionReviewCardState extends State<_RedactionReviewCard> {
  bool _maskedPreviewExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final t = widget.theme;
    final busy = widget.isConfirming || widget.isDismissing;

    const _warningOrange = Color(0xFFFF6D00);
    const _dangerRed     = Color(0xFFF44336);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: t.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warningOrange.withValues(alpha: .5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Warning header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _warningOrange.withValues(alpha: .10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: _warningOrange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Wykryto dane wrażliwe — Emma wstrzymała analizę',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _warningOrange,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Email metadata ──────────────────────────────────────
                Text(
                  s.senderName.isNotEmpty ? s.senderName : s.senderEmail,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.textColor,
                  ),
                ),
                if (s.subject.isNotEmpty)
                  Text(
                    s.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: t.textColor.withValues(alpha: .65),
                    ),
                  ),
                const SizedBox(height: 10),

                // ── Detected types chips ────────────────────────────────
                Text(
                  'Wykryte typy danych:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.textColor.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: s.detectedSensitiveLabels.map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _dangerRed.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _dangerRed.withValues(alpha: .4)),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _dangerRed,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // ── Masked preview (collapsible) ────────────────────────
                if (s.maskedText.isNotEmpty) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _maskedPreviewExpanded = !_maskedPreviewExpanded),
                    child: Row(
                      children: [
                        Icon(
                          _maskedPreviewExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: t.textColor.withValues(alpha: .55),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _maskedPreviewExpanded
                              ? 'Ukryj podgląd z zakrytymi danymi'
                              : 'Pokaż podgląd z zakrytymi danymi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: t.textColor.withValues(alpha: .6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _maskedPreviewExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: t.textColor.withValues(alpha: .05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: t.dashboardBoarder),
                      ),
                      child: SelectableText(
                        s.maskedText,
                        style: TextStyle(
                          fontSize: 11,
                          color: t.textColor.withValues(alpha: .8),
                          height: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Confirmation prompt ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _warningOrange.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _warningOrange.withValues(alpha: .25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: _warningOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sprawdź, czy wszystkie dane zostały poprawnie zakryte (oznaczone [PESEL], [IBAN] itp.). '
                          'Po potwierdzeniu Emma przeanalizuje mail — wyśle tylko zakrytą wersję.',
                          style: TextStyle(
                            fontSize: 11,
                            color: t.textColor.withValues(alpha: .75),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Action buttons ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onConfirm,
                        icon: widget.isConfirming
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Dane zakryte poprawnie — analizuj'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _warningOrange,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: busy ? null : widget.onDismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.textColor.withValues(alpha: .6),
                        side: BorderSide(color: t.dashboardBoarder),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      ),
                      child: widget.isDismissing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Odrzuć', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
