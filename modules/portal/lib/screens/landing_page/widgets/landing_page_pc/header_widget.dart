import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/landing_page/providers/landing_page_provider.dart';
import 'package:portal/widgets/landing_page_pc/components/filters_landing.dart';
import 'package:portal/widgets/landing_page_pc/components/filters_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';

class HeaderWidget extends ConsumerStatefulWidget {
  final double paddingDynamic;
  final bool isMobile;
  final bool isTablet;

  const HeaderWidget({
    super.key,
    required this.paddingDynamic,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  ConsumerState<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends ConsumerState<HeaderWidget> {
  final Map<PopupType, GlobalKey> _itemKeys = {
    PopupType.location: GlobalKey(),
    PopupType.property: GlobalKey(),
    PopupType.price: GlobalKey(),
    PopupType.meter: GlobalKey(),
  };

  final Map<PopupType, LayerLink> _popupLinks = {
    PopupType.location: LayerLink(),
    PopupType.property: LayerLink(),
    PopupType.price: LayerLink(),
    PopupType.meter: LayerLink(),
  };

  final FocusScopeNode _popupFocusScopeNode = FocusScopeNode(
    debugLabel: 'landing-filter-popup-scope',
  );

  final FocusNode _locationSearchFocusNode = FocusNode(
    debugLabel: 'landing-location-search',
  );

  final String _filtersHeroTag = 'landing-page-filters-cta';

  Size? _previousSize;
  BoxConstraints? _previousConstraints;
  String selectedCategory = '';
  bool _isPopupOpen = false;

  bool _isBuyCategory(String category) =>
      category.trim().toLowerCase() == 'Buy'.tr.toLowerCase();

  bool _isRentCategory(String category) =>
      category.trim().toLowerCase() == 'Rent'.tr.toLowerCase();

  bool _isDevelopersCategory(String category) =>
      category.trim().toLowerCase() == 'Developers'.tr.toLowerCase();

  String? _offerTypeFromCategory(String category) {
    if (_isRentCategory(category)) return 'rent';
    if (_isBuyCategory(category) || _isDevelopersCategory(category)) {
      return 'sell';
    }
    return null;
  }

  void _hydrateCategoryFromCache() {
    final filters = ref.read(filterCacheProvider.notifier).filters;
    final offerType = filters[FilterPopConst.offerType]?.toString();
    final marketType = filters[FilterPopConst.marketType]?.toString();

    String next = '';
    if (marketType == 'primary') {
      next = 'Developers'.tr;
    } else if (offerType == 'rent') {
      next = 'Rent'.tr;
    } else if (offerType == 'sell') {
      next = 'Buy'.tr;
    }

    if (next.isNotEmpty && next != selectedCategory && mounted) {
      setState(() {
        selectedCategory = next;
      });
    }
  }

  void _handleCategorySelected(String category) {
    final cache = ref.read(filterCacheProvider.notifier);
    final ui = ref.read(filterButtonProvider.notifier);

    final offerType = _offerTypeFromCategory(category);

    setState(() {
      selectedCategory = category;
    });

    if (offerType != null) {
      cache.addFilter(FilterPopConst.offerType, offerType);
      ui.updateFilter(FilterPopConst.offerType, offerType);
    } else {
      cache.removeFilter(FilterPopConst.offerType);
      ui.removeFilter(FilterPopConst.offerType);
    }

    if (_isDevelopersCategory(category)) {
      cache.addFilter(FilterPopConst.marketType, 'primary');
      ui.updateFilter(FilterPopConst.marketType, 'primary');
    } else {
      final currentMarket = cache.filters[FilterPopConst.marketType]?.toString();
      if (currentMarket == 'primary') {
        cache.removeFilter(FilterPopConst.marketType);
        ui.removeFilter(FilterPopConst.marketType);
      }
    }
  }

  void _togglePopup(PopupType type) {
    final currentType = ref.read(activePopupProvider);

    if (currentType == type && _isPopupOpen) {
      _closeAllPopups();
      return;
    }

    ref.read(activePopupProvider.notifier).state = type;
    _isPopupOpen = true;

    if (widget.isMobile) {
      _showPopupMobile(type);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestFocusForPopup(type);
    });
  }

  Future<void> _showPopupMobile(PopupType type) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _requestFocusForPopup(type);
        });

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: _buildPopupCard(type, isMobile: true),
          ),
        );
      },
    );

    if (!mounted) return;
    _closeAllPopups();
  }

  void _requestFocusForPopup(PopupType type) {
    _popupFocusScopeNode.requestFocus();

    if (type == PopupType.location) {
      _locationSearchFocusNode.requestFocus();
    } else {
      _locationSearchFocusNode.unfocus();
    }
  }

  void _closeAllPopups() {
    _locationSearchFocusNode.unfocus();
    _popupFocusScopeNode.unfocus();

    _isPopupOpen = false;
    ref.read(activePopupProvider.notifier).state = null;
  }

  double _popupWidthFor(PopupType type) {
    switch (type) {
      case PopupType.location:
        return widget.isTablet ? 420 : 500;
      case PopupType.property:
        return widget.isMobile? 360: 500;
      case PopupType.price:
        return widget.isMobile? 360: 500;
      case PopupType.meter:
        return widget.isMobile? 360: 500;
    }
  }

  Widget _buildPopupCard(PopupType type, {bool isMobile = false}) {
    return FocusScope(
      node: _popupFocusScopeNode,
      child: Material(
        color: Colors.transparent,
        child: PrimaryScrollController.none(
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) => true,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _popupWidthFor(type),
                maxHeight:
                    isMobile ? MediaQuery.of(context).size.height * 0.75 : 460,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: _getPopupContent(type),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPopupLayer(PopupType type) {
    final link = _popupLinks[type];
    if (link == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeAllPopups,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -12),
            child: _buildPopupCard(type),
          ),
        ],
      ),
    );
  }

  Widget _getPopupContent(PopupType type) {
    switch (type) {
      case PopupType.location:
        return LocationSearchWidget(
          providerKey: 'portal',
          isMobile: widget.isMobile,
          autofocus: true,
          closeRouteOnClose: widget.isMobile,
          searchFocusNode: _locationSearchFocusNode,
          onSelected: (sel) {
            if (!sel.isEmpty) {
              ref.read(selectedLocationProvider.notifier).state = sel.display;

              ref
                  .read(filterCacheProvider.notifier)
                  .addFilter(FilterPopConst.location, sel.display);
              ref
                  .read(filterCacheProvider.notifier)
                  .addFilter(FilterPopConst.locationType, sel.type);
              ref
                  .read(filterCacheProvider.notifier)
                  .addFilter(FilterPopConst.locationId, sel.id);
            } else {
              ref.read(selectedLocationProvider.notifier).state = '';

              ref
                  .read(filterCacheProvider.notifier)
                  .addFilter(FilterPopConst.location, '');
              ref
                  .read(filterCacheProvider.notifier)
                  .addFilter(FilterPopConst.locationType, '');
              ref
                  .read(filterCacheProvider.notifier)
                  .addFilter(FilterPopConst.locationId, '');
            }

            _closeAllPopups();
          },
          onClose: _closeAllPopups,
        );

      case PopupType.property:
        return PropertyTypes(
          onClose: _closeAllPopups,
          closeRouteOnClose: widget.isMobile,
        );

      case PopupType.price:
        return PriceRangeWidget(
          onClose: _closeAllPopups,
          closeRouteOnClose: widget.isMobile,
        );

      case PopupType.meter:
        return MeterRangeWidget(
          onClose: _closeAllPopups,
          closeRouteOnClose: widget.isMobile,
        );
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hydrateCategoryFromCache();
    });
  }

  @override
  void didUpdateWidget(covariant HeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.paddingDynamic != widget.paddingDynamic) {
      _closeAllPopups();
    }
  }

  @override
  void dispose() {
    _locationSearchFocusNode.dispose();
    _popupFocusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePopup = ref.watch(activePopupProvider);

    if (activePopup == null) {
      _isPopupOpen = false;
    }

    final currentSize = MediaQuery.of(context).size;
    if (_previousSize != null && _previousSize != currentSize && _isPopupOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _closeAllPopups();
      });
    }
    _previousSize = currentSize;

    final currentThemeMode = ref.watch(themeProvider);
    final theme = ref.watch(themeColorsProvider);

    final landing = currentThemeMode == ThemeMode.light
        ? 'assets/images/hero-section(3).webp'
        : 'assets/images/landing_light.webp';

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_isPopupOpen) return false;

        final isVertical = notification.metrics.axis == Axis.vertical;
        final isRealPageScroll = notification is UserScrollNotification ||
            notification is ScrollStartNotification ||
            notification is ScrollUpdateNotification;

        if (isVertical && isRealPageScroll) {
          _closeAllPopups();
        }

        return false;
      },
      child: Container(
        height: MediaQuery.of(context).size.height / 1.1,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(landing),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  if (_previousConstraints != null &&
                      _previousConstraints != constraints &&
                      _isPopupOpen) {
                    _closeAllPopups();
                  }

                  _previousConstraints = constraints;
                });

                return SizedBox(
                  width: constraints.maxWidth,
                  height: MediaQuery.of(context).size.height * 0.80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.paddingDynamic,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 60),
                                      Text(
                                        'Connecting you to the perfect\nproperty – Effortlessly!'
                                            .tr,
                                        style: AppTextStyles.libreCaslonHeading
                                            .copyWith(
                                          color: theme.textColor,
                                          fontSize:
                                              widget.isTablet ? 32 : 50,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      Text(
                                        "Whether you\\'re buying, selling, or renting, our dedicated team is here to\nmake the process seamless, stress-free, and tailored to your needs."
                                            .tr,
                                        style: TextStyle(
                                          fontSize:
                                              widget.isTablet ? 16 : 18,
                                          color: theme.textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                  FilterLandingpageContent(
                                    paddingDynamic: widget.paddingDynamic,
                                    selectedCategory: selectedCategory,
                                    onCategorySelected: _handleCategorySelected,
                                    popupKeys: _itemKeys,
                                    popupLinks: _popupLinks,
                                    togglePopup: _togglePopup,
                                    isTablet: widget.isTablet,
                                    heroTag: _filtersHeroTag,
                                  ),
                                  const SizedBox(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activePopup != null && !widget.isMobile)
                        _buildDesktopPopupLayer(activePopup),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}