import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:tms_app/todo/provider/filtered_tasks_provider.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';

class SelectionHeaderBar extends StatelessWidget {
  final dynamic theme;
  final String label;
  final bool isOpen;
  final VoidCallback onClear;
  final VoidCallback onToggleOpen;

  const SelectionHeaderBar({
    super.key,
    required this.theme,
    required this.label,
    required this.isOpen,
    required this.onClear,
    required this.onToggleOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.popupcontainercolor.withAlpha((255 * 0.25).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.textColor.withAlpha((255 * 0.12).toInt()),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text('Clear'.tr, style: TextStyle(color: theme.textColor)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: elevatedButtonStyleRounded10.copyWith(
              backgroundColor: WidgetStatePropertyAll(theme.themeColor),
              foregroundColor: WidgetStatePropertyAll(theme.themeTextColor),
            ),
            onPressed: onToggleOpen,
            child: Text(
              isOpen ? 'Close'.tr : 'select'.tr,
              style: AppTextStyles.interMedium.copyWith(
                color: theme.themeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionListContainer extends StatelessWidget {
  final dynamic theme;
  final Widget child;

  const SelectionListContainer({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.popupcontainercolor.withAlpha((255 * 0.20).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.textColor.withAlpha((255 * 0.12).toInt()),
        ),
      ),
      child: child,
    );
  }
}

class SelectionSearchField extends StatefulWidget {
  final dynamic theme;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFocused;

  const SelectionSearchField({
    super.key,
    required this.theme,
    required this.hint,
    required this.onChanged,
    this.onFocused,
  });

  @override
  State<SelectionSearchField> createState() => _SelectionSearchFieldState();
}

class _SelectionSearchFieldState extends State<SelectionSearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onFocused?.call();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      onTap: widget.onFocused,
      onChanged: widget.onChanged,
      style: TextStyle(color: widget.theme.textColor),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: widget.theme.textColor.withAlpha((255 * 0.5).toInt()),
        ),
        filled: true,
        fillColor: widget.theme.popupcontainercolor.withAlpha((255 * 0.25).toInt()),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.theme.textColor.withAlpha((255 * 0.12).toInt()),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.theme.textColor.withAlpha((255 * 0.35).toInt()),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

class FilterActionsRow extends ConsumerWidget {
  final dynamic theme;
  final VoidCallback? onApply;

  const FilterActionsRow({
    super.key,
    required this.theme,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        TextButton(
          onPressed: () {
            ref.read(taskFiltersProvider.notifier).reset();
            ref.read(appliedTaskFiltersProvider.notifier).state = const TaskFiltersState();

            ref.read(showAssignedClientsSheetProvider.notifier).state = false;
            ref.read(assignedClientsSearchQueryProvider.notifier).state = '';

            ref.read(showMembersSheetProvider.notifier).state = false;
            ref.read(membersSearchQueryProvider.notifier).state = '';

            // ✅ NEW: labels sheet reset
            ref.read(showLabelsSheetProvider.notifier).state = false;
            ref.read(labelsSearchQueryProvider.notifier).state = '';

            Navigator.of(context).pop();
          },
          child: Text(
            'Reset'.tr,
            style: AppTextStyles.interMedium.copyWith(color: theme.textColor),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close'.tr,
            style: AppTextStyles.interMedium.copyWith(color: theme.textColor),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: elevatedButtonStyleRounded10.copyWith(
            backgroundColor: WidgetStatePropertyAll(theme.themeColor),
            foregroundColor: WidgetStatePropertyAll(theme.themeTextColor),
          ),
          onPressed: () {
            // ✅ Commit draft filters -> applied filters
            final draft = ref.read(taskFiltersProvider);
            ref.read(appliedTaskFiltersProvider.notifier).state = draft;

            // ✅ Fetch filtered tasks now (ONLY on apply)
            onApply?.call();

            Navigator.of(context).pop();
          },

          child: Text(
            'Apply'.tr,
            style: AppTextStyles.interMedium.copyWith(
              color: theme.themeTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
