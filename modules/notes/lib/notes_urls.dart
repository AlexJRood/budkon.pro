import 'package:core/platform/url.dart';

/// Notes feature API endpoints. Moved out of core's `URLs` God-package —
/// these are consumed only inside the notes module, so they live with the
/// feature. The shared host stays central (`URLs.baseUrl`).
class NotesUrls {
  const NotesUrls._();

  static const String notes = '${URLs.baseUrl}/notes/notes/';
  static String note(int id) => '${URLs.baseUrl}/notes/notes/$id/';
  static String shareNote(int id) => '${URLs.baseUrl}/notes/notes/$id/share/';
  static const String sharedNotes = '${URLs.baseUrl}/notes/notes/shared/';
}
