import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportNotesNotifier extends AsyncNotifier<Map<int, String>> {
  static const _prefix = 'report_note_';

  @override
  Future<Map<int, String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <int, String>{};
    for (final k in keys) {
      final id = int.tryParse(k.substring(_prefix.length));
      if (id != null) map[id] = prefs.getString(k) ?? '';
    }
    return map;
  }

  Future<void> saveNote(int reportId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await prefs.remove('$_prefix$reportId');
    } else {
      await prefs.setString('$_prefix$reportId', text);
    }
    state = AsyncData({
      ...state.valueOrNull ?? {},
      reportId: text,
    });
  }
}

final reportNotesProvider =
    AsyncNotifierProvider<ReportNotesNotifier, Map<int, String>>(
  ReportNotesNotifier.new,
);
