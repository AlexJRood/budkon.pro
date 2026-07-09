import 'package:cloud/api/move.dart';
import 'package:cloud/cards/folder_card.dart';
import 'package:cloud/models/explorer.dart';
import 'package:cloud/models/file.dart';
import 'package:cloud/models/folder.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/bread_crumbs.dart';
import 'package:cloud/utils/pie_menu/pie_files.dart';
import 'package:cloud/widgets/file_viewer.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_handle.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class CloudExplorerContent extends ConsumerStatefulWidget {
  final CloudFolder? currentFolder;
  final String? currentFolderId;
  final AsyncValue<CloudExplorerResponse> contentsAsync;
  final List<CloudFolder> folders;
  final bool isClient;
  final bool isMobile;

  /// Disables every mutation path while preserving the existing folder/file UI.
  final bool readOnly;

  /// Member Cloud uses its own breadcrumbs because it is driven by a scoped API.
  final bool showBreadcrumbs;

  /// The member endpoint already returns only the current logical folder.
  final bool showAllFiles;

  /// Optional scoped navigation callback. When omitted, the regular Cloud
  /// providers remain the source of navigation state.
  final ValueChanged<String?>? onFolderChanged;

  /// When true, sizes to its content and skips its own internal
  /// [SingleChildScrollView] so it can be embedded inside another
  /// scrollable without creating a nested scroll region.
  final bool shrinkWrap;

  const CloudExplorerContent({
    super.key,
    required this.currentFolder,
    required this.currentFolderId,
    required this.contentsAsync,
    required this.folders,
    this.isClient = false,
    this.isMobile = false,
    this.readOnly = false,
    this.showBreadcrumbs = true,
    this.showAllFiles = false,
    this.onFolderChanged,
    this.shrinkWrap = false,
  });

  @override
  ConsumerState<CloudExplorerContent> createState() =>
      _CloudExplorerContentState();
}

class _CloudExplorerContentState extends ConsumerState<CloudExplorerContent> {
  CloudFolder get _effectiveCurrentFolder =>
      widget.currentFolder ??
      CloudFolder(id: 'root', name: 'Root', filesCount: 0);

  bool _isVirtualCloudDocumentFile(CloudFile file) {
    return file.id.startsWith('doc:') || file.id.startsWith('document:');
  }

  String? _virtualCloudDocumentId(CloudFile file) {
    if (file.id.startsWith('doc:')) {
      return file.id.substring('doc:'.length).trim();
    }

    if (file.id.startsWith('document:')) {
      return file.id.substring('document:'.length).trim();
    }

    return null;
  }

  bool _canOpenFile(CloudFile file) {
    return file.url.trim().isNotEmpty;
  }

  void _showSnackBar(
    ScaffoldMessengerState? messenger,
    String message, {
    bool isError = false,
  }) {
    if (messenger == null || !messenger.mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  void _openCloudDocument(
    CloudFile file,
    ScaffoldMessengerState? messenger,
  ) {
    if (!_canOpenFile(file)) {
      _showSnackBar(
        messenger,
        'member_cloud_metadata_only'.tr,
        isError: true,
      );
      return;
    }

    final documentId = _virtualCloudDocumentId(file);
    if (documentId == null || documentId.isEmpty) return;

    final docsPath =
        '${Routes.docs}?documentId=${Uri.encodeComponent(documentId)}';

    ref.read(navigationService).pushNamedScreen(
      docsPath,
      data: {
        'documentId': documentId,
        'document_id': documentId,
        'id': documentId,
        'mode': widget.readOnly ? 'view_document' : 'edit_document',
        'readOnly': widget.readOnly,
        'source': widget.readOnly ? 'member_cloud' : 'cloud_explorer',
      },
    );
  }

  Future<void> _openFileOrDocument(
    CloudFile file,
    ScaffoldMessengerState? messenger,
  ) async {
    if (!_canOpenFile(file)) {
      _showSnackBar(
        messenger,
        'member_cloud_metadata_only'.tr,
        isError: true,
      );
      return;
    }

    if (_isVirtualCloudDocumentFile(file)) {
      _openCloudDocument(file, messenger);
      return;
    }

    if (widget.isMobile) {
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
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => FileViewerDialog(file: file),
    );
  }

  Future<void> _moveFileWithFeedback(
    ScaffoldMessengerState? messenger,
    CloudFile file,
    CloudFolder targetFolder,
  ) async {
    if (widget.readOnly) return;

    if (_isVirtualCloudDocumentFile(file)) {
      _showSnackBar(
        messenger,
        'Dokumenty Docs są zapisywane jako delta i na razie nie są przenoszone jak zwykłe pliki.'.tr,
        isError: true,
      );
      return;
    }

    final result = await moveFileToFolder(ref, file, targetFolder);
    if (!mounted) return;

    _showSnackBar(
      messenger,
      result.message,
      isError: !result.success,
    );
  }

  Future<void> _moveFolderWithFeedback(
    ScaffoldMessengerState? messenger,
    CloudFolder movedFolder,
    CloudFolder targetFolder,
  ) async {
    if (widget.readOnly) return;

    final result = await moveFolderToFolder(ref, movedFolder, targetFolder);
    if (!mounted) return;

    _showSnackBar(
      messenger,
      result.message,
      isError: !result.success,
    );
  }

  Future<void> _handleDropToCurrentFolder(
    ScaffoldMessengerState? messenger,
    DndPayload payload,
  ) async {
    if (widget.readOnly) return;

    if (payload.type == DndPayloadType.cloudFile) {
      final file = CloudFile.fromJson(payload.data!);
      await _moveFileWithFeedback(messenger, file, _effectiveCurrentFolder);
      return;
    }

    if (payload.type == DndPayloadType.cloudFolder) {
      final folder = CloudFolder.fromJson(payload.data!);
      await _moveFolderWithFeedback(messenger, folder, _effectiveCurrentFolder);
    }
  }

  void _openFolder(String folderId) {
    if (widget.onFolderChanged != null) {
      widget.onFolderChanged!(folderId);
      return;
    }

    final provider = widget.isClient
        ? clientExplorerParamsProvider
        : cloudExplorerParamsProvider;
    final old = ref.read(provider);

    ref.read(provider.notifier).state = old.copyWith(
      parent: folderId,
      search: null,
      fileType: null,
      isDeleted: false,
    );
  }

  Widget _buildFolderCard(
    CloudFolder folder,
    ScaffoldMessengerState? messenger,
  ) {
    final card = FolderCard(
      isClient: widget.isClient,
      id: folder.id,
      name: folder.name,
      count: folder.filesCount ?? 0,
      folder: folder,
      allFolders: widget.folders,
      onTap: () => _openFolder(folder.id),
      onFileDropped: widget.readOnly
          ? (_) async {}
          : (file) async {
              await _moveFileWithFeedback(messenger, file, folder);
            },
      onFolderDropped: widget.readOnly
          ? (_) async {}
          : (movedFolder) async {
              await _moveFolderWithFeedback(
                messenger,
                movedFolder,
                folder,
              );
            },
    );

    if (!widget.readOnly) return card;

    // FolderCard contains its own DnD/menu behavior. Absorb those mutation
    // gestures and put a clean navigation tap above the same visual card.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFolder(folder.id),
      child: AbsorbPointer(child: card),
    );
  }

  Widget _buildReadOnlyFileCell(
    CloudFile file,
    ThemeColors theme,
    ScaffoldMessengerState? messenger,
  ) {
    final canOpen = _canOpenFile(file);

    return InkWell(
      onTap: canOpen
          ? () => _openFileOrDocument(file, messenger)
          : () {
              _showSnackBar(
                messenger,
                'member_cloud_metadata_only'.tr,
                isError: true,
              );
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _isVirtualCloudDocumentFile(file)
                  ? Icons.description_outlined
                  : canOpen
                      ? Icons.insert_drive_file_outlined
                      : Icons.lock_outline,
              color: _isVirtualCloudDocumentFile(file)
                  ? Colors.purpleAccent
                  : canOpen
                      ? Colors.blueAccent
                      : theme.textColor.withAlpha(120),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                file.name,
                style: TextStyle(
                  color: canOpen
                      ? theme.textColor
                      : theme.textColor.withAlpha(150),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableFileCell(
    CloudFile file,
    ThemeColors theme,
    ScaffoldMessengerState? messenger,
  ) {
    final fileRow = Row(
      children: [
        Icon(
          _isVirtualCloudDocumentFile(file)
              ? Icons.description_outlined
              : Icons.insert_drive_file_outlined,
          color: _isVirtualCloudDocumentFile(file)
              ? Colors.purpleAccent
              : Colors.blueAccent,
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
        // Reserve space for the drag handle so text doesn't overlap it.
        const SizedBox(width: 28),
      ],
    );

    final dndPayload = DndPayload(
      type: DndPayloadType.cloudFile,
      id: file.id,
      data: file.toJson(),
    );

    // DndHandle is placed as a Stack sibling on top of PieMenu so that on
    // mobile, long-pressing the handle starts a drag without competing with
    // PieMenu's LongPressGestureRecognizer.
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        PieMenu(
          theme: PieTheme.of(context).copyWith(
            overlayColor: (() {
              final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
              final base = uiIsDark ? Colors.black : Colors.white;
              return base.withValues(alpha: 0.70);
            })(),
          ),
          onPressedWithDevice: (kind) async {
            if (kind == PointerDeviceKind.mouse ||
                kind == PointerDeviceKind.touch) {
              await _openFileOrDocument(file, messenger);
            }
          },
          actions: _isVirtualCloudDocumentFile(file)
              ? const []
              : pieFiles(ref, file, context),
          child: fileRow,
        ),
        DndHandle(
          payload: dndPayload,
          feedbackBuilder: (ctx) => Material(
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
                  Icon(
                    _isVirtualCloudDocumentFile(file)
                        ? Icons.description_outlined
                        : Icons.insert_drive_file_outlined,
                    color: theme.themeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    file.name,
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
        ),
      ],
    );
  }

  Widget _buildExplorerBody(
    ThemeColors theme,
    ScaffoldMessengerState? messenger,
  ) {
    return KeyedSubtree(
      key: ValueKey(widget.currentFolderId ?? 'root'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showBreadcrumbs)
            CloudBreadcrumbs(isClient: widget.isClient),
          widget.contentsAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: AppLottie.loading(
                  size: widget.isMobile ? 200 : 450,
                ),
              ),
            ),
            error: (err, stack) =>
                Center(child: Text("${'Mistake:'.tr} $err")),
            data: (data) {
              final subfolders = data.subfolders;
              final effectiveFolderId = widget.currentFolderId ?? 'root';

              final files = widget.showAllFiles
                  ? data.files
                  : data.files.where((file) {
                      final folderId = file.folderId ?? 'root';
                      return folderId == effectiveFolderId;
                    }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subfolders.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Subfolders'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            (constraints.maxWidth / 240).floor().clamp(1, 8);

                        return GridView.builder(
                          addAutomaticKeepAlives: false,
                          addSemanticIndexes: false,
                          cacheExtent: 160,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 3.2,
                          ),
                          itemCount: subfolders.length,
                          itemBuilder: (context, index) {
                            return _buildFolderCard(
                              subfolders[index],
                              messenger,
                            );
                          },
                        );
                      },
                    ),
                  ],
                  if (files.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 8),
                      child: Text(
                        'Files'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                theme.dashboardContainer,
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'File name'.tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Date uploaded'.tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Size'.tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                              ],
                              rows: files.map((file) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      widget.readOnly
                                          ? _buildReadOnlyFileCell(
                                              file,
                                              theme,
                                              messenger,
                                            )
                                          : _buildEditableFileCell(
                                              file,
                                              theme,
                                              messenger,
                                            ),
                                    ),
                                    DataCell(
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(
                                          file.createdAt.toLocal(),
                                        ),
                                        style: TextStyle(color: theme.textColor),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _isVirtualCloudDocumentFile(file)
                                            ? 'Docs / delta'.tr
                                            : (file.sizeString ?? ''),
                                        style: TextStyle(color: theme.textColor),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (subfolders.isEmpty && files.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(64),
                        child: AppLottie.noResults(),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final body = _buildExplorerBody(theme, messenger);

    final content = widget.readOnly
        ? body
        : DndReceiver(
            targets: const [DndTargetType.cloudFolder],
            onDrop: (payload) async {
              await _handleDropToCurrentFolder(messenger, payload);
            },
            builder: (
              context,
              hoveringPayload,
              isHovering,
              canAcceptDrop,
              child,
            ) {
              return Container(
                decoration: isHovering
                    ? BoxDecoration(
                        border: Border.all(
                          color: canAcceptDrop
                              ? Colors.green.withAlpha(178)
                              : Colors.red.withAlpha(178),
                          width: 3,
                        ),
                        color: canAcceptDrop
                            ? Colors.green.withAlpha(23)
                            : Colors.red.withAlpha(23),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: child,
              );
            },
            child: body,
          );

    if (widget.shrinkWrap) return content;

    return SingleChildScrollView(
      primary: false,
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.zero,
        child: content,
      ),
    );
  }
}
