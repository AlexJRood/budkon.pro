import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

enum ContactPanelSection {
  dashboard,
  settlements,
  comments,
  transactions,
  docs,
  editContact,
  mail,
  savedSearches,
  invoices,
  tasks,
  calendar,
  unknown;

  static ContactPanelSection fromRoute(String route) => switch (route) {
    'dashboard'    => dashboard,
    'settlements'  => settlements,
    'komentarze'   => comments,
    'transakcje'   => transactions,
    'docs'         => docs,
    'edit-contact' => editContact,
    'mail'         => mail,
    'wyszukiwania' => savedSearches,
    'invoices'     => invoices,
    'tasks'        => tasks,
    'calendar'     => calendar,
    _              => unknown,
  };
}

enum ContactType {
  lead,
  client,
  owner,
  associationMember,
  company,
  crmUser,
}

String contactPanelModeForContactType(ContactType type) {
  switch (type) {
    case ContactType.crmUser:
      return 'crm-user';
    case ContactType.associationMember:
      return 'association-member';
    case ContactType.company:
      return 'company';
    case ContactType.owner:
      return 'owner';
    case ContactType.lead:
      return 'lead';
    case ContactType.client:
      return 'client';
  }
}

String contactPanelDashboardKeyForContactType(ContactType type) {
  switch (type) {
    case ContactType.crmUser:
      return 'crm_user_panel_dashboard';
    default:
      return 'client_panel_dashboard';
  }
}

String contactPanelBasePathForContactType({
  required ContactType type,
  required Object contactId,
}) {
  switch (type) {
    case ContactType.crmUser:
      return '/pro/crm-users/$contactId';
    case ContactType.associationMember:
      return '/pro/association-members/$contactId';
    case ContactType.company:
      return '/pro/companies/$contactId';
    case ContactType.owner:
      return '/pro/owners/$contactId';
    case ContactType.lead:
      return '/pro/leads/$contactId';
    case ContactType.client:
      return '/pro/clients/$contactId';
  }
}

class ContactMenuItem {
  final Widget icon;
  final String label;
  final String route;

  const ContactMenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

List<SidebarDockItemConfig> buildSidebarDockItemsForContactType({
  required ContactType type,
}) {
  final baseItems = <SidebarDockItemConfig>[
    SidebarDockItemConfig(
      id: 'contact-dashboard',
      label: 'Dashboard'.tr,
      iconKey: 'home',
      route: 'dashboard',
      order: 1,
    ),
    SidebarDockItemConfig(
      id: 'contact-docs',
      label: 'Docs'.tr,
      iconKey: 'folder',
      route: 'docs',
      order: 2,
    ),
  ];

  switch (type) {
    case ContactType.crmUser:
  return  [
    SidebarDockItemConfig(
      id: 'crm-user-dashboard',
      label: 'Dashboard'.tr,
      iconKey: 'home',
      route: 'dashboard',
      order: 1,
    ),
    SidebarDockItemConfig(
      id: 'crm-user-tasks',
      label: 'tasks_title'.tr,
      iconKey: 'viewList',
      route: 'tasks',
      order: 2,
    ),
    SidebarDockItemConfig(
      id: 'crm-user-calendar',
      label: 'calendar_title'.tr,
      iconKey: 'trend',
      route: 'calendar',
      order: 3,
    ),
    SidebarDockItemConfig(
      id: 'crm-user-settlements',
      label: 'Settlements'.tr,
      iconKey: 'dollar',
      route: 'settlements',
      order: 4,
    ),
    SidebarDockItemConfig(
      id: 'crm-user-docs',
      label: 'Docs'.tr,
      iconKey: 'folder',
      route: 'docs',
      order: 5,
    ),
    SidebarDockItemConfig(
      id: 'crm-user-comments',
      label: 'Comments'.tr,
      iconKey: 'message',
      route: 'komentarze',
      order: 6,
    ),
    SidebarDockItemConfig(
      id: 'crm-user-edit',
      label: 'Profile'.tr,
      iconKey: 'person',
      route: 'edit-contact',
      order: 7,
    ),
  ];

    case ContactType.client:
      return  [
        ...baseItems,
        SidebarDockItemConfig(
          id: 'contact-transactions',
          label: 'transactions_label'.tr,
          iconKey: 'pie',
          route: 'transakcje',
          order: 3,
        ),
        SidebarDockItemConfig(
          id: 'contact-searches',
          label: 'saved_searches_title'.tr,
          iconKey: 'search',
          route: 'wyszukiwania',
          order: 4,
        ),
        SidebarDockItemConfig(
          id: 'contact-invoices',
          label: 'Invoices'.tr,
          iconKey: 'dollar',
          route: 'invoices',
          order: 5,
        ),
        SidebarDockItemConfig(
          id: 'contact-comments',
          label: 'Comment'.tr,
          iconKey: 'message',
          route: 'komentarze',
          order: 6,
        ),
        SidebarDockItemConfig(
          id: 'contact-edit',
          label: 'edit_contact_label'.tr,
          iconKey: 'person',
          route: 'edit-contact',
          order: 7,
        ),
      ];

    case ContactType.associationMember:
      return  [
        SidebarDockItemConfig(
          id: 'association-dashboard',
          label: 'Dashboard'.tr,
          iconKey: 'home',
          route: 'dashboard',
          order: 1,
        ),
        SidebarDockItemConfig(
          id: 'association-invoices',
          label: 'Invoices'.tr,
          iconKey: 'dollar',
          route: 'invoices',
          order: 2,
        ),
        SidebarDockItemConfig(
          id: 'association-membership',
          label: 'Membership'.tr,
          iconKey: 'message',
          route: 'membership',
          order: 3,
        ),
        SidebarDockItemConfig(
          id: 'association-docs',
          label: 'Docs'.tr,
          iconKey: 'folder',
          route: 'docs',
          order: 4,
        ),
        SidebarDockItemConfig(
          id: 'association-comments',
          label: 'Comment'.tr,
          iconKey: 'message',
          route: 'komentarze',
          order: 5,
        ),
        SidebarDockItemConfig(
          id: 'association-notes',
          label: 'Notes'.tr,
          iconKey: 'message',
          route: 'notes',
          order: 6,
        ),
        SidebarDockItemConfig(
          id: 'association-edit',
          label: 'edit_contact_label'.tr,
          iconKey: 'person',
          route: 'edit-contact',
          order: 7,
        ),
      ];

    case ContactType.lead:
      return  [
        ...baseItems,
        SidebarDockItemConfig(
          id: 'lead-comments',
          label: 'Comment'.tr,
          iconKey: 'message',
          route: 'komentarze',
          order: 3,
        ),
        SidebarDockItemConfig(
          id: 'lead-edit',
          label: 'edit_contact_label'.tr,
          iconKey: 'person',
          route: 'edit-contact',
          order: 4,
        ),
      ];

    case ContactType.company:
      return  [
        ...baseItems,
        SidebarDockItemConfig(
          id: 'company-team',
          label: 'Team'.tr,
          iconKey: 'viewList',
          route: 'team',
          order: 3,
        ),
        SidebarDockItemConfig(
          id: 'company-relations',
          label: 'Relationships'.tr,
          iconKey: 'trend',
          route: 'relations',
          order: 4,
        ),
      ];

    case ContactType.owner:
      return  [
        ...baseItems,
        SidebarDockItemConfig(
          id: 'owner-notes',
          label: 'Note'.tr,
          iconKey: 'message',
          route: 'notes',
          order: 3,
        ),
        SidebarDockItemConfig(
          id: 'owner-properties',
          label: 'real_estate_label'.tr,
          iconKey: 'trend',
          route: 'properties',
          order: 4,
        ),
      ];
  }
}

SidebarDockConfig buildClientAgentCrmSidebarDockConfig({
  required ContactType type,
}) {
  return SidebarDockConfig(
    module: AppModule.agentCrm,
    enabled: true,
    side: SidebarDockSide.left,
    ui: const SidebarDockUiConfig(
      railWidth: 60,
      expandedWidth: 186,
      stretchHeight: 128,
      enableMagnify: true,
      enablePieMenu: false,
      enableTooltips: false,
      blurBackground: true,
      showLegacyTopButtons: false,
      showLegacyBottomButtons: false,
    ),
    sections: [
      SidebarDockSectionConfig(
        id: 'client-panel-center',
        position: SidebarDockSectionPosition.center,
        items: buildSidebarDockItemsForContactType(type: type),
      ),
       SidebarDockSectionConfig(
        id: 'client-panel-bottom',
        position: SidebarDockSectionPosition.bottom,
        items: [
          SidebarDockItemConfig(
            id: 'client-panel-mail',
            label: 'label_mail'.tr,
            iconKey: 'mail',
            route: 'mail',
            order: 1,
          ),
          SidebarDockItemConfig(
            id: 'client-panel-chat',
            label: 'chat'.tr,
            iconKey: 'chat',
            route: '__chat__',
            order: 2,
          ),
        ],
      ),
    ],
  );
}

List<ContactMenuItem> _mapDockItemsToMenuItems({
  required List<SidebarDockItemConfig> items,
  required ThemeColors theme,
  required String currentRoute,
}) {
  final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));

  return sorted.map((item) {
    final isActive = item.route == currentRoute;

    return ContactMenuItem(
      icon: resolveSidebarDockIcon(
        iconKey: item.iconKey,
        color: isActive ? AppColors.white : theme.textColor,
      ),
      label: item.label.tr,
      route: item.route ?? '',
    );
  }).toList();
}

List<ContactMenuItem> buildMenuItemsForContactType({
  required ContactType type,
  required ThemeColors theme,
  required String currentRoute,
}) {
  final config = buildClientAgentCrmSidebarDockConfig(type: type);
  final centerItems =
      config.section(SidebarDockSectionPosition.center)?.items ?? const [];

  return _mapDockItemsToMenuItems(
    items: centerItems,
    theme: theme,
    currentRoute: currentRoute,
  );
}

List<ContactMenuItem> buildBottomBarMainMenuItemsForContactType({
  required ContactType type,
  required ThemeColors theme,
  required String currentRoute,
  int maxVisible = 4,
}) {
  final config = buildClientAgentCrmSidebarDockConfig(type: type);
  final centerItems =
      config.section(SidebarDockSectionPosition.center)?.items ?? const [];

  final visible = centerItems.take(maxVisible).toList();

  return _mapDockItemsToMenuItems(
    items: visible,
    theme: theme,
    currentRoute: currentRoute,
  );
}

List<ContactMenuItem> buildBottomBarMoreMenuItemsForContactType({
  required ContactType type,
  required ThemeColors theme,
  required String currentRoute,
  int maxVisible = 4,
}) {
  final config = buildClientAgentCrmSidebarDockConfig(type: type);

  final centerItems =
      config.section(SidebarDockSectionPosition.center)?.items ?? const [];
  final bottomItems =
      config.section(SidebarDockSectionPosition.bottom)?.items ?? const [];

  final overflowItems = <SidebarDockItemConfig>[
    ...centerItems.skip(maxVisible),
    ...bottomItems,
  ];

  return _mapDockItemsToMenuItems(
    items: overflowItems,
    theme: theme,
    currentRoute: currentRoute,
  );
}