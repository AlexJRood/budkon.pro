
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tagInputProvider = StateNotifierProvider.family<TagInputNotifier, TagInputState, String>(
  (ref, id) => TagInputNotifier(),
);

class TagInputState {
  final List<String> items;
  final String currentText;
  
  TagInputState({
    required this.items,
    required this.currentText,
  });
  
  TagInputState copyWith({
    List<String>? items,
    String? currentText,
  }) {
    return TagInputState(
      items: items ?? this.items,
      currentText: currentText ?? this.currentText,
    );
  }
}

class TagInputNotifier extends StateNotifier<TagInputState> {
  TagInputNotifier() : super(TagInputState(items: [], currentText: ''));

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
    state = TagInputState(items: [], currentText: '');
  }
}
