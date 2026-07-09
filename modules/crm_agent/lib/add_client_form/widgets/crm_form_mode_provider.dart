import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Persisted mode toggle ────────────────────────────────────────────────────

const _kKey = 'crm_add_form_steps_mode';

class CrmFormModeNotifier extends StateNotifier<bool> {
  CrmFormModeNotifier() : super(false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) state = prefs.getBool(_kKey) ?? false;
  }

  void toggle() {
    state = !state;
    SharedPreferences.getInstance().then((p) => p.setBool(_kKey, state));
  }
}

/// true = steps mode, false = full form
final crmFormStepsEnabledProvider =
    StateNotifierProvider<CrmFormModeNotifier, bool>((ref) {
  final n = CrmFormModeNotifier();
  unawaited(n.load());
  return n;
});

// ─── Step progress (same pattern as add_offer progressProvider) ───────────────

/// 0.5 = step 0, 1.5 = step 1  (matches progressToPageIndex convention)
final crmProgressProvider = StateProvider<double>((ref) => 0.5);

/// Highest step index the user has visited — controls back-navigation access.
final crmMaxVisitedStepProvider = StateProvider<int>((ref) => 0);

int crmProgressToStep(double progress) {
  final raw = (progress - 0.5).floor();
  return raw < 0 ? 0 : raw;
}

double crmStepToProgress(int step) => step + 0.5;

void crmResetProgress(dynamic ref) {
  ref.read(crmProgressProvider.notifier).state = 0.5;
  ref.read(crmMaxVisitedStepProvider.notifier).state = 0;
}
