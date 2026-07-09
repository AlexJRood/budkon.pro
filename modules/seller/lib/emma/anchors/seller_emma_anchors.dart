import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class SellerEmmaAnchors {
  static const String _module = 'seller';
  static const String _profileRoute = '/pro/seller/profile';

  static const EmmaUiAnchorSpec sellerProfilePage = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.page',
    frontendRef: 'SellerEmmaAnchors.sellerProfilePage',
    label: 'Seller Profile Page',
    description: 'Main seller profile page displaying seller information and their property listings',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'page', 'onboarding'],
    meta: {
      'group': 'layout',
      'appModule': 'seller',
    },
    onboardingOrder: 1,
    onboardingMessage: 'This is the seller profile page where you can view seller information and their properties',
  );

  static const EmmaUiAnchorSpec sellerProfileHeader = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.header',
    frontendRef: 'SellerEmmaAnchors.sellerProfileHeader',
    label: 'Seller Profile Header',
    description: 'Header section with background image and seller avatar',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'header', 'background', 'avatar'],
    meta: {
      'group': 'profile_header',
      'appModule': 'seller',
    },
    onboardingOrder: 2,
    onboardingMessage: 'This header shows the seller\'s profile picture and cover image',
  );

  static const EmmaUiAnchorSpec sellerAvatar = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.avatar',
    frontendRef: 'SellerEmmaAnchors.sellerAvatar',
    label: 'Seller Avatar',
    description: 'Profile picture of the seller',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'avatar', 'image'],
    meta: {
      'group': 'profile_header',
      'appModule': 'seller',
    },
    onboardingOrder: 3,
    onboardingMessage: 'This is the seller\'s profile picture',
  );

  static const EmmaUiAnchorSpec sellerFullName = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.full_name',
    frontendRef: 'SellerEmmaAnchors.sellerFullName',
    label: 'Seller Full Name',
    description: 'Display name of the seller',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'name', 'information'],
    meta: {
      'group': 'seller_info',
      'appModule': 'seller',
    },
    onboardingOrder: 4,
    onboardingMessage: 'This is the seller\'s full name',
  );

  static const EmmaUiAnchorSpec sellerEmail = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.email',
    frontendRef: 'SellerEmmaAnchors.sellerEmail',
    label: 'Seller Email',
    description: 'Email address of the seller for contact',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'email', 'contact'],
    meta: {
      'group': 'seller_info',
      'appModule': 'seller',
    },
    onboardingOrder: 5,
    onboardingMessage: 'Contact the seller via this email address',
  );

  static const EmmaUiAnchorSpec sellerPhoneNumber = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.phone',
    frontendRef: 'SellerEmmaAnchors.sellerPhoneNumber',
    label: 'Seller Phone Number',
    description: 'Phone number of the seller for direct contact',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'phone', 'contact'],
    meta: {
      'group': 'seller_info',
      'appModule': 'seller',
    },
    onboardingOrder: 6,
    onboardingMessage: 'Call or text the seller directly',
  );

  static const EmmaUiAnchorSpec propertiesInfoBox = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.properties_info',
    frontendRef: 'SellerEmmaAnchors.propertiesInfoBox',
    label: 'Properties Info Box',
    description: 'Information box showing number of properties listed by seller',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'properties', 'stats'],
    meta: {
      'group': 'seller_stats',
      'appModule': 'seller',
    },
    onboardingOrder: 7,
    onboardingMessage: 'This shows how many properties this seller has listed',
  );

  static const EmmaUiAnchorSpec memberSinceDate = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.member_since',
    frontendRef: 'SellerEmmaAnchors.memberSinceDate',
    label: 'Member Since Date',
    description: 'Date when the seller joined the platform',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'profile', 'member_since', 'date'],
    meta: {
      'group': 'seller_info',
      'appModule': 'seller',
    },
    onboardingOrder: 8,
    onboardingMessage: 'The seller has been a member since this date',
  );

  static const EmmaUiAnchorSpec sellerTabsContainer = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.tabs_container',
    frontendRef: 'SellerEmmaAnchors.sellerTabsContainer',
    label: 'Seller Tabs Container',
    description: 'Tab navigation for filtering seller advertisements',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.nav,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'tabs', 'navigation', 'filter'],
    meta: {
      'group': 'navigation',
      'appModule': 'seller',
    },
    onboardingOrder: 9,
    onboardingMessage: 'Use these tabs to filter the seller\'s advertisements',
  );

  static const EmmaUiAnchorSpec allAdvertisementsTab = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.tab.all_advertisements',
    frontendRef: 'SellerEmmaAnchors.allAdvertisementsTab',
    label: 'All Advertisements Tab',
    description: 'Tab showing all advertisements from the seller',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.tab,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'tab', 'advertisements', 'all'],
    meta: {
      'group': 'tabs',
      'filterType': 'all',
      'appModule': 'seller',
    },
    onboardingOrder: 10,
    onboardingMessage: 'View all properties listed by this seller',
  );

  static const EmmaUiAnchorSpec advertisementsGrid = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisements_grid',
    frontendRef: 'SellerEmmaAnchors.advertisementsGrid',
    label: 'Advertisements Grid',
    description: 'Grid view of seller\'s property advertisements',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisements', 'grid', 'properties'],
    meta: {
      'group': 'content',
      'appModule': 'seller',
    },
    onboardingOrder: 11,
    onboardingMessage: 'This grid shows all properties from this seller',
  );

  static const EmmaUiAnchorSpec advertisementCard = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card', 
    frontendRef: 'SellerEmmaAnchors.advertisementCard',
    label: 'Advertisement Card',
    description: 'Individual property card with image, title, and price',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'card', 'property'],
    meta: {
      'group': 'advertisements',
      'appModule': 'seller',
    },
    onboardingOrder: 12,
    onboardingMessage: 'Click to view property details',
  );

  static const EmmaUiAnchorSpec advertisementCardImage = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.image',
    frontendRef: 'SellerEmmaAnchors.advertisementCardImage',
    label: 'Advertisement Card Image',
    description: 'Main image of the property advertisement',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'image', 'property'],
    meta: {
      'group': 'advertisement_content',
      'appModule': 'seller',
    },
  );

  static const EmmaUiAnchorSpec proBadge = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.pro_badge',
    frontendRef: 'SellerEmmaAnchors.proBadge',
    label: 'Pro Badge',
    description: 'Badge indicating premium/verified advertisement',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'pro', 'badge', 'premium'],
    meta: {
      'group': 'advertisement_badges',
      'appModule': 'seller',
    },
  );


  static const EmmaUiAnchorSpec advertisementCardTitle = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.title',
    frontendRef: 'SellerEmmaAnchors.advertisementCardTitle',
    label: 'Advertisement Card Title',
    description: 'Title of the property advertisement',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'title', 'property'],
    meta: {
      'group': 'advertisement_content',
      'appModule': 'seller',
    },
  );

  static const EmmaUiAnchorSpec advertisementCardPrice = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.price',
    frontendRef: 'SellerEmmaAnchors.advertisementCardPrice',
    label: 'Advertisement Card Price',
    description: 'Price of the property',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'price', 'property'],
    meta: {
      'group': 'advertisement_content',
      'appModule': 'seller',
    },
  );

  static const EmmaUiAnchorSpec advertisementCardLocation = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.location',
    frontendRef: 'SellerEmmaAnchors.advertisementCardLocation',
    label: 'Advertisement Card Location',
    description: 'Location of the property',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'location', 'property'],
    meta: {
      'group': 'advertisement_content',
      'appModule': 'seller',
    },
  );

  static const EmmaUiAnchorSpec favoriteButton = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.favorite_button',
    frontendRef: 'SellerEmmaAnchors.favoriteButton',
    label: 'Favorite Button',
    description: 'Button to save advertisement to favorites',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'favorite', 'like', 'button'],
    meta: {
      'group': 'card_actions',
      'action': 'favorite',
      'appModule': 'seller',
    },
    onboardingOrder: 13,
    onboardingMessage: 'Save this property to your favorites',
  );

  static const EmmaUiAnchorSpec addToWatchlistButton = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.watchlist_button',
    frontendRef: 'SellerEmmaAnchors.addToWatchlistButton',
    label: 'Add to Watchlist Button',
    description: 'Button to add advertisement to browsing list',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'watchlist', 'button'],
    meta: {
      'group': 'card_actions',
      'action': 'watchlist',
      'appModule': 'seller',
    },
    onboardingOrder: 14,
    onboardingMessage: 'Add this property to your watchlist',
  );

  static const EmmaUiAnchorSpec hideAdvertisementButton = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.hide_button',
    frontendRef: 'SellerEmmaAnchors.hideAdvertisementButton',
    label: 'Hide Advertisement Button',
    description: 'Button to hide advertisement from view',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'hide', 'button'],
    meta: {
      'group': 'card_actions',
      'action': 'hide',
      'appModule': 'seller',
    },
    onboardingOrder: 15,
    onboardingMessage: 'Hide this advertisement if you\'re not interested',
  );

  static const EmmaUiAnchorSpec shareAdvertisementButton = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.advertisement_card.share_button',
    frontendRef: 'SellerEmmaAnchors.shareAdvertisementButton',
    label: 'Share Advertisement Button',
    description: 'Button to share advertisement with others',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'advertisement', 'share', 'button'],
    meta: {
      'group': 'card_actions',
      'action': 'share',
      'appModule': 'seller',
    },
    onboardingOrder: 16,
    onboardingMessage: 'Share this property with friends or family',
  );

  static const EmmaUiAnchorSpec emptyStateContainer = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.empty_state',
    frontendRef: 'SellerEmmaAnchors.emptyStateContainer',
    label: 'Empty State Container',
    description: 'Message shown when seller has no advertisements',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['seller', 'empty', 'state', 'no_results'],
    meta: {
      'group': 'feedback',
      'appModule': 'seller',
    },
    onboardingOrder: 17,
    onboardingMessage: 'This seller doesn\'t have any properties listed yet',
  );

  static const EmmaUiAnchorSpec sellerProfileFooter = EmmaUiAnchorSpec(
    anchorKey: 'seller.profile.footer',
    frontendRef: 'SellerEmmaAnchors.sellerProfileFooter',
    label: 'Seller Profile Footer',
    description: 'Footer section of the seller profile page',
    module: _module,
    screenKey: 'seller_profile',
    routePattern: _profileRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['seller', 'footer', 'layout'],
    meta: {
      'group': 'layout',
      'appModule': 'seller',
    },
  );

  static const List<EmmaUiAnchorSpec> values = [
    sellerProfilePage,
    sellerProfileHeader,
    sellerAvatar,
    sellerFullName,
    sellerEmail,
    sellerPhoneNumber,
    propertiesInfoBox,
    memberSinceDate,
    sellerTabsContainer,
    allAdvertisementsTab,
    advertisementsGrid,
    advertisementCard,
    advertisementCardImage,
    proBadge,
    advertisementCardTitle,
    advertisementCardPrice,
    advertisementCardLocation,
    favoriteButton,
    addToWatchlistButton,
    hideAdvertisementButton,
    shareAdvertisementButton,
    emptyStateContainer,
    sellerProfileFooter,
  ];
}