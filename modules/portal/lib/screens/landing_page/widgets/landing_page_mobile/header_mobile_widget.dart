import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:portal/screens/filters/filters_page.dart';
import 'package:portal/widgets/landing_page_pc/components/category_buttons.dart';
import 'package:portal/widgets/landing_page_pc/components/filter_buttons.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:portal/screens/landing_page/providers/landing_page_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:portal/widgets/landing_page_pc/components/filters_widget.dart';
import 'package:portal/widgets/landing_page_pc/components/filter_popup_controller.dart';
import 'dart:ui' as ui;
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter/foundation.dart';

import 'package:get/get_utils/get_utils.dart';

class HeaderWidgetMobile extends ConsumerStatefulWidget {
  final bool isMobile;
  const HeaderWidgetMobile({super.key, this.isMobile = false});

  @override
  ConsumerState<HeaderWidgetMobile> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends ConsumerState<HeaderWidgetMobile> {
  final Map<PopupType, GlobalKey> _itemKeys = {
    PopupType.location: GlobalKey(),
    PopupType.property: GlobalKey(),
    PopupType.price: GlobalKey(),
    PopupType.meter: GlobalKey(),
  };

  String selectedCategory = 'BUY'.tr;
  late LandingFilterPopupController _popupController;

  // ✅ Cache controllers so we don't touch ref in dispose()
  late final StateController<bool> _isLocationVisibleCtrl;
  late final StateController<bool> _isPropertyVisibleCtrl;
  late final StateController<bool> _isPriceSelectedCtrl;
  late final StateController<bool> _isMeterRangeVisibleCtrl;

  @override
  void initState() {
    super.initState();

    // ✅ ref is allowed here
    _isLocationVisibleCtrl = ref.read(isLocationVisibleProvider.notifier);
    _isPropertyVisibleCtrl = ref.read(isPropertyVisibleProvider.notifier);
    _isPriceSelectedCtrl = ref.read(isPriceSelectedProvider.notifier);
    _isMeterRangeVisibleCtrl = ref.read(isSelectedMeterRangeProvider.notifier);

    _popupController = LandingFilterPopupController(
      ref: ref,
      context: context,
      itemKeys: _itemKeys,
    );
  }

  @override
  void dispose() {
    // ✅ NO ref usage in dispose()
    _isLocationVisibleCtrl.state = false;
    _isPropertyVisibleCtrl.state = false;
    _isPriceSelectedCtrl.state = false;
    _isMeterRangeVisibleCtrl.state = false;

    _popupController.dispose();
    super.dispose();
  }
  Future<void> _openMobileSheet(PopupType type) async {
    switch (type) {
      case PopupType.location:
        ref.read(isLocationVisibleProvider.notifier).state = true;
        break;
      case PopupType.property:
        ref.read(isPropertyVisibleProvider.notifier).state = true;
        break;
      case PopupType.price:
        ref.read(isPriceSelectedProvider.notifier).state = true;
        break;
      case PopupType.meter:
        ref.read(isSelectedMeterRangeProvider.notifier).state = true;
        break;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.55,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollController) {
            switch (type) {
              case PopupType.location:
                return LocationSearchWidget(
                  isMobile: true,
                  scrollController: scrollController,
                  onClose: () {
                    ref.read(isLocationVisibleProvider.notifier).state = false;
                  }, 
                  providerKey: 'portal',
                );

              case PopupType.property:
                return PropertyTypes(
                  isMobile: true,
                  scrollController: scrollController,
                  onClose: () {
                    ref.read(isPropertyVisibleProvider.notifier).state = false;
                  },
                );

              case PopupType.price:
                return PriceRangeWidget(
                  isMobile: true,
                  scrollController: scrollController,
                  onClose: () {
                    ref.read(isPriceSelectedProvider.notifier).state = false;
                  },
                );

              case PopupType.meter:
                return MeterRangeWidget(
                  isMobile: true,
                  scrollController: scrollController,
                  onClose: () {
                    ref.read(isSelectedMeterRangeProvider.notifier).state =
                        false;
                  },
                );
            }
          },
        );
      },
    ).whenComplete(() {
      ref.read(isLocationVisibleProvider.notifier).state = false;
      ref.read(isPropertyVisibleProvider.notifier).state = false;
      ref.read(isPriceSelectedProvider.notifier).state = false;
      ref.read(isSelectedMeterRangeProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final currentthememode = ref.read(themeProvider);
    final landing =
        currentthememode == ThemeMode.system
            ? 'assets/images/landing_light.webp'
            : currentthememode == ThemeMode.light
            ? 'assets/images/hero-section(3).webp'
            : 'assets/images/landing_light.webp';

    return Stack(
      children: [
        Container(
          height: 700,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(landing),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(
          height: 900,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 40,
                  ),
                  child: Column(
                    spacing: 20,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connecting you to the\nperfect property – Effortlessly!'.tr,
                        style: AppTextStyles.libreCaslonHeading.copyWith(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                       'team_mission_description'.tr,
                        style: AppTextStyles.interMedium14.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            color: theme.adPopBackground.withAlpha(
                              (255 * 0.35).toInt(),
                            ),
                            width: double.infinity,
                            child: Column(
                              children: [
                                CategorySelector(
                                  selectedCategory: selectedCategory,
                                  onCategorySelected: (category) {
                                    setState(() {
                                      selectedCategory = category;
                                    });
                                  },
                                  tabs: ['BUY'.tr, 'RENT'.tr, 'INVEST'.tr],
                                  isMobile: widget.isMobile,
                                ),
                                SelectionButton(
                                  isMobile: true,
                                  title: 'Location'.tr,
                                  value:
                                      ref
                                              .watch(selectedLocationProvider)
                                              .isEmpty
                                          ? 'All locations'.tr
                                          : ref.watch(selectedLocationProvider),
                                  onPressed: () {
                                    if (widget.isMobile) {
                                      _openMobileSheet(PopupType.location);
                                    } else {
                                      _popupController.togglePopup(
                                        PopupType.location,
                                      );
                                    }
                                  },
                                  buttonKey: _itemKeys[PopupType.location],
                                ),

                                SelectionButton(
                                  isMobile: true,
                                  title: 'property_type'.tr,
                                  value:
                                      ref
                                              .watch(selectedPropertyProvider)
                                              .isEmpty
                                          ? 'All property types'.tr
                                          : ref.watch(selectedPropertyProvider),
                                  onPressed: () {
                                    if (widget.isMobile) {
                                      _openMobileSheet(PopupType.property);
                                    } else {
                                      _popupController.togglePopup(
                                        PopupType.property,
                                      );
                                    }
                                  },
                                  buttonKey: _itemKeys[PopupType.property],
                                ),

                                SelectionButton(
                                  isMobile: true,
                                  title: 'Price range'.tr,
                                  value:
                                      ref
                                              .watch(selectedPriceRangeProvider)
                                              .isEmpty
                                          ? 'Choose price range'.tr
                                          : ref.watch(
                                            selectedPriceRangeProvider,
                                          ),
                                  onPressed: () {
                                    if (widget.isMobile) {
                                      _openMobileSheet(PopupType.price);
                                    } else {
                                      _popupController.togglePopup(
                                        PopupType.price,
                                      );
                                    }
                                  },
                                  buttonKey: _itemKeys[PopupType.price],
                                ),

                                SelectionButton(
                                  isMobile: true,
                                  title: 'Meter range'.tr,
                                  value:
                                      ref
                                              .watch(selectedMeterRangeProvider)
                                              .isEmpty
                                          ? 'Choose meter range'.tr
                                          : ref.watch(
                                            selectedMeterRangeProvider,
                                          ),
                                  onPressed: () {
                                    if (widget.isMobile) {
                                      _openMobileSheet(PopupType.meter);
                                    } else {
                                      _popupController.togglePopup(
                                        PopupType.meter,
                                      );
                                    }
                                  },
                                  buttonKey: _itemKeys[PopupType.meter],
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(6),
                                                ),
                                            border: Border.all(
                                              color: const Color.fromRGBO(
                                                200,
                                                200,
                                                200,
                                                1,
                                              ),
                                            ),
                                          ),
                                          child: ElevatedButton(
                                            style: buttonStyleRounded10ThemeRed,
                                            onPressed: () {
                                              ref
                                                  .read(filterProvider.notifier)
                                                  .applyFiltersFromCache(
                                                    ref.read(
                                                      filterCacheProvider
                                                          .notifier,
                                                    ),
                                                    ref,
                                                  );
                                              ref
                                                  .read(filterProvider.notifier)
                                                  .applyFilters(ref)
                                                  .whenComplete(() {
                                                    final data = ref.read(
                                                      filterCacheProvider,
                                                    );
                                                    if (kDebugMode) print(data);
                                                  });

                                              String selectedFeedView = ref
                                                  .read(
                                                    selectedFeedViewProvider,
                                                  );
                                              ref
                                                  .read(navigationService)
                                                  .pushNamedReplacementScreen(
                                                    selectedFeedView,
                                                  );
                                            },
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                spacing: 15,
                                                children: [
                                                  AppIcons.search(
                                                    color: AppColors.white,
                                                  ),
                                                  Text(
                                                    'Search'.tr,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        style:
                                            elevatedButtonStyleRounded6withoutPaddingWhite,
                                        onPressed: () {
                                          if (widget.isMobile) {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            6,
                                                          ),
                                                        ),
                                                  ),
                                              builder: (context) {
                                                final bottomInset = MediaQuery.of(context).viewInsets.bottom;

                                                return AnimatedPadding(
                                                  duration: const Duration(milliseconds: 250),
                                                  curve: Curves.easeOut,
                                                  padding: EdgeInsets.only(bottom: bottomInset),
                                                  child: DraggableScrollableSheet(
                                                    initialChildSize: 0.85,
                                                    minChildSize: 0.4,
                                                    maxChildSize: 0.95,
                                                    expand: false,
                                                    builder: (ctx, scrollController) => FiltersPage(
                                                      tag: UniqueKey().toString(),
                                                      isNeedToNavigate: true,
                                                      scrollController: scrollController,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          } else {
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                opaque: false,
                                                pageBuilder:
                                                    (_, __, ___) => FiltersPage(
                                                      tag:
                                                          UniqueKey()
                                                              .toString(),
                                                      isNeedToNavigate: true,
                                                    ),
                                                transitionsBuilder: (
                                                  _,
                                                  anim,
                                                  __,
                                                  child,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: anim,
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          }
                                        },
                                        child: AppIcons.filterAlt(
                                          color: const Color.fromRGBO(
                                            35,
                                            35,
                                            35,
                                            1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
