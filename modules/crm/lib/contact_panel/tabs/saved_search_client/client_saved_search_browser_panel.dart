import 'dart:async';

import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/tabs/dashboard/new_clients_view_full.dart';
import 'package:crm/contact_panel/tabs/transactions/tx_client_provider.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/pie_menu/saved_search_nm.dart';
import 'package:network_monitoring/providers/saved_search/inbox_api.dart';
import 'package:network_monitoring/providers/saved_search/inbox_models.dart';
import 'package:network_monitoring/screens/list_with_save_searches/widget/saved_search_card.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum ClientSavedSearchBrowseMode {
  list,
  allNew,
  singleSearch,
}

enum ClientSavedSearchAllNewMode {
  merged,
  sequential,
}

class ClientSavedSearchBrowserPanel extends ConsumerStatefulWidget {
  final int? clientId;
  final int? transactionId;
  final bool closeOverlayOnOpenSearch;

  const ClientSavedSearchBrowserPanel({
    super.key,
    this.clientId,
    this.transactionId,
    this.closeOverlayOnOpenSearch = false,
  });

  @override
  ConsumerState<ClientSavedSearchBrowserPanel> createState() =>
      ClientSavedSearchBrowserPanelState();
}

class ClientSavedSearchBrowserPanelState
    extends ConsumerState<ClientSavedSearchBrowserPanel> {
  final ScrollController _inboxScrollController = ScrollController();
  final TextEditingController _queryController = TextEditingController();

  final Map<int, SavedSearchInboxItemModel> _pendingSeen = {};
  final Set<int> _queuedSeen = {};

  Timer? _seenDebounce;
  Timer? _bannerTimer;

  String? _bannerText;

  ClientSavedSearchBrowseMode _browseMode = ClientSavedSearchBrowseMode.list;
  ClientSavedSearchAllNewMode _allNewMode =
      ClientSavedSearchAllNewMode.merged;

  List<SavedSearchWithCountersModel> _savedSearches = [];
  int _savedSearchesCount = 0;
  int _savedSearchesPage = 1;
  int _savedSearchesPageSize = 50;
  bool _savedSearchesLoading = false;
  String? _savedSearchesError;

  bool _savedSearchesHasNew = false;
  bool _savedSearchesHasResults = false;
  bool _savedSearchesEnableNotifications = false;
  bool _savedSearchesEnableEmailNotifications = false;
  String _savedSearchesScope = '';
  String _savedSearchesOrdering = 'new_desc';

  int? _selectedSavedSearchId;

  List<SavedSearchInboxItemModel> _items = [];
  bool _isInitialLoadingInbox = false;
  bool _isLoadingMoreInbox = false;
  bool _hasMoreInbox = false;
  int _nextInboxPage = 1;
  String? _inboxError;
  String? _activeInboxSignature;
  String? _autoAdvanceHandledSignature;
  bool _isResolvingTargetAd = false;
  String? _openedTargetSignature;

  bool _onlyNew = true;
  bool _includeInactive = false;
  bool _includeArchived = false;
  bool _excludeFavorites = false;
  bool _excludeHide = false;
  bool _excludeDisplayed = false;
  bool _markSeenAcrossSearches = false;

  @override
  void initState() {
    super.initState();
    _inboxScrollController.addListener(_onInboxScroll);
    _loadSavedSearches();
  }

  @override
  void dispose() {
    _seenDebounce?.cancel();
    _bannerTimer?.cancel();
    _inboxScrollController.removeListener(_onInboxScroll);
    _inboxScrollController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  SavedSearchWithCountersModel? get _selectedSearch {
    if (_selectedSavedSearchId == null) return null;
    for (final item in _savedSearches) {
      if (item.id == _selectedSavedSearchId) return item;
    }
    return null;
  }

  void _onInboxScroll() {
    if (!_inboxScrollController.hasClients) return;
    final pos = _inboxScrollController.position;

    if (_hasMoreInbox &&
        !_isLoadingMoreInbox &&
        !_isInitialLoadingInbox &&
        pos.pixels >= pos.maxScrollExtent - 700) {
      _loadMoreInbox();
    }

    if (!_hasMoreInbox &&
        !_isLoadingMoreInbox &&
        !_isInitialLoadingInbox &&
        pos.maxScrollExtent > 0 &&
        pos.pixels >= pos.maxScrollExtent - 40) {
      _maybeAutoAdvanceAfterEndReached();
    }
  }

  void _showBanner(String text) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerText = text;
    });

    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _bannerText = null;
      });
    });
  }

  Color _overlayColor(ThemeColors theme) {
    final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
    final base = uiIsDark ? Colors.black : Colors.white;
    return base.withOpacity(0.70);
  }

  dynamic _buildSavedSearchPieMenuActions(
    BuildContext context,
    ThemeColors theme,
    SavedSearchWithCountersModel search,
  ) {
    try {
      return Function.apply(
        buildPieMenuActionsNMsavedSearch,
        [ref, search, search.id, context, theme],
        <Symbol, dynamic>{
          #clientId: widget.clientId,
          #transactionId: widget.transactionId,
        },
      );
    } catch (_) {
      return buildPieMenuActionsNMsavedSearch(
        ref,
        search,
        search.id,
        context,
        theme,
      );
    }
  }

  void _applySavedSearchToClientContext(SavedSearchWithCountersModel search) {
    final notifier = ref.read(filterProvider.notifier);

    notifier.setClientId('', ref);
    notifier.filteredScope(widget.clientId, widget.transactionId, ref);
    notifier.setSavedSearches({search.id}, ref, widget.transactionId);

    ref.read(activeSectionProvider.notifier).state = 'transakcje';

    if (widget.clientId != null) {
      ref.read(selectedTransactionProvider(widget.clientId!));
    }

    if (widget.closeOverlayOnOpenSearch && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  SavedSearchWithCountersModel? _firstSequentialCandidate() {
    for (final item in _savedSearches) {
      if (item.newUniqueCount > 0) return item;
    }
    return _savedSearches.isNotEmpty ? _savedSearches.first : null;
  }

  Future<void> _loadSavedSearches() async {
    setState(() {
      _savedSearchesLoading = true;
      _savedSearchesError = null;
    });

    try {
      final page = await ref.read(savedSearchInboxApiProvider).fetchSavedSearchesWithCounters(
            clientId: widget.clientId,
            transactionId: widget.transactionId,
            q: _queryController.text.trim().isEmpty
                ? null
                : _queryController.text.trim(),
            hasNew: _savedSearchesHasNew ? true : null,
            hasResults: _savedSearchesHasResults ? true : null,
            enableNotifications:
                _savedSearchesEnableNotifications ? true : null,
            enableEmailNotification:
                _savedSearchesEnableEmailNotifications ? true : null,
            scope: _savedSearchesScope.isEmpty ? null : _savedSearchesScope,
            ordering: _savedSearchesOrdering,
            page: _savedSearchesPage,
            pageSize: _savedSearchesPageSize,
          );

      if (!mounted) return;

      setState(() {
        _savedSearches = page.results;
        _savedSearchesCount = page.count;
        _savedSearchesLoading = false;
        _savedSearchesError = null;
      });

      final exists = _savedSearches.any((e) => e.id == _selectedSavedSearchId);

      if (!exists) {
        final fallback = _browseMode == ClientSavedSearchBrowseMode.allNew &&
                _allNewMode == ClientSavedSearchAllNewMode.sequential
            ? _firstSequentialCandidate()
            : (_savedSearches.isNotEmpty ? _savedSearches.first : null);

        _selectedSavedSearchId = fallback?.id;
      }

      if (_browseMode != ClientSavedSearchBrowseMode.list) {
        await _loadInboxFirstPage();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savedSearchesLoading = false;
        _savedSearchesError = e.toString();
      });
    }
  }

  String _buildInboxSignature() {
    return [
      _browseMode.name,
      _allNewMode.name,
      _selectedSavedSearchId,
      _onlyNew,
      _includeInactive,
      _includeArchived,
      _excludeFavorites,
      _excludeHide,
      _excludeDisplayed,
      widget.clientId,
      widget.transactionId,
    ].join('|');
  }

  List<int>? _resolveInboxSavedSearchIds() {
    if (_browseMode == ClientSavedSearchBrowseMode.singleSearch &&
        _selectedSavedSearchId != null) {
      return [_selectedSavedSearchId!];
    }

    if (_browseMode == ClientSavedSearchBrowseMode.allNew &&
        _allNewMode == ClientSavedSearchAllNewMode.sequential &&
        _selectedSavedSearchId != null) {
      return [_selectedSavedSearchId!];
    }

    if (_browseMode == ClientSavedSearchBrowseMode.allNew &&
        _allNewMode == ClientSavedSearchAllNewMode.merged) {
      return null;
    }

    return null;
  }

  List<int>? _resolveMarkSeenSavedSearchIds() {
    if (_browseMode == ClientSavedSearchBrowseMode.allNew &&
        _allNewMode == ClientSavedSearchAllNewMode.merged) {
      return null;
    }

    if (_markSeenAcrossSearches) {
      return null;
    }

    if (_selectedSavedSearchId != null) {
      return [_selectedSavedSearchId!];
    }

    return null;
  }

  void _resetTransientInboxState() {
    _pendingSeen.clear();
    _queuedSeen.clear();
    _seenDebounce?.cancel();
    _openedTargetSignature = null;
    _autoAdvanceHandledSignature = null;
  }

  Future<void> _loadInboxFirstPage() async {
    if (_browseMode == ClientSavedSearchBrowseMode.list) return;

    final signature = _buildInboxSignature();
    _resetTransientInboxState();

    setState(() {
      _activeInboxSignature = signature;
      _isInitialLoadingInbox = true;
      _isLoadingMoreInbox = false;
      _items = [];
      _hasMoreInbox = false;
      _nextInboxPage = 1;
      _inboxError = null;
    });

    try {
      final page = await ref.read(savedSearchInboxApiProvider).fetchInbox(
            savedSearchIds: _resolveInboxSavedSearchIds(),
            clientId: widget.clientId,
            transactionId: widget.transactionId,
            onlyNew: _onlyNew,
            includeInactive: _includeInactive,
            includeArchived: _includeArchived,
            excludeFavorites: _excludeFavorites,
            excludeHide: _excludeHide,
            excludeDisplayed: _excludeDisplayed,
            page: 1,
            pageSize: 20,
          );

      if (!mounted || _activeInboxSignature != signature) return;

      setState(() {
        _items = page.results;
        _hasMoreInbox = page.next != null && page.next!.isNotEmpty;
        _nextInboxPage = 2;
        _isInitialLoadingInbox = false;
        _inboxError = null;
      });

      if (_items.isEmpty) {
        _maybeAutoAdvanceAfterEndReached();
      }
    } catch (e) {
      if (!mounted || _activeInboxSignature != signature) return;
      setState(() {
        _isInitialLoadingInbox = false;
        _inboxError = e.toString();
      });
    }
  }

  Future<void> _loadMoreInbox() async {
    if (_isLoadingMoreInbox || !_hasMoreInbox) return;
    final signature = _activeInboxSignature;
    if (signature == null) return;

    setState(() {
      _isLoadingMoreInbox = true;
    });

    try {
      final page = await ref.read(savedSearchInboxApiProvider).fetchInbox(
            savedSearchIds: _resolveInboxSavedSearchIds(),
            clientId: widget.clientId,
            transactionId: widget.transactionId,
            onlyNew: _onlyNew,
            includeInactive: _includeInactive,
            includeArchived: _includeArchived,
            excludeFavorites: _excludeFavorites,
            excludeHide: _excludeHide,
            excludeDisplayed: _excludeDisplayed,
            page: _nextInboxPage,
            pageSize: 20,
          );

      if (!mounted || _activeInboxSignature != signature) return;

      final existingIds = _items.map((e) => e.representativeAdId).toSet();
      final newItems = page.results
          .where((e) => !existingIds.contains(e.representativeAdId))
          .toList();

      setState(() {
        _items = [..._items, ...newItems];
        _hasMoreInbox = page.next != null && page.next!.isNotEmpty;
        _nextInboxPage += 1;
        _isLoadingMoreInbox = false;
      });
    } catch (e) {
      if (!mounted || _activeInboxSignature != signature) return;
      setState(() {
        _isLoadingMoreInbox = false;
        _inboxError = e.toString();
      });
    }
  }

  void _queueSeen(SavedSearchInboxItemModel item) {
    if (item.newMatchesCount <= 0) return;
    if (_queuedSeen.contains(item.representativeAdId)) return;

    _queuedSeen.add(item.representativeAdId);
    _pendingSeen[item.representativeAdId] = item;

    _seenDebounce?.cancel();
    _seenDebounce = Timer(const Duration(milliseconds: 700), _flushSeen);
  }

Future<void> _flushSeen() async {
  if (_pendingSeen.isEmpty) return;

  final items = _pendingSeen.values.toList(growable: false);
  _pendingSeen.clear();

  try {
    await ref.read(savedSearchInboxApiProvider).markInboxSeen(
          representativeAdIds:
              items.map((e) => e.representativeAdId).toList(),
          savedSearchIds: _resolveMarkSeenSavedSearchIds(),
          clientId: widget.clientId,
          transactionId: widget.transactionId,
        );

    if (!mounted) return;

    // IMPORTANT:
    // Do not call _loadSavedSearches() here.
    // Visible cards are marked as seen by VisibilityDetector,
    // and reloading the inbox here causes an endless auto-refresh loop.
    //
    // The current list stays stable until the user manually refreshes
    // or changes filters/view.
  } catch (_) {
    for (final item in items) {
      _queuedSeen.remove(item.representativeAdId);
    }
  }
}
  SavedSearchWithCountersModel? _findNextSearchWithNewAds() {
    final current = _selectedSearch;
    if (current == null) return null;

    final currentIndex = _savedSearches.indexWhere((e) => e.id == current.id);
    if (currentIndex == -1) return null;

    for (int i = currentIndex + 1; i < _savedSearches.length; i++) {
      if (_savedSearches[i].newUniqueCount > 0) {
        return _savedSearches[i];
      }
    }

    for (int i = 0; i < currentIndex; i++) {
      if (_savedSearches[i].newUniqueCount > 0) {
        return _savedSearches[i];
      }
    }

    return null;
  }

  void _maybeAutoAdvanceAfterEndReached() {
    if (_browseMode != ClientSavedSearchBrowseMode.allNew) return;
    if (_allNewMode != ClientSavedSearchAllNewMode.sequential) return;
    if (_selectedSearch == null) return;
    if (_activeInboxSignature == null) return;
    if (_autoAdvanceHandledSignature == _activeInboxSignature) return;

    _autoAdvanceHandledSignature = _activeInboxSignature;

    final next = _findNextSearchWithNewAds();
    if (next == null || next.id == _selectedSearch!.id) return;

    setState(() {
      _selectedSavedSearchId = next.id;
    });

    _showBanner(
      '${'Now showing new ads from'.tr}: ${next.title ?? 'Saved search'}',
    );

    _loadInboxFirstPage();
  }

  void _openAllNew({
    ClientSavedSearchAllNewMode mode = ClientSavedSearchAllNewMode.merged,
  }) {
    setState(() {
      _browseMode = ClientSavedSearchBrowseMode.allNew;
      _allNewMode = mode;

      if (mode == ClientSavedSearchAllNewMode.sequential) {
        final candidate = _firstSequentialCandidate();
        _selectedSavedSearchId = candidate?.id;
      }
    });

    _loadInboxFirstPage();
  }

  void _openSingleSearch(SavedSearchWithCountersModel search) {
    setState(() {
      _selectedSavedSearchId = search.id;
      _browseMode = ClientSavedSearchBrowseMode.singleSearch;
    });

    _loadInboxFirstPage();
  }

  void _handleSearchCardSelect(SavedSearchWithCountersModel search) {
    if (_browseMode == ClientSavedSearchBrowseMode.allNew &&
        _allNewMode == ClientSavedSearchAllNewMode.sequential) {
      setState(() {
        _selectedSavedSearchId = search.id;
      });
      _loadInboxFirstPage();
      return;
    }

    _openSingleSearch(search);
  }

  void _backToList() {
    setState(() {
      _browseMode = ClientSavedSearchBrowseMode.list;
    });
  }

  void _resetListFilters() {
    _queryController.clear();
    setState(() {
      _savedSearchesHasNew = false;
      _savedSearchesHasResults = false;
      _savedSearchesEnableNotifications = false;
      _savedSearchesEnableEmailNotifications = false;
      _savedSearchesScope = '';
      _savedSearchesOrdering = 'new_desc';
      _savedSearchesPage = 1;
      _savedSearchesPageSize = 50;
    });
    _loadSavedSearches();
  }

  // Public API for external vertical buttons
  void openFiltersSheet() {
    if (!mounted) return;
    _showFiltersBottomSheet(context);
  }

  void openAllNewAds() {
    _openAllNew();
  }

  void _showFiltersBottomSheet(BuildContext ctx) {
    final theme = ref.read(themeColorsProvider);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetCtx, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Material(
            color: theme.dashboardContainer,
            child: SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                ),
                child: StatefulBuilder(
                  builder: (_, setSheetState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42, height: 4,
                          decoration: BoxDecoration(
                            color: theme.dashboardBoarder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Filters'.tr,
                        style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _queryController,
                        onChanged: (v) { _savedSearchesPage = 1; _loadSavedSearches(); },
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          hintText: 'Search saved searches...'.tr,
                          hintStyle: TextStyle(color: theme.textColor.withOpacity(0.55)),
                          prefixIcon: Icon(Icons.search, color: theme.textColor),
                          filled: true,
                          fillColor: theme.textFieldColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dashboardBoarder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dashboardBoarder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.themeColor)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _savedSearchesOrdering,
                              isExpanded: true,
                              dropdownColor: theme.dashboardContainer,
                              decoration: InputDecoration(labelText: 'Sort'.tr, labelStyle: TextStyle(color: theme.textColor), filled: true, fillColor: theme.textFieldColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              style: TextStyle(color: theme.textColor),
                              items: [
                                DropdownMenuItem(value: 'new_desc', child: Text('Most new'.tr)),
                                DropdownMenuItem(value: 'updated_desc', child: Text('Recently updated'.tr)),
                                DropdownMenuItem(value: 'title_asc', child: Text('Title A-Z'.tr)),
                                DropdownMenuItem(value: 'title_desc', child: Text('Title Z-A'.tr)),
                                DropdownMenuItem(value: 'created_desc', child: Text('Recently created'.tr)),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setSheetState(() {});
                                setState(() { _savedSearchesOrdering = v; _savedSearchesPage = 1; });
                                _loadSavedSearches();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _savedSearchesScope.isEmpty ? '__all__' : _savedSearchesScope,
                              isExpanded: true,
                              dropdownColor: theme.dashboardContainer,
                              decoration: InputDecoration(labelText: 'Scope'.tr, labelStyle: TextStyle(color: theme.textColor), filled: true, fillColor: theme.textFieldColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              style: TextStyle(color: theme.textColor),
                              items: [
                                DropdownMenuItem(value: '__all__', child: Text('All'.tr)),
                                DropdownMenuItem(value: 'client', child: Text('Client'.tr)),
                                DropdownMenuItem(value: 'transaction', child: Text('Transaction'.tr)),
                                DropdownMenuItem(value: 'unassigned', child: Text('Unassigned'.tr)),
                                DropdownMenuItem(value: 'mixed', child: Text('Assigned'.tr)),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setSheetState(() {});
                                setState(() { _savedSearchesScope = v == '__all__' ? '' : v; _savedSearchesPage = 1; });
                                _loadSavedSearches();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(label: Text('Has new'.tr), selected: _savedSearchesHasNew, onSelected: (v) { setSheetState(() {}); setState(() { _savedSearchesHasNew = v; _savedSearchesPage = 1; }); _loadSavedSearches(); }),
                          FilterChip(label: Text('Has results'.tr), selected: _savedSearchesHasResults, onSelected: (v) { setSheetState(() {}); setState(() { _savedSearchesHasResults = v; _savedSearchesPage = 1; }); _loadSavedSearches(); }),
                          FilterChip(label: Text('Notifications'.tr), selected: _savedSearchesEnableNotifications, onSelected: (v) { setSheetState(() {}); setState(() { _savedSearchesEnableNotifications = v; _savedSearchesPage = 1; }); _loadSavedSearches(); }),
                          FilterChip(label: Text('E-mail notifications'.tr), selected: _savedSearchesEnableEmailNotifications, onSelected: (v) { setSheetState(() {}); setState(() { _savedSearchesEnableEmailNotifications = v; _savedSearchesPage = 1; }); _loadSavedSearches(); }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () { _resetListFilters(); setSheetState(() {}); },
                          icon: Icon(Icons.restart_alt, color: theme.textColor),
                          label: Text('Reset'.tr, style: TextStyle(color: theme.textColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInboxFiltersSheet(BuildContext ctx) {
    final theme = ref.read(themeColorsProvider);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetCtx, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Material(
            color: theme.dashboardContainer,
            child: SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                ),
                child: StatefulBuilder(
                  builder: (_, setSheetState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42, height: 4,
                          decoration: BoxDecoration(
                            color: theme.dashboardBoarder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Filters'.tr,
                        style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      if (_browseMode == ClientSavedSearchBrowseMode.allNew) ...[
                        Text('View mode'.tr, style: TextStyle(color: theme.textColor.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text('Merged feed'.tr),
                              selected: _allNewMode == ClientSavedSearchAllNewMode.merged,
                              onSelected: (_) {
                                setSheetState(() {});
                                setState(() { _allNewMode = ClientSavedSearchAllNewMode.merged; });
                                _loadInboxFirstPage();
                              },
                            ),
                            ChoiceChip(
                              label: Text('Sequential searches'.tr),
                              selected: _allNewMode == ClientSavedSearchAllNewMode.sequential,
                              onSelected: (_) {
                                setSheetState(() {});
                                setState(() {
                                  _allNewMode = ClientSavedSearchAllNewMode.sequential;
                                  final candidate = _firstSequentialCandidate();
                                  _selectedSavedSearchId = candidate?.id;
                                });
                                _loadInboxFirstPage();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text('Ad filters'.tr, style: TextStyle(color: theme.textColor.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_browseMode == ClientSavedSearchBrowseMode.singleSearch ||
                              (_browseMode == ClientSavedSearchBrowseMode.allNew &&
                                  _allNewMode == ClientSavedSearchAllNewMode.sequential))
                            FilterChip(
                              label: Text('Seen in other searches'.tr),
                              selected: _markSeenAcrossSearches,
                              onSelected: (v) {
                                setSheetState(() {});
                                setState(() => _markSeenAcrossSearches = v);
                              },
                            ),
                          FilterChip(
                            label: Text('Only new'.tr),
                            selected: _onlyNew,
                            onSelected: (v) {
                              setSheetState(() {});
                              setState(() => _onlyNew = v);
                              _loadInboxFirstPage();
                            },
                          ),
                          FilterChip(
                            label: Text('Include inactive'.tr),
                            selected: _includeInactive,
                            onSelected: (v) {
                              setSheetState(() {});
                              setState(() => _includeInactive = v);
                              _loadInboxFirstPage();
                            },
                          ),
                          FilterChip(
                            label: Text('Include archived'.tr),
                            selected: _includeArchived,
                            onSelected: (v) {
                              setSheetState(() {});
                              setState(() => _includeArchived = v);
                              _loadInboxFirstPage();
                            },
                          ),
                          FilterChip(
                            label: Text('Exclude favorites'.tr),
                            selected: _excludeFavorites,
                            onSelected: (v) {
                              setSheetState(() {});
                              setState(() => _excludeFavorites = v);
                              _loadInboxFirstPage();
                            },
                          ),
                          FilterChip(
                            label: Text('Exclude hidden'.tr),
                            selected: _excludeHide,
                            onSelected: (v) {
                              setSheetState(() {});
                              setState(() => _excludeHide = v);
                              _loadInboxFirstPage();
                            },
                          ),
                          FilterChip(
                            label: Text('Exclude displayed'.tr),
                            selected: _excludeDisplayed,
                            onSelected: (v) {
                              setSheetState(() {});
                              setState(() => _excludeDisplayed = v);
                              _loadInboxFirstPage();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

String? _extractMainImage(dynamic images) {
  if (images == null) return null;

  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first != null && first.toString().trim().isNotEmpty) {
      return first.toString();
    }
  }

  if (images is Map) {
    for (final key in const ['main', '0', 'first', 'thumbnail']) {
      final value = images[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    for (final entry in images.entries) {
      final value = entry.value;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
  }

  return null;
}

MonitoringAdsModel? _toMonitoringAd(Map<String, dynamic>? raw) {
  if (raw == null) return null;

  try {
    return MonitoringAdsModel.fromJson(raw);
  } catch (_) {
    return null;
  }
}




  Widget _buildSavedSearchCard(
    BuildContext context,
    ThemeColors theme,
    SavedSearchWithCountersModel search,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final isSelected = _selectedSavedSearchId == search.id;

    return PieMenu(
      theme: PieTheme.of(context).copyWith(
        overlayColor: _overlayColor(theme),
      ),
      actions: _buildSavedSearchPieMenuActions(context, theme, search),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SavedSearchNmCard(
          search: search,
          selected: isSelected,
          isMobile: isMobile,
          transactionId: widget.transactionId,
          onSelect: () => _handleSearchCardSelect(search),
          onApply: () => _applySavedSearchToClientContext(search),
        ),
      ),
    );
  }

  Widget _buildSavedSearchListPanel({
    required bool isSidebar,
  }) {
    final theme = ref.watch(themeColorsProvider);
    final isMobileLayout = MediaQuery.of(context).size.width < 700;

    if (_savedSearchesLoading && _savedSearches.isEmpty) {
      return Center(child: AppLottie.loading());
    }

    if (_savedSearchesError != null && _savedSearches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load saved searches: $_savedSearchesError'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
      );
    }

    final topPadding = isMobileLayout ? TopAppBarSize.resolve(context) : 0.0;
    final bottomPadding = isMobileLayout ? BottomBarSize.resolve(context) : 0.0;

    final paginationFooter = _ClientSavedSearchesPaginationFooter(
      totalCount: _savedSearchesCount,
      page: _savedSearchesPage,
      pageSize: _savedSearchesPageSize,
      onPageSizeChanged: (value) {
        setState(() {
          _savedSearchesPageSize = value;
          _savedSearchesPage = 1;
        });
        _loadSavedSearches();
      },
      onPrev: _savedSearchesPage > 1
          ? () {
              setState(() {
                _savedSearchesPage -= 1;
              });
              _loadSavedSearches();
            }
          : null,
      onNext: _savedSearchesPage <
              ((_savedSearchesCount + _savedSearchesPageSize - 1) ~/
                  _savedSearchesPageSize)
          ? () {
              setState(() {
                _savedSearchesPage += 1;
              });
              _loadSavedSearches();
            }
          : null,
    );

    final body = _savedSearches.isEmpty
        ? Center(child: AppLottie.noResults(size: 220))
        : ListView.builder(
            padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: bottomPadding + 80),
            itemCount: _savedSearches.length + (isMobileLayout ? 1 : 0),
            itemBuilder: (context, index) {
              if (isMobileLayout && index == _savedSearches.length) {
                return Padding(
                  padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
                  child: paginationFooter,
                );
              }
              final search = _savedSearches[index];
              return _buildSavedSearchCard(context, theme, search);
            },
          );

    return Container(
      decoration: BoxDecoration(
        color: isMobileLayout ? null :theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: isMobileLayout ? null : Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        children: [
          SizedBox(height: topPadding),
          if (!isMobileLayout) ...[
            _ClientSavedSearchesHeader(
              queryController: _queryController,
              hasNew: _savedSearchesHasNew,
              hasResults: _savedSearchesHasResults,
              enableNotifications: _savedSearchesEnableNotifications,
              enableEmailNotifications: _savedSearchesEnableEmailNotifications,
              scope: _savedSearchesScope,
              ordering: _savedSearchesOrdering,
              isSequentialSidebar: isSidebar &&
                  _browseMode == ClientSavedSearchBrowseMode.allNew &&
                  _allNewMode == ClientSavedSearchAllNewMode.sequential,
              onQueryChanged: (value) {
                _savedSearchesPage = 1;
                _loadSavedSearches();
              },
              onHasNewChanged: (value) {
                setState(() {
                  _savedSearchesHasNew = value;
                  _savedSearchesPage = 1;
                });
                _loadSavedSearches();
              },
              onHasResultsChanged: (value) {
                setState(() {
                  _savedSearchesHasResults = value;
                  _savedSearchesPage = 1;
                });
                _loadSavedSearches();
              },
              onNotificationsChanged: (value) {
                setState(() {
                  _savedSearchesEnableNotifications = value;
                  _savedSearchesPage = 1;
                });
                _loadSavedSearches();
              },
              onEmailNotificationsChanged: (value) {
                setState(() {
                  _savedSearchesEnableEmailNotifications = value;
                  _savedSearchesPage = 1;
                });
                _loadSavedSearches();
              },
              onScopeChanged: (value) {
                setState(() {
                  _savedSearchesScope = value;
                  _savedSearchesPage = 1;
                });
                _loadSavedSearches();
              },
              onOrderingChanged: (value) {
                setState(() {
                  _savedSearchesOrdering = value;
                  _savedSearchesPage = 1;
                });
                _loadSavedSearches();
              },
              onReset: _resetListFilters,
              onOpenAllNew: () => _openAllNew(),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: Column(
              children: [
                if (isSidebar &&
                    _browseMode == ClientSavedSearchBrowseMode.allNew &&
                    _allNewMode == ClientSavedSearchAllNewMode.sequential)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12).copyWith(bottom: 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.textFieldColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dashboardBoarder),
                    ),
                    child: Text(
                      'Sequential mode — current search is highlighted'.tr,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
          if (!isMobileLayout) ...[
            const Divider(height: 1),
            paginationFooter,
          ],
        ],
      ),
    );
  }

  Widget _buildInboxPanel() {
    final theme = ref.watch(themeColorsProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    final title = _browseMode == ClientSavedSearchBrowseMode.allNew
        ? _allNewMode == ClientSavedSearchAllNewMode.sequential
            ? '${'Sequential new ads'.tr}: ${_selectedSearch?.title ?? 'Saved search'}'
            : 'All new ads'.tr
        : '${'New ads from'.tr}: ${_selectedSearch?.title ?? 'Saved search'}';

    if (_isInitialLoadingInbox && _items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Center(child: AppLottie.loading()),
      );
    }

    if (_inboxError != null && _items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              'Inbox error:\n$_inboxError',
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isMobile ? null : theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: isMobile ? null :  Border.all(color: theme.dashboardBoarder),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: isMobile ? TopAppBarSize.resolve(context) : 0),
              _ClientInboxHeader(
                title: title,
                browseMode: _browseMode,
                onBackToList: _backToList,
                onRefresh: _loadInboxFirstPage,
                onOpenSearch: _selectedSearch == null
                    ? null
                    : () => _applySavedSearchToClientContext(_selectedSearch!),
                onOpenFilters: () => _showInboxFiltersSheet(context),
              ),
              const Divider(height: 1),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppLottie.noResults(size: 220),
                              const SizedBox(height: 12),
                              Text(
                                _browseMode ==
                                            ClientSavedSearchBrowseMode.allNew &&
                                        _allNewMode ==
                                            ClientSavedSearchAllNewMode
                                                .sequential
                                    ? 'No new ads in this search'.tr
                                    : _browseMode ==
                                            ClientSavedSearchBrowseMode.allNew
                                        ? 'No new ads found'.tr
                                        : 'No new ads in this saved search'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _inboxScrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= _items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: _isLoadingMoreInbox
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Loading more...'.tr,
                                            style: TextStyle(
                                              color: theme.textColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : !_hasMoreInbox
                                        ? Text(
                                            _browseMode ==
                                                        ClientSavedSearchBrowseMode
                                                            .allNew &&
                                                    _allNewMode ==
                                                        ClientSavedSearchAllNewMode
                                                            .sequential
                                                ? 'End of current search'.tr
                                                : _browseMode ==
                                                        ClientSavedSearchBrowseMode
                                                            .allNew
                                                    ? 'End of all new ads'.tr
                                                    : 'End of this saved search'
                                                        .tr,
                                            style: TextStyle(
                                              color: theme.textColor
                                                  .withOpacity(0.65),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : const SizedBox(height: 40),
                              ),
                            );
                          }

                          final item = _items[index];
                          final ad = _toMonitoringAd(item.ad);

                          if (ad == null) {
                            return const SizedBox.shrink();
                          }

                          final mainImageUrl = _extractMainImage(item.images) ?? '';
                          final showMatchedChips =
                              _browseMode ==
                                      ClientSavedSearchBrowseMode.allNew &&
                                  _allNewMode ==
                                      ClientSavedSearchAllNewMode.merged;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: VisibilityDetector(
                              key: Key(
                                'client-saved-search-inbox-${_browseMode.name}-${_allNewMode.name}-${_selectedSavedSearchId}-${item.representativeAdId}',
                              ),
                              onVisibilityChanged: (info) {
                                if (info.visibleFraction >= 0.60) {
                                  _queueSeen(item);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showMatchedChips) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ...item.matchedSavedSearches.map(
                                          (e) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: e.isNew
                                                  ? theme.themeColor
                                                      .withOpacity(0.16)
                                                  : theme.textFieldColor,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              e.title,
                                              style: TextStyle(
                                                color: theme.textColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  SelectedCardWidgetNM(
                                    ad: ad,
                                    tag:
                                        'client-saved-search-inbox-${item.representativeAdId}',
                                    mainImageUrl: mainImageUrl,
                                    isPro: true,
                                    isDefaultDarkSystem:
                                        Theme.of(context).brightness ==
                                            Brightness.dark,
                                    color: theme.dashboardContainer,
                                    textColor: theme.textColor,
                                    textFieldColor: theme.textFieldColor,
                                    buildShimmerPlaceholder: Container(
                                      width: double.infinity,
                                      height: isMobile ? 220 : 150,
                                      decoration: BoxDecoration(
                                        color: theme.textFieldColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    buildPieMenuActions: buildPieMenuActionsNM(
                                      ref,
                                      ad,
                                      context,
                                      widget.transactionId,
                                      widget.clientId,
                                    ),
                                    aspectRatio:
                                        (isMobile
                                                ? CardTypeNM.vanda
                                                : CardTypeNM.list)
                                            .aspectRatio,
                                    isMobile: isMobile,
                                    transactionId: widget.transactionId,
                                    clientId: widget.clientId,
                                    cardTypeNMOverwrite: isMobile
                                        ? CardTypeNM.vanda
                                        : CardTypeNM.list,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _bannerText == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(_bannerText),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.themeColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: theme.themeColor.withOpacity(0.20),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Text(
                          _bannerText!,
                          style: TextStyle(
                            color: theme.themeColorText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (_browseMode == ClientSavedSearchBrowseMode.list) {
      return _buildSavedSearchListPanel(isSidebar: false);
    }

    if (_browseMode == ClientSavedSearchBrowseMode.allNew &&
        _allNewMode == ClientSavedSearchAllNewMode.sequential &&
        !isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 430,
            child: _buildSavedSearchListPanel(isSidebar: true),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildInboxPanel()),
        ],
      );
    }

    return _buildInboxPanel();
  }
}

class _ClientSavedSearchesHeader extends StatelessWidget {
  final TextEditingController queryController;
  final bool hasNew;
  final bool hasResults;
  final bool enableNotifications;
  final bool enableEmailNotifications;
  final String scope;
  final String ordering;
  final bool isSequentialSidebar;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<bool> onHasNewChanged;
  final ValueChanged<bool> onHasResultsChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onEmailNotificationsChanged;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<String> onOrderingChanged;
  final VoidCallback onReset;
  final VoidCallback onOpenAllNew;

  const _ClientSavedSearchesHeader({
    required this.queryController,
    required this.hasNew,
    required this.hasResults,
    required this.enableNotifications,
    required this.enableEmailNotifications,
    required this.scope,
    required this.ordering,
    required this.isSequentialSidebar,
    required this.onQueryChanged,
    required this.onHasNewChanged,
    required this.onHasResultsChanged,
    required this.onNotificationsChanged,
    required this.onEmailNotificationsChanged,
    required this.onScopeChanged,
    required this.onOrderingChanged,
    required this.onReset,
    required this.onOpenAllNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.read(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSequentialSidebar
                      ? 'Searches in sequence'.tr
                      : 'Saved searches'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onOpenAllNew,
                icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                label: Text('All new ads'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.themeColorText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: queryController,
            onChanged: onQueryChanged,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Search saved searches...'.tr,
              hintStyle: TextStyle(color: theme.textColor.withOpacity(0.55)),
              prefixIcon: Icon(Icons.search, color: theme.textColor),
              filled: true,
              fillColor: theme.textFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dashboardBoarder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dashboardBoarder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.themeColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: ordering,
                  isExpanded: true,
                  dropdownColor: theme.dashboardContainer,
                  decoration: InputDecoration(
                    labelText: 'Sort'.tr,
                    labelStyle: TextStyle(color: theme.textColor),
                    filled: true,
                    fillColor: theme.textFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: TextStyle(color: theme.textColor),
                  items: [
                    DropdownMenuItem(
                      value: 'new_desc',
                      child: Text('Most new'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'updated_desc',
                      child: Text('Recently updated'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'title_asc',
                      child: Text('Title A-Z'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'title_desc',
                      child: Text('Title Z-A'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'created_desc',
                      child: Text('Recently created'.tr),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onOrderingChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: scope.isEmpty ? '__all__' : scope,
                  isExpanded: true,
                  dropdownColor: theme.dashboardContainer,
                  decoration: InputDecoration(
                    labelText: 'Scope'.tr,
                    labelStyle: TextStyle(color: theme.textColor),
                    filled: true,
                    fillColor: theme.textFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: TextStyle(color: theme.textColor),
                  items: [
                    DropdownMenuItem(
                      value: '__all__',
                      child: Text('All'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'client',
                      child: Text('Client'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'transaction',
                      child: Text('Transaction'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'unassigned',
                      child: Text('Unassigned'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'mixed',
                      child: Text('Assigned'.tr),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onScopeChanged(value == '__all__' ? '' : value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('Has new'.tr),
                selected: hasNew,
                onSelected: onHasNewChanged,
              ),
              FilterChip(
                label: Text('Has results'.tr),
                selected: hasResults,
                onSelected: onHasResultsChanged,
              ),
              FilterChip(
                label: Text('Notifications'.tr),
                selected: enableNotifications,
                onSelected: onNotificationsChanged,
              ),
              FilterChip(
                label: Text('E-mail notifications'.tr),
                selected: enableEmailNotifications,
                onSelected: onEmailNotificationsChanged,
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: Icon(Icons.restart_alt, color: theme.textColor),
                label: Text(
                  'Reset'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientSavedSearchesPaginationFooter extends ConsumerWidget {
  final int totalCount;
  final int page;
  final int pageSize;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  const _ClientSavedSearchesPaginationFooter({
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final totalPages =
        totalCount <= 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${'Results'.tr}: $totalCount',
              style: TextStyle(
                color: theme.textColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<int>(
            value: pageSize,
            dropdownColor: theme.dashboardContainer,
            style: TextStyle(color: theme.textColor),
            items: const [50, 100, 200]
                .map(
                  (size) => DropdownMenuItem<int>(
                    value: size,
                    child: Text('$size / page'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onPageSizeChanged(value);
            },
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '$page / $totalPages',
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ClientInboxHeader extends ConsumerWidget {
  final String title;
  final ClientSavedSearchBrowseMode browseMode;
  final VoidCallback onBackToList;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenSearch;
  final VoidCallback onOpenFilters;

  const _ClientInboxHeader({
    required this.title,
    required this.browseMode,
    required this.onBackToList,
    required this.onRefresh,
    required this.onOpenSearch,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackToList,
            icon: Icon(Icons.arrow_back, color: theme.textColor),
            tooltip: 'Back to saved searches'.tr,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onOpenSearch != null)
            IconButton(
              onPressed: onOpenSearch,
              icon: Icon(Icons.travel_explore_outlined, color: theme.textColor),
              tooltip: 'Open search'.tr,
            ),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh, color: theme.textColor),
            tooltip: 'Refresh'.tr,
          ),
          IconButton(
            onPressed: onOpenFilters,
            icon: Icon(Icons.tune_rounded, color: theme.textColor),
            tooltip: 'Filters'.tr,
          ),
        ],
      ),
    );
  }
}

extension on BuildContext {
  T read<T>(ProviderListenable<T> provider) {
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }
}