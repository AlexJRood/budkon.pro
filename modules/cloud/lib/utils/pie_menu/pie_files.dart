// cloud/utils/pie_menu/pie_files.dart

import 'dart:ui' as ui;

import 'package:cloud/models/file.dart';
import 'package:cloud/providers/bulk_download_provider.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/download/download_image.dart';
import 'package:cloud/widgets/share_file_dialog.dart';
import 'package:cloud/utils/pin/destination_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/api/pie_onselect_api.dart';
import 'package:core/platform/enum/cloud_item_ref.dart';
import 'package:core/platform/provider/cloud_selection_controller.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class ActionModel {
  final int id;
  ActionModel({required this.id});
}

List<PieAction> pieFiles(
  WidgetRef ref,
  dynamic action,
  BuildContext context,
) {
  final theme = ref.read(themeColorsProvider);
  final file = action as CloudFile;

  final selection = ref.read(cloudSelectionProvider);
  final selectedFileIds = selection.selectedFileIds.toList();
  final selectedFolderIds = selection.selectedFolderIds.toList();
  final selectedCount = selectedFileIds.length + selectedFolderIds.length;

  final clickedFileId = file.id.toString();
  final clickedIsInSelection = selectedFileIds.contains(clickedFileId);
  final isMultiDownload = selectedCount > 1 && clickedIsInSelection;

  return [
    PieAction(
      tooltip: Text(
        'Pin shortcut'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: makePieOnSelect(
        ref: ref,
        context: context,
        requireLogin: true,
        preferPagePresentation: false,
        useRootNavigatorForDialogs: true,
        callback: (ref, ctx) async {
          final file = action as CloudFile;

          await showCloudShortcutPinDialog(
            context: ctx,
            ref: ref,
            resourceType: 'file',
            resourceId: file.id.toString(),
            label: file.name,
            subtitle: file.extension.isNotEmpty
                ? file.extension.toUpperCase()
                : null,
          );
          return true;
        },
      ),
      child: const Icon(
        Icons.push_pin_rounded,
        color: AppColors.white,
      ),
    ),

    PieAction(
      tooltip: Text(
        isMultiDownload
            ? 'download_selected_images'.tr
            : 'download_image'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: makePieOnSelect(
        ref: ref,
        context: context,
        requireLogin: true,
        callback: (ref, ctx) async {
          if (isMultiDownload) {
            return await ref
                .read(bulkDownloadProvider.notifier)
                .downloadCurrentSelectionAsZip();
          }

          await downloadImageFile(file);
          return true;
        },
        successSnack: isMultiDownload
            ? 'selected_images_downloaded'.tr
            : 'image_downloaded'.tr,
      ),
      child: AppIcons.download(color: AppColors.white),
    ),

    PieAction(
      tooltip: Text(
        'select_file'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: makePieOnSelect(
        ref: ref,
        context: context,
        callback: (ref, ctx) async {
          final sel = ref.read(cloudSelectionProvider.notifier);

          sel.enterSelectionMode();

          sel.toggleItem(
            CloudItemRef(
              kind: CloudItemKind.file,
              id: action.id.toString(),
            ),
          );

          return true;
        },
      ),
      child: AppIcons.folder(color: AppColors.white),
    ),

    PieAction(
      tooltip: Text(
        'delete_file'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: makePieOnSelect(
        ref: ref,
        context: context,
        requireLogin: true,
        confirmTitle: 'confirm'.tr,
        confirmMessage: 'are_you_sure_remove_this_file'.tr,
        api: PieApiCall(
          endpoint: 'https://www.superbee.cloud/storage/files/${action.id}/',
          method: PieApiMethod.delete,
          hasToken: true,
        ),
        successSnack: 'file_has_been_removed'.tr,
        errorSnack: 'error_while_removing_file'.tr,
        afterSuccess: [
              (ref, ctx) async {
            ref.invalidate(cloudExplorerProvider);

            final clientParams = ref.read(clientExplorerParamsProvider);
            ref.invalidate(clientFileExplorerProvider(clientParams));
            refreshCloudShortcuts(ref);
            ref.invalidate(cloudSidebarProvider);
          },
        ],
      ),
      child: AppIcons.delete(color: AppColors.white),
    ),

    PieAction(
      tooltip: Text(
        'share_file'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: makePieOnSelect(
        ref: ref,
        context: context,
        requireLogin: true,
        callback: (ref, ctx) async {
          final file = action as CloudFile;
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) {
              return BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ShareFileDialog(
                      resourceId: file.id.toString(),
                      resourceName: file.name,
                      resourceType: ShareResourceType.file,
                      parentContext: ctx,
                    )
                  ),
                ),
              );
            },
          );

          return true;
        },
      ),
      child: Icon(
        Icons.share_outlined,
        color: AppColors.white,
      ),
    ),
  ];
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}