import 'package:crm_agent/add_client_form/components/buy/buy_filltered_button.dart'
    hide CrmAddFilteredButton;
import 'package:crm_agent/add_client_form/components/buy/buy_from_filter_components.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_add_filltered_button.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_custom_drop_down.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_custom_text_field.dart';
import 'package:crm_agent/add_client_form/components/sell/sell_estate_filtered_button.dart'
    as sell_estate;
import 'package:crm_agent/add_client_form/components/buy/buy_estate_filtered_button.dart'
    as buy_estate;
import 'package:crm_agent/add_client_form/controllers/buy_controlers.dart';
import 'package:crm_agent/add_client_form/controllers/sell_controlers.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/widgets/event.dart';
import 'package:crm_agent/add_client_form/widgets/transaction.dart';
import 'package:crm_agent/add_client_form/widgets/transaction_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/common/autocompletion/autocomplete.dart';
import 'package:core/theme/apptheme.dart';

// ─── SELL step 1: Co sprzedaje ────────────────────────────────────────────────

class CrmSellQuickStep1 extends ConsumerWidget {
  const CrmSellQuickStep1({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final sellControllers = ref.watch(sellControllersProvider);
    final addClientFormNotifier = ref.read(addClientFormProvider.notifier);
    final sellDraft = ref.read(sellOfferFilterCacheProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(theme, 'Offer type'.tr),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CrmAddFilteredButton(
                text: 'offer_type_sell'.tr,
                filterValue: 'sell',
                filterKey: 'offer_type',
                alignment: Alignment.centerLeft,
                minHeight: 44,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CrmAddFilteredButton(
                text: 'offer_type_rent'.tr,
                filterValue: 'rent',
                filterKey: 'offer_type',
                alignment: Alignment.centerLeft,
                minHeight: 44,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _label(theme, 'property_type'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FilterPopConst.estateTypes.map((e) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
              child: sell_estate.CrmAddEstateTypeFilteredButton(
                text: e['text']!.tr,
                filterValue: e['filterValue']!,
                filterKey: 'estate_type',
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        _label(theme, 'Location'.tr),
        const SizedBox(height: 8),
        AutoCompleteWidget(
          provider: 'sell-estate-location',
          hintText: 'Search city / district'.tr,
          onQueryChanged: (ref, query) {
            sellDraft.addData('location_query', query);
            if (query.trim().isEmpty) {
              sellDraft.addData('city', '');
              sellDraft.addData('state', '');
              sellDraft.addData('district', '');
              sellDraft.addData('geo_id', '');
              sellDraft.addData('geo_type', '');
            }
          },
          onLocationChanged: (ref, sel) {
            if (!sel.isEmpty) {
              sellDraft.addData('location_selection', sel.toJson());
              sellDraft.addData('location_name', sel.name);
              sellDraft.addData('location_display', sel.display);
              sellDraft.addData('city', sel.city);
              sellDraft.addData('state', sel.state);
              sellDraft.addData('district', sel.district);
              sellDraft.addData('county', sel.county);
              sellDraft.addData('commune', sel.commune);
              sellDraft.addData('geo_id', sel.id);
              sellDraft.addData('geo_type', sel.type);
              sellDraft.addData('geo_level', sel.level);
              sellDraft.addData('country', 'Poland');
            }
          },
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SellCustomTextField(
                id: 501,
                valueKey: 'square_footage',
                hintText: 'Floor area (m²)'.tr,
                controller: sellControllers.squareFootageController,
                onChanged: (value) {
                  addClientFormNotifier.updateTextField(
                    sellControllers.squareFootageController,
                    value,
                  );
                  sellDraft.addData('square_footage', value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SellCustomTextField(
                id: 502,
                valueKey: 'floor',
                hintText: 'Floor'.tr,
                controller: sellControllers.floorController,
                onChanged: (value) {
                  addClientFormNotifier.updateTextField(
                    sellControllers.floorController,
                    value,
                  );
                  sellDraft.addData('floor', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _label(theme, 'Rooms'.tr),
        const SizedBox(height: 8),
        const _SellRoomsChips(),

        const SizedBox(height: 16),
        _label(theme, 'Pricing Information'.tr),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: AddClientFormCustomDropDown(
                options: FilterPopConst.currencyOptions,
                valueKey: 'currency',
                hintText: 'Currency'.tr,
                id: 520,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SellCustomTextField(
                id: 521,
                valueKey: 'price',
                hintText: 'Price'.tr,
                useThousandsSeparator: true,
                emitRawValue: true,
                maxLength: 20,
                controller: sellControllers.priceController,
                onChanged: (value) {
                  addClientFormNotifier.updateTextField(
                    sellControllers.priceController,
                    value,
                  );
                  sellDraft.addData('price', value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(ThemeColors theme, String text) => Text(
        text,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      );
}

// ─── Sell-only rooms chip row (writes to sellOfferFilterCacheProvider only) ───

class _SellRoomsChips extends ConsumerWidget {
  const _SellRoomsChips();

  static const _options = ['any', '1', '2', '3', '4', '5', '6+'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selected = ref.watch(
      sellOfferFilterCacheProvider.select((s) {
        final draft = s['draft'];
        if (draft is Map) return draft['rooms']?.toString() ?? '';
        return '';
      }),
    );

    return Row(
      children: _options.map((v) {
        final isSelected = v == 'any' ? selected.isEmpty : selected == v;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final cache = ref.read(sellOfferFilterCacheProvider.notifier);
                cache.addData('rooms', v == 'any' ? '' : v);
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? theme.textColor : theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Center(
                  child: Text(
                    v == 'any' ? 'Any'.tr : v,
                    style: TextStyle(
                      color: isSelected ? theme.dashboardContainer : theme.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── SELL step 2: Transakcja ──────────────────────────────────────────────────

class CrmSellQuickStep2 extends ConsumerWidget {
  final bool isMobile;
  const CrmSellQuickStep2({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionCardWidget(isMobile: isMobile);
  }
}

// ─── BUY step 1: Czego szuka ─────────────────────────────────────────────────

class CrmBuyQuickStep1 extends ConsumerStatefulWidget {
  const CrmBuyQuickStep1({super.key});

  @override
  ConsumerState<CrmBuyQuickStep1> createState() => _CrmBuyQuickStep1State();
}

class _CrmBuyQuickStep1State extends ConsumerState<CrmBuyQuickStep1> {
  late final FocusNode _priceFromFocus;
  late final FocusNode _priceToFocus;
  late final FocusNode _areaFromFocus;
  late final FocusNode _areaToFocus;
  late final FocusNode _buildYearFromFocus;
  late final FocusNode _buildYearToFocus;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _priceFromFocus = FocusNode();
    _priceToFocus = FocusNode();
    _areaFromFocus = FocusNode();
    _areaToFocus = FocusNode();
    _buildYearFromFocus = FocusNode();
    _buildYearToFocus = FocusNode();
  }

  @override
  void dispose() {
    _priceFromFocus.dispose();
    _priceToFocus.dispose();
    _areaFromFocus.dispose();
    _areaToFocus.dispose();
    _buildYearFromFocus.dispose();
    _buildYearToFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final buyControllers = ref.watch(buySearchControllersProvider);
    final cache = ref.read(buyOfferFilterCacheProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(theme, 'Offer type'.tr),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CrmAddFilterButton(
                text: 'offer_type_sell'.tr,
                filterValue: 'sell',
                filterKey: 'offer_type',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CrmAddFilterButton(
                text: 'offer_type_rent'.tr,
                filterValue: 'rent',
                filterKey: 'offer_type',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _label(theme, 'property_type'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FilterPopConst.estateTypes.map((e) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
              child: buy_estate.CrmAddEstateTypeFilteredButton(
                text: e['text']!.tr,
                filterValue: e['filterValue']!,
                filterKey: 'estate_type',
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        _label(theme, 'Location'.tr),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: AutoCompleteWidget(
            provider: 'nm',
            onLocationChanged: (ref, sel) {
              if (sel.isEmpty) {
                cache.removeFilter('location_type');
                cache.removeFilter('location_id');
                cache.removeFilter('city');
                cache.removeFilter('state');
                return;
              }
              cache.addFilter('location_type', sel.type);
              cache.addFilter('location_id', sel.id);
              if (sel.city.trim().isNotEmpty) {
                cache.addFilter('city', sel.city.trim());
              } else {
                cache.removeFilter('city');
              }
              if (sel.state.trim().isNotEmpty) {
                cache.addFilter('state', sel.state.trim());
              } else {
                cache.removeFilter('state');
              }
            },
          ),
        ),

        const SizedBox(height: 16),
        _label(theme, 'Price'.tr),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: CrmAddBuildDropdownButtonFormField(
                filterKey: 'currency',
                items: const ['PLN', 'EUR', 'USD'],
                labelText: 'Currency'.tr,
                currentValue: 'PLN',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CrmAddBuildNumberField(
                controller: buyControllers.minPriceController,
                labelText: 'price_from'.tr,
                filterKey: 'min_price',
                focusNode: _priceFromFocus,
                nextFocusNode: _priceToFocus,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CrmAddBuildNumberField(
                controller: buyControllers.maxPriceController,
                labelText: 'price_to'.tr,
                filterKey: 'max_price',
                focusNode: _priceToFocus,
                textInputAction: TextInputAction.done,
                isLast: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _label(theme, 'Rooms'.tr),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(child: CrmAddMultiFilteredButton(text: 'Any', filterValue: 'any', filterKey: 'rooms')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '1', filterValue: '1', filterKey: 'rooms')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '2', filterValue: '2', filterKey: 'rooms')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '3', filterValue: '3', filterKey: 'rooms')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '4', filterValue: '4', filterKey: 'rooms')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '5', filterValue: '5', filterKey: 'rooms')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '6+', filterValue: '6+', filterKey: 'rooms')),
          ],
        ),

        const SizedBox(height: 16),
        _label(theme, 'floors'.tr),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(child: CrmAddMultiFilteredButton(text: 'Any', filterValue: 'any', filterKey: 'floors')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '0', filterValue: '0', filterKey: 'floors')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '1', filterValue: '1', filterKey: 'floors')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '2', filterValue: '2', filterKey: 'floors')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '3', filterValue: '3', filterKey: 'floors')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '4', filterValue: '4', filterKey: 'floors')),
            SizedBox(width: 4),
            Expanded(child: CrmAddMultiFilteredButton(text: '5+', filterValue: '5+', filterKey: 'floors')),
          ],
        ),

        const SizedBox(height: 16),
        // ── Expandable extra filters ──────────────────────────────────────
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: theme.textColor.withAlpha(180),
                ),
                const SizedBox(width: 6),
                Text(
                  _expanded ? 'less_filters'.tr : 'more_filters'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(180),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _label(theme, 'floor_area'.tr),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CrmAddBuildNumberField(
                      controller: buyControllers.minSquareFootageController,
                      labelText: 'area_from'.tr,
                      filterKey: 'min_square_footage',
                      focusNode: _areaFromFocus,
                      nextFocusNode: _areaToFocus,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CrmAddBuildNumberField(
                      controller: buyControllers.maxSquareFootageController,
                      labelText: 'area_to'.tr,
                      filterKey: 'max_square_footage',
                      focusNode: _areaToFocus,
                      nextFocusNode: _buildYearFromFocus,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label(theme, 'Year of build'.tr),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CrmAddBuildNumberField(
                      controller: buyControllers.minBuildYear,
                      labelText: 'Year of build from'.tr,
                      filterKey: 'min_build_year',
                      focusNode: _buildYearFromFocus,
                      nextFocusNode: _buildYearToFocus,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CrmAddBuildNumberField(
                      controller: buyControllers.maxBuildYear,
                      labelText: 'Year of build to'.tr,
                      filterKey: 'max_build_year',
                      focusNode: _buildYearToFocus,
                      textInputAction: TextInputAction.done,
                      isLast: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label(theme, 'Bathrooms'.tr),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(child: CrmAddMultiFilteredButton(text: 'Any', filterValue: 'any', filterKey: 'bathrooms')),
                  SizedBox(width: 4),
                  Expanded(child: CrmAddMultiFilteredButton(text: '1', filterValue: '1', filterKey: 'bathrooms')),
                  SizedBox(width: 4),
                  Expanded(child: CrmAddMultiFilteredButton(text: '2', filterValue: '2', filterKey: 'bathrooms')),
                  SizedBox(width: 4),
                  Expanded(child: CrmAddMultiFilteredButton(text: '3', filterValue: '3', filterKey: 'bathrooms')),
                  SizedBox(width: 4),
                  Expanded(child: CrmAddMultiFilteredButton(text: '4', filterValue: '4', filterKey: 'bathrooms')),
                  SizedBox(width: 4),
                  Expanded(child: CrmAddMultiFilteredButton(text: '5+', filterValue: '5+', filterKey: 'bathrooms')),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),

      ],
    );
  }

  Widget _label(ThemeColors theme, String text) => Text(
        text,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      );
}

// ─── BUY step 2: Transakcja ──────────────────────────────────────────────────

class CrmBuyQuickStep2 extends ConsumerWidget {
  final bool isMobile;
  const CrmBuyQuickStep2({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionCardWidget(isMobile: isMobile);
  }
}

// ─── VIEW step 1: Kiedy ───────────────────────────────────────────────────────

class CrmViewQuickStep1 extends ConsumerWidget {
  final bool isMobile;
  const CrmViewQuickStep1({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionListPicker(),
        const SizedBox(height: 20),
        AddEventCardWidget(isMobile: isMobile),
      ],
    );
  }
}
