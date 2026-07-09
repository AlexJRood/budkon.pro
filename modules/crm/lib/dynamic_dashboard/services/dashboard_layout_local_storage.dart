import 'dart:convert';

import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dashboardLayoutLocalStorageProvider =
    Provider<DashboardLayoutLocalStorage>((ref) {
  return DashboardLayoutLocalStorage();
});

class DashboardLayoutLocalStorage {
  SharedPreferences? _prefs;

  String _configKey(String dashboardKey) => 'dashboard_layout_config_$dashboardKey';
  String _lastCheckKey(String dashboardKey) => 'dashboard_layout_last_check_$dashboardKey';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<DashboardConfig?> readConfig(String dashboardKey) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_configKey(dashboardKey));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return DashboardConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return DashboardConfig.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeConfig(String dashboardKey, DashboardConfig config) async {
    final prefs = await _getPrefs();
    await prefs.setString(_configKey(dashboardKey), jsonEncode(config.toJson()));
  }

  Future<DateTime?> readLastCheck(String dashboardKey) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_lastCheckKey(dashboardKey));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastCheck(String dashboardKey, DateTime value) async {
    final prefs = await _getPrefs();
    await prefs.setString(_lastCheckKey(dashboardKey), value.toUtc().toIso8601String());
  }

  Future<void> clear(String dashboardKey) async {
    final prefs = await _getPrefs();
    await prefs.remove(_configKey(dashboardKey));
    await prefs.remove(_lastCheckKey(dashboardKey));
  }
}