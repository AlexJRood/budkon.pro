import 'package:core/ui/anchors/anchor_spec.dart';

class CrmClientsEmmaAnchors {
  static const addClientButton = EmmaUiAnchorSpec(
    anchorKey: 'crm.clients.filterbar.add_client_button',
    label: 'Add client button',
    description:
        'Button for adding a new client. Opens a form to create a new CRM contact.',
    module: 'crm',
    screenKey: 'crm_clients',
    routePattern: '/pro/clients*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    aliases: ['dodaj klienta', 'nowy klient', 'add client', 'new client'],
    tags: ['crm', 'clients', 'filterbar', 'add', 'button'],
    meta: {'opens': 'add_client_form'},
  );

  static const appbarRoot = EmmaUiAnchorSpec(
    anchorKey: 'crm.clients.appbar.root',
    label: 'Clients app bar',
    description: 'Top app bar container for the CRM clients list view.',
    module: 'crm',
    screenKey: 'crm_clients',
    routePattern: '/pro/clients*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['crm', 'clients', 'appbar'],
  );

  static const appbarAddClientButton = EmmaUiAnchorSpec(
    anchorKey: 'crm.clients.appbar.add_client_button',
    label: 'Add client (app bar)',
    description: 'App bar button for adding a new client (mobile/compact view).',
    module: 'crm',
    screenKey: 'crm_clients',
    routePattern: '/pro/clients*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    aliases: ['dodaj klienta', 'nowy klient', 'add client', 'new client'],
    tags: ['crm', 'clients', 'appbar', 'add', 'button'],
    meta: {'opens': 'add_client_form'},
  );

  static const appbarSearch = EmmaUiAnchorSpec(
    anchorKey: 'crm.clients.appbar.search',
    label: 'Search clients (app bar)',
    description: 'App bar search button for filtering the clients list.',
    module: 'crm',
    screenKey: 'crm_clients',
    routePattern: '/pro/clients*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['crm', 'clients', 'appbar', 'search'],
  );

  static const appbarClientStrip = EmmaUiAnchorSpec(
    anchorKey: 'crm.clients.appbar.client_strip',
    label: 'Client strip',
    description: 'Horizontal strip of client avatars/chips in the app bar.',
    module: 'crm',
    screenKey: 'crm_clients',
    routePattern: '/pro/clients*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['crm', 'clients', 'appbar', 'strip'],
  );

  static const filterBar = EmmaUiAnchorSpec(
    anchorKey: 'crm.clients.filterbar',
    label: 'Clients filter bar',
    description: 'Filter and search bar for the CRM clients list.',
    module: 'crm',
    screenKey: 'crm_clients',
    routePattern: '/pro/clients*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['crm', 'clients', 'filterbar', 'search', 'filter'],
  );
}
