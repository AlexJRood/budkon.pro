import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:network_monitoring/providers/saved_search/inbox_providers.dart';
import 'package:network_monitoring/screens/list_with_save_searches/list_with_save_search_mobile.dart';
import 'package:network_monitoring/screens/list_with_save_searches/list_with_save_search_pc.dart';

class ListWithSaveSearchScreen extends ConsumerStatefulWidget {
  final int? initialSavedSearchId;
  final int? initialAdId;
  final bool fromNotification;

  const ListWithSaveSearchScreen({
    super.key,
    this.initialSavedSearchId,
    this.initialAdId,
    this.fromNotification = false,
  });

  @override
  ConsumerState<ListWithSaveSearchScreen> createState() =>
      _ListWithSaveSearchScreenState();
}

class _ListWithSaveSearchScreenState
    extends ConsumerState<ListWithSaveSearchScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.initialSavedSearchId != null) {
        ref.read(selectedSavedSearchIdProvider.notifier).state =
            widget.initialSavedSearchId;
      }

      if (widget.initialAdId != null || widget.initialSavedSearchId != null) {
        ref.read(savedSearchInboxDeepLinkProvider.notifier).state =
            SavedSearchInboxDeepLink(
          savedSearchId: widget.initialSavedSearchId,
          targetAdId: widget.initialAdId,
          fromNotification: widget.fromNotification,
        );

        ref.read(savedSearchInboxPanelOpenProvider.notifier).state = true;
      }

      // When opened from notification,
      // do not force only_new=true, because the ad may already be seen.
      if (widget.fromNotification && widget.initialAdId != null) {
        ref.read(savedSearchInboxOnlyNewProvider.notifier).state = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.networkMonitoring,
      enableScrool: true,
      childPc: const ListWithSaveSearchesPc(),
      childMobile: const ListWithSaveSearchMobile(),
    );
  }
}