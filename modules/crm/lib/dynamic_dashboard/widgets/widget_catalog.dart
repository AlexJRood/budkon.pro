import 'package:crm/dynamic_dashboard/models/catalog_models.dart';
import 'package:crm/dynamic_dashboard/services/catalog_api.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

enum DashboardMarketplaceTab {
  available,
  onDashboard,
  market,
}

enum _ViewMode { list, grid }

class DashboardWidgetMarketplaceSheet extends ConsumerStatefulWidget {
  const DashboardWidgetMarketplaceSheet({
    super.key,
    required this.dashboardKey,
    required this.zoneKey,
    required this.existingTypes,
    required this.onAdd,
  });

  final String dashboardKey;
  final String zoneKey;
  final Set<String> existingTypes;
  final void Function(DashboardCatalogItem item) onAdd;

  @override
  ConsumerState<DashboardWidgetMarketplaceSheet> createState() =>
      _DashboardWidgetMarketplaceSheetState();
}

class _DashboardWidgetMarketplaceSheetState
    extends ConsumerState<DashboardWidgetMarketplaceSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategory;
  String _search = '';
  final Set<String> _expandedSlugs = {};
  _ViewMode _viewMode = _ViewMode.list;

  String _safeAnchorPart(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'unknown' : cleaned;
  }

  // Returns the theme-appropriate preview URL: light or dark desktop variant.
  String? _previewUrl(DashboardCatalogItem item) {
    if (item.previewImages.isNotEmpty) {
      // ThemeMode.light = dark UI, ThemeMode.system = light UI (naming is inverted)
      final isDarkUi = ref.read(themeProvider) == ThemeMode.light;
      final variant = isDarkUi ? 'dark_desktop' : 'light_desktop';
      return (item.previewImages[variant] ?? item.previewImages.values.firstOrNull)?.url
          ?? item.previewImageUrl;
    }
    return item.previewImageUrl;
  }

  // Background that matches the variant shown (matches dashboardContainer colour).
  Color _previewBg(DashboardCatalogItem item) {
    final isDarkUi = ref.read(themeProvider) == ThemeMode.light;
    if (item.previewImages.isNotEmpty) {
      return isDarkUi ? const Color(0xFF212020) : const Color(0xFFFFFFFF);
    }
    // No image: neutral placeholder bg
    return ref.read(themeColorsProvider).dashboardBoarder.withAlpha(30);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DashboardCatalogQuery _queryForTab(DashboardMarketplaceTab tab) {
    switch (tab) {
      case DashboardMarketplaceTab.available:
      case DashboardMarketplaceTab.onDashboard:
        return DashboardCatalogQuery(
          dashboardKey: widget.dashboardKey,
          zoneKey: widget.zoneKey,
          category: _selectedCategory,
          search: _search.isEmpty ? null : _search,
        );
      case DashboardMarketplaceTab.market:
        return DashboardCatalogQuery(
          dashboardKey: widget.dashboardKey,
          zoneKey: widget.zoneKey,
          source: 'market',
          category: _selectedCategory,
          search: _search.isEmpty ? null : _search,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootAnchor =
        'dynamic_dashboard.${widget.dashboardKey}.marketplace.${widget.zoneKey}';
    final theme = ref.read(themeColorsProvider);

    return EmmaUiAnchorTarget(
      // @emma-backend: DashboardMarketplaceEmmaAnchors.root(widget.dashboardKey, widget.zoneKey)
      anchorKey: '$rootAnchor.root',
      child: SafeArea(
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    EmmaUiAnchorTarget(
                      // @emma-backend: DashboardMarketplaceEmmaAnchors.title(widget.dashboardKey, widget.zoneKey)
                      anchorKey: '$rootAnchor.title',
                      child: Text(
                        'widget_marketplace_title'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: theme.textColor),
                      tooltip: 'close_button'.tr,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              EmmaUiAnchorTarget(
                // @emma-backend: DashboardMarketplaceEmmaAnchors.tabs(widget.dashboardKey, widget.zoneKey)
                anchorKey: '$rootAnchor.tabs',
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: theme.textColor,
                  unselectedLabelColor: theme.textColor.withAlpha(120),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                  dividerColor: theme.dashboardBoarder,
                  indicatorColor: theme.themeColor,
                  tabs: [
                    EmmaUiAnchorTarget(
                      // @emma-backend: DashboardMarketplaceEmmaAnchors.tabAvailable(widget.dashboardKey, widget.zoneKey)
                      anchorKey: '$rootAnchor.tabs.available',
                      child: Tab(text: 'available_tab'.tr),
                    ),
                    EmmaUiAnchorTarget(
                      // @emma-backend: DashboardMarketplaceEmmaAnchors.tabOnDashboard(widget.dashboardKey, widget.zoneKey)
                      anchorKey: '$rootAnchor.tabs.on_dashboard',
                      child: Tab(text: 'on_dashboard_tab'.tr),
                    ),
                    EmmaUiAnchorTarget(
                      // @emma-backend: DashboardMarketplaceEmmaAnchors.tabMarket(widget.dashboardKey, widget.zoneKey)
                      anchorKey: '$rootAnchor.tabs.market',
                      child: Tab(text: 'market_tab'.tr),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: EmmaUiAnchorTarget(
                        // @emma-backend: DashboardMarketplaceEmmaAnchors.search(widget.dashboardKey, widget.zoneKey)
                        anchorKey: '$rootAnchor.search',
                        child: CoreTextField(
                          controller: _searchController,
                          label: 'search_widget_hint'.tr,
                          prefixIcon:
                              Icon(Icons.search_rounded, color: theme.textColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _viewToggleButton(theme),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTab(DashboardMarketplaceTab.available),
                    _buildTab(DashboardMarketplaceTab.onDashboard),
                    _buildTab(DashboardMarketplaceTab.market),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(DashboardMarketplaceTab tab) {
    final query = _queryForTab(tab);
    final asyncValue = ref.watch(dashboardCatalogProvider(query));
    final theme = ref.read(themeColorsProvider);

    final tabKey = switch (tab) {
      DashboardMarketplaceTab.available => 'available',
      DashboardMarketplaceTab.onDashboard => 'on_dashboard',
      DashboardMarketplaceTab.market => 'market',
    };

    final rootAnchor =
        'dynamic_dashboard.${widget.dashboardKey}.marketplace.${widget.zoneKey}.tab.$tabKey';

    return asyncValue.when(
      loading: () => EmmaUiAnchorTarget(
        // @emma-backend: DashboardMarketplaceEmmaAnchors.loading(widget.dashboardKey, widget.zoneKey, tabKey)
        anchorKey: '$rootAnchor.loading',
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EmmaUiAnchorTarget(
        // @emma-backend: DashboardMarketplaceEmmaAnchors.error(widget.dashboardKey, widget.zoneKey, tabKey)
        anchorKey: '$rootAnchor.error',
        child: Center(child: Text('Error: $error')),
      ),
      data: (items) {
        final visibleItems = items.where((item) {
          switch (tab) {
            case DashboardMarketplaceTab.available:
              if (!item.canAdd && !item.canInstall) return false;
              if (!item.allowMultiple &&
                  widget.existingTypes.contains(item.componentKey)) {
                return false;
              }
            case DashboardMarketplaceTab.onDashboard:
              if (!widget.existingTypes.contains(item.componentKey)) return false;
            case DashboardMarketplaceTab.market:
              break;
          }
          if (_selectedCategory == null || _selectedCategory!.isEmpty) return true;
          return item.category == _selectedCategory;
        }).toList();

        final categories =
            visibleItems.map((e) => e.category).toSet().toList()..sort();

        return Column(
          children: [
            if (categories.isNotEmpty)
              EmmaUiAnchorTarget(
                // @emma-backend: DashboardMarketplaceEmmaAnchors.categoryBar(widget.dashboardKey, widget.zoneKey, tabKey)
                anchorKey: '$rootAnchor.category_bar',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      EmmaUiAnchorTarget(
                        // @emma-backend: DashboardMarketplaceEmmaAnchors.categoryAll(widget.dashboardKey, widget.zoneKey, tabKey)
                        anchorKey: '$rootAnchor.category.all',
                        child: _categoryChip(
                          label: 'all_label'.tr,
                          selected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final category in categories) ...[
                        EmmaUiAnchorTarget(
                          // @emma-backend: DashboardMarketplaceEmmaAnchors.category(widget.dashboardKey, widget.zoneKey, tabKey, category)
                          anchorKey:
                              '$rootAnchor.category.${_safeAnchorPart(category)}',
                          child: _categoryChip(
                            label: category,
                            selected: _selectedCategory == category,
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: EmmaUiAnchorTarget(
                // @emma-backend: DashboardMarketplaceEmmaAnchors.results(widget.dashboardKey, widget.zoneKey, tabKey)
                anchorKey: '$rootAnchor.results',
                child: visibleItems.isEmpty
                    ? Center(
                        child: Text(
                          'no_widgets_found'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(140),
                          ),
                        ),
                      )
                    : _viewMode == _ViewMode.list
                        ? ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibleItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _buildItemCard(
                              item: visibleItems[index],
                              tab: tab,
                              tabKey: tabKey,
                              query: query,
                              rootAnchor: rootAnchor,
                              theme: theme,
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cols =
                                  (constraints.maxWidth / 200).floor().clamp(2, 5);
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: visibleItems.length,
                                itemBuilder: (context, index) => _buildItemTile(
                                  item: visibleItems[index],
                                  query: query,
                                  rootAnchor: rootAnchor,
                                  theme: theme,
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── list card ──────────────────────────────────────────────────────────────

  Widget _buildItemCard({
    required DashboardCatalogItem item,
    required DashboardMarketplaceTab tab,
    required String tabKey,
    required DashboardCatalogQuery query,
    required String rootAnchor,
    required ThemeColors theme,
  }) {
    final itemKey = _safeAnchorPart(item.slug);
    final isOnDashboard = widget.existingTypes.contains(item.componentKey);
    final alreadyExists = !item.allowMultiple && isOnDashboard;
    final canAddNow = item.canAdd && !alreadyExists;
    final canInstallNow = item.canInstall;
    final isExpanded = _expandedSlugs.contains(item.slug);
    final previewUrl = _previewUrl(item);

    String addLabel() {
      if (item.allowMultiple && isOnDashboard) return 'add_another_button'.tr;
      if (alreadyExists) return 'already_added_label'.tr;
      return 'add_button'.tr;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: DashboardMarketplaceEmmaAnchors.itemCard(widget.dashboardKey, widget.zoneKey, tabKey, item.slug)
      anchorKey: '$rootAnchor.item.$itemKey.card',
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: theme.adPopBackground,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() {
            if (_expandedSlugs.contains(item.slug)) {
              _expandedSlugs.remove(item.slug);
            } else {
              _expandedSlugs.add(item.slug);
            }
          }),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── always-visible preview ─────────────────────────────────
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 108,
                  width: double.infinity,
                  child: _buildPreviewBanner(
                    url: previewUrl,
                    bg: _previewBg(item),
                    theme: theme,
                    iconFallback: _iconFor(item.iconKey),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── header row ─────────────────────────────────────
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.themeColor.withAlpha(35),
                          child: Icon(
                            _iconFor(item.iconKey),
                            color: theme.themeColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.description.isEmpty
                                    ? 'no_description_label'.tr
                                    : item.description,
                                maxLines: isExpanded ? 4 : 1,
                                overflow: isExpanded
                                    ? TextOverflow.clip
                                    : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textColor.withAlpha(150),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: theme.textColor.withAlpha(100),
                          size: 18,
                        ),
                      ],
                    ),

                    // ── expanded meta ──────────────────────────────────
                    if (isExpanded) ...[
                      const SizedBox(height: 10),
                      _buildMeta(item, theme),
                    ],

                    const SizedBox(height: 10),

                    // ── pills ──────────────────────────────────────────
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill(item.category, theme),
                        _pill(item.source.key, theme),
                        if (item.isPremium)
                          _pillColored('premium_pill'.tr, theme.themeColor, theme),
                        if (item.isInstalled)
                          _pillColored(
                              'installed_pill'.tr, theme.themeAccent, theme),
                        if (isOnDashboard)
                          _pillColored('on_dashboard_pill'.tr,
                              theme.themeColor.withAlpha(190), theme),
                        if (item.allowMultiple) _pill('multi_pill'.tr, theme),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── actions ────────────────────────────────────────
                    Row(
                      children: [
                        if (canInstallNow)
                          EmmaUiAnchorTarget(
                            // @emma-backend: DashboardMarketplaceEmmaAnchors.itemInstallButton(...)
                            anchorKey: '$rootAnchor.item.$itemKey.install',
                            child: FilledButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(dashboardCatalogApiProvider)
                                    .installWidget(item.slug);
                                ref.invalidate(dashboardCatalogProvider(query));
                              },
                              icon: Icon(Icons.download_rounded,
                                  color: theme.textColor, size: 16),
                              label: Text('install_button'.tr,
                                  style: TextStyle(
                                      color: theme.textColor, fontSize: 13)),
                            ),
                          ),
                        if (canInstallNow) const SizedBox(width: 8),
                        EmmaUiAnchorTarget(
                          // @emma-backend: DashboardMarketplaceEmmaAnchors.itemAddButton(...)
                          anchorKey: '$rootAnchor.item.$itemKey.add',
                          child: FilledButton.icon(
                            onPressed: canAddNow
                                ? () {
                                    widget.onAdd(item);
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            icon: Icon(
                              item.allowMultiple && isOnDashboard
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.add_rounded,
                              color: theme.textColor,
                              size: 16,
                            ),
                            label: Text(addLabel(),
                                style: TextStyle(
                                    color: theme.textColor, fontSize: 13)),
                          ),
                        ),
                        const Spacer(),
                        if (!canAddNow && !canInstallNow)
                          Text(
                            _reasonText(
                              alreadyExists ? 'already_added' : item.disabledReason,
                            ),
                            style: TextStyle(
                              color: theme.textColor.withAlpha(130),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── grid tile ──────────────────────────────────────────────────────────────

  Widget _buildItemTile({
    required DashboardCatalogItem item,
    required DashboardCatalogQuery query,
    required String rootAnchor,
    required ThemeColors theme,
  }) {
    final itemKey = _safeAnchorPart(item.slug);
    final isOnDashboard = widget.existingTypes.contains(item.componentKey);
    final alreadyExists = !item.allowMultiple && isOnDashboard;
    final canAddNow = item.canAdd && !alreadyExists;
    final canInstallNow = item.canInstall;
    final previewUrl = _previewUrl(item);

    return EmmaUiAnchorTarget(
      anchorKey: '$rootAnchor.item.$itemKey.tile',
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: theme.adPopBackground,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canAddNow || canInstallNow
              ? () {
                  if (canAddNow) {
                    widget.onAdd(item);
                    Navigator.of(context).pop();
                  } else if (canInstallNow) {
                    ref
                        .read(dashboardCatalogApiProvider)
                        .installWidget(item.slug)
                        .then((_) =>
                            ref.invalidate(dashboardCatalogProvider(query)));
                  }
                }
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── preview image fills the top ~60% ──────────────────────
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _buildPreviewBanner(
                    url: previewUrl,
                    bg: _previewBg(item),
                    theme: theme,
                    iconFallback: _iconFor(item.iconKey),
                  ),
                ),
              ),

              // ── info strip ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: theme.textColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(child: _pill(item.category, theme)),
                        const SizedBox(width: 4),
                        if (isOnDashboard && !item.allowMultiple)
                          Icon(Icons.check_circle_rounded,
                              size: 16,
                              color: theme.themeColor.withAlpha(190))
                        else if (canInstallNow)
                          Icon(Icons.download_rounded,
                              size: 16, color: theme.themeColor)
                        else if (canAddNow)
                          Icon(
                            item.allowMultiple && isOnDashboard
                                ? Icons.add_circle_outline_rounded
                                : Icons.add_rounded,
                            size: 16,
                            color: theme.themeColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── preview banner (shared by card + tile) ─────────────────────────────────

  Widget _buildPreviewBanner({
    required String? url,
    required Color bg,
    required ThemeColors theme,
    required IconData iconFallback,
  }) {
    if (url != null && url.isNotEmpty) {
      return ColoredBox(
        color: bg,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Shimmer.fromColors(
              baseColor: ShimmerColors.base(context),
              highlightColor: ShimmerColors.highlight(context),
              child: ColoredBox(color: ShimmerColors.background(context)),
            );
          },
          errorBuilder: (_, __, ___) =>
              _previewPlaceholder(theme, iconFallback),
        ),
      );
    }
    return _previewPlaceholder(theme, iconFallback);
  }

  Widget _previewPlaceholder(ThemeColors theme, IconData icon) {
    return ColoredBox(
      color: theme.dashboardBoarder.withAlpha(35),
      child: Center(
        child: Icon(icon, size: 32, color: theme.textColor.withAlpha(60)),
      ),
    );
  }

  // ── expanded meta details (perms / sizes / constraints) ────────────────────

  Widget _buildMeta(DashboardCatalogItem item, ThemeColors theme) {
    final hasPerms = item.requiredPermissions.isNotEmpty;
    final hasSizes = item.defaultSizes.isNotEmpty;
    final hasConstraints = item.constraints.isNotEmpty;

    if (!hasPerms && !hasSizes && !hasConstraints) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardBoarder.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPerms) ...[
            Text(
              'required_permissions_label'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.textColor.withAlpha(160),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.requiredPermissions.join(', '),
              style:
                  TextStyle(fontSize: 11, color: theme.textColor.withAlpha(200)),
            ),
            if (hasSizes || hasConstraints) const SizedBox(height: 8),
          ],
          if (hasSizes) ...[
            Text(
              'default_sizes_label'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.textColor.withAlpha(160),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final entry in item.defaultSizes.entries)
                  _metaPill(_sizeLabel(entry.key, entry.value), theme),
              ],
            ),
            if (hasConstraints) const SizedBox(height: 8),
          ],
          if (hasConstraints)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final entry in item.constraints.entries)
                  _metaPill('${entry.key}: ${entry.value}', theme),
              ],
            ),
        ],
      ),
    );
  }

  String _sizeLabel(String breakpoint, dynamic value) {
    if (value is Map) {
      final w = value['w'];
      final h = value['h'];
      if (w != null && h != null) return '$breakpoint: $w×$h';
    }
    return breakpoint;
  }

  // ── misc helpers ───────────────────────────────────────────────────────────

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ThemeColors theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? theme.themeColor : theme.dashboardBoarder.withAlpha(50),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? theme.themeColor : theme.dashboardBoarder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? theme.themeColorText : theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _viewToggleButton(ThemeColors theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.dashboardBoarder.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleIcon(
            icon: Icons.view_list_rounded,
            active: _viewMode == _ViewMode.list,
            onTap: () => setState(() => _viewMode = _ViewMode.list),
            theme: theme,
          ),
          _toggleIcon(
            icon: Icons.grid_view_rounded,
            active: _viewMode == _ViewMode.grid,
            onTap: () => setState(() => _viewMode = _ViewMode.grid),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _toggleIcon({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required ThemeColors theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 48,
        decoration: BoxDecoration(
          color: active ? theme.themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? theme.themeColorText : theme.textColor.withAlpha(160),
        ),
      ),
    );
  }

  Widget _pill(String text, ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.dashboardBoarder.withAlpha(60),
        border: Border.all(color: theme.dashboardBoarder, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(170)),
      ),
    );
  }

  Widget _pillColored(String text, Color color, ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withAlpha(35),
        border: Border.all(color: color.withAlpha(120), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  Widget _metaPill(String text, ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.dashboardBoarder.withAlpha(70),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: theme.textColor.withAlpha(180)),
      ),
    );
  }

  String _reasonText(String? reason) {
    switch (reason) {
      case 'install_required':
        return 'reason_install_required'.tr;
      case 'dashboard_not_allowed':
        return 'reason_dashboard_not_allowed'.tr;
      case 'zone_not_allowed':
        return 'reason_zone_not_allowed'.tr;
      case 'role_not_allowed':
        return 'reason_role_not_allowed'.tr;
      case 'missing_permissions':
        return 'reason_missing_permissions'.tr;
      case 'inactive':
        return 'reason_inactive'.tr;
      case 'already_added':
        return 'reason_already_added'.tr;
      default:
        return 'reason_unavailable'.tr;
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'calendar_month_rounded':
        return Icons.calendar_month_rounded;
      case 'payments_rounded':
        return Icons.payments_rounded;
      case 'waving_hand_rounded':
        return Icons.waving_hand_rounded;
      case 'auto_graph_rounded':
        return Icons.auto_graph_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}
