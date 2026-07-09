import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client_saved_search_browser_panel.dart';

class SaveSearchTransactionPopUp extends ConsumerWidget {
  final int transactionId;
  final int? clientId;

  const SaveSearchTransactionPopUp({
    super.key,
    required this.transactionId,
    this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClientSavedSearchBrowserPanel(
      clientId: clientId,
      transactionId: transactionId,
      closeOverlayOnOpenSearch: true,
    );
  }
}