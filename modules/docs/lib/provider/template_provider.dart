import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/models/document_temp.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final templateProvider =
    StateNotifierProvider<TemplateNotifier, AsyncValue<DocumentTemplate?>>(
  (ref) => TemplateNotifier(),
);

class TemplateNotifier extends StateNotifier<AsyncValue<DocumentTemplate?>> {
  TemplateNotifier() : super(const AsyncValue.data(null));

  Future<void> fetchTemplate(String templateId, dynamic ref) async {
    state = const AsyncValue.loading();

    try {
      final template = await DocumentService.getTemplate(templateId, ref);
      state = AsyncValue.data(template);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void setTemplate(DocumentTemplate template) {
    state = AsyncValue.data(template);
  }

  void updateTemplateContent(
    Map<String, dynamic> deltaJson,
    Map<String, dynamic> styleJson,
  ) {
    state.whenData((template) {
      if (template == null) return;

      state = AsyncValue.data(
        template.copyWith(
          deltaJson: deltaJson,
          styleJson: styleJson,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void updateFields(List<DocumentTemplateField> fields) {
    state.whenData((template) {
      if (template == null) return;

      state = AsyncValue.data(
        template.copyWith(formFields: fields),
      );
    });
  }

  void clearTemplate() {
    state = const AsyncValue.data(null);
  }
}