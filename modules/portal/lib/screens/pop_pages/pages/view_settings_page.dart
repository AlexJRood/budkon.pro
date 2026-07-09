import 'dart:ui' as ui;
import 'package:portal/bars/top_app_bar_portal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/feed/components/map/map_style_selector.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/common/currency_config.dart';

// Global providers
final excludeFavoritesProvider = StateProvider<bool>((ref) => false);
final excludeHideProvider = StateProvider<bool>((ref) => false);
final excludeDisplayedProvider = StateProvider<bool>((ref) => false);

class ViewSettingsPage extends ConsumerStatefulWidget {
  final Offset? buttonPosition;
  final bool isTopAppbar;

  const ViewSettingsPage({
    super.key,
    this.buttonPosition,
    this.isTopAppbar = false,
  });

  @override
  ViewSettingsPopState createState() => ViewSettingsPopState();
}

class ViewSettingsPopState extends ConsumerState<ViewSettingsPage> {
  late final TextEditingController searchController;
  late final TextEditingController excludeController;
  late final TextEditingController minPriceController;
  late final TextEditingController maxPriceController;
  late final FocusNode _dropdownFocusNode;

  bool _excludeFavorites = false;
  bool _excludeHide = false;
  bool _excludeDisplayed = false;

  @override
  void initState() {
    super.initState();

    final filterNotifier = ref.read(filterProvider.notifier);

    searchController = TextEditingController(
      text: filterNotifier.searchQuery,
    );
    excludeController = TextEditingController(
      text: filterNotifier.excludeQuery,
    );
    minPriceController = TextEditingController(
      text: filterNotifier.filters['min_price']?.toString() ?? '',
    );
    maxPriceController = TextEditingController(
      text: filterNotifier.filters['max_price']?.toString() ?? '',
    );

    _dropdownFocusNode = FocusNode();
    _dropdownFocusNode.addListener(_handleDropdownFocusChange);
  }

  void _handleDropdownFocusChange() {
    if (!mounted) return;

    final isDropdownOpen = _dropdownFocusNode.hasFocus;
    final isViewOpen = ref.read(isViewSettingPageProvider);

    if (isDropdownOpen && !isViewOpen) {
      ref.read(isViewSettingPageProvider.notifier).state = true;
    } else if (!isDropdownOpen && isViewOpen) {
      ref.read(isViewSettingPageProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _dropdownFocusNode.removeListener(_handleDropdownFocusChange);

    searchController.dispose();
    excludeController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    _dropdownFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    _excludeFavorites = ref.watch(excludeFavoritesProvider);
    _excludeHide = ref.watch(excludeHideProvider);
    _excludeDisplayed = ref.watch(excludeDisplayedProvider);

    final theme = ref.watch(themeColorsProvider);
    final selectedCurrency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (!widget.isTopAppbar)
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withAlpha((255 * 0.5).toInt()),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Hero(
            tag: 'view-settings-hero',
            child: Padding(
              padding: widget.buttonPosition != null
                  ? EdgeInsets.only(
                      left: widget.buttonPosition!.dx,
                      top: widget.buttonPosition!.dy,
                    )
                  : EdgeInsets.only(
                      left: screenWidth * 0.1,
                      top: screenHeight * 0.05,
                    ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: Container(
                  width: 250,
                  height: 450,
                  padding: const EdgeInsets.all(20),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: widget.isTopAppbar ? 0 : 50,
                      sigmaY: widget.isTopAppbar ? 0 : 50,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Text(
                                  'Currency'.tr,
                                  style: AppTextStyles.interRegular14.copyWith(
                                    color: theme.textColor,
                                  ),
                                ),
                                const Spacer(),
                                DropdownButton<String>(
                                  focusNode: _dropdownFocusNode,
                                  dropdownColor: theme.dashboardContainer,
                                  value: selectedCurrency,
                                  onChanged: (String? newValue) {
                                    if (newValue == null) return;

                                    ref
                                        .read(currencyProvider.notifier)
                                        .setCurrency(newValue);

                                    ref
                                        .read(filterCacheProvider.notifier)
                                        .setSelectedCurrency(newValue);

                                    ref
                                        .read(filterProvider.notifier)
                                        .applyFiltersFromCache(
                                          ref.read(filterCacheProvider.notifier),
                                          ref,
                                        );

                                    if (ref.read(isViewSettingPageProvider)) {
                                      ref
                                          .read(
                                            isViewSettingPageProvider.notifier,
                                          )
                                          .state = false;
                                    }

                                    _dropdownFocusNode.unfocus();
                                  },
                                  items: <String>[
                                    'PLN',
                                    'EUR',
                                    'USD',
                                    'GBP',
                                    'CZK',
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          color: theme.textColor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          if (isUserLoggedIn) ...[
                            Material(
                              color: Colors.transparent,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Liked'.tr,
                                    style: AppTextStyles.interRegular14.copyWith(
                                      color: theme.textColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _excludeFavorites,
                                    onChanged: (value) {
                                      ref
                                          .read(
                                            excludeFavoritesProvider.notifier,
                                          )
                                          .state = value;
                                      ref
                                          .read(filterCacheProvider.notifier)
                                          .addFilter(
                                            'exclude_favorites',
                                            value ? 'true' : 'false',
                                          );
                                      ref
                                          .read(filterProvider.notifier)
                                          .applyFiltersFromCache(
                                            ref.read(filterCacheProvider.notifier),
                                            ref,
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'hidden'.tr,
                                    style: AppTextStyles.interRegular14.copyWith(
                                      color: theme.textColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _excludeHide,
                                    onChanged: (value) {
                                      ref
                                          .read(excludeHideProvider.notifier)
                                          .state = value;
                                      ref
                                          .read(filterCacheProvider.notifier)
                                          .addFilter(
                                            'exclude_hide',
                                            value ? 'true' : 'false',
                                          );
                                      ref
                                          .read(filterProvider.notifier)
                                          .applyFiltersFromCache(
                                            ref.read(filterCacheProvider.notifier),
                                            ref,
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'displayed'.tr,
                                    style: AppTextStyles.interRegular14.copyWith(
                                      color: theme.textColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _excludeDisplayed,
                                    onChanged: (value) {
                                      ref
                                          .read(
                                            excludeDisplayedProvider.notifier,
                                          )
                                          .state = value;
                                      ref
                                          .read(filterCacheProvider.notifier)
                                          .addFilter(
                                            'exclude_displayed',
                                            value ? 'true' : 'false',
                                          );
                                      ref
                                          .read(filterProvider.notifier)
                                          .applyFiltersFromCache(
                                            ref.read(filterCacheProvider.notifier),
                                            ref,
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: Row(
                                children:  [
                                  Expanded(
                                    child: MapStyleSelector(
                                      compact: false,
                                      onMenuOpened: () {
                                        ref.read(isViewSettingPageProvider.notifier).state = true;
                                      },
                                      onMenuClosed: () {
                                        ref.read(isViewSettingPageProvider.notifier).state = false;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}