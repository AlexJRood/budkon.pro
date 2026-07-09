import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EmmaChatPresentation {
  embedded,
  popup,
}

@immutable
class EmmaChatPresentationState {
  final EmmaChatPresentation mode;

  /// Who requested popup (stack-like, but simple set is enough)
  final Set<String> owners;

  const EmmaChatPresentationState({
    required this.mode,
    required this.owners,
  });

  factory EmmaChatPresentationState.initial() => const EmmaChatPresentationState(
        mode: EmmaChatPresentation.embedded,
        owners: <String>{},
      );

  EmmaChatPresentationState copyWith({
    EmmaChatPresentation? mode,
    Set<String>? owners,
  }) =>
      EmmaChatPresentationState(
        mode: mode ?? this.mode,
        owners: owners ?? this.owners,
      );

  bool get isPopup => mode == EmmaChatPresentation.popup;
}

class EmmaChatPresentationNotifier
    extends StateNotifier<EmmaChatPresentationState> {
  EmmaChatPresentationNotifier()
      : super(EmmaChatPresentationState.initial());

  void requestPopup({required String ownerKey}) {
    final nextOwners = {...state.owners, ownerKey};
    state = state.copyWith(
      owners: nextOwners,
      mode: EmmaChatPresentation.popup,
    );
  }

  void releasePopup({required String ownerKey}) {
    if (!state.owners.contains(ownerKey)) return;
    final nextOwners = {...state.owners}..remove(ownerKey);

    state = state.copyWith(
      owners: nextOwners,
      mode: nextOwners.isEmpty
          ? EmmaChatPresentation.embedded
          : EmmaChatPresentation.popup,
    );
  }

  void forceEmbedded() {
    state = state.copyWith(
      owners: <String>{},
      mode: EmmaChatPresentation.embedded,
    );
  }
}

final emmaChatPresentationProvider = StateNotifierProvider<
    EmmaChatPresentationNotifier,
    EmmaChatPresentationState>((ref) {
  return EmmaChatPresentationNotifier();
});
