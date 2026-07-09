import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';

class FilterSectionTitle extends StatelessWidget {
  final dynamic theme;
  final String title;

  const FilterSectionTitle({
    super.key,
    required this.theme,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FilterNameSection extends ConsumerWidget {
  final dynamic theme;
  final TextEditingController nameCtrl;

  const FilterNameSection({
    super.key,
    required this.theme,
    required this.nameCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionTitle(theme: theme, title: 'Name (contains)'.tr),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtrl,
          onChanged: (v) => ref.read(taskFiltersProvider.notifier).setName(v),
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            hintText: 'Type task name...'.tr,
            hintStyle: TextStyle(
              color: theme.textColor.withAlpha((255 * 0.5).toInt()),
            ),
            filled: true,
            fillColor: theme.popupcontainercolor.withAlpha(
              (255 * 0.25).toInt(),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.textColor.withAlpha((255 * 0.12).toInt()),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.textColor.withAlpha((255 * 0.35).toInt()),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}
