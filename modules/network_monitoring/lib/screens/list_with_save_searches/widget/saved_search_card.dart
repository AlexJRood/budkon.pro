import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:intl/intl.dart';

import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/add_search.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/controlers.dart';
import 'package:network_monitoring/providers/saved_search/api.dart';
import 'package:network_monitoring/providers/saved_search/edit.dart';
import 'package:network_monitoring/providers/saved_search/inbox_models.dart';
import 'package:network_monitoring/providers/saved_search/remove.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:core/platform/filters/filters_const.dart';
import 'package:core/theme/apptheme.dart';

final DateFormat _dateFormatter = DateFormat('dd.MM.yyyy');

String humanDateTime(
  String? raw, {
  String locale = 'pl_PL',
}) {
  if (raw == null || raw.trim().isEmpty) return '';

  DateTime? dt = DateTime.tryParse(raw.trim());
  if (dt == null) return raw;

  dt = dt.toLocal();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);

  final timeFmt = DateFormat('HH:mm', locale).format(dt);

  if (date == today) {
    return '${'today'.tr}, $timeFmt';
  }
  if (date == today.subtract(const Duration(days: 1))) {
    return '${'Yesterday'.tr}, $timeFmt';
  }

  final dateFmt = DateFormat('d MMM y', locale).format(dt);
  return '$dateFmt, $timeFmt';
}

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

List<SavedSearchChipSection> buildSavedSearchChipSectionsNm(
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

  final estateType = _s(filters['estate_type']);
  if (estateType != null) {
    final label = FilterPopConst.estateTypeLabelOf(estateType);
    if (label != null && label.trim().isNotEmpty) {
      addTo(SavedSearchChipGroup.offer, chip(label));
    }
  }

  final offerType = _s(filters['offer_type']);
  if (offerType != null) {
    addTo(
      SavedSearchChipGroup.offer,
      chip((offerType == 'sell' ? 'For Sale' : 'For Rent').tr),
    );
  }

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

  addRange(
    SavedSearchChipGroup.pricing,
    'Price'.tr,
    'min_price',
    'max_price',
    prefix: '\$',
  );
  addRange(
    SavedSearchChipGroup.pricing,
    'Area'.tr,
    'min_square_footage',
    'max_square_footage',
    suffix: ' m²',
  );

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

  addNumberOrCsv(
    SavedSearchChipGroup.params,
    'rooms',
    labelOverride: 'Rooms'.tr,
  );
  addNumberOrCsv(
    SavedSearchChipGroup.params,
    'bathrooms',
    labelOverride: 'Bathrooms'.tr,
  );

  if (!compact) {
    addNumberOrCsv(
      SavedSearchChipGroup.params,
      'floor',
      labelOverride: 'Floor'.tr,
    );
    addNumberOrCsv(
      SavedSearchChipGroup.params,
      'build_year',
      labelOverride: 'Build year'.tr,
    );
  }

  for (final k in [
    'country',
    'state',
    'city',
    'district',
    'street',
    'address',
  ]) {
    final v = _s(filters[k]);
    if (v == null) continue;
    if (compact && (k == 'street' || k == 'address')) continue;
    addTo(SavedSearchChipGroup.location, chip('${_labelForKey(k)}: $v'));
  }

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
    if (compact && k == 'available_from') continue;

    addTo(
      k == 'source' ? SavedSearchChipGroup.meta : SavedSearchChipGroup.params,
      chip('${_labelForKey(k)}: $v'),
    );
  }

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
      if (compact &&
          ![
            'elevator',
            'balcony',
            'garden',
            'garage',
            'parking_space',
            'internet',
            'furnished',
          ].contains(k)) {
        continue;
      }
      addTo(SavedSearchChipGroup.features, chip(_labelForKey(k)));
    }
  }

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

  return sections.where((s) => !s.isEmpty).toList();
}

Widget buildChipSectionsUiNm({
  required List<SavedSearchChipSection> sections,
  required ThemeColors theme,
  bool compact = false,
}) {
  Widget wrap(List<Widget> children) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );

  Widget locationBlock(List<Widget> chips) {
    if (chips.isEmpty) return const SizedBox.shrink();
    if (compact) return wrap(chips);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardBoarder.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
      ),
      child: wrap(chips),
    );
  }

  final children = <Widget>[];

  for (final s in sections) {
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

Widget _buildMetaChip(ThemeColors theme, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: theme.textFieldColor,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: theme.textColor,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class SavedSearchNmDetailsPopup extends ConsumerWidget {
  final SavedSearchWithCountersModel search;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  const SavedSearchNmDetailsPopup({
    super.key,
    required this.search,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final Map<String, dynamic> filters = search.filters;

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.textFieldColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(color: theme.textColor, fontSize: 13),
          ),
        );

    final createdText = search.createdAt != null
        ? _dateFormatter.format(DateTime.parse(search.createdAt!))
        : null;

    final sections = buildSavedSearchChipSectionsNm(
      filters,
      chip,
      compact: false,
    );

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (search.title ?? 'Saved Search'.tr).toString(),
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (createdText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          createdText,
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetaChip(
                  theme,
                  '${'new_status'.tr}: ${search.newUniqueCount}',
                ),
                _buildMetaChip(
                  theme,
                  '${'Total'.tr}: ${search.totalUniqueCount}',
                ),
                if (_s(search.lastMatchAt)?.isNotEmpty == true)
                  _buildMetaChip(
                    theme,
                    '${'last_match'.tr}: ${humanDateTime(search.lastMatchAt)}',
                  ),
                if (search.transactions.isNotEmpty)
                  _buildMetaChip(
                    theme,
                    '${'Transactions'.tr}: ${search.transactions.length}',
                  ),
                if (search.clients.isNotEmpty)
                  _buildMetaChip(
                    theme,
                    '${'Clients'.tr}: ${search.clients.length}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_s(search.searchQuery)?.isNotEmpty == true) ...[
                      Text(
                        'Query'.tr,
                        style: TextStyle(
                          color: theme.themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      chip(search.searchQuery ?? ''),
                      const SizedBox(height: 14),
                    ],
                    if (search.transactions.isNotEmpty) ...[
                      Text(
                        'Transactions'.tr,
                        style: TextStyle(
                          color: theme.themeColor.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: search.transactions
                            .map((e) => chip(e.label))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (search.clients.isNotEmpty) ...[
                      Text(
                        'Clients'.tr,
                        style: TextStyle(
                          color: theme.themeColor.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            search.clients.map((e) => chip(e.label)).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      'filters_applied'.tr,
                      style: TextStyle(
                        color: theme.themeColor.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildChipSectionsUiNm(
                      sections: sections,
                      theme: theme,
                      compact: false,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_s(search.lastChecked)?.isNotEmpty == true)
                          Text(
                            '${'last_checked'.tr}: ${humanDateTime(search.lastChecked)}',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        if (search.lastCount != null)
                          Text(
                            '${'last_count'.tr}: ${search.lastCount}',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close'.tr,
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    child: Text(
                      'Edit'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                if (onDelete != null)
                  TextButton(
                    onPressed: () async => onDelete?.call(),
                    child: Text(
                      'Delete'.tr,
                      style: TextStyle(color: theme.textColor),
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

Future<void> openSavedSearchDetailsNm(
  BuildContext context,
  WidgetRef ref, {
  required SavedSearchWithCountersModel search,
  VoidCallback? onEdit,
  Future<void> Function()? onDelete,
}) {
  return PopPageManager.show(
    context,
    tag: 'nm-saved-search-${search.id}',
    isBig: false,
    width: 560,
    height: 620,
    shouldBeADrawer: false,
    child: SavedSearchNmDetailsPopup(
      search: search,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}


Future<bool?> _confirmDeleteDialog(BuildContext context, ThemeColors theme) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.dashboardContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      title: Text(
        'Confirm'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      content: Text(
        'Are you sure you want to delete this search?'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            'Cancel'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: theme.themeColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            'Delete'.tr,
            style: TextStyle(color: theme.themeColorText),
          ),
        ),
      ],
    ),
  );
}

class SavedSearchNmCard extends ConsumerWidget {
  final SavedSearchWithCountersModel search;
  final VoidCallback onApply;
  final VoidCallback onSelect;
  final bool isMobile;
  final bool selected;
  final int? transactionId;

  const SavedSearchNmCard({
    super.key,
    required this.search,
    required this.onApply,
    required this.onSelect,
    this.isMobile = false,
    this.selected = false,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final Map<String, dynamic> filters = search.filters;

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(color: theme.textColor, fontSize: 12),
          ),
        );

    final sections = buildSavedSearchChipSectionsNm(
      filters,
      chip,
      compact: true,
    );

    Future<void> doDelete() async {
      final confirmed = await _confirmDeleteDialog(context, theme);
      if (confirmed == true) {
        await ref.read(removeSavedSearchProvider).removeSavedSearch(search.id);
      }
    }

    Future<void> doEdit() async {
      final isMobile = MediaQuery.of(context).size.width < 700;
        if (isMobile) {
          await showEditSavedSearchBottomSheet(context, search, transactionId, ref);
        } else {
          await showEditSavedSearchDialog(context, search,transactionId, ref);
        }
       if (context.mounted) {
          ref.invalidate(savedSearchesProvider); 
       }
    }
    Future<void> doPreview() async {
      await openSavedSearchDetailsNm(
        context,
        ref,
        search: search,
        onEdit: () async {
          Navigator.of(context).pop();
          await doEdit();
        },
        onDelete: () async {
          Navigator.of(context).pop();
          await doDelete();
        },
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: selected ? 1.6 : 1,
              color: selected ? theme.themeColor : theme.dashboardBoarder,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.themeColor.withOpacity(0.18),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (search.title ?? 'Saved Search'.tr).toString(),
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (search.newUniqueCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.themeColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '+${search.newUniqueCount}',
                              style: TextStyle(
                                color: theme.themeColorText,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetaChip(
                          theme,
                          '${'Total'.tr}: ${search.totalUniqueCount}',
                        ),
                        if (_s(search.lastMatchAt)?.isNotEmpty == true)
                          _buildMetaChip(
                            theme,
                            humanDateTime(search.lastMatchAt),
                          ),
                        if (search.transactions.isNotEmpty)
                          _buildMetaChip(
                            theme,
                            '${'Tx'.tr}: ${search.transactions.length}',
                          ),
                        if (search.clients.isNotEmpty)
                          _buildMetaChip(
                            theme,
                            '${'Clients'.tr}: ${search.clients.length}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    buildChipSectionsUiNm(
                      sections: sections,
                      theme: theme,
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: onApply,
                          icon: Icon(Icons.travel_explore_outlined, color: theme.textColor),
                          label: Text('Open search'.tr, style: TextStyle(color: theme.textColor)),
                        ),
                        const SizedBox(width: 8),
                        if (selected)
                          Text(
                            'Selected'.tr,
                            style: TextStyle(
                              color: theme.themeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    color: theme.textColor,
                    tooltip: 'more_information'.tr,
                    onPressed: doPreview,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    color: theme.textColor,
                    tooltip: 'Edit'.tr,
                    onPressed: doEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.textColor),
                    tooltip: 'Delete'.tr,
                    onPressed: doDelete,
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