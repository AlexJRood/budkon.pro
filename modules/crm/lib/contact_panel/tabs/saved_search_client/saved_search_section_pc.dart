import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client_saved_search_browser_panel.dart';

class ClientSavedSearchSection extends ConsumerWidget {
  final int clientId;

  const ClientSavedSearchSection({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: ClientSavedSearchBrowserPanel(
        clientId: clientId,
        closeOverlayOnOpenSearch: false,
      ),
    );
  }
}