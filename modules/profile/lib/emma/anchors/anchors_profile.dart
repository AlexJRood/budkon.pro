import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class ProfileEmmaAnchors {
  static const String _module = 'profile';
  static const String _route = '/profile/:userId';

  static const EmmaUiAnchorSpec screenRoot = EmmaUiAnchorSpec(
    anchorKey: 'profile.screen.root',
    frontendRef: 'ProfileEmmaAnchors.screenRoot',
    label: 'Profile screen',
    description:
        'Main profile screen wrapper used to display the user profile in desktop or mobile layout.',
    module: _module,
    screenKey: 'profile_screen',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'screen', 'layout', 'onboarding'],
    meta: {
      'group': 'layout',
    },
    onboardingOrder: 1,
    onboardingMessage: 'This is the main profile screen.',
  );

  static const EmmaUiAnchorSpec mobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.root',
    frontendRef: 'ProfileEmmaAnchors.mobileRoot',
    label: 'Mobile profile layout',
    description:
        'Mobile layout of the user profile screen.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'mobile', 'layout'],
    meta: {
      'platform': 'mobile',
      'group': 'layout',
    },
  );

  static const EmmaUiAnchorSpec mobileHeader = EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.header',
    frontendRef: 'ProfileEmmaAnchors.mobileHeader',
    label: 'Mobile profile header',
    description:
        'Header section of the mobile profile with background image and avatar.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'mobile', 'header', 'cover', 'avatar'],
    meta: {
      'platform': 'mobile',
      'group': 'header',
    },
    onboardingOrder: 2,
    onboardingMessage:
        'This header shows the profile cover image and avatar.',
  );

  static const EmmaUiAnchorSpec mobileBackgroundUploadButton =
      EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.header.background_upload_button',
    frontendRef: 'ProfileEmmaAnchors.mobileBackgroundUploadButton',
    label: 'Mobile background upload button',
    description:
        'Button used by the current user to upload or change the profile background image on mobile.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'mobile', 'background', 'upload', 'edit'],
    meta: {
      'platform': 'mobile',
      'group': 'header_actions',
      'requiresCurrentUser': true,
    },
  );

  static const EmmaUiAnchorSpec mobileAvatar = EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.header.avatar',
    frontendRef: 'ProfileEmmaAnchors.mobileAvatar',
    label: 'Mobile profile avatar',
    description:
        'Profile avatar displayed in the mobile profile header.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['profile', 'mobile', 'avatar', 'identity'],
    meta: {
      'platform': 'mobile',
      'group': 'header',
    },
  );

  static const EmmaUiAnchorSpec mobileBasicInfo = EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.basic_info',
    frontendRef: 'ProfileEmmaAnchors.mobileBasicInfo',
    label: 'Mobile profile basic info',
    description:
        'Basic profile information section with full name and email on mobile.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['profile', 'mobile', 'basic_info', 'identity'],
    meta: {
      'platform': 'mobile',
      'group': 'identity',
    },
  );

  static const EmmaUiAnchorSpec mobileCompanyCard = EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.company_card',
    frontendRef: 'ProfileEmmaAnchors.mobileCompanyCard',
    label: 'Mobile company card',
    description:
        'Company information card displayed on the mobile profile.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'mobile', 'company', 'card'],
    meta: {
      'platform': 'mobile',
      'group': 'identity',
    },
  );

  static const EmmaUiAnchorSpec mobileEditProfileButton = EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.edit_profile_button',
    frontendRef: 'ProfileEmmaAnchors.mobileEditProfileButton',
    label: 'Mobile edit profile button',
    description:
        'Button used to edit profile information on mobile.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'mobile', 'edit', 'button', 'cta'],
    meta: {
      'platform': 'mobile',
      'group': 'actions',
      'requiresCurrentUser': true,
    },
  );

  static const EmmaUiAnchorSpec desktopRoot = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.root',
    frontendRef: 'ProfileEmmaAnchors.desktopRoot',
    label: 'Desktop profile layout',
    description:
        'Desktop layout of the user profile screen.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'desktop', 'layout'],
    meta: {
      'platform': 'desktop',
      'group': 'layout',
    },
  );

  static const EmmaUiAnchorSpec desktopHeader = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.header',
    frontendRef: 'ProfileEmmaAnchors.desktopHeader',
    label: 'Desktop profile header',
    description:
        'Header section of the desktop profile with cover image, avatar and association summary.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'desktop', 'header', 'cover', 'avatar'],
    meta: {
      'platform': 'desktop',
      'group': 'header',
    },
    onboardingOrder: 2,
    onboardingMessage:
        'This header shows the profile cover image and main identity summary.',
  );

  static const EmmaUiAnchorSpec desktopBackgroundUploadButton =
      EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.header.background_upload_button',
    frontendRef: 'ProfileEmmaAnchors.desktopBackgroundUploadButton',
    label: 'Desktop background upload button',
    description:
        'Button used by the current user to upload or change the profile background image on desktop.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'desktop', 'background', 'upload', 'edit'],
    meta: {
      'platform': 'desktop',
      'group': 'header_actions',
      'requiresCurrentUser': true,
    },
  );

  static const EmmaUiAnchorSpec desktopAvatar = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.header.avatar',
    frontendRef: 'ProfileEmmaAnchors.desktopAvatar',
    label: 'Desktop profile avatar',
    description:
        'Profile avatar displayed in the desktop profile header.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['profile', 'desktop', 'avatar', 'identity'],
    meta: {
      'platform': 'desktop',
      'group': 'header',
    },
  );

  static const EmmaUiAnchorSpec desktopAssociationCard = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.header.association_card',
    frontendRef: 'ProfileEmmaAnchors.desktopAssociationCard',
    label: 'Desktop association card',
    description:
        'Association summary card displayed near the desktop profile header.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['profile', 'desktop', 'association', 'card'],
    meta: {
      'platform': 'desktop',
      'group': 'header',
    },
  );

  static const EmmaUiAnchorSpec desktopLeftPanel = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.left_panel',
    frontendRef: 'ProfileEmmaAnchors.desktopLeftPanel',
    label: 'Desktop left profile panel',
    description:
        'Left side desktop profile panel with identity, company card and edit action.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'desktop', 'left_panel', 'identity'],
    meta: {
      'platform': 'desktop',
      'group': 'identity',
    },
  );

  static const EmmaUiAnchorSpec desktopBasicInfo = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.basic_info',
    frontendRef: 'ProfileEmmaAnchors.desktopBasicInfo',
    label: 'Desktop profile basic info',
    description:
        'Basic profile information section with full name, email and member since date on desktop.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['profile', 'desktop', 'basic_info', 'identity'],
    meta: {
      'platform': 'desktop',
      'group': 'identity',
    },
  );

  static const EmmaUiAnchorSpec desktopCompanyCard = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.company_card',
    frontendRef: 'ProfileEmmaAnchors.desktopCompanyCard',
    label: 'Desktop company card',
    description:
        'Company information card displayed in the desktop profile left panel.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'desktop', 'company', 'card'],
    meta: {
      'platform': 'desktop',
      'group': 'identity',
    },
  );

  static const EmmaUiAnchorSpec desktopEditProfileButton = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.edit_profile_button',
    frontendRef: 'ProfileEmmaAnchors.desktopEditProfileButton',
    label: 'Desktop edit profile button',
    description:
        'Button used to navigate to profile settings or edit profile information on desktop.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'desktop', 'edit', 'button', 'cta'],
    meta: {
      'platform': 'desktop',
      'group': 'actions',
      'requiresCurrentUser': true,
    },
  );

  static const EmmaUiAnchorSpec mobileTabs = EmmaUiAnchorSpec(
    anchorKey: 'profile.mobile.tabs',
    frontendRef: 'ProfileEmmaAnchors.mobileTabs',
    label: 'Mobile profile tabs',
    description:
        'Tab navigation for switching profile content sections on mobile.',
    module: _module,
    screenKey: 'mobile_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.tab,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'mobile', 'tabs', 'navigation'],
    meta: {
      'platform': 'mobile',
      'group': 'navigation',
    },
    onboardingOrder: 3,
    onboardingMessage:
        'Use these tabs to switch between profile content sections.',
  );

  static const EmmaUiAnchorSpec desktopTabs = EmmaUiAnchorSpec(
    anchorKey: 'profile.desktop.tabs',
    frontendRef: 'ProfileEmmaAnchors.desktopTabs',
    label: 'Desktop profile tabs',
    description:
        'Tab navigation for switching profile content sections on desktop.',
    module: _module,
    screenKey: 'desktop_profile',
    routePattern: _route,
    targetKind: EmmaUiAnchorTargetKind.tab,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['profile', 'desktop', 'tabs', 'navigation'],
    meta: {
      'platform': 'desktop',
      'group': 'navigation',
    },
    onboardingOrder: 3,
    onboardingMessage:
        'Use these tabs to switch between profile content sections.',
  );

  static EmmaUiAnchorSpec tabItem({
    required String platform,
    required String tabId,
    required String label,
  }) {
    final screenKey = platform == 'mobile' ? 'mobile_profile' : 'desktop_profile';

    return EmmaUiAnchorSpec(
      anchorKey: 'profile.$platform.tabs.$tabId',
      frontendRef:
          "ProfileEmmaAnchors.tabItem(platform: '$platform', tabId: '$tabId')",
      label: '$label tab',
      description:
          'Profile tab used to open the $label section on $platform.',
      module: _module,
      screenKey: screenKey,
      routePattern: _route,
      targetKind: EmmaUiAnchorTargetKind.tab,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      usageMode: EmmaUiAnchorUsageMode.both,
      tags: ['profile', platform, 'tab', tabId, 'navigation'],
      meta: {
        'platform': platform,
        'group': 'navigation',
        'tabId': tabId,
      },
    );
  }
}