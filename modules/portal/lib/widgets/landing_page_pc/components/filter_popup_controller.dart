import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/landing_page/providers/landing_page_provider.dart';
import 'package:portal/widgets/landing_page_pc/components/filters_widget.dart';

enum PopupType { location, property, price, meter }

final activePopupProvider = StateProvider<PopupType?>((ref) => null);

class LandingFilterPopupController {
  final WidgetRef ref;
  final BuildContext context;
  final Map<PopupType, GlobalKey> itemKeys;
  OverlayEntry? overlayEntry;
  Size? previousSize;
  final bool isMobile;
  BoxConstraints? previousConstraints;

  // Used only for desktop overlay outer scroll, not for mobile sheet
  final ScrollController scrollController = ScrollController();

  LandingFilterPopupController({
    required this.ref,
    required this.context,
    required this.itemKeys,
    this.isMobile = true,
  });

  Widget _buildScrollablePopupContent(PopupType type) {
    final popupContent = _getPopupContent(type);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 450,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        child: SingleChildScrollView(
          controller: scrollController,
          child: popupContent,
        ),
      ),
    );
  }

  void _showPopupPc(PopupType type) {
    final key = itemKeys[type];
    if (key == null || key.currentContext == null) return;

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final scrollablePopup = _buildScrollablePopupContent(type);

    overlayEntry?.remove();
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: closeAllPopups,
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy - 450,
            child: GestureDetector(
              onTap: () {},
              child: scrollablePopup,
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }



  void showPopup(PopupType type) {
    isMobile ? _showPopupMobile(type) : _showPopupPc(type);
  }


  void _showPopupMobile(PopupType type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return  DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: true,
              builder: (context, sheetScrollController) {
                // We pass sheetScrollController down to SelectionWidget via *_Widget
                return _getPopupContent(
                  type,
                  scrollController: sheetScrollController,
                );
              },
        );
      },
    );
  }

  void togglePopup(PopupType type) {
    final currentType = ref.read(activePopupProvider);
    if (currentType == type) {
      closeAllPopups();
    } else {
      ref.read(activePopupProvider.notifier).state = type;
      showPopup(type);
    }
  }

  void closeAllPopups() {
    ref.read(activePopupProvider.notifier).state = null;
    overlayEntry?.remove();
    overlayEntry = null;
  }

  // IMPORTANT: optional scrollController, used only on mobile
  Widget _getPopupContent(PopupType type, {ScrollController? scrollController}) {
    switch (type) {
      case PopupType.location:
        return LocationSearchWidget(
  providerKey: 'portal', // albo 'portal' – zależnie jak używasz providerów
  isMobile: isMobile,
  scrollController: scrollController,
  onSelected: (sel) {
    // przykładowo: zapis do Twoich providerów/filtrów
    if (!sel.isEmpty) {
      ref.read(selectedLocationProvider.notifier).state = sel.display; // lub sel.city
      ref.read(filterCacheProvider.notifier).addFilter('location', sel!.display);
      // jeśli potrzebujesz rozróżnienia: sel.type + sel.id
      ref.read(filterCacheProvider.notifier).addFilter('location_type', sel.type);
      ref.read(filterCacheProvider.notifier).addFilter('location_id', sel.id);
    } else {
      ref.read(selectedLocationProvider.notifier).state = '';
      ref.read(filterCacheProvider.notifier).addFilter('location', '');
      ref.read(filterCacheProvider.notifier).addFilter('location_type', '');
      ref.read(filterCacheProvider.notifier).addFilter('location_id', '');
    }
  },
  onClose: () {
    ref.read(isLocationVisibleProvider.notifier).state = false;
    // jeśli mobile bottom sheet:
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      Future.microtask(() {
        if (nav.mounted) nav.pop();
      });
    }
  },
        );
      case PopupType.property:
        return PropertyTypes(
          isMobile: isMobile,
          scrollController: scrollController,
        );
      case PopupType.price:
        return PriceRangeWidget(
          isMobile: isMobile,
          scrollController: scrollController,
        );
      case PopupType.meter:
        return MeterRangeWidget(
          isMobile: isMobile,
          scrollController: scrollController,
        );
    }
  }

  void dispose() {
    overlayEntry?.remove();
    overlayEntry = null;
    scrollController.dispose();
  }

  void handleSizeChange(Size currentSize) {
    if (previousSize != null && previousSize != currentSize) {
      closeAllPopups();
    }
    previousSize = currentSize;
  }

  void handleConstraintsChange(BoxConstraints constraints) {
    if (previousConstraints != null && constraints != previousConstraints) {
      closeAllPopups();
    }
    previousConstraints = constraints;
  }
}
