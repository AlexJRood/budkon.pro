import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mail/components/mail_sidebar.dart';
import 'package:mail/components/mail_top_bar.dart';
import '../emma/anchors/anchors_mail.dart';
import 'package:mail/components/scheduled_emails_with_preview.dart';
import 'package:mail/send_mail/send_mail.dart';
import 'package:mail/utils/api_services.dart';
import 'package:mail/utils/mail_filters.dart';
import 'package:mail/utils/mail_thread_tree.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class MailVerticalBar extends ConsumerWidget {
  final VoidCallback onPressed;
  final bool showActionList;
  final int? leadId;
  final dynamic lead;

  const MailVerticalBar({
    super.key,
    required this.onPressed,
    required this.showActionList,
    this.leadId,
    this.lead,
  });

  Future<void> _syncEmails(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(syncEmailsProvider.future);

      triggerMailRefresh(ref);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Synchronization completed'.tr)),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Sync error: $e'.tr)),
      );
    }
  }

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

  void _showMobileFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Consumer(
          builder: (context, ref, __) {
            final theme = ref.watch(themeColorsProvider);
            final pageSize = ref.watch(mailPageSizeProvider);
            final selectedTagIds = ref.watch(selectedEmailTagIdsProvider);

            final maxSheetHeight = MediaQuery.of(context).size.height * 0.92;

            // PieCanvas has to fill a bounded box (its descendants use PieMenu,
            // and it throws on unbounded height). Wrapping the sheet directly it
            // expanded to full height, pinned the content to the top, left a
            // see-through gap below it and swallowed the drag-to-dismiss.
            // Instead: let it fill the modal, put a translucent tap-to-dismiss
            // layer behind, and bottom-align the panel so it hugs the bottom
            // edge and sizes to its own content.
            return PieCanvas(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: true,
                      bottom: false,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxSheetHeight),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.dashboardContainer,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            border: Border.all(
                              color: theme.dashboardBoarder,
                              width: 1.2,
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 42,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: theme.textColor.withAlpha(70),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                MailTopBar(isMobile: true),
                                const SizedBox(height: 10),
                                _MobileSortDropdown(theme: theme),
                                const SizedBox(height: 10),
                                const MailViewModeSwitcher(),
                                const SizedBox(height: 10),
                                UnifiedSidebarSection(
                                  shrinkWrap: true,
                                  onSelectType: (value) =>
                                      _selectMailType(ref, value),
                                ),
                                const SizedBox(height: 10),
                                TagsSection(
                                  selectedTagIds: selectedTagIds,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Messages per page'.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.adPopBackground,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.dashboardBoarder
                                              .withAlpha(180),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: pageSize,
                                          dropdownColor: theme.adPopBackground,
                                          icon: Icon(
                                            Icons.expand_more,
                                            color: theme.textColor,
                                          ),
                                          items: const [20, 50, 100]
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e,
                                                  child: Text(
                                                    '$e',
                                                    style: AppTextStyles
                                                        .interLight14
                                                        .copyWith(
                                                      color: theme.textColor,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            if (val == null) return;

                                            ref
                                                .read(
                                                  mailPageSizeProvider.notifier,
                                                )
                                                .state = val;
                                            ref
                                                .read(mailPageProvider.notifier)
                                                .state = 1;
                                            triggerMailRefresh(ref);
                                          },
                                        ),
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return EmmaUiAnchorTarget(
      anchorKey: EmmaAnchors.mailVerticalBarRoot.anchorKey,
      spec: EmmaAnchors.mailVerticalBarRoot,
      runtimeMode: EmmaAnchors.mailVerticalBarRoot.runtimeMode,
      tapMode: EmmaAnchors.mailVerticalBarRoot.tapMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          EmmaUiAnchorTarget(
            anchorKey: EmmaAnchors.mailVerticalBarRefreshButton.anchorKey,
            spec: EmmaAnchors.mailVerticalBarRefreshButton,
            runtimeMode: EmmaAnchors.mailVerticalBarRefreshButton.runtimeMode,
            tapMode: EmmaAnchors.mailVerticalBarRefreshButton.tapMode,
            child: _VerticalActionButton(
              theme: theme,
              onPressed: () => _syncEmails(context, ref),
              child: AppIcons.refresh(color: theme.textColor),
            ),
          ),
          const SizedBox(height: 5),
          EmmaUiAnchorTarget(
            anchorKey: EmmaAnchors.mailVerticalBarFilterButton.anchorKey,
            spec: EmmaAnchors.mailVerticalBarFilterButton,
            runtimeMode: EmmaAnchors.mailVerticalBarFilterButton.runtimeMode,
            tapMode: EmmaAnchors.mailVerticalBarFilterButton.tapMode,
            child: _VerticalActionButton(
              theme: theme,
              onPressed: () => _showMobileFilters(context, ref),
              child: AppIcons.filterAlt(color: theme.textColor),
            ),
          ),
          const SizedBox(height: 5),
          EmmaUiAnchorTarget(
            anchorKey: EmmaAnchors.mailVerticalBarComposeButton.anchorKey,
            spec: EmmaAnchors.mailVerticalBarComposeButton,
            runtimeMode: EmmaAnchors.mailVerticalBarComposeButton.runtimeMode,
            tapMode: EmmaAnchors.mailVerticalBarComposeButton.tapMode,
            child: _VerticalActionButton(
              theme: theme,
              onPressed: () {
                onPressed();

                showEmailOverlay(
                  context,
                  ref,
                  leadId: leadId,
                  lead: lead,
                );
              },
              child: AppIcons.newChat(color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalActionButton extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onPressed;
  final Widget child;

  const _VerticalActionButton({
    required this.theme,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: theme.textFieldColor,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class _MobileSortDropdown extends ConsumerWidget {
  final ThemeColors theme;

  const _MobileSortDropdown({
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSort = ref.watch(mailSortProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          value: selectedSort,
          dropdownColor: theme.adPopBackground,
          borderRadius: BorderRadius.circular(12),
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
}
