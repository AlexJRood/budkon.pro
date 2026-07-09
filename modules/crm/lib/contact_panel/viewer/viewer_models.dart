
// ── MODELE ───────────────────────────────────────────────────────
// viewer_models.dart (albo gdzie masz ViewerItem)

import 'package:calendar/models/event_model.dart'; // <-- masz już EventModel

class ViewerItem {
  final int id;
  final int contactId;
  final int transactionId;
  final String? name;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? avatar;
  final int? statusId;
  final String? note;
  final String? lastContactAt;
  final bool isHide;
  final List<EventModel> events; // <-- NEW

  ViewerItem({
    required this.id,
    required this.contactId,
    required this.transactionId,
    this.name,
    this.lastName,
    this.email,
    this.phone,
    this.avatar,
    this.statusId,
    this.note,
    this.lastContactAt,
    this.isHide = false,
    this.events = const [], // <-- NEW
  });

  factory ViewerItem.fromJson(Map<String, dynamic> j) {
    final eventsRaw = (j['events'] as List?) ?? const [];
    final evs = <EventModel>[];
    for (final e in eventsRaw) {
      if (e is Map<String, dynamic>) {
        evs.add(EventModel.fromJson(e));
      }
    }
    return ViewerItem(
      id: j['id'],
      contactId: j['contact'],
      transactionId: j['transaction'],
      name: j['name'],
      lastName: j['last_name'],
      email: j['email'],
      phone: j['phone'],
      avatar: j['avatar'],
      statusId: j['status']?['id'] ?? j['status_id'],
      note: j['note'],
      lastContactAt: j['last_contact_at'],
      isHide: (j['is_hide'] ?? false) == true,
      events: evs, // <-- NEW
    );
  }
}



class ViewerStatusType {
  final int id;
  final String label;
  final int index;

  ViewerStatusType({required this.id, required this.label, required this.index});
  factory ViewerStatusType.fromJson(Map<String, dynamic> j)
    => ViewerStatusType(id: j['id'], label: j['label'], index: j['index'] ?? 0);
}
