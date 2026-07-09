import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:core/platform/api_services.dart';

enum UploadStatus { initial, uploading, success, failure }

final fileUploadProvider = StateNotifierProvider<FileUploadNotifier, UploadStatus>((ref) => FileUploadNotifier());

class FileUploadNotifier extends StateNotifier<UploadStatus> {
  FileUploadNotifier() : super(UploadStatus.initial);

  Future<void> uploadFile({
    required Uint8List bytes,
    required String name,
    required WidgetRef ref,
    String? folderId,
    String? fileType,
    String? description,
    List<String>? tags,
  }) async {
    state = UploadStatus.uploading;
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: name),
        if (folderId != null) 'folder': folderId,
        if (fileType != null) 'file_type': fileType,
        if (description != null) 'description': description,
        if (tags != null) 'tags': tags,
      });

      // Użyj Twojego ApiServices.post
      final resp = await ApiServices.post(
        "https://www.superbee.cloud/storage/upload/",
        formData: formData,
        hasToken: true,
      );

      if (resp != null && resp.statusCode == 201) {
        state = UploadStatus.success;
      } else {
        state = UploadStatus.failure;
      }
    } catch (e) {
      state = UploadStatus.failure;
    }
  }
}



// class UniversalFileDropZone extends ConsumerStatefulWidget {
//   final String? folderId; // ID folderu, jeśli wrzucasz do konkretnego folderu
//   const UniversalFileDropZone({super.key, this.folderId});

//   @override
//   ConsumerState<UniversalFileDropZone> createState() => _UniversalFileDropZoneState();
// }

// class _UniversalFileDropZoneState extends ConsumerState<UniversalFileDropZone> {
//   late DropzoneViewController dropzoneController;
//   bool highlighted = false;

//   void _handleFile(Uint8List bytes, String name) async {
//     await ref.read(fileUploadProvider.notifier).uploadFile(
//       bytes: bytes,
//       name: name,
//       ref: ref,
//       folderId: widget.folderId,
//     );
//   }

//   Future<void> _onPickFiles() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
//     if (result != null && result.files.single.bytes != null) {
//       _handleFile(result.files.single.bytes!, result.files.single.name);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final uploadStatus = ref.watch(fileUploadProvider);

//     return Card(
//       color: Colors.black26,
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: kIsWeb
//             ? Stack(
//                 children: [
//                   DropzoneView(
//                     onCreated: (ctrl) => dropzoneController = ctrl,
//                     onDrop: (ev) async {
//                       setState(() => highlighted = false);
//                       final name = await dropzoneController.getFilename(ev);
//                       final bytes = await dropzoneController.getFileData(ev);
//                       _handleFile(bytes, name);
//                     },
//                     onHover: () => setState(() => highlighted = true),
//                     onLeave: () => setState(() => highlighted = false),
//                   ),
//                   Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.cloud_upload, size: 64, color: highlighted ? Colors.blueAccent : Colors.white54),
//                         const SizedBox(height: 12),
//                         Text(
//                           highlighted ? "Upuść plik, aby załadować" : "Przeciągnij i upuść pliki tutaj lub kliknij, aby wybrać",
//                           style: TextStyle(color: highlighted ? Colors.blueAccent : Colors.white70),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _onPickFiles,
//                           child: const Text("Wybierz plik"),
//                         ),
//                         const SizedBox(height: 16),
//                         if (uploadStatus == UploadStatus.uploading) ...[
//                           const CircularProgressIndicator(),
//                           const SizedBox(height: 8),
//                           const Text("Wysyłanie pliku...")
//                         ] else if (uploadStatus == UploadStatus.success) ...[
//                           const Icon(Icons.check_circle, color: Colors.green, size: 32),
//                           const Text("Plik przesłany!"),
//                         ] else if (uploadStatus == UploadStatus.failure) ...[
//                           const Icon(Icons.error, color: Colors.red, size: 32),
//                           const Text("Błąd podczas uploadu!"),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               )
//             : InkWell(
//                 onTap: _onPickFiles,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.cloud_upload, size: 64, color: Colors.white54),
//                     const SizedBox(height: 12),
//                     const Text("Kliknij, aby wybrać plik", style: TextStyle(color: Colors.white70)),
//                     const SizedBox(height: 16),
//                     if (uploadStatus == UploadStatus.uploading) ...[
//                       const CircularProgressIndicator(),
//                       const SizedBox(height: 8),
//                       const Text("Wysyłanie pliku...")
//                     ] else if (uploadStatus == UploadStatus.success) ...[
//                       const Icon(Icons.check_circle, color: Colors.green, size: 32),
//                       const Text("Plik przesłany!"),
//                     ] else if (uploadStatus == UploadStatus.failure) ...[
//                       const Icon(Icons.error, color: Colors.red, size: 32),
//                       const Text("Błąd podczas uploadu!"),
//                     ],
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }
