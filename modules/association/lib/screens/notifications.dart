// lib/screens/association_notifications/association_notifications_screen.dart
// Comments are in English as requested.

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:association/providers/notifications.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import 'package:association/screens/notifications/detail_pane.dart';
import 'package:association/screens/notifications/mobile_buttons.dart';
import 'package:association/screens/notifications/campaign_ui_utils.dart';
import 'package:association/screens/notifications/create_campaign_dialog.dart';

class AssociationNotificationsScreen extends ConsumerStatefulWidget {
  const AssociationNotificationsScreen({
    super.key,
    required this.baseUrl,
    required this.associationId,
    this.notificationId,
  });

  final String baseUrl;
  final int associationId;

  /// Optional campaign/notification id to open on entry (deep link).
  final String? notificationId;

  @override
  ConsumerState<AssociationNotificationsScreen> createState() =>
      _AssociationNotificationsScreenState();
}

class _AssociationNotificationsScreenState
    extends ConsumerState<AssociationNotificationsScreen> {
  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  @override
  void initState() {
    super.initState();

    // Load list on first build and optionally open deep-linked campaign.
    Future.microtask(() async {
      final notifier = ref.read(
        campaignListProvider(
          (baseUrl: widget.baseUrl, associationId: widget.associationId),
        ).notifier,
      );

      // 1) Load list first
      await notifier.load();

      // 2) If deep link id provided - select it and open details on mobile
      final id = widget.notificationId;
      if (id != null && id.trim().isNotEmpty) {
        notifier.select(id);

        if (!mounted) return;

        // Open bottom sheet only after first frame is built (safe context).
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final isMobile = MediaQuery.of(context).size.width < 800;
          if (isMobile) {
            await _openDetailBottomSheet(id);
          }
        });
      }
    });
  }

  Future<void> _reload() async {
    await ref
        .read(
          campaignListProvider(
            (baseUrl: widget.baseUrl, associationId: widget.associationId),
          ).notifier,
        )
        .load();
  }

  // Bottom sheet with DraggableScrollableSheet on mobile
  Future<void> _openDetailBottomSheet(String id) async {
    final theme = ref.read(themeColorsProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: theme.dashboardBoarder),
              ),
              child: PrimaryScrollController(
                controller: scrollController,
                child: AssociationCampaignDetailPane(
                  baseUrl: widget.baseUrl,
                  theme: theme,
                  selectedId: id,
                  onActionDone: _reload,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateDialog() async {
    final theme = ref.read(themeColorsProvider);

    await showDialog(
      context: context,
      builder: (_) => CreateCampaignDialog(
        theme: theme,
        baseUrl: widget.baseUrl,
        associationId: widget.associationId,
        onCreated: (id) async {
          Navigator.of(context).pop();
          await ref
              .read(
                campaignListProvider(
                  (baseUrl: widget.baseUrl, associationId: widget.associationId),
                ).notifier,
              )
              .load();
          ref
              .read(
                campaignListProvider(
                  (baseUrl: widget.baseUrl, associationId: widget.associationId),
                ).notifier,
              )
              .select(id);
        },
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    final theme = ref.read(themeColorsProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.98,
          expand: false,
          builder: (ctx2, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: theme.dashboardBoarder),
              ),
              child: PrimaryScrollController(
                controller: scrollController,
                child: CreateCampaignDialog(
                  theme: theme,
                  baseUrl: widget.baseUrl,
                  associationId: widget.associationId,
                  onCreated: (id) async {
                    Navigator.of(ctx2).pop(); // close sheet
                    await ref
                        .read(
                          campaignListProvider(
                            (baseUrl: widget.baseUrl, associationId: widget.associationId),
                          ).notifier,
                        )
                        .load();
                    ref
                        .read(
                          campaignListProvider(
                            (baseUrl: widget.baseUrl, associationId: widget.associationId),
                          ).notifier,
                        )
                        .select(id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(
      campaignListProvider(
        (baseUrl: widget.baseUrl, associationId: widget.associationId),
      ),
    );

    final theme = ref.read(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          layoutTypePc: LayoutTypePc.row,
          paddingMobile: 8,

          // ======= MOBILE FLOATING BUTTONS =======
          verticalButtons: isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MobileNewCampaignButton(onPressed: _openCreateSheet),
                    const SizedBox(height: 8),
                    MobileRefreshButton(onPressed: _reload),
                  ],
                )
              : null,

          // ======= DESKTOP / PC LAYOUT =======
          childrenPc: [
            // Left list
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              style: buttonStyleRounded10ThemeRed,
                              onPressed: _openCreateDialog,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 5,
                                children: const [
                                  Icon(Icons.campaign, color: AppColors.white),
                                  Text(
                                    'New campaign',
                                    style: TextStyle(color: AppColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: ElevatedButton(
                            style: elevatedButtonStyleRounded10,
                            onPressed: _reload,
                            child: Icon(Icons.refresh, color: theme.textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (listState.loading)
                    const LinearProgressIndicator(minHeight: 2),
                  if (listState.error != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Błąd: ${listState.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: listState.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final c = listState.items[i];
                        final selected = c.id == listState.selectedId;

                        return ListTile(
                          selected: selected,
                          title: Text(
                            c.title,
                            maxLines: 1,
                            style: TextStyle(color: theme.textColor, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            campaignSubtitleFor(c),
                            style: TextStyle(
                              color: theme.textColor.withAlpha(140),
                              fontSize: 12,
                            ),
                          ),
                          trailing: campaignStatusChip(status: c.status),
                          onTap: () => ref
                              .read(
                                campaignListProvider(
                                  (baseUrl: widget.baseUrl, associationId: widget.associationId),
                                ).notifier,
                              )
                              .select(c.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: AssociationCampaignDetailPane(
                baseUrl: widget.baseUrl,
                theme: theme,
                selectedId: listState.selectedId,
                onActionDone: _reload,
              ),
            ),
          ],

          // ======= MOBILE LAYOUT =======
          childrenMobile: [
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'Association notifications'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (listState.loading)
              const LinearProgressIndicator(minHeight: 2),
            if (listState.error != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Błąd: ${listState.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: listState.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final c = listState.items[i];
                  final selected = c.id == listState.selectedId;

                  return ListTile(
                    selected: selected,
                    title: Text(
                      c.title,
                      maxLines: 1,
                      style: TextStyle(color: theme.textColor, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      campaignSubtitleFor(c),
                      style: TextStyle(
                        color: theme.textColor.withAlpha(140),
                        fontSize: 12,
                      ),
                    ),
                    trailing: campaignStatusChip(status: c.status),
                    onTap: () {
                      ref
                          .read(
                            campaignListProvider(
                              (baseUrl: widget.baseUrl, associationId: widget.associationId),
                            ).notifier,
                          )
                          .select(c.id);

                      _openDetailBottomSheet(c.id);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
