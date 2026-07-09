import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/contact_panel/viewer/viewer_list.dart'; // ViewerListClientTable

class SellerPresentationsTab extends ConsumerWidget {
  final int transactionId;
  final String portalId;
  final bool isMobile;

  const SellerPresentationsTab({
    super.key,
    required this.transactionId,
    required this.portalId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: ViewerListClientTable(
              isClient:true,
              transactionId: transactionId,
              portalId: portalId,
              clientId: null,
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }
}
