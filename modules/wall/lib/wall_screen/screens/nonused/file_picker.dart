import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:get/get_utils/get_utils.dart';
typedef PickedFile = dynamic; // File (mobile/desktop) lub PlatformFile (web)

class ReusableFilePicker extends StatefulWidget {
  final String? title;
  final List<PickedFile>? initialFiles;
  final ValueChanged<List<PickedFile>>? onFilesChanged;
  final bool allowMultiple;
  final FileType fileType;
  final bool allowCamera;

  const ReusableFilePicker({
    Key? key,
    this.title,
    this.initialFiles,
    this.onFilesChanged,
    this.allowMultiple = true,
    this.fileType = FileType.media,
    this.allowCamera = true,
  }) : super(key: key);

  @override
  State<ReusableFilePicker> createState() => _ReusableFilePickerState();
}

class _ReusableFilePickerState extends State<ReusableFilePicker> {
  late List<PickedFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List<PickedFile>.from(widget.initialFiles ?? []);
  }

  void _notifyParent() {
    widget.onFilesChanged?.call(_files);
  }

  Future<void> _pickFiles() async {
    final results = await FilePicker.platform.pickFiles(
      allowMultiple: widget.allowMultiple,
      type: widget.fileType,
      withData: true,
    );
    if (results != null) {
      setState(() {
        if (kIsWeb) {
          _files.addAll(results.files.where((f) => f.bytes != null).where(
              (f) => !_files.any((existing) =>
                  (existing is PlatformFile && existing.name == f.name))));
        } else {
          _files.addAll(results.paths
              .whereType<String>()
              .map((p) => File(p))
              .where((f) =>
                  !_files.any((existing) =>
                      existing is File && existing.path == f.path)));
        }
        _notifyParent();
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _files.add(File(pickedFile.path));
        _notifyParent();
      });
    }
  }

  Widget _buildThumbnail(PickedFile file) {
    if (kIsWeb && file is PlatformFile && file.bytes != null) {
      // Obrazek (web)
      if (_isImage(file.name)) {
        return Image.memory(file.bytes!, fit: BoxFit.cover);
      }
      // Video (web) – brak podglądu miniatury, można ikonkę
      return const Icon(Icons.videocam, size: 40, color: Colors.amber);
    } else if (file is File) {
      // Obrazek (mobile/desktop)
      if (_isImage(file.path)) {
        return Image.file(file, fit: BoxFit.cover);
      }
      // Video – ikona, można dodać video_player na życzenie
      return const Icon(Icons.videocam, size: 40, color: Colors.amber);
    }
    return const Icon(Icons.insert_drive_file, size: 40);
  }

  String _fileName(PickedFile file) {
    if (kIsWeb && file is PlatformFile) return file.name;
    if (file is File) return p.basename(file.path);
    return 'unknown_file'.tr;
  }

  int _fileSize(PickedFile file) {
    if (kIsWeb && file is PlatformFile) return file.size;
    if (file is File) {
      try {
        return file.lengthSync();
      } catch (_) {}
    }
    return 0;
  }

  bool _isImage(String path) =>
      path.toLowerCase().endsWith('.png') ||
      path.toLowerCase().endsWith('.jpg') ||
      path.toLowerCase().endsWith('.jpeg') ||
      path.toLowerCase().endsWith('.gif') ||
      path.toLowerCase().endsWith('.webp');

  void _removeFile(PickedFile file) {
    setState(() {
      _files.remove(file);
      _notifyParent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label:  Text('Add files'.tr),
              onPressed: _pickFiles,
            ),
            if (widget.allowCamera && !kIsWeb) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label:Text('Apparatus'.tr),
                onPressed: _pickFromCamera,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (_files.isNotEmpty)
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _files.map((f) {
                final name = _fileName(f);
                final size = _fileSize(f);
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(right: 8, bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildThumbnail(f),
                      ),
                    ),
                    Positioned(
                      top: 52,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                        color: Colors.black.withAlpha(128),
                        child: Text(
                          name.length > 16
                              ? name.substring(0, 13) + "..."
                              : name,
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 62,
                      left: 2,
                      child: Container(
                        color: Colors.black.withAlpha(128),
                        child: Text(
                          size > 0
                              ? "${(size / 1024).toStringAsFixed(1)} KB"
                              : "None".tr,
                          style: const TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      onPressed: () => _removeFile(f),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
