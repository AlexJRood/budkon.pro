import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:core/platform/api_services.dart';
import 'package:wall/wall_screen/screens/nonused/file_picker.dart';
import 'package:get/get_utils/get_utils.dart';
class CommunityPostUploadWidget extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>>? userOptions; // [{id, name}]
  final void Function()? onUploaded;

  const CommunityPostUploadWidget({
    Key? key,
    this.userOptions,
    this.onUploaded,
  }) : super(key: key);

  @override
  ConsumerState<CommunityPostUploadWidget> createState() =>
      _CommunityPostUploadWidgetState();
}

class _CommunityPostUploadWidgetState
    extends ConsumerState<CommunityPostUploadWidget> {
  final _contentController = TextEditingController();
  String _wallType = 'both';
  String? _location;
  double? _lat;
  double? _lon;
  List<dynamic> _files = [];
  List<int> _taggedUserIds = [];
  bool _loading = false;
  String? _statusMsg;

  bool get _readyToUpload => _filesReady();

  bool _filesReady() {
    if (_files.isEmpty) return true;
    for (final f in _files) {
      if (kIsWeb && f is PlatformFile) {
        if (f.bytes == null || f.bytes!.isEmpty) return false;
      } else if (f is File) {
        if (!f.existsSync() || f.lengthSync() == 0) return false;
      }
    }
    return true;
  }

  Future<void> _uploadPost() async {
    setState(() {
      _loading = true;
      _statusMsg = null;
    });

    if (!_filesReady()) {
      setState(() {
        _loading = false;
        _statusMsg = "some_files_not_ready_for_upload".tr;
      });
      return;
    }

    final formData = FormData();

    formData.fields
      ..add(MapEntry('content', _contentController.text))
      ..add(MapEntry('wall_type', _wallType));
    if (_location?.isNotEmpty ?? false) formData.fields.add(MapEntry('location', _location!));
    if (_lat != null) formData.fields.add(MapEntry('lat', _lat.toString()));
    if (_lon != null) formData.fields.add(MapEntry('lon', _lon.toString()));

    for (final id in _taggedUserIds) {
      formData.fields.add(MapEntry('tagged_users', id.toString()));
    }

    // Files: mobile/web support
    for (final f in _files) {
      if (kIsWeb && f is PlatformFile) {
        formData.files.add(MapEntry(
          'files',
          MultipartFile.fromBytes(
            f.bytes!,
            filename: f.name,
          ),
        ));
      } else if (f is File) {
        final filename = p.basename(f.path);
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(f.path, filename: filename),
        ));
      }
    }

    final resp = await ApiServices.post(
      'https://www.superbee.cloud/community/posts/upload_post/',
      formData: formData,
      hasToken: true,
    );

    setState(() => _loading = false);

    if (resp != null && resp.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('post_uploaded'.tr)),
      );
      _contentController.clear();
      setState(() {
        _files.clear();
        _taggedUserIds.clear();
        _statusMsg = null;
      });
      widget.onUploaded?.call();
    } else {
      String errMsg = resp?.data?.toString() ?? 'Error'.tr;
      setState(() {
        _statusMsg = '${'Error'.tr}: $errMsg';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'Error'.tr}: $errMsg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_statusMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_statusMsg!, style: TextStyle(color: Colors.amber)),
              ),
            ReusableFilePicker(
              title: "Attach media".tr,
              initialFiles: _files,
              allowMultiple: true,
              allowCamera: true,
              fileType: FileType.media,
              onFilesChanged: (files) {
                setState(() => _files = files);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Post content'.tr,
                border: OutlineInputBorder(),
                fillColor: Color.fromARGB(31, 0, 0, 0),
                filled: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Wall:'.tr),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _wallType,
                  items: [
                    DropdownMenuItem(value: 'both', child: Text('Everyone'.tr)),
                    DropdownMenuItem(value: 'agents', child: Text('Agents'.tr)),
                    DropdownMenuItem(value: 'flipers', child: Text('Flippers'.tr)),
                  ],
                  onChanged: (v) => setState(() => _wallType = v ?? 'both'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.location_on),
                  tooltip: 'Add location'.tr,
                  onPressed: () async {
                    final loc = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title:Text("Enter location".tr),
                        content: TextField(
                          autofocus: true,
                          onChanged: (val) => _location = val,
                          decoration: InputDecoration(
                            hintText: "City or address".tr,
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, _location),
                              child: Text('OK'.tr))
                        ],
                      ),
                    );
                    setState(() => _location = loc);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.userOptions != null) ...[
              Wrap(
                spacing: 8,
                children: widget.userOptions!.map((user) {
                  final isSelected = _taggedUserIds.contains(user['id']);
                  return FilterChip(
                    label: Text('${user['name']}'),
                    selected: isSelected,
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _taggedUserIds.add(user['id']);
                        } else {
                          _taggedUserIds.remove(user['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Upload'.tr),
                onPressed: (_loading || !_readyToUpload) ? null : _uploadPost,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
