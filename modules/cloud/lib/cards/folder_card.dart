import 'package:cloud/models/file.dart';
import 'package:cloud/models/folder.dart';
import 'package:cloud/models/cloud_drag_payload.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/pie_menu/pie_folders.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_handle.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';

class FolderCard extends ConsumerStatefulWidget {
  final String id;
  final String name;
  final int count;
  final dynamic folder;
  final List<CloudFolder> allFolders;
  final Future<void> Function(CloudFile file)? onFileDropped;
  final Future<void> Function(CloudFolder movedFolder)? onFolderDropped;
  final VoidCallback? onTap;
  final bool isClient;

  const FolderCard({
    super.key,
    required this.id,
    required this.name,
    required this.count,
    required this.allFolders,
    this.folder,
    this.onFileDropped,
    this.onFolderDropped,
    this.onTap,
    this.isClient = false,
  });

  @override
  ConsumerState<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends ConsumerState<FolderCard> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final dndPayload = DndPayload(
      type: DndPayloadType.cloudFolder,
      id: widget.id,
      data: widget.folder is CloudFolder
          ? (widget.folder as CloudFolder).toJson()
          : CloudFolder(
              id: widget.id,
              name: widget.name,
              filesCount: widget.count,
            ).toJson(),
      subActions: const ['assign_cloud_items'],
      action: 'move',
    );

    // DndHandle is a Stack sibling of PieMenu so there is no gesture-arena
    // conflict on mobile. PieMenu covers the card body; the handle is in the
    // top-right corner outside the PieMenu gesture area (Stack z-order).
    return Stack(
      children: [
        PieMenu(
          theme: PieTheme.of(context).copyWith(
            overlayColor: (() {
              final currentTheme = ref.watch(themeColorsProvider);
              final bool uiIsDark =
                  currentTheme.textColor.computeLuminance() > 0.5;
              final base = uiIsDark ? Colors.black : Colors.white;
              return base.withValues(alpha: 0.70);
            })(),
          ),
          onPressedWithDevice: (_) {},
          actions: pieFolders(ref, widget.folder, context),
          child: DndReceiver(
            targets: const [DndTargetType.cloudFolder],
            onDrop: (payload) async {
              if (payload.type == DndPayloadType.cloudFolder &&
                  payload.id == widget.id) {
                return;
              }

              if (payload.type == DndPayloadType.multipleCloudItems) {
                final cloudPayload = CloudDragPayload.fromJson(payload.data!);
                debugPrint(
                  'Dropped multiple items: ${cloudPayload.files.length} files, ${cloudPayload.folders.length} folders onto folder ${widget.id}',
                );
                return;
              }

              if (payload.type == DndPayloadType.cloudFile &&
                  widget.onFileDropped != null) {
                await widget.onFileDropped!(CloudFile.fromJson(payload.data!));
                return;
              }

              if (payload.type == DndPayloadType.cloudFolder &&
                  widget.onFolderDropped != null) {
                final movedFolder = CloudFolder.fromJson(payload.data!);
                await widget.onFolderDropped!(movedFolder);
              }
            },
            builder:
                (context, hoveringPayload, isHovering, canAcceptDrop, child) {
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (widget.onTap != null) {
                    widget.onTap!();
                    return;
                  }

                  final provider = widget.isClient
                      ? clientExplorerParamsProvider
                      : cloudExplorerParamsProvider;

                  ref
                      .read(provider.notifier)
                      .state = ref.read(provider).copyWith(
                    parent: widget.id,
                  );
                },
                child: _folderCardInner(theme, isHovered: isHovering),
              );
            },
            child: const SizedBox.shrink(),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: DndHandle(
            payload: dndPayload,
            feedbackBuilder: (ctx) => Opacity(
              opacity: 0.8,
              child: Transform.scale(
                scale: 0.9,
                child: SizedBox(
                  width: 280,
                  child: _folderCardInner(theme, isHovered: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _folderCardInner(ThemeColors theme, {bool isHovered = false}) {
    return Card(
      color: isHovered ? theme.dashboardBoarder : theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.dashboardBoarder,
          width: isHovered ? 3 : 2,
        ),
      ),
      elevation: isHovered ? 2 : 0,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.folder, color: theme.textColor, size: 25),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.dashboardBoarder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.count.toString(),
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}