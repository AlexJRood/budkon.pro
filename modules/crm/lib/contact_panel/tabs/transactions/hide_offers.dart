// comments in English per your guideline
import 'package:crm/contact_panel/tabs/transactions/transaction_docs_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/components/cards/provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';


/// Transient modes: clicking them again should return to last sticky
const Set<TransactionViewMode> _transientViews = {
  TransactionViewMode.search,
  TransactionViewMode.fav,
  TransactionViewMode.draft,
};

/// Controller state: selected + last sticky
@immutable
class ViewModeState {
  final TransactionViewMode selected;
  final TransactionViewMode lastSticky;
  const ViewModeState({required this.selected, required this.lastSticky});

  ViewModeState copyWith({
    TransactionViewMode? selected,
    TransactionViewMode? lastSticky,
  }) => ViewModeState(
    selected: selected ?? this.selected,
    lastSticky: lastSticky ?? this.lastSticky,
  );

  @override
  String toString() =>
      'ViewModeState(selected: $selected, lastSticky: $lastSticky)';
}

/// Robust controller with explicit API
class ViewModeController extends StateNotifier<ViewModeState> {
  ViewModeController({required TransactionType type})
    : super(
        ViewModeState(
          selected:
              type == TransactionType.buy
                  ? TransactionViewMode.search
                  : TransactionViewMode.draft,
          lastSticky: TransactionViewMode.details, // default fallback
        ),
      );

  /// Handle click on a given mode with sticky logic
  void onTap(TransactionViewMode mode) {
    final isSelected = state.selected == mode;

    // If clicking same transient -> go back to last sticky
    if (isSelected && _transientViews.contains(mode)) {
      state = state.copyWith(selected: state.lastSticky);
      return;
    }

    // Always select clicked
    var newState = state.copyWith(selected: mode);

    // If sticky, remember it
    if (!_transientViews.contains(mode)) {
      newState = newState.copyWith(lastSticky: mode);
    }

    state = newState;
  }
}

/// Unique provider name to avoid collisions anywhere in the app.
/// If you need different state per-transaction-id, switch this to `.family`.
final viewModeControllerProvider = StateNotifierProvider.autoDispose
    .family<ViewModeController, ViewModeState, TransactionType>(
      (ref, type) => ViewModeController(type: type),
    );

/// Strongly typed option config
class _Option {
  final String label;
  final TransactionViewMode value;
  final Widget Function({Color? color}) icon;
  const _Option({required this.label, required this.value, required this.icon});
}

class ViewModeTransaction extends ConsumerWidget {
  final bool isClientView;
  final TransactionType type;

  const ViewModeTransaction({
    super.key,
    this.isClientView = false,
    this.type = TransactionType.create,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    // read state from our UNIQUE controller (no clash with other providers)
    final vm = ref.watch(viewModeControllerProvider(type));
    final selected = vm.selected;

    // Options based on transaction type
    final List<_Option> cardOptions =
        (type == TransactionType.buy)
            ? const [
              _Option(
                label: 'Search',
                value: TransactionViewMode.search,
                icon: AppIcons.search,
              ),
              _Option(
                label: 'Details',
                value: TransactionViewMode.details,
                icon: AppIcons.gridView,
              ),
              _Option(
                label: 'Note',
                value: TransactionViewMode.note,
                icon: AppIcons.task,
              ),
              _Option(
                label: 'Docs',
                value: TransactionViewMode.docs,
                icon: AppIcons.folder,
              ),
              _Option(
                label: 'Fav',
                value: TransactionViewMode.fav,
                icon: AppIcons.heart,
              ),
            ]
            : const [
              _Option(
                label: 'Draft',
                value: TransactionViewMode.draft,
                icon: AppIcons.mapView,
              ),
              _Option(
                label: 'Details',
                value: TransactionViewMode.details,
                icon: AppIcons.gridView,
              ),
              _Option(
                label: 'Note',
                value: TransactionViewMode.note,
                icon: AppIcons.mapView,
              ),
              _Option(
                label: 'Docs',
                value: TransactionViewMode.docs,
                icon: AppIcons.folder,
              ),
              _Option(
                label: 'Viewers',
                value: TransactionViewMode.viewer,
                icon: AppIcons.person,
              ),
            ];

    final bool showRightSelector = selected == TransactionViewMode.search;

    // Buttons
    final controller = ref.read(viewModeControllerProvider(type).notifier);
    final List<Widget> leftButtons =
        cardOptions.map((opt) {
          final isSelected = selected == opt.value;
          return SizedBox(
            height: 35,
            child: ElevatedButton.icon(
              icon: opt.icon(
                color: isSelected ? Colors.white : theme.textColor,
              ),
              label: Text(
                opt.label.tr,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textColor,
                ),
              ),
              onPressed: () {
                // single source of truth: delegate to controller
                controller.onTap(opt.value);
              },
              style:
                  isSelected
                      ? buttonStyleRounded10ThemeRedWithPadding15
                      : elevatedButtonStyleRounded10,
            ),
          );
        }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LEFT: buttons + tiny live state badge (can remove anytime)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 4,
              children: [const SizedBox(width: 8), ...leftButtons],
            ),
          ),
        ),

        // RIGHT: selector only in search mode
        if (showRightSelector) ...[
          const SizedBox(width: 12),
          CardTypeSelectorNM(),
          const SizedBox(width: 12),
        ],
      ],
    );
  }
}
