import 'package:flutter_riverpod/flutter_riverpod.dart';

final nmTagInputProvider = StateNotifierProvider.family<NMTagInputNotifier, NMTagInputState, String>(
  (ref, id) => NMTagInputNotifier(),
);

class NMTagInputState {
  final List<String> items;
  final String currentText;
  
  NMTagInputState({
    required this.items,
    required this.currentText,
  });
  
  NMTagInputState copyWith({
    List<String>? items,
    String? currentText,
  }) {
    return NMTagInputState(
      items: items ?? this.items,
      currentText: currentText ?? this.currentText,
    );
  }
}

class NMTagInputNotifier extends StateNotifier<NMTagInputState> {
  NMTagInputNotifier() : super(NMTagInputState(items: [], currentText: ''));

  void updateText(String text) {
    state = state.copyWith(currentText: text);
  }

  void addItem(String item) {
    if (item.trim().isNotEmpty && !state.items.contains(item.trim())) {
      state = state.copyWith(
        items: [...state.items, item.trim()],
        currentText: '',
      );
    }
  }

  void removeItem(String item) {
    state = state.copyWith(
      items: state.items.where((i) => i != item).toList(),
    );
  }

  void clearText() {
    state = state.copyWith(currentText: '');
  }

  void setItems(List<String> items) {
    state = state.copyWith(items: items);
  }

  void clearAll() {
    state = NMTagInputState(items: [], currentText: '');
  }
}