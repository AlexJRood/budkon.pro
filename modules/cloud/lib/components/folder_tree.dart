import 'package:cloud/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:cloud/models/folder.dart';
import 'package:cloud/models/file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:cloud/api/move.dart';
import 'package:core/theme/icons.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:cloud/models/cloud_drag_payload.dart';
import 'package:get/get_utils/get_utils.dart';

class FolderTreeWidget extends ConsumerStatefulWidget {
  final List<CloudFolder> folders;
  final String? parentId;
  final int indent;
  final void Function(CloudFolder)? onTap;
  final void Function(CloudFile file, CloudFolder folder)? onFileDropped;
  final void Function(CloudFolder movedFolder, CloudFolder targetFolder)?
  onFolderDropped;

  const FolderTreeWidget({
    Key? key,
    required this.folders,
    this.parentId,
    this.indent = 0,
    this.onTap,
    this.onFileDropped,
    this.onFolderDropped,
  }) : super(key: key);

  @override
  ConsumerState<FolderTreeWidget> createState() => _FolderTreeWidgetState();
}

class _FolderTreeWidgetState extends ConsumerState<FolderTreeWidget> {
  bool rejectedMove = false;
  final Map<String, bool> expanded =
      {}; // <--- trzyma stan rozwiniecia kazdego folderu

  @override
  Widget build(BuildContext context) {
    final children =
        widget.folders.where((f) => f.parent == widget.parentId).toList();
    final theme = ref.read(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children.map((folder) {
            final hasSub = widget.folders.any((f) => f.parent == folder.id);
            final isOpen = expanded[folder.id] ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16.0 * widget.indent),
                  child: DndReceiver(
                    targets: const [DndTargetType.cloudFolder],
                    onDrop: (payload) async {
                      if (payload.type == DndPayloadType.multipleCloudItems) {
                        final cloudPayload = CloudDragPayload.fromJson(
                          payload.data!,
                        );
                        debugPrint(
                          'Dropped multiple items: ${cloudPayload.files.length} files, ${cloudPayload.folders.length} folders onto folder ${folder.id}',
                        );
                        // API implementation pending
                        return;
                      }
                      if (payload.type == DndPayloadType.cloudFile &&
                          widget.onFileDropped != null) {
                        widget.onFileDropped!(
                          CloudFile.fromJson(payload.data!),
                          folder,
                        );
                      }
                      if (payload.type == DndPayloadType.cloudFolder) {
                        final movedFolder = CloudFolder.fromJson(payload.data!);
                        debugPrint(
                          'FolderTreeWidget: Dropped folder ${movedFolder.name} (${movedFolder.id}) onto ${folder.name} (${folder.id})',
                        );

                        // Prevent moving folder into itself or its descendants
                        if (isDescendant(movedFolder, folder, widget.folders)) {
                          debugPrint(
                            'FolderTreeWidget: Drop rejected (descendant check)',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:Text(
                                  'You cannot move a folder to yourself or to your own subfolder.'.tr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.orange.shade700,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          return;
                        }

                        if (widget.onFolderDropped != null) {
                          debugPrint(
                            'FolderTreeWidget: invoking widget.onFolderDropped',
                          );
                          widget.onFolderDropped!(movedFolder, folder);
                        } else {
                          debugPrint(
                            'FolderTreeWidget: invoking internal moveFolderToFolder',
                          );
                          await moveFolderToFolder(                            
                            ref,
                            movedFolder,
                            folder,
                          );
                        }
                      }
                    },
                    builder: (
                      context,
                      hoveringPayload,
                      isHovering,
                      canAcceptDrop,
                      child,
                    ) {
                      return DndSender(
                        payload: DndPayload(
                          type: DndPayloadType.cloudFolder,
                          id: folder.id,
                          data: folder.toJson(),
                          action: 'move',
                          subActions: const ['assign_cloud_items'],
                        ),
                        useLongPress: true,
                        feedbackBuilder:
                            (context) => Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.dashboardContainer.withAlpha(
                                    240,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.themeColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcons.folder(color: theme.themeColor),
                                    const SizedBox(width: 10),
                                    Text(
                                      folder.name,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        child: _buildCard(
                          context,
                          theme,
                          folder,
                          hasSub,
                          widget.onTap,
                          isHovering,
                          isOpen,
                          () {
                            setState(() => expanded[folder.id] = !isOpen);
                          },
                        ),
                      );
                    },
                    child: const SizedBox.shrink(),
                  ),
                ),
                // Rekurencja na podfoldery, pokazuje się tylko jak otwarte
                if (isOpen)
                  FolderTreeWidget(
                    folders: widget.folders,
                    parentId: folder.id,
                    indent: widget.indent + 1,
                    onTap: widget.onTap,
                    onFileDropped: widget.onFileDropped,
                    onFolderDropped: widget.onFolderDropped,
                  ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeColors theme,
    CloudFolder folder,
    bool hasSub,
    void Function(CloudFolder)? onTap,
    bool isHovered,
    bool isOpen,
    VoidCallback onExpandToggle,
  ) {
    return Card(
      elevation: isHovered ? 2 : 0,
      margin: EdgeInsets.zero,
      color: isHovered ? theme.dashboardBoarder : theme.dashboardContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        dense: true,
        leading: AppIcons.folder(color: theme.textColor),
        title: Text(folder.name, style: TextStyle(color: theme.textColor)),
        trailing:
            hasSub
                ? IconButton(
                  icon: Icon(
                    isOpen ? Icons.expand_more : Icons.chevron_right,
                    color: theme.textColor,
                  ),
                  splashRadius: 18,
                  onPressed: onExpandToggle,
                )
                : null,
        contentPadding: const EdgeInsets.only(left: 0, right: 0),
        onTap: () {
          // 1. Breadcrumbs logic
          final currentPath = ref.read(selectedFolderPathProvider);
          int alreadyInPath = currentPath.indexWhere((f) => f.id == folder.id);

          if (alreadyInPath != -1) {
            ref.read(selectedFolderPathProvider.notifier).state = currentPath
                .sublist(0, alreadyInPath + 1);
          } else {
            ref.read(selectedFolderPathProvider.notifier).state = [
              ...currentPath,
              folder,
            ];
          }
          // 2. Zmiana folderu w explorerze!
          ref.read(cloudExplorerParamsProvider.notifier).state = ref
              .read(cloudExplorerParamsProvider.notifier)
              .state
              .copyWith(parent: folder.id);

          onExpandToggle();
          if (onTap != null) onTap(folder);
        },
      ),
    );
  }
}
