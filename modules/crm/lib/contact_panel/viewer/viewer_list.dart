import 'package:calendar/models/event_model.dart';
import 'package:crm/contact_panel/viewer/on_hover_profile.dart';
import 'package:crm/contact_panel/viewer/viewer_calendar.dart';
import 'package:crm/contact_panel/viewer/viewer_note.dart';
import 'package:crm/contact_panel/viewer/viewer_statuses.dart';
import 'package:crm/your_agent/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/font_size.dart';
import 'package:core/theme/lottie.dart';

import 'package:core/platform/data_table_with_infinity_scroll.dart';
import 'package:core/platform/status_dropdown.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:crm/contact_panel/viewer/viewer_provider.dart';
import 'package:crm/contact_panel/viewer/viewer_models.dart';
import 'package:crm/contact_panel/viewer/viewer_dialog.dart';

enum _ViewMode { list, timeline }

class ViewerListClientTable extends ConsumerStatefulWidget {
  final int transactionId;
  final int? clientId;
  final bool isMobile;
  final bool isClient;

  /// Required for client portal tracking.
  final String? portalId;

  const ViewerListClientTable({
    super.key,
    required this.transactionId,
    this.clientId,
    this.isMobile = false,
    this.isClient = false,
    this.portalId,
  });

  @override
  ConsumerState<ViewerListClientTable> createState() =>
      _ViewerListClientTableState();
}

class _ViewerListClientTableState extends ConsumerState<ViewerListClientTable> {
  int _currentPage = 1;
  int _pageSize = 25;

  bool _collapsed = false;
  bool _showHidden = false;
  _ViewMode _viewMode = _ViewMode.list;

  String? _lastTrackedListSignature;

  List<ViewerItem> _slice(List<ViewerItem> all) {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= all.length) return const [];
    final end = (start + _pageSize) > all.length ? all.length : start + _pageSize;
    return all.sublist(start, end);
  }

  bool _isAddRow(ViewerItem v) => v.id == -1;

  String _viewerName(ViewerItem v) {
    return [v.name, v.lastName].where((e) => (e ?? '').isNotEmpty).join(' ');
  }

  String _fmtDateTime(DateTime? value) {
    if (value == null) return '—';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatEventRange(EventModel event) {
    final from = event.from;
    final to = event.to;
    final y = from.year.toString().padLeft(4, '0');
    final m = from.month.toString().padLeft(2, '0');
    final d = from.day.toString().padLeft(2, '0');
    final fh = from.hour.toString().padLeft(2, '0');
    final fm = from.minute.toString().padLeft(2, '0');
    final th = to.hour.toString().padLeft(2, '0');
    final tm = to.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $fh:$fm - $th:$tm';
  }

  List<ViewerItem> _currentlyDisplayed(List<ViewerItem> visible) {
    if (widget.isMobile) {
      return _slice(visible);
    }

    if (_viewMode == _ViewMode.timeline) {
      return visible;
    }

    return _slice(visible);
  }

  Future<void> _safeTrackClientEvent(
    String eventType, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!widget.isClient) return;
    final portalId = widget.portalId;
    if (portalId == null || portalId.trim().isEmpty) return;

    try {
      await ref.read(clientPortalActionsProvider).trackEvent(
            portalId: portalId,
            eventType: eventType,
            metadata: {
              'transaction_id': widget.transactionId,
              if (metadata != null) ...metadata,
            },
          );
    } catch (_) {
      // Silent on purpose – tracking must never break UI.
    }
  }

  void _maybeTrackPresentedList(List<ViewerItem> displayed) {
    if (!widget.isClient) return;
    final portalId = widget.portalId;
    if (portalId == null || portalId.trim().isEmpty) return;

    final viewerIds = displayed.map((e) => e.id).toList();
    final eventIds = <String>[];

    for (final viewer in displayed) {
      for (final event in viewer.events) {
        eventIds.add(event.id);
      }
    }

    final signature = [
      portalId,
      widget.transactionId,
      widget.isMobile,
      _viewMode.name,
      _currentPage,
      _pageSize,
      viewerIds.join(','),
      eventIds.join(','),
    ].join('|');

    if (_lastTrackedListSignature == signature) return;
    _lastTrackedListSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _safeTrackClientEvent(
        ClientPortalEventTypes.presentationsListView,
        metadata: {
          'viewer_ids': viewerIds,
          'event_ids': eventIds,
          'items': displayed
              .map(
                (viewer) => {
                  'viewer_id': viewer.id,
                  'contact_id': viewer.contactId,
                  'viewer_name': _viewerName(viewer),
                  'status_id': viewer.statusId,
                  'last_contact_at': viewer.lastContactAt,
                  'event_ids': viewer.events.map((e) => e.id).toList(),
                  'event_titles': viewer.events.map((e) => e.title).toList(),
                },
              )
              .toList(),
          'source': 'viewer_list_client_table',
        },
      );
    });
  }

  Future<void> _trackViewerOpen(ViewerItem viewer) async {
    await _safeTrackClientEvent(
      ClientPortalEventTypes.presentationItemOpen,
      metadata: {
        'viewer_id': viewer.id,
        'contact_id': viewer.contactId,
        'viewer_name': _viewerName(viewer),
        'status_id': viewer.statusId,
        'event_ids': viewer.events.map((e) => e.id).toList(),
        'event_titles': viewer.events.map((e) => e.title).toList(),
        'events_count': viewer.events.length,
        'source': 'viewer_open',
      },
    );
  }

  Future<void> _trackEventOpen(
    ViewerItem viewer,
    EventModel event,
  ) async {
    await _safeTrackClientEvent(
      ClientPortalEventTypes.presentationEventOpen,
      metadata: {
        'viewer_id': viewer.id,
        'contact_id': viewer.contactId,
        'viewer_name': _viewerName(viewer),
        'event_id': event.id,
        'event_title': event.title,
        'event_from': event.from.toIso8601String(),
        'event_to': event.to.toIso8601String(),
        'is_completed': event.isCompleted,
        'source': 'presentation_event_tap',
      },
    );
  }

  Future<void> _showClientPresentationSheet(
    BuildContext context,
    ThemeColors theme,
    ViewerItem viewer,
  ) async {
    await _trackViewerOpen(viewer);

    if (!mounted) return;

    await showModalBottomSheet(
      backgroundColor: theme.dashboardContainer,
      context: context,
      isScrollControlled: true,
      builder: (_) => _ClientPresentationEventsSheet(
        viewer: viewer,
        onEventTap: (event) async {
          await _trackEventOpen(viewer, event);
        },
      ),
    );
  }

  Future<void> _showAgentEventsSheet(
    BuildContext context,
    ViewerItem viewer,
  ) async {
    await showModalBottomSheet(
      backgroundColor: ref.read(themeColorsProvider).dashboardContainer,
      context: context,
      isScrollControlled: true,
      builder: (_) => ViewerEventsSheet(
        clientId: widget.clientId ?? viewer.contactId,
        txId: widget.transactionId,
        viewer: viewer,
        onChanged: () => ref.invalidate(
          viewersForTransactionProvider(widget.transactionId),
        ),
      ),
    );
  }

  Future<void> _openEvents(
    BuildContext context,
    ThemeColors theme,
    ViewerItem viewer,
  ) async {
    if (widget.isClient) {
      await _showClientPresentationSheet(context, theme, viewer);
      return;
    }

    await _showAgentEventsSheet(context, viewer);
  }

  Future<bool?> openAddViewerResponsive(
    BuildContext context, {
    required int transactionId,
    required ThemeColors theme,
  }) async {
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 720;
    final isDesktopLike = kIsWeb ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux;

    final isMobile = !isDesktopLike || isNarrow;

    if (!isMobile) {
      return showDialog<bool>(
        context: context,
        builder: (_) => AddViewerDialog(transactionId: transactionId),
      );
    }

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(color: theme.dashboardBoarder),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dashboardBoarder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        child: AddViewerDialog(
                          transactionId: transactionId,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _statusLabelFor(
    ViewerItem viewer,
    List<dynamic> statuses,
  ) {
    for (final status in statuses) {
      final statusId = status.id;
      if (statusId == viewer.statusId) {
        return status.label?.toString() ?? '—';
      }
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final size = ref.watch(fontSizeProvider(context));
    final padding = size.logoSize(4, 12);

    final viewersAsync =
        ref.watch(viewersForTransactionProvider(widget.transactionId));
    final statusesAsync = ref.watch(viewerStatusTypesProvider);

    Widget topBar(int hiddenCount, List<ViewerItem> visible) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
        child: Row(
          children: [
            if (!widget.isClient)
              OutlinedButton(
                onPressed: hiddenCount == 0
                    ? null
                    : () => setState(() => _showHidden = !_showHidden),
                child: Text(
                  _showHidden
                      ? 'hide_hidden_button'.tr
                      : '${'show_hidden_button'.tr} ($hiddenCount)'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            if (widget.isClient)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'presentation_list_title'.tr,
                  style: AppTextStyles.interSemiBold16
                      .copyWith(color: theme.textColor),
                ),
              ),
            const Spacer(),
            if (!widget.isClient)
              IconButton(
                tooltip: 'manage_statuses_title'.tr,
                icon: AppIcons.moreVertical(color: theme.textColor),
                onPressed: () => showDialog(
                  context: context,
                  builder: (dCtx) => Dialog(
                    backgroundColor: theme.adPopBackground,
                    insetPadding: const EdgeInsets.all(12),
                    child: const SizedBox(
                      width: 520,
                      height: 520,
                      child: ViewerStatusDialog(),
                    ),
                  ),
                ),
              ),
            if (!widget.isMobile)
              IconButton(
                tooltip: _viewMode == _ViewMode.list
                    ? 'show_timeline_tooltip'.tr
                    : 'show_list_tooltip'.tr,
                icon: _viewMode == _ViewMode.list
                    ? AppIcons.calendar(color: theme.textColor)
                    : AppIcons.viewList(color: theme.textColor),
                onPressed: () => setState(() {
                  _viewMode = _viewMode == _ViewMode.list
                      ? _ViewMode.timeline
                      : _ViewMode.list;
                }),
              ),
            if (!widget.isClient)
              TextButton.icon(
                onPressed: () async {
                  final added = await openAddViewerResponsive(
                    context,
                    transactionId: widget.transactionId,
                    theme: theme,
                  );
                  if (added == true) {
                    ref.invalidate(
                      viewersForTransactionProvider(widget.transactionId),
                    );
                  }
                },
                icon: AppIcons.add(color: theme.textColor),
                label: Text(
                  'add_button'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
          ],
        ),
      );
    }

    return viewersAsync.when(
      data: (allRaw) {
        final hiddenCount = allRaw.where((v) => v.isHide).length;
        final visible =
            _showHidden ? allRaw : allRaw.where((v) => !v.isHide).toList();

        final displayedNow = _currentlyDisplayed(visible);
        _maybeTrackPresentedList(displayedNow);

        if (_collapsed) {
          return Column(
            children: [
              topBar(hiddenCount, visible),
            ],
          );
        }

        if (allRaw.isEmpty) {
          return Column(
            children: [
              topBar(hiddenCount, visible),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppLottie.noResults(),
                          const SizedBox(height: 12),
                          Text(
                            'no_viewers_for_transaction'.tr,
                            style: AppTextStyles.interLight16.copyWith(
                              color: theme.textColor,
                            ),
                          ),
                          if (!widget.isClient) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final added = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AddViewerDialog(
                                    transactionId: widget.transactionId,
                                  ),
                                );
                                if (added == true) {
                                  ref.invalidate(
                                    viewersForTransactionProvider(
                                      widget.transactionId,
                                    ),
                                  );
                                }
                              },
                              icon: AppIcons.add(color: theme.textColor),
                              label: Text(
                                'add_viewer_button'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // MOBILE
        if (widget.isMobile) {
          final items = _slice(visible);

          return Column(
            children: [
              topBar(hiddenCount, visible),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(padding),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _ViewerMobileCard(
                    viewer: items[i],
                    theme: theme,
                    statusesAsync: statusesAsync,
                    isClient: widget.isClient,
                    statusLabelBuilder: (viewer, statuses) =>
                        _statusLabelFor(viewer, statuses),
                    onOpenEvents: () => _openEvents(context, theme, items[i]),
                    onOpenContact: widget.isClient
                        ? null
                        : () => ref
                            .read(navigationService)
                            .pushNamedScreen('/contacts/${items[i].contactId}'),
                    onStatusChange: (newId) async {
                      await setViewerStatusForTx(
                        txId: widget.transactionId,
                        viewerId: items[i].id,
                        statusId: newId,
                      );
                      ref.invalidate(
                        viewersForTransactionProvider(widget.transactionId),
                      );
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('status_updated_message'.tr),
                        ),
                      );
                    },
                    onEditNote: () async {
                      final saved = await showDialog<bool>(
                        context: context,
                        builder: (_) => ViewerNoteDialog(
                          transactionId: widget.transactionId,
                          viewerId: items[i].id,
                          initialNote: items[i].note ?? '',
                        ),
                      );
                      if (saved == true) {
                        ref.invalidate(
                          viewersForTransactionProvider(widget.transactionId),
                        );
                      }
                    },
                    onToggleHide: () async {
                      final isHidden = items[i].isHide;
                      await setHideViewerContact(
                        txId: widget.transactionId,
                        viewerId: items[i].id,
                        isHide: !isHidden,
                      );
                      ref.invalidate(
                        viewersForTransactionProvider(widget.transactionId),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isHidden ? 'unhidden_message'.tr : 'hidden_message'.tr),
                        ),
                      );
                    },
                    onRemove: () async {
                      await removeViewerFromTx(
                        txId: widget.transactionId,
                        viewerId: items[i].id,
                      );
                      ref.invalidate(
                        viewersForTransactionProvider(widget.transactionId),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('deleted_message'.tr)),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        // DESKTOP TIMELINE
        if (_viewMode == _ViewMode.timeline) {
          final items = _flattenAndSortEvents(visible);

          return Column(
            children: [
              topBar(hiddenCount, visible),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppLottie.noResults(),
                            const SizedBox(height: 12),
                            Text(
                              'no_events_for_viewers'.tr,
                              style: AppTextStyles.interLight16.copyWith(
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final it = items[i];
                          final showDateHeader = i == 0 ||
                              !_isSameDay(
                                items[i - 1].event.from,
                                it.event.from,
                              );
                          final timeRange =
                              '${_fmt(it.event.from)} – ${_fmt(it.event.to)}';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 12, bottom: 8),
                                  child: Text(
                                    _dateLabel(it.event.from),
                                    style: AppTextStyles.interSemiBold16
                                        .copyWith(color: theme.textColor),
                                  ),
                                ),
                              _TimelineTile(
                                themeTextColor: theme.textColor,
                                avatarUrl: it.viewer.avatar,
                                viewerName: _viewerName(it.viewer),
                                title: it.event.title,
                                timeRange: timeRange,
                                isCompleted: it.event.isCompleted,
                                onTap: () async {
                                  if (widget.isClient) {
                                    await _trackEventOpen(it.viewer, it.event);
                                    if (!mounted) return;
                                    await showDialog(
                                      context: context,
                                      builder: (_) => _ClientPresentationEventDialog(
                                        event: it.event,
                                      ),
                                    );
                                    return;
                                  }

                                  await _openEvents(context, theme, it.viewer);
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        }

        // DESKTOP CLIENT TABLE (read-only)
        if (widget.isClient) {
          final rows = _slice(visible);

          return Column(
            children: [
              topBar(hiddenCount, visible),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: statusesAsync.when(
                    data: (statuses) {
                      return AppPaginatedTable<ViewerItem>(
                        selectable: false,
                        rows: rows,
                        totalCount: visible.length,
                        rowKey: (v) => v.id,
                        headingColor: theme.dashboardContainer,
                        columns: [
                          AppTableColumn<ViewerItem>(
                            header: Row(
                              children: [
                                const SizedBox(width: 70),
                                Text(
                                  'person_column_header'.tr,
                                  style: TextStyle(color: theme.textColor),
                                ),
                              ],
                            ),
                            flex: 3,
                            cellBuilder: (ctx, v) => Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundImage:
                                          (v.avatar != null &&
                                                  v.avatar!.isNotEmpty)
                                              ? NetworkImage(v.avatar!)
                                              : null,
                                      child: (v.avatar == null ||
                                              v.avatar!.isEmpty)
                                          ? AppIcons.person(
                                              color: theme.textColor,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    _viewerName(v).isEmpty
                                        ? '—'
                                        : _viewerName(v),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppTableColumn<ViewerItem>(
                            header: Text(
                              'status_column_header'.tr,
                              style: TextStyle(color: theme.textColor),
                            ),
                            width: 220,
                            cellBuilder: (ctx, v) => Text(
                              _statusLabelFor(v, statuses),
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                          AppTableColumn<ViewerItem>(
                            header: Text(
                              'last_contact_column_header'.tr,
                              style: TextStyle(color: theme.textColor),
                            ),
                            width: 180,
                            cellBuilder: (ctx, v) => Text(
                              _fmtDateTime(v.lastContactAt as DateTime?),
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                          AppTableColumn<ViewerItem>(
                            header: Text(
                              'events_column_header'.tr,
                              style: TextStyle(color: theme.textColor),
                            ),
                            width: 180,
                            cellBuilder: (ctx, v) {
                              final count = v.events.length;
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => _openEvents(context, theme, v),
                                  icon: AppIcons.calendar(
                                    color: theme.textColor,
                                  ),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'show_button'.tr,
                                        style:
                                            TextStyle(color: theme.textColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          color: theme.dashboardContainer,
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        selectedKeys: const <Object>{},
                        onSelectionChanged: (_) {},
                        onRowTap: (v) async {
                          await _openEvents(context, theme, v);
                        },
                        currentPage: _currentPage,
                        pageSize: _pageSize,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                        onPageSizeChanged: (s) => setState(() {
                          _pageSize = s;
                          _currentPage = 1;
                        }),
                        enableInfiniteScroll: true,
                        appendPaging: false,
                        emptyText: 'no_presentations_message'.tr,
                        rowExtent: 56,
                        headerExtent: 56,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        '${'statuses_error_prefix'.tr} $e',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // DESKTOP AGENT TABLE
        final rows = _slice(visible);
        final rowsWithAdd = [
          ...rows,
          ViewerItem(
            id: -1,
            contactId: 0,
            transactionId: widget.transactionId,
            name: null,
            lastName: null,
            email: null,
            phone: null,
            avatar: null,
            statusId: null,
            note: null,
            lastContactAt: null,
            isHide: false,
            events: const [],
          ),
        ];

        return Column(
          children: [
            topBar(hiddenCount, visible),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: AppPaginatedTable<ViewerItem>(
                  selectable: false,
                  rows: rowsWithAdd,
                  totalCount: visible.length,
                  rowKey: (v) => v.id == -1 ? Object() : v.id,
                  headingColor: theme.dashboardContainer,
                  columns: [
                    AppTableColumn<ViewerItem>(
                      header: Row(
                        children: [
                          const SizedBox(width: 70),
                          Text(
                            'contact_column_header'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ],
                      ),
                      flex: 3,
                      cellBuilder: (ctx, v) => _isAddRow(v)
                          ? const SizedBox.shrink()
                          : ProfileHoverRegion(
                              profile: ProfileHoverData.fromViewer(v),
                              theme: theme,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage:
                                            (v.avatar != null &&
                                                    v.avatar!.isNotEmpty)
                                                ? NetworkImage(v.avatar!)
                                                : null,
                                        child: (v.avatar == null ||
                                                v.avatar!.isEmpty)
                                            ? AppIcons.person(
                                                color: theme.textColor,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => ref
                                          .read(navigationService)
                                          .pushNamedScreen(
                                            '/contacts/${v.contactId}',
                                          ),
                                      child: Text(
                                        _viewerName(v),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            TextStyle(color: theme.textColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    AppTableColumn<ViewerItem>(
                      header: Text(
                        'events_column_header'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                      width: 180,
                      cellBuilder: (ctx, v) {
                        if (_isAddRow(v)) return const SizedBox.shrink();
                        final count = v.events.length;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openEvents(context, theme, v),
                            icon: AppIcons.calendar(color: theme.textColor),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'show_button'.tr,
                                  style: TextStyle(color: theme.textColor),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: theme.dashboardContainer,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    AppTableColumn<ViewerItem>(
                      header: Text(
                        'note_column_header'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                      flex: 3,
                      cellBuilder: (ctx, v) {
                        if (_isAddRow(v)) return const SizedBox.shrink();
                        final preview = (v.note ?? '').trim();
                        final short = preview.length <= 50
                            ? preview
                            : '${preview.substring(0, 50)}…';

                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: () async {
                                  final saved = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => ViewerNoteDialog(
                                      transactionId: widget.transactionId,
                                      viewerId: v.id,
                                      initialNote: v.note ?? '',
                                    ),
                                  );
                                  if (saved == true) {
                                    ref.invalidate(
                                      viewersForTransactionProvider(
                                        widget.transactionId,
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        preview.isEmpty
                                            ? 'add_note_button'.tr
                                            : short,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            TextStyle(color: theme.textColor),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    AppIcons.pencil(color: theme.textColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    AppTableColumn<ViewerItem>(
                      header: Text(
                        'actions_column_header'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                      width: 280,
                      cellBuilder: (ctx, v) {
                        if (_isAddRow(v)) return const SizedBox.shrink();
                        return statusesAsync.when(
                          data: (opts) => Row(
                            children: [
                              Expanded(
                                child: AppStatusDropdownField(
                                  ref: ref,
                                  value: v.statusId,
                                  options: opts
                                      .map(
                                        (o) => StatusOption(
                                          id: o.id,
                                          label: o.label,
                                          index: o.index,
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (newId) async {
                                    await setViewerStatusForTx(
                                      txId: widget.transactionId,
                                      viewerId: v.id,
                                      statusId: newId,
                                    );
                                    ref.invalidate(
                                      viewersForTransactionProvider(
                                        widget.transactionId,
                                      ),
                                    );
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('status_updated_message'.tr),
                                      ),
                                    );
                                  },
                                  haveBorder: false,
                                  haveLabel: false,
                                  width: 220,
                                  height: 44,
                                ),
                              ),
                            ],
                          ),
                          loading: () => const SizedBox(
                            width: 220,
                            height: 44,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text('${'Error'.tr} $e'),
                        );
                      },
                    ),
                    AppTableColumn<ViewerItem>(
                      header: Text(
                        'actions_column_header'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                      width: 92,
                      cellBuilder: (ctx, v) {
                        if (_isAddRow(v)) return const SizedBox.shrink();
                        final isHidden = v.isHide;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: isHidden
                                  ? 'unhide_row_tooltip'.tr
                                  : 'hide_row_tooltip'.tr,
                              icon: FaIcon(
                                isHidden
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                              ),
                              onPressed: () async {
                                await setHideViewerContact(
                                  txId: widget.transactionId,
                                  viewerId: v.id,
                                  isHide: !isHidden,
                                );
                                ref.invalidate(
                                  viewersForTransactionProvider(
                                    widget.transactionId,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isHidden ? 'unhidden_message'.tr : 'hidden_message'.tr,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'remove_from_viewers_tooltip'.tr,
                              icon: AppIcons.delete(color: theme.textColor),
                              onPressed: () async {
                                await removeViewerFromTx(
                                  txId: widget.transactionId,
                                  viewerId: v.id,
                                );
                                ref.invalidate(
                                  viewersForTransactionProvider(
                                    widget.transactionId,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('deleted_message'.tr)),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  selectedKeys: const <Object>{},
                  onSelectionChanged: (_) {},
                  onRowTap: (v) {
                    if (_isAddRow(v)) return;
                    ref.read(navigationService).pushNamedScreen(
                          '/contacts/${v.contactId}',
                        );
                  },
                  currentPage: _currentPage,
                  pageSize: _pageSize,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  onPageSizeChanged: (s) => setState(() {
                    _pageSize = s;
                    _currentPage = 1;
                  }),
                  enableInfiniteScroll: true,
                  appendPaging: false,
                  emptyText: 'no_viewers_message'.tr,
                  rowExtent: 56,
                  headerExtent: 56,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error: $e'.tr,
          style: AppTextStyles.interLight,
        ),
      ),
    );
  }

  List<_EventLineItem> _flattenAndSortEvents(List<ViewerItem> viewers) {
    final list = <_EventLineItem>[];
    for (final v in viewers) {
      for (final e in v.events) {
        list.add(_EventLineItem(v, e));
      }
    }
    list.sort((a, b) => a.event.from.compareTo(b.event.from));
    return list;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmt(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

// ────────────────────────────────────────────────────────────────
// MOBILE CARD

class _ViewerMobileCard extends ConsumerWidget {
  const _ViewerMobileCard({
    required this.viewer,
    required this.theme,
    required this.statusesAsync,
    required this.isClient,
    required this.statusLabelBuilder,
    required this.onOpenEvents,
    required this.onOpenContact,
    required this.onStatusChange,
    required this.onEditNote,
    required this.onToggleHide,
    required this.onRemove,
  });

  final ViewerItem viewer;
  final ThemeColors theme;
  final AsyncValue<dynamic> statusesAsync;
  final bool isClient;
  final String Function(ViewerItem viewer, List<dynamic> statuses)
      statusLabelBuilder;
  final VoidCallback onOpenEvents;
  final VoidCallback? onOpenContact;
  final Future<void> Function(int?) onStatusChange;
  final VoidCallback onEditNote;
  final VoidCallback onToggleHide;
  final VoidCallback onRemove;

  String _name(ViewerItem v) =>
      [v.name, v.lastName].where((e) => (e ?? '').isNotEmpty).join(' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = _name(viewer);
    final note = (viewer.note ?? '').trim();
    final noteShort = note.length <= 70 ? note : '${note.substring(0, 70)}…';
    final eventsCount = viewer.events.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(31),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    (viewer.avatar != null && viewer.avatar!.isNotEmpty)
                        ? NetworkImage(viewer.avatar!)
                        : null,
                child: (viewer.avatar == null || viewer.avatar!.isEmpty)
                    ? AppIcons.person(color: theme.textColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onOpenContact,
                  child: Text(
                    name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interSemiBold16
                        .copyWith(color: theme.textColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Row(
                  children: [
                    AppIcons.calendar(color: theme.textColor),
                    const SizedBox(width: 6),
                    Text(
                      '$eventsCount',
                      style: TextStyle(color: theme.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if ((viewer.email ?? '').isNotEmpty || (viewer.phone ?? '').isNotEmpty)
            Row(
              children: [
                if ((viewer.email ?? '').isNotEmpty) ...[
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: theme.textColor.withAlpha(204),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      viewer.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(230),
                      ),
                    ),
                  ),
                ],
                if ((viewer.email ?? '').isNotEmpty &&
                    (viewer.phone ?? '').isNotEmpty)
                  const SizedBox(width: 12),
                if ((viewer.phone ?? '').isNotEmpty) ...[
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: theme.textColor.withAlpha(204),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      viewer.phone!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(230),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 10),

          if (!isClient)
            Align(
              alignment: Alignment.centerLeft,
              child: statusesAsync.when(
                data: (opts) => SizedBox(
                  width: double.infinity,
                  child: AppStatusDropdownField(
                    ref: ref,
                    value: viewer.statusId,
                    options: opts,
                    onChanged: onStatusChange,
                    haveBorder: true,
                    haveLabel: false,
                    height: 44,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 44,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  '${'statuses_error_prefix'} $e',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: statusesAsync.when(
                data: (opts) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.adPopBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dashboardBoarder),
                  ),
                  child: Text(
                    '${'Status'.tr}: ${statusLabelBuilder(viewer, opts)}',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                loading: () => const SizedBox(
                  height: 44,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

          if (!isClient) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: onEditNote,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AppIcons.pencil(color: theme.textColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            note.isEmpty ? 'add_note_button'.tr : noteShort,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenEvents,
                  icon: AppIcons.calendar(color: theme.textColor),
                  label: Text(
                    isClient ? 'show_presentations_button'.tr:  'Events'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
              if (!isClient) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: viewer.isHide ? 'unhide_button'.tr: 'hide'.tr,
                  icon: FaIcon(
                    viewer.isHide
                        ? FontAwesomeIcons.eyeSlash
                        : FontAwesomeIcons.eye,
                  ),
                  onPressed: onToggleHide,
                ),
                IconButton(
                  tooltip: 'btn_delete'.tr,
                  icon: AppIcons.delete(color: theme.textColor),
                  onPressed: onRemove,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────── Timeline helpers ─────────────

class _EventLineItem {
  final ViewerItem viewer;
  final EventModel event;
  _EventLineItem(this.viewer, this.event);
}

class _TimelineTile extends StatelessWidget {
  final String? avatarUrl;
  final String viewerName;
  final String title;
  final String timeRange;
  final bool isCompleted;
  final VoidCallback? onTap;
  final Color themeTextColor;

  const _TimelineTile({
    super.key,
    required this.viewerName,
    required this.title,
    required this.timeRange,
    required this.isCompleted,
    required this.themeTextColor,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeTextColor.withAlpha(230),
                ),
              ),
              Container(
                width: 2,
                height: 42,
                color: themeTextColor.withAlpha(51),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeTextColor.withAlpha(31)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? NetworkImage(avatarUrl!)
                            : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: themeTextColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$viewerName • $timeRange',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: themeTextColor.withAlpha(204),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted) const SizedBox(width: 8),
                  if (isCompleted)
                    const Icon(Icons.check_circle, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// CLIENT READ-ONLY SHEET

class _ClientPresentationEventsSheet extends ConsumerWidget {
  final ViewerItem viewer;
  final Future<void> Function(EventModel event)? onEventTap;

  const _ClientPresentationEventsSheet({
    required this.viewer,
    this.onEventTap,
  });

  String _viewerName() {
    return [viewer.name, viewer.lastName]
        .where((e) => (e ?? '').isNotEmpty)
        .join(' ');
  }

  String _fmtRange(EventModel event) {
    final from = event.from;
    final to = event.to;
    final y = from.year.toString().padLeft(4, '0');
    final m = from.month.toString().padLeft(2, '0');
    final d = from.day.toString().padLeft(2, '0');
    final fh = from.hour.toString().padLeft(2, '0');
    final fm = from.minute.toString().padLeft(2, '0');
    final th = to.hour.toString().padLeft(2, '0');
    final tm = to.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $fh:$fm - $th:$tm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final events = viewer.events;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _viewerName().isEmpty
                  ? 'presentation_label'.tr
                  : _viewerName(),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${'events_count_label'.tr}: ${events.length}',
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Text(
                        'no_events_message'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final event = events[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            if (onEventTap != null) {
                              await onEventTap!(event);
                            }
                            if (!context.mounted) return;
                            await showDialog(
                              context: context,
                              builder: (_) => _ClientPresentationEventDialog(
                                event: event,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.adPopBackground,
                              border: Border.all(color: theme.dashboardBoarder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _fmtRange(event),
                                  style: TextStyle(
                                    color: theme.textColor.withAlpha(185),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  event.isCompleted
                                      ? 'completed_status'.tr
                                      : 'scheduled_status'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                  ),
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
      ),
    );
  }
}

class _ClientPresentationEventDialog extends ConsumerWidget {
  final EventModel event;

  const _ClientPresentationEventDialog({
    required this.event,
  });

  String _fmtRange() {
    final from = event.from;
    final to = event.to;
    final y = from.year.toString().padLeft(4, '0');
    final m = from.month.toString().padLeft(2, '0');
    final d = from.day.toString().padLeft(2, '0');
    final fh = from.hour.toString().padLeft(2, '0');
    final fm = from.minute.toString().padLeft(2, '0');
    final th = to.hour.toString().padLeft(2, '0');
    final tm = to.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $fh:$fm - $th:$tm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return AlertDialog(
      backgroundColor: theme.dashboardContainer,
      title: Text(
        event.title,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EventInfoRow(
            label: 'date_label'.tr,
            value: _fmtRange(),
          ),
          _EventInfoRow(
            label: 'status_label'.tr,
            value: event.isCompleted ? 'completed_status'.tr : 'scheduled_status'.tr,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'close_button'.tr,
            style: TextStyle(color: theme.textColor),
          ),
        ),
      ],
    );
  }
}

class _EventInfoRow extends ConsumerWidget {
  final String label;
  final String value;

  const _EventInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}