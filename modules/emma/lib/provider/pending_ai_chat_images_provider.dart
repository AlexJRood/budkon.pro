// Add this near your other AI providers
import 'package:emma/provider/emma_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/widgets/message_bubble.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:emma/widgets/avatar_widget.dart';
import 'package:core/theme/lottie.dart';

final pendingAiChatImagesProvider = StateNotifierProvider<PendingAiChatImagesNotifier, List<PendingDropImage>>(
      (ref) => PendingAiChatImagesNotifier(),
);

class PendingAiChatImagesNotifier extends StateNotifier<List<PendingDropImage>> {
  PendingAiChatImagesNotifier() : super(const []);

  void addAll(List<PendingDropImage> items) {
    if (items.isEmpty) return;
    state = [...state, ...items];
  }

  void addOne(PendingDropImage item) {
    state = [...state, item];
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state]..removeAt(index);
    state = next;
  }

  void clear() {
    state = const [];
  }
}


class PendingDropImage {
  final String clientId; // ✅ NEW
  final Uint8List bytes;
  final String name;

  const PendingDropImage({
    required this.clientId,
    required this.bytes,
    required this.name,
  });
}