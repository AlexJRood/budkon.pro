import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class ImporterEmmaAnchors {
  static const importDataPageRoot = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.page.root',
    frontendRef: 'ImporterEmmaAnchors.importDataPageRoot',
    label: 'Data importer page',
    description:
        'Main data importer screen used to upload files, prepare data, map fields, and review import jobs.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'data', 'import', 'page', 'root'],
    meta: {
      'usage_mode': 'both',
      'flow': 'data_import',
    },
  );

  static const importDataHeader = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.header',
    frontendRef: 'ImporterEmmaAnchors.importDataHeader',
    label: 'Importer header',
    description:
        'Progress header showing current import step, completion status, and quick import statistics.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'header', 'steps', 'progress'],
    meta: {
      'usage_mode': 'both',
      'onboarding_area': 'import_progress',
    },
  );

  static const importDataStepFile = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.step.file',
    frontendRef: 'ImporterEmmaAnchors.importDataStepFile',
    label: 'File import step',
    description:
        'First importer step where the user uploads or selects a source data file.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.tab,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    onboardingOrder: 1,
    onboardingMessage:
        'Zaczynamy od pliku. Tutaj wrzucasz CSV, XLSX, JSON albo XML, a importer przygotowuje szybki podgląd danych.',
    tags: ['importer', 'step', 'file', 'upload'],
    meta: {
      'usage_mode': 'both',
      'step': 1,
    },
  );

  static const importDataStepEditor = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.step.editor',
    frontendRef: 'ImporterEmmaAnchors.importDataStepEditor',
    label: 'Data editor step',
    description:
        'Second importer step where the user reviews, filters, selects, and prepares imported data.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.tab,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    onboardingOrder: 2,
    onboardingMessage:
        'W edytorze sprawdzasz dane, wybierasz wiersze do importu i możesz przygotować kolumny przed mapowaniem.',
    tags: ['importer', 'step', 'editor', 'data'],
    meta: {
      'usage_mode': 'both',
      'step': 2,
    },
  );

  static const importDataStepMapper = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.step.mapper',
    frontendRef: 'ImporterEmmaAnchors.importDataStepMapper',
    label: 'Field mapper step',
    description:
        'Third importer step where source columns are mapped to target model fields.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.tab,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    onboardingOrder: 3,
    onboardingMessage:
        'Tutaj łączysz kolumny z pliku z polami w systemie. Możesz użyć listy albo canvasu z przeciąganiem.',
    tags: ['importer', 'step', 'mapper', 'fields', 'mapping'],
    meta: {
      'usage_mode': 'both',
      'step': 3,
      'supports_drag_drop': true,
    },
  );

  static const importDataStepJobs = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.step.jobs',
    frontendRef: 'ImporterEmmaAnchors.importDataStepJobs',
    label: 'Import jobs step',
    description:
        'Fourth importer step where the user reviews recent import jobs, progress, and errors.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.tab,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    onboardingOrder: 4,
    onboardingMessage:
        'Po imporcie tutaj sprawdzasz status, błędy i historię ostatnich zadań importu.',
    tags: ['importer', 'step', 'jobs', 'history', 'status'],
    meta: {
      'usage_mode': 'both',
      'step': 4,
    },
  );

  static const importDataContent = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.content',
    frontendRef: 'ImporterEmmaAnchors.importDataContent',
    label: 'Importer active content',
    description:
        'Main content area of the currently selected importer step.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'content', 'active_step'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importDataBottomActions = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.bottom_actions',
    frontendRef: 'ImporterEmmaAnchors.importDataBottomActions',
    label: 'Importer bottom actions',
    description:
        'Sticky bottom action bar with next, back, submit, refresh, or new import actions.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'actions', 'bottom_bar', 'navigation'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importDataPrimaryAction = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.primary_action',
    frontendRef: 'ImporterEmmaAnchors.importDataPrimaryAction',
    label: 'Importer primary action',
    description:
        'Primary importer action button used to continue, run import, or refresh import jobs.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'primary_action', 'button', 'continue', 'submit'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importDataSecondaryAction = EmmaUiAnchorSpec(
    anchorKey: 'importer.data.secondary_action',
    frontendRef: 'ImporterEmmaAnchors.importDataSecondaryAction',
    label: 'Importer secondary action',
    description:
        'Secondary importer action button used to go back or start a new import.',
    module: 'importer',
    screenKey: 'data_importer',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'secondary_action', 'button', 'back', 'new_import'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importUploadRoot = EmmaUiAnchorSpec(
    anchorKey: 'importer.upload.root',
    frontendRef: 'ImporterEmmaAnchors.importUploadRoot',
    label: 'Upload tab',
    description:
        'Upload tab where users choose a source file and see initial import guidance.',
    module: 'importer',
    screenKey: 'data_importer_upload',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'upload', 'file'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importUploadDropzone = EmmaUiAnchorSpec(
    anchorKey: 'importer.upload.dropzone',
    frontendRef: 'ImporterEmmaAnchors.importUploadDropzone',
    label: 'Upload file dropzone',
    description:
        'Clickable upload zone used to select a CSV, XLSX, JSON, or XML file.',
    module: 'importer',
    screenKey: 'data_importer_upload',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    onboardingOrder: 10,
    onboardingMessage:
        'Kliknij tutaj, żeby wybrać plik do importu. Po wyborze importer od razu spróbuje przygotować podgląd.',
    tags: ['importer', 'upload', 'dropzone', 'file_picker'],
    meta: {
      'usage_mode': 'both',
      'accepts': ['csv', 'xlsx', 'xls', 'json', 'xml'],
    },
  );

  static const importUploadSelectedFile = EmmaUiAnchorSpec(
    anchorKey: 'importer.upload.selected_file',
    frontendRef: 'ImporterEmmaAnchors.importUploadSelectedFile',
    label: 'Selected file info',
    description:
        'Selected source file summary with filename, size, and clear action.',
    module: 'importer',
    screenKey: 'data_importer_upload',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'upload', 'selected_file', 'file_info'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importUploadPreview = EmmaUiAnchorSpec(
    anchorKey: 'importer.upload.preview',
    frontendRef: 'ImporterEmmaAnchors.importUploadPreview',
    label: 'Upload quick preview',
    description:
        'Mini preview of detected columns and sample rows after selecting a file.',
    module: 'importer',
    screenKey: 'data_importer_upload',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'upload', 'preview', 'columns', 'rows'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorRoot = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.root',
    frontendRef: 'ImporterEmmaAnchors.importEditorRoot',
    label: 'Importer editor',
    description:
        'Editor tab for searching columns, filtering values, selecting rows, and preparing data.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'editor', 'data_preparation'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorToolbar = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.toolbar',
    frontendRef: 'ImporterEmmaAnchors.importEditorToolbar',
    label: 'Editor toolbar',
    description:
        'Toolbar with column search, value search, target model selector, selection actions, and filters.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'editor', 'toolbar', 'filters'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorColumnSearch = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.column_search',
    frontendRef: 'ImporterEmmaAnchors.importEditorColumnSearch',
    label: 'Column search',
    description:
        'Search input used to filter visible imported columns in the editor.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'editor', 'search', 'columns'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorValueSearch = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.value_search',
    frontendRef: 'ImporterEmmaAnchors.importEditorValueSearch',
    label: 'Value search',
    description:
        'Search input used to find matching values across visible imported data.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'editor', 'search', 'values'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorTargetModelSelect = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.target_model_select',
    frontendRef: 'ImporterEmmaAnchors.importEditorTargetModelSelect',
    label: 'Target model selector',
    description:
        'Dropdown used to select the default target model for imported data mapping.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'editor', 'target_model', 'dropdown'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorSelectionActions = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.selection_actions',
    frontendRef: 'ImporterEmmaAnchors.importEditorSelectionActions',
    label: 'Selection actions',
    description:
        'Menu with bulk row selection actions for imported data.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.menuItem,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'editor', 'selection', 'bulk_actions'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorColumnsPanel = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.columns_panel',
    frontendRef: 'ImporterEmmaAnchors.importEditorColumnsPanel',
    label: 'Editor columns panel',
    description:
        'Column list panel used to select a source column and inspect mapping or transform status.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'editor', 'columns', 'source_columns'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorGridPanel = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.grid_panel',
    frontendRef: 'ImporterEmmaAnchors.importEditorGridPanel',
    label: 'Editor data grid',
    description:
        'Data preview grid with selectable rows and visible imported values.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'editor', 'grid', 'preview', 'row_selection'],
    meta: {
      'usage_mode': 'both',
      'supports_row_selection': true,
    },
  );

  static const importEditorInspectorPanel = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.inspector_panel',
    frontendRef: 'ImporterEmmaAnchors.importEditorInspectorPanel',
    label: 'Editor inspector',
    description:
        'Inspector panel for the selected source column with mappings, transforms, and sample values.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'editor', 'inspector', 'column_details'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorMapFieldButton = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.map_field_button',
    frontendRef: 'ImporterEmmaAnchors.importEditorMapFieldButton',
    label: 'Map field button',
    description:
        'Button used to open mapping controls for the selected source column.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'editor', 'mapping', 'button'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importEditorTransformsButton = EmmaUiAnchorSpec(
    anchorKey: 'importer.editor.transforms_button',
    frontendRef: 'ImporterEmmaAnchors.importEditorTransformsButton',
    label: 'Transforms button',
    description:
        'Button used to open transformation tools for the selected source column.',
    module: 'importer',
    screenKey: 'data_importer_editor',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'editor', 'transforms', 'button'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importMapperRoot = EmmaUiAnchorSpec(
    anchorKey: 'importer.mapper.root',
    frontendRef: 'ImporterEmmaAnchors.importMapperRoot',
    label: 'Field mapper',
    description:
        'Mapper tab where source columns are assigned to target model fields.',
    module: 'importer',
    screenKey: 'data_importer_mapper',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'mapper', 'fields'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importMapperToolbar = EmmaUiAnchorSpec(
    anchorKey: 'importer.mapper.toolbar',
    frontendRef: 'ImporterEmmaAnchors.importMapperToolbar',
    label: 'Mapper toolbar',
    description:
        'Toolbar showing mapper stats, active source column, and list/canvas view switcher.',
    module: 'importer',
    screenKey: 'data_importer_mapper',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'mapper', 'toolbar', 'view_switcher'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importMapperCanvas = EmmaUiAnchorSpec(
    anchorKey: 'importer.mapper.canvas',
    frontendRef: 'ImporterEmmaAnchors.importMapperCanvas',
    label: 'Mapper canvas',
    description:
        'Visual drag-and-drop canvas for connecting source columns to target model fields.',
    module: 'importer',
    screenKey: 'data_importer_mapper',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    onboardingOrder: 30,
    onboardingMessage:
        'Canvas pozwala przeciągać kolumny z lewej strony na pola modelu po prawej. Linie pokazują aktualne połączenia.',
    tags: ['importer', 'mapper', 'canvas', 'drag_drop'],
    meta: {
      'usage_mode': 'both',
      'supports_drag_drop': true,
      'supports_zoom': true,
      'supports_fullscreen': true,
    },
  );

  static const importMapperSourcePanel = EmmaUiAnchorSpec(
    anchorKey: 'importer.mapper.source_panel',
    frontendRef: 'ImporterEmmaAnchors.importMapperSourcePanel',
    label: 'Mapper source columns',
    description:
        'Source columns panel used to select a column from the imported file.',
    module: 'importer',
    screenKey: 'data_importer_mapper',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'mapper', 'source_columns'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importMapperTargetPanel = EmmaUiAnchorSpec(
    anchorKey: 'importer.mapper.target_panel',
    frontendRef: 'ImporterEmmaAnchors.importMapperTargetPanel',
    label: 'Mapper target fields',
    description:
        'Target model fields panel used to assign source columns to fields.',
    module: 'importer',
    screenKey: 'data_importer_mapper',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'mapper', 'target_fields'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importJobsRoot = EmmaUiAnchorSpec(
    anchorKey: 'importer.jobs.root',
    frontendRef: 'ImporterEmmaAnchors.importJobsRoot',
    label: 'Import jobs',
    description:
        'Import jobs tab with recent imports, status counters, progress and errors.',
    module: 'importer',
    screenKey: 'data_importer_jobs',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'jobs', 'status', 'history'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importJobsRefreshButton = EmmaUiAnchorSpec(
    anchorKey: 'importer.jobs.refresh_button',
    frontendRef: 'ImporterEmmaAnchors.importJobsRefreshButton',
    label: 'Refresh import jobs',
    description:
        'Button used to refresh recent import jobs and progress statuses.',
    module: 'importer',
    screenKey: 'data_importer_jobs',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    tags: ['importer', 'jobs', 'refresh', 'button'],
    meta: {
      'usage_mode': 'both',
    },
  );

  static const importJobsList = EmmaUiAnchorSpec(
    anchorKey: 'importer.jobs.list',
    frontendRef: 'ImporterEmmaAnchors.importJobsList',
    label: 'Import jobs list',
    description:
        'List of recent import jobs with progress, successful rows, failed rows, and status.',
    module: 'importer',
    screenKey: 'data_importer_jobs',
    routePattern: '/pro/*',
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.disabled,
    tags: ['importer', 'jobs', 'list', 'history'],
    meta: {
      'usage_mode': 'both',
    },
  );
}