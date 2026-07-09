import 'dart:async';

import 'package:crm/bars/client_tile.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:mail/components/scheduled_emails_with_preview_mobile.dart';
import 'package:mail/utils/api_services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/theme/button_style.dart';

import '../emma/anchors/anchors_mail.dart';
import '../models/mail_models.dart';
import '../models/mailbox_query.dart';
import '../provider/mailbox_providers.dart';
import '../utils/mail_filters.dart';
import '../utils/mail_thread_tree.dart';
import '../utils/utils.dart';
import 'mail_detail.dart';
import 'mail_top_bar.dart';

class _MailListDatePresentation {
  final String primary;
  final String? secondary;

  const _MailListDatePresentation({
    required this.primary,
    this.secondary,
  });
}

DateTime? _parseMailListDate(dynamic raw) {
  if (raw == null) return null;

  if (raw is DateTime) {
    return raw.toLocal();
  }

  if (raw is num) {
    final millis = raw > 1000000000000
        ? raw.toInt()
        : (raw * 1000).toInt();

    return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  }

  final value = raw.toString().trim();
  if (value.isEmpty) return null;

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;

  return parsed.toLocal();
}

DateTime? _emailListDateOf(EmailMessage email) {
  final candidates = <dynamic>[
    email.timelineAtIso,
    email.receivedAt,
    email.sentAt,
    email.createdAt,
    email.updatedAt,
  ];

  for (final candidate in candidates) {
    final parsed = _parseMailListDate(candidate);
    if (parsed != null) return parsed;
  }

  return null;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

bool _sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _monthShortPl(int month) {
  const months = [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paź',
    'lis',
    'gru',
  ];

  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

String _relativeMailDateLabel(DateTime date, DateTime now) {
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'przed chwilą';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
  if (diff.inHours < 24) return '${diff.inHours} godz. temu';

  return '';
}

_MailListDatePresentation _formatMailListDate(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();

  final time = '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  final relative = _relativeMailDateLabel(local, now);

  if (_sameCalendarDay(local, now)) {
    return _MailListDatePresentation(
      primary: 'Dziś $time',
      secondary: relative.isEmpty ? null : relative,
    );
  }

  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (_sameCalendarDay(local, yesterday)) {
    return _MailListDatePresentation(
      primary: 'Wczoraj $time',
    );
  }

  if (local.year == now.year) {
    return _MailListDatePresentation(
      primary: '${local.day} ${_monthShortPl(local.month)}',
      secondary: time,
    );
  }

  return _MailListDatePresentation(
    primary:
        '${_twoDigits(local.day)}.${_twoDigits(local.month)}.${local.year}',
    secondary: time,
  );
}

Widget _buildMailListDateBadge({
  required ThemeColors theme,
  required EmailMessage email,
  required bool isRead,
  bool compact = false,
}) {
  final date = _emailListDateOf(email);
  if (date == null) return const SizedBox.shrink();

  final formatted = _formatMailListDate(date);

  final primaryColor = isRead
      ? theme.textColor.withAlpha(125)
      : theme.textColor.withAlpha(230);

  final secondaryColor = isRead
      ? theme.textColor.withAlpha(95)
      : theme.themeColor.withAlpha(220);

  return Tooltip(
    message:
        '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatted.primary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryColor,
            fontSize: compact ? 10 : 11,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
            height: 1.1,
          ),
        ),
        if (formatted.secondary != null) ...[
          const SizedBox(height: 2),
          Text(
            formatted.secondary!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: secondaryColor,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ],
    ),
  );
}

class EmailListWithPreviewMobile extends ConsumerStatefulWidget {
  final String? email;
  final int? leadId;
  final dynamic lead;
  final bool isMobile;
  final bool enableBulkSelection;

  const EmailListWithPreviewMobile({
    super.key,
    this.leadId,
    this.lead,
    this.email,
    required this.isMobile,
    this.enableBulkSelection = false,
  });

  @override
  ConsumerState<EmailListWithPreviewMobile> createState() =>
      _EmailListWithPreviewMobileState();
}

class _EmailListWithPreviewMobileState
    extends ConsumerState<EmailListWithPreviewMobile> {
  int? selectedEmailId;

  Timer? _refreshDebounce;

  DateTime? _lastQueryStartedAt;
  static const Duration _emptyStateGracePeriod =
      Duration(milliseconds: 900);

  bool _serverHistoryModeEnabled = false;
  bool _olderLoadQueued = false;

  final Set<String> _expandedThreadIds = <String>{};

  ProviderSubscription? _filtersSub1;
  ProviderSubscription? _filtersSub2;
  ProviderSubscription? _filtersSub3;
  ProviderSubscription? _filtersSub4;
  ProviderSubscription? _filtersSub5;
  ProviderSubscription? _filtersSub6;
  ProviderSubscription? _filtersSub7;
  ProviderSubscription? _filtersSub8;
  ProviderSubscription? _filtersSub9;
  ProviderSubscription? _filtersSub10;

  late MailboxQuery _mailboxQuery;

  @override
  void initState() {
    super.initState();

    _mailboxQuery = _buildQuery(
      fallbackLeadId: widget.leadId,
      fallbackEmail: widget.email,
    );
    _lastQueryStartedAt = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mailLeadIdProvider.notifier).state = widget.leadId;
      ref.read(mailEmailProvider.notifier).state = widget.email;
      _rebuildQuery(resetSelectedEmail: false);
    });

    void scheduleRefresh() {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _rebuildQuery();
      });
    }

    _filtersSub1 = ref.listenManual(
      mailTypeProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub2 = ref.listenManual(
      mailSearchProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub3 = ref.listenManual(
      mailPageSizeProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub4 = ref.listenManual(
      mailLeadIdProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub5 = ref.listenManual(
      mailEmailProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub6 = ref.listenManual(
      mailSortProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub7 = ref.listenManual(
      selectedEmailAccountIdProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub8 = ref.listenManual(
      selectedEmailTabIdProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub9 = ref.listenManual(
      selectedEmailTagIdsProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
    _filtersSub10 = ref.listenManual(
      mailRefreshTickProvider,
      (_, __) => scheduleRefresh(),
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();

    _filtersSub1?.close();
    _filtersSub2?.close();
    _filtersSub3?.close();
    _filtersSub4?.close();
    _filtersSub5?.close();
    _filtersSub6?.close();
    _filtersSub7?.close();
    _filtersSub8?.close();
    _filtersSub9?.close();
    _filtersSub10?.close();

    final leadIdNotifier = ref.read(mailLeadIdProvider.notifier);
    final emailNotifier = ref.read(mailEmailProvider.notifier);

    super.dispose();

    Future.microtask(() {
      leadIdNotifier.state = null;
      emailNotifier.state = null;
    });
  }

  MailboxQuery _buildQuery({
    int? fallbackLeadId,
    String? fallbackEmail,
  }) {
    final selectedSort = ref.read(mailSortProvider);
    final selectedType = ref.read(mailTypeProvider);
    final selectedSearch = ref.read(mailSearchProvider);
    final selectedLeadId = ref.read(mailLeadIdProvider) ?? fallbackLeadId;
    final selectedEmail = ref.read(mailEmailProvider) ?? fallbackEmail;
    final selectedAccount = ref.read(selectedEmailAccountProvider);
    final selectedAccountId = ref.read(selectedEmailAccountIdProvider);
    final pageSize = ref.read(mailPageSizeProvider);
    final currentTabId = ref.read(selectedEmailTabIdProvider);
    final tags = ref.read(selectedEmailTagIdsProvider).toList();

    String ordering;
    switch (selectedSort) {
      case 'received_at_asc':
        ordering = 'timeline_at';
        break;
      case 'received_at_desc':
      default:
        ordering = '-timeline_at';
        break;
    }

    final namespace = _buildStorageNamespace(
      accountEmail: selectedAccount?.emailAddress,
      accountId: selectedAccountId,
    );

    return MailboxQuery(
      tagIds: tags,
      currentTabId: currentTabId,
      storageNamespace: namespace,
      emailAccountId: selectedAccountId,
      mailType: selectedType,
      search: selectedSearch,
      leadId: selectedLeadId != 0 ? selectedLeadId : null,
      email: selectedEmail,
      ordering: ordering,
      maxLocal: pageSize,
    );
  }

  String _buildStorageNamespace({
    required String? accountEmail,
    required int? accountId,
  }) {
    final normalizedEmail = accountEmail?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) {
      return 'mail_local::$normalizedEmail';
    }
    if (accountId != null) {
      return 'mail_local::account_$accountId';
    }
    return 'mail_local::default';
  }

  void _rebuildQuery({bool resetSelectedEmail = true}) {
    if (!mounted) return;

    setState(() {
      _lastQueryStartedAt = DateTime.now();
      _mailboxQuery = _buildQuery();
      _serverHistoryModeEnabled = false;
      _olderLoadQueued = false;
      _expandedThreadIds.clear();

      if (resetSelectedEmail) {
        selectedEmailId = null;
      }
    });
  }

  void _toggleThread(String threadId) {
    setState(() {
      if (_expandedThreadIds.contains(threadId)) {
        _expandedThreadIds.remove(threadId);
      } else {
        _expandedThreadIds.add(threadId);
      }
    });
  }

  bool _shouldHoldEmptyState({
    required dynamic mailboxState,
    required List<EmailMessage> items,
  }) {
    final isInGracePeriod = _lastQueryStartedAt != null &&
        DateTime.now().difference(_lastQueryStartedAt!) <
            _emptyStateGracePeriod;

    return items.isEmpty &&
        (mailboxState.isLoadingLocal == true ||
            mailboxState.isSyncing == true ||
            isInGracePeriod);
  }

  void _queueAutoLoadOlderIfNeeded({
    required dynamic mailboxState,
    required dynamic mailboxController,
    required List<EmailMessage> items,
  }) {
    if (!mounted) return;
    if (items.isEmpty) return;
    if (mailboxState.hasOlder != true) return;
    if (mailboxState.isLoadingMore == true) return;
    if (_olderLoadQueued) return;

    _olderLoadQueued = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _olderLoadQueued = false;
      if (!mounted) return;

      if (!_serverHistoryModeEnabled) {
        setState(() {
          _serverHistoryModeEnabled = true;
        });
      }

      await mailboxController.loadOlder();
    });
  }

  Color _parseColor(String? hex, Color fallback) {
    final normalized = (hex ?? '').replaceAll('#', '').trim();
    if (normalized.isEmpty) return fallback;

    final value = normalized.length == 6
        ? 'FF$normalized'
        : normalized.padLeft(8, 'F');

    return Color(int.tryParse(value, radix: 16) ?? fallback.value);
  }

  Widget _buildMiniChip({
    required ThemeColors theme,
    required String label,
    required IconData icon,
    String? colorHex,
  }) {
    final color = _parseColor(colorHex, theme.themeColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(220),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChips(EmailMessage email, ThemeColors theme) {
    final visibleTags = email.tags.take(2).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (email.currentTabName.isNotEmpty)
          _buildMiniChip(
            theme: theme,
            label: email.currentTabName,
            icon: Icons.folder_open_outlined,
            colorHex: email.currentTabColor,
          ),
        if (email.isEmma)
          _buildMiniChip(
            theme: theme,
            label: 'Emma',
            icon: Icons.smart_toy_outlined,
            colorHex: '#692125',
          ),
        if (email.isEmmaDirectSend)
          _buildMiniChip(
            theme: theme,
            label: 'Direct',
            icon: Icons.send_outlined,
            colorHex: '#14B8A6',
          ),
        if (email.effectiveIsSpam)
          _buildMiniChip(
            theme: theme,
            label: 'Spam',
            icon: Icons.report_gmailerrorred_outlined,
            colorHex: '#DC2626',
          ),
        if ((email.unsubscribeUrl ?? '').isNotEmpty ||
            (email.unsubscribeMailto ?? '').isNotEmpty)
          _buildMiniChip(
            theme: theme,
            label: 'Unsubscribe',
            icon: Icons.unsubscribe_outlined,
            colorHex: '#F59E0B',
          ),
        ...visibleTags.map(
          (tag) => _buildMiniChip(
            theme: theme,
            label: tag.name,
            icon: Icons.sell_outlined,
            colorHex: tag.color,
          ),
        ),
      ],
    );
  }

  Future<void> _openEmailDetails({
    required BuildContext context,
    required EmailMessage email,
    required dynamic mailboxController,
    String? threadId,
    bool isTreeMode = false,
  }) async {
    if (isTreeMode) {
      _expandedThreadIds.add(threadId ?? threadIdOfMail(email));
    }

    if (!email.isRead) {
      unawaited(mailboxController.markEmailAsRead(email.id));
    }

    if (email.isEmma) {
      unawaited(mailboxController.touchEmmaSeen(email.id));
    }

    setState(() => selectedEmailId = email.id);

    final sheetCtrl = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(6),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          controller: sheetCtrl,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, sc) {
            return EmailDetail(
              emailId: email.id,
              isMobile: true,
              scrollController: sc,
              sheetController: sheetCtrl,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final selectionMode = widget.enableBulkSelection
        ? ref.watch(mailSelectionModeProvider)
        : false;
    final selectedIds = widget.enableBulkSelection
        ? ref.watch(selectedMailIdsProvider)
        : <int>{};
    final showCheckboxes = selectionMode || selectedIds.isNotEmpty;
    final notConnected = ref.watch(emailConnectionErrorProvider);

    final isClientListExpanded = ref.watch(clientListMobileVisibilityProvider);
    final selectedType = ref.watch(mailTypeProvider);

    if (selectedType == 'scheduled') {
      return const ScheduledEmailsWithPreviewMobile(isMobile: true);
    }

    final mailboxState = ref.watch(mailboxControllerProvider(_mailboxQuery));
    final mailboxController =
        ref.read(mailboxControllerProvider(_mailboxQuery).notifier);

    final isTreeMode =
        ref.watch(mailListViewModeProvider) == MailListViewMode.tree;

    final listView = _buildListView(
      theme: theme,
      mailboxState: mailboxState,
      mailboxController: mailboxController,
      selectionMode: selectionMode,
      selectedIds: selectedIds,
      showCheckboxes: showCheckboxes,
      notConnected: notConnected,
      isTreeMode: isTreeMode,
    );

    return EmmaUiAnchorTarget(
      anchorKey: EmmaAnchors.mailMobileList.anchorKey,

      spec: EmmaAnchors.mailMobileList,
      runtimeMode: EmmaAnchors.mailMobileList.runtimeMode,
      tapMode: EmmaAnchors.mailMobileList.tapMode,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            if (widget.enableBulkSelection) ...[
            if (isClientListExpanded) const SizedBox(height: 64),
            MailTopBar(
              isMobile: true,
              enableBulkSelection: widget.enableBulkSelection,
            ),
            if (mailboxState.isSyncing == true)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(theme.themeColor),
              ),
            if (_serverHistoryModeEnabled)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dashboardBoarder.withAlpha(120),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      size: 16,
                      color: theme.themeColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reached local cache. Older messages load automatically from server.'
                            .tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(210),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (showCheckboxes && selectedIds.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dashboardBoarder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: theme.themeColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${selectedIds.length} selected'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ref.read(mailSelectionModeProvider.notifier).state =
                            false;
                        ref.read(selectedMailIdsProvider.notifier).state =
                            <int>{};
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.close,
                              size: 18,
                              color: theme.textColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cancel'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: widget.enableBulkSelection && selectedIds.isNotEmpty
                  ? DndSender(
                      payload: DndPayload(
                        type: DndPayloadType.email,
                        action: 'assign_emails',
                        subActions: const [
                          'assign_emails',
                          'send_to_spam',
                          'move_to_tab',
                        ],
                        id: 'bulk',
                        data: {
                          'emails': selectedIds.toList(),
                        },
                      ),
                      useLongPress: true,
                      feedbackBuilder: (context) =>
                          DragFeedbackBuilders.emailsFeedback(
                        context,
                        selectedIds.length,
                      ),
                      child: listView,
                    )
                  : listView,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildListView({
    required ThemeColors theme,
    required dynamic mailboxState,
    required dynamic mailboxController,
    required bool selectionMode,
    required Set<int> selectedIds,
    required bool showCheckboxes,
    required bool notConnected,
    required bool isTreeMode,
  }) {
    final items = (mailboxState.items as List).cast<EmailMessage>();

    if (_shouldHoldEmptyState(
      mailboxState: mailboxState,
      items: items,
    )) {
      return _ShimmerEmailListMobile(
        theme: theme,
        showCheckboxes: showCheckboxes,
      );
    }

    if (mailboxState.error != null && items.isEmpty && !notConnected) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${"Error".tr}: ${mailboxState.error}',
                style: AppTextStyles.interLight14
                    .copyWith(color: theme.textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => mailboxController.refreshHard(),
                child: Text('Try Again'.tr),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      if (notConnected) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Your email is not connected to Hously.\nPlease create an account with this email in Hously first."
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }

      return Center(child: AppLottie.noResults(size: 450));
    }

    final treeRows = isTreeMode
        ? buildMailTreeRows(
            items,
            expandedThreadIds: _expandedThreadIds,
            selectedEmailId: selectedEmailId,
          )
        : <MailTreeRow>[];

    return RefreshIndicator(
      onRefresh: () async {
        await mailboxController.refreshHard();
      },
      child: ListView.builder(
        padding: EdgeInsets.zero,
        cacheExtent: 400,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: (isTreeMode ? treeRows.length : items.length) +
            (mailboxState.hasOlder == true ? 1 : 0),
        itemBuilder: (context, index) {
          final visibleLength = isTreeMode ? treeRows.length : items.length;

          if (index == visibleLength) {
            _queueAutoLoadOlderIfNeeded(
              mailboxState: mailboxState,
              mailboxController: mailboxController,
              items: items,
            );

            return _OlderMessagesFooterMobile(
              theme: theme,
              isLoading: mailboxState.isLoadingMore == true || _olderLoadQueued,
              text: 'Loading older messages from server...'.tr,
            );
          }

          late final EmailMessage email;
          late final int depth;
          late final bool canToggleThread;
          late final bool isThreadExpanded;
          late final int hiddenChildrenCount;
          late final String? threadId;

          if (isTreeMode) {
            final row = treeRows[index];
            email = row.email;
            depth = row.depth;
            canToggleThread = row.canToggleThread;
            isThreadExpanded = row.isThreadExpanded;
            hiddenChildrenCount = row.hiddenChildrenCount;
            threadId = row.threadId;
          } else {
            email = items[index];
            depth = 0;
            canToggleThread = false;
            isThreadExpanded = false;
            hiddenChildrenCount = 0;
            threadId = null;
          }

          final int emailId = email.id;
          final bool isSelected = emailId == selectedEmailId;

          final emailSubject = shortenText(email.subject, 25);
          final senderPrimary = email.senderDisplayName.trim().isNotEmpty
              ? email.senderDisplayName
              : email.sender;
          final emailSender = shortenText(senderPrimary, 35);
          final bool isRead = email.isRead;

          final emailTile = TextButton(
            style: buildSelectEmail(isSelected, theme.adPopBackground),
            onPressed: () {
              if (showCheckboxes) {
                final newSet = Set<int>.from(selectedIds);

                if (newSet.contains(emailId)) {
                  newSet.remove(emailId);
                } else {
                  newSet.add(emailId);
                }

                ref.read(selectedMailIdsProvider.notifier).state = newSet;
                ref.read(mailSelectionModeProvider.notifier).state =
                    newSet.isNotEmpty;
              } else {
                _openEmailDetails(
                  context: context,
                  email: email,
                  mailboxController: mailboxController,
                  threadId: threadId,
                  isTreeMode: isTreeMode,
                );
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCheckboxes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: selectedIds.contains(emailId),
                        onChanged: (value) {
                          final newSet = Set<int>.from(selectedIds);

                          if (value == true) {
                            newSet.add(emailId);
                          } else {
                            newSet.remove(emailId);
                          }

                          ref.read(selectedMailIdsProvider.notifier).state =
                              newSet;
                          ref.read(mailSelectionModeProvider.notifier).state =
                              newSet.isNotEmpty;
                        },
                      ),
                    ),
                  ),
                if (isTreeMode)
                  Padding(
                    padding: EdgeInsets.only(
                      left: (depth * 14).toDouble(),
                      right: 6,
                      top: 2,
                    ),
                    child: SizedBox(
                      width: 20,
                      child: canToggleThread
                          ? InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _toggleThread(threadId!),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  isThreadExpanded
                                      ? Icons.expand_more
                                      : Icons.chevron_right,
                                  size: 18,
                                  color: theme.themeColor,
                                ),
                              ),
                            )
                          : depth > 0
                              ? Icon(
                                  Icons.subdirectory_arrow_right_rounded,
                                  size: 15,
                                  color: theme.textColor.withAlpha(140),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              emailSubject,
                              style: AppTextStyles.interSemiBold16.copyWith(
                                color: isRead
                                    ? theme.textColor.withAlpha(140)
                                    : theme.textColor,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 82),
                            child: _buildMailListDateBadge(
                              theme: theme,
                              email: email,
                              isRead: isRead,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              emailSender,
                              style: AppTextStyles.interLight14.copyWith(
                                color: isRead
                                    ? theme.textColor.withAlpha(120)
                                    : theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canToggleThread && hiddenChildrenCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.themeColor.withAlpha(18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: theme.themeColor.withAlpha(80),
                                ),
                              ),
                              child: Text(
                                isThreadExpanded
                                    ? '${hiddenChildrenCount + 1} in thread'.tr
                                    : '+$hiddenChildrenCount ${"replies".tr}',
                                style: TextStyle(
                                  color: theme.themeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMetaChips(email, theme),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (!showCheckboxes) {
            return DndSender(
              payload: DndPayload(
                type: DndPayloadType.email,
                action: 'assign_emails',
                subActions: const [
                  'assign_emails',
                  'send_to_spam',
                  'move_to_tab',
                ],
                id: emailId.toString(),
                data: {
                  'emails': [emailId],
                  'subject': emailSubject,
                  'sender': emailSender,
                  'current_tab_id': email.currentTabId,
                  'current_tab_name': email.currentTabName,
                  'tag_ids': email.tags.map((e) => e.id).toList(),
                  'is_emma': email.isEmma,
                  'is_emma_direct_send': email.isEmmaDirectSend,
                  'effective_is_spam': email.effectiveIsSpam,
                  'thread_id': threadId ?? threadIdOfMail(email),
                },
              ),
              useLongPress: true,
              feedbackBuilder: (context) =>
                  DragFeedbackBuilders.emailsFeedback(context, 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: emailTile,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: emailTile,
          );
        },
      ),
    );
  }
}

class _OlderMessagesFooterMobile extends StatelessWidget {
  final ThemeColors theme;
  final bool isLoading;
  final String text;

  const _OlderMessagesFooterMobile({
    required this.theme,
    required this.isLoading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: isLoading
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.themeColor),
                    )
                  : Icon(
                      Icons.history,
                      size: 18,
                      color: theme.themeColor,
                    ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor.withAlpha(210),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerEmailListMobile extends StatelessWidget {
  final ThemeColors theme;
  final bool showCheckboxes;

  const _ShimmerEmailListMobile({
    required this.theme,
    required this.showCheckboxes,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, __) => _ShimmerEmailTileMobile(
        theme: theme,
        showCheckboxes: showCheckboxes,
      ),
    );
  }
}

class _ShimmerEmailTileMobile extends StatelessWidget {
  final ThemeColors theme;
  final bool showCheckboxes;

  const _ShimmerEmailTileMobile({
    required this.theme,
    required this.showCheckboxes,
  });

  @override
  Widget build(BuildContext context) {
    final base = theme.textColor.withAlpha(25);
    final highlight = theme.textColor.withAlpha(70);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheckboxes)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Shimmer.fromColors(
                baseColor: base,
                highlightColor: highlight,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: base,
                      highlightColor: highlight,
                      child: Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Shimmer.fromColors(
                      baseColor: base,
                      highlightColor: highlight,
                      child: Container(
                        height: 10,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: base,
                  highlightColor: highlight,
                  child: Container(
                    height: 12,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: base,
                  highlightColor: highlight,
                  child: Container(
                    height: 18,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}