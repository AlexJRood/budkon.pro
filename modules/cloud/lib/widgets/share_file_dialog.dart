import 'package:cloud/models/file_share_model.dart';
import 'package:cloud/providers/share_targets_provider.dart';
import 'package:cloud/providers/shared_files_provider.dart';
import 'package:cloud/widgets/share_file_dialog_step_two.dart';
import 'package:cloud/widgets/shared_file_dialog_step_one.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

enum ShareResourceType {
  file,
  folder,
}

class ShareFileDialog extends ConsumerStatefulWidget {
  final String resourceId;
  final String resourceName;
  final ShareResourceType resourceType;
  final BuildContext parentContext;
  final bool isEditMode;
  final String? shareId;
  final bool? initialCanEdit;
  final String? initialNote;
  final DateTime? initialExpiresAt;
  final String? resourceUrl;
  final String? mimeType;
  final String? fileType;
  final bool isPreviewFile;

  const ShareFileDialog({
    super.key,
    required this.resourceId,
    required this.resourceName,
    required this.resourceType,
    required this.parentContext,
    this.isEditMode = false,
    this.shareId,
    this.initialCanEdit,
    this.initialNote,
    this.initialExpiresAt,
    this.resourceUrl,
    this.mimeType,
    this.fileType,
    this.isPreviewFile = false,
  });

  @override
  ConsumerState<ShareFileDialog> createState() => _ShareFileDialogState();
}

class _ShareFileDialogState extends ConsumerState<ShareFileDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shareUsersProvider.notifier).fetch();

      if (widget.isEditMode) {
        ref.read(sharedFilesProvider.notifier).resetDialogState();
        ref.read(shareDialogCanEditProvider.notifier).state =
            widget.initialCanEdit ?? false;
        ref.read(shareDialogNoteProvider.notifier).state =
            widget.initialNote ?? '';
        ref.read(shareDialogExpiresAtProvider.notifier).state =
            widget.initialExpiresAt;
      }
    });
  }

  String _targetTypeLabel(ShareTargetType type) {
    switch (type) {
      case ShareTargetType.user:
        return 'User'.tr;
      case ShareTargetType.company:
        return 'Company'.tr;
      case ShareTargetType.team:
        return 'Team'.tr;
      case ShareTargetType.email:
        return 'Email'.tr;
    }
  }

  List<ShareTargetOption> _filteredItems(
      List<ShareTargetOption> items,
      String query,
      ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) => item.label.toLowerCase().contains(q)).toList();
  }

  String? _selectedLabel(List<ShareTargetOption> items, String? selectedId) {
    for (final item in items) {
      if (item.id == selectedId) return item.label;
    }
    return null;
  }

  void _showError(String text) {
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void _goToStepTwo() {
    if (widget.isEditMode) {
      ref.read(shareDialogStepProvider.notifier).state = 2;
      return;
    }

    final targetType = ref.read(shareDialogTargetTypeProvider);
    final selectedId = ref.read(shareDialogSelectedOptionIdProvider);
    final email = ref.read(shareDialogEmailProvider);

    if (targetType == ShareTargetType.email) {
      if (email.trim().isEmpty) {
        _showError('Please enter email'.tr);
        return;
      }
    } else {
      if (selectedId == null) {
        _showError(
          '${"Please select".tr} ${_targetTypeLabel(targetType).toLowerCase()}',
        );
        return;
      }
    }

    ref.read(shareDialogStepProvider.notifier).state = 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final targetType = ref.watch(shareDialogTargetTypeProvider);
    final selectedOptionId = ref.watch(shareDialogSelectedOptionIdProvider);
    final searchQuery = ref.watch(shareDialogSearchQueryProvider);
    final showInlinePicker = ref.watch(shareDialogInlinePickerOpenProvider);

    final usersState = ref.watch(shareUsersProvider);
    final companiesState = ref.watch(shareCompaniesProvider);
    final teamsState = ref.watch(shareTeamsProvider);

    final activeState = switch (targetType) {
      ShareTargetType.user => usersState,
      ShareTargetType.company => companiesState,
      ShareTargetType.team => teamsState,
      ShareTargetType.email => null,
    };

    final items = activeState?.items ?? const <ShareTargetOption>[];
    final filteredItems = _filteredItems(items, searchQuery);
    final selectedLabel = _selectedLabel(items, selectedOptionId);

    final step = ref.watch(shareDialogStepProvider);
    final canEdit = ref.watch(shareDialogCanEditProvider);
    final note = ref.watch(shareDialogNoteProvider);
    final expiresAt = ref.watch(shareDialogExpiresAtProvider);
    final isSubmitting = ref.watch(shareDialogSubmitLoadingProvider);
    final submitError = ref.watch(shareDialogSubmitErrorProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(sharedFilesProvider.notifier).resetDialogState();
          });
        }
      },
      child: Dialog(
        backgroundColor: theme.popupcontainercolor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dashboardBoarder, width: 1.2),
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                offset: Offset(0, 10),
                color: Colors.black26,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: step == 1
                ? SharedFileDialogStepOne(
              theme: theme,
              targetType: targetType,
              activeState: activeState,
              items: items,
              filteredItems: filteredItems,
              selectedLabel: selectedLabel,
              showInlinePicker: showInlinePicker,
              resourceName: widget.resourceName,
              resourceType: widget.resourceType,
              goToStepTwo: _goToStepTwo,
              isEditMode: widget.isEditMode,
              resourceUrl: widget.resourceUrl,
              mimeType: widget.mimeType,
              fileType: widget.fileType,
              isPreviewFile: widget.isPreviewFile, // ✅ add this
            )
                : ShareFileDialogStepTwo(
              theme: theme,
              canEdit: canEdit,
              note: note,
              expiresAt: expiresAt,
              isSubmitting: isSubmitting,
              submitError: submitError,
              resourceId: widget.resourceId,
              resourceType: widget.resourceType,
              parentContext: widget.parentContext,
              isEditMode: widget.isEditMode,
              shareId: widget.shareId,
            ),
          ),
        ),
      ),
    );
  }
}