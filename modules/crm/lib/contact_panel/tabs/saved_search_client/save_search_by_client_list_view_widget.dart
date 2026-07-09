import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client_saved_search_browser_panel.dart';

class SaveSearchByClientListViewWidget extends ConsumerWidget {
  final int clientId;

  const SaveSearchByClientListViewWidget({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClientSavedSearchBrowserPanel(
      clientId: clientId,
      closeOverlayOnOpenSearch: false,
    );
  }
}