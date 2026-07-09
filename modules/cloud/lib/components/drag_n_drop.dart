import 'package:cloud/models/file.dart';
import 'package:cloud/providers/refresh_provider.dart';
import 'package:cloud/widgets/file_viewer.dart';
import 'package:cloud/widgets/flie_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud/api/upload.dart';
import 'package:core/theme/apptheme.dart';
import 'dart:async';
import 'package:get/get_utils/get_utils.dart';
// ✅ Needed to refresh explorer after uploads
import 'package:cloud/providers/providers.dart';

// upload.dart (albo wspólny plik z modelami uploadu)
class UploadExtra {
  final String? folderId;
  final String? description;
  final List<String>? tags;
  final bool? isSecured;
  final String? appLabel;
  final String? model;
  final String? objectId; // trzymamy jako String dla multipart
  final String? relationType;
  final String? fileType; // opcjonalny hint

  const UploadExtra({
    this.folderId,
    this.description,
    this.tags,
    this.isSecured,
    this.appLabel,
    this.model,
    this.objectId,
    this.relationType,
    this.fileType,
  });
}

/// Identifies a dropped folder in the upload queue. Local file uploads use
/// the `File`/`XFile` object itself as the queue key; folders use this
/// lightweight ref (path-based equality) since a folder upload has no
/// single underlying file object.
class FolderUploadRef {
  final String path;
  const FolderUploadRef(this.path);

  @override
  bool operator ==(Object other) => other is FolderUploadRef && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

// ---- KOLEJKA UPLOADU ----
class FileUploadTask {
  final dynamic file;
  final UploadExtra? extra;
  final double progress;
  final String status; // 'queued', 'uploading', 'done', 'error'
  final String? errorMsg;
  final Map<String, dynamic>? uploadedData; // server response after successful upload
  final bool isFolder;

  FileUploadTask({
    required this.file,
    this.extra,
    this.progress = 0,
    this.status = 'queued',
    this.errorMsg,
    this.uploadedData,
    this.isFolder = false,
  });
}

class UploadQueueNotifier extends StateNotifier<List<FileUploadTask>> {
  UploadQueueNotifier() : super([]);

  void addFile(dynamic file, {UploadExtra? extra}) {
    state = [...state, FileUploadTask(file: file, extra: extra)];
  }

  /// Folder uploads are driven directly by `uploadDroppedDirectory`
  /// (not by `processQueue`), so they start out already 'uploading'.
  void addFolder(dynamic file, {UploadExtra? extra}) {
    state = [
      ...state,
      FileUploadTask(file: file, extra: extra, isFolder: true, status: 'uploading'),
    ];
  }

  void setProgress(dynamic file, double progress) {
    state = [
      for (final task in state)
        if (task.file == file)
          FileUploadTask(
            file: task.file,
            extra: task.extra, // ✅ preserve extra
            progress: progress,
            status: task.status,
            errorMsg: task.errorMsg,
            uploadedData: task.uploadedData,
            isFolder: task.isFolder,
          )
        else
          task,
    ];
  }

  void setStatus(
    dynamic file,
    String status, {
    String? errorMsg,
    Map<String, dynamic>? uploadedData,
  }) {
    state = [
      for (final task in state)
        if (task.file == file)
          FileUploadTask(
            file: task.file,
            extra: task.extra,
            progress: task.progress,
            status: status,
            errorMsg: errorMsg ?? task.errorMsg,
            uploadedData: uploadedData ?? task.uploadedData,
            isFolder: task.isFolder,
          )
        else
          task,
    ];
  }

  void removeFile(dynamic file) {
    state = state.where((t) => t.file != file).toList();
  }
}

final uploadQueueProvider =
    StateNotifierProvider<UploadQueueNotifier, List<FileUploadTask>>(
      (ref) => UploadQueueNotifier(),
    );

//// ---- WIDGETY ----

void showFileUploadOverlay(BuildContext context, WidgetRef ref) {
  final isOpen = ref.read(uploadOverlayOpenProvider);
  if (isOpen) return; // ✅ prevent stacking

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  final Size screenSize = MediaQuery.of(context).size;
  final bool isMobile = screenSize.width < 800;

  ref.read(uploadOverlayOpenProvider.notifier).state = true;

  entry = OverlayEntry(
    builder:
        (_) => Positioned(
          bottom: isMobile ? 0 : 20,
          right: isMobile ? 0 : 20,
          child: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? screenSize.width : screenSize.width * 0.55,
                maxHeight: isMobile
                    ? screenSize.height * 0.7
                    : screenSize.height * 0.82,
              ),
              child: FileUploadOverlay(
                onClose: () {
                  if (ref.read(uploadOverlayOpenProvider)) {
                    ref.read(uploadOverlayOpenProvider.notifier).state = false;
                  }
                  entry.remove();
                },
              ),
            ),
          ),
        ),
  );

  overlay.insert(entry);
}

class FileUploadOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final DropzoneViewController? dropController;
  final UploadExtra? extra;
  const FileUploadOverlay({
    super.key,
    required this.onClose,
    this.dropController,
    this.extra,
  });

  @override
  ConsumerState<FileUploadOverlay> createState() => _FileUploadOverlayState();
}

class _FileUploadOverlayState extends ConsumerState<FileUploadOverlay> {
  bool _isUploading = false;
  bool _minimized = false;

  Timer? _autoCloseTimer;
  bool _autoCloseScheduled = false;
  ProviderSubscription<List<FileUploadTask>>? _queueSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      processQueue();
      _queueSub = ref.listenManual<List<FileUploadTask>>(uploadQueueProvider, (
        prev,
        next,
      ) {
        if (!mounted) return;

        final hasQueued = next.any((t) => t.status == 'queued');
        final hasUploading = next.any((t) => t.status == 'uploading');
        final allFinished = next.isNotEmpty && !hasQueued && !hasUploading;
        if (hasQueued || hasUploading) {
          _autoCloseTimer?.cancel();
          _autoCloseScheduled = false;

          if (hasQueued && !_isUploading) {
            processQueue();
          }
          return;
        }
        if (allFinished && !_autoCloseScheduled && !_minimized) {
          _autoCloseScheduled = true;
          _autoCloseTimer?.cancel();
          _autoCloseTimer = Timer(const Duration(seconds: 15), () {
            if (!mounted || _minimized) return;
            widget.onClose();
          });
        }
        if (next.isEmpty) {
          _autoCloseTimer?.cancel();
          _autoCloseScheduled = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _queueSub?.close();
    super.dispose();
  }

  Future<void> processQueue() async {
    if (_isUploading) return;
    _isUploading = true;
    _autoCloseTimer?.cancel();
    _autoCloseScheduled = false;

    final notifier = ref.read(uploadQueueProvider.notifier);

    for (final task in List<FileUploadTask>.from(
      ref.read(uploadQueueProvider),
    )) {
      if (task.isFolder) continue; // driven directly by uploadDroppedDirectory
      if (task.status != 'queued') continue;

      notifier.setStatus(task.file, 'uploading');
      try {
        final uploadedData = await uploadFileToCloud(
          file: task.file,
          uploadUrl: "https://www.superbee.cloud/storage/upload/",
          folderId: task.extra?.folderId,
          description: task.extra?.description,
          tags: task.extra?.tags,
          isSecured: task.extra?.isSecured,
          appLabel: task.extra?.appLabel,
          model: task.extra?.model,
          objectId: task.extra?.objectId,
          relationType: task.extra?.relationType,
          fileType: task.extra?.fileType,
          onProgress: (progress) => notifier.setProgress(task.file, progress),
          ref: ref,
        );

        notifier.setStatus(task.file, 'done', uploadedData: uploadedData);

        ref.invalidate(cloudExplorerProvider);
        final clientParams = ref.read(clientExplorerParamsProvider);
        ref.invalidate(clientFileExplorerProvider(clientParams));

        final container = ProviderScope.containerOf(context, listen: false);
        refreshSidebarOnUploadComplete(container);
      } catch (e) {
        notifier.setStatus(task.file, 'error', errorMsg: e.toString());
      }
    }

    _isUploading = false;
  }

  void _openFile(BuildContext context, Map<String, dynamic> data) {
    try {
      final file = CloudFile.fromJson(data);
      final screenSize = MediaQuery.sizeOf(context);
      final isMobile = screenSize.width < 700;

      if (isMobile) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, __) => FileViewerDialog(file: file, isMobile: true),
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: Colors.transparent,
            child: SizedBox(
              width: screenSize.width - 24,
              height: screenSize.height - 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FileViewerDialog(file: file, isMobile: false),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      // uploaded data doesn't match CloudFile shape — ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(uploadQueueProvider);
    final theme = ref.read(themeColorsProvider);

    final doneCount = queue.where((t) => t.status == 'done').length;
    final errorCount = queue.where((t) => t.status == 'error').length;
    final activeCount = queue.where(
      (t) => t.status == 'queued' || t.status == 'uploading',
    ).length;

    final headerRadius = BorderRadius.circular(_minimized ? 12 : 10);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.dashboardContainer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────
          GestureDetector(
            onTap: _minimized ? () => setState(() => _minimized = false) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: headerRadius,
                color: theme.themeColor,
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload, color: theme.themeTextColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Uploading files'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.themeTextColor,
                          ),
                        ),
                        if (_minimized)
                          Text(
                            _miniSummary(activeCount, doneCount, errorCount),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.themeTextColor.withAlpha(200),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Minimize / expand
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => setState(() {
                      _minimized = !_minimized;
                      if (!_minimized) {
                        // Reset auto-close when expanding
                        _autoCloseTimer?.cancel();
                        _autoCloseScheduled = false;
                      }
                    }),
                    icon: Icon(
                      _minimized
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.themeTextColor,
                      size: 20,
                    ),
                    tooltip: _minimized ? 'Expand'.tr : 'Minimize'.tr,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close, color: theme.themeTextColor, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // ── Queue list (hidden when minimized) ─────────────
          if (!_minimized) ...[
            const Divider(height: 1),
            if (queue.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'No files in queue.'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            if (queue.isNotEmpty)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: queue.map<Widget>((task) {
              final percent = (task.progress * 100).toStringAsFixed(0);
              final fileName = _fileName(task.file);
              final canOpen =
                  task.status == 'done' && task.uploadedData != null;

              return InkWell(
                onTap: canOpen
                    ? () => _openFile(context, task.uploadedData!)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: [
                      Icon(
                        task.isFolder ? Icons.folder : Icons.insert_drive_file,
                        size: 20,
                        color: canOpen
                            ? theme.themeColor
                            : theme.textColor.withAlpha(160),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fileName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: canOpen
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (canOpen)
                              Text(
                                'tap_to_open_file'.tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.themeColor.withAlpha(200),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status indicator
                      if (task.status == 'uploading') ...[
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: task.progress,
                            color: theme.themeColor,
                            backgroundColor: theme.themeColor.withAlpha(40),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textColor.withAlpha(180),
                          ),
                        ),
                      ],
                      if (task.status == 'queued')
                        Text(
                          'Queued'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textColor.withAlpha(150),
                          ),
                        ),
                      if (task.status == 'done')
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 18),
                      if (task.status == 'error')
                        Tooltip(
                          message: task.errorMsg ?? 'Error',
                          child: const Icon(Icons.error_rounded,
                              color: Colors.redAccent, size: 18),
                        ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(Icons.close_rounded,
                            size: 16, color: theme.textColor.withAlpha(140)),
                        onPressed: () =>
                            ref.read(uploadQueueProvider.notifier).removeFile(task.file),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _miniSummary(int active, int done, int error) {
    final parts = <String>[];
    if (active > 0) parts.add('$active uploading');
    if (done > 0) parts.add('$done done');
    if (error > 0) parts.add('$error error');
    return parts.join(' · ');
  }

  String _fileName(dynamic file) {
    try {
      if (kIsWeb) return (file?.name ?? 'file').toString();
      final path = file?.path?.toString() ?? '';
      return path.contains('/') ? path.split('/').last : path.split('\\').last;
    } catch (_) {
      return 'file';
    }
  }
}
