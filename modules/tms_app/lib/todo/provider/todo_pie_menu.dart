// tms_app/todo/provider/todo_pie_menu.dart


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:http/http.dart' as http;
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/models/get_user_board_model.dart';


List<PieAction> buildPieMenuActionsTodo(
  BuildContext context,
  WidgetRef ref,
  String boardId,
  ThemeColors theme
) {
  return [
    PieAction(
      tooltip:  Text('Edit board'.tr,style: TextStyle(color: theme.textColor),),
      onSelect: () async {
        final board = ref
            .read(boardManagementProvider)
            .results
            ?.firstWhere((b) => b.id.toString() == boardId);
        if (board == null) return;

        final boardNameController = TextEditingController(text: board.name);
        ref.read(boardEditImageProvider.notifier).state = null;
        ref.read(boardEditChangedProvider.notifier).state = false;
        ref.read(boardEditLoadingProvider.notifier).state = false;

        // Download current avatar if it's a URL
        if (board.avatar != null &&
            board.avatar is String &&
            board.avatar!.startsWith('http')) {
          try {
            final response = await http.get(Uri.parse(board.avatar!));
            if (response.statusCode == 200) {
              ref.read(boardEditImageProvider.notifier).state =
                  response.bodyBytes;
            }
          } catch (e) {
            debugPrint('⚠️ Failed to load avatar image: $e');
          }
        }

        final confirmed = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: !ref.read(boardEditLoadingProvider),
          barrierLabel: 'Edit board',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (context, anim, __, child) {
            final isLoading = ref.watch(boardEditLoadingProvider);
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutBack,
                  ),
                  child: PopScope(
                    canPop: !isLoading,
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isLoading = ref.watch(boardEditLoadingProvider);
                          final selectedImageBytes = ref.watch(
                            boardEditImageProvider,
                          );
                          final hasChanged = ref.watch(boardEditChangedProvider);
                          final theme = ref.watch(themeColorsProvider);
                          return Container(
                            width:
                                MediaQuery.of(context).size.width > 640
                                    ? 600
                                    : MediaQuery.of(context).size.width * 0.9,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.popupcontainercolor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Edit board'.tr,
                                  style:  TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 75,
                                    );
                                    if (pickedFile != null) {
                                      final bytes =
                                          await pickedFile.readAsBytes();
                                      ref
                                          .read(boardEditImageProvider.notifier)
                                          .state = bytes;
                                      ref
                                          .read(boardEditChangedProvider.notifier)
                                          .state = true;
                                    }
                                  },
                                  child: Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white38),
                                    ),
                                    child:
                                        selectedImageBytes != null
                                            ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.memory(
                                                selectedImageBytes,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : const Center(
                                              child: Icon(
                                                Icons.add_a_photo,
                                                color: Colors.white70,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: boardNameController,
                                  onChanged:
                                      (val) =>
                                          ref
                                              .read(
                                                boardEditChangedProvider.notifier,
                                              )
                                              .state = val.trim() != board.name,
                                  style:  TextStyle(color: theme.textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Board name',
                                    hintStyle:  TextStyle(
                                      color: theme.textColor,
                                    ),
                                    filled: true,
                                    fillColor: theme.textFieldColor,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white38,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side:  BorderSide(
                                          color: theme.bordercolor ,
                                        ),
                                      ),
                                      onPressed:
                                          () {
                                        ref.read(boardEditLoadingProvider.notifier).state = false;
                                        Navigator.of(context).pop(false);
                                        },
                                      child: Text('Anuluj'.tr,
                                      style: TextStyle(
                                        color: theme.textColor
                                      ),),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.themeColor,
                                      ),
                                      onPressed: hasChanged && !isLoading
                                          ? () async {
                                        final newName = boardNameController.text.trim();

                                        if (newName.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please enter a board name')),
                                          );
                                          return;
                                        }

                                        ref.read(boardEditLoadingProvider.notifier).state = true;

                                        try {
                                          await ref
                                              .read(boardManagementProvider.notifier)
                                              .editBoard(
                                            boardId,
                                            newName,
                                            selectedImageBytes,
                                          );

                                          await ref
                                              .read(boardManagementProvider.notifier)
                                              .fetchBoards(ref);

                                          ref.read(boardsOrderProvider.notifier).state =
                                          List<BoardResults>.of(
                                            ref.read(boardManagementProvider).results ?? [],
                                          );

                                          if (context.mounted) {
                                            Navigator.of(context).pop(true);
                                          }
                                        } finally {
                                          ref.read(boardEditLoadingProvider.notifier).state = false;
                                        }
                                      }
                                          : null,
                                      child: isLoading
                                          ? SizedBox(
                                        height: 40,
                                        width: 70,
                                        child: AppLottie.loading()
                                      )
                                          : Text(
                                        'Confirm'.tr,
                                        style: TextStyle(
                                          color: hasChanged
                                              ? theme.themeTextColor
                                              : theme.textColor,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );

        if (confirmed == true) {
          context.showSnackBarLikeSection('Board updated');
        }
        ref.read(boardEditImageProvider.notifier).state = null;
        ref.read(boardEditChangedProvider.notifier).state = false;
        ref.read(boardEditLoadingProvider.notifier).state = false;
      },
      child: AppIcons.pencil(color: theme.themeTextColor),
    ),
    PieAction(tooltip: Text('Delete Board'.tr,style: TextStyle(color: theme.textColor),),
        onSelect: () async {
          final messenger = ScaffoldMessenger.of(context);

          final board = ref
              .read(boardManagementProvider)
              .results
              ?.firstWhere((b) => b.id.toString() == boardId);

          if (board == null) return;

          final confirmed = await showGeneralDialog<bool>(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Delete Board'.tr,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => const SizedBox.shrink(),
            transitionBuilder: (context, anim, __, child) {
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutBack,
                    ),
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final theme = ref.watch(themeColorsProvider);

                          return Container(
                            width: MediaQuery.of(context).size.width > 640
                                ? 600
                                : MediaQuery.of(context).size.width * 0.9,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.popupcontainercolor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Delete Board'.tr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${"Are you sure you want to delete".tr} "${board.name ?? 'this board'.tr}"?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: theme.bordercolor,
                                        ),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'Anuluj'.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.themeColor,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(boardManagementProvider.notifier)
                                            .deleteBoard(boardId,ref);
                                        if (context.mounted) {
                                          Navigator.of(context).pop(true);
                                        }
                                      },
                                      child: Text(
                                        'Confirm'.tr,
                                        style: TextStyle(
                                          color: theme.dashboardContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );

          if (confirmed == true) {
            messenger
              ..removeCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Board deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
          }
        },
        child: AppIcons.delete(color: theme.themeTextColor))
  ];
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
