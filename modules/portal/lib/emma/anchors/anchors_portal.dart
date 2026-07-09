import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class PortalEmmaAnchors {
  static const String _module = 'portal';

  // ---------------------------------------------------------------------------
  // Feed – PC
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec feedPcRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.feed.pc.root',
    frontendRef: 'PortalEmmaAnchors.feedPcRoot',
    label: 'Portal feed (desktop)',
    description: 'Root of the desktop property listings feed.',
    module: _module,
    screenKey: 'feed_pc',
    routePattern: '/portal/feed',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'feed', 'desktop', 'listings'],
    meta: {'group': 'feed', 'platform': 'desktop'},
  );

  static const EmmaUiAnchorSpec feedPcQuickFilters = EmmaUiAnchorSpec(
    anchorKey: 'portal.feed.pc.quick_filters',
    frontendRef: 'PortalEmmaAnchors.feedPcQuickFilters',
    label: 'Quick filters sidebar',
    description: 'Left-side quick filters panel on the desktop listings feed.',
    module: _module,
    screenKey: 'feed_pc',
    routePattern: '/portal/feed',
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'feed', 'filters', 'sidebar', 'desktop'],
    meta: {'group': 'feed', 'platform': 'desktop'},
  );

  static const EmmaUiAnchorSpec feedPcMapWidget = EmmaUiAnchorSpec(
    anchorKey: 'portal.feed.pc.map',
    frontendRef: 'PortalEmmaAnchors.feedPcMapWidget',
    label: 'Feed map widget',
    description: 'Collapsed map preview embedded at the top of the desktop listings feed.',
    module: _module,
    screenKey: 'feed_pc',
    routePattern: '/portal/feed',
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'feed', 'map', 'desktop'],
    meta: {'group': 'feed', 'platform': 'desktop'},
  );

  static const EmmaUiAnchorSpec feedPcSortBar = EmmaUiAnchorSpec(
    anchorKey: 'portal.feed.pc.sort_bar',
    frontendRef: 'PortalEmmaAnchors.feedPcSortBar',
    label: 'Sort & view selector',
    description: 'Row containing sort dropdown and card-type (view) selector in the desktop feed.',
    module: _module,
    screenKey: 'feed_pc',
    routePattern: '/portal/feed',
    targetKind: EmmaUiAnchorTargetKind.nav,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['portal', 'feed', 'sort', 'view', 'desktop'],
    meta: {'group': 'feed', 'platform': 'desktop'},
  );

  static const EmmaUiAnchorSpec feedPcAdList = EmmaUiAnchorSpec(
    anchorKey: 'portal.feed.pc.ad_list',
    frontendRef: 'PortalEmmaAnchors.feedPcAdList',
    label: 'Listings grid (desktop)',
    description: 'Paginated grid of property listing cards on the desktop feed.',
    module: _module,
    screenKey: 'feed_pc',
    routePattern: '/portal/feed',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'feed', 'grid', 'listings', 'desktop'],
    meta: {'group': 'feed', 'platform': 'desktop'},
  );

  // ---------------------------------------------------------------------------
  // Feed – Mobile
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec feedMobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.feed.mobile.root',
    frontendRef: 'PortalEmmaAnchors.feedMobileRoot',
    label: 'Portal feed (mobile)',
    description: 'Root of the mobile property listings feed.',
    module: _module,
    screenKey: 'feed_mobile',
    routePattern: '/portal/feed',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'feed', 'mobile', 'listings'],
    meta: {'group': 'feed', 'platform': 'mobile'},
  );

  static const EmmaUiAnchorSpec feedMobileAdList = EmmaUiAnchorSpec(
    anchorKey: 'portal.feed.mobile.ad_list',
    frontendRef: 'PortalEmmaAnchors.feedMobileAdList',
    label: 'Listings grid (mobile)',
    description: 'Paginated grid of property listing cards on the mobile feed.',
    module: _module,
    screenKey: 'feed_mobile',
    routePattern: '/portal/feed',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'feed', 'grid', 'listings', 'mobile'],
    meta: {'group': 'feed', 'platform': 'mobile'},
  );

  // ---------------------------------------------------------------------------
  // Ad detail popup
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec adDetailRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.ad_detail.root',
    frontendRef: 'PortalEmmaAnchors.adDetailRoot',
    label: 'Ad detail popup',
    description: 'Root of the ad detail popup (all layout variants).',
    module: _module,
    screenKey: 'ad_detail',
    routePattern: '/portal/offer/:slug',
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'ad', 'detail', 'popup'],
    meta: {'group': 'ad_detail'},
  );

  static const EmmaUiAnchorSpec adDetailFullRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.ad_detail.full.root',
    frontendRef: 'PortalEmmaAnchors.adDetailFullRoot',
    label: 'Ad detail (wide desktop)',
    description: 'Scrollable content area of the full-width desktop ad detail view.',
    module: _module,
    screenKey: 'ad_detail_full',
    routePattern: '/portal/offer/:slug',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'ad', 'detail', 'desktop', 'full'],
    meta: {'group': 'ad_detail', 'platform': 'desktop_full'},
  );

  static const EmmaUiAnchorSpec adDetailMidRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.ad_detail.mid.root',
    frontendRef: 'PortalEmmaAnchors.adDetailMidRoot',
    label: 'Ad detail (mid desktop)',
    description: 'Scrollable content area of the mid-width desktop ad detail view.',
    module: _module,
    screenKey: 'ad_detail_mid',
    routePattern: '/portal/offer/:slug',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'ad', 'detail', 'desktop', 'mid'],
    meta: {'group': 'ad_detail', 'platform': 'desktop_mid'},
  );

  static const EmmaUiAnchorSpec adDetailMobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.ad_detail.mobile.root',
    frontendRef: 'PortalEmmaAnchors.adDetailMobileRoot',
    label: 'Ad detail (mobile)',
    description: 'Scrollable content area of the mobile ad detail view.',
    module: _module,
    screenKey: 'ad_detail_mobile',
    routePattern: '/portal/offer/:slug',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'ad', 'detail', 'mobile'],
    meta: {'group': 'ad_detail', 'platform': 'mobile'},
  );

  // ---------------------------------------------------------------------------
  // Filters dialog
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec filtersRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.filters.root',
    frontendRef: 'PortalEmmaAnchors.filtersRoot',
    label: 'Filters dialog',
    description: 'Root of the search filters dialog (PC and mobile variants).',
    module: _module,
    screenKey: 'filters',
    routePattern: '/portal/filters',
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'filters', 'search'],
    meta: {'group': 'filters'},
  );

  static const EmmaUiAnchorSpec filtersPcOfferType = EmmaUiAnchorSpec(
    anchorKey: 'portal.filters.pc.offer_type',
    frontendRef: 'PortalEmmaAnchors.filtersPcOfferType',
    label: 'Filters – offer type',
    description: 'Offer type (sale / rent) button group in the filters dialog.',
    module: _module,
    screenKey: 'filters',
    routePattern: '/portal/filters',
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['portal', 'filters', 'offer_type'],
    meta: {'group': 'filters'},
  );

  static const EmmaUiAnchorSpec filtersPcLocation = EmmaUiAnchorSpec(
    anchorKey: 'portal.filters.pc.location',
    frontendRef: 'PortalEmmaAnchors.filtersPcLocation',
    label: 'Filters – location input',
    description: 'Location autocomplete input in the filters dialog.',
    module: _module,
    screenKey: 'filters',
    routePattern: '/portal/filters',
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['portal', 'filters', 'location', 'search'],
    meta: {'group': 'filters'},
  );

  static const EmmaUiAnchorSpec filtersPcSubmit = EmmaUiAnchorSpec(
    anchorKey: 'portal.filters.pc.submit',
    frontendRef: 'PortalEmmaAnchors.filtersPcSubmit',
    label: 'Filters – apply button',
    description: 'Button to apply the selected filters.',
    module: _module,
    screenKey: 'filters',
    routePattern: '/portal/filters',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['portal', 'filters', 'submit', 'apply'],
    meta: {'group': 'filters'},
  );

  // ---------------------------------------------------------------------------
  // Add offer wizard
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec addOfferRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.add_offer.root',
    frontendRef: 'PortalEmmaAnchors.addOfferRoot',
    label: 'Add offer wizard',
    description: 'Root container of the add offer step-by-step wizard.',
    module: _module,
    screenKey: 'add_offer',
    routePattern: '/portal/add-offer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'add_offer', 'wizard'],
    meta: {'group': 'add_offer'},
  );

  static const EmmaUiAnchorSpec addOfferProgress = EmmaUiAnchorSpec(
    anchorKey: 'portal.add_offer.progress',
    frontendRef: 'PortalEmmaAnchors.addOfferProgress',
    label: 'Add offer – progress bar',
    description: 'Step progress indicator at the top of the add offer wizard.',
    module: _module,
    screenKey: 'add_offer',
    routePattern: '/portal/add-offer',
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['portal', 'add_offer', 'progress', 'steps'],
    meta: {'group': 'add_offer'},
  );

  // ---------------------------------------------------------------------------
  // Landing page
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec landingPcRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.landing.pc.root',
    frontendRef: 'PortalEmmaAnchors.landingPcRoot',
    label: 'Landing page (desktop)',
    description: 'Root of the desktop portal landing page.',
    module: _module,
    screenKey: 'landing_pc',
    routePattern: '/portal',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'landing', 'desktop'],
    meta: {'group': 'landing', 'platform': 'desktop'},
  );

  static const EmmaUiAnchorSpec landingMobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.landing.mobile.root',
    frontendRef: 'PortalEmmaAnchors.landingMobileRoot',
    label: 'Landing page (mobile)',
    description: 'Root of the mobile portal landing page.',
    module: _module,
    screenKey: 'landing_mobile',
    routePattern: '/portal',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'landing', 'mobile'],
    meta: {'group': 'landing', 'platform': 'mobile'},
  );

  // ---------------------------------------------------------------------------
  // Map view
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec mapViewRoot = EmmaUiAnchorSpec(
    anchorKey: 'portal.map.root',
    frontendRef: 'PortalEmmaAnchors.mapViewRoot',
    label: 'Map view',
    description: 'Full map view page showing property listings on a map.',
    module: _module,
    screenKey: 'map_view',
    routePattern: '/portal/map',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['portal', 'map', 'listings'],
    meta: {'group': 'map'},
  );

  static const List<EmmaUiAnchorSpec> all = [
    feedPcRoot,
    feedPcQuickFilters,
    feedPcMapWidget,
    feedPcSortBar,
    feedPcAdList,
    feedMobileRoot,
    feedMobileAdList,
    adDetailRoot,
    adDetailFullRoot,
    adDetailMidRoot,
    adDetailMobileRoot,
    filtersRoot,
    filtersPcOfferType,
    filtersPcLocation,
    filtersPcSubmit,
    addOfferRoot,
    addOfferProgress,
    landingPcRoot,
    landingMobileRoot,
    mapViewRoot,
  ];
}
