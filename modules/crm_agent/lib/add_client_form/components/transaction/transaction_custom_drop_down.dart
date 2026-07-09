import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart'; // ✅ for .tr
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';

class DropdownState {
  final String selectedValue;
  final String valueKey;
  final int? txId;

  DropdownState({
    required this.selectedValue,
    required this.valueKey,
    required this.txId,
  });
}

class DropdownNotifier extends StateNotifier<Map<String, DropdownState>> {
  DropdownNotifier() : super(<String, DropdownState>{});

  static String makeKey({
    required int id,
    required String valueKey,
    required int? txId,
  }) =>
      '$valueKey|$id|${txId ?? 'new'}';

  String _norm(String s) => s.trim().toLowerCase();

  String? _normalizeInitial(String? raw, List<String> options) {
    if (raw == null) return null;
    final needle = _norm(raw);
    for (final o in options) {
      if (_norm(o) == needle) return o;
    }
    return null;
  }

  void setInitial({
    required int id,
    required String valueKey,
    required int? txId,
    required String? initialValue,
    required List<String> options,
    required WidgetRef ref,
  }) {
    final normalized = _normalizeInitial(initialValue, options);
    if (normalized == null) return;

    final k = makeKey(id: id, valueKey: valueKey, txId: txId);
    final curr = state[k];

    if (curr == null || curr.selectedValue != normalized) {
      Future.microtask(() {
        state = {
          ...state,
          k: DropdownState(
            selectedValue: normalized,
            valueKey: valueKey,
            txId: txId,
          ),
        };
        ref.read(agentTransactionCacheProvider.notifier).addTransactionData(valueKey, normalized);
      });
    }
  }

  void update({
    required int id,
    required String valueKey,
    required int? txId,
    required String newValue,
    required WidgetRef ref,
  }) {
    final k = makeKey(id: id, valueKey: valueKey, txId: txId);
    state = {
      ...state,
      k: DropdownState(
        selectedValue: newValue,
        valueKey: valueKey,
        txId: txId,
      ),
    };
    ref.read(agentTransactionCacheProvider.notifier).addTransactionData(valueKey, newValue);
  }
}

final agentTransactionDropDownProvider =
    StateNotifierProvider<DropdownNotifier, Map<String, DropdownState>>((ref) {
  return DropdownNotifier();
});

class AgentTransactionFormCustomDropDown extends ConsumerStatefulWidget {
  final int id;
  final List<String> options; // ✅ values (MUST be unique)
  final String hintText;
  final String valueKey;

  final int? txId;
  final String? initialValue;
  final VoidCallback? onChanged;
  final String? Function(String?)? validator;

  /// ✅ NEW: translate only labels, keep values stable
  final bool translateLabels;

  const AgentTransactionFormCustomDropDown({
    super.key,
    required this.id,
    required this.options,
    required this.hintText,
    required this.valueKey,
    this.txId,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.translateLabels = false,
  });

  @override
  ConsumerState<AgentTransactionFormCustomDropDown> createState() =>
      _AgentTransactionFormCustomDropDownState();
}

class _AgentTransactionFormCustomDropDownState
    extends ConsumerState<AgentTransactionFormCustomDropDown> {
  DropdownNotifier get _notifier => ref.read(agentTransactionDropDownProvider.notifier);

  String get _mapKey => DropdownNotifier.makeKey(
        id: widget.id,
        valueKey: widget.valueKey,
        txId: widget.txId,
      );

  /// ✅ Dedupe by VALUE (just in case)
  List<String> _uniqueValues(List<String> input) {
    final seen = <String>{};
    final out = <String>[];
    for (final s in input) {
      final v = s.trim();
      if (v.isEmpty) continue;
      if (seen.add(v)) out.add(v);
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.setInitial(
        id: widget.id,
        valueKey: widget.valueKey,
        txId: widget.txId,
        initialValue: widget.initialValue,
        options: _uniqueValues(widget.options),
        ref: ref,
      );
    });
  }

  @override
  void didUpdateWidget(covariant AgentTransactionFormCustomDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.txId != widget.txId ||
        oldWidget.initialValue != widget.initialValue ||
        oldWidget.valueKey != widget.valueKey ||
        oldWidget.id != widget.id ||
        oldWidget.options != widget.options) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifier.setInitial(
          id: widget.id,
          valueKey: widget.valueKey,
          txId: widget.txId,
          initialValue: widget.initialValue,
          options: _uniqueValues(widget.options),
          ref: ref,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final map = ref.watch(agentTransactionDropDownProvider);

    final uniqOptions = _uniqueValues(widget.options);

    final stored = map[_mapKey]?.selectedValue;
    final currentValue =
        (stored != null && uniqOptions.contains(stored.trim())) ? stored.trim() : null;

    final formFieldKey = ValueKey('${_mapKey}_${currentValue ?? 'null'}');

    return FormField<String>(
      key: formFieldKey,
      initialValue: currentValue,
      validator: widget.validator,
      builder: (state) {
        final errorText = state.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: errorText == null
                      ? theme.dashboardBoarder
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.value,
                  hint: Text(
                    widget.hintText,
                    style: TextStyle(color: theme.textColor, fontSize: 12),
                  ),
                  icon: AppIcons.iosArrowDown(color: theme.textColor),
                  dropdownColor: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(6),
                  style: TextStyle(color: theme.textColor, fontSize: 14),
                  items: uniqOptions
                      .map(
                        (opt) => DropdownMenuItem<String>(
                          value: opt, // ✅ stable unique value (NOT translated)
                          child: Text(
                            widget.translateLabels ? opt.tr : opt,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;

                    state.didChange(newValue);

                    _notifier.update(
                      id: widget.id,
                      valueKey: widget.valueKey,
                      txId: widget.txId,
                      newValue: newValue,
                      ref: ref,
                    );

                    widget.onChanged?.call();
                  },
                ),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}