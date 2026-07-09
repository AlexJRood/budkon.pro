import 'package:core/ui/anchors/anchor_spec.dart';

class EmmaAnchors {


static const mailViewRoot = EmmaUiAnchorSpec(
  anchorKey: 'mail.view.root',
  frontendRef: 'EmmaAnchors.mailViewRoot',
  label: 'Mail view',
  description: 'Main mail module view with desktop and mobile layouts.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'email', 'root'],
);

static const mailPcSidebar = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.sidebar',
  frontendRef: 'EmmaAnchors.mailPcSidebar',
  label: 'Mail sidebar',
  description: 'Desktop mail sidebar with account switcher, filters, tabs, tags and compose button.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.sidebar,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'sidebar', 'filters'],
);

static const mailPcAccountSwitcher = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.account_switcher',
  frontendRef: 'EmmaAnchors.mailPcAccountSwitcher',
  label: 'Email account switcher',
  description: 'Control used to view or switch the active email account.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'account', 'switcher'],
);

static const mailPcFiltersPanel = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filters_panel',
  frontendRef: 'EmmaAnchors.mailPcFiltersPanel',
  label: 'Mail filters panel',
  description: 'Desktop filter panel for mail type, sorting and taxonomy filters.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filters', 'panel'],
);

static const mailPcSortDropdown = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.sort_dropdown',
  frontendRef: 'EmmaAnchors.mailPcSortDropdown',
  label: 'Mail sort dropdown',
  description: 'Dropdown for sorting emails by newest or oldest.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.input,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'sort', 'dropdown'],
);

static const mailPcFilterAll = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filter.all',
  frontendRef: 'EmmaAnchors.mailPcFilterAll',
  label: 'All emails filter',
  description: 'Filter showing all emails.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filter', 'all'],
);

static const mailPcFilterInbox = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filter.inbox',
  frontendRef: 'EmmaAnchors.mailPcFilterInbox',
  label: 'Inbox filter',
  description: 'Filter showing received emails.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filter', 'inbox', 'received'],
);

static const mailPcFilterSent = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filter.sent',
  frontendRef: 'EmmaAnchors.mailPcFilterSent',
  label: 'Sent emails filter',
  description: 'Filter showing sent emails.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filter', 'sent'],
);

static const mailPcFilterEmma = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filter.emma',
  frontendRef: 'EmmaAnchors.mailPcFilterEmma',
  label: 'Emma emails filter',
  description: 'Filter showing emails related to Emma workflows.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filter', 'emma'],
);

static const mailPcFilterEmmaDirect = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filter.emma_direct',
  frontendRef: 'EmmaAnchors.mailPcFilterEmmaDirect',
  label: 'Emma Direct emails filter',
  description: 'Filter showing direct Emma email actions.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filter', 'emma', 'direct'],
);

static const mailPcFilterSpam = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filter.spam',
  frontendRef: 'EmmaAnchors.mailPcFilterSpam',
  label: 'Spam filter',
  description: 'Spam folder filter and drag-and-drop target.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filter', 'spam', 'drag_drop'],
  meta: {'supports_drop': true},
);

static const mailPcFilterScheduled = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.filter.scheduled',
  frontendRef: 'EmmaAnchors.mailPcFilterScheduled',
  label: 'Scheduled emails filter',
  description: 'Filter showing scheduled emails.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'filter', 'scheduled'],
);

static const mailPcTabsSection = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.tabs_section',
  frontendRef: 'EmmaAnchors.mailPcTabsSection',
  label: 'Email tabs section',
  description: 'Section for filtering emails by custom tabs.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'tabs', 'taxonomy'],
);

static const mailPcTagsSection = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.tags_section',
  frontendRef: 'EmmaAnchors.mailPcTagsSection',
  label: 'Email tags section',
  description: 'Section for filtering emails by custom tags.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'tags', 'taxonomy'],
);

static const mailPcComposeButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.compose_button',
  frontendRef: 'EmmaAnchors.mailPcComposeButton',
  label: 'New message button',
  description: 'Button opening the email composer overlay.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'new_message'],
  meta: {'opens': 'email_compose_overlay'},
);

static const mailPcList = EmmaUiAnchorSpec(
  anchorKey: 'mail.pc.list',
  frontendRef: 'EmmaAnchors.mailPcList',
  label: 'Email list',
  description: 'Main desktop email list with preview and bulk selection.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'list', 'preview', 'bulk_selection'],
);

static const mailMobileList = EmmaUiAnchorSpec(
  anchorKey: 'mail.mobile.list',
  frontendRef: 'EmmaAnchors.mailMobileList',
  label: 'Mobile email list',
  description: 'Main mobile email list with preview and bulk selection.',
  module: 'mail',
  screenKey: 'mail_view_mobile',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'mobile', 'list'],
);

static const mailVerticalBarRoot = EmmaUiAnchorSpec(
  anchorKey: 'mail.vertical_bar.root',
  frontendRef: 'EmmaAnchors.mailVerticalBarRoot',
  label: 'Mail vertical actions',
  description: 'Floating vertical action bar for sync, filters and compose on mail views.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.sidebar,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'vertical_bar', 'actions'],
);

static const mailVerticalBarRefreshButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.vertical_bar.refresh_button',
  frontendRef: 'EmmaAnchors.mailVerticalBarRefreshButton',
  label: 'Sync emails button',
  description: 'Button triggering manual email synchronization.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'sync', 'refresh'],
);

static const mailVerticalBarFilterButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.vertical_bar.filter_button',
  frontendRef: 'EmmaAnchors.mailVerticalBarFilterButton',
  label: 'Mobile mail filters button',
  description: 'Button opening mobile mail filters bottom sheet.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'mobile', 'filters'],
  meta: {'opens': 'mail_filter_sheet'},
);

static const mailVerticalBarComposeButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.vertical_bar.compose_button',
  frontendRef: 'EmmaAnchors.mailVerticalBarComposeButton',
  label: 'Mobile compose button',
  description: 'Button opening mobile email composer.',
  module: 'mail',
  screenKey: 'mail_view',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'mobile', 'compose'],
);

static const mailComposeOverlayRoot = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.overlay.root',
  frontendRef: 'EmmaAnchors.mailComposeOverlayRoot',
  label: 'Email composer',
  description: 'Email compose overlay used to create and send messages.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.overlay,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'overlay'],
);

static const mailComposeHeader = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.header',
  frontendRef: 'EmmaAnchors.mailComposeHeader',
  label: 'Composer header',
  description: 'Header of the email composer used to drag, collapse, expand or close the composer.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'header', 'drag'],
  meta: {'supports_drag': true},
);

static const mailComposeToSection = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.to_section',
  frontendRef: 'EmmaAnchors.mailComposeToSection',
  label: 'Recipient field',
  description: 'Recipient field in the email composer.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.input,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'recipient', 'to'],
);

static const mailComposeSubjectInput = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.subject_input',
  frontendRef: 'EmmaAnchors.mailComposeSubjectInput',
  label: 'Email subject input',
  description: 'Subject input in the email composer.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.input,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'subject'],
);

static const mailComposeBodyInput = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.body_input',
  frontendRef: 'EmmaAnchors.mailComposeBodyInput',
  label: 'Email body input',
  description: 'Main message body input in the email composer.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.input,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'body'],
);

static const mailComposeAttachmentsButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.attachments_button',
  frontendRef: 'EmmaAnchors.mailComposeAttachmentsButton',
  label: 'Add attachments button',
  description: 'Button for adding attachments to the email.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'attachments'],
);

static const mailComposeSenderDropdown = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.sender_dropdown',
  frontendRef: 'EmmaAnchors.mailComposeSenderDropdown',
  label: 'Sender account dropdown',
  description: 'Dropdown for selecting the sender email account.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.input,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'sender', 'account'],
);

static const mailComposeCancelButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.cancel_button',
  frontendRef: 'EmmaAnchors.mailComposeCancelButton',
  label: 'Cancel email button',
  description: 'Button closing the email composer without sending.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'cancel'],
);

static const mailComposeSendButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.send_button',
  frontendRef: 'EmmaAnchors.mailComposeSendButton',
  label: 'Send email button',
  description: 'Button sending the current email immediately.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'send'],
);

static const mailComposeSendMenuButton = EmmaUiAnchorSpec(
  anchorKey: 'mail.compose.send_menu_button',
  frontendRef: 'EmmaAnchors.mailComposeSendMenuButton',
  label: 'Send options button',
  description: 'Button opening send options, such as scheduled sending.',
  module: 'mail',
  screenKey: 'mail_compose_overlay',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['mail', 'compose', 'send', 'schedule'],
);




  static const all = <EmmaUiAnchorSpec>[


    mailViewRoot,
    mailPcSidebar,
    mailPcAccountSwitcher,
    mailPcFiltersPanel,
    mailPcSortDropdown,
    mailPcFilterAll,
    mailPcFilterInbox,
    mailPcFilterSent,
    mailPcFilterEmma,
    mailPcFilterEmmaDirect,
    mailPcFilterSpam,
    mailPcFilterScheduled,
    mailPcTabsSection,
    mailPcTagsSection,
    mailPcComposeButton,
    mailPcList,
    mailMobileList,
    mailVerticalBarRoot,
    mailVerticalBarRefreshButton,
    mailVerticalBarFilterButton,
    mailVerticalBarComposeButton,
    mailComposeOverlayRoot,
    mailComposeHeader,
    mailComposeToSection,
    mailComposeSubjectInput,
    mailComposeBodyInput,
    mailComposeAttachmentsButton,
    mailComposeSenderDropdown,
    mailComposeCancelButton,
    mailComposeSendButton,
    mailComposeSendMenuButton,


  ];

}