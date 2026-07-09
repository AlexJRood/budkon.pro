import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/compensation/commission_integration/widgets/commission_integration_controller_widget.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/add_search.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/controlers.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/custom_drop_down.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/filtered_button.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/from_filter_components.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/sort.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_docs_view.dart';
import 'package:crm/contact_panel/tabs/transactions/view_provider.dart';
import 'package:crm/contact_panel/sections/ad_list.dart';
import 'package:crm/contact_panel/sections/ad_view.dart';
import 'package:crm/data/clients/client_saved_search.dart';
import 'package:crm/data/clients/draft_provider.dart';
import 'package:crm/draft_ads_listview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/models/saved_search_model.dart';
import 'package:network_monitoring/providers/saved_search/remove.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:core/theme/lottie.dart';
import '../../../data/clients/ad_provider.dart';
import 'package:intl/intl.dart';

final DateFormat formatter = DateFormat('dd.MM.yyyy');

/// =======================
/// helpers for chips (card + preview)
/// =======================

String? _s(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

bool _isTrue(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes' || s == 'y';
}

List<String> _splitCsv(dynamic v) {
  final s = _s(v);
  if (s == null) return [];
  return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

String _labelForKey(String key) {
  const map = <String, String>{
    'city': 'City',
    'district': 'District',
    'state': 'State',
    'country': 'Country',
    'street': 'Street',
    'address': 'Address',

    'heating_type': 'Heating',
    'building_type': 'Building',
    'market': 'Market',
    'ownership_type': 'Ownership',
    'available_from': 'Available from',
    'energy_certificate': 'Energy cert.',
    'furnished': 'Furnished',

    'build_year': 'Build year',
    'floor': 'Floor',

    'rooms': 'Rooms',
    'bathrooms': 'Bathrooms',

    'source': 'Source',
  };
  return (map[key] ?? key).tr;
}

/// Builds chips from `filters`.
/// compact=true -> list card (short)
/// compact=false -> preview popup (full + unknown keys)
enum SavedSearchChipGroup {
  location,
  offer,
  pricing,
  params,
  features,
  meta,
  other,
}

class SavedSearchChipSection {
  final SavedSearchChipGroup group;
  final String title;
  final List<Widget> chips;

  const SavedSearchChipSection({
    required this.group,
    required this.title,
    required this.chips,
  });

  bool get isEmpty => chips.isEmpty;
}

String _groupTitle(SavedSearchChipGroup g) {
  switch (g) {
    case SavedSearchChipGroup.location:
      return 'Location'.tr;
    case SavedSearchChipGroup.offer:
      return 'Offer'.tr;
    case SavedSearchChipGroup.pricing:
      return 'Pricing'.tr;
    case SavedSearchChipGroup.params:
      return 'Parameters'.tr;
    case SavedSearchChipGroup.features:
      return 'Features'.tr;
    case SavedSearchChipGroup.meta:
      return 'Meta'.tr;
    case SavedSearchChipGroup.other:
      return 'Other'.tr;
  }
}

/// Zwraca sekcje z chipami podzielone kategoriami.
/// compact=true -> mniej pól
List<SavedSearchChipSection> buildSavedSearchChipSections(
  Map<String, dynamic> filters,
  Widget Function(String text) chip, {
  bool compact = false,
}) {
  final location = <Widget>[];
  final offer = <Widget>[];
  final pricing = <Widget>[];
  final params = <Widget>[];
  final features = <Widget>[];
  final meta = <Widget>[];
  final other = <Widget>[];

  void addTo(SavedSearchChipGroup g, Widget w) {
    switch (g) {
      case SavedSearchChipGroup.location:
        location.add(w);
        break;
      case SavedSearchChipGroup.offer:
        offer.add(w);
        break;
      case SavedSearchChipGroup.pricing:
        pricing.add(w);
        break;
      case SavedSearchChipGroup.params:
        params.add(w);
        break;
      case SavedSearchChipGroup.features:
        features.add(w);
        break;
      case SavedSearchChipGroup.meta:
        meta.add(w);
        break;
      case SavedSearchChipGroup.other:
        other.add(w);
        break;
    }
  }

  // --- Offer type
  final offerType = _s(filters['offer_type']);
  if (offerType != null) {
    addTo(
      SavedSearchChipGroup.offer,
      chip((offerType == 'sell' ? 'For Sale' : 'For Rent').tr),
    );
  }

  // --- Ranges
  void addRange(
    SavedSearchChipGroup group,
    String label,
    String minKey,
    String maxKey, {
    String suffix = '',
    String? prefix,
  }) {
    final minV = _s(filters[minKey]);
    final maxV = _s(filters[maxKey]);
    if (minV == null && maxV == null) return;

    final left = '${prefix ?? ''}${minV ?? '0'}';
    final right = '${prefix ?? ''}${maxV ?? ''}';
    addTo(group, chip('$label: $left → $right$suffix'.trim()));
  }

  addRange(SavedSearchChipGroup.pricing, 'Price'.tr, 'min_price', 'max_price', prefix: '\$');
  addRange(SavedSearchChipGroup.pricing, 'Area'.tr, 'min_square_footage', 'max_square_footage', suffix: ' m²');

  // --- numbers/csv
  void addNumberOrCsv(
    SavedSearchChipGroup group,
    String key, {
    String? labelOverride,
    String suffix = '',
  }) {
    final values = _splitCsv(filters[key]);
    if (values.isEmpty) return;
    final label = (labelOverride ?? _labelForKey(key));
    addTo(group, chip('$label: ${values.join(', ')}$suffix'));
  }

  addNumberOrCsv(SavedSearchChipGroup.params, 'rooms', labelOverride: 'Rooms'.tr);
  addNumberOrCsv(SavedSearchChipGroup.params, 'bathrooms', labelOverride: 'Bathrooms'.tr);

  if (!compact) {
    addNumberOrCsv(SavedSearchChipGroup.params, 'floor', labelOverride: 'Floor'.tr);
    addNumberOrCsv(SavedSearchChipGroup.params, 'build_year', labelOverride: 'Build year'.tr);
  }

  // --- location keys
  for (final k in ['country', 'state', 'city', 'district', 'street', 'address']) {
    final v = _s(filters[k]);
    if (v == null) continue;
    addTo(SavedSearchChipGroup.location, chip('${_labelForKey(k)}: $v'));
  }

  // --- property / meta text keys
  for (final k in [
    'heating_type',
    'building_type',
    'market',
    'ownership_type',
    'available_from',
    'source',
  ]) {
    final v = _s(filters[k]);
    if (v == null) continue;
    // "source" bardziej meta
    addTo(
      k == 'source' ? SavedSearchChipGroup.meta : SavedSearchChipGroup.params,
      chip('${_labelForKey(k)}: $v'),
    );
  }

  // --- boolean features
  for (final k in [
    'elevator',
    'balcony',
    'garden',
    'garage',
    'parking_space',
    'basement',
    'terraces',
    'separate_kitchen',
    'internet',
    'gas',
    'water',
    'electricity',
    'sewerage',
    'furnished',
    'energy_certificate',
  ]) {
    if (_isTrue(filters[k])) {
      addTo(SavedSearchChipGroup.features, chip(_labelForKey(k)));
    }
  }

  // --- unknown keys to "other" (only in full mode)
  if (!compact) {
    final known = <String>{
      'estate_type',
      'offer_type',
      'min_price',
      'max_price',
      'min_square_footage',
      'max_square_footage',
      'rooms',
      'bathrooms',
      'floor',
      'build_year',
      'country',
      'state',
      'city',
      'district',
      'street',
      'address',
      'heating_type',
      'building_type',
      'market',
      'ownership_type',
      'available_from',
      'source',
      'elevator',
      'balcony',
      'garden',
      'garage',
      'parking_space',
      'basement',
      'terraces',
      'separate_kitchen',
      'internet',
      'gas',
      'water',
      'electricity',
      'sewerage',
      'furnished',
      'energy_certificate',
      // common query keys
      'search',
      'exclude',
      'sort',
      'include_inactive',
      'include_archived',
      'saved_search_id',
      'saved_search_client_id',
      'saved_search_transaction_id',
      'combine',
    };

    filters.forEach((k, v) {
      if (known.contains(k)) return;
      final sv = _s(v);
      if (sv == null) return;
      addTo(SavedSearchChipGroup.other, chip('${_labelForKey(k)}: $sv'));
    });
  }

  final sections = <SavedSearchChipSection>[
    SavedSearchChipSection(
      group: SavedSearchChipGroup.location,
      title: _groupTitle(SavedSearchChipGroup.location),
      chips: location,
    ),
    SavedSearchChipSection(
      group: SavedSearchChipGroup.offer,
      title: _groupTitle(SavedSearchChipGroup.offer),
      chips: offer,
    ),
    SavedSearchChipSection(
      group: SavedSearchChipGroup.pricing,
      title: _groupTitle(SavedSearchChipGroup.pricing),
      chips: pricing,
    ),
    SavedSearchChipSection(
      group: SavedSearchChipGroup.params,
      title: _groupTitle(SavedSearchChipGroup.params),
      chips: params,
    ),
    SavedSearchChipSection(
      group: SavedSearchChipGroup.features,
      title: _groupTitle(SavedSearchChipGroup.features),
      chips: features,
    ),
    SavedSearchChipSection(
      group: SavedSearchChipGroup.meta,
      title: _groupTitle(SavedSearchChipGroup.meta),
      chips: meta,
    ),
    SavedSearchChipSection(
      group: SavedSearchChipGroup.other,
      title: _groupTitle(SavedSearchChipGroup.other),
      chips: other,
    ),
  ];

  // usuń puste
  return sections.where((s) => !s.isEmpty).toList();
}





/// =========
/// ROOT VIEW
/// =========

class TransactionView extends ConsumerWidget {
  final int? clientId;
  final AgentTransactionModel? transaction;
  final DraftAdsListViewModel? adDraft;
  final bool isMobile;
  final TransactionType type;

  const TransactionView({
    super.key,
    this.isMobile = false,
    this.clientId,
    this.transaction,
    this.adDraft,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transaction == null) {
      return  Center(child: Text('no_transactions'.tr));
    }

    return isMobile
        ? SelectedTransactionView(
            clientId: clientId,
            transaction: transaction!,
            type: type,
            isMobile: isMobile,
          )
        : Column(
            children: [
              ViewModeTransaction(type: type),
              Expanded(
                child: SelectedTransactionView(
                  clientId: clientId,
                  transaction: transaction!,
                  type: type,
                ),
              ),
            ],
          );
  }
}

final viewModeProvider = StateProvider<AdViewMode>((ref) => AdViewMode.list);

enum AdViewMode { list, grid, map }

/// ===================
/// BUYER TRANSACTION UI
/// ===================

class TransactionViewBuyer extends ConsumerWidget {
  final int clientId;
  final AgentTransactionModel transaction;
  final bool isMobile;

  const TransactionViewBuyer({
    super.key,
    this.isMobile = false,
    required this.clientId,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSearchesAsyncValue = ref.watch(transactionSavedSearchesProvider(transaction.id));
    final viewMode = ref.watch(viewModeProvider);
    final theme = ref.read(themeColorsProvider);

    return Column(
      children: [
        const SizedBox(height: 5),
        Row(
          children: [
            if (!isMobile) ...[
              savedSearchesAsyncValue.when(
                data: (savedSearches) => SavedSearchDropdown(
                  savedSearches: savedSearches,
                  clientId: clientId,
                  transactionId: transaction.id,
                ),
                loading: () => SizedBox(
                  width: 18,
                  height: 18,
                  child: AppLottie.loading(),
                ),
                error: (_, __) => SavedSearchDropdown(
                  savedSearches: const <SavedSearchModel>[],
                  clientId: -1,
                  transactionId: transaction.id,
                ),
              ),
              const SizedBox(width: 12),

              ElevatedButton(
                style: elevatedButtonStyleRounded10withoutPadding,
                onPressed: () {
                  PopPageManager.show(
                    context,
                    tag: 'add-search-${transaction.id}',
                    isBig: true,
                    child: AddSearchClientPanel(
                      needBackground: false,
                      transactionId: transaction.id,
                      clientId: clientId,
                    ),
                  );
                },
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      AppIcons.add(color: theme.textColor),
                      const SizedBox(width: 6),
                      Text('Add Search'.tr,
                          style: TextStyle(color: theme.textColor)),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              ClientPanelAdditionalInfoFilteredButton(
                hasIcon: true,
                height: 32,
                text: 'Favorites'.tr,
                filterKey: 'exclude_favorites',
                onClick: () {
                  ref.read(filterProvider.notifier).applyFiltersFromCache(
                        ref.read(filterCacheProvider.notifier),
                        ref,
                      );
                },
                hasBorder: false,
              ),
              const SizedBox(width: 8),

              ClientPanelAdditionalInfoFilteredButton(
                height: 32,
                hasIcon: true,
                text: 'hide'.tr,
                filterKey: 'exclude_hide',
                onClick: () {
                  ref.read(filterProvider.notifier).applyFiltersFromCache(
                        ref.read(filterCacheProvider.notifier),
                        ref,
                      );
                },
                hasBorder: false,
              ),
              const SizedBox(width: 8),

              ClientPanelAdditionalInfoFilteredButton(
                hasIcon: true,
                height: 32,
                text: 'Displayed'.tr,
                filterKey: 'exclude_displayed',
                onClick: () {
                  ref.read(filterProvider.notifier).applyFiltersFromCache(
                        ref.read(filterCacheProvider.notifier),
                        ref,
                      );
                },
                hasBorder: false,
              ),
              const SizedBox(width: 8),

              Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                width: 210,
                height: 32,
                child: ClientPanelDropdownSortSelector(),
              ),
              const SizedBox(width: 105),
            ],
          ],
        ),
        if (!isMobile) const SizedBox(height: 8),

        // Commission integration summary for this transaction.
        TransactionCommissionIntegrationPanel(
          transactionId: transaction.id,
          initialSummary: transaction.commissionSummary,
          isMobile: isMobile,
        ),
        const SizedBox(height: 8),

        Expanded(
          child: AdListClient(
            viewMode: viewMode,
            isMobile: isMobile,
            transactionId: transaction.id,
            clientId: clientId,
          ),
        ),
      ],
    );
  }
}

/// =======================
/// MULTI-SELECT (POPUP MODAL)
/// =======================

class SavedSearchMultiSelectPopup extends ConsumerStatefulWidget {
  final List<SavedSearchModel> savedSearches;
  final Set<int> initial;
  final void Function(Set<int>? result) onSubmit; // null => cancel

  const SavedSearchMultiSelectPopup({
    super.key,
    required this.savedSearches,
    required this.initial,
    required this.onSubmit,
  });

  @override
  ConsumerState<SavedSearchMultiSelectPopup> createState() =>
      _SavedSearchMultiSelectPopupState();
}

class _SavedSearchMultiSelectPopupState
    extends ConsumerState<SavedSearchMultiSelectPopup> {
  late Set<int> temp;

  @override
  void initState() {
    super.initState();
    temp = {...widget.initial};
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Saved Searches'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    widget.onSubmit(null);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  color: theme.textColor,
                  tooltip: 'Close'.tr,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.textFieldColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(12),
                child: ListView(
                  children: [
                    CheckboxListTile(
                      value: temp.isEmpty,
                      onChanged: (_) => setState(() => temp.clear()),
                      title: Text('Show all'.tr,
                          style: TextStyle(color: theme.textColor)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: theme.themeColor,
                      checkColor: Colors.white,
                    ),
                    const Divider(),
                    ...widget.savedSearches.map((s) {
                      final checked = temp.contains(s.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              temp.add(s.id);
                            } else {
                              temp.remove(s.id);
                            }
                          });
                        },
                        title: Text(
                          s.title,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight:
                                checked ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: theme.themeColor,
                        checkColor: Colors.white,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    widget.onSubmit(null);
                    Navigator.of(context).pop();
                  },
                  child:
                      Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () {
                    temp.clear();
                    setState(() {});
                  },
                  child:
                      Text('Clear'.tr, style: TextStyle(color: theme.textColor)),
                ),
                const Spacer(),
                ElevatedButton(
                  style: buttonStyleRounded10ThemeRed,
                  onPressed: () {
                    widget.onSubmit(temp);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text('Apply'.tr,
                        style: TextStyle(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// DROPDOWN -> OTWÓRZ MULTI-SELECT (cards popup)
/// =======================

class SavedSearchDropdown extends ConsumerWidget {
  final List<SavedSearchModel> savedSearches;
  final int clientId;
  final int transactionId;

  const SavedSearchDropdown({
    super.key,
    required this.savedSearches,
    required this.clientId,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    ref.watch(filterProvider);

    final btnLabel = 'Saved searches'.tr;
    final selectedCount =
        ref.read(filterProvider.notifier).selectedSavedSearchIds.length;
    final suffix = selectedCount > 0 ? ' ($selectedCount)' : '';

    return ElevatedButton(
      style: elevatedButtonStyleRounded10withoutPadding,
      onPressed: () => openMultiSelectWithPopPage(context, ref),
      child: Container(
        height: 32,
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text('$btnLabel$suffix', style: TextStyle(color: theme.textColor)),
            const Spacer(),
            AppIcons.iosArrowDown(color: theme.textColor),
          ],
        ),
      ),
    );
  }

  Future<void> openMultiSelectWithPopPage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(filterProvider.notifier);
    final initial = {...notifier.selectedSavedSearchIds};
    final tag = 'saved-search-cards-${transactionId}_$clientId';

    await PopPageManager.show(
      context,
      tag: tag,
      isBig: false,
      width: 680,
      height: 700,
      shouldBeADrawer: false,
      child: SavedSearchCardsPopup(
        transactionId: transactionId,
        savedSearches: savedSearches,
        initial: initial,
        onSubmit: (Set<int>? result) {
          if (result == null) return;
          notifier.setClientId('', ref);
          notifier.filteredScope(clientId, transactionId, ref);
          notifier.setSavedSearches(result, ref, transactionId); // empty => show all
        },
      ),
    );
  }
}


Widget buildChipSectionsUi({
  required List<SavedSearchChipSection> sections,
  required ThemeColors theme,
  bool compact = false,
}) {
  // Widget sectionTitle(String text) => Padding(
  //       padding: const EdgeInsets.only(bottom: 6),
  //       child: Text(
  //         text,
  //         style: TextStyle(
  //           color: theme.textColor.withAlpha(170),
  //           fontSize: 11,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //     );

  Widget wrap(List<Widget> children) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );

  // Lokalizacja: zamiast wrapa możesz zrobić 1-2 linie (bardziej "czytelne")
  Widget locationBlock(List<Widget> chips) {
    if (compact) {
      // compact: nadal Wrap, ale możesz ograniczyć ilość (np. tylko city/district)
      return wrap(chips);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
      ),
      child: wrap(chips),
    );
  }

  final children = <Widget>[];

  for (final s in sections) {
    // children.add(sectionTitle(s.title));

    if (s.group == SavedSearchChipGroup.location) {
      children.add(locationBlock(s.chips));
    } else {
      children.add(wrap(s.chips));
    }

    children.add(const SizedBox(height: 10));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}


/// =======================
/// SELLER TRANSACTION UI
/// =======================

class TransactionViewSeller extends ConsumerWidget {
  final AgentTransactionModel transaction;
  final bool isMobile;

  const TransactionViewSeller({
    super.key,
    this.isMobile = false,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? draftId = transaction.draft;
    final theme = ref.read(themeColorsProvider);

    if (draftId == null) {
      return Center(
        child: Text(
          'missing_draft_id'.tr,
          style: TextStyle(color: theme.textColor, fontSize: 24),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(isMobile ? 0 : 16.0),
      child: 
          ref.watch(draftAdProvider(draftId)).when(
                data: (draft) =>
                    AdViewClient(adFeedPop: draft, isMobile: isMobile),
                loading: () => AppLottie.loading(),
                error: (err, stack) => AppLottie.error(),
              ),
    );
  }
}

/// =======================
/// LEGACY CLIENT DROPDOWN (single select) — unchanged
/// =======================

class FilterSearchSelection extends ConsumerWidget {
  final int clientId;

  const FilterSearchSelection({super.key, required this.clientId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSearchesAsyncValue =
        ref.watch(clientSavedSearchesProvider(clientId));
    final theme = ref.read(themeColorsProvider);

    return savedSearchesAsyncValue.when(
      data: (savedSearches) {
        return DropdownButton<String>(
          dropdownColor: theme.dashboardContainer,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          value: ref.watch(filterProvider.notifier).selectedSavedSearchId,
          onChanged: (String? newValue) {
            if (newValue == null) return;
            ref.read(filterProvider.notifier).setSavedSearch(newValue, ref);
          },
          items: [
            DropdownMenuItem(value: 'all', child: Text('Show all'.tr)),
            ...savedSearches.map((search) {
              return DropdownMenuItem(
                value: search.id.toString(),
                child: Text(search.title, style: TextStyle(color: theme.textColor)),
              );
            }),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) =>
          Text('Error loading saved searches'.tr),
    );
  }
}

/// =======================
/// POPUP: DETAILS
/// =======================

class SavedSearchDetailsPopup extends ConsumerWidget {
  final SavedSearchModel search;
  final int? transactionId;
  final int? clientId;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  const SavedSearchDetailsPopup({
    super.key,
    required this.search,
    this.transactionId,
    this.clientId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final Map<String, dynamic> filters =
        (search.filters as Map?)?.cast<String, dynamic>() ?? {};

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.textFieldColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text,
              style: TextStyle(color: theme.textColor, fontSize: 13)),
        );

                    final sections = buildSavedSearchChipSections(filters, chip, compact: true);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        search.title,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(DateTime.parse(search.createdAt)),
                        style: TextStyle(
                          color: theme.textColor.withAlpha(153),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.textColor),
                  tooltip: 'Close'.tr,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_s(search.searchQuery)?.isNotEmpty == true) ...[
                      Text(
                        'query_label'.tr,
                        style: TextStyle(
                          color: theme.themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      chip(search.searchQuery ?? ''),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      'Filters applied:'.tr,
                      style: TextStyle(
                        color: theme.themeColor.withAlpha(204),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

buildChipSectionsUi(
  sections: [
    // estate_type możesz wrzucić do "Offer" albo jako osobna sekcja:
    if (_s(filters['estate_type']) != null)
      SavedSearchChipSection(
        group: SavedSearchChipGroup.offer,
        title: 'Type'.tr,
        chips: [chip(FilterPopConst.estateTypeLabelOf(filters['estate_type'])!)],
      ),
    ...sections,
  ],
  theme: theme,
  compact: true,
),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_s(search.lastChecked)?.isNotEmpty == true)
                          Text(
                            '${'last_checked_prefix'.tr} ${search.lastChecked}',
                            style: TextStyle(
                              color: theme.textColor.withAlpha(178),
                              fontSize: 12,
                            ),
                          ),
                        if (_s(search.lastCount)?.isNotEmpty == true)
                          Text(
                            '${'last_count_prefix'.tr} ${search.lastCount}',
                            style: TextStyle(
                              color: theme.textColor.withAlpha(178),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // footer
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(153),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// helper: open details popup
Future<void> openSavedSearchDetails(
  BuildContext context,
  WidgetRef ref, {
  required SavedSearchModel search,
  int? transactionId,
  int? clientId,
  VoidCallback? onEdit,
  Future<void> Function()? onDelete,
}) {
  return PopPageManager.show(
    context,
    tag: 'saved-search-${search.id}',
    isBig: false,
    width: 560,
    height: 620,
    shouldBeADrawer: false,
    child: SavedSearchDetailsPopup(
      search: search,
      transactionId: transactionId,
      clientId: clientId,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

/// =======================
/// POPUP: CARDS + MULTI-SELECT
/// =======================

class SavedSearchCardsPopup extends ConsumerStatefulWidget {
  final List<SavedSearchModel> savedSearches;
  final int? transactionId;
  final Set<int> initial;
  final void Function(Set<int>? result) onSubmit; // null => cancel

  const SavedSearchCardsPopup({
    super.key,
    this.transactionId,
    required this.savedSearches,
    required this.initial,
    required this.onSubmit,
  });

  @override
  ConsumerState<SavedSearchCardsPopup> createState() =>
      _SavedSearchCardsPopupState();
}

class _SavedSearchCardsPopupState extends ConsumerState<SavedSearchCardsPopup> {
  late Set<int> temp;

  @override
  void initState() {
    super.initState();
    temp = {...widget.initial};
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Saved searches'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    widget.onSubmit(null);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  color: theme.textColor,
                  tooltip: 'Close'.tr,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Show all
            Container(
              decoration: BoxDecoration(
                color: theme.adPopBackground.withAlpha(75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                value: temp.isEmpty,
                onChanged: (_) => setState(() => temp.clear()),
                title: Text('Show all'.tr,
                    style: TextStyle(color: theme.textColor)),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: theme.themeColor,
                checkColor: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.savedSearches.isEmpty
                    ? Center(
                        child: Text(
                          'no_saved_searches'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(178),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: widget.savedSearches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final s = widget.savedSearches[i];
                          final selected = temp.contains(s.id);
                          return SavedSearchSelectableCard(
                            transactionId: widget.transactionId,
                            search: s,
                            selected: selected,
                            onToggle: () {
                              setState(() {
                                if (selected) {
                                  temp.remove(s.id);
                                } else {
                                  temp.add(s.id);
                                }
                              });
                            },
                            onPreview: () => openSavedSearchDetails(
                              context,
                              ref,
                              search: s,
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () {
                    widget.onSubmit(null);
                    Navigator.of(context).pop();
                  },
                  child:
                      Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () => setState(() => temp.clear()),
                  child:
                      Text('Clear'.tr, style: TextStyle(color: theme.textColor)),
                ),
                const Spacer(),
                Expanded(
                  child: ElevatedButton(
                    style: buttonStyleRounded10ThemeRed,
                    onPressed: () {
                      widget.onSubmit(temp);
                      Navigator.of(context).pop();
                    },
                    child: Text('Apply'.tr,
                        style: TextStyle(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// CARD (checkbox + chips + actions)
/// =======================

class SavedSearchSelectableCard extends ConsumerWidget {
  final SavedSearchModel search;
  final int? transactionId;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback? onPreview;

  const SavedSearchSelectableCard({
    super.key,
    this.transactionId,
    required this.search,
    required this.selected,
    required this.onToggle,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final Map<String, dynamic> filters =
        (search.filters as Map?)?.cast<String, dynamic>() ?? {};
    final container = ProviderScope.containerOf(context, listen: false);

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text,
              style: TextStyle(color: theme.textColor, fontSize: 12)),
        );


        final sections = buildSavedSearchChipSections(filters, chip, compact: false);

    return Material(
      color: Colors.transparent,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10withoutPadding,
        onPressed: onToggle,
        child: Container(
          decoration: BoxDecoration(
            color: theme.adPopBackground.withAlpha(selected ? 125 : 75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected ? theme.themeColor : theme.dashboardContainer,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                activeColor: theme.themeColor,
                checkColor: Colors.white,
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      search.title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if ((search.createdAt ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(DateTime.parse(search.createdAt)),
                        style: TextStyle(
                          color: theme.textColor.withAlpha(153),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),


                  buildChipSectionsUi(
                    sections: [
                      if (_s(filters['estate_type']) != null)
                        SavedSearchChipSection(
                          group: SavedSearchChipGroup.offer,
                          title: 'Type'.tr,
                          chips: [chip(FilterPopConst.estateTypeLabelOf(filters['estate_type'])!)],
                        ),
                      ...sections,
                    ],
                    theme: theme,
                    compact: false,
                  ),

                  ],
                ),
              ),

              if (onPreview != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      color: theme.textColor,
                      tooltip: 'More information'.tr,
                      onPressed: onPreview,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.textColor),
                      tooltip: 'Delete'.tr,
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          useRootNavigator: true,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: theme.dashboardContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            title: Text('Confirm'.tr,
                                style: TextStyle(color: theme.textColor)),
                            content: Text(
                              'Are you sure you want to delete this search?'.tr,
                              style: TextStyle(color: theme.textColor),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: Text('Cancel'.tr,
                                    style: TextStyle(color: theme.textColor)),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: theme.themeColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: Text('Delete'.tr,
                                    style: TextStyle(
                                        color: theme.themeColorText)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await ref
                              .read(removeSavedSearchProvider)
                              .removeSavedSearch(search.id);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: theme.textColor,
                      tooltip: 'Edit saved search'.tr,
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.dashboardContainer,
                        builder: (_) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.85,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            expand: false,
                            builder: (ctx, scrollController) {
                              return SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: AddSearchClientPanel(
                                    headline: 'Edit saved filter'.tr,
                                    isEdit: true,
                                    transactionId: transactionId,
                                    savedSearchId: search.id,
                                    isMobile: true,
                                    needBackground: false,
                                    search: search.toJson(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ).whenComplete(() {
                        container
                            .read(filterCacheProvider.notifier)
                            .clearFilters();
                        container
                            .read(filterButtonProvider.notifier)
                            .clearUiFilters();
                        container
                            .read(clientPanelDropdownProvider.notifier)
                            .clearAll();
                        container.read(filtersControllersProvider).clear();
                        debugPrint('clear filters after closing drawer');
                      }),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
