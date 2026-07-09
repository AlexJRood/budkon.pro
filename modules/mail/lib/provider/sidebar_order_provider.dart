import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SidebarOrderNotifier extends StateNotifier<List<String>?> {
  static const _prefKey = 'mail_sidebar_order_v1';

  SidebarOrderNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey);
    if (mounted) state = saved;
  }

  Future<void> update(List<String> order) async {
    state = order;
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_prefKey, order);
  }

  Future<void> reset() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_prefKey);
  }
}

final sidebarOrderProvider =
    StateNotifierProvider<SidebarOrderNotifier, List<String>?>(
  (ref) => SidebarOrderNotifier(),
);
