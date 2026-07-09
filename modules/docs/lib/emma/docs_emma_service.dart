// docs/lib/emma/docs_emma_service.dart
//
// Helper for managing Emma context from the docs screen.
// Call setDocumentContext when a document is opened,
// setSelectedText when user selects text in the editor,
// and clearDocumentContext when the screen is closed.
import 'package:emma/provider/context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocsEmmaService {
  const DocsEmmaService._();

  static void setDocumentContext(
    WidgetRef ref, {
    required String documentId,
    String? selectedText,
    String? contactId,
    String? contactType,
  }) {
    ref.read(emmaContextProvider.notifier).setModuleContext(<String, dynamic>{
      'document_id': documentId,
      if (selectedText != null && selectedText.isNotEmpty)
        'selected_text': selectedText
      else
        'selected_text': null,
      if (contactId != null && contactId.isNotEmpty)
        'contact_id': contactId
      else
        'contact_id': null,
      if (contactType != null && contactType.isNotEmpty)
        'contact_type': contactType
      else
        'contact_type': null,
    });
  }

  static void setSelectedText(WidgetRef ref, String? text) {
    ref.read(emmaContextProvider.notifier).setModuleContext(<String, dynamic>{
      'selected_text': (text != null && text.trim().isNotEmpty) ? text.trim() : null,
    });
  }

  static void clearDocumentContext(WidgetRef ref) {
    ref.read(emmaContextProvider.notifier).clearModuleContext();
  }
}
