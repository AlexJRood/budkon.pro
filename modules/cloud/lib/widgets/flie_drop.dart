import 'package:core/ui/device_type_util.dart';
import 'package:cloud/components/drag_n_drop.dart';
import 'package:cloud/providers/refresh_provider.dart';
import 'package:cloud/utils/folder_drop_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'dart:io';
import 'package:cloud/providers/providers.dart';
final uploadOverlayOpenProvider = StateProvider<bool>((ref) => false);

class UniversalFileDropZone extends ConsumerWidget {
  final Widget? child;
  final bool autoOpenOverlay;
  final UploadExtra? extra;
  final bool isClient;

  const UniversalFileDropZone({
    super.key,
    this.child,
    this.autoOpenOverlay = true,
    this.extra,
    this.isClient = false,
  });

  bool get _isDnDSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isDnDSupported) {
      return _DropArea(
        autoOpenOverlay: autoOpenOverlay,
        extra: extra,
        isClient: isClient,
        child: child,
      );
    }
    // Mobile: tylko przycisk (opcjonalnie) + child
    return child ?? const SizedBox.shrink();
  }
}

class _DropArea extends ConsumerStatefulWidget {
  final Widget? child;
  final bool autoOpenOverlay;
  final UploadExtra? extra;
  final bool isClient;
  const _DropArea({
    super.key,
    this.child,
    required this.autoOpenOverlay,
    this.extra,
    this.isClient = false,
  });

  @override
  _DropAreaState createState() => _DropAreaState(); // ✅ zwracamy konkretny ConsumerState
}

class _DropAreaState extends ConsumerState<_DropArea> {
  bool _highlight = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;

    final notifier = ref.read(uploadQueueProvider.notifier);
    for (final f in result.files) {
      notifier.addFile(f, extra: widget.extra);
    }

    if (widget.autoOpenOverlay) {
      showFileUploadOverlay(context, ref);
    }
  }

  Future<void> _handleDroppedItems(List<XFile> droppedItems) async {
    final notifier = ref.read(uploadQueueProvider.notifier);
    final currentParentId = ref.read(cloudExplorerParamsProvider).parent?.toString();

    for (final x in droppedItems) {
      try {
        final kind = await getDroppedEntryKind(x);

        if (kind == 'file') {
          notifier.addFile(File(x.path), extra: widget.extra);
          continue;
        }

        if (kind == 'directory') {
          final folderRef = FolderUploadRef(x.path);
          notifier.addFolder(folderRef, extra: widget.extra);
          try {
            await uploadDroppedDirectory(
              localDirectoryPath: x.path,
              ref: ref,
              parentCloudFolderId: currentParentId,
              onStatus: (msg) => debugPrint(msg),
              onProgress: (progress) => notifier.setProgress(folderRef, progress),
            );
            notifier.setStatus(folderRef, 'done');
          } catch (e) {
            notifier.setStatus(folderRef, 'error', errorMsg: e.toString());
          }
          continue;
        }

        debugPrint('Unsupported dropped item: ${x.path}');
      } catch (e) {
        // One failing item (e.g. a folder upload error) must not abort the
        // rest of the drop, otherwise neither the remaining items nor the
        // upload overlay are ever processed.
        debugPrint('Failed to handle dropped item ${x.path}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _highlight = true),
      onDragExited: (_) => setState(() => _highlight = false),
      onDragDone: (details) async {
        if (!mounted) return;
        setState(() => _highlight = false);

        try {
          if (widget.autoOpenOverlay) {
            showFileUploadOverlay(context, ref);
          }

          await _handleDroppedItems(details.files);

          final container = ProviderScope.containerOf(context, listen: false);
          refreshSidebarOnUploadComplete(container);

          ref.invalidate(cloudExplorerProvider);
          ref.invalidate(cloudSidebarProvider);
        } catch (e) {
          debugPrint('Drop upload error: $e');
        }
      },
      child: Stack(
        children: [
          if (widget.child != null) widget.child!,
          if (_highlight)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(82),
                alignment: Alignment.center,
                child: Text(
                  'Drop files or folders here'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Uniwersalny przycisk otwierający file pickera.
/// Możesz użyć gdziekolwiek – BarManager, AppBar, FAB itd.
///
class FilePickerButton extends StatelessWidget {
  final void Function(List<dynamic> files)? onFilesPicked;
  final String label;
  final bool allowMultiple;
  final Color color;

  const FilePickerButton({
    super.key,
    this.color = AppColors.white,
    required this.onFilesPicked,
    this.label = 'Add file',
    this.allowMultiple = true,
  });

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _pickFiles(BuildContext context) async {
    if (_isMobilePlatform) {
      await _showMobileSourceSheet(context);
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      withData: true,
    );
    if (result != null && onFilesPicked != null) {
      onFilesPicked!(result.files); // zgodnie z Twoim callbackiem
    }
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      withData: true,
    );
    if (result != null && onFilesPicked != null) {
      onFilesPicked!(result.files);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    if (allowMultiple) {
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty && onFilesPicked != null) {
        onFilesPicked!(images);
      }
    } else {
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && onFilesPicked != null) {
        onFilesPicked!([image]);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null && onFilesPicked != null) {
      onFilesPicked!([image]);
    }
  }

  Future<void> _showMobileSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: AppIcons.camera(color: AppColors.black),
                  title: Text('Take photo'.tr),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('Choose photo'.tr),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: AppIcons.document(color: AppColors.black),
                  title: Text('Choose file'.tr),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickFromFiles();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: buttonStyleRounded10ThemeRed,
      onPressed: () => _pickFiles(context),
      child: SizedBox(height: 40, width: 40, child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AppIcons.add(color: color),
      )),
    );
  }
}
