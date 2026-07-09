import 'package:cloud/models/file_share_model.dart';
import 'package:cloud/providers/share_targets_provider.dart';
import 'package:cloud/providers/shared_files_provider.dart';
import 'package:cloud/widgets/share_file_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

class SharedFileDialogStepOne extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final ShareTargetType targetType;
  final ShareTargetState? activeState;
  final List<ShareTargetOption> items;
  final List<ShareTargetOption> filteredItems;
  final String? selectedLabel;
  final bool showInlinePicker;
  final String resourceName;
  final ShareResourceType resourceType;
  final void Function()? goToStepTwo;
  final bool isEditMode;
  final String? resourceUrl;
  final String? mimeType;
  final String? fileType;
  final bool isPreviewFile;

  const SharedFileDialogStepOne({
    super.key,
    required this.theme,
    required this.targetType,
    required this.activeState,
    required this.items,
    required this.filteredItems,
    required this.selectedLabel,
    required this.showInlinePicker,
    required this.resourceName,
    required this.resourceType,
    required this.goToStepTwo,
    this.isEditMode = false,
    this.resourceUrl,
    this.mimeType,
    this.fileType,
    this.isPreviewFile = false,
  });

  @override
  ConsumerState<SharedFileDialogStepOne> createState() =>
      _SharedFileDialogStepOneState();
}

class _SharedFileDialogStepOneState
    extends ConsumerState<SharedFileDialogStepOne> {
  InputDecoration inputDecoration(ThemeColors theme, String label) {
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

  String _dialogTitle() {
    if (widget.isEditMode) return 'Edit share'.tr;
    return widget.resourceType == ShareResourceType.file
        ? 'Share file'.tr
        : 'Share folder'.tr;
  }

  String _resourceLabel() {
    return widget.resourceType == ShareResourceType.file
        ? 'File'.tr
        : 'Folder'.tr;
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

  void _changeTargetType(ShareTargetType value) {
    ref.read(shareDialogTargetTypeProvider.notifier).state = value;
    ref.read(shareDialogSelectedOptionIdProvider.notifier).state = null;
    ref.read(shareDialogEmailProvider.notifier).state = '';
    ref.read(shareDialogSearchQueryProvider.notifier).state = '';
    ref.read(shareDialogInlinePickerOpenProvider.notifier).state = false;

    switch (value) {
      case ShareTargetType.user:
        ref.read(shareUsersProvider.notifier).fetch();
        break;
      case ShareTargetType.company:
        ref.read(shareCompaniesProvider.notifier).fetch();
        break;
      case ShareTargetType.team:
        ref.read(shareTeamsProvider.notifier).fetch();
        break;
      case ShareTargetType.email:
        break;
    }
  }

  String _emptyStateText(ShareTargetType type) {
    switch (type) {
      case ShareTargetType.team:
        return 'No teams available. You are not part of any team yet.'.tr;
      case ShareTargetType.company:
        return 'No companies available.'.tr;
      case ShareTargetType.user:
        return 'No users available.'.tr;
      case ShareTargetType.email:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(shareDialogEmailProvider);
    final searchQuery = ref.watch(shareDialogSearchQueryProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dialogTitle(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: widget.theme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.theme.adPopBackground.withAlpha(120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.dashboardBoarder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_resourceLabel()}: ${widget.resourceName}',
                style: TextStyle(
                  color: widget.theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.isEditMode) ...[
                const SizedBox(height: 14),
                _largeResourcePreview(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (!widget.isEditMode) ...[
          DropdownButtonFormField<ShareTargetType>(
            initialValue: widget.targetType,
            decoration: inputDecoration(widget.theme, 'Target type'.tr),
            dropdownColor: widget.theme.dashboardContainer,
            style: TextStyle(color: widget.theme.textColor),
            items: [
              DropdownMenuItem(
                value: ShareTargetType.user,
                child: Text('User'.tr),
              ),
              DropdownMenuItem(
                value: ShareTargetType.company,
                child: Text('Company'.tr),
              ),
              DropdownMenuItem(
                value: ShareTargetType.team,
                child: Text('Team'.tr),
              ),
              DropdownMenuItem(
                value: ShareTargetType.email,
                child: Text('Email'.tr),
              ),
            ],
            onChanged: (value) {
              if (value != null) _changeTargetType(value);
            },
          ),

          const SizedBox(height: 16),

          if (widget.targetType == ShareTargetType.email)
            TextFormField(
              key: const ValueKey('share-email'),
              initialValue: email,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: widget.theme.textColor),
              onChanged: (value) {
                ref.read(shareDialogEmailProvider.notifier).state = value;
              },
              decoration: inputDecoration(widget.theme, 'Email'.tr).copyWith(
                hintText: 'client@example.com',
                hintStyle: TextStyle(
                  color: widget.theme.textColor.withAlpha(120),
                ),
              ),
            )
          else if (widget.activeState != null && widget.activeState!.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.activeState != null && widget.activeState?.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(
                  '${widget.activeState?.error!}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            else if (widget.activeState != null && widget.activeState!.items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.theme.adPopBackground.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.theme.dashboardBoarder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: widget.theme.textColor.withAlpha(180),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _emptyStateText(widget.targetType),
                          style: TextStyle(
                            color: widget.theme.textColor.withAlpha(180),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final current =
                        ref.read(shareDialogInlinePickerOpenProvider);

                        ref
                            .read(shareDialogInlinePickerOpenProvider.notifier)
                            .state = !current;

                        if (current == true) {
                          ref.read(shareDialogSearchQueryProvider.notifier).state = '';
                        }
                      },
                      child: InputDecorator(
                        decoration: inputDecoration(
                          widget.theme,
                          _targetTypeLabel(widget.targetType),
                        ).copyWith(
                          suffixIcon: Icon(
                            widget.showInlinePicker
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: widget.theme.textColor,
                          ),
                        ),
                        child: Text(
                          widget.selectedLabel ??
                              '${"Select".tr} ${_targetTypeLabel(widget.targetType).toLowerCase()}',
                          style: TextStyle(
                            color: widget.selectedLabel != null
                                ? widget.theme.textColor
                                : widget.theme.textColor.withAlpha(140),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),

                    if (widget.showInlinePicker) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.theme.adPopBackground.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.theme.dashboardBoarder),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              key: ValueKey('share-search-${widget.targetType.name}'),
                              initialValue: searchQuery,
                              style: TextStyle(color: widget.theme.textColor),
                              onChanged: (value) {
                                ref
                                    .read(shareDialogSearchQueryProvider.notifier)
                                    .state = value;
                              },
                              decoration: inputDecoration(
                                widget.theme,
                                'Search'.tr,
                              ).copyWith(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: widget.theme.textColor.withAlpha(170),
                                ),
                                isDense: true,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              constraints: const BoxConstraints(maxHeight: 220),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: widget.theme.dashboardBoarder,
                                ),
                              ),
                              child: widget.filteredItems.isEmpty
                                  ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No results found'.tr,
                                    style: TextStyle(
                                      color: widget.theme.textColor,
                                    ),
                                  ),
                                ),
                              )
                                  : ListView.separated(
                                shrinkWrap: true,
                                itemCount: widget.filteredItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: widget.theme.dashboardBoarder,
                                ),
                                itemBuilder: (context, index) {
                                  final item = widget.filteredItems[index];

                                  final isSelected = item.id ==
                                      ref.watch(
                                        shareDialogSelectedOptionIdProvider,
                                      );

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        ref
                                            .read(
                                          shareDialogSelectedOptionIdProvider
                                              .notifier,
                                        )
                                            .state = item.id;

                                        ref
                                            .read(
                                          shareDialogInlinePickerOpenProvider
                                              .notifier,
                                        )
                                            .state = false;

                                        ref
                                            .read(
                                          shareDialogSearchQueryProvider.notifier,
                                        )
                                            .state = '';
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.label,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.blueAccent
                                                      : widget.theme.textColor,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.blueAccent,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                ref.read(sharedFilesProvider.notifier).resetDialogState();
                Navigator.of(context).pop();
              },
              child: Text(
                'Close'.tr,
                style: TextStyle(
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: buttonStyleRounded10ThemeRed,
              onPressed: widget.goToStepTwo,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'Next'.tr,
                  style: TextStyle(color: widget.theme.themeTextColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _largeResourcePreview() {
    final mime = (widget.mimeType ?? '').toLowerCase();
    final type = (widget.fileType ?? '').toLowerCase();

    if (widget.resourceType == ShareResourceType.folder && !widget.isPreviewFile) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.theme.dashboardBoarder),
        ),
        child: Icon(Icons.folder_open, size: 90, color: widget.theme.themeColor),
      );
    }

    if (
        widget.resourceUrl != null &&
        widget.resourceUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          widget.resourceUrl!,
          height: 260,
          width: double.infinity,
          fit: BoxFit.contain,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, error, stackTrace) {
            debugPrint('IMAGE LOAD ERROR => $error');
            return _genericLargeFileIcon();
          },
        )
      );
    }

    return _genericLargeFileIcon();
  }

  Widget _genericLargeFileIcon() {
    final mime = (widget.mimeType ?? '').toLowerCase();

    final icon = mime.contains('pdf')
        ? Icons.picture_as_pdf_outlined
        : mime.startsWith('video/')
        ? Icons.video_file_outlined
        : Icons.insert_drive_file_outlined;

    return Container(
      height: 220,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.dashboardBoarder),
      ),
      child: Icon(icon, size: 90, color: widget.theme.themeColor),
    );
  }
}