import 'dart:async';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/models/document.dart';
import 'package:docs/models/document_temp.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/widgets/delete_confirmation_dialog.dart';
import 'package:docs/widgets/desktop/create_template_dialog.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

enum DocsLibraryTab {
  documents,
  templates,
}

enum DocsLibraryViewMode {
  grid,
  list,
}

/// Shared across the (desktop/tablet) inline header and the mobile floating
/// [DocsVerticalBarMobile], which lives outside the [DocsLibraryConnectedView]
/// subtree as a BarManager sibling and can't reach its local State.
final docsSelectedTabProvider =
    StateProvider<DocsLibraryTab>((ref) => DocsLibraryTab.documents);

final docsViewModeProvider =
    StateProvider<DocsLibraryViewMode>((ref) => DocsLibraryViewMode.grid);

final docsIsCreatingDocumentProvider = StateProvider<bool>((ref) => false);

final docsIsCreatingTemplateProvider = StateProvider<bool>((ref) => false);

final docsErrorProvider = StateProvider<String?>((ref) => null);

/// Creation/navigation logic shared between the inline (desktop/tablet)
/// header buttons and [DocsVerticalBarMobile], which lives outside
/// [DocsLibraryConnectedView]'s State and can't call its instance methods.
void docsOpenDocument(
  WidgetRef ref,
  String documentEditorRoute,
  String documentId,
) {
  ref.read(navigationService).pushNamedScreen(
    documentEditorRoute,
    data: {
      'documentId': documentId,
      'mode': 'edit_document',
    },
  );
}

void docsOpenTemplateEditor(
  WidgetRef ref,
  String documentEditorRoute,
  DocumentTemplate template,
) {
  ref.read(navigationService).pushNamedScreen(
    documentEditorRoute,
    data: {
      'templateId': template.id.toString(),
      'template': template,
      'mode': 'template_edit',
      'isEditingTemplate': true,
    },
  );
}

Future<void> docsCreateBlankDocument(
  BuildContext context,
  WidgetRef ref,
  String documentEditorRoute,
) async {
  if (ref.read(docsIsCreatingDocumentProvider)) return;

  ref.read(docsIsCreatingDocumentProvider.notifier).state = true;
  ref.read(docsErrorProvider.notifier).state = null;

  try {
    final templates = await DocumentService.getTemplates(ref);
    final defaultTemplateId = templates.isNotEmpty ? templates.first.id : null;

    final document = await DocumentService.createDocument(
      templateId: defaultTemplateId,
      title: 'Untitled Document',
      currentDelta: {
        'ops': [
          {'insert': '\n'},
        ],
      },
      currentStyle: {},
      ref: ref,
    );

    if (!context.mounted) return;

    ref.read(documentProvider.notifier).setDocument(document);
    docsOpenDocument(ref, documentEditorRoute, document.id);
  } catch (e) {
    if (!context.mounted) return;
    ref.read(docsErrorProvider.notifier).state = e.toString();
  } finally {
    if (context.mounted) {
      ref.read(docsIsCreatingDocumentProvider.notifier).state = false;
    }
  }
}

Future<void> docsCreateTemplate(
  BuildContext context,
  WidgetRef ref,
  String documentEditorRoute,
) async {
  if (ref.read(docsIsCreatingTemplateProvider)) return;

  ref.read(docsIsCreatingTemplateProvider.notifier).state = true;
  ref.read(docsErrorProvider.notifier).state = null;

  try {
    final templateMap = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => const CreateTemplateDialog(),
    );

    if (!context.mounted || templateMap == null) return;

    final template = templateMap['template'] as DocumentTemplate?;
    if (template == null) return;

    final freshTemplate =
        await DocumentService.getTemplate(template.id.toString(), ref);

    if (!context.mounted) return;

    docsOpenTemplateEditor(ref, documentEditorRoute, freshTemplate);
  } catch (e) {
    if (!context.mounted) return;
    ref.read(docsErrorProvider.notifier).state = e.toString();
  } finally {
    if (context.mounted) {
      ref.read(docsIsCreatingTemplateProvider.notifier).state = false;
    }
  }
}

Future<void> docsCreateDocumentFromTemplate(
  BuildContext context,
  WidgetRef ref,
  String documentEditorRoute,
  DocumentTemplate template,
) async {
  if (ref.read(docsIsCreatingDocumentProvider)) return;

  ref.read(docsIsCreatingDocumentProvider.notifier).state = true;
  ref.read(docsErrorProvider.notifier).state = null;

  try {
    final freshTemplate =
        await DocumentService.getTemplate(template.id.toString(), ref);

    final document = await DocumentService.createDocument(
      templateId: freshTemplate.id,
      title: 'New ${freshTemplate.name}',
      currentDelta: freshTemplate.deltaJson,
      currentStyle: freshTemplate.styleJson,
      ref: ref,
    );

    if (!context.mounted) return;

    ref.read(documentProvider.notifier).setDocument(document);
    docsOpenDocument(ref, documentEditorRoute, document.id);
  } catch (e) {
    if (!context.mounted) return;
    ref.read(docsErrorProvider.notifier).state = e.toString();
  } finally {
    if (context.mounted) {
      ref.read(docsIsCreatingDocumentProvider.notifier).state = false;
    }
  }
}

Future<void> docsEditTemplate(
  BuildContext context,
  WidgetRef ref,
  String documentEditorRoute,
  DocumentTemplate template,
) async {
  ref.read(docsErrorProvider.notifier).state = null;

  try {
    final freshTemplate =
        await DocumentService.getTemplate(template.id.toString(), ref);

    if (!context.mounted) return;

    docsOpenTemplateEditor(ref, documentEditorRoute, freshTemplate);
  } catch (e) {
    if (!context.mounted) return;
    ref.read(docsErrorProvider.notifier).state = e.toString();
  }
}

/// Creates a document or template depending on the active tab — used by the
/// mobile floating "new" button, mirroring the inline header's primary action.
Future<void> docsCreateForActiveTab(
  BuildContext context,
  WidgetRef ref,
  String documentEditorRoute,
) {
  final selectedTab = ref.read(docsSelectedTabProvider);

  return selectedTab == DocsLibraryTab.templates
      ? docsCreateTemplate(context, ref, documentEditorRoute)
      : docsCreateBlankDocument(context, ref, documentEditorRoute);
}

Map<String, dynamic> _docsSetNullableFilterValue(
  Map<String, dynamic> state,
  String key,
  dynamic value,
) {
  final next = Map<String, dynamic>.from(state);

  if (value == null || value.toString().trim().isEmpty) {
    next.remove(key);
  } else {
    next[key] = value;
  }

  return next;
}

void docsSetDocumentFilter(WidgetRef ref, String key, dynamic value) {
  ref.read(documentFiltersProvider.notifier).update(
        (state) => _docsSetNullableFilterValue(state, key, value),
      );
}

void docsSetTemplateFilter(WidgetRef ref, String key, dynamic value) {
  ref.read(templateFiltersProvider.notifier).update(
        (state) => _docsSetNullableFilterValue(state, key, value),
      );
}

class DocsLibraryScreen extends ConsumerWidget {
  final DocsLibraryTab initialTab;
  final String title;

  /// Podmień na swoje route name, np. Routes.documentEditor.
  final String documentEditorRoute;

  /// Podmień na swoje route name, np. Routes.templateFill.
  final String templateFillRoute;

  DocsLibraryScreen({
    super.key,
    this.initialTab = DocsLibraryTab.documents,
    this.title = 'Dokumenty',
    this.documentEditorRoute = '/docs/editor',
    this.templateFillRoute = '/docs/templates/fill',
  });

  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      isChildExpanded: true,
      enableScrool: false,
      isTopAppBarHoveroverUI: false,
      isTopAppBarOff: true,
      isBottomBarOff: true,
      isTopAppBarOffMobile: false,
      layoutTypePc: LayoutTypePc.stack,
      layoutTypeTablet: LayoutTypeTablet.stack,
      layoutTypeMobile: LayoutTypeMobile.stack,
      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      // Only float over the mobile shell — the desktop/tablet layouts already
      // show filters/view-toggle/create inline in the header.
      verticalButtonsPc: const SizedBox.shrink(),
      verticalButtons: DocsVerticalBarMobile(
        documentEditorRoute: documentEditorRoute,
      ),
      childPc: DocsLibraryConnectedView(
        initialTab: initialTab,
        title: title,
        documentEditorRoute: documentEditorRoute,
        templateFillRoute: templateFillRoute,
      ),
      childTablet: DocsLibraryConnectedView(
        initialTab: initialTab,
        title: title,
        documentEditorRoute: documentEditorRoute,
        templateFillRoute: templateFillRoute,
      ),
      childMobile: Builder(
        builder: (context) {
          final topPadding = TopAppBarSize.resolve(context);
          return Column(
            children: [
              SizedBox(height: topPadding),
              Expanded(
                child: DocsLibraryConnectedView(
                  initialTab: initialTab,
                  title: title,
                  documentEditorRoute: documentEditorRoute,
                  templateFillRoute: templateFillRoute,
                  isMobileShell: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DocsLibraryConnectedView extends ConsumerStatefulWidget {
  final DocsLibraryTab initialTab;
  final String title;
  final String documentEditorRoute;
  final String templateFillRoute;
  final bool isMobileShell;

  const DocsLibraryConnectedView({
    super.key,
    required this.initialTab,
    required this.title,
    required this.documentEditorRoute,
    required this.templateFillRoute,
    this.isMobileShell = false,
  });

  @override
  ConsumerState<DocsLibraryConnectedView> createState() =>
      _DocsLibraryConnectedViewState();
}

class _DocsLibraryConnectedViewState
    extends ConsumerState<DocsLibraryConnectedView> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  bool _filtersExpanded = false;

  String _search = '';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(docsSelectedTabProvider.notifier).state = widget.initialTab;
      ref.read(documentFiltersProvider.notifier).state = {};
      ref.read(templateFiltersProvider.notifier).state = {};
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(documentsProvider);
    ref.invalidate(documentTemplatesProvider);
  }

  Map<String, dynamic> _setNullableFilterValue(
    Map<String, dynamic> state,
    String key,
    dynamic value,
  ) {
    final next = Map<String, dynamic>.from(state);

    if (value == null || value.toString().trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }

    return next;
  }

  void _setDocumentFilter(String key, dynamic value) {
    ref.read(documentFiltersProvider.notifier).update(
          (state) => _setNullableFilterValue(state, key, value),
        );
  }

  void _setTemplateFilter(String key, dynamic value) {
    ref.read(templateFiltersProvider.notifier).update(
          (state) => _setNullableFilterValue(state, key, value),
        );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _search = value;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      final clean = value.trim();

      if (ref.read(docsSelectedTabProvider) == DocsLibraryTab.documents) {
        _setDocumentFilter('search', clean);
      } else {
        _setTemplateFilter('search', clean);
      }
    });
  }

  void _clearSearchOnly() {
    _searchDebounce?.cancel();

    setState(() {
      _search = '';
      _searchController.clear();
    });

    _setDocumentFilter('search', null);
    _setTemplateFilter('search', null);
  }

  void _clearAllFilters() {
    _searchDebounce?.cancel();

    setState(() {
      _search = '';
      _searchController.clear();
    });

    ref.read(documentFiltersProvider.notifier).state = {};
    ref.read(templateFiltersProvider.notifier).state = {};
  }

  Future<void> _createBlankDocument() =>
      docsCreateBlankDocument(context, ref, widget.documentEditorRoute);

  Future<void> _createTemplate() =>
      docsCreateTemplate(context, ref, widget.documentEditorRoute);

  Future<void> _createDocumentFromTemplate(DocumentTemplate template) =>
      docsCreateDocumentFromTemplate(
        context,
        ref,
        widget.documentEditorRoute,
        template,
      );

  Future<void> _editTemplate(DocumentTemplate template) =>
      docsEditTemplate(context, ref, widget.documentEditorRoute, template);

  void _openDocument(String documentId) =>
      docsOpenDocument(ref, widget.documentEditorRoute, documentId);

  void _openTemplateFill(DocumentTemplate template) {
    ref.read(navigationService).pushNamedScreen(
      widget.templateFillRoute,
      data: {
        'templateId': template.id.toString(),
        'template': template,
      },
    );
  }

  void _setFinalizedOnly(bool selected) {
    _setDocumentFilter('is_finalized', selected ? 'true' : null);
  }

  void _setGlobalTemplatesOnly(bool selected) {
    _setTemplateFilter('is_global', selected ? 'true' : null);
  }

  void _setDocumentStatus(String? status) {
    _setDocumentFilter('status', status);
  }

  void _setDocumentOrdering(String? ordering) {
    _setDocumentFilter('ordering', ordering);
  }

  void _setTemplateOrdering(String? ordering) {
    _setTemplateFilter('ordering', ordering);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Brak daty';

    return DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal());
  }

  String _documentStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Szkic';
      case 'in_progress':
        return 'W trakcie';
      case 'to_sign':
        return 'Do podpisu';
      case 'finalized':
        return 'Gotowy';
      case 'sent':
        return 'Wysłany';
      case 'signed':
        return 'Podpisany';
      case 'archived':
        return 'Archiwum';
      default:
        return status;
    }
  }

  String _templateScopeLabel(DocumentTemplate template) {
    final map = template.toString().toLowerCase();

    if (map.contains('global')) {
      return 'Globalny';
    }

    return 'Prywatny';
  }

  List<Documents> _filterDocuments(List<Documents> documents) {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return documents;

    return documents.where((document) {
      final title = document.title.toLowerCase();
      final templateName = document.templateName.toLowerCase();
      final status = document.status.toLowerCase();
      final id = document.id.toLowerCase();

      return title.contains(query) ||
          templateName.contains(query) ||
          status.contains(query) ||
          id.contains(query);
    }).toList();
  }

  List<DocumentTemplate> _filterTemplates(List<DocumentTemplate> templates) {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return templates;

    return templates.where((template) {
      final name = template.name.toLowerCase();
      final description = template.description.toLowerCase();
      final owner = (template.ownerUsername ?? '').toLowerCase();
      final id = template.id.toString().toLowerCase();

      return name.contains(query) ||
          description.contains(query) ||
          owner.contains(query) ||
          id.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final documentFilters = ref.watch(documentFiltersProvider);
    final templateFilters = ref.watch(templateFiltersProvider);

    final documentsAsync = ref.watch(documentsProvider(documentFilters));
    final templatesAsync = ref.watch(documentTemplatesProvider(templateFilters));

    final documentsCount = documentsAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => null,
    );

    final templatesCount = templatesAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => null,
    );

    final selectedTab = ref.watch(docsSelectedTabProvider);
    final viewMode = ref.watch(docsViewModeProvider);
    final isCreatingDocument = ref.watch(docsIsCreatingDocumentProvider);
    final isCreatingTemplate = ref.watch(docsIsCreatingTemplateProvider);
    final error = ref.watch(docsErrorProvider);

    final baseTheme = Theme.of(context);

    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.createDocumentDialog.anchorKey,

      spec: DocsEmmaAnchors.createDocumentDialog,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Theme(
        data: baseTheme.copyWith(
          scaffoldBackgroundColor: theme.dashboardContainer,
          textTheme: baseTheme.textTheme.apply(
            bodyColor: theme.textColor,
            displayColor: theme.textColor,
          ),
          iconTheme: IconThemeData(color: theme.textColor),
          popupMenuTheme: PopupMenuThemeData(
            color: theme.dashboardContainer,
            textStyle: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: Container(
          color: theme.dashboardContainer,
          child: SafeArea(
            child: Builder(
              builder: (context) {
                final header = _DocsLibraryHeader(
                  title: widget.title,
                  selectedTab: selectedTab,
                  documentsCount: documentsCount,
                  templatesCount: templatesCount,
                  isCreatingDocument: isCreatingDocument,
                  isCreatingTemplate: isCreatingTemplate,
                  showCreateAction: !widget.isMobileShell,
                  onCreateDocument: _createBlankDocument,
                  onCreateTemplate: _createTemplate,
                  onRefresh: _refresh,
                );

                final filterBar = Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: EmmaUiAnchorTarget(
                    anchorKey: DocsEmmaAnchors.documentFilterBar.anchorKey,
                    spec: DocsEmmaAnchors.documentFilterBar,
                    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                    tapMode: EmmaUiAnchorTapMode.disabled,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 540;

                        final tabs = _DocsLibraryTabs(
                          selectedTab: selectedTab,
                          onChanged: (tab) {
                            _clearSearchOnly();
                            ref.read(docsSelectedTabProvider.notifier).state =
                                tab;
                          },
                        );

                        final searchAndFilters = _DocsSearchAndFilters(
                          controller: _searchController,
                          selectedTab: selectedTab,
                          viewMode: viewMode,
                          filtersExpanded: _filtersExpanded,
                          documentFilters: documentFilters,
                          templateFilters: templateFilters,
                          showFilterControls: !widget.isMobileShell,
                          onViewModeChanged: (mode) {
                            ref.read(docsViewModeProvider.notifier).state =
                                mode;
                          },
                          onToggleFiltersExpanded: () {
                            setState(() {
                              _filtersExpanded = !_filtersExpanded;
                            });
                          },
                          onSearchChanged: _onSearchChanged,
                          onFinalizedOnlyChanged: _setFinalizedOnly,
                          onGlobalTemplatesOnlyChanged: _setGlobalTemplatesOnly,
                          onDocumentStatusChanged: _setDocumentStatus,
                          onDocumentOrderingChanged: _setDocumentOrdering,
                          onTemplateOrderingChanged: _setTemplateOrdering,
                          onClearFilters: _clearAllFilters,
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              tabs,
                              const SizedBox(height: 10),
                              searchAndFilters,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: tabs),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: searchAndFilters),
                          ],
                        );
                      },
                    ),
                  ),
                );

                final errorBanner = error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _DocsLibraryError(
                          error: error,
                          onClose: () {
                            ref.read(docsErrorProvider.notifier).state = null;
                          },
                        ),
                      );

                final body = AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selectedTab == DocsLibraryTab.documents
                      ? _buildDocumentsView(
                          key: const ValueKey('documents'),
                          documentsAsync: documentsAsync,
                          filters: documentFilters,
                          viewMode: viewMode,
                        )
                      : _buildTemplatesView(
                          key: const ValueKey('templates'),
                          templatesAsync: templatesAsync,
                          filters: templateFilters,
                          viewMode: viewMode,
                        ),
                );

                if (widget.isMobileShell) {
                  // The whole page scrolls together on mobile: header, tabs,
                  // search and the list/grid share one scroll position instead
                  // of pinning the header and only scrolling the list.
                  return NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(child: header),
                      SliverToBoxAdapter(child: filterBar),
                      if (error != null) SliverToBoxAdapter(child: errorBanner),
                    ],
                    body: body,
                  );
                }

                return Column(
                  children: [
                    header,
                    filterBar,
                    errorBanner,
                    Expanded(child: body),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsView({
    required Key key,
    required AsyncValue<List<Documents>> documentsAsync,
    required Map<String, dynamic> filters,
    required DocsLibraryViewMode viewMode,
  }) {
    return documentsAsync.when(
      loading: () => Center(child: AppLottie.loading(size: 320)),
      error: (error, _) => _DocsEmptyState(
        key: key,
        icon: Icons.error_outline,
        title: 'Nie udało się pobrać dokumentów',
        description: error.toString(),
        primaryLabel: 'Odśwież',
        onPrimary: _refresh,
      ),
      data: (documents) {
        final filtered = _filterDocuments(documents);
        final hasSearch = _search.trim().isNotEmpty;
        final hasFilters = filters.isNotEmpty;

        if (filtered.isEmpty) {
          return _DocsEmptyState(
            key: key,
            icon: hasSearch || hasFilters
                ? Icons.search_off
                : Icons.description_outlined,
            title: hasSearch || hasFilters
                ? 'Nie znaleziono dokumentów'
                : 'Nie masz jeszcze dokumentów',
            description: hasSearch || hasFilters
                ? 'Zmień wyszukiwanie albo wyczyść filtry.'
                : 'Utwórz pierwszy dokument albo wybierz template i wygeneruj dokument.',
            primaryLabel:
                hasSearch || hasFilters ? 'Wyczyść filtry' : 'Nowy dokument',
            secondaryLabel: 'Odśwież',
            onPrimary:
                hasSearch || hasFilters ? _clearAllFilters : _createBlankDocument,
            onSecondary: _refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (viewMode == DocsLibraryViewMode.list) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final document = filtered[index];

                    return EmmaUiAnchorTarget(
                      anchorKey:
                          '${DocsEmmaAnchors.documentListItem.anchorKey}_${document.id}',
                      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                      child: _DocumentListTile(
                        document: document,
                        statusLabel: _documentStatusLabel(document.status),
                        updatedAtLabel: _formatDate(document.updatedAt),
                        createdAtLabel: _formatDate(document.createdAt),
                        onTap: () => _openDocument(document.id),
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (context) => DeleteConfirmationDialog(
                              itemType: 'document',
                              itemId: document.id,
                              itemName: document.title,
                              onDeleted: () {
                                ref.invalidate(documentsProvider);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }

              final width = constraints.maxWidth;

              final crossAxisCount = width >= 1280
                  ? 4
                  : width >= 940
                      ? 3
                      : width >= 620
                          ? 2
                          : 1;

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: crossAxisCount == 1 ? 1.55 : 1.42,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final document = filtered[index];

                  return EmmaUiAnchorTarget(
                    anchorKey:
                        '${DocsEmmaAnchors.documentListItem.anchorKey}_${document.id}',
                    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: _DocumentCard(
                      document: document,
                      statusLabel: _documentStatusLabel(document.status),
                      updatedAtLabel: _formatDate(document.updatedAt),
                      createdAtLabel: _formatDate(document.createdAt),
                      onTap: () => _openDocument(document.id),
                      onDelete: () {
                        showDialog(
                          context: context,
                          builder: (context) => DeleteConfirmationDialog(
                            itemType: 'document',
                            itemId: document.id,
                            itemName: document.title,
                            onDeleted: () {
                              ref.invalidate(documentsProvider);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTemplatesView({
    required Key key,
    required AsyncValue<List<DocumentTemplate>> templatesAsync,
    required Map<String, dynamic> filters,
    required DocsLibraryViewMode viewMode,
  }) {
    return templatesAsync.when(
      loading: () => Center(child: AppLottie.loading(size: 320)),
      error: (error, _) => _DocsEmptyState(
        key: key,
        icon: Icons.error_outline,
        title: 'Nie udało się pobrać templatek',
        description: error.toString(),
        primaryLabel: 'Odśwież',
        onPrimary: _refresh,
      ),
      data: (templates) {
        final filtered = _filterTemplates(templates);
        final hasSearch = _search.trim().isNotEmpty;
        final hasFilters = filters.isNotEmpty;

        if (filtered.isEmpty) {
          return _DocsEmptyState(
            key: key,
            icon: hasSearch || hasFilters
                ? Icons.search_off
                : Icons.dashboard_customize_outlined,
            title: hasSearch || hasFilters
                ? 'Nie znaleziono templatek'
                : 'Nie masz jeszcze templatek',
            description: hasSearch || hasFilters
                ? 'Zmień wyszukiwanie albo wyczyść filtry.'
                : 'Utwórz template umowy, formularza lub dokumentu dla klientów.',
            primaryLabel:
                hasSearch || hasFilters ? 'Wyczyść filtry' : 'Nowa template',
            secondaryLabel: 'Odśwież',
            onPrimary: hasSearch || hasFilters ? _clearAllFilters : _createTemplate,
            onSecondary: _refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (viewMode == DocsLibraryViewMode.list) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final template = filtered[index];

                    return EmmaUiAnchorTarget(
                      anchorKey:
                          '${DocsEmmaAnchors.templateListItem.anchorKey}_${template.id}',
                      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                      child: _TemplateListTile(
                        template: template,
                        scopeLabel: _templateScopeLabel(template),
                        createdAtLabel: _formatDate(template.createdAt),
                        updatedAtLabel: _formatDate(template.updatedAt),
                        onFill: () => _openTemplateFill(template),
                        onCreateDocument: () =>
                            _createDocumentFromTemplate(template),
                        onEdit: () => _editTemplate(template),
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (context) => DeleteConfirmationDialog(
                              itemType: 'template',
                              itemId: template.id,
                              itemName: template.name,
                              onDeleted: () {
                                ref.invalidate(documentTemplatesProvider);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }

              final width = constraints.maxWidth;

              final crossAxisCount = width >= 1280
                  ? 4
                  : width >= 940
                      ? 3
                      : width >= 620
                          ? 2
                          : 1;

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: crossAxisCount == 1 ? 1.1 : 1.28,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final template = filtered[index];

                  return EmmaUiAnchorTarget(
                    anchorKey:
                        '${DocsEmmaAnchors.templateListItem.anchorKey}_${template.id}',
                    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: _TemplateCard(
                      template: template,
                      scopeLabel: _templateScopeLabel(template),
                      createdAtLabel: _formatDate(template.createdAt),
                      updatedAtLabel: _formatDate(template.updatedAt),
                      onFill: () => _openTemplateFill(template),
                      onCreateDocument: () => _createDocumentFromTemplate(template),
                      onEdit: () => _editTemplate(template),
                      onDelete: () {
                        showDialog(
                          context: context,
                          builder: (context) => DeleteConfirmationDialog(
                            itemType: 'template',
                            itemId: template.id,
                            itemName: template.name,
                            onDeleted: () {
                              ref.invalidate(documentTemplatesProvider);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _DocsLibraryHeader extends ConsumerWidget {
  final String title;
  final DocsLibraryTab selectedTab;
  final int? documentsCount;
  final int? templatesCount;
  final bool isCreatingDocument;
  final bool isCreatingTemplate;
  final bool showCreateAction;
  final VoidCallback onCreateDocument;
  final VoidCallback onCreateTemplate;
  final VoidCallback onRefresh;

  const _DocsLibraryHeader({
    required this.title,
    required this.selectedTab,
    required this.documentsCount,
    required this.templatesCount,
    required this.isCreatingDocument,
    required this.isCreatingTemplate,
    required this.onCreateDocument,
    required this.onCreateTemplate,
    required this.onRefresh,
    this.showCreateAction = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isTemplateTab = selectedTab == DocsLibraryTab.templates;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final titleSection = Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Icon(
                  isTemplateTab
                      ? Icons.dashboard_customize_outlined
                      : Icons.description_outlined,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Zarządzaj dokumentami, umowami i formularzami dla klientów.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(150),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CountPill(
                label: 'Dokumenty',
                value: documentsCount,
                icon: Icons.description_outlined,
              ),
              _CountPill(
                label: 'Templatki',
                value: templatesCount,
                icon: Icons.dashboard_customize_outlined,
              ),
              _ThemedIconButton(
                tooltip: 'Odśwież',
                icon: Icons.refresh,
                onPressed: onRefresh,
              ),
              if (showCreateAction)
                _PrimaryActionButton(
                  onPressed: isTemplateTab
                      ? isCreatingTemplate
                          ? null
                          : onCreateTemplate
                      : isCreatingDocument
                          ? null
                          : onCreateDocument,
                  icon: isCreatingDocument || isCreatingTemplate
                      ? null
                      : isTemplateTab
                          ? Icons.add_box_outlined
                          : Icons.add,
                  isLoading: isCreatingDocument || isCreatingTemplate,
                  label: isTemplateTab ? 'Nowa template' : 'Nowy dokument',
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSection,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _DocsLibraryTabs extends ConsumerWidget {
  final DocsLibraryTab selectedTab;
  final ValueChanged<DocsLibraryTab> onChanged;

  const _DocsLibraryTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: EmmaUiAnchorTarget(
              anchorKey: DocsEmmaAnchors.documentsTab.anchorKey,

              spec: DocsEmmaAnchors.documentsTab,
              runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
              tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
              child: _TabButton(
                label: 'Moje dokumenty',
                icon: Icons.description_outlined,
                selected: selectedTab == DocsLibraryTab.documents,
                onTap: () => onChanged(DocsLibraryTab.documents),
              ),
            ),
          ),
          Expanded(
            child: EmmaUiAnchorTarget(
              anchorKey: DocsEmmaAnchors.templatesTab.anchorKey,

              spec: DocsEmmaAnchors.templatesTab,
              runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
              tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
              child: _TabButton(
                label: 'Templatki',
                icon: Icons.dashboard_customize_outlined,
                selected: selectedTab == DocsLibraryTab.templates,
                onTap: () => onChanged(DocsLibraryTab.templates),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: selected ? theme.themeColor.withAlpha(35) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? theme.themeColor : theme.textColor.withAlpha(160),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? theme.themeColor
                        : theme.textColor.withAlpha(170),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocsSearchAndFilters extends ConsumerWidget {
  final TextEditingController controller;
  final DocsLibraryTab selectedTab;
  final DocsLibraryViewMode viewMode;
  final bool filtersExpanded;
  final Map<String, dynamic> documentFilters;
  final Map<String, dynamic> templateFilters;
  final ValueChanged<DocsLibraryViewMode> onViewModeChanged;
  final VoidCallback onToggleFiltersExpanded;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onFinalizedOnlyChanged;
  final ValueChanged<bool> onGlobalTemplatesOnlyChanged;
  final ValueChanged<String?> onDocumentStatusChanged;
  final ValueChanged<String?> onDocumentOrderingChanged;
  final ValueChanged<String?> onTemplateOrderingChanged;
  final VoidCallback onClearFilters;
  final bool showFilterControls;

  const _DocsSearchAndFilters({
    required this.controller,
    required this.selectedTab,
    required this.viewMode,
    required this.filtersExpanded,
    required this.documentFilters,
    required this.templateFilters,
    required this.onViewModeChanged,
    required this.onToggleFiltersExpanded,
    required this.onSearchChanged,
    required this.onFinalizedOnlyChanged,
    required this.onGlobalTemplatesOnlyChanged,
    required this.onDocumentStatusChanged,
    required this.onDocumentOrderingChanged,
    required this.onTemplateOrderingChanged,
    required this.onClearFilters,
    this.showFilterControls = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isTemplateTab = selectedTab == DocsLibraryTab.templates;

    final activeFilters = isTemplateTab ? templateFilters : documentFilters;

    final hasFilters = activeFilters.entries.any((entry) {
      final value = entry.value;
      return value != null && value.toString().trim().isNotEmpty;
    });

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 480;

            final search = TextField(
              controller: controller,
              onChanged: onSearchChanged,
              cursorColor: theme.themeColor,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.textColor.withAlpha(160),
                ),
                suffixIcon: controller.text.trim().isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          controller.clear();
                          onSearchChanged('');
                        },
                        icon: Icon(
                          Icons.close,
                          color: theme.textColor.withAlpha(160),
                        ),
                      )
                    : null,
                hintText: isTemplateTab
                    ? 'Szukaj templatek...'
                    : 'Szukaj dokumentów...',
                hintStyle: TextStyle(
                  color: theme.textColor.withAlpha(130),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: theme.dashboardContainer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: theme.dashboardBoarder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: theme.dashboardBoarder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: theme.themeColor, width: 1.2),
                ),
              ),
            );

            if (!showFilterControls) {
              // Filters/view-toggle live in the mobile floating vertical bar
              // instead, so only the search box stays inline here.
              return search;
            }

            final controls = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ViewModeToggle(
                  value: viewMode,
                  onChanged: onViewModeChanged,
                ),
                _SecondaryActionButton(
                  onPressed: onToggleFiltersExpanded,
                  icon: filtersExpanded
                      ? Icons.tune
                      : Icons.filter_alt_outlined,
                  label: filtersExpanded ? 'Ukryj filtry' : 'Więcej filtrów',
                ),
                if (hasFilters)
                  _SecondaryActionButton(
                    onPressed: onClearFilters,
                    icon: Icons.filter_alt_off,
                    label: 'Wyczyść',
                    danger: true,
                  ),
              ],
            );

            if (compact) {
              return Column(
                children: [
                  search,
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: controls,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                controls,
              ],
            );
          },
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: filtersExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _AdvancedFiltersPanel(
              selectedTab: selectedTab,
              documentFilters: documentFilters,
              templateFilters: templateFilters,
              onFinalizedOnlyChanged: onFinalizedOnlyChanged,
              onGlobalTemplatesOnlyChanged: onGlobalTemplatesOnlyChanged,
              onDocumentStatusChanged: onDocumentStatusChanged,
              onDocumentOrderingChanged: onDocumentOrderingChanged,
              onTemplateOrderingChanged: onTemplateOrderingChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvancedFiltersPanel extends ConsumerWidget {
  final DocsLibraryTab selectedTab;
  final Map<String, dynamic> documentFilters;
  final Map<String, dynamic> templateFilters;
  final ValueChanged<bool> onFinalizedOnlyChanged;
  final ValueChanged<bool> onGlobalTemplatesOnlyChanged;
  final ValueChanged<String?> onDocumentStatusChanged;
  final ValueChanged<String?> onDocumentOrderingChanged;
  final ValueChanged<String?> onTemplateOrderingChanged;

  const _AdvancedFiltersPanel({
    required this.selectedTab,
    required this.documentFilters,
    required this.templateFilters,
    required this.onFinalizedOnlyChanged,
    required this.onGlobalTemplatesOnlyChanged,
    required this.onDocumentStatusChanged,
    required this.onDocumentOrderingChanged,
    required this.onTemplateOrderingChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isTemplateTab = selectedTab == DocsLibraryTab.templates;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtry i sortowanie',
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (!isTemplateTab) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterPill(
                  label: 'Wszystkie statusy',
                  selected: (documentFilters['status'] ?? '').toString().isEmpty,
                  onSelected: (_) => onDocumentStatusChanged(null),
                ),
                _FilterPill(
                  label: 'Szkic',
                  selected: documentFilters['status'] == 'draft',
                  onSelected: (_) => onDocumentStatusChanged('draft'),
                ),
                _FilterPill(
                  label: 'W trakcie',
                  selected: documentFilters['status'] == 'in_progress',
                  onSelected: (_) => onDocumentStatusChanged('in_progress'),
                ),
                _FilterPill(
                  label: 'Do podpisu',
                  selected: documentFilters['status'] == 'to_sign',
                  onSelected: (_) => onDocumentStatusChanged('to_sign'),
                ),
                _FilterPill(
                  label: 'Podpisane',
                  selected: documentFilters['status'] == 'signed',
                  onSelected: (_) => onDocumentStatusChanged('signed'),
                ),
                _FilterPill(
                  label: 'Archiwum',
                  selected: documentFilters['status'] == 'archived',
                  onSelected: (_) => onDocumentStatusChanged('archived'),
                ),
                _FilterPill(
                  label: 'Tylko finalne',
                  selected: documentFilters['is_finalized'] == 'true',
                  icon: Icons.verified_outlined,
                  onSelected: onFinalizedOnlyChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ThemedDropdown<String>(
              label: 'Sortowanie',
              value: documentFilters['ordering']?.toString(),
              items: const [
                DropdownMenuItem(
                  value: '-date_updated',
                  child: Text('Ostatnio aktualizowane'),
                ),
                DropdownMenuItem(
                  value: 'date_updated',
                  child: Text('Najdawniej aktualizowane'),
                ),
                DropdownMenuItem(
                  value: '-date_created',
                  child: Text('Najnowsze'),
                ),
                DropdownMenuItem(
                  value: 'date_created',
                  child: Text('Najstarsze'),
                ),
                DropdownMenuItem(
                  value: 'status',
                  child: Text('Status A-Z'),
                ),
                DropdownMenuItem(
                  value: '-status',
                  child: Text('Status Z-A'),
                ),
              ],
              onChanged: onDocumentOrderingChanged,
            ),
          ],
          if (isTemplateTab) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterPill(
                  label: 'Wszystkie templatki',
                  selected: (templateFilters['is_global'] ?? '').toString().isEmpty,
                  onSelected: (_) => onGlobalTemplatesOnlyChanged(false),
                ),
                EmmaUiAnchorTarget(
                  anchorKey: DocsEmmaAnchors.globalTemplatesFilter.anchorKey,

                  spec: DocsEmmaAnchors.globalTemplatesFilter,
                  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                  child: _FilterPill(
                    label: 'Globalne templatki',
                    selected: templateFilters['is_global'] == 'true',
                    icon: Icons.public_outlined,
                    onSelected: onGlobalTemplatesOnlyChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ThemedDropdown<String>(
              label: 'Sortowanie',
              value: templateFilters['ordering']?.toString(),
              items: const [
                DropdownMenuItem(
                  value: 'name',
                  child: Text('Nazwa A-Z'),
                ),
                DropdownMenuItem(
                  value: '-name',
                  child: Text('Nazwa Z-A'),
                ),
                DropdownMenuItem(
                  value: '-date_updated',
                  child: Text('Ostatnio aktualizowane'),
                ),
                DropdownMenuItem(
                  value: 'date_updated',
                  child: Text('Najdawniej aktualizowane'),
                ),
                DropdownMenuItem(
                  value: '-date_created',
                  child: Text('Najnowsze'),
                ),
                DropdownMenuItem(
                  value: 'date_created',
                  child: Text('Najstarsze'),
                ),
              ],
              onChanged: onTemplateOrderingChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewModeToggle extends ConsumerWidget {
  final DocsLibraryViewMode value;
  final ValueChanged<DocsLibraryViewMode> onChanged;

  const _ViewModeToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    Widget item({
      required DocsLibraryViewMode mode,
      required IconData icon,
      required String tooltip,
    }) {
      final selected = value == mode;

      return Tooltip(
        message: tooltip,
        child: Material(
          color: selected ? theme.themeColor.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onChanged(mode),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(
                icon,
                size: 18,
                color: selected ? theme.themeColor : theme.textColor.withAlpha(165),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(
            mode: DocsLibraryViewMode.grid,
            icon: Icons.grid_view_rounded,
            tooltip: 'Widok kafelków',
          ),
          item(
            mode: DocsLibraryViewMode.list,
            icon: Icons.view_list_rounded,
            tooltip: 'Widok listy',
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final Documents document;
  final String statusLabel;
  final String updatedAtLabel;
  final String createdAtLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.statusLabel,
    required this.updatedAtLabel,
    required this.createdAtLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _CardIcon(icon: Icons.description_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _DocumentPopupMenu(onDelete: onDelete),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    label: statusLabel,
                    icon: Icons.circle_outlined,
                  ),
                  _MiniBadge(
                    label: document.templateName,
                    icon: Icons.dashboard_customize_outlined,
                  ),
                  if (document.isFinalized)
                    const _MiniBadge(
                      label: 'Finalny',
                      icon: Icons.verified_outlined,
                    ),
                ],
              ),
              const Spacer(),
              const SizedBox(height: 12),
              _MetaLine(
                icon: Icons.update,
                label: 'Aktualizacja',
                value: updatedAtLabel,
              ),
              const SizedBox(height: 6),
              _MetaLine(
                icon: Icons.add_circle_outline,
                label: 'Utworzono',
                value: createdAtLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentListTile extends ConsumerWidget {
  final Documents document;
  final String statusLabel;
  final String updatedAtLabel;
  final String createdAtLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentListTile({
    required this.document,
    required this.statusLabel,
    required this.updatedAtLabel,
    required this.createdAtLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Row(
            children: [
              const _CardIcon(icon: Icons.description_outlined),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniBadge(
                          label: statusLabel,
                          icon: Icons.circle_outlined,
                        ),
                        _MiniBadge(
                          label: document.templateName,
                          icon: Icons.dashboard_customize_outlined,
                        ),
                        if (document.isFinalized)
                          const _MiniBadge(
                            label: 'Finalny',
                            icon: Icons.verified_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _MetaLine(
                      icon: Icons.update,
                      label: 'Aktualizacja',
                      value: updatedAtLabel,
                    ),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: Icons.add_circle_outline,
                      label: 'Utworzono',
                      value: createdAtLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DocumentPopupMenu(onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final DocumentTemplate template;
  final String scopeLabel;
  final String createdAtLabel;
  final String updatedAtLabel;
  final VoidCallback onFill;
  final VoidCallback onCreateDocument;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.scopeLabel,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.onFill,
    required this.onCreateDocument,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _CardIcon(icon: Icons.dashboard_customize_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                _TemplatePopupMenu(
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              template.description.isEmpty
                  ? 'Brak opisu template.'
                  : template.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(155),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniBadge(
                  label: scopeLabel,
                  icon: Icons.public_outlined,
                ),
                _MiniBadge(
                  label: template.ownerUsername?.trim().isNotEmpty == true
                      ? template.ownerUsername!.trim()
                      : 'Brak właściciela',
                  icon: Icons.person_outline,
                ),
              ],
            ),
            const Spacer(),
            _MetaLine(
              icon: Icons.update,
              label: 'Aktualizacja',
              value: updatedAtLabel,
            ),
            const SizedBox(height: 6),
            _MetaLine(
              icon: Icons.add_circle_outline,
              label: 'Utworzono',
              value: createdAtLabel,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PrimaryActionButton(
                    onPressed: onFill,
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Wypełnij',
                  ),
                ),
                const SizedBox(width: 8),
                EmmaUiAnchorTarget(
                  anchorKey: DocsEmmaAnchors.createFromTemplateButton.anchorKey,

                  spec: DocsEmmaAnchors.createFromTemplateButton,
                  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                  child: _ThemedIconButton(
                    tooltip: 'Utwórz dokument',
                    onPressed: onCreateDocument,
                    icon: Icons.note_add_outlined,
                  ),
                ),
                EmmaUiAnchorTarget(
                  anchorKey: DocsEmmaAnchors.editTemplateButton.anchorKey,

                  spec: DocsEmmaAnchors.editTemplateButton,
                  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                  child: _ThemedIconButton(
                    tooltip: 'Edytuj template',
                    onPressed: onEdit,
                    icon: Icons.edit_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateListTile extends ConsumerWidget {
  final DocumentTemplate template;
  final String scopeLabel;
  final String createdAtLabel;
  final String updatedAtLabel;
  final VoidCallback onFill;
  final VoidCallback onCreateDocument;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateListTile({
    required this.template,
    required this.scopeLabel,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.onFill,
    required this.onCreateDocument,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Row(
          children: [
            const _CardIcon(icon: Icons.dashboard_customize_outlined),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    template.description.isEmpty
                        ? 'Brak opisu template.'
                        : template.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(155),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniBadge(
                        label: scopeLabel,
                        icon: Icons.public_outlined,
                      ),
                      _MiniBadge(
                        label: template.ownerUsername?.trim().isNotEmpty == true
                            ? template.ownerUsername!.trim()
                            : 'Brak właściciela',
                        icon: Icons.person_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _MetaLine(
                    icon: Icons.update,
                    label: 'Aktualizacja',
                    value: updatedAtLabel,
                  ),
                  const SizedBox(height: 6),
                  _MetaLine(
                    icon: Icons.add_circle_outline,
                    label: 'Utworzono',
                    value: createdAtLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _PrimaryActionButton(
              onPressed: onFill,
              icon: Icons.assignment_turned_in_outlined,
              label: 'Wypełnij',
            ),
            const SizedBox(width: 6),
            EmmaUiAnchorTarget(
              anchorKey: DocsEmmaAnchors.createFromTemplateButton.anchorKey,

              spec: DocsEmmaAnchors.createFromTemplateButton,
              runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
              tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
              child: _ThemedIconButton(
                tooltip: 'Utwórz dokument',
                onPressed: onCreateDocument,
                icon: Icons.note_add_outlined,
              ),
            ),
            EmmaUiAnchorTarget(
              anchorKey: DocsEmmaAnchors.editTemplateButton.anchorKey,

              spec: DocsEmmaAnchors.editTemplateButton,
              runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
              tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
              child: _TemplatePopupMenu(
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPopupMenu extends ConsumerWidget {
  final VoidCallback onDelete;

  const _DocumentPopupMenu({
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: theme.textColor),
      color: theme.dashboardContainer,
      tooltip: 'Opcje',
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Usuń',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplatePopupMenu extends ConsumerWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplatePopupMenu({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: theme.textColor),
      color: theme.dashboardContainer,
      tooltip: 'Opcje',
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: theme.textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Edytuj',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Usuń',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardIcon extends ConsumerWidget {
  final IconData icon;

  const _CardIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Icon(icon, color: theme.textColor),
    );
  }
}

class _CountPill extends ConsumerWidget {
  final String label;
  final int? value;
  final IconData icon;

  const _CountPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.textColor.withAlpha(160)),
          const SizedBox(width: 6),
          Text(
            value == null ? '...' : value.toString(),
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(150),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends ConsumerWidget {
  final String label;
  final IconData icon;

  const _MiniBadge({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.textColor.withAlpha(160)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Row(
      children: [
        Icon(icon, size: 15, color: theme.textColor.withAlpha(130)),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: TextStyle(
            color: theme.textColor.withAlpha(130),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends ConsumerWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final ValueChanged<bool> onSelected;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? theme.themeColor : theme.textColor.withAlpha(180),
          fontWeight: FontWeight.w800,
        ),
      ),
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? theme.themeColor : theme.textColor.withAlpha(150),
            ),
      selected: selected,
      checkmarkColor: theme.themeColor,
      backgroundColor: theme.dashboardContainer,
      selectedColor: theme.themeColor.withAlpha(35),
      side: BorderSide(
        color: selected ? theme.themeColor.withAlpha(160) : theme.dashboardBoarder,
      ),
      onSelected: onSelected,
    );
  }
}

class _ThemedDropdown<T> extends ConsumerWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _ThemedDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return DropdownButtonFormField<T>(
      value: value,
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(
            'Domyślnie',
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map((item) {
          return DropdownMenuItem<T>(
            value: item.value,
            child: DefaultTextStyle(
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
              child: item.child,
            ),
          );
        }),
      ],
      dropdownColor: theme.dashboardContainer,
      iconEnabledColor: theme.textColor,
      style: TextStyle(
        color: theme.textColor,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.textColor.withAlpha(160),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: theme.dashboardContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.themeColor),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _PrimaryActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final bool isLoading;

  const _PrimaryActionButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: theme.dashboardBoarder.withAlpha(90),
        disabledForegroundColor: theme.textColor.withAlpha(120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            )
          : Icon(icon ?? Icons.add),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool danger;

  const _SecondaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final color = danger ? Colors.red.shade300 : theme.textColor;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: danger ? Colors.red.withAlpha(130) : theme.dashboardBoarder,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ThemedIconButton extends ConsumerWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _ThemedIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: theme.textColor,
        backgroundColor: theme.dashboardContainer,
        side: BorderSide(color: theme.dashboardBoarder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: Icon(icon, color: theme.textColor),
    );
  }
}

class _DocsEmptyState extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String description;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _DocsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryLabel,
    this.secondaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: theme.textColor.withAlpha(170)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (secondaryLabel != null && onSecondary != null)
                  _SecondaryActionButton(
                    onPressed: onSecondary!,
                    icon: Icons.refresh,
                    label: secondaryLabel!,
                  ),
                _PrimaryActionButton(
                  onPressed: onPrimary,
                  icon: Icons.add,
                  label: primaryLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocsLibraryError extends ConsumerWidget {
  final String error;
  final VoidCallback onClose;

  const _DocsLibraryError({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withAlpha(120)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: theme.textColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating mobile-only vertical bar (see [BarManager.verticalButtons]) that
/// hosts the filters/view-toggle/create actions the inline header shows on
/// desktop and tablet — mirrors modules/calendar's CalendarVerticalBar.
class DocsVerticalBarMobile extends ConsumerWidget {
  final String documentEditorRoute;

  const DocsVerticalBarMobile({
    super.key,
    required this.documentEditorRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedTab = ref.watch(docsSelectedTabProvider);
    final viewMode = ref.watch(docsViewModeProvider);
    final isTemplateTab = selectedTab == DocsLibraryTab.templates;
    final isCreating = isTemplateTab
        ? ref.watch(docsIsCreatingTemplateProvider)
        : ref.watch(docsIsCreatingDocumentProvider);

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _DocsVerticalActionButton(
          theme: theme,
          tooltip: 'Filtry',
          onPressed: () => _openFiltersSheet(context, ref),
          child: Icon(Icons.filter_alt_outlined, color: theme.textColor),
        ),
        _DocsVerticalActionButton(
          theme: theme,
          tooltip: viewMode == DocsLibraryViewMode.grid
              ? 'Widok listy'
              : 'Widok kafelków',
          onPressed: () {
            ref.read(docsViewModeProvider.notifier).state =
                viewMode == DocsLibraryViewMode.grid
                    ? DocsLibraryViewMode.list
                    : DocsLibraryViewMode.grid;
          },
          child: Icon(
            viewMode == DocsLibraryViewMode.grid
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            color: theme.textColor,
          ),
        ),
        _DocsVerticalActionButton(
          theme: theme,
          tooltip: isTemplateTab ? 'Nowa template' : 'Nowy dokument',
          onPressed: isCreating
              ? null
              : () => docsCreateForActiveTab(context, ref, documentEditorRoute),
          child: isCreating
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.textColor,
                  ),
                )
              : Icon(Icons.add, color: theme.textColor),
        ),
      ],
    );
  }

  Future<void> _openFiltersSheet(BuildContext context, WidgetRef ref) async {
    final theme = ref.read(themeColorsProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.dashboardContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return _DocsFiltersSheet(scrollController: scrollController);
          },
        );
      },
    );
  }
}

class _DocsVerticalActionButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  const _DocsVerticalActionButton({
    required this.theme,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: child,
        ),
      ),
    );
  }
}

class _DocsFiltersSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _DocsFiltersSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedTab = ref.watch(docsSelectedTabProvider);
    final documentFilters = ref.watch(documentFiltersProvider);
    final templateFilters = ref.watch(templateFiltersProvider);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtry i sortowanie',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final currentSearch = selectedTab == DocsLibraryTab.templates
                      ? templateFilters['search']
                      : documentFilters['search'];

                  final cleared = currentSearch != null &&
                          currentSearch.toString().trim().isNotEmpty
                      ? {'search': currentSearch}
                      : <String, dynamic>{};

                  if (selectedTab == DocsLibraryTab.templates) {
                    ref.read(templateFiltersProvider.notifier).state = cleared;
                  } else {
                    ref.read(documentFiltersProvider.notifier).state = cleared;
                  }
                },
                icon: Icon(Icons.filter_alt_off, color: Colors.red.shade300),
                label: Text(
                  'Wyczyść',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AdvancedFiltersPanel(
            selectedTab: selectedTab,
            documentFilters: documentFilters,
            templateFilters: templateFilters,
            onFinalizedOnlyChanged: (selected) => docsSetDocumentFilter(
              ref,
              'is_finalized',
              selected ? 'true' : null,
            ),
            onGlobalTemplatesOnlyChanged: (selected) => docsSetTemplateFilter(
              ref,
              'is_global',
              selected ? 'true' : null,
            ),
            onDocumentStatusChanged: (status) =>
                docsSetDocumentFilter(ref, 'status', status),
            onDocumentOrderingChanged: (ordering) =>
                docsSetDocumentFilter(ref, 'ordering', ordering),
            onTemplateOrderingChanged: (ordering) =>
                docsSetTemplateFilter(ref, 'ordering', ordering),
          ),
        ],
      ),
    );
  }
}
