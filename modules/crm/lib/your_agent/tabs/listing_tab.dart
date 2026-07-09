import 'package:crm/contact_panel/sections/ad_view.dart';
import 'package:crm/draft_ads_listview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import 'package:core/ui/device_type_util.dart';

class ListingTab extends ConsumerWidget {
  final Map<String, dynamic>? listing;
  final Map<String, dynamic> transaction;
  final String portalId;
  final bool canEdit;

  const ListingTab({
    super.key,
    this.canEdit = false,
    required this.portalId,
    required this.listing,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    if (listing == null) {
      return Center(
        child: Text(
          'no_linked_listing_message'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    // 🔄 Tu przepuszczamy JSON z portalu przez Twój model z CRM
    final adViewModel = DraftAdsListViewModel.fromJson(listing!);

    final isMobile = DeviceTypeUtil.isMobile(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: AdViewClient(
              adFeedPop: adViewModel,
              isMobile: isMobile,
              isClientPortal: true,
              portalId: portalId,
              canEdit: canEdit, // 👈 kluczowe: klient nic nie edytuje
            ),
          ),
        ],
      ),
    );
  }
}
