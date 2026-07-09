import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/api/doc_web_socket.dart';
import 'package:docs/models/document.dart';
import 'package:docs/models/document_temp.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final documentFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});
final templateFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final documentLoadingProvider = StateProvider<bool>((ref) => false);

final documentWebSocketConnectedProvider = StateProvider<bool>((ref) => false);

final documentPresenceProvider =
    StateProvider<Map<String, DocumentPresenceUser>>((ref) => {});

final documentsProvider =
    FutureProvider.family<List<Documents>, Map<String, dynamic>>(
  (ref, filters) async {
    return DocumentService.getDocumentsWithFilters(
      ref: ref,
      queryParams: filters.isEmpty ? null : filters,
    );
  },
);

final documentTemplatesProvider =
    FutureProvider.family<List<DocumentTemplate>, Map<String, dynamic>>(
  (ref, filters) async {
    return DocumentService.getTemplatesWithFilters(
      ref: ref,
      queryParams: filters.isEmpty ? null : filters,
    );
  },
);

final documentTitlesProvider = StateProvider<Map<String, String>>((ref) => {});

final documentProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<Documents?>>(
  (ref) => DocumentNotifier(),
);

/// IMPORTANT:
/// Do not use autoDispose here.
/// This service is read from the editor with ref.read(...), and autoDispose can
/// kill it immediately after the frame if nothing watches it directly.
final documentWebSocketProvider = Provider<DocumentWebSocketService>((ref) {
  final service = DocumentWebSocketService(ref);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class DocumentNotifier extends StateNotifier<AsyncValue<Documents?>> {
  DocumentNotifier() : super(const AsyncValue.data(null));

  Future<void> fetchDocument(String documentId, dynamic ref) async {
    if (!mounted) return;

    state = const AsyncValue.loading();

    try {
      final document = await DocumentService.getDocument(documentId, ref);

      if (!mounted) return;

      state = AsyncValue.data(document);
    } catch (error, stackTrace) {
      if (!mounted) return;

      state = AsyncValue.error(error, stackTrace);
    }
  }

  void setDocument(Documents document) {
    if (!mounted) return;

    state = AsyncValue.data(document);
  }

  void setInitialContent(
    Map<String, dynamic> delta,
    Map<String, dynamic> style, {
    int? revision,
    String? title,
    String? status,
    bool? isFinalized,
    String? lastEditedByUsername,
  }) {
    if (!mounted) return;

    state.whenData((document) {
      if (!mounted) return;
      if (document == null) return;

      state = AsyncValue.data(
        document.copyWith(
          currentDelta: delta,
          currentStyle: style,
          revision: revision,
          title: title,
          status: status,
          isFinalized: isFinalized,
          lastEditedByUsername: lastEditedByUsername,
        ),
      );
    });
  }

  void updateDocumentContent(
    Map<String, dynamic> delta,
    Map<String, dynamic> style, {
    int? revision,
    String? title,
    String? status,
    bool? isFinalized,
    String? lastEditedByUsername,
  }) {
    if (!mounted) return;

    state.whenData((document) {
      if (!mounted) return;
      if (document == null) return;

      state = AsyncValue.data(
        document.copyWith(
          currentDelta: delta,
          currentStyle: style,
          revision: revision,
          title: title,
          status: status,
          isFinalized: isFinalized,
          lastEditedByUsername: lastEditedByUsername,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void updateLocalTitle(String newTitle, WidgetRef ref) {
    if (!mounted) return;

    state.whenData((document) {
      if (!mounted) return;
      if (document == null) return;

      ref.read(documentTitlesProvider.notifier).update((state) {
        return {
          ...state,
          document.id: newTitle,
        };
      });

      this.state = AsyncValue.data(
        document.copyWith(title: newTitle),
      );
    });
  }

  String getLocalTitle(WidgetRef ref) {
    return state.when(
      data: (document) {
        if (document == null) return 'Untitled Document';

        final localTitles = ref.read(documentTitlesProvider);

        return localTitles[document.id] ??
            document.title.trim().ifEmpty('Untitled Document');
      },
      loading: () => 'Loading...',
      error: (_, __) => 'Untitled Document',
    );
  }

  int getCurrentRevision() {
    return state.maybeWhen(
      data: (document) => document?.revision ?? 0,
      orElse: () => 0,
    );
  }

  void clearDocument() {
    if (!mounted) return;

    state = const AsyncValue.data(null);
  }
}

extension _StringFallbackX on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}