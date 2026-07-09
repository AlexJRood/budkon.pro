// cloud/utils/pie_menu/pie_folders.dart

import 'dart:ui' as ui;

import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/pin/destination_dialog.dart';
import 'package:cloud/widgets/share_file_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/api/pie_onselect_api.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class ActionModel {
  final int id;
  ActionModel({required this.id});
}

List<PieAction> pieFolders(
  WidgetRef ref,
  dynamic action,
  BuildContext context,
) {
  final theme = ref.read(themeColorsProvider);

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
          await showCloudShortcutPinDialog(
            context: ctx,
            ref: ref,
            resourceType: 'folder',
            resourceId: action.id.toString(),
            label: action.name?.toString(),
            subtitle: 'Folder'.tr,
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
        'delete_folder'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: makePieOnSelect(
        ref: ref,
        context: context,
        requireLogin: true,
        confirmTitle: 'confirm'.tr,
        confirmMessage: 'delete_this_folder'.tr,
        api: PieApiCall(
          endpoint: 'https://www.superbee.cloud/storage/folders/${action.id}/',
          method: PieApiMethod.delete,
          hasToken: true,
        ),
        successSnack: 'folder_has_been_removed'.tr,
        errorSnack: 'error_while_deleting'.tr,
        afterSuccess: [
          (ref, ctx) async {
            ref.invalidate(cloudExplorerProvider);
            refreshCloudShortcuts(ref);
            final container = ProviderScope.containerOf(context, listen: false);

            refreshAllCloudDataFromContainer(container);

            final clientParams = ref.read(clientExplorerParamsProvider);
            ref.invalidate(clientFileExplorerProvider(clientParams));
          },
        ],
      ),
      child: AppIcons.delete(color: AppColors.white),
    ),


PieAction(
  tooltip: Text('edit_folder'.tr,
    style: TextStyle(color: theme.textColor),),
  onSelect: makePieOnSelect(
  ref: ref,
  context: context,
  requireLogin: true,
  preferPagePresentation: true,   // ← najbezpieczniej z PieMenu
  useRootNavigatorForDialogs: true,
  editFields: [ EditField(key: 'name', label: 'Folder name'.tr, initialValue: action.name) ],
  api: PieApiCall(
    endpoint: 'https://www.superbee.cloud/storage/folders/${action.id}/',
    method: PieApiMethod.patch,
    hasToken: true,
  ),
  mergeEditIntoApiData: true,
  // successSnack: 'folder_updated'.tr,
  // errorSnack: 'error_while_updating'.tr,
    afterSuccess: [
          (ref, ctx) async {
            final container = ProviderScope.containerOf(context, listen: false);

            refreshAllCloudDataFromContainer(container);
            refreshCloudShortcuts(ref);
        final clientParams = ref.read(clientExplorerParamsProvider);
        ref.invalidate(clientFileExplorerProvider(clientParams));
      },
    ],
),
child: AppIcons.pencil(color: AppColors.white),
),

    PieAction(
      tooltip: Text('share_folder'.tr,
        style: TextStyle(color: theme.textColor),),
      onSelect: makePieOnSelect(
        ref: ref,
        context: context,
        requireLogin: true,
        callback: (ref, ctx) async {
          await showDialog(
            context: ctx,
            builder: (_) => BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ShareFileDialog(
                    resourceId: action.id.toString(),
                    resourceName: action.name?.toString() ?? '',
                    resourceType: ShareResourceType.folder,
                    parentContext: ctx,
                  ),
                ),
              ),
            ),
          );

          return true;
        },
      ),
      child: const Icon(
        Icons.share_outlined,
        color: AppColors.white,
      ),
    ),
    ///////// Feature to finish in version 2.0 //////// 

    // PieAction(
    //   tooltip:
    //       isFavorite
    //           ? Text('Usuń z ulubionych'.tr)
    //           : Text('Dodaj do ulubionych'.tr),
    //   onSelect: () {
    //     handleFavoriteAction(ref, action, context);
    //   },
    //   child: FaIcon(
    //     isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
    //   ),
    // ),
    
    // PieAction(
    //   tooltip: Text('Edit folder'.tr),
    //   onSelect: () {
    //     handleHideAction(ref, action, context);
    //   },
    //   child: FaIcon(
    //     isHidden ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
    //   ),
    // ),


    

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