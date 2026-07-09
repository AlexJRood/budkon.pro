import 'dart:ui';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:mail/settings/settings_mail_pc.dart';
import '../emma/anchors/anchors_mail.dart';
import '../utils/mail_filters.dart';
import '../utils/api_services.dart';
import '../send_mail/send_mail.dart';
import '../provider/mail_taxonomy_providers.dart';
import '../provider/sidebar_order_provider.dart';

class MailSidebar extends ConsumerWidget {
  final double width;
  final bool isTablet;
  final int? leadId;
  final dynamic lead;

  const MailSidebar({
    super.key,
    this.width = 240,
    this.isTablet = false,
    this.leadId,
    this.lead,
  });

  void _selectMailType(WidgetRef ref, String value) {
    ref.read(mailTypeProvider.notifier).state = value;
    ref.read(mailPageProvider.notifier).state = 1;
    ref.read(selectedEmailTabIdProvider.notifier).state = null;

    if (value == 'scheduled') {
      ref.invalidate(scheduledPendingEmailsProvider);
      ref.invalidate(scheduledSentEmailsProvider);
    }

    triggerMailRefresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTagIds = ref.watch(selectedEmailTagIdsProvider);
    final theme = ref.watch(themeColorsProvider);

    final double tagsHeight = (MediaQuery.of(context).size.height * 0.28)
        .clamp(150.0, 250.0)
        .toDouble();

    Widget buildSortButton() {
      return Container(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 48,
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dashboardBoarder.withAlpha(180),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: theme.adPopBackground,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            value: ref.watch(mailSortProvider),
            icon: Icon(Icons.expand_more, color: theme.textColor),
            style: TextStyle(color: theme.textColor),
            onChanged: (value) {
              if (value == null) return;

              ref.read(mailSortProvider.notifier).state = value;
              ref.read(mailPageProvider.notifier).state = 1;
              triggerMailRefresh(ref);
            },
            items: [
              DropdownMenuItem(
                value: 'received_at_desc',
                child: Text(
                  'Newest'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              DropdownMenuItem(
                value: 'received_at_asc',
                child: Text(
                  'Oldest'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return EmmaUiAnchorTarget(
      anchorKey: EmmaAnchors.mailPcSidebar.anchorKey,
      spec: EmmaAnchors.mailPcSidebar,
      runtimeMode: EmmaAnchors.mailPcSidebar.runtimeMode,
      tapMode: EmmaAnchors.mailPcSidebar.tapMode,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              EmmaUiAnchorTarget(
                anchorKey: EmmaAnchors.mailPcAccountSwitcher.anchorKey,
                spec: EmmaAnchors.mailPcAccountSwitcher,
                runtimeMode: EmmaAnchors.mailPcAccountSwitcher.runtimeMode,
                tapMode: EmmaAnchors.mailPcAccountSwitcher.tapMode,
                child: buildSwitchAccountBox(context, ref, theme),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    border: Border.all(
                      color: theme.dashboardBoarder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      EmmaUiAnchorTarget(
                        anchorKey: EmmaAnchors.mailPcSortDropdown.anchorKey,
                        spec: EmmaAnchors.mailPcSortDropdown,
                        runtimeMode: EmmaAnchors.mailPcSortDropdown.runtimeMode,
                        tapMode: EmmaAnchors.mailPcSortDropdown.tapMode,
                        child: buildSortButton(),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: EmmaUiAnchorTarget(
                          anchorKey: EmmaAnchors.mailPcFiltersPanel.anchorKey,
                          spec: EmmaAnchors.mailPcFiltersPanel,
                          runtimeMode:
                              EmmaAnchors.mailPcFiltersPanel.runtimeMode,
                          tapMode: EmmaAnchors.mailPcFiltersPanel.tapMode,
                          child: UnifiedSidebarSection(
                            onSelectType: (value) =>
                                _selectMailType(ref, value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EmmaUiAnchorTarget(
                anchorKey: EmmaAnchors.mailPcTagsSection.anchorKey,
                spec: EmmaAnchors.mailPcTagsSection,
                runtimeMode: EmmaAnchors.mailPcTagsSection.runtimeMode,
                tapMode: EmmaAnchors.mailPcTagsSection.tapMode,
                child: TagsSection(
                  selectedTagIds: selectedTagIds,
                  height: tagsHeight,
                ),
              ),
              const SizedBox(height: 16),
              EmmaUiAnchorTarget(
                anchorKey: EmmaAnchors.mailPcComposeButton.anchorKey,
                spec: EmmaAnchors.mailPcComposeButton,
                runtimeMode: EmmaAnchors.mailPcComposeButton.runtimeMode,
                tapMode: EmmaAnchors.mailPcComposeButton.tapMode,
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: buttonStyleRounded10ThemeRed,
                    onPressed: () => showEmailOverlay(
                      context,
                      ref,
                      leadId: leadId,
                      lead: lead,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcons.newChat(
                          height: 25,
                          width: 25,
                          color: AppColors.white,
                        ),
                        if (!isTablet || width > 120) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'New message'.tr,
                              style: const TextStyle(
                                color: AppColors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSwitchAccountBox(
      BuildContext context, WidgetRef ref, ThemeColors theme) {
    final accountsAsync = ref.watch(emailAccountsProvider);
    final selectedAccount = ref.watch(selectedEmailAccountProvider);

    void openAddAccount() => showAddEmailAccountDialog(
          context,
          onSuccess: () => ref.invalidate(emailAccountsProvider),
        );

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(color: theme.dashboardBoarder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: accountsAsync.when(
        loading: () => Row(
          children: [
            Icon(Icons.alternate_email, color: theme.textColor, size: 18),
            const SizedBox(width: 10),
            if (!isTablet || width > 120)
              Expanded(
                child: Text(
                  'Loading accounts...'.tr,
                  style: TextStyle(color: theme.textColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        error: (e, _) => Row(
          children: [
            Icon(Icons.error_outline, color: theme.textColor, size: 18),
            const SizedBox(width: 10),
            if (!isTablet || width > 120)
              Expanded(
                child: Text(
                  'Failed to load email accounts'.tr,
                  style: TextStyle(color: theme.textColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Row(
              children: [
                Icon(Icons.mail_outline, color: theme.textColor, size: 18),
                const SizedBox(width: 10),
                if (!isTablet || width > 120)
                  Expanded(
                    child: Text(
                      'No connected email accounts'.tr,
                      style: TextStyle(color: theme.textColor, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                IconButton(
                  onPressed: openAddAccount,
                  icon: Icon(Icons.add, color: theme.textColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            );
          }

          final activeAccount = selectedAccount ?? accounts.first;

          return Row(
            children: [
              AccountAvatar(email: activeAccount.emailAddress, size: 28),
              const SizedBox(width: 10),
              if (!isTablet || width > 120)
                Expanded(
                  child: Text(
                    activeAccount.emailAddress,
                    style: TextStyle(color: theme.textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (!isTablet || width > 120)
                PopupMenuButton<int?>(
                  color: theme.adPopBackground,
                  onSelected: (id) {
                    if (id == null) {
                      openAddAccount();
                    } else {
                      ref.read(selectedEmailAccountIdProvider.notifier).state =
                          id;
                      ref.read(mailPageProvider.notifier).state = 1;
                      triggerMailRefresh(ref);
                    }
                  },
                  itemBuilder: (_) => [
                    ...accounts.map((a) {
                      final isSelected = activeAccount.id == a.id;
                      return PopupMenuItem<int?>(
                        value: a.id,
                        child: Row(
                          children: [
                            AccountAvatar(email: a.emailAddress, size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.emailAddress,
                                style: TextStyle(color: theme.textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSelected)
                              Icon(Icons.check,
                                  size: 16, color: theme.textColor),
                          ],
                        ),
                      );
                    }),
                    const PopupMenuDivider(),
                    PopupMenuItem<int?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: theme.themeColor),
                          const SizedBox(width: 8),
                          Text(
                            'Add account'.tr,
                            style: TextStyle(color: theme.themeColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.expand_more,
                    color: theme.textColor,
                    size: 18,
                  ),
                ),
              if (isTablet) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    ref.read(mailSidebarVisibleProvider.notifier).state = false;
                  },
                  icon: Icon(Icons.close, color: theme.textColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class SidebarSelectableTile extends ConsumerWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? accentColor;
  final Widget? trailing;

  const SidebarSelectableTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.icon,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final effectiveAccent = accentColor ?? theme.themeColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        color:
            isSelected ? effectiveAccent.withAlpha(26) : theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? effectiveAccent.withAlpha(140)
              : theme.dashboardBoarder.withAlpha(180),
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withAlpha(isSelected ? 40 : 18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: icon != null
                      ? Icon(icon, size: 16, color: effectiveAccent)
                      : Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: effectiveAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SysConfig {
  final String label;
  final IconData icon;
  final String mailType;
  final bool isSpam;
  const _SysConfig({
    required this.label,
    required this.icon,
    required this.mailType,
    this.isSpam = false,
  });
}

class _SidebarListItem {
  final String id;
  final String? label;
  final IconData? icon;
  final String? mailType;
  final bool isSpam;
  final dynamic backendTab;

  bool get isCustomTab => backendTab != null && mailType == null;

  const _SidebarListItem({
    required this.id,
    this.label,
    this.icon,
    this.mailType,
    this.isSpam = false,
    this.backendTab,
  });
}

class UnifiedSidebarSection extends ConsumerStatefulWidget {
  final void Function(String) onSelectType;
  final bool shrinkWrap;

  const UnifiedSidebarSection({
    super.key,
    required this.onSelectType,
    this.shrinkWrap = false,
  });

  @override
  ConsumerState<UnifiedSidebarSection> createState() =>
      _UnifiedSidebarSectionState();
}

class _UnifiedSidebarSectionState extends ConsumerState<UnifiedSidebarSection> {
  static const _sysConfigs = <String, _SysConfig>{
    'inbox': _SysConfig(
        label: 'Received', icon: Icons.inbox_outlined, mailType: 'inbox'),
    'emma': _SysConfig(
        label: 'Emma', icon: Icons.smart_toy_outlined, mailType: 'emma'),
    'direct': _SysConfig(
        label: 'Emma Direct',
        icon: Icons.bolt_outlined,
        mailType: 'emma-direct'),
    'spam': _SysConfig(
        label: 'Spam',
        icon: Icons.report_gmailerrorred_outlined,
        mailType: 'spam',
        isSpam: true),
    'newsletters': _SysConfig(
        label: 'Newsletters',
        icon: Icons.newspaper_outlined,
        mailType: 'newsletters'),
  };

  static const _defaultOrder = [
    'all',
    'sys_inbox',
    'sys_emma',
    'sys_direct',
    'sys_spam',
    'sys_newsletters',
    'sent',
    'scheduled',
  ];

  List<_SidebarListItem> _orderedItems = [];

  static List<_SidebarListItem> _buildMergedList(
    List<dynamic> allTabs,
    List<String>? savedOrder,
  ) {
    final itemMap = <String, _SidebarListItem>{
      'all': const _SidebarListItem(
          id: 'all',
          label: 'All',
          icon: Icons.all_inbox_outlined,
          mailType: 'all'),
      'sent': const _SidebarListItem(
          id: 'sent',
          label: 'Sent',
          icon: Icons.send_outlined,
          mailType: 'sent'),
      'scheduled': const _SidebarListItem(
          id: 'scheduled',
          label: 'Scheduled',
          icon: Icons.schedule_outlined,
          mailType: 'scheduled'),
    };

    for (final tab in allTabs) {
      final key = (tab.systemKey ?? '').toString().trim();
      final config = _sysConfigs[key];
      if (config != null) {
        final id = 'sys_$key';
        itemMap[id] = _SidebarListItem(
          id: id,
          label: config.label,
          icon: config.icon,
          mailType: config.mailType,
          isSpam: config.isSpam,
          backendTab: tab,
        );
      } else if (key.isEmpty || key == 'custom') {
        final id = 'tab_${tab.id}';
        itemMap[id] = _SidebarListItem(id: id, backendTab: tab);
      }
    }

    final order = savedOrder ?? _defaultOrder;
    final remaining = Map<String, _SidebarListItem>.from(itemMap);
    final result = <_SidebarListItem>[];

    for (final id in order) {
      final item = remaining.remove(id);
      if (item != null) result.add(item);
    }
    // New items not in saved order (e.g. newly created custom tabs)
    result.addAll(remaining.values);
    return result;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabs = ref.read(emailTabsProvider).value;
      final order = ref.read(sidebarOrderProvider);
      setState(() => _orderedItems = _buildMergedList(tabs ?? [], order));
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _orderedItems.removeAt(oldIndex);
      _orderedItems.insert(newIndex, item);
    });
    _persistOrder();
  }

  Future<void> _persistOrder() async {
    final ids = _orderedItems.map((e) => e.id).toList();
    await ref.read(sidebarOrderProvider.notifier).update(ids);

    final backendTabs = _orderedItems
        .where((e) => e.backendTab != null)
        .map((e) => e.backendTab)
        .toList();

    if (backendTabs.isNotEmpty) {
      EmailTaxonomyService.bulkReorderTabs(
        ref: ref,
        orderedTabs: backendTabs,
      ).catchError((_) {
        if (mounted) ref.invalidate(emailTabsProvider);
      });
    }
  }

  Future<void> _addTab(BuildContext context) async {
    final result = await showTaxonomyEditDialog(
      context: context,
      ref: ref,
      title: 'Create tab'.tr,
      confirmText: 'Create'.tr,
    );
    if (result == null) return;
    try {
      await EmailTaxonomyService.createTab(
        ref: ref,
        name: result.name,
        color: result.colorHex,
      );
      ref.invalidate(emailTabsProvider);
      if (context.mounted) {
        context.showSnackBarLikeSection('Tab created'.tr);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBarLikeSection('${'Failed to create tab'.tr}: $e');
      }
    }
  }

  Widget _wrapAnchor(String itemId, {required Key key, required Widget child}) {
    dynamic anchor;
    switch (itemId) {
      case 'all':
        anchor = EmmaAnchors.mailPcFilterAll;
        break;
      case 'sys_inbox':
        anchor = EmmaAnchors.mailPcFilterInbox;
        break;
      case 'sent':
        anchor = EmmaAnchors.mailPcFilterSent;
        break;
      case 'sys_emma':
        anchor = EmmaAnchors.mailPcFilterEmma;
        break;
      case 'sys_direct':
        anchor = EmmaAnchors.mailPcFilterEmmaDirect;
        break;
      case 'sys_spam':
        anchor = EmmaAnchors.mailPcFilterSpam;
        break;
      case 'scheduled':
        anchor = EmmaAnchors.mailPcFilterScheduled;
        break;
    }
    if (anchor != null) {
      return EmmaUiAnchorTarget(
        key: key,
        anchorKey: anchor.anchorKey,
        runtimeMode: anchor.runtimeMode,
        tapMode: anchor.tapMode,
        child: child,
      );
    }
    return KeyedSubtree(key: key, child: child);
  }

  Widget _buildItemWidget(
    _SidebarListItem item,
    int index,
    ThemeColors theme,
    String selectedType,
    int? selectedTabId,
    BuildContext context,
  ) {
    final dragHandle = ReorderableDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: 2),
        child: Icon(Icons.drag_handle,
            size: 16, color: theme.textColor.withAlpha(90)),
      ),
    );

    Widget tile;

    if (item.isCustomTab) {
      final tab = item.backendTab;
      final isSelected = selectedTabId == tab.id;
      final accentColor =
          MailColorParser.parse(tab.color, const Color(0xFF2563EB));

      Widget inner = SidebarSelectableTile(
        label: tab.name,
        isSelected: isSelected,
        accentColor: accentColor,
        icon: Icons.folder_open_outlined,
        trailing: dragHandle,
        onPressed: () {
          ref.read(selectedEmailTabIdProvider.notifier).state =
              isSelected ? null : tab.id;
          if (!isSelected) ref.read(mailTypeProvider.notifier).state = 'all';
          ref.read(mailPageProvider.notifier).state = 1;
          triggerMailRefresh(ref);
        },
      );

      inner = PieMenu(
        actions: _buildTabPieActions(context: context, ref: ref, tab: tab),
        child: inner,
      );

      tile = DndReceiver(
        targets: [DndTargetType.emailTab],
        onDrop: (DndPayload payload) async {
          final emailIds =
              EmailTaxonomyService.extractEmailIdsFromPayload(payload.data);
          if (emailIds.isEmpty) return;
          await EmailTaxonomyService.bulkMoveEmailsToTab(
              ref: ref, emailIds: emailIds, tabId: tab.id);
          triggerMailRefresh(ref);
          if (context.mounted)
            context.showSnackBarLikeSection('Emails moved'.tr);
        },
        child: inner,
      );
    } else {
      final isSelected = selectedType == item.mailType && selectedTabId == null;

      Widget inner = SidebarSelectableTile(
        label: item.label!.tr,
        icon: item.icon!,
        isSelected: isSelected,
        accentColor: item.backendTab != null
            ? MailColorParser.parse(item.backendTab.color, theme.themeColor)
            : null,
        trailing: dragHandle,
        onPressed: () => widget.onSelectType(item.mailType!),
      );

      if (item.isSpam) {
        tile = DndReceiver(
          targets: [DndTargetType.spamFolder],
          onDrop: (DndPayload payload) async {
            final emailIds =
                EmailTaxonomyService.extractEmailIdsFromPayload(payload.data);
            if (emailIds.isEmpty) return;
            final tabs = ref.read(emailTabsProvider).value;
            if (tabs != null) {
              final spamTab =
                  tabs.firstWhereOrNull((t) => t.systemKey == 'spam');
              if (spamTab != null) {
                await EmailTaxonomyService.bulkMoveEmailsToTab(
                    ref: ref, emailIds: emailIds, tabId: spamTab.id);
                triggerMailRefresh(ref);
                if (context.mounted)
                  context.showSnackBarLikeSection('Emails moved to Spam'.tr);
              }
            }
          },
          child: inner,
        );
      } else {
        tile = inner;
      }
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: tile,
    );

    return _wrapAnchor(item.id, key: ValueKey(item.id), child: content);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final tabsAsync = ref.watch(emailTabsProvider);
    final selectedType = ref.watch(mailTypeProvider);
    final selectedTabId = ref.watch(selectedEmailTabIdProvider);
    final savedOrder = ref.watch(sidebarOrderProvider);

    ref.listen(emailTabsProvider, (_, next) {
      next.whenData((tabs) {
        if (!mounted) return;
        setState(() => _orderedItems =
            _buildMergedList(tabs, ref.read(sidebarOrderProvider)));
      });
    });

    ref.listen(sidebarOrderProvider, (_, order) {
      final tabs = ref.read(emailTabsProvider).value;
      if (tabs != null && mounted) {
        setState(() => _orderedItems = _buildMergedList(tabs, order));
      }
    });

    if (_orderedItems.isEmpty) {
      if (tabsAsync.value != null) {
        _orderedItems = _buildMergedList(tabsAsync.value!, savedOrder);
      } else if (tabsAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      } else if (tabsAsync.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Failed to load tabs'.tr,
                style: TextStyle(color: theme.textColor)),
          ),
        );
      }
    }

    final addTabButton = Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _addTab(context),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.dashboardBoarder.withAlpha(120), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add,
                    size: 15, color: theme.textColor.withAlpha(160)),
                const SizedBox(width: 6),
                Text(
                  'Add tab'.tr,
                  style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final list = ReorderableListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      buildDefaultDragHandles: false,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      onReorder: _onReorder,
      children: [
        for (int i = 0; i < _orderedItems.length; i++)
          _buildItemWidget(
              _orderedItems[i], i, theme, selectedType, selectedTabId, context),
      ],
    );

    return Column(
      mainAxisSize: widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        widget.shrinkWrap ? list : Expanded(child: list),
        addTabButton,
      ],
    );
  }
}

class TagsSection extends ConsumerWidget {
  final Set<int> selectedTagIds;

  /// Fixed height for the tag list's own internal scroll area. When null,
  /// the section sizes itself to its content and relies on an ancestor
  /// scroll view instead (used e.g. in the mobile filters sheet).
  final double? height;

  const TagsSection({
    super.key,
    required this.selectedTagIds,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final tagsAsync = ref.watch(emailTagsProvider);

    final content = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(
          color: theme.dashboardBoarder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(
          'Failed to load tags'.tr,
          style: TextStyle(color: theme.textColor),
        ),
        data: (tags) {
          final tagsWrap = tags.isEmpty
              ? Text(
                  'No tags yet'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(180),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final isSelected = selectedTagIds.contains(tag.id);
                    final chipColor = MailColorParser.parse(
                      tag.color,
                      theme.themeColor,
                    );

                    return PieMenu(
                      actions: _buildTagPieActions(
                        context: context,
                        ref: ref,
                        tag: tag,
                      ),
                      child: SidebarTagChip(
                        label: tag.name,
                        isSelected: isSelected,
                        color: chipColor,
                        onTap: () {
                          final next = Set<int>.from(selectedTagIds);

                          if (isSelected) {
                            next.remove(tag.id);
                          } else {
                            next.add(tag.id);
                          }

                          ref
                              .read(
                                selectedEmailTagIdsProvider.notifier,
                              )
                              .state = next;
                          ref.read(mailPageProvider.notifier).state = 1;
                          triggerMailRefresh(ref);
                        },
                      ),
                    );
                  }).toList(),
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
            children: [
              SectionHeader(
                title: 'Tags'.tr,
                onAdd: () async {
                  final result = await showTaxonomyEditDialog(
                    context: context,
                    ref: ref,
                    title: 'Create tag'.tr,
                    confirmText: 'Create'.tr,
                  );

                  if (result == null) return;

                  try {
                    await EmailTaxonomyService.createTag(
                      ref: ref,
                      name: result.name,
                      color: result.colorHex,
                    );

                    ref.invalidate(emailTagsProvider);

                    if (context.mounted) {
                      context.showSnackBarLikeSection('Tag created'.tr);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showSnackBarLikeSection(
                        '${'Failed to create tag'.tr}: $e',
                      );
                    }
                  }
                },
                onClear: () {
                  ref.read(selectedEmailTagIdsProvider.notifier).state =
                      <int>{};
                  ref.read(mailPageProvider.notifier).state = 1;
                  triggerMailRefresh(ref);
                },
              ),
              const SizedBox(height: 8),
              height != null
                  ? Expanded(
                      child: tags.isEmpty
                          ? tagsWrap
                          : SingleChildScrollView(child: tagsWrap),
                    )
                  : tagsWrap,
            ],
          );
        },
      ),
    );

    if (height == null) {
      return SizedBox(width: double.infinity, child: content);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: content,
    );
  }
}

class SectionHeader extends ConsumerWidget {
  final String title;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onAdd,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: theme.themeColor),
                  const SizedBox(width: 4),
                  Text(
                    'Add'.tr,
                    style: TextStyle(
                      color: theme.themeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                'Clear'.tr,
                style: TextStyle(
                  color: theme.themeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarTagChip extends ConsumerWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const SidebarTagChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? color.withAlpha(34) : theme.adPopBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected
              ? color.withAlpha(150)
              : theme.dashboardBoarder.withAlpha(180),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
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

class TaxonomyDialogResult {
  final String name;
  final String colorHex;

  const TaxonomyDialogResult({
    required this.name,
    required this.colorHex,
  });
}

Future<TaxonomyDialogResult?> showTaxonomyEditDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required String confirmText,
  String initialName = '',
  String initialColorHex = '#2563EB',
}) async {
  final theme = ref.read(themeColorsProvider);
  final controller = TextEditingController(text: initialName);

  String selectedColor = initialColorHex;
  bool submitted = false;

  const availableColors = [
    '#2563EB',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#8B5CF6',
    '#EC4899',
    '#06B6D4',
    '#84CC16',
    '#F97316',
    '#64748B',
  ];

  final result = await showGeneralDialog<TaxonomyDialogResult?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, __, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutBack,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                final trimmed = controller.text.trim();
                final hasChanges = trimmed != initialName.trim() ||
                    selectedColor != initialColorHex;

                final canSubmit = trimmed.isNotEmpty &&
                    (initialName.isEmpty ? true : hasChanges) &&
                    !submitted;

                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width > 640
                        ? 560
                        : MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.dashboardBoarder,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: controller,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!canSubmit) return;
                            submitted = true;
                            Navigator.of(context).pop(
                              TaxonomyDialogResult(
                                name: controller.text.trim(),
                                colorHex: selectedColor,
                              ),
                            );
                          },
                          style: TextStyle(color: theme.textColor),
                          decoration: InputDecoration(
                            hintText: 'Name'.tr,
                            hintStyle: TextStyle(
                              color: theme.textColor.withAlpha(150),
                            ),
                            filled: true,
                            fillColor: theme.adPopBackground,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.dashboardBoarder,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.themeColor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Color'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: availableColors.map((hex) {
                            final color = MailColorParser.parse(
                              hex,
                              theme.themeColor,
                            );

                            final isSelected = selectedColor == hex;

                            return InkWell(
                              onTap: () => setState(() => selectedColor = hex),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.textColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withAlpha(100),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.textColor,
                                side: BorderSide(
                                  color: theme.dashboardBoarder,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(null),
                              child: Text(
                                'Cancel'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.themeColor,
                              ),
                              onPressed: canSubmit
                                  ? () {
                                      submitted = true;
                                      Navigator.of(context).pop(
                                        TaxonomyDialogResult(
                                          name: controller.text.trim(),
                                          colorHex: selectedColor,
                                        ),
                                      );
                                    }
                                  : null,
                              child: Text(
                                confirmText,
                                style: TextStyle(
                                  color: canSubmit
                                      ? theme.themeTextColor
                                      : theme.textColor.withAlpha(150),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );

  Future.delayed(const Duration(milliseconds: 400), controller.dispose);
  return result;
}

Future<bool?> showDeleteConfirmDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required String message,
}) {
  final theme = ref.read(themeColorsProvider);

  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, __, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutBack,
            ),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width > 640
                    ? 500
                    : MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dashboardBoarder,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(
                              color: theme.dashboardBoarder,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Cancel'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Delete'.tr,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class MailColorParser {
  static Color parse(String hex, Color fallback) {
    final normalized = hex.replaceAll('#', '').trim();
    if (normalized.isEmpty) return fallback;

    final value =
        normalized.length == 6 ? 'FF$normalized' : normalized.padLeft(8, 'F');

    return Color(int.tryParse(value, radix: 16) ?? fallback.value);
  }
}

List<PieAction> _buildTagPieActions({
  required BuildContext context,
  required WidgetRef ref,
  required dynamic tag,
}) {
  final theme = ref.read(themeColorsProvider);

  return [
    PieAction(
      tooltip: Text('Edit tag'.tr),
      onSelect: () async {
        final result = await showTaxonomyEditDialog(
          context: context,
          ref: ref,
          title: 'Edit tag'.tr,
          confirmText: 'Save'.tr,
          initialName: tag.name,
          initialColorHex: tag.color,
        );

        if (result == null) return;

        try {
          await EmailTaxonomyService.updateTag(
            ref: ref,
            tagId: tag.id,
            name: result.name,
            color: result.colorHex,
          );

          ref.invalidate(emailTagsProvider);

          if (context.mounted) {
            context.showSnackBarLikeSection('Tag updated'.tr);
          }
        } catch (e) {
          if (context.mounted) {
            context.showSnackBarLikeSection(
              '${'Failed to update tag'.tr}: $e',
            );
          }
        }
      },
      child: Icon(Icons.edit, color: theme.themeTextColor),
    ),
    PieAction(
      tooltip: Text('Delete tag'.tr),
      onSelect: () async {
        final confirmed = await showDeleteConfirmDialog(
          context: context,
          ref: ref,
          title: 'Delete tag'.tr,
          message: '${'Do you want to delete'.tr} "${tag.name}"?',
        );

        if (confirmed != true) return;

        try {
          await EmailTaxonomyService.deleteTag(
            ref: ref,
            tagId: tag.id,
          );

          final next = Set<int>.from(ref.read(selectedEmailTagIdsProvider));
          next.remove(tag.id);
          ref.read(selectedEmailTagIdsProvider.notifier).state = next;

          ref.invalidate(emailTagsProvider);
          triggerMailRefresh(ref);

          if (context.mounted) {
            context.showSnackBarLikeSection('Tag deleted'.tr);
          }
        } catch (e) {
          if (context.mounted) {
            context.showSnackBarLikeSection(
              '${'Failed to delete tag'.tr}: $e',
            );
          }
        }
      },
      child: Icon(Icons.delete_outline, color: theme.themeTextColor),
    ),
  ];
}

List<PieAction> _buildTabPieActions({
  required BuildContext context,
  required WidgetRef ref,
  required dynamic tab,
}) {
  final theme = ref.read(themeColorsProvider);

  return [
    PieAction(
      tooltip: Text('Edit tab'.tr),
      onSelect: () async {
        final result = await showTaxonomyEditDialog(
          context: context,
          ref: ref,
          title: 'Edit tab'.tr,
          confirmText: 'Save'.tr,
          initialName: tab.name,
          initialColorHex: tab.color,
        );

        if (result == null) return;

        try {
          await EmailTaxonomyService.updateTab(
            ref: ref,
            tabId: tab.id,
            name: result.name,
            color: result.colorHex,
          );

          ref.invalidate(emailTabsProvider);

          if (context.mounted) {
            context.showSnackBarLikeSection('Tab updated'.tr);
          }
        } catch (e) {
          if (context.mounted) {
            context.showSnackBarLikeSection(
              '${'Failed to update tab'.tr}: $e',
            );
          }
        }
      },
      child: Icon(Icons.edit, color: theme.themeTextColor),
    ),
    PieAction(
      tooltip: Text('Delete tab'.tr),
      onSelect: () async {
        final confirmed = await showDeleteConfirmDialog(
          context: context,
          ref: ref,
          title: 'Delete tab'.tr,
          message: '${'Do you want to delete'.tr} "${tab.name}"?',
        );

        if (confirmed != true) return;

        try {
          await EmailTaxonomyService.deleteTab(
            ref: ref,
            tabId: tab.id,
          );

          if (ref.read(selectedEmailTabIdProvider) == tab.id) {
            ref.read(selectedEmailTabIdProvider.notifier).state = null;
          }

          ref.invalidate(emailTabsProvider);
          triggerMailRefresh(ref);

          if (context.mounted) {
            context.showSnackBarLikeSection('Tab deleted'.tr);
          }
        } catch (e) {
          if (context.mounted) {
            context.showSnackBarLikeSection(
              '${'Failed to delete tab'.tr}: $e',
            );
          }
        }
      },
      child: Icon(Icons.delete_outline, color: theme.themeTextColor),
    ),
  ];
}

Color _colorForEmail(String email) {
  const palette = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFFF97316),
    Color(0xFF64748B),
  ];
  final hash = email
      .toLowerCase()
      .codeUnits
      .fold(0, (a, b) => (a * 31 + b) & 0x7FFFFFFF);
  return palette[hash % palette.length];
}

class AccountAvatar extends StatelessWidget {
  final String email;
  final double size;

  const AccountAvatar({super.key, required this.email, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final color = _colorForEmail(email);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.46,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
