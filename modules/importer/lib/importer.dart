import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:importer/tabs/batch_import_overlay.dart';
import 'package:importer/tabs/import_tab_mapper.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

import 'import_state.dart';
import 'tabs/import_tab_editor.dart';
import 'tabs/import_tab_jobs.dart';
import 'tabs/import_tab_upload.dart';

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:importer/emma/anchors/anchors_importer.dart';

class ImportDataPage extends ConsumerStatefulWidget {
  const ImportDataPage({super.key});

  @override
  ConsumerState<ImportDataPage> createState() => _ImportDataPageState();
}

class _ImportDataPageState extends ConsumerState<ImportDataPage> {
  final _sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final optionsAsync = ref.watch(importOptionsProvider);
    final jobsAsync = ref.watch(importJobsProvider);
    final formState = ref.watch(importFormProvider);
    final formNotifier = ref.read(importFormProvider.notifier);

    return EmmaUiAnchorTarget(
      // @emma-backend: ImporterEmmaAnchors.importDataPageRoot
      anchorKey: 'importer.data.page.root',
      child: BarManager(
        sideMenuKey: _sideMenuKey,
        appModule: AppModule.agentCrm,
        isTopAppBarOff: true,
        isTopAppBarOffMobile: false,
        isBottomBarOff: true,
        childPc: ImportTabsContent(
          theme: theme,
          optionsAsync: optionsAsync,
          jobsAsync: jobsAsync,
          formState: formState,
          formNotifier: formNotifier,
          showHeader: false,
        ),
        childTablet: ImportTabsContent(
          theme: theme,
          optionsAsync: optionsAsync,
          jobsAsync: jobsAsync,
          formState: formState,
          formNotifier: formNotifier,
          showHeader: false,
          isTablet: true,
      ),
      childMobile: ImportTabsContent(
          theme: theme,
          optionsAsync: optionsAsync,
          jobsAsync: jobsAsync,
          formState: formState,
          formNotifier: formNotifier,
          showHeader: false,
        ),
      ),
    );
  }
}

class _ImportStepMeta {
  final String tabLabel;
  final String shortLabel;
  final String title;
  final String description;

  const _ImportStepMeta({
    required this.tabLabel,
    required this.shortLabel,
    required this.title,
    required this.description,
  });
}

const List<_ImportStepMeta> _importSteps = [
  _ImportStepMeta(
    tabLabel: '1. Plik',
    shortLabel: 'Plik',
    title: 'Wybierz plik',
    description: 'Załaduj źródło danych i sprawdź szybki podgląd.',
  ),
  _ImportStepMeta(
    tabLabel: '2. Edytor',
    shortLabel: 'Edytor',
    title: 'Przygotuj dane',
    description: 'Zweryfikuj kolumny, wartości i popraw dane przed mapowaniem.',
  ),
  _ImportStepMeta(
    tabLabel: '3. Mapper',
    shortLabel: 'Mapper',
    title: 'Połącz pola',
    description: 'Przypisz kolumny do modelu i uruchom import.',
  ),
  _ImportStepMeta(
    tabLabel: '4. Wynik',
    shortLabel: 'Wynik',
    title: 'Sprawdź wynik',
    description: 'Zobacz rezultat importu i ewentualne błędy.',
  ),
];

class ImportTabsContent extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final AsyncValue<ImportOptions> optionsAsync;
  final AsyncValue<List<ImportJobSummary>> jobsAsync;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final bool showHeader;
  final bool isTablet;

  const ImportTabsContent({
    super.key,
    required this.theme,
    required this.optionsAsync,
    required this.jobsAsync,
    required this.formState,
    required this.formNotifier,
    this.showHeader = false,
    this.isTablet = false,
  });

  @override
  ConsumerState<ImportTabsContent> createState() => _ImportTabsContentState();
}

class _ImportTabsContentState extends ConsumerState<ImportTabsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  bool get _hasFile => widget.formState.file != null;
  bool get _hasPreview => widget.formState.previewColumns.isNotEmpty;
  bool get _hasMappings => widget.formState.fieldMappings.isNotEmpty;
  bool get _isCompact => MediaQuery.of(context).size.width < 980;

  int get _mappedCount => widget.formState.fieldMappings.length;
  int get _previewColumnsCount => widget.formState.previewColumns.length;
  int get _previewRowsCount => widget.formState.previewData.length;
  ImportEditorPaginationState? _editorPaginationState;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _importSteps.length, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging) return;

      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void didUpdateWidget(covariant ImportTabsContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-advance to editor when CSV is parsed and preview becomes available.
    if (_currentIndex == 0 &&
        oldWidget.formState.previewColumns.isEmpty &&
        widget.formState.previewColumns.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goToStep(1);
      });
      return;
    }

    if (_currentIndex == 3) return;

    if (!_canOpenStep(_currentIndex)) {
      final fallback = _closestAvailableStep();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _tabController.animateTo(fallback);
        setState(() {
          _currentIndex = fallback;
        });
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _closestAvailableStep() {
    if (_hasPreview) return 2;
    if (_hasFile) return 1;
    return 0;
  }

  bool _canOpenStep(int index) {
    switch (index) {
      case 0:
        return true;
      case 1:
        return _hasFile;
      case 2:
        return _hasPreview;
      case 3:
        return true;
      default:
        return false;
    }
  }



  void _handleEditorPaginationChanged(ImportEditorPaginationState pagination) {
    if (_editorPaginationState == pagination) return;

    setState(() {
      _editorPaginationState = pagination;
    });
  }




  bool _canProceedFromCurrentStep() {
    switch (_currentIndex) {
      case 0:
        return _hasFile;
      case 1:
        return _hasPreview;
      case 2:
        return _hasMappings &&
            !widget.formState.isSubmitting &&
            !widget.formState.isBatchRunning;
      case 3:
        return !widget.formState.isSubmitting &&
            !widget.formState.isBatchRunning;
      default:
        return false;
    }
  }

  bool _isStepCompleted(int index) {
    switch (index) {
      case 0:
        return _hasFile;
      case 1:
        return _hasPreview;
      case 2:
        return _hasMappings;
      case 3:
        return widget.formState.batchResults.isNotEmpty ||
            widget.formState.lastJobId != null ||
            (widget.formState.lastMessage?.trim().isNotEmpty ?? false);
      default:
        return false;
    }
  }

  bool _isStepLocked(int index) {
    switch (index) {
      case 1:
        return !_hasFile;
      case 2:
        return !_hasPreview;
      default:
        return false;
    }
  }

  String _blockedReasonForStep(int index) {
    switch (index) {
      case 1:
        return 'Najpierw wybierz plik w kroku 1.'.tr;
      case 2:
        return 'Najpierw przygotuj podgląd danych w kroku 2.'.tr;
      default:
        return 'Ten krok nie jest jeszcze dostępny.'.tr;
    }
  }

  void _showBlockedStepMessage(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_blockedReasonForStep(index)),
      ),
    );
  }

  void _goToStep(int index) {
    if (!_canOpenStep(index)) {
      _showBlockedStepMessage(index);
      return;
    }

    _tabController.animateTo(index);
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openBatchOverlayAndHandleResult() async {
    final overlayResult = await showBatchImportOverlay(context);

    if (!mounted || overlayResult == null) return;

    switch (overlayResult.action) {
      case BatchImportOverlayAction.showRowInEditor:
        _jumpToEditorRow(overlayResult.previewRowIndex);
        break;
    }
  }

  void _jumpToEditorRow(int previewRowIndex) {
    final state = ref.read(importFormProvider);

    if (state.previewData.isEmpty) {
      _goToStep(1);
      return;
    }

    final maxIndex = state.previewData.length - 1;
    final safeRowIndex = previewRowIndex.clamp(0, maxIndex).toInt();

    final pageSize = state.pageSize <= 0 ? 100 : state.pageSize;
    final targetPage = safeRowIndex ~/ pageSize;

    final notifier = ref.read(importFormProvider.notifier);

    notifier.setPage(targetPage);

    // Nie kasujemy całego zaznaczenia użytkownika.
    // Tylko upewniamy się, że problematyczny wiersz jest zaznaczony.
    notifier.setRowSelected(safeRowIndex, true);

    _goToStep(1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Otworzono edytor na stronie z wierszem ${safeRowIndex + 1}.'.tr,
          ),
        ),
      );
    });
  }

  Future<void> _handlePrimaryAction() async {
    switch (_currentIndex) {
      case 0:
        if (!_hasFile) {
          _showBlockedStepMessage(1);
          return;
        }

        _goToStep(1);
        return;

      case 1:
        if (!_hasPreview) {
          _showBlockedStepMessage(2);
          return;
        }

        _goToStep(2);
        return;

      case 2:
        if (!_hasMappings) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Dodaj przynajmniej jedno mapowanie przed startem importu.'.tr,
              ),
            ),
          );
          return;
        }

        final importFuture = widget.formNotifier.submitBatch(ref);

        // Dajemy providerowi jedną klatkę na ustawienie isBatchRunning=true,
        // żeby overlay od razu pokazał live progress.
        await Future<void>.delayed(const Duration(milliseconds: 80));

        BatchImportOverlayResult? overlayResult;

        if (mounted) {
          overlayResult = await showBatchImportOverlay(context);
        }

        await importFuture;

        final newState = ref.read(importFormProvider);

        if (!mounted) return;

        if (overlayResult?.action == BatchImportOverlayAction.showRowInEditor) {
          _jumpToEditorRow(overlayResult!.previewRowIndex);
          return;
        }

        if (newState.error == null) {
          ref.invalidate(importJobsProvider);
          _goToStep(3);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(newState.error!)),
          );
        }

        return;

      case 3:
        final state = ref.read(importFormProvider);

        if (state.batchResults.isNotEmpty || state.isBatchRunning) {
          await _openBatchOverlayAndHandleResult();
          return;
        }

        ref.invalidate(importJobsProvider);
        return;
    }
  }

  void _handleSecondaryAction() {
    if (_currentIndex == 3) {
      widget.formNotifier.setFile(null);
      _goToStep(0);
      return;
    }

    if (_currentIndex > 0) {
      _goToStep(_currentIndex - 1);
    }
  }

  String _primaryButtonLabel() {
    switch (_currentIndex) {
      case 0:
        return 'Dalej: edytor'.tr;
      case 1:
        return 'Dalej: mapper'.tr;
      case 2:
        return widget.formState.isSubmitting || widget.formState.isBatchRunning
            ? 'Importowanie...'.tr
            : 'Uruchom import'.tr;
      case 3:
        return widget.formState.batchResults.isNotEmpty
            ? 'Pokaż wynik'.tr
            : 'Odśwież wynik'.tr;
      default:
        return 'Dalej'.tr;
    }
  }

  String? _secondaryButtonLabel() {
    if (_currentIndex == 0) return null;
    if (_currentIndex == 3) return 'Nowy import'.tr;
    return 'Wstecz'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final activeStep = _importSteps[_currentIndex];
    final formError = widget.formState.error;
    final lastMessage = widget.formState.lastMessage;


    final editorPagination = _editorPaginationState;

    final previousEditorPage = editorPagination != null &&
            editorPagination.currentPage > 0
        ? () {
            widget.formNotifier.setPage(editorPagination.currentPage - 1);
          }
        : null;

    final nextEditorPage = editorPagination != null &&
            editorPagination.currentPage < editorPagination.totalPages - 1
        ? () {
            widget.formNotifier.setPage(editorPagination.currentPage + 1);
          }
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Text(
            'Import danych'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Załaduj plik, przygotuj dane, przypisz pola i uruchom import.'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(204),
            ),
          ),
          const SizedBox(height: 16),
        ],
        EmmaUiAnchorTarget(
          // @emma-backend: ImporterEmmaAnchors.importDataHeader
          anchorKey: 'importer.data.header',
          child: _ImportUnifiedHeader(
            theme: theme,
            currentIndex: _currentIndex,
            activeStep: activeStep,
            isCompact: _isCompact,
            hasFile: _hasFile,
            hasPreview: _hasPreview,
            hasMappings: _hasMappings,
            previewRowsCount: _previewRowsCount,
            previewColumnsCount: _previewColumnsCount,
            mappedCount: _mappedCount,
            isSubmitting:
                widget.formState.isSubmitting || widget.formState.isBatchRunning,
            isStepCompleted: _isStepCompleted,
            isStepLocked: _isStepLocked,
            blockedReasonForStep: _blockedReasonForStep,
            onStepTap: _goToStep,
          ),
        ),
        if ((formError?.trim().isNotEmpty ?? false) ||
            (lastMessage?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 10),
          _ImportInlineBanner(
            theme: theme,
            message: formError?.trim().isNotEmpty == true
                ? formError!
                : lastMessage!,
            isError: formError?.trim().isNotEmpty == true,
            onDismiss: formError?.trim().isNotEmpty == true
                ? null
                : () => widget.formNotifier.clearMessages(),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: EmmaUiAnchorTarget(
            // @emma-backend: ImporterEmmaAnchors.importDataContent
            anchorKey: 'importer.data.content',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ImportTabUpload(
                    optionsAsync: widget.optionsAsync,
                    formState: widget.formState,
                    formNotifier: widget.formNotifier,
                    isTablet: widget.isTablet,
                  ),
                  ImportTabEditor(
                    optionsAsync: widget.optionsAsync,
                    formState: widget.formState,
                    formNotifier: widget.formNotifier,
                    onPaginationChanged: _handleEditorPaginationChanged,
                    isTablet: widget.isTablet,
                  ),
                  ImportTabFieldMapper(
                    optionsAsync: widget.optionsAsync,
                    formState: widget.formState,
                    formNotifier: widget.formNotifier,
                    isTablet: widget.isTablet,
                  ),
                  ImportTabJobs(
                    jobsAsync: widget.jobsAsync,
                  ),
                ],
              ),
            ),
          ),
        ),
        EmmaUiAnchorTarget(
          // @emma-backend: ImporterEmmaAnchors.importDataBottomActions
          anchorKey: 'importer.data.bottom_actions',
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isCompact ? 12 : 16,
              vertical: 8,
            ),
            child: _ImportBottomContextActions(
              isCompact: _isCompact,
              currentIndex: _currentIndex,
              totalSteps: _importSteps.length,
              activeStep: activeStep,
              formState: widget.formState,
              editorPagination: editorPagination,
              onPageSizeChanged: widget.formNotifier.setPageSize,
              onPreviousEditorPage: previousEditorPage,
              onNextEditorPage: nextEditorPage,
              canProceed: _canProceedFromCurrentStep(),
              primaryButtonLabel: _primaryButtonLabel(),
              secondaryButtonLabel: _secondaryButtonLabel(),
              onPrimaryAction: _handlePrimaryAction,
              onSecondaryAction: _handleSecondaryAction,
            ),
          ),
        ),
      ],
    );
  }
}



class _ImportBottomContextActions extends ConsumerWidget {
  final bool isCompact;
  final int currentIndex;
  final int totalSteps;
  final _ImportStepMeta activeStep;
  final ImportFormState formState;
  final ImportEditorPaginationState? editorPagination;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onPreviousEditorPage;
  final VoidCallback? onNextEditorPage;
  final bool canProceed;
  final String primaryButtonLabel;
  final String? secondaryButtonLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  const _ImportBottomContextActions({
    required this.isCompact,
    required this.currentIndex,
    required this.totalSteps,
    required this.activeStep,
    required this.formState,
    required this.editorPagination,
    required this.onPageSizeChanged,
    required this.onPreviousEditorPage,
    required this.onNextEditorPage,
    required this.canProceed,
    required this.primaryButtonLabel,
    required this.secondaryButtonLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  bool get _isBusy => formState.isSubmitting || formState.isBatchRunning;

  bool get _showEditorPagination {
    return currentIndex == 1 && editorPagination != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BottomStepLabel(
            theme: theme,
            currentIndex: currentIndex,
            totalSteps: totalSteps,
            activeStep: activeStep,
          ),
          if (_showEditorPagination) ...[
            const SizedBox(height: 10),
            _ImportEditorPaginationControls(
              theme: theme,
              pagination: editorPagination!,
              onPageSizeChanged: onPageSizeChanged,
              onPreviousPage: onPreviousEditorPage,
              onNextPage: onNextEditorPage,
            ),
          ],
          const SizedBox(height: 10),
          if (secondaryButtonLabel != null) ...[
            EmmaUiAnchorTarget(
              // @emma-backend: ImporterEmmaAnchors.importDataSecondaryAction
              anchorKey: 'importer.data.secondary_action',
              child: OutlinedButton(
                onPressed: _isBusy ? null : onSecondaryAction,
                child: Text(secondaryButtonLabel!, style: TextStyle(color: theme.textColor)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          EmmaUiAnchorTarget(
            // @emma-backend: ImporterEmmaAnchors.importDataPrimaryAction
            anchorKey: 'importer.data.primary_action',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: buttonStyleRounded10ThemeRed,
                  onPressed: canProceed ? onPrimaryAction : null,
                  icon: _isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          currentIndex == 2
                              ? Icons.play_arrow_rounded
                              : currentIndex == 3
                                  ? Icons.fact_check_outlined
                                  : Icons.arrow_forward_rounded,
                        ),
                  label: Text(primaryButtonLabel, style: TextStyle(color: theme.textColor)),
                ),
                if (currentIndex == 2 && !canProceed && !_isBusy)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Dodaj przynajmniej jedno mapowanie.'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orangeAccent.withAlpha(200),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _BottomStepLabel(
          theme: theme,
          currentIndex: currentIndex,
          totalSteps: totalSteps,
          activeStep: activeStep,
        ),
        if (_showEditorPagination) ...[
          const SizedBox(width: 18),
          Flexible(
            child: Align(
              alignment: Alignment.center,
              child: _ImportEditorPaginationControls(
                theme: theme,
                pagination: editorPagination!,
                onPageSizeChanged: onPageSizeChanged,
                onPreviousPage: onPreviousEditorPage,
                onNextPage: onNextEditorPage,
              ),
            ),
          ),
        ] else
          const Spacer(),
        if (secondaryButtonLabel != null) ...[
          OutlinedButton(
            onPressed: _isBusy ? null : onSecondaryAction,
            child: Text(
              secondaryButtonLabel!,
              style: TextStyle(color: theme.textColor),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: canProceed ? onPrimaryAction : null,
              icon: _isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      currentIndex == 2
                          ? Icons.play_arrow_rounded
                          : currentIndex == 3
                              ? Icons.fact_check_outlined
                              : Icons.arrow_forward_rounded,
                      color: theme.textColor,
                    ),
              label: Text(
                primaryButtonLabel,
                style: TextStyle(color: theme.textColor),
              ),
            ),
            if (currentIndex == 2 && !canProceed && !_isBusy)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Dodaj przynajmniej jedno mapowanie.'.tr,
                  style: TextStyle(
                    color: Colors.orangeAccent.withAlpha(200),
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BottomStepLabel extends StatelessWidget {
  final ThemeColors theme;
  final int currentIndex;
  final int totalSteps;
  final _ImportStepMeta activeStep;

  const _BottomStepLabel({
    required this.theme,
    required this.currentIndex,
    required this.totalSteps,
    required this.activeStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.flag_circle_rounded,
          size: 16,
          color: theme.themeColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Krok ${currentIndex + 1}/$totalSteps'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(190),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.themeColor.withAlpha(20),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.themeColor.withAlpha(70)),
          ),
          child: Text(
            activeStep.shortLabel.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportEditorPaginationControls extends StatelessWidget {
  final ThemeColors theme;
  final ImportEditorPaginationState pagination;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const _ImportEditorPaginationControls({
    required this.theme,
    required this.pagination,
    required this.onPageSizeChanged,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final pageSizes = <int>{
      50,
      100,
      200,
      500,
      pagination.pageSize,
    }.toList()
      ..sort();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Wiersze: ${pagination.totalRows} • Strona ${pagination.currentPage + 1} / ${pagination.totalPages}'
              .tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(178),
            fontSize: 11,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Na stronę:'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(178),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            DropdownButton<int>(
              value: pagination.pageSize,
              dropdownColor: theme.dashboardContainer,
              items: pageSizes
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        '$v',
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  onPageSizeChanged(v);
                }
              },
            ),
          ],
        ),
        IconButton(
          onPressed: onPreviousPage,
          icon: Icon(
            Icons.chevron_left_rounded,
            color: theme.textColor,
          ),
          tooltip: 'Poprzednia strona'.tr,
        ),
        IconButton(
          onPressed: onNextPage,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: theme.textColor,
          ),
          tooltip: 'Następna strona'.tr,
        ),
      ],
    );
  }
}

class _ImportUnifiedHeader extends StatelessWidget {
  final ThemeColors theme;
  final int currentIndex;
  final _ImportStepMeta activeStep;
  final bool isCompact;
  final bool hasFile;
  final bool hasPreview;
  final bool hasMappings;
  final int previewRowsCount;
  final int previewColumnsCount;
  final int mappedCount;
  final bool isSubmitting;
  final bool Function(int index) isStepCompleted;
  final bool Function(int index) isStepLocked;
  final String Function(int index) blockedReasonForStep;
  final ValueChanged<int> onStepTap;

  const _ImportUnifiedHeader({
    required this.theme,
    required this.currentIndex,
    required this.activeStep,
    required this.isCompact,
    required this.hasFile,
    required this.hasPreview,
    required this.hasMappings,
    required this.previewRowsCount,
    required this.previewColumnsCount,
    required this.mappedCount,
    required this.isSubmitting,
    required this.isStepCompleted,
    required this.isStepLocked,
    required this.blockedReasonForStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    // final progress = (currentIndex + 1) / _importSteps.length;
    // final progressPercent = (progress * 100).round();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        // vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: TopAppBarSize.resolve(context) +6),
          _buildStepsRow(),
          // const SizedBox(height: 6),
          // _buildBottomInfoRow(progressPercent),
        ],
      ),
    );
  }


  String _stepAnchorKey(int index) {
    switch (index) {
      case 0:
        return 'importer.data.step.file';
      case 1:
        return 'importer.data.step.editor';
      case 2:
        return 'importer.data.step.mapper';
      case 3:
        return 'importer.data.step.jobs';
      default:
        return 'importer.data.step.unknown';
    }
  }

  Widget _buildStepsRow() {
    if (isCompact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            _importSteps.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                right: index == _importSteps.length - 1 ? 0 : 8,
              ),
              child: EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importDataStepFile / importDataStepEditor / importDataStepMapper / importDataStepJobs
                anchorKey: _stepAnchorKey(index),
                child: Tooltip(
                  message: isStepLocked(index) ? blockedReasonForStep(index) : '',
                  child: _ImportStepCard(
                    theme: theme,
                    index: index,
                    meta: _importSteps[index],
                    isCompact: isCompact,
                    isActive: currentIndex == index,
                    isDone: isStepCompleted(index),
                    isLocked: isStepLocked(index),
                    onTap: () => onStepTap(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: List.generate(
        _importSteps.length,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == _importSteps.length - 1 ? 0 : 8,
            ),
            child: EmmaUiAnchorTarget(
              anchorKey: _stepAnchorKey(index),
              child: Tooltip(
                message: isStepLocked(index) ? blockedReasonForStep(index) : '',
                child: _ImportStepCard(
                  theme: theme,
                  index: index,
                  meta: _importSteps[index],
                  isCompact: false,
                  isActive: currentIndex == index,
                  isDone: isStepCompleted(index),
                  isLocked: isStepLocked(index),
                  onTap: () => onStepTap(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _ImportStepCard extends StatelessWidget {
  final ThemeColors theme;
  final int index;
  final _ImportStepMeta meta;
  final bool isCompact;
  final bool isActive;
  final bool isDone;
  final bool isLocked;
  final VoidCallback onTap;

  const _ImportStepCard({
    required this.theme,
    required this.index,
    required this.meta,
    required this.isCompact,
    required this.isActive,
    required this.isDone,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? theme.themeColor
        : isDone
            ? Colors.greenAccent.withAlpha(100)
            : theme.dashboardBoarder.withAlpha(120);

    final bgColor = isActive
        ? theme.themeColor.withAlpha(14)
        : Colors.black.withAlpha(10);

    final iconColor = isDone
        ? Colors.greenAccent.shade400
        : isLocked
            ? theme.textColor.withAlpha(105)
            : isActive
                ? theme.themeColor
                : theme.textColor.withAlpha(165);

    final icon = isDone
        ? Icons.check_circle_rounded
        : isLocked
            ? Icons.lock_outline_rounded
            : Icons.radio_button_unchecked_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: isCompact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: isCompact
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepIndexDot(
                      theme: theme,
                      index: index,
                      isActive: isActive,
                      isDone: isDone,
                      isLocked: isLocked,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meta.shortLabel.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 13, color: iconColor),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StepIndexDot(
                          theme: theme,
                          index: index,
                          isActive: isActive,
                          isDone: isDone,
                          isLocked: isLocked,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meta.shortLabel.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(icon, size: 13, color: iconColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.title.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(150),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StepIndexDot extends StatelessWidget {
  final ThemeColors theme;
  final int index;
  final bool isActive;
  final bool isDone;
  final bool isLocked;

  const _StepIndexDot({
    required this.theme,
    required this.index,
    required this.isActive,
    required this.isDone,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? theme.themeColor
        : isDone
            ? Colors.greenAccent.withAlpha(120)
            : theme.dashboardBoarder.withAlpha(135);

    final bgColor = isActive
        ? theme.themeColor.withAlpha(20)
        : isDone
            ? Colors.greenAccent.withAlpha(14)
            : Colors.transparent;

    final textColor = isDone
        ? Colors.greenAccent.shade400
        : isLocked
            ? theme.textColor.withAlpha(115)
            : isActive
                ? theme.themeColor
                : theme.textColor.withAlpha(170);

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ImportInlineBanner extends StatelessWidget {
  final ThemeColors theme;
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const _ImportInlineBanner({
    required this.theme,
    required this.message,
    required this.isError,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isError ? Colors.redAccent : Colors.greenAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? Colors.redAccent.withAlpha(18)
            : Colors.greenAccent.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: theme.textColor.withAlpha(150),
              ),
            ),
          ],
        ],
      ),
    );
  }
}