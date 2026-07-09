import 'package:cloud/providers/shared_files_provider.dart';
import 'package:cloud/widgets/share_file_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

class ShareFileDialogStepTwo extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final bool canEdit;
  final String note;
  final DateTime? expiresAt;
  final bool isSubmitting;
  final String? submitError;
  final BuildContext parentContext;
  final String resourceId;
  final ShareResourceType resourceType;
  final bool isEditMode;
  final String? shareId;

  const ShareFileDialogStepTwo({
    super.key,
    required this.canEdit,
    required this.expiresAt,
    required this.isSubmitting,
    required this.note,
    required this.submitError,
    required this.theme,
    required this.parentContext,
    required this.resourceId,
    required this.resourceType,
    this.isEditMode = false,
    this.shareId,
  });

  @override
  ConsumerState<ShareFileDialogStepTwo> createState() =>
      _ShareFileDialogStepTwoState();
}

class _ShareFileDialogStepTwoState
    extends ConsumerState<ShareFileDialogStepTwo> {
  InputDecoration _inputDecoration(ThemeColors theme, String label) {
    return InputDecoration(
      label: Text(
        label,
        style: TextStyle(color: theme.textColor.withAlpha(180)),
      ),
      labelStyle: TextStyle(color: theme.textColor.withAlpha(180)),
      filled: true,
      fillColor: theme.adPopBackground.withAlpha(120),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dashboardBoarder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dashboardBoarder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.themeColor, width: 1.4),
      ),
    );
  }

  Future<DateTime?> _pickStyledDate({
    required BuildContext context,
    required ThemeColors theme,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDatePicker(
      useRootNavigator: true,
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      confirmText: 'OK'.tr,
      cancelText: 'Cancel'.tr,
      helpText: 'Choose date'.tr,
      fieldHintText: 'dd.MM.yyyy'.tr,
      fieldLabelText: 'Enter date'.tr,
      builder: (context, child) {
        final base = Theme.of(context);
        final isDark = base.brightness == Brightness.dark;

        final scheme = (isDark
            ? const ColorScheme.dark()
            : const ColorScheme.light())
            .copyWith(
          primary: theme.themeColor,
          onPrimary: theme.themeTextColor,
          surface: theme.adPopBackground,
          onSurface: theme.textColor,
        );

        return Theme(
          data: base.copyWith(
            colorScheme: scheme,
            dialogTheme: DialogThemeData(
              backgroundColor: theme.adPopBackground,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: theme.textFieldColor,
              hintStyle: TextStyle(color: theme.textColor.withOpacity(0.7)),
              labelStyle: TextStyle(color: theme.textColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.themeColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.themeColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.themeColor, width: 2),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: theme.adPopBackground,
              headerBackgroundColor: theme.themeColor,
              headerForegroundColor: theme.themeTextColor,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? theme.themeTextColor
                    : theme.textColor;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? theme.themeColor
                    : Colors.transparent;
              }),
              todayBorder: BorderSide(color: theme.themeColor),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? theme.themeTextColor
                    : theme.textColor;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? theme.themeColor
                    : Colors.transparent;
              }),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: theme.themeColor,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: theme.themeColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: theme.themeColor),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _goBackToStepOne() {
    ref.read(shareDialogStepProvider.notifier).state = 1;
  }

  String _shareButtonText() {
    return widget.isEditMode ? 'Save changes'.tr : 'Share'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final canEdit = ref.watch(shareDialogCanEditProvider);
    final note = ref.watch(shareDialogNoteProvider);
    final expiresAt = ref.watch(shareDialogExpiresAtProvider);
    final isSubmitting = ref.watch(shareDialogSubmitLoadingProvider);
    final submitError = ref.watch(shareDialogSubmitErrorProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditMode ? 'Edit share settings'.tr : 'Share settings'.tr,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          activeTrackColor: theme.themeColor,
          contentPadding: EdgeInsets.zero,
          value: canEdit,
          onChanged: (value) {
            ref.read(shareDialogCanEditProvider.notifier).state = value;
          },
          title: Text('Can edit'.tr, style: TextStyle(color: theme.textColor)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          cursorColor: theme.textColor,
          initialValue: note,
          style: TextStyle(color: theme.textColor),
          onChanged: (value) {
            ref.read(shareDialogNoteProvider.notifier).state = value;
          },
          maxLines: 3,
          decoration: _inputDecoration(theme, 'Note'.tr),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await _pickStyledDate(
              context: context,
              theme: theme,
              initialDate:
              expiresAt ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );

            if (picked != null) {
              ref.read(shareDialogExpiresAtProvider.notifier).state = picked;
            }
          },
          child: InputDecorator(
            decoration: _inputDecoration(theme, 'Expires at'.tr).copyWith(
              suffixIcon: Icon(Icons.calendar_today, color: theme.textColor),
            ),
            child: Text(
              expiresAt == null
                  ? 'No expiration'.tr
                  : '${expiresAt.year}-${expiresAt.month.toString().padLeft(2, '0')}-${expiresAt.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: expiresAt == null
                    ? theme.textColor.withAlpha(140)
                    : theme.textColor,
              ),
            ),
          ),
        ),
        if (submitError != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(
              submitError,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isSubmitting ? null : _goBackToStepOne,
              child: Text(
                'Back'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: buttonStyleRounded10ThemeRed,
              onPressed: isSubmitting
                  ? null
                  : () {
                if (widget.isEditMode) {
                  ref.read(sharedFilesProvider.notifier).updateShare(
                    context: context,
                    shareId: widget.shareId!,
                    resourceType: widget.resourceType,
                    parentContext: widget.parentContext,
                  );
                } else {
                  ref.read(sharedFilesProvider.notifier).submitShare(
                    context: context,
                    resourceId: widget.resourceId,
                    resourceType: widget.resourceType,
                    parentContext: widget.parentContext,
                  );
                }
              },
              child: isSubmitting
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: SizedBox(
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.textColor,
                  ),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  _shareButtonText(),
                  style: TextStyle(color: theme.themeTextColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}