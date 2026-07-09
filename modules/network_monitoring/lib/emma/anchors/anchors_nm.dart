import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class NetworkMonitoringEmmaAnchors {
  static const String _module = 'network_monitoring';

  static const String _feedScreenKey = 'network_monitoring_feed';
  static const String _feedRoute = '/network-monitoring';

  static const String _mapScreenKey = 'network_monitoring_map';
  static const String _mapRoute = '/network-monitoring/map';

  // ---------------------------------------------------------------------------
  // Feed / list view
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec feedRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedRoot',
    label: 'Network Monitoring feed',
    description:
        'Main Network Monitoring feed screen wrapper. Contains desktop or mobile feed depending on viewport.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'feed', 'root'],
  );

  static const EmmaUiAnchorSpec feedPcRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcRoot',
    label: 'Network Monitoring desktop feed',
    description:
        'Desktop layout for Network Monitoring feed with filters, advertisement grid and browse list.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'feed', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcFilters = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.filters',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcFilters',
    label: 'Network Monitoring filters',
    description:
        'Desktop filter panel used to filter Network Monitoring advertisements.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'filters', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcGrid = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.grid',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcGrid',
    label: 'Network Monitoring desktop grid wrapper',
    description:
        'Desktop grid area showing paginated Network Monitoring advertisements.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'grid', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcGridRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.grid.root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcGridRoot',
    label: 'Network Monitoring desktop grid',
    description:
        'Root of the desktop paginated advertisement grid, including toolbar and ad cards.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'grid', 'desktop', 'pagination'],
  );

  static const EmmaUiAnchorSpec feedPcBrowseList = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.browse_list',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcBrowseList',
    label: 'Network Monitoring browse list',
    description:
        'Desktop browse list panel for selected or browsed Network Monitoring advertisements.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'browse-list', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcToolbar = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.toolbar',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcToolbar',
    label: 'Network Monitoring desktop toolbar',
    description:
        'Toolbar above the desktop advertisement grid. Contains sorting, result count, map toggle and card type controls.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'toolbar', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcSortSelector = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.sort_selector',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcSortSelector',
    label: 'Sort selector',
    description:
        'Dropdown selector used to sort Network Monitoring advertisement results.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'sort', 'desktop', 'control'],
  );

  static const EmmaUiAnchorSpec feedPcResultsCount = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.results_count',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcResultsCount',
    label: 'Results count',
    description:
        'Displays the current number of advertisements found in Network Monitoring feed.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'results-count', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcMapToggle = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.map_toggle',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcMapToggle',
    label: 'Map view toggle',
    description:
        'Toggle used to switch between feed view and map view in Network Monitoring.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'toggle', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcCardTypeSelector = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.card_type_selector',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcCardTypeSelector',
    label: 'Card type selector',
    description:
        'Selector used to change the advertisement card layout in Network Monitoring feed.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'card-type', 'layout', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedPcNoResults = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.pc.no_results',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcNoResults',
    label: 'No results state',
    description:
        'Empty state displayed when no Network Monitoring advertisements match current filters on desktop.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'empty-state', 'desktop'],
  );

  static const EmmaUiAnchorSpec feedMobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileRoot',
    label: 'Network Monitoring mobile feed',
    description:
        'Mobile layout for Network Monitoring feed with paginated list or grid results.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'feed', 'mobile'],
  );

  static const EmmaUiAnchorSpec feedMobileNoResults = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.no_results',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileNoResults',
    label: 'No mobile results state',
    description:
        'Empty state displayed when no Network Monitoring advertisements match current filters on mobile.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'empty-state', 'mobile'],
  );

  static const EmmaUiAnchorSpec feedMobileVerticalBar = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.vertical_bar',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileVerticalBar',
    label: 'Mobile vertical action bar',
    description:
        'Floating vertical action bar for mobile Network Monitoring feed actions.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'mobile', 'vertical-bar'],
  );

  static const EmmaUiAnchorSpec feedMobileFiltersButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.filters_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileFiltersButton',
    label: 'Mobile filters button',
    description:
        'Button opening Network Monitoring filters bottom sheet on mobile.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'filters', 'mobile', 'button'],
  );

  static const EmmaUiAnchorSpec feedMobileSortButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.sort_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileSortButton',
    label: 'Mobile sort button',
    description: 'Button opening sorting and card layout options on mobile.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'sort', 'mobile', 'button'],
  );

  static const EmmaUiAnchorSpec feedMobileBrowseListButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.browse_list_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileBrowseListButton',
    label: 'Mobile browse list button',
    description:
        'Button opening the Network Monitoring browse list bottom sheet on mobile.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'browse-list', 'mobile', 'button'],
  );

  static const EmmaUiAnchorSpec feedMobileFiltersSheet = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.filters_sheet',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileFiltersSheet',
    label: 'Mobile filters sheet',
    description:
        'Bottom sheet containing Network Monitoring filters on mobile.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'filters', 'mobile', 'sheet'],
  );

  static const EmmaUiAnchorSpec feedMobileSortSheet = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.sort_sheet',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileSortSheet',
    label: 'Mobile sort sheet',
    description:
        'Bottom sheet containing Network Monitoring sort and card type options on mobile.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'sort', 'mobile', 'sheet'],
  );

  static const EmmaUiAnchorSpec feedMobileBrowseSheet = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.feed.mobile.browse_sheet',
    frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileBrowseSheet',
    label: 'Mobile browse list sheet',
    description:
        'Bottom sheet containing the Network Monitoring browse list on mobile.',
    module: _module,
    screenKey: _feedScreenKey,
    routePattern: _feedRoute,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'browse-list', 'mobile', 'sheet'],
  );

  // ---------------------------------------------------------------------------
  // Map view
  // ---------------------------------------------------------------------------

  static const EmmaUiAnchorSpec mapRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapRoot',
    label: 'Network Monitoring map screen',
    description:
        'Main Network Monitoring map screen wrapper with map canvas, toolbar, side results and browse list.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'root'],
  );

  static const EmmaUiAnchorSpec mapCanvas = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.canvas',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapCanvas',
    label: 'Map canvas',
    description:
        'Main map canvas used to browse Network Monitoring advertisements geographically.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'canvas'],
  );

  static const EmmaUiAnchorSpec mapTopToolbar = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.top_toolbar',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapTopToolbar',
    label: 'Map top toolbar',
    description:
        'Top toolbar on the Network Monitoring map with sorting, filters, result count, feed toggle and card layout controls.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'toolbar'],
  );

  static const EmmaUiAnchorSpec mapSortSelector = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.sort_selector',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapSortSelector',
    label: 'Map sort selector',
    description:
        'Dropdown selector used to sort Network Monitoring advertisements while browsing the map.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'sort', 'control'],
  );

  static const EmmaUiAnchorSpec mapFiltersButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.filters_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapFiltersButton',
    label: 'Map filters button',
    description:
        'Button opening all filters overlay for Network Monitoring map results.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'filters', 'button'],
  );

  static const EmmaUiAnchorSpec mapResultsCount = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.results_count',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapResultsCount',
    label: 'Map results count',
    description:
        'Displays the number of Network Monitoring advertisements matching current map filters and viewport.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'results-count'],
  );

  static const EmmaUiAnchorSpec mapFeedToggle = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.feed_toggle',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapFeedToggle',
    label: 'Feed view toggle',
    description:
        'Toggle used to switch from Network Monitoring map view back to feed view.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'feed-toggle', 'button'],
  );

  static const EmmaUiAnchorSpec mapCardTypeSelector = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.card_type_selector',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapCardTypeSelector',
    label: 'Map card type selector',
    description:
        'Selector used to change card layout for Network Monitoring map side results.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'card-type', 'layout'],
  );

  static const EmmaUiAnchorSpec mapDrawingControls = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.drawing_controls',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapDrawingControls',
    label: 'Map drawing controls',
    description:
        'Control group used to clear drawn area, switch draw mode, open map layers and manage map cache.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'drawing', 'controls'],
  );

  static const EmmaUiAnchorSpec mapClearDrawingButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.clear_drawing_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapClearDrawingButton',
    label: 'Clear drawing button',
    description:
        'Button clearing the currently drawn polygon or selected map area.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'drawing', 'clear', 'button'],
  );

  static const EmmaUiAnchorSpec mapDrawModeButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.draw_mode_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapDrawModeButton',
    label: 'Draw mode button',
    description:
        'Button switching between map browsing mode and freehand drawing mode.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'drawing', 'mode', 'button'],
  );

  static const EmmaUiAnchorSpec mapLayersButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.layers_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapLayersButton',
    label: 'Map layers button',
    description:
        'Button opening the map layers settings panel for parcels, MPZP, GESUT and related layers.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'layers', 'button'],
  );

  static const EmmaUiAnchorSpec mapCacheButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.cache_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapCacheButton',
    label: 'Map cache button',
    description:
        'Button opening the map layer cache manager for cached map data.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'cache', 'button'],
  );

  static const EmmaUiAnchorSpec mapSidePanel = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.side_panel',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapSidePanel',
    label: 'Map side results panel',
    description:
        'Right side panel displaying paginated advertisements matching the current map viewport and filters.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'side-panel', 'results'],
  );

  static const EmmaUiAnchorSpec mapSidePanelHeader = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.side_panel_header',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapSidePanelHeader',
    label: 'Map side panel header',
    description:
        'Header of the map side panel with result count and card layout selector.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'side-panel', 'header'],
  );

  static const EmmaUiAnchorSpec mapSideResultsList = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.side_results_list',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapSideResultsList',
    label: 'Map side results list',
    description:
        'Scrollable paginated list of Network Monitoring advertisements shown next to the map.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'side-panel', 'list'],
  );

  static const EmmaUiAnchorSpec mapNoResults = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.no_results',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapNoResults',
    label: 'Map no results state',
    description:
        'Empty state displayed when no advertisements match current map viewport or filters.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'map', 'empty-state'],
  );

  static const EmmaUiAnchorSpec mapBrowseList = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.browse_list',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapBrowseList',
    label: 'Map browse list',
    description:
        'Browse list panel displayed next to the Network Monitoring map screen.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'browse-list'],
  );

  static const EmmaUiAnchorSpec mapInnerRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.inner_root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapInnerRoot',
    label: 'Network Monitoring inner map',
    description:
        'Inner AppMapShell instance responsible for map tiles, pins, overlays and layer services.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'map', 'inner', 'shell'],
  );

  static const EmmaUiAnchorSpec mapDrawnPolygonLayer = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.drawn_polygon_layer',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapDrawnPolygonLayer',
    label: 'Drawn polygon layer',
    description:
        'Map polygon layer rendered after drawing a closed search area on the map.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'map', 'drawing', 'polygon'],
  );

  static const EmmaUiAnchorSpec mapDrawnPolylineLayer = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.drawn_polyline_layer',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapDrawnPolylineLayer',
    label: 'Drawn polyline layer',
    description:
        'Map polyline layer rendered while drawing or previewing a search area on the map.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'map', 'drawing', 'polyline'],
  );

  static const EmmaUiAnchorSpec mapDrawOverlay = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.draw_overlay',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapDrawOverlay',
    label: 'Map drawing overlay',
    description:
        'Transparent interaction overlay used to capture pointer input while drawing a freehand map area.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'map', 'drawing', 'overlay'],
  );

  static const EmmaUiAnchorSpec mapStatusOverlay = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.status_overlay',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapStatusOverlay',
    label: 'Map status overlay',
    description:
        'Bottom status overlay area used to show map loading and error notices.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'map', 'status', 'overlay'],
  );

  static const EmmaUiAnchorSpec mapLoadingNotice = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.loading_notice',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapLoadingNotice',
    label: 'Map loading notice',
    description:
        'Notice displayed while map advertisements or pins are being loaded.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'map', 'loading', 'notice'],
  );

  static const EmmaUiAnchorSpec mapErrorNotice = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.map.error_notice',
    frontendRef: 'NetworkMonitoringEmmaAnchors.mapErrorNotice',
    label: 'Map error notice',
    description:
        'Notice displayed when loading map advertisements or pins fails.',
    module: _module,
    screenKey: _mapScreenKey,
    routePattern: _mapRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'map', 'error', 'notice'],
  );

  // ---------------------------------------------------------------------------
  // Static export list
  // ---------------------------------------------------------------------------

  static List<EmmaUiAnchorSpec> get all => const [
        feedRoot,
        feedPcRoot,
        feedPcFilters,
        feedPcGrid,
        feedPcGridRoot,
        feedPcBrowseList,
        feedPcToolbar,
        feedPcSortSelector,
        feedPcResultsCount,
        feedPcMapToggle,
        feedPcCardTypeSelector,
        feedPcNoResults,
        feedMobileRoot,
        feedMobileNoResults,
        feedMobileVerticalBar,
        feedMobileFiltersButton,
        feedMobileSortButton,
        feedMobileBrowseListButton,
        feedMobileFiltersSheet,
        feedMobileSortSheet,
        feedMobileBrowseSheet,

        mapRoot,
        mapCanvas,
        mapTopToolbar,
        mapSortSelector,
        mapFiltersButton,
        mapResultsCount,
        mapFeedToggle,
        mapCardTypeSelector,
        mapDrawingControls,
        mapClearDrawingButton,
        mapDrawModeButton,
        mapLayersButton,
        mapCacheButton,
        mapSidePanel,
        mapSidePanelHeader,
        mapSideResultsList,
        mapNoResults,
        mapBrowseList,
        mapInnerRoot,
        mapDrawnPolygonLayer,
        mapDrawnPolylineLayer,
        mapDrawOverlay,
        mapStatusOverlay,
        mapLoadingNotice,
        mapErrorNotice,
      ];

  // ---------------------------------------------------------------------------
  // Runtime / dynamic anchors
  // ---------------------------------------------------------------------------

  static EmmaUiAnchorSpec feedPcCard(int adId) => EmmaUiAnchorSpec(
        anchorKey: 'network_monitoring.feed.pc.card.$adId',
        frontendRef: 'NetworkMonitoringEmmaAnchors.feedPcCard($adId)',
        label: 'Network Monitoring desktop advertisement card',
        description:
            'Runtime anchor for a single Network Monitoring advertisement card on desktop.',
        module: _module,
        screenKey: _feedScreenKey,
        routePattern: _feedRoute,
        targetKind: EmmaUiAnchorTargetKind.card,
        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
        usageMode: EmmaUiAnchorUsageMode.both,
        tags: ['network-monitoring', 'advertisement', 'card', 'desktop'],
      );

  static EmmaUiAnchorSpec feedMobileGridCard(int adId) => EmmaUiAnchorSpec(
        anchorKey: 'network_monitoring.feed.mobile.grid_card.$adId',
        frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileGridCard($adId)',
        label: 'Network Monitoring mobile grid advertisement card',
        description:
            'Runtime anchor for a single Network Monitoring advertisement card in mobile grid mode.',
        module: _module,
        screenKey: _feedScreenKey,
        routePattern: _feedRoute,
        targetKind: EmmaUiAnchorTargetKind.card,
        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
        usageMode: EmmaUiAnchorUsageMode.both,
        tags: ['network-monitoring', 'advertisement', 'card', 'mobile', 'grid'],
      );

  static EmmaUiAnchorSpec feedMobileListCard(int adId) => EmmaUiAnchorSpec(
        anchorKey: 'network_monitoring.feed.mobile.list_card.$adId',
        frontendRef: 'NetworkMonitoringEmmaAnchors.feedMobileListCard($adId)',
        label: 'Network Monitoring mobile list advertisement card',
        description:
            'Runtime anchor for a single Network Monitoring advertisement card in mobile list mode.',
        module: _module,
        screenKey: _feedScreenKey,
        routePattern: _feedRoute,
        targetKind: EmmaUiAnchorTargetKind.card,
        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
        usageMode: EmmaUiAnchorUsageMode.both,
        tags: ['network-monitoring', 'advertisement', 'card', 'mobile', 'list'],
      );

  static EmmaUiAnchorSpec mapSideCard(int adId) => EmmaUiAnchorSpec(
        anchorKey: 'network_monitoring.map.side_card.$adId',
        frontendRef: 'NetworkMonitoringEmmaAnchors.mapSideCard($adId)',
        label: 'Network Monitoring map side advertisement card',
        description:
            'Runtime anchor for a single advertisement card in the Network Monitoring map side panel.',
        module: _module,
        screenKey: _mapScreenKey,
        routePattern: _mapRoute,
        targetKind: EmmaUiAnchorTargetKind.card,
        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
        usageMode: EmmaUiAnchorUsageMode.both,
        tags: ['network-monitoring', 'map', 'advertisement', 'card'],
      );


        // ---------------------------------------------------------------------------
  // Saved searches / saved search inbox
  // ---------------------------------------------------------------------------

  static const String _savedSearchScreenKey =
      'network_monitoring_saved_searches';
  static const String _savedSearchRoute = '/network-monitoring/saved-searches';

  static const EmmaUiAnchorSpec savedSearchMobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.mobile.root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchMobileRoot',
    label: 'Saved searches mobile root',
    description:
        'Mobile saved searches screen wrapper. Switches between saved searches list and selected inbox panel.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'mobile', 'root'],
  );

  static const EmmaUiAnchorSpec savedSearchMobileList = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.mobile.list',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchMobileList',
    label: 'Saved searches mobile list',
    description:
        'Mobile list of saved searches with counters and available search definitions.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'mobile', 'list'],
  );

  static const EmmaUiAnchorSpec savedSearchMobilePanel = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.mobile.panel',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchMobilePanel',
    label: 'Saved search mobile results panel',
    description:
        'Mobile panel showing results for the currently selected saved search.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'mobile', 'panel'],
  );

  static const EmmaUiAnchorSpec savedSearchMobileHeader = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.mobile.header',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchMobileHeader',
    label: 'Saved search mobile header',
    description:
        'Header for mobile saved search results, including title and back action.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'mobile', 'header'],
  );

  static const EmmaUiAnchorSpec savedSearchMobileBackButton = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.mobile.back_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchMobileBackButton',
    label: 'Saved search mobile back button',
    description:
        'Button closing selected saved search results and returning to saved searches list on mobile.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'mobile', 'back-button'],
  );

  static const EmmaUiAnchorSpec savedSearchMobileInboxPanel =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.mobile.inbox_panel',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchMobileInboxPanel',
    label: 'Saved search mobile inbox panel',
    description:
        'Inbox panel with advertisements returned by the selected saved search on mobile.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'mobile', 'inbox'],
  );

  static const EmmaUiAnchorSpec savedSearchPcRoot = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.root',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcRoot',
    label: 'Saved searches desktop root',
    description:
        'Desktop saved searches screen wrapper with list, sequential mode and inbox mode.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'root'],
  );

  static const EmmaUiAnchorSpec savedSearchPcHero = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.hero',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcHero',
    label: 'Saved searches desktop hero',
    description:
        'Hero banner displayed above the saved searches list on desktop.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'hero'],
  );

  static const EmmaUiAnchorSpec savedSearchPcListMode = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.list_mode',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcListMode',
    label: 'Saved searches desktop list mode',
    description:
        'Centered desktop list mode showing only saved searches sidebar panel.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'list-mode'],
  );

  static const EmmaUiAnchorSpec savedSearchPcSequentialMode =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.sequential_mode',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcSequentialMode',
    label: 'Saved searches sequential mode',
    description:
        'Desktop sequential mode with saved searches sidebar and inbox panel shown side by side.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'sequential'],
  );

  static const EmmaUiAnchorSpec savedSearchPcInboxMode = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.inbox_mode',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcInboxMode',
    label: 'Saved searches inbox mode',
    description:
        'Desktop inbox-only mode for browsing merged or selected saved search results.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'inbox-mode'],
  );

  static const EmmaUiAnchorSpec savedSearchPcSidebarPanel =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.sidebar_panel',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcSidebarPanel',
    label: 'Saved searches sidebar panel',
    description:
        'Desktop sidebar panel containing filters, saved searches list and pagination.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'sidebar'],
  );

  static const EmmaUiAnchorSpec savedSearchPcFiltersHeader =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.filters_header',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcFiltersHeader',
    label: 'Saved searches filters header',
    description:
        'Header and filters area for desktop saved searches list.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'filters'],
  );

  static const EmmaUiAnchorSpec savedSearchPcAllNewButton =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.all_new_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcAllNewButton',
    label: 'All new ads button',
    description:
        'Button opening merged inbox with all new advertisements from saved searches.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'all-new'],
  );

  static const EmmaUiAnchorSpec savedSearchPcSearchInput =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.search_input',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcSearchInput',
    label: 'Saved searches search input',
    description:
        'Input used to search saved search definitions by title or metadata.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'search'],
  );

  static const EmmaUiAnchorSpec savedSearchPcSortDropdown =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.sort_dropdown',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcSortDropdown',
    label: 'Saved searches sort dropdown',
    description:
        'Dropdown used to sort saved searches by new count, update date, title or creation date.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'sort'],
  );

  static const EmmaUiAnchorSpec savedSearchPcScopeDropdown =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.scope_dropdown',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcScopeDropdown',
    label: 'Saved searches scope dropdown',
    description:
        'Dropdown used to filter saved searches by assignment scope.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'scope'],
  );

  static const EmmaUiAnchorSpec savedSearchPcFilterChips =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.filter_chips',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcFilterChips',
    label: 'Saved searches filter chips',
    description:
        'Filter chips used to show saved searches with new results, any results, notifications or e-mail notifications.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'chips'],
  );

  static const EmmaUiAnchorSpec savedSearchPcResetFiltersButton =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.reset_filters_button',
    frontendRef:
        'NetworkMonitoringEmmaAnchors.savedSearchPcResetFiltersButton',
    label: 'Reset saved search filters button',
    description:
        'Button resetting saved searches list filters to default values.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'reset'],
  );

  static const EmmaUiAnchorSpec savedSearchPcSequentialNotice =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.sequential_notice',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcSequentialNotice',
    label: 'Sequential mode notice',
    description:
        'Notice explaining that sequential mode highlights the currently active saved search.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'notice'],
  );

  static const EmmaUiAnchorSpec savedSearchPcList = EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.list',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcList',
    label: 'Saved searches desktop list',
    description:
        'Desktop saved searches list with counters and selectable saved search items.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'list'],
  );

  static const EmmaUiAnchorSpec savedSearchPcInboxPanel =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.inbox_panel',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcInboxPanel',
    label: 'Saved searches desktop inbox panel',
    description:
        'Desktop inbox panel displaying advertisements from selected or merged saved searches.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'inbox'],
  );

  static const EmmaUiAnchorSpec savedSearchPcPaginationFooter =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.pagination_footer',
    frontendRef:
        'NetworkMonitoringEmmaAnchors.savedSearchPcPaginationFooter',
    label: 'Saved searches pagination footer',
    description:
        'Footer containing saved searches result count, page size selector and pagination controls.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'pagination'],
  );

  static const EmmaUiAnchorSpec savedSearchPcPageSizeDropdown =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.page_size_dropdown',
    frontendRef:
        'NetworkMonitoringEmmaAnchors.savedSearchPcPageSizeDropdown',
    label: 'Saved searches page size dropdown',
    description:
        'Dropdown used to change the number of saved searches displayed per page.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'page-size'],
  );

  static const EmmaUiAnchorSpec savedSearchPcPreviousPageButton =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.previous_page_button',
    frontendRef:
        'NetworkMonitoringEmmaAnchors.savedSearchPcPreviousPageButton',
    label: 'Previous saved searches page button',
    description:
        'Button navigating to the previous page of saved searches.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'pagination'],
  );

  static const EmmaUiAnchorSpec savedSearchPcNextPageButton =
      EmmaUiAnchorSpec(
    anchorKey: 'network_monitoring.saved_search.pc.next_page_button',
    frontendRef: 'NetworkMonitoringEmmaAnchors.savedSearchPcNextPageButton',
    label: 'Next saved searches page button',
    description:
        'Button navigating to the next page of saved searches.',
    module: _module,
    screenKey: _savedSearchScreenKey,
    routePattern: _savedSearchRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['network-monitoring', 'saved-search', 'desktop', 'pagination'],
  );

  
}