// emma/lib/provider/docs_emma_state.dart
//
// Shared state for docs-Emma integration.
// Block definitions in emma update this; docs screen watches it.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class DocsTextEditRequest {
  final String original;
  final String rewritten;
  final String instruction;

  const DocsTextEditRequest({
    required this.original,
    required this.rewritten,
    required this.instruction,
  });
}

@immutable
class DocsCreateFromContactRequest {
  final int templateId;
  final String templateName;
  final String contactId;
  final String contactType;

  const DocsCreateFromContactRequest({
    required this.templateId,
    required this.templateName,
    required this.contactId,
    required this.contactType,
  });
}

@immutable
class DocsEmmaState {
  final DocsTextEditRequest? pendingTextEdit;
  final DocsCreateFromContactRequest? pendingCreateFromContact;

  const DocsEmmaState({
    this.pendingTextEdit,
    this.pendingCreateFromContact,
  });

  DocsEmmaState _copyWith({
    DocsTextEditRequest? pendingTextEdit,
    DocsCreateFromContactRequest? pendingCreateFromContact,
    bool clearTextEdit = false,
    bool clearCreateFromContact = false,
  }) {
    return DocsEmmaState(
      pendingTextEdit: clearTextEdit ? null : (pendingTextEdit ?? this.pendingTextEdit),
      pendingCreateFromContact: clearCreateFromContact
          ? null
          : (pendingCreateFromContact ?? this.pendingCreateFromContact),
    );
  }
}

class DocsEmmaNotifier extends StateNotifier<DocsEmmaState> {
  DocsEmmaNotifier() : super(const DocsEmmaState());

  void requestTextEdit(DocsTextEditRequest request) {
    state = state._copyWith(pendingTextEdit: request);
  }

  void clearTextEdit() {
    state = state._copyWith(clearTextEdit: true);
  }

  void requestCreateFromContact(DocsCreateFromContactRequest request) {
    state = state._copyWith(pendingCreateFromContact: request);
  }

  void clearCreateFromContact() {
    state = state._copyWith(clearCreateFromContact: true);
  }
}

final docsEmmaProvider =
    StateNotifierProvider<DocsEmmaNotifier, DocsEmmaState>(
  (ref) => DocsEmmaNotifier(),
);
