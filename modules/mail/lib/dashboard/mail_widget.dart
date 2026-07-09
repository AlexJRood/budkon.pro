import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import 'package:mail/components/mail_detail.dart';
import 'package:mail/models/mail_models.dart';
import 'package:mail/models/mailbox_query.dart';
import 'package:mail/provider/mailbox_providers.dart';
import 'package:mail/send_mail/send_mail.dart';
import 'package:mail/utils/api_services.dart';

enum DashboardMailFilter {
  latest,
  unread,
  inbox,
  sent,
  emma,
}

extension DashboardMailFilterX on DashboardMailFilter {
  String get key {
    switch (this) {
      case DashboardMailFilter.latest:
        return 'latest';
      case DashboardMailFilter.unread:
        return 'unread';
      case DashboardMailFilter.inbox:
        return 'inbox';
      case DashboardMailFilter.sent:
        return 'sent';
      case DashboardMailFilter.emma:
        return 'emma';
    }
  }

  String get label {
    switch (this) {
      case DashboardMailFilter.latest:
        return 'Latest';
      case DashboardMailFilter.unread:
        return 'Only new';
      case DashboardMailFilter.inbox:
        return 'Received';
      case DashboardMailFilter.sent:
        return 'Sent';
      case DashboardMailFilter.emma:
        return 'Emma';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardMailFilter.latest:
        return Icons.schedule_rounded;
      case DashboardMailFilter.unread:
        return Icons.mark_email_unread_outlined;
      case DashboardMailFilter.inbox:
        return Icons.inbox_outlined;
      case DashboardMailFilter.sent:
        return Icons.send_outlined;
      case DashboardMailFilter.emma:
        return Icons.smart_toy_outlined;
    }
  }

  String get mailboxType {
    switch (this) {
      case DashboardMailFilter.latest:
      case DashboardMailFilter.unread:
        return 'all';
      case DashboardMailFilter.inbox:
        return 'inbox';
      case DashboardMailFilter.sent:
        return 'sent';
      case DashboardMailFilter.emma:
        return 'emma';
    }
  }

  static DashboardMailFilter fromRaw(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'unread':
      case 'new':
      case 'only_new':
        return DashboardMailFilter.unread;
      case 'inbox':
      case 'received':
        return DashboardMailFilter.inbox;
      case 'sent':
        return DashboardMailFilter.sent;
      case 'emma':
        return DashboardMailFilter.emma;
      case 'latest':
      default:
        return DashboardMailFilter.latest;
    }
  }
}

enum DashboardMailLayout {
  auto,
  vertical,
  horizontal,
}

extension DashboardMailLayoutX on DashboardMailLayout {
  String get key {
    switch (this) {
      case DashboardMailLayout.auto:
        return 'auto';
      case DashboardMailLayout.vertical:
        return 'vertical';
      case DashboardMailLayout.horizontal:
        return 'horizontal';
    }
  }

  String get label {
    switch (this) {
      case DashboardMailLayout.auto:
        return 'Auto';
      case DashboardMailLayout.vertical:
        return 'Vertical';
      case DashboardMailLayout.horizontal:
        return 'Horizontal';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardMailLayout.auto:
        return Icons.auto_awesome_motion_outlined;
      case DashboardMailLayout.vertical:
        return Icons.view_agenda_outlined;
      case DashboardMailLayout.horizontal:
        return Icons.view_column_outlined;
    }
  }

  static DashboardMailLayout fromRaw(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'vertical':
        return DashboardMailLayout.vertical;
      case 'horizontal':
        return DashboardMailLayout.horizontal;
      case 'auto':
      default:
        return DashboardMailLayout.auto;
    }
  }
}

class DashboardMailWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final Map<String, dynamic> settings;

  /// Zmień, jeśli u Ciebie routing maila jest pod inną ścieżką.
  final String mailRoute;

  const DashboardMailWidget({
    super.key,
    required this.isMobile,
    this.settings = const {},
    this.mailRoute = '/mail',
  });

  @override
  ConsumerState<DashboardMailWidget> createState() =>
      _DashboardMailWidgetState();
}

class _DashboardMailWidgetState extends ConsumerState<DashboardMailWidget> {
  int? _selectedEmailId;
  DashboardMailFilter? _runtimeFilter;
  DashboardMailLayout? _runtimeLayout;

  MailboxQuery? _mailboxQuery;
  String? _querySignature;

  DashboardMailFilter get _filter {
    return _runtimeFilter ?? DashboardMailFilterX.fromRaw(widget.settings['filter']);
  }

  DashboardMailLayout get _layout {
    return _runtimeLayout ?? DashboardMailLayoutX.fromRaw(widget.settings['layout']);
  }

  int get _limit {
    final raw = widget.settings['limit'];
    final parsed = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    return (parsed ?? 12).clamp(3, 50);
  }

  bool get _showPreview {
    final raw = widget.settings['showPreview'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _showAccountSwitcher {
    final raw = widget.settings['showAccountSwitcher'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _compact {
    final raw = widget.settings['compact'];
    if (raw is bool) return raw;
    return false;
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

  MailboxQuery _buildQuery({
    required DashboardMailFilter filter,
    required int? accountId,
    required String? accountEmail,
  }) {
    return MailboxQuery(
      currentTabId: null,
      tagIds: const [],
      storageNamespace: _buildStorageNamespace(
        accountEmail: accountEmail,
        accountId: accountId,
      ),
      emailAccountId: accountId,
      mailType: filter.mailboxType,
      search: '',
      leadId: null,
      email: null,
      ordering: '-timeline_at',
      maxLocal: _limit,
    );
  }

  String _buildQuerySignature({
    required DashboardMailFilter filter,
    required int? accountId,
    required String? accountEmail,
  }) {
    return [
      filter.key,
      accountId?.toString() ?? 'null',
      accountEmail ?? '',
      _limit.toString(),
    ].join('|');
  }

  List<EmailMessage> _applyRuntimeFilter(List<EmailMessage> items) {
    final filter = _filter;

    switch (filter) {
      case DashboardMailFilter.unread:
        return items.where((e) => !e.isRead).toList(growable: false);
      case DashboardMailFilter.emma:
        return items.where((e) => e.isEmma).toList(growable: false);
      case DashboardMailFilter.latest:
      case DashboardMailFilter.inbox:
      case DashboardMailFilter.sent:
        return items;
    }
  }

  String _bestTimeIso(EmailMessage email) {
    final candidates = [
      email.timelineAtIso,
      email.receivedAt,
      email.sentAt,
      email.createdAt,
      email.updatedAt,
    ];

    for (final raw in candidates) {
      final value = raw?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return '';
  }

  String _formatTime(String rawIso) {
    final parsed = DateTime.tryParse(rawIso);
    if (parsed == null) return '';

    final local = parsed.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day.$month';
  }

  String _shorten(String value, int max) {
    final trimmed = value.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max).trim()}...';
  }

  Future<void> _refresh(MailboxQuery query) async {
    await ref.read(mailboxControllerProvider(query).notifier).refreshHard();
  }

  void _openMailModule(BuildContext context) {
    Navigator.of(context).pushNamed(widget.mailRoute);
  }

  Future<void> _openEmail({
    required BuildContext context,
    required MailboxQuery query,
    required EmailMessage email,
    required bool openAsSheet,
  }) async {
    final controller = ref.read(mailboxControllerProvider(query).notifier);

    if (!email.isRead) {
      unawaited(controller.markEmailAsRead(email.id));
    }

    if (email.isEmma) {
      unawaited(controller.touchEmmaSeen(email.id));
    }

    if (!openAsSheet) {
      setState(() => _selectedEmailId = email.id);
      return;
    }

    setState(() => _selectedEmailId = email.id);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final theme = ref.read(themeColorsProvider);

        return DraggableScrollableSheet(
          initialChildSize: widget.isMobile ? 0.92 : 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Container(
                color: theme.dashboardContainer,
                child: EmailDetail(
                  emailId: email.id,
                  isMobile: widget.isMobile,
                ),
              ),
            );
          },
        );
      },
    );
  }

  DashboardMailLayout _resolveLayout({
    required BoxConstraints constraints,
  }) {
    final configured = _layout;

    if (configured != DashboardMailLayout.auto) {
      return configured;
    }

    if (widget.isMobile) {
      return DashboardMailLayout.vertical;
    }

    final canUseHorizontal =
        constraints.maxWidth >= 680 && constraints.maxHeight >= 330;

    return canUseHorizontal
        ? DashboardMailLayout.horizontal
        : DashboardMailLayout.vertical;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final selectedAccount = ref.watch(selectedEmailAccountProvider);
    final selectedAccountId = ref.watch(selectedEmailAccountIdProvider);

    final filter = _filter;

    final nextSignature = _buildQuerySignature(
      filter: filter,
      accountId: selectedAccountId,
      accountEmail: selectedAccount?.emailAddress,
    );

    if (_querySignature != nextSignature || _mailboxQuery == null) {
      _querySignature = nextSignature;
      _mailboxQuery = _buildQuery(
        filter: filter,
        accountId: selectedAccountId,
        accountEmail: selectedAccount?.emailAddress,
      );
      _selectedEmailId = null;
    }

    final query = _mailboxQuery!;
    final mailboxState = ref.watch(mailboxControllerProvider(query));

    final rawItems = (mailboxState.items as List).cast<EmailMessage>();
    final items = _applyRuntimeFilter(rawItems).take(_limit).toList();

    final unreadCount = rawItems.where((e) => !e.isRead).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedLayout = _resolveLayout(constraints: constraints);
        final showSidePreview = resolvedLayout == DashboardMailLayout.horizontal &&
            _showPreview &&
            !widget.isMobile;

        return Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dashboardBoarder,
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _MailDashboardHeader(
                  theme: theme,
                  filter: filter,
                  layout: _layout,
                  unreadCount: unreadCount,
                  compact: _compact || constraints.maxHeight < 360,
                  onFilterChanged: (value) {
                    setState(() {
                      _runtimeFilter = value;
                      _querySignature = null;
                    });
                  },
                  onLayoutChanged: (value) {
                    setState(() => _runtimeLayout = value);
                  },
                  onRefresh: () => _refresh(query),
                  onOpenMail: () => _openMailModule(context),
                  onNewMessage: () => showEmailOverlay(context, ref),
                ),
                if (_showAccountSwitcher)
                  _MailAccountSwitcher(
                    theme: theme,
                    compact: _compact || constraints.maxWidth < 420,
                    onChanged: () {
                      setState(() {
                        _querySignature = null;
                        _selectedEmailId = null;
                      });
                    },
                  ),
                if (mailboxState.isSyncing == true)
                  LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.themeColor,
                    ),
                  ),
                Expanded(
                  child: showSidePreview
                      ? Row(
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * 0.42,
                              child: _MailDashboardList(
                                theme: theme,
                                query: query,
                                items: items,
                                isLoading: mailboxState.isLoadingLocal == true,
                                error: mailboxState.error,
                                selectedEmailId: _selectedEmailId,
                                compact: _compact,
                                onOpenEmail: (email) => _openEmail(
                                  context: context,
                                  query: query,
                                  email: email,
                                  openAsSheet: false,
                                ),
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: theme.dashboardBoarder,
                            ),
                            Expanded(
                              child: _selectedEmailId == null
                                  ? _MailEmptyPreview(theme: theme)
                                  : EmailDetail(
                                      emailId: _selectedEmailId!,
                                      isMobile: false,
                                    ),
                            ),
                          ],
                        )
                      : _MailDashboardList(
                          theme: theme,
                          query: query,
                          items: items,
                          isLoading: mailboxState.isLoadingLocal == true,
                          error: mailboxState.error,
                          selectedEmailId: _selectedEmailId,
                          compact: _compact,
                          onOpenEmail: (email) => _openEmail(
                            context: context,
                            query: query,
                            email: email,
                            openAsSheet: true,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MailDashboardHeader extends StatelessWidget {
  final ThemeColors theme;
  final DashboardMailFilter filter;
  final DashboardMailLayout layout;
  final int unreadCount;
  final bool compact;
  final ValueChanged<DashboardMailFilter> onFilterChanged;
  final ValueChanged<DashboardMailLayout> onLayoutChanged;
  final VoidCallback onRefresh;
  final VoidCallback onOpenMail;
  final VoidCallback onNewMessage;

  const _MailDashboardHeader({
    required this.theme,
    required this.filter,
    required this.layout,
    required this.unreadCount,
    required this.compact,
    required this.onFilterChanged,
    required this.onLayoutChanged,
    required this.onRefresh,
    required this.onOpenMail,
    required this.onNewMessage,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 54.0 : 64.0;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder.withAlpha(160),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.themeColor.withAlpha(80),
              ),
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: theme.themeColor,
              size: compact ? 18 : 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: compact
                ? Text(
                    'Mail'.tr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mail'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unreadCount > 0
                            ? '$unreadCount ${"new messages".tr}'
                            : 'No new messages'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(165),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          _HeaderPopupButton<DashboardMailFilter>(
            theme: theme,
            tooltip: 'Filter'.tr,
            icon: filter.icon,
            items: DashboardMailFilter.values,
            selected: filter,
            labelBuilder: (e) => e.label.tr,
            iconBuilder: (e) => e.icon,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 6),
          _HeaderPopupButton<DashboardMailLayout>(
            theme: theme,
            tooltip: 'Layout'.tr,
            icon: layout.icon,
            items: DashboardMailLayout.values,
            selected: layout,
            labelBuilder: (e) => e.label.tr,
            iconBuilder: (e) => e.icon,
            onSelected: onLayoutChanged,
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            theme: theme,
            tooltip: 'Refresh'.tr,
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            theme: theme,
            tooltip: 'Go to mail'.tr,
            icon: Icons.open_in_new_rounded,
            onTap: onOpenMail,
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            theme: theme,
            tooltip: 'New message'.tr,
            icon: Icons.add_rounded,
            filled: true,
            onTap: onNewMessage,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? theme.themeColor : theme.adPopBackground;
    final fg = filled ? theme.themeTextColor : theme.textColor;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled
                  ? theme.themeColor.withAlpha(160)
                  : theme.dashboardBoarder.withAlpha(150),
            ),
          ),
          child: Icon(icon, color: fg, size: 18),
        ),
      ),
    );
  }
}

class _HeaderPopupButton<T> extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final List<T> items;
  final T selected;
  final String Function(T item) labelBuilder;
  final IconData Function(T item) iconBuilder;
  final ValueChanged<T> onSelected;

  const _HeaderPopupButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<T>(
        color: theme.adPopBackground,
        tooltip: tooltip,
        onSelected: onSelected,
        itemBuilder: (_) {
          return items.map((item) {
            final isSelected = item == selected;

            return PopupMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Icon(
                    iconBuilder(item),
                    size: 17,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labelBuilder(item),
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: theme.themeColor,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dashboardBoarder.withAlpha(150),
            ),
          ),
          child: Icon(icon, color: theme.textColor, size: 18),
        ),
      ),
    );
  }
}

class _MailAccountSwitcher extends ConsumerWidget {
  final ThemeColors theme;
  final bool compact;
  final VoidCallback onChanged;

  const _MailAccountSwitcher({
    required this.theme,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(emailAccountsProvider);
    final selectedAccount = ref.watch(selectedEmailAccountProvider);

    return Container(
      height: compact ? 42 : 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(120),
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder.withAlpha(130),
          ),
        ),
      ),
      child: accountsAsync.when(
        loading: () => Row(
          children: [
            Icon(Icons.alternate_email_rounded, size: 16, color: theme.textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Loading accounts...'.tr,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor.withAlpha(170),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        error: (_, __) => Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: theme.textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load email accounts'.tr,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor.withAlpha(170),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Row(
              children: [
                Icon(Icons.mail_outline_rounded, size: 16, color: theme.textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No connected email accounts'.tr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          }

          final active = selectedAccount ?? accounts.first;
          final canSwitch = accounts.length > 1;

          return Row(
            children: [
              Icon(Icons.alternate_email_rounded, size: 16, color: theme.themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active.emailAddress,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canSwitch)
                PopupMenuButton<int>(
                  color: theme.adPopBackground,
                  onSelected: (id) {
                    ref.read(selectedEmailAccountIdProvider.notifier).state = id;
                    onChanged();
                  },
                  itemBuilder: (_) {
                    return accounts.map((account) {
                      final isSelected = account.id == active.id;

                      return PopupMenuItem<int>(
                        value: account.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                account.emailAddress,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: theme.themeColor,
                              ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MailDashboardList extends StatelessWidget {
  final ThemeColors theme;
  final MailboxQuery query;
  final List<EmailMessage> items;
  final bool isLoading;
  final Object? error;
  final int? selectedEmailId;
  final bool compact;
  final ValueChanged<EmailMessage> onOpenEmail;

  const _MailDashboardList({
    required this.theme,
    required this.query,
    required this.items,
    required this.isLoading,
    required this.error,
    required this.selectedEmailId,
    required this.compact,
    required this.onOpenEmail,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const _MailDashboardLoading();
    }

    if (error != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            '${'Failed to load emails'.tr}: $error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: theme.textColor.withAlpha(120),
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'No emails to show'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor.withAlpha(180),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: EdgeInsets.all(compact ? 8 : 10),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: compact ? 6 : 8),
        itemBuilder: (context, index) {
          final email = items[index];

          return _MailDashboardTile(
            theme: theme,
            email: email,
            isSelected: selectedEmailId == email.id,
            compact: compact,
            onTap: () => onOpenEmail(email),
          );
        },
      ),
    );
  }
}

class _MailDashboardTile extends StatelessWidget {
  final ThemeColors theme;
  final EmailMessage email;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _MailDashboardTile({
    required this.theme,
    required this.email,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  String _bestTimeIso(EmailMessage email) {
    final candidates = [
      email.timelineAtIso,
      email.receivedAt,
      email.sentAt,
      email.createdAt,
      email.updatedAt,
    ];

    for (final raw in candidates) {
      final value = raw?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return '';
  }

  String _formatTime(String rawIso) {
    final parsed = DateTime.tryParse(rawIso);
    if (parsed == null) return '';

    final local = parsed.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day.$month';
  }

  String _shorten(String value, int max) {
    final trimmed = value.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max).trim()}...';
  }

  @override
  Widget build(BuildContext context) {
    final sender = email.senderDisplayName.trim().isNotEmpty
        ? email.senderDisplayName.trim()
        : email.sender.trim();

    final subject = email.subject.trim().isNotEmpty
        ? email.subject.trim()
        : '(No subject)'.tr;

    final time = _formatTime(_bestTimeIso(email));
    final isUnread = !email.isRead;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.themeColor.withAlpha(26)
            : theme.adPopBackground.withAlpha(isUnread ? 230 : 155),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.themeColor.withAlpha(145)
              : isUnread
                  ? theme.themeColor.withAlpha(70)
                  : theme.dashboardBoarder.withAlpha(145),
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 9 : 11,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? theme.themeColor.withAlpha(30)
                        : theme.textColor.withAlpha(14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isUnread
                        ? Icons.mark_email_unread_outlined
                        : Icons.mail_outline_rounded,
                    color: isUnread ? theme.themeColor : theme.textColor.withAlpha(150),
                    size: compact ? 16 : 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _shorten(sender, 34),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isUnread
                                    ? theme.textColor
                                    : theme.textColor.withAlpha(160),
                                fontSize: compact ? 12 : 13,
                                fontWeight:
                                    isUnread ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(130),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _shorten(subject, compact ? 45 : 70),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnread
                              ? theme.textColor.withAlpha(220)
                              : theme.textColor.withAlpha(135),
                          fontSize: compact ? 11 : 12,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (!compact &&
                          (email.isEmma ||
                              email.isEmmaDirectSend ||
                              email.effectiveIsSpam ||
                              email.currentTabName.isNotEmpty ||
                              email.tags.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (email.currentTabName.isNotEmpty)
                              _MailMiniChip(
                                theme: theme,
                                label: email.currentTabName,
                                icon: Icons.folder_open_outlined,
                              ),
                            if (email.isEmma)
                              _MailMiniChip(
                                theme: theme,
                                label: 'Emma',
                                icon: Icons.smart_toy_outlined,
                              ),
                            if (email.isEmmaDirectSend)
                              _MailMiniChip(
                                theme: theme,
                                label: 'Direct',
                                icon: Icons.bolt_outlined,
                              ),
                            if (email.effectiveIsSpam)
                              _MailMiniChip(
                                theme: theme,
                                label: 'Spam',
                                icon: Icons.report_gmailerrorred_outlined,
                              ),
                            ...email.tags.take(2).map(
                                  (tag) => _MailMiniChip(
                                    theme: theme,
                                    label: tag.name,
                                    icon: Icons.sell_outlined,
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MailMiniChip extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final IconData icon;

  const _MailMiniChip({
    required this.theme,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.themeColor.withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.themeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(190),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MailEmptyPreview extends StatelessWidget {
  final ThemeColors theme;

  const _MailEmptyPreview({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline_rounded,
              color: theme.textColor.withAlpha(110),
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              'Select a message'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MailDashboardLoading extends StatelessWidget {
  const _MailDashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}