import 'package:core/ui/device_type_util.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/emma/anchors/anchors_nm.dart';
import 'package:network_monitoring/providers/saved_search/inbox_providers.dart';
import 'package:network_monitoring/screens/list_with_save_searches/widget/save_search_list_view_widget.dart';
import 'package:network_monitoring/screens/list_with_save_searches/widget/saved_search_inbox_panel.dart';
import 'package:core/theme/apptheme.dart';

class ListWithSaveSearchMobile extends ConsumerWidget {
  const ListWithSaveSearchMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final panelOpen = ref.watch(savedSearchInboxPanelOpenProvider);
    final selectedAsync = ref.watch(selectedSavedSearchProvider);

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchMobileRoot
      anchorKey: 'network_monitoring.saved_search.mobile.root',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: panelOpen
            ? EmmaUiAnchorTarget(
                // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchMobilePanel
                anchorKey: 'network_monitoring.saved_search.mobile.panel',
                child: Container(
                  key: const ValueKey('saved-search-mobile-panel'),
                  color: theme.dashboardContainer,
                  child: Column(
                    children: [
                      SizedBox(height: TopAppBarSize.resolve(context),),
                      _MobileResultsHeader(
                        title: selectedAsync.valueOrNull?.title,
                        onBack: () {
                          ref
                              .read(savedSearchInboxPanelOpenProvider.notifier)
                              .state = false;
                        },
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: EmmaUiAnchorTarget(
                            // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchMobileInboxPanel
                            anchorKey:
                                'network_monitoring.saved_search.mobile.inbox_panel',
                            child: SavedSearchInboxPanel(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const EmmaUiAnchorTarget(
                // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchMobileList
                anchorKey: 'network_monitoring.saved_search.mobile.list',
                child:  SizedBox.expand(
                  child: ColoredBox(
                    key: ValueKey('saved-search-mobile-list'),
                    color: Colors.transparent,
                    child: SaveSearchListViewWidget(isMobile: true),
                  ),
                ),
              ),
      ),
    );
  }
}

class _MobileResultsHeader extends ConsumerWidget {
  final String? title;
  final VoidCallback onBack;

  const _MobileResultsHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchMobileHeader
      anchorKey: 'network_monitoring.saved_search.mobile.header',
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          border: Border(
            bottom: BorderSide(
              color: theme.dashboardBoarder,
            ),
          ),
        ),
        child: Row(
          children: [
            EmmaUiAnchorTarget(
              // @emma-backend: NetworkMonitoringEmmaAnchors.savedSearchMobileBackButton
              anchorKey:
                  'network_monitoring.saved_search.mobile.back_button',
              child: IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.textColor,
                ),
                tooltip: 'Back'.tr,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'saved_search_results'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((title ?? '').trim().isNotEmpty)
                    Text(
                      title!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}