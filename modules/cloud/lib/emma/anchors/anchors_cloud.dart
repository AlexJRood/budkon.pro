import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class CloudEmmaAnchors {
  static const String _module = 'cloud';
  static const String _baseRoute = '/cloud-storage';

  static const EmmaUiAnchorSpec pageRoot = EmmaUiAnchorSpec(
    anchorKey: 'cloud.page.root',
    frontendRef: 'CloudEmmaAnchors.pageRoot',
    label: 'Cloud storage page',
    description:
        'Main cloud storage workspace with sidebar, upload actions and content area.',
    module: _module,
    screenKey: 'storage_page',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'storage', 'workspace', 'onboarding'],
    meta: {
      'group': 'layout',
      'appModule': 'agent_crm',
    },
    onboardingOrder: 1,
    onboardingMessage: 'This is the main cloud storage workspace.',
  );

  static const EmmaUiAnchorSpec uploadButtonMobile = EmmaUiAnchorSpec(
    anchorKey: 'cloud.page.quick_upload_button.mobile',
    frontendRef: 'CloudEmmaAnchors.uploadButtonMobile',
    label: 'Mobile quick upload button',
    description:
        'Quick upload button used to pick files for upload in cloud storage on mobile layouts.',
    module: _module,
    screenKey: 'storage_page',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'upload', 'button', 'mobile', 'cta'],
    meta: {
      'group': 'primary_actions',
      'platform': 'mobile',
    },
  );

  static const EmmaUiAnchorSpec uploadButtonDesktop = EmmaUiAnchorSpec(
    anchorKey: 'cloud.page.quick_upload_button.desktop',
    frontendRef: 'CloudEmmaAnchors.uploadButtonDesktop',
    label: 'Desktop quick upload button',
    description:
        'Quick upload button used to pick files for upload in cloud storage on desktop layouts.',
    module: _module,
    screenKey: 'storage_page',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'upload', 'button', 'desktop', 'cta'],
    meta: {
      'group': 'primary_actions',
      'platform': 'desktop',
    },
  );

  static const EmmaUiAnchorSpec sidebar = EmmaUiAnchorSpec(
    anchorKey: 'cloud.page.sidebar.main',
    frontendRef: 'CloudEmmaAnchors.sidebar',
    label: 'Cloud storage sidebar',
    description:
        'Primary sidebar for cloud storage navigation, filters and upgrade-related entry points.',
    module: _module,
    screenKey: 'storage_page',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'sidebar', 'navigation', 'filters', 'onboarding'],
    meta: {
      'group': 'main_navigation',
    },
    onboardingOrder: 2,
    onboardingMessage:
        'Use this sidebar to navigate cloud storage sections and filters.',
  );

  static const EmmaUiAnchorSpec contentView = EmmaUiAnchorSpec(
    anchorKey: 'cloud.page.content_view',
    frontendRef: 'CloudEmmaAnchors.contentView',
    label: 'Cloud storage content view',
    description:
        'Main content area of cloud storage showing either the home dashboard or the file explorer.',
    module: _module,
    screenKey: 'storage_page',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'content', 'workspace'],
    meta: {
      'group': 'main_content',
    },
  );

  static const EmmaUiAnchorSpec homeRoot = EmmaUiAnchorSpec(
    anchorKey: 'cloud.home.root',
    frontendRef: 'CloudEmmaAnchors.homeRoot',
    label: 'Cloud storage home',
    description:
        'Default cloud storage home dashboard with quota, folders and recent documents.',
    module: _module,
    screenKey: 'home',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'home', 'dashboard'],
    meta: {
      'group': 'dashboard',
    },
  );

  static const EmmaUiAnchorSpec homeHeader = EmmaUiAnchorSpec(
    anchorKey: 'cloud.home.header',
    frontendRef: 'CloudEmmaAnchors.homeHeader',
    label: 'Cloud storage home header',
    description:
        'Header section of the cloud storage home page with title and primary context.',
    module: _module,
    screenKey: 'home',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'home', 'header'],
    meta: {
      'group': 'dashboard',
    },
  );

  static const EmmaUiAnchorSpec storageQuota = EmmaUiAnchorSpec(
    anchorKey: 'cloud.home.storage_quota',
    frontendRef: 'CloudEmmaAnchors.storageQuota',
    label: 'Storage quota widget',
    description:
        'Widget showing current cloud storage usage and quota information.',
    module: _module,
    screenKey: 'home',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'quota', 'usage', 'storage'],
    meta: {
      'group': 'dashboard_metrics',
    },
  );

  static const EmmaUiAnchorSpec foldersSection = EmmaUiAnchorSpec(
    anchorKey: 'cloud.home.folders_section',
    frontendRef: 'CloudEmmaAnchors.foldersSection',
    label: 'Folders section',
    description:
        'Section displaying cloud folders and shortcuts to important directories.',
    module: _module,
    screenKey: 'home',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'folders', 'navigation', 'content'],
    meta: {
      'group': 'home_sections',
    },
  );

  static const EmmaUiAnchorSpec recentDocumentsSection = EmmaUiAnchorSpec(
    anchorKey: 'cloud.home.recent_documents_section',
    frontendRef: 'CloudEmmaAnchors.recentDocumentsSection',
    label: 'Recent documents section',
    description:
        'Section showing recently added or recently accessed documents in cloud storage.',
    module: _module,
    screenKey: 'home',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'recent', 'documents', 'history'],
    meta: {
      'group': 'home_sections',
    },
  );

  static const EmmaUiAnchorSpec recentDocumentsTable = EmmaUiAnchorSpec(
    anchorKey: 'cloud.home.recent_documents_table',
    frontendRef: 'CloudEmmaAnchors.recentDocumentsTable',
    label: 'Recent documents table',
    description:
        'Table widget listing recent documents in cloud storage.',
    module: _module,
    screenKey: 'home',
    routePattern: _baseRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'recent', 'documents', 'table'],
    meta: {
      'group': 'home_sections',
    },
  );

  static const EmmaUiAnchorSpec explorerRoot = EmmaUiAnchorSpec(
    anchorKey: 'cloud.explorer.root',
    frontendRef: 'CloudEmmaAnchors.explorerRoot',
    label: 'Cloud explorer',
    description:
        'Main cloud explorer view used to browse folders and files.',
    module: _module,
    screenKey: 'explorer',
    routePattern: '$_baseRoute/explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'explorer', 'files', 'folders'],
    meta: {
      'group': 'explorer',
      'mode': 'standard',
    },
    onboardingOrder: 3,
    onboardingMessage: 'This is the main file explorer area.',
  );

  static const EmmaUiAnchorSpec clientExplorerRoot = EmmaUiAnchorSpec(
    anchorKey: 'cloud.client_explorer.root',
    frontendRef: 'CloudEmmaAnchors.clientExplorerRoot',
    label: 'Client cloud explorer',
    description:
        'Client-scoped cloud explorer used to browse files tied to a specific client context.',
    module: _module,
    screenKey: 'client_explorer',
    routePattern: '$_baseRoute/client-explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'client', 'explorer', 'files'],
    meta: {
      'group': 'explorer',
      'mode': 'client',
    },
  );

  static const EmmaUiAnchorSpec explorerDropZone = EmmaUiAnchorSpec(
    anchorKey: 'cloud.explorer.drop_zone',
    frontendRef: 'CloudEmmaAnchors.explorerDropZone',
    label: 'Explorer upload drop zone',
    description:
        'File drop zone covering the explorer area for drag and drop uploads.',
    module: _module,
    screenKey: 'explorer',
    routePattern: '$_baseRoute/explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'explorer', 'dropzone', 'upload', 'drag_and_drop'],
    meta: {
      'group': 'upload',
      'mode': 'standard',
    },
  );

  static const EmmaUiAnchorSpec clientExplorerDropZone = EmmaUiAnchorSpec(
    anchorKey: 'cloud.client_explorer.drop_zone',
    frontendRef: 'CloudEmmaAnchors.clientExplorerDropZone',
    label: 'Client explorer upload drop zone',
    description:
        'File drop zone covering the client explorer area for drag and drop uploads.',
    module: _module,
    screenKey: 'client_explorer',
    routePattern: '$_baseRoute/client-explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'client', 'explorer', 'dropzone', 'upload'],
    meta: {
      'group': 'upload',
      'mode': 'client',
    },
  );

  static const EmmaUiAnchorSpec explorerBreadcrumbs = EmmaUiAnchorSpec(
    anchorKey: 'cloud.explorer.breadcrumbs',
    frontendRef: 'CloudEmmaAnchors.explorerBreadcrumbs',
    label: 'Explorer breadcrumbs',
    description:
        'Breadcrumb navigation showing the current folder path in the cloud explorer.',
    module: _module,
    screenKey: 'explorer',
    routePattern: '$_baseRoute/explorer',
    targetKind: EmmaUiAnchorTargetKind.nav,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'explorer', 'breadcrumbs', 'navigation'],
    meta: {
      'group': 'navigation',
      'mode': 'standard',
    },
  );

  static const EmmaUiAnchorSpec clientExplorerBreadcrumbs = EmmaUiAnchorSpec(
    anchorKey: 'cloud.client_explorer.breadcrumbs',
    frontendRef: 'CloudEmmaAnchors.clientExplorerBreadcrumbs',
    label: 'Client explorer breadcrumbs',
    description:
        'Breadcrumb navigation showing the current folder path in the client cloud explorer.',
    module: _module,
    screenKey: 'client_explorer',
    routePattern: '$_baseRoute/client-explorer',
    targetKind: EmmaUiAnchorTargetKind.nav,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'client', 'breadcrumbs', 'navigation'],
    meta: {
      'group': 'navigation',
      'mode': 'client',
    },
  );

  static const EmmaUiAnchorSpec explorerEmptyState = EmmaUiAnchorSpec(
    anchorKey: 'cloud.explorer.empty_state',
    frontendRef: 'CloudEmmaAnchors.explorerEmptyState',
    label: 'Explorer empty state',
    description:
        'Empty state shown when the explorer has no folders or files to display.',
    module: _module,
    screenKey: 'explorer',
    routePattern: '$_baseRoute/explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'explorer', 'empty_state', 'onboarding'],
    meta: {
      'group': 'empty_state',
      'mode': 'standard',
    },
  );

  static const EmmaUiAnchorSpec clientExplorerEmptyState = EmmaUiAnchorSpec(
    anchorKey: 'cloud.client_explorer.empty_state',
    frontendRef: 'CloudEmmaAnchors.clientExplorerEmptyState',
    label: 'Client explorer empty state',
    description:
        'Empty state shown when the client cloud explorer has no folders or files to display.',
    module: _module,
    screenKey: 'client_explorer',
    routePattern: '$_baseRoute/client-explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'client', 'explorer', 'empty_state'],
    meta: {
      'group': 'empty_state',
      'mode': 'client',
    },
  );

  static const EmmaUiAnchorSpec explorerAddFolderCard = EmmaUiAnchorSpec(
    anchorKey: 'cloud.explorer.empty_state.add_folder_card',
    frontendRef: 'CloudEmmaAnchors.explorerAddFolderCard',
    label: 'Add folder card',
    description:
        'Primary card action used to create a folder from the explorer empty state.',
    module: _module,
    screenKey: 'explorer',
    routePattern: '$_baseRoute/explorer',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['cloud', 'explorer', 'folder', 'create', 'cta'],
    meta: {
      'group': 'empty_state_actions',
      'mode': 'standard',
    },
  );

  static const EmmaUiAnchorSpec clientExplorerAddFolderCard = EmmaUiAnchorSpec(
    anchorKey: 'cloud.client_explorer.empty_state.add_folder_card',
    frontendRef: 'CloudEmmaAnchors.clientExplorerAddFolderCard',
    label: 'Client add folder card',
    description:
        'Primary card action used to create a folder from the client explorer empty state.',
    module: _module,
    screenKey: 'client_explorer',
    routePattern: '$_baseRoute/client-explorer',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['cloud', 'client', 'explorer', 'folder', 'create'],
    meta: {
      'group': 'empty_state_actions',
      'mode': 'client',
    },
  );

  static const EmmaUiAnchorSpec explorerContent = EmmaUiAnchorSpec(
    anchorKey: 'cloud.explorer.content',
    frontendRef: 'CloudEmmaAnchors.explorerContent',
    label: 'Explorer content',
    description:
        'Main explorer content with folder and file results.',
    module: _module,
    screenKey: 'explorer',
    routePattern: '$_baseRoute/explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    keyboardShortcuts: {
      'Esc': 'Exit selection mode',
    },
    tags: ['cloud', 'explorer', 'content', 'files', 'folders'],
    meta: {
      'group': 'results',
      'mode': 'standard',
    },
  );

  static const EmmaUiAnchorSpec clientExplorerContent = EmmaUiAnchorSpec(
    anchorKey: 'cloud.client_explorer.content',
    frontendRef: 'CloudEmmaAnchors.clientExplorerContent',
    label: 'Client explorer content',
    description:
        'Main client explorer content with folder and file results.',
    module: _module,
    screenKey: 'client_explorer',
    routePattern: '$_baseRoute/client-explorer',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    keyboardShortcuts: {
      'Esc': 'Exit selection mode',
    },
    tags: ['cloud', 'client', 'explorer', 'content'],
    meta: {
      'group': 'results',
      'mode': 'client',
    },
  );
}