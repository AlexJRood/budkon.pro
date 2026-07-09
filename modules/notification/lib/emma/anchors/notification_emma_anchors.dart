import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class NotificationEmmaAnchors {
  static const String _module = 'notification';
  static const String _screen = 'notification_center';
  static const String _route = '/notification';
  
  static const EmmaUiAnchorSpec screenRoot = EmmaUiAnchorSpec(
    anchorKey: 'notification.screen.root',
    frontendRef: 'NotificationEmmaAnchors.screenRoot',
    label: 'Notification Screen Root',
    description: 'Main container for the notification center with blur background',
    module: _module,
    screenKey: _screen,
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'screen', 'container', 'layout'],
    meta: {
      'group': 'layout',
      'appModule': 'notification',
      'hasBackdrop': true,
    },
    onboardingOrder: 1,
    onboardingMessage: 'This is your notification center where you see all alerts.',
  );

  static const EmmaUiAnchorSpec dismissArea = EmmaUiAnchorSpec(
    anchorKey: 'notification.screen.dismiss_area',
    frontendRef: 'NotificationEmmaAnchors.dismissArea',
    label: 'Notification Dismiss Area',
    description: 'Background area that closes the notification center when tapped',
    module: _module,
    screenKey: _screen,
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['notification', 'dismiss', 'close', 'gesture'],
    meta: {
      'group': 'interactions',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec content = EmmaUiAnchorSpec(
    anchorKey: 'notification.screen.content',
    frontendRef: 'NotificationEmmaAnchors.content',
    label: 'Notification Content Container',
    description: 'Main content area containing the notification list',
    module: _module,
    screenKey: _screen,
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'content', 'container', 'list'],
    meta: {
      'group': 'layout',
      'appModule': 'notification',
    },
  );


  static const String _mobileScreen = 'notification_mobile';
  static const String _mobileRoute = '/notification/mobile';
  static const EmmaUiAnchorSpec mobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'notification.mobile.root',
    frontendRef: 'NotificationEmmaAnchors.mobileRoot',
    label: 'Mobile Notification View',
    description: 'Mobile-optimized notification center with stacked cards',
    module: _module,
    screenKey: _mobileScreen,
    routePattern: _mobileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'mobile', 'screen', 'list'],
    meta: {
      'group': 'layout',
      'platform': 'mobile',
      'appModule': 'notification',
    },
    onboardingOrder: 10,
    onboardingMessage: 'Your notifications appear here on mobile devices.',
  );

  static const EmmaUiAnchorSpec mobileAppbar = EmmaUiAnchorSpec(
    anchorKey: 'notification.mobile.appbar',
    frontendRef: 'NotificationEmmaAnchors.mobileAppbar',
    label: 'Mobile Notification App Bar',
    description: 'Top app bar with title and back button for notification center',
    module: _module,
    screenKey: _mobileScreen,
    routePattern: _mobileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'mobile', 'appbar', 'navigation'],
    meta: {
      'group': 'navigation',
      'platform': 'mobile',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec mobileList = EmmaUiAnchorSpec(
    anchorKey: 'notification.mobile.list',
    frontendRef: 'NotificationEmmaAnchors.mobileList',
    label: 'Mobile Notification List',
    description: 'Scrollable list of all notifications on mobile',
    module: _module,
    screenKey: _mobileScreen,
    routePattern: _mobileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'mobile', 'list', 'scrollable'],
    meta: {
      'group': 'content',
      'platform': 'mobile',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec mobileFirstCard = EmmaUiAnchorSpec(
    anchorKey: 'notification.mobile.first_card',
    frontendRef: 'NotificationEmmaAnchors.mobileFirstCard',
    label: 'First Notification Card',
    description: 'The first/top notification item in the mobile list',
    module: _module,
    screenKey: _mobileScreen,
    routePattern: _mobileRoute,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'mobile', 'card', 'first', 'onboarding'],
    meta: {
      'group': 'notification_items',
      'platform': 'mobile',
      'appModule': 'notification',
    },
    onboardingOrder: 11,
    onboardingMessage: 'Tap any notification to view its details.',
  );

  static const EmmaUiAnchorSpec mobileEmptyState = EmmaUiAnchorSpec(
    anchorKey: 'notification.mobile.empty_state',
    frontendRef: 'NotificationEmmaAnchors.mobileEmptyState',
    label: 'Mobile Empty State',
    description: 'Empty state shown when there are no notifications',
    module: _module,
    screenKey: _mobileScreen,
    routePattern: _mobileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['notification', 'mobile', 'empty', 'state'],
    meta: {
      'group': 'states',
      'platform': 'mobile',
      'appModule': 'notification',
    },
  );


  static const String _pcScreen = 'notification_pc';
  static const String _pcRoute = '/notification/pc';
  static const EmmaUiAnchorSpec pcRoot = EmmaUiAnchorSpec(
    anchorKey: 'notification.pc.root',
    frontendRef: 'NotificationEmmaAnchors.pcRoot',
    label: 'Desktop Notification View',
    description: 'Desktop-optimized notification center with sidebar',
    module: _module,
    screenKey: _pcScreen,
    routePattern: _pcRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'desktop', 'screen', 'sidebar'],
    meta: {
      'group': 'layout',
      'platform': 'desktop',
      'appModule': 'notification',
    },
    onboardingOrder: 20,
    onboardingMessage: 'Your notifications appear here on desktop devices.',
  );

  static const EmmaUiAnchorSpec pcSidebar = EmmaUiAnchorSpec(
    anchorKey: 'notification.pc.sidebar',
    frontendRef: 'NotificationEmmaAnchors.pcSidebar',
    label: 'Desktop Notification Sidebar',
    description: 'Left sidebar with chat and navigation options',
    module: _module,
    screenKey: _pcScreen,
    routePattern: _pcRoute,
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'desktop', 'sidebar', 'navigation', 'chat'],
    meta: {
      'group': 'navigation',
      'platform': 'desktop',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec pcPanel = EmmaUiAnchorSpec(
    anchorKey: 'notification.pc.panel',
    frontendRef: 'NotificationEmmaAnchors.pcPanel',
    label: 'Desktop Notification Panel',
    description: 'Main content panel containing the notification list',
    module: _module,
    screenKey: _pcScreen,
    routePattern: _pcRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'desktop', 'panel', 'content'],
    meta: {
      'group': 'content',
      'platform': 'desktop',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec pcList = EmmaUiAnchorSpec(
    anchorKey: 'notification.pc.list',
    frontendRef: 'NotificationEmmaAnchors.pcList',
    label: 'Desktop Notification List',
    description: 'Scrollable list of notifications with separators',
    module: _module,
    screenKey: _pcScreen,
    routePattern: _pcRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'desktop', 'list', 'scrollable'],
    meta: {
      'group': 'content',
      'platform': 'desktop',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec pcFirstCard = EmmaUiAnchorSpec(
    anchorKey: 'notification.pc.first_card',
    frontendRef: 'NotificationEmmaAnchors.pcFirstCard',
    label: 'First Desktop Notification Card',
    description: 'The first notification item in the desktop list',
    module: _module,
    screenKey: _pcScreen,
    routePattern: _pcRoute,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'desktop', 'card', 'first', 'onboarding'],
    meta: {
      'group': 'notification_items',
      'platform': 'desktop',
      'appModule': 'notification',
    },
    onboardingOrder: 21,
    onboardingMessage: 'Click any notification to view its details.',
  );

  static const EmmaUiAnchorSpec pcLoadingState = EmmaUiAnchorSpec(
    anchorKey: 'notification.pc.loading_state',
    frontendRef: 'NotificationEmmaAnchors.pcLoadingState',
    label: 'Desktop Loading State',
    description: 'Loading indicator shown while fetching notifications',
    module: _module,
    screenKey: _pcScreen,
    routePattern: _pcRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['notification', 'desktop', 'loading', 'state'],
    meta: {
      'group': 'states',
      'platform': 'desktop',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec pcEmptyState = EmmaUiAnchorSpec(
    anchorKey: 'notification.pc.empty_state',
    frontendRef: 'NotificationEmmaAnchors.pcEmptyState',
    label: 'Desktop Empty State',
    description: 'Empty state shown when there are no notifications on desktop',
    module: _module,
    screenKey: _pcScreen,
    routePattern: _pcRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['notification', 'desktop', 'empty', 'state'],
    meta: {
      'group': 'states',
      'platform': 'desktop',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec markAsReadAction = EmmaUiAnchorSpec(
    anchorKey: 'notification.card.action.mark_as_read',
    frontendRef: 'NotificationEmmaAnchors.markAsReadAction',
    label: 'Mark as Read Action',
    description: 'Button or gesture to mark a notification as read',
    module: _module,
    screenKey: _screen,
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['notification', 'action', 'mark_read', 'button'],
    meta: {
      'group': 'notification_actions',
      'appModule': 'notification',
    },
  );

  static const EmmaUiAnchorSpec deleteAction = EmmaUiAnchorSpec(
    anchorKey: 'notification.card.action.delete',
    frontendRef: 'NotificationEmmaAnchors.deleteAction',
    label: 'Delete Notification Action',
    description: 'Button to delete a notification',
    module: _module,
    screenKey: _screen,
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['notification', 'action', 'delete', 'button'],
    meta: {
      'group': 'notification_actions',
      'appModule': 'notification',
    },
  );

  static const List<EmmaUiAnchorSpec> values = [
    screenRoot,
    dismissArea,
    content,
    mobileRoot,
    mobileAppbar,
    mobileList,
    mobileFirstCard,
    mobileEmptyState,
    pcRoot,
    pcSidebar,
    pcPanel,
    pcList,
    pcFirstCard,
    pcLoadingState,
    pcEmptyState,
    markAsReadAction,
    deleteAction,
  ];
}