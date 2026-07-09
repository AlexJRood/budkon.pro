
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/widgets/landing_page_pc/components/filters_landing.dart';

final scrollPopupManagerProvider = Provider<ScrollPopupManager>((ref) {
  return ScrollPopupManager(ref);
});

class ScrollPopupManager {
  final Ref ref;

  ScrollPopupManager(this.ref);

  void onScroll() {
    final activePopup = ref.read(activePopupProvider);
    if (activePopup != null) {
      ref.read(activePopupProvider.notifier).state = null;
    }
  }

  void closeAllPopups() => ref.read(activePopupProvider.notifier).state = null;
}