import 'package:core/ui/anchors/anchor_spec.dart';

class EmmaAnchors {
  static const tmsTodoPageRoot = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.page.root',
    frontendRef: 'EmmaAnchors.tmsTodoPageRoot',
    label: 'TMS todo page',
    description:
        'Main TMS task management page wrapper with responsive desktop and mobile layout.',
    module: 'tms',
    screenKey: 'todo_page',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'todo', 'tasks', 'page', 'root'],
  );

  static const tmsTodoPcRoot = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.pc.root',
    frontendRef: 'EmmaAnchors.tmsTodoPcRoot',
    label: 'TMS desktop view',
    description: 'Desktop layout of the task management board.',
    module: 'tms',
    screenKey: 'todo_pc',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'todo', 'desktop', 'board'],
  );

  static const tmsTodoPcBoardSidebar = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.pc.board_sidebar',
    frontendRef: 'EmmaAnchors.tmsTodoPcBoardSidebar',
    label: 'Boards sidebar',
    description:
        'Left desktop sidebar with board navigation, sync status and add board action.',
    module: 'tms',
    screenKey: 'todo_pc',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.sidebar,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    defaultPlacement: EmmaUiAnchorPlacement.right,
    tags: ['tms', 'boards', 'sidebar', 'navigation'],
  );

  static const tmsTodoPcSyncStatus = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.pc.sync_status',
    frontendRef: 'EmmaAnchors.tmsTodoPcSyncStatus',
    label: 'TMS sync status',
    description: 'Status chip showing local/offline synchronization state for TMS.',
    module: 'tms',
    screenKey: 'todo_pc',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['tms', 'sync', 'offline', 'status'],
  );

  static const tmsTodoPcAllBoardsButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.pc.all_boards_button',
    frontendRef: 'EmmaAnchors.tmsTodoPcAllBoardsButton',
    label: 'All boards button',
    description: 'Button opening the full boards/projects management view.',
    module: 'tms',
    screenKey: 'todo_pc',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'boards', 'all_boards', 'navigation', 'button'],
    meta: {
      'opens': 'boards_page',
    },
  );

  static const tmsTodoPcBoardList = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.pc.board_list',
    frontendRef: 'EmmaAnchors.tmsTodoPcBoardList',
    label: 'Boards list',
    description:
        'Reorderable vertical list of available TMS boards on desktop.',
    module: 'tms',
    screenKey: 'todo_pc',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    defaultPlacement: EmmaUiAnchorPlacement.right,
    tags: ['tms', 'boards', 'list', 'reorder', 'drag_drop'],
    meta: {
      'supports_reorder': true,
      'supports_pie_menu_on_items': true,
      'scroll_direction': 'vertical',
    },
  );

  static const tmsTodoPcAddBoardButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.pc.add_board_button',
    frontendRef: 'EmmaAnchors.tmsTodoPcAddBoardButton',
    label: 'Add board button',
    description: 'Button opening the create board dialog.',
    module: 'tms',
    screenKey: 'todo_pc',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'boards', 'add', 'button', 'cta'],
    meta: {
      'opens': 'create_board_dialog',
    },
  );

  static const tmsTodoPcFilterButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.pc.filter_button',
    frontendRef: 'EmmaAnchors.tmsTodoPcFilterButton',
    label: 'Task filters button',
    description: 'Desktop side action button opening task filters.',
    module: 'tms',
    screenKey: 'todo_pc',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'tasks', 'filters', 'button'],
    meta: {
      'opens': 'task_filters_dialog',
    },
  );

  static const tmsTodoMobileRoot = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.mobile.root',
    frontendRef: 'EmmaAnchors.tmsTodoMobileRoot',
    label: 'TMS mobile view',
    description: 'Mobile layout of the task management board.',
    module: 'tms',
    screenKey: 'todo_mobile',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'todo', 'mobile', 'board'],
  );

  static const tmsTodoMobileBoardStrip = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.mobile.board_strip',
    frontendRef: 'EmmaAnchors.tmsTodoMobileBoardStrip',
    label: 'Mobile boards strip',
    description: 'Horizontal strip with board shortcuts on mobile.',
    module: 'tms',
    screenKey: 'todo_mobile',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'boards', 'mobile', 'horizontal_list'],
    meta: {
      'scroll_direction': 'horizontal',
      'supports_board_open': true,
      'supports_pie_menu_on_items': true,
    },
  );

  static const tmsTodoMobileAddBoardTile = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.mobile.add_board_tile',
    frontendRef: 'EmmaAnchors.tmsTodoMobileAddBoardTile',
    label: 'Mobile add board tile',
    description: 'Tile used to create a new board from the mobile board strip.',
    module: 'tms',
    screenKey: 'todo_mobile',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'boards', 'mobile', 'add', 'tile'],
    meta: {
      'opens': 'create_board_dialog',
    },
  );

  static const tmsTodoMobileFilterButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.mobile.filter_button',
    frontendRef: 'EmmaAnchors.tmsTodoMobileFilterButton',
    label: 'Mobile filters button',
    description: 'Floating mobile action button opening task filters.',
    module: 'tms',
    screenKey: 'todo_mobile',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'tasks', 'filters', 'mobile', 'button'],
    meta: {
      'opens': 'task_filters_sheet',
    },
  );

  static const tmsTodoMobileAddTaskButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.mobile.add_task_button',
    frontendRef: 'EmmaAnchors.tmsTodoMobileAddTaskButton',
    label: 'Mobile add task button',
    description: 'Floating mobile action button opening the add task sheet.',
    module: 'tms',
    screenKey: 'todo_mobile',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'tasks', 'add', 'mobile', 'button'],
    meta: {
      'opens': 'add_task_sheet',
    },
  );

  static const tmsTodoBoardRoot = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.root',
    frontendRef: 'EmmaAnchors.tmsTodoBoardRoot',
    label: 'Task board',
    description: 'Main Kanban-like TMS board with columns and task cards.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'board', 'kanban', 'tasks'],
  );

  static const tmsTodoBoardDragSurface = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.drag_surface',
    frontendRef: 'EmmaAnchors.tmsTodoBoardDragSurface',
    label: 'Drag and drop board area',
    description:
        'Interactive board surface where task cards and columns can be reordered with drag and drop.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.onboarding,
    defaultPlacement: EmmaUiAnchorPlacement.top,
    tags: ['tms', 'drag_drop', 'kanban', 'tasks', 'columns'],
    meta: {
      'supports_drag_drop': true,
      'drag_entities': ['task_card', 'column'],
      'mobile_drag_mode': 'long_press',
    },
    onboardingOrder: 10,
    onboardingMessage:
        'Tutaj możesz przeciągać zadania między kolumnami. Na telefonie przeciąganie aktywuje się po dłuższym przytrzymaniu.',
  );

  static const tmsTodoBoardFirstColumnHeader = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.first_column.header',
    frontendRef: 'EmmaAnchors.tmsTodoBoardFirstColumnHeader',
    label: 'First column header',
    description:
        'Header of the first visible task column. It can be clicked to rename the column.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'column', 'header', 'edit'],
    meta: {
      'supports_inline_edit': true,
      'entity': 'progress_column',
    },
  );

  static const tmsTodoBoardFirstColumnMenuButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.first_column.menu_button',
    frontendRef: 'EmmaAnchors.tmsTodoBoardFirstColumnMenuButton',
    label: 'Column menu button',
    description:
        'Column menu with actions for adding a task, editing progress and deleting the column.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'column', 'menu', 'actions'],
    meta: {
      'opens': 'column_actions_menu',
    },
  );

  static const tmsTodoBoardFirstColumnAddCardButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.first_column.add_card_button',
    frontendRef: 'EmmaAnchors.tmsTodoBoardFirstColumnAddCardButton',
    label: 'Add card button',
    description: 'Button used to add a new task card to the first visible column.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'task', 'card', 'add', 'button'],
    meta: {
      'opens': 'add_task_inline_form',
    },
  );

  static const tmsTodoBoardFirstColumnAddCardForm = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.first_column.add_card_form',
    frontendRef: 'EmmaAnchors.tmsTodoBoardFirstColumnAddCardForm',
    label: 'Add card form',
    description: 'Inline form used to create a new task card in the first column.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'task', 'card', 'form', 'create'],
  );

  static const tmsTodoBoardFirstColumnAddCardInput = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.first_column.add_card_input',
    frontendRef: 'EmmaAnchors.tmsTodoBoardFirstColumnAddCardInput',
    label: 'Task name input',
    description: 'Input for entering the new task card name.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'task', 'input', 'name'],
  );

  static const tmsTodoBoardFirstTaskCard = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.first_task_card',
    frontendRef: 'EmmaAnchors.tmsTodoBoardFirstTaskCard',
    label: 'First task card',
    description:
        'First visible task card on the board. Cards can be opened and moved between columns.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'task', 'card', 'drag_drop', 'open'],
    meta: {
      'supports_drag_drop': true,
      'opens': 'task_details_popup',
    },
    onboardingOrder: 11,
    onboardingMessage:
        'To jest karta zadania. Kliknięcie otwiera szczegóły, a przeciągnięcie przenosi zadanie między kolumnami.',
  );

  static const tmsTodoBoardAddListButton = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.add_list_button',
    frontendRef: 'EmmaAnchors.tmsTodoBoardAddListButton',
    label: 'Add another list button',
    description: 'Button used to add another column/list to the board.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'column', 'list', 'add', 'button'],
    meta: {
      'opens': 'add_list_form',
    },
  );

  static const tmsTodoBoardAddListForm = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.add_list_form',
    frontendRef: 'EmmaAnchors.tmsTodoBoardAddListForm',
    label: 'Add list form',
    description: 'Inline form for creating a new board column/list.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'column', 'list', 'form', 'create'],
  );

  static const tmsTodoBoardAddListInput = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.add_list_input',
    frontendRef: 'EmmaAnchors.tmsTodoBoardAddListInput',
    label: 'List name input',
    description: 'Input for entering the new column/list name.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'column', 'list', 'input'],
  );

  static const tmsTodoBoardPendingTasksInfo = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.board.pending_tasks_info',
    frontendRef: 'EmmaAnchors.tmsTodoBoardPendingTasksInfo',
    label: 'Pending tasks info',
    description:
        'Info box explaining that queued tasks will be moved into the newly created list.',
    module: 'tms',
    screenKey: 'todo_board',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['tms', 'tasks', 'pending', 'move'],
  );

  static const tmsTodoTaskPopupRoot = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.task_popup.root',
    frontendRef: 'EmmaAnchors.tmsTodoTaskPopupRoot',
    label: 'Task details popup',
    description: 'Popup with detailed information and actions for a selected task.',
    module: 'tms',
    screenKey: 'task_details_popup',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.overlay,
    runtimeMode: EmmaUiAnchorRuntimeMode.always,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'task', 'details', 'popup'],
  );

  static const tmsTodoTaskPopupHeader = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.task_popup.header',
    frontendRef: 'EmmaAnchors.tmsTodoTaskPopupHeader',
    label: 'Task popup header',
    description: 'Header area of the task details popup.',
    module: 'tms',
    screenKey: 'task_details_popup',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'task', 'popup', 'header'],
  );

  static const tmsTodoTaskPopupContent = EmmaUiAnchorSpec(
    anchorKey: 'tms.todo.task_popup.content',
    frontendRef: 'EmmaAnchors.tmsTodoTaskPopupContent',
    label: 'Task popup content',
    description: 'Main content area of the task details popup.',
    module: 'tms',
    screenKey: 'task_details_popup',
    routePattern: '/pro/todo/',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['tms', 'task', 'popup', 'content'],
  );
  
  static const tmsBoardPageRoot = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.page.root',
  frontendRef: 'EmmaAnchors.tmsBoardPageRoot',
  label: 'TMS boards page',
  description: 'Responsive TMS boards page that opens desktop board overview or mobile todo view.',
  module: 'tms',
  screenKey: 'boards_page',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'page', 'root'],
);

static const tmsBoardPcRoot = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.root',
  frontendRef: 'EmmaAnchors.tmsBoardPcRoot',
  label: 'TMS boards desktop view',
  description: 'Desktop overview page for browsing, sorting and opening task boards.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'desktop', 'overview'],
);

static const tmsBoardPcHeader = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.header',
  frontendRef: 'EmmaAnchors.tmsBoardPcHeader',
  label: 'Boards header',
  description: 'Top header of the boards overview with company title, sort and board avatars.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'header', 'topbar'],
);

static const tmsBoardPcCompanyTitle = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.company_title',
  frontendRef: 'EmmaAnchors.tmsBoardPcCompanyTitle',
  label: 'Company title',
  description: 'Company title displayed in the boards header.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.help,
  tags: ['tms', 'boards', 'company', 'title'],
);

static const tmsBoardPcHeaderSortMenu = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.header_sort_menu',
  frontendRef: 'EmmaAnchors.tmsBoardPcHeaderSortMenu',
  label: 'Header sort menu',
  description: 'Sort menu in the boards header used to order boards by date or name.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'sort', 'menu'],
  meta: {'sort_entities': 'boards'},
);

static const tmsBoardPcHeaderAvatars = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.header_avatars',
  frontendRef: 'EmmaAnchors.tmsBoardPcHeaderAvatars',
  label: 'Board avatars',
  description: 'Small overlapping board avatars shown in the boards header.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.widget,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.help,
  tags: ['tms', 'boards', 'avatars', 'preview'],
);

static const tmsBoardPcRecentlyViewedSection = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.recently_viewed_section',
  frontendRef: 'EmmaAnchors.tmsBoardPcRecentlyViewedSection',
  label: 'Recently viewed boards section',
  description: 'Section showing recently viewed or quick-access boards.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'recent', 'section'],
);

static const tmsBoardPcRecentBoardsStrip = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.recent_boards_strip',
  frontendRef: 'EmmaAnchors.tmsBoardPcRecentBoardsStrip',
  label: 'Recent boards strip',
  description: 'Horizontal strip of board cards with drag-to-scroll support.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'recent', 'horizontal_list'],
  meta: {
    'scroll_direction': 'horizontal',
    'supports_pie_menu_on_items': true,
    'opens': 'todo_board',
  },
);

static const tmsBoardPcFirstRecentBoardCard = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.first_recent_board_card',
  frontendRef: 'EmmaAnchors.tmsBoardPcFirstRecentBoardCard',
  label: 'First recent board card',
  description: 'First visible board card in the recently viewed strip.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.card,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'recent', 'card', 'open'],
  meta: {
    'opens': 'todo_board',
    'supports_pie_menu': true,
  },
);

static const tmsBoardPcAllBoardsSection = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.all_boards_section',
  frontendRef: 'EmmaAnchors.tmsBoardPcAllBoardsSection',
  label: 'All boards section',
  description: 'Main section listing all available TMS boards.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'all', 'section'],
);

static const tmsBoardPcAllBoardsSortMenu = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.all_boards_sort_menu',
  frontendRef: 'EmmaAnchors.tmsBoardPcAllBoardsSortMenu',
  label: 'All boards sort menu',
  description: 'Sort menu for the all boards grid.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'sort', 'grid'],
  meta: {'sort_entities': 'boards'},
);

static const tmsBoardPcBoardsGrid = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.boards_grid',
  frontendRef: 'EmmaAnchors.tmsBoardPcBoardsGrid',
  label: 'Boards grid',
  description: 'Grid containing all board cards.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.section,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.disabled,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'grid', 'cards'],
  meta: {
    'supports_pie_menu_on_items': true,
    'opens': 'todo_board',
  },
);

static const tmsBoardPcFirstGridBoardCard = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.first_grid_board_card',
  frontendRef: 'EmmaAnchors.tmsBoardPcFirstGridBoardCard',
  label: 'First board card',
  description: 'First visible board card in the all boards grid.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.card,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'grid', 'card', 'open'],
  meta: {
    'opens': 'todo_board',
    'supports_pie_menu': true,
  },
);

static const tmsBoardPcAddBoardButton = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.add_board_button',
  frontendRef: 'EmmaAnchors.tmsBoardPcAddBoardButton',
  label: 'Add board button',
  description: 'Button opening the create board dialog from the boards overview.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.button,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'add', 'button', 'cta'],
  meta: {'opens': 'create_board_dialog'},
);

static const tmsBoardPcProfileCard = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.pc.profile_card',
  frontendRef: 'EmmaAnchors.tmsBoardPcProfileCard',
  label: 'User profile card',
  description: 'Right side profile card with avatar, name and email.',
  module: 'tms',
  screenKey: 'boards_pc',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.card,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'profile', 'user', 'card'],
  meta: {'opens': 'profile_page'},
);

static const tmsBoardCardWidgetRoot = EmmaUiAnchorSpec(
  anchorKey: 'tms.board.card.widget',
  frontendRef: 'EmmaAnchors.tmsBoardCardWidgetRoot',
  label: 'Board card widget',
  description: 'Reusable visual board card widget.',
  module: 'tms',
  screenKey: 'boards',
  routePattern: '/pro/*',
  targetKind: EmmaUiAnchorTargetKind.card,
  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
  usageMode: EmmaUiAnchorUsageMode.both,
  tags: ['tms', 'boards', 'card', 'widget'],
);

  static const all = <EmmaUiAnchorSpec>[
    tmsTodoPageRoot,
    tmsTodoPcRoot,
    tmsTodoPcBoardSidebar,
    tmsTodoPcSyncStatus,
    tmsTodoPcAllBoardsButton,
    tmsTodoPcBoardList,
    tmsTodoPcAddBoardButton,
    tmsTodoPcFilterButton,
    tmsTodoMobileRoot,
    tmsTodoMobileBoardStrip,
    tmsTodoMobileAddBoardTile,
    tmsTodoMobileFilterButton,
    tmsTodoMobileAddTaskButton,
    tmsTodoBoardRoot,
    tmsTodoBoardDragSurface,
    tmsTodoBoardFirstColumnHeader,
    tmsTodoBoardFirstColumnMenuButton,
    tmsTodoBoardFirstColumnAddCardButton,
    tmsTodoBoardFirstColumnAddCardForm,
    tmsTodoBoardFirstColumnAddCardInput,
    tmsTodoBoardFirstTaskCard,
    tmsTodoBoardAddListButton,
    tmsTodoBoardAddListForm,
    tmsTodoBoardAddListInput,
    tmsTodoBoardPendingTasksInfo,
    tmsTodoTaskPopupRoot,
    tmsTodoTaskPopupHeader,
    tmsTodoTaskPopupContent,
    tmsBoardPageRoot,
    tmsBoardPcRoot,
    tmsBoardPcHeader,
    tmsBoardPcCompanyTitle,
    tmsBoardPcHeaderSortMenu,
    tmsBoardPcHeaderAvatars,
    tmsBoardPcRecentlyViewedSection,
    tmsBoardPcRecentBoardsStrip,
    tmsBoardPcFirstRecentBoardCard,
    tmsBoardPcAllBoardsSection,
    tmsBoardPcAllBoardsSortMenu,
    tmsBoardPcBoardsGrid,
    tmsBoardPcFirstGridBoardCard,
    tmsBoardPcAddBoardButton,
    tmsBoardPcProfileCard,
    tmsBoardCardWidgetRoot,
  ];
}