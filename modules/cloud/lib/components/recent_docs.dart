import 'package:cloud/models/cloud_drag_payload.dart';
import 'package:cloud/utils/pie_menu/pie_files.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud/models/file.dart';
import 'package:cloud/widgets/file_viewer.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/enum/cloud_item_ref.dart';
import 'package:core/platform/provider/cloud_selection_controller.dart';
import 'package:core/theme/apptheme.dart';
import 'package:cloud/providers/providers.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/lottie.dart';
import 'package:flutter/services.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';


class RecentDocumentsTable extends ConsumerStatefulWidget {
  final bool isMobile;
  const RecentDocumentsTable({super.key, this.isMobile = false});

  @override
  ConsumerState<RecentDocumentsTable> createState() => _RecentDocumentsTableState();
}

class _RecentDocumentsTableState extends ConsumerState<RecentDocumentsTable> {
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  bool get isMobile => widget.isMobile;

  @override
  Widget build(BuildContext context) {
    final explorerAsync = ref.watch(cloudExplorerProvider);
    final theme = ref.read(themeColorsProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(color: theme.dashboardBoarder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Card(
        color: theme.dashboardContainer,
        elevation: 2,
        margin: EdgeInsets.zero,
        child: explorerAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: AppLottie.loading(size: 450)),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '${'Error loading files:'.tr}$err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          data: (explorer) {
            final allFiles = explorer.files;
            final files = allFiles.take(_visibleCount).toList();
            final hasMore = _visibleCount < allFiles.length;

            // ✅ selection state
            final selState = ref.watch(cloudSelectionProvider);
            final sel = ref.read(cloudSelectionProvider.notifier);

            final selectedCount =
                selState.selectedFileIds.length + selState.selectedFolderIds.length;

            // ✅ show top bar when in selection mode
            final showSelectionTopBar = selState.selectionMode;

            // ✅ show checkboxes when selection mode OR something selected
            final showCheckboxes = selState.selectionMode || selectedCount > 0;
            final selectionModeActive = selState.selectionMode || selectedCount > 0;
            final table = DataTable(
              columnSpacing: 8,       // 🔥 reduce space BETWEEN columns
              horizontalMargin: 8,
              headingRowColor: WidgetStateProperty.all(theme.dashboardContainer),
              columns: [

                DataColumn(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Checkbox(
                          value: selectionModeActive,
                          activeColor: theme.themeColor,
                          checkColor: theme.themeTextColor,
                          side: BorderSide(color: theme.textColor),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (value) {
                            if (value == true) {
                              ref.read(cloudSelectionProvider.notifier).enterSelectionMode();
                            } else {
                              ref.read(cloudSelectionProvider.notifier).exitSelectionMode();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("File name".tr, style: TextStyle(color: theme.textColor)),
                    ],
                  ),
                ),
                DataColumn(
                  label: Text("Submission date".tr, style: TextStyle(color: theme.textColor)),
                ),
                DataColumn(
                  label: Text("Last modification".tr, style: TextStyle(color: theme.textColor)),
                ),
                DataColumn(
                  label: Text("Shared".tr, style: TextStyle(color: theme.textColor)),
                ),
              ],
              rows: files.asMap().entries.map<DataRow>((entry) {
                final index = entry.key;
                final file = entry.value;

                final itemRef = CloudItemRef(
                  kind: CloudItemKind.file,
                  id: file.id.toString(),
                );

                return DataRow(
                  cells: [

                    DataCell(
                      PieMenu(
                        theme: PieTheme.of(context).copyWith(
                          overlayColor: (() {
                            final t = ref.watch(themeColorsProvider);
                            final bool uiIsDark = t.textColor.computeLuminance() > 0.5;
                            final base = uiIsDark ? Colors.black : Colors.white;
                            return base.withValues(alpha: 0.70);
                          })(),
                        ),
                        onPressedWithDevice: (kind) {
                          final selection = ref.read(cloudSelectionProvider.notifier);

                          final visibleItems = files
                              .map(
                                (f) => CloudItemRef(
                              kind: CloudItemKind.file,
                              id: f.id.toString(),
                            ),
                          )
                              .toList();

                          final clicked = CloudItemRef(
                            kind: CloudItemKind.file,
                            id: file.id.toString(),
                          );

                          selection.handleTap(
                            item: clicked,
                            index: index,
                            visibleItems: visibleItems,
                            ctrlPressed: _isCtrlPressed(),
                            shiftPressed: _isShiftPressed(),
                            onOpen: () async {
                              if (isMobile) {
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) {
                                    return DraggableScrollableSheet(
                                      initialChildSize: 0.9,
                                      minChildSize: 0.9,
                                      maxChildSize: 0.95,
                                      expand: false,
                                      builder: (ctx, scrollController) {
                                        return FileViewerDialog(
                                          isMobile: true,
                                          file: file,
                                        );
                                      },
                                    );
                                  },
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => FileViewerDialog(file: file),
                                );
                              }
                            },
                          );
                        },
                        actions: pieFiles(ref, file, context),
                        child: DndSender(
                          useLongPress: true,
                          payload: (() {
                            if (sel.isSelected(itemRef) &&
                                (selState.selectedFileIds.length +
                                    selState.selectedFolderIds.length) >
                                    1) {
                              return DndPayload(
                                type: DndPayloadType.multipleCloudItems,
                                id: 'multiple_selection',
                                data: CloudDragPayload.fromSelection(selState).toJson(),
                                subActions: const [
                                  'assign_cloud_items',
                                  'pin_cloud_shortcut',
                                ],
                              );
                            }

                            return DndPayload(
                              type: file.extension.isEmpty
                                  ? DndPayloadType.cloudFolder
                                  : DndPayloadType.cloudFile,
                              id: file.id,
                              action: 'move',
                              data: file.toJson(),
                              subActions: const [
                                'assign_cloud_items',
                                'pin_cloud_shortcut',
                              ],
                            );
                          })(),
                          onDragStarted: () {
                            ref.read(cloudSelectionProvider.notifier).handleDragStart(
                              item: itemRef,
                              index: index,
                            );
                          },
                          feedbackBuilder: (context) {
                            final selection = ref.read(cloudSelectionProvider);
                            final isMultiple = sel.isSelected(itemRef) &&
                                (selection.selectedFileIds.length +
                                    selection.selectedFolderIds.length) >
                                    1;

                            final count = selection.selectedFileIds.length +
                                selection.selectedFolderIds.length;

                            return Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.dashboardContainer.withAlpha(240),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.themeColor, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isMultiple)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.themeColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          count.toString(),
                                          style: TextStyle(
                                            color: theme.themeTextColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        file.extension.isEmpty
                                            ? Icons.folder
                                            : Icons.insert_drive_file_outlined,
                                        color: theme.themeColor,
                                        size: 20,
                                      ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isMultiple ? "${'You drawl'.tr} $count ${'elements'.tr}" : file.name,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: showCheckboxes
                                    ? Checkbox(
                                  value: sel.isSelected(itemRef),
                                  activeColor: theme.themeColor,
                                  checkColor: theme.themeTextColor,
                                  side: BorderSide(color: theme.textColor),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (_) => sel.toggleItem(
                                    itemRef,
                                    setAnchorIndex: index,
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                file.extension.isEmpty
                                    ? Icons.folder
                                    : Icons.insert_drive_file_outlined,
                                color: file.extension.isEmpty ? theme.themeColor : Colors.blueAccent,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  file.name,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Other cells - wrap with PieMenu for consistent behavior
                    DataCell(
                      PieMenu(
                        theme: PieTheme.of(context).copyWith(
                          overlayColor: (() {
                            final t = ref.watch(themeColorsProvider);
                            final bool uiIsDark = t.textColor.computeLuminance() > 0.5;
                            final base = uiIsDark ? Colors.black : Colors.white;
                            return base.withValues(alpha: 0.70);
                          })(),
                        ),
                        onPressedWithDevice: (kind) {
                          showDialog(
                            context: context,
                            builder: (ctx) => FileViewerDialog(file: file),
                          );
                        },
                        actions: pieFiles(ref, file, context),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            "${file.createdAt.year}-${file.createdAt.month.toString().padLeft(2, '0')}-${file.createdAt.day.toString().padLeft(2, '0')}",
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      PieMenu(
                        theme: PieTheme.of(context).copyWith(
                          overlayColor: (() {
                            final t = ref.watch(themeColorsProvider);
                            final bool uiIsDark = t.textColor.computeLuminance() > 0.5;
                            final base = uiIsDark ? Colors.black : Colors.white;
                            return base.withValues(alpha: 0.70);
                          })(),
                        ),
                        onPressedWithDevice: (kind) {
                          showDialog(
                            context: context,
                            builder: (ctx) => FileViewerDialog(file: file),
                          );
                        },
                        actions: pieFiles(ref, file, context),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            "${file.updatedAt.year}-${file.updatedAt.month.toString().padLeft(2, '0')}-${file.updatedAt.day.toString().padLeft(2, '0')}",
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      PieMenu(
                        theme: PieTheme.of(context).copyWith(
                          overlayColor: (() {
                            final t = ref.watch(themeColorsProvider);
                            final bool uiIsDark = t.textColor.computeLuminance() > 0.5;
                            final base = uiIsDark ? Colors.black : Colors.white;
                            return base.withValues(alpha: 0.70);
                          })(),
                        ),
                        onPressedWithDevice: (kind) {
                          showDialog(
                            context: context,
                            builder: (ctx) => FileViewerDialog(file: file),
                          );
                        },
                        actions: pieFiles(ref, file, context),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            file.sharedWith.isEmpty ? "—" : "👥+${file.sharedWith.length}",
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
            if (files.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 44,
                      color: theme.textColor,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "No files".tr,
                      style: TextStyle(fontSize: 18, color: theme.textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Your uploaded files will appear here.".tr,
                      style: TextStyle(fontSize: 14, color: theme.textColor),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSelectionTopBar)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      border: Border(
                        bottom: BorderSide(color: theme.dashboardBoarder, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: theme.themeColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$selectedCount selected'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            ref.read(cloudSelectionProvider.notifier).exitSelectionMode();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.close, size: 18, color: theme.textColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Cancel'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isMobile)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 760,
                      child: table,
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: table,
                      ),
                    ),
                  ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _visibleCount += _pageSize;
                          });
                        },
                        icon: const Icon(Icons.expand_more),
                        label: Text('Load more'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.dashboardBoarder),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _isCtrlPressed() {
  final keys = HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.controlLeft) ||
      keys.contains(LogicalKeyboardKey.controlRight) ||
      keys.contains(LogicalKeyboardKey.metaLeft) ||
      keys.contains(LogicalKeyboardKey.metaRight);
}

bool _isShiftPressed() {
  final keys = HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.shiftLeft) ||
      keys.contains(LogicalKeyboardKey.shiftRight);
}