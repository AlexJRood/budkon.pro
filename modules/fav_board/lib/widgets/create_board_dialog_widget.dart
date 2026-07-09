import 'package:fav_board/models/portal_fav_board_model.dart';
import 'package:fav_board/providers/network_board_provider.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:fav_board/widgets/labelled_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'client_list_widget.dart';

import 'package:get/get_utils/get_utils.dart';

class CreateBoardDialog extends ConsumerStatefulWidget {
  final bool isEdit;
  final String? boardUrl;
  final Board? boardDetails;
  final bool isMobile;

  const CreateBoardDialog({
    super.key,
    this.isEdit = false,
    this.boardUrl,
    this.boardDetails,
    this.isMobile = false,
  });

  @override
  ConsumerState<CreateBoardDialog> createState() => _CreateBoardDialogState();
}

class _CreateBoardDialogState extends ConsumerState<CreateBoardDialog> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController searchController;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text:
          widget.isEdit && widget.boardDetails != null
              ? widget.boardDetails!.title
              : '',
    );
    descriptionController = TextEditingController(
      text:
          widget.isEdit && widget.boardDetails != null
              ? widget.boardDetails!.description ?? ''
              : '',
    );
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(portalBoardsProvider.notifier).isLoading;
    final selectedTabIndex = ref.watch(selectedTabProvider);
    final theme = ref.read(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      width: 615.w,
      height: 526.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEdit ? 'Edit your board'.tr : 'Create board'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: AppIcons.close(color: theme.textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelledFieldWidget(
                      label: 'Board Name'.tr,
                      controller: nameController,
                      hint: 'Name'.tr,
                    ),
                    const SizedBox(height: 25),
                    if (widget.isEdit)
                      LabelledFieldWidget(
                        label: 'Description'.tr,
                        controller: descriptionController,
                        hint: "What's your board about?".tr,
                      ),
                    if (widget.isEdit && widget.boardUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite collaborators'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.textFieldColor.withAlpha(
                                        (255 * 0.4).toInt(),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.boardUrl!,
                                      style: TextStyle(
                                        color: theme.textColor.withAlpha(
                                          (255 * 0.6).toInt(),
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      87,
                                      148,
                                      221,
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: AppIcons.copy(
                                    color: Color.fromRGBO(161, 236, 230, 1),
                                    height: 18.h,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 25),
                    LabelledFieldWidget(
                      label: 'Search...'.tr,
                      controller: searchController,
                      hint: 'Search...'.tr,
                      prefixIcon: AppIcons.search(
                        color: theme.textColor,
                        height: 24.h,
                        width: 24.h,
                      ),
                      onChanged:
                          (value) => ref
                              .read(clientProvider.notifier)
                              .fetchClients(searchQuery: value),
                      onSubmitted:
                          (value) => ref
                              .read(clientProvider.notifier)
                              .fetchClients(searchQuery: value),
                    ),
                    const SizedBox(height: 16),
                    ClientList(scrollController: null, isEdit: widget.isEdit),
                    if (widget.isEdit) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Action'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 13.sp,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (selectedTabIndex == 0) {
                            if (widget.boardDetails?.id != null) {
                              await ref
                                  .read(portalBoardsProvider.notifier)
                                  .deleteBoard('${widget.boardDetails?.id}')
                                  .whenComplete(() {
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  });
                            }
                          } else {
                            await ref
                                .read(networkBoardsProvider.notifier)
                                .deleteBoard('${widget.boardDetails?.id}')
                                .whenComplete(() {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(87, 148, 221, 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Delete board'.tr,
                              style: TextStyle(
                                color: Color.fromRGBO(161, 236, 230, 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (selectedTabIndex == 0) {
                    if (widget.isEdit) {
                      await ref
                          .read(portalBoardsProvider.notifier)
                          .editBoard(
                            '${widget.boardDetails?.id}',
                            nameController.text,
                            descriptionController.text,
                            widget.boardDetails!.boardIndex!,
                          )
                          .whenComplete(() {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          });
                    } else {
                      await ref
                          .read(portalBoardsProvider.notifier)
                          .createBoard(nameController.text)
                          .whenComplete(() {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          });
                    }
                  } else {
                    if (widget.isEdit) {
                      await ref
                          .read(networkBoardsProvider.notifier)
                          .editBoard(
                            '${widget.boardDetails?.id}',
                            nameController.text,
                            descriptionController.text,
                            widget.boardDetails!.boardIndex!,
                          )
                          .whenComplete(() {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          });
                    } else {
                      await ref
                          .read(networkBoardsProvider.notifier)
                          .createBoard(nameController.text)
                          .whenComplete(() {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.themeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child:
                      isLoading
                          ?  SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2,color: theme.themeTextColor,),
                          )
                          : Text(
                            widget.isEdit ? 'Done'.tr : 'Create'.tr,
                            style: TextStyle(color: theme.themeTextColor),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
