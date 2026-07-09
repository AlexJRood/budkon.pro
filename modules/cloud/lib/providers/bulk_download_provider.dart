import 'dart:typed_data';
import 'package:cloud/cloud_urls.dart';

import 'package:cloud/providers/providers.dart';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/provider/cloud_selection_controller.dart';

import 'package:cloud/utils/download/web_download_stub.dart'
if (dart.library.html) 'package:cloud/utils/download/web_download.dart';

class BulkDownloadState {
  final bool isLoading;
  final String? error;

  const BulkDownloadState({
    this.isLoading = false,
    this.error,
  });

  BulkDownloadState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BulkDownloadState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BulkDownloadNotifier extends StateNotifier<BulkDownloadState> {
  BulkDownloadNotifier(this.ref) : super(const BulkDownloadState());

  final Ref ref;

  Future<bool> downloadZip({
    required List<String> fileIds,
    required List<String> folderIds,
    bool recursive = true,
  }) async {
    if (state.isLoading) return false;

    if (fileIds.isEmpty && folderIds.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Nothing selected',
      );
      return false;
    }

    state = const BulkDownloadState(isLoading: true);
    ref.read(isDownloadingProvider.notifier).state = true;

    try {
      final headers = await ApiServices.buildHeaders(
        hasToken: true,
        ref: ref,
      );

      debugPrint('ZIP headers: $headers');
      final response = await ApiServices.post(
        CloudUrls.exploreDownloadZip,
        hasToken: true,
        ref: ref,
        responseType: ResponseType.bytes,
        data: {
          'files': fileIds,
          'folders': folderIds,
          'recursive': recursive,
        },
      );
      debugPrint('ZIP status: ${response?.statusCode}');
      debugPrint('ZIP response type: ${response?.data.runtimeType}');
      if (response?.data is List<int>) {
        debugPrint('ZIP byte length: ${(response!.data as List<int>).length}');
      }
      debugPrint('Selected files: $fileIds');
      debugPrint('Selected folders: $folderIds');
      debugPrint('Recursive: $recursive');

      if (response == null) {
        throw Exception('ZIP request failed');
      }

      final statusCode = response.statusCode ?? 500;
      if (statusCode >= 400) {
        throw Exception('ZIP request failed: $statusCode');
      }

      final raw = response.data;

      late final Uint8List uint8Bytes;
      if (raw is Uint8List) {
        uint8Bytes = raw;
      } else if (raw is List<int>) {
        uint8Bytes = Uint8List.fromList(raw);
      } else {
        throw Exception('Unexpected ZIP response type: ${raw.runtimeType}');
      }

      if (uint8Bytes.isEmpty) {
        throw Exception('ZIP file is empty');
      }

      if (kIsWeb) {
        await webDownloadBytes(
          uint8Bytes,
          'cloud_selection.zip',
          mimeType: 'application/zip',
        );

        state = const BulkDownloadState(isLoading: false);
        ref.read(isDownloadingProvider.notifier).state = false;
        return true;
      } else {
        final result = await FileSaver.instance.saveAs(
          name: 'cloud_selection',
          bytes: uint8Bytes,
          fileExtension: 'zip',
          mimeType: MimeType.other,
          includeExtension: true,
        );

        final savedSuccessfully = result != null &&
            (!(result is String) || result.trim().isNotEmpty);

        state = const BulkDownloadState(isLoading: false);
        ref.read(isDownloadingProvider.notifier).state = false;
        return savedSuccessfully;
      }
    } catch (e) {
      state = BulkDownloadState(
        isLoading: false,
        error: e.toString(),
      );
      ref.read(isDownloadingProvider.notifier).state = false;
      rethrow;
    }
  }

  Future<bool> downloadCurrentSelectionAsZip() async {
    final selection = ref.read(cloudSelectionProvider);

    return await downloadZip(
      fileIds: selection.selectedFileIds.toList(),
      folderIds: selection.selectedFolderIds.toList(),
      recursive: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final bulkDownloadProvider =
StateNotifierProvider<BulkDownloadNotifier, BulkDownloadState>(
      (ref) => BulkDownloadNotifier(ref),
);