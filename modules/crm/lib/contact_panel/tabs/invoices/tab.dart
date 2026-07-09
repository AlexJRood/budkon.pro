import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/tabs/invoices/invoices.dart';
import 'package:crm/contact_panel/tabs/invoices/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class ClientInvoicesPage extends ConsumerWidget {
  final int clientId;
  final bool isMobile;

  const ClientInvoicesPage({
    super.key,
    required this.clientId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(invoiceProvider(clientId));

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${'Error'.tr} $e',
          style: TextStyle(color: theme.textColor),
        ),
      ),
      data: (data) {
        return Padding(
          padding: EdgeInsets.only(left: isMobile ? 0 : 24, right: isMobile ? 0 : 24,top: TopAppBarSize.resolve(context) ),
          child: ClientInvoicesListWidget(
            data: data,
            isMobile: isMobile,
            clientId: clientId,
          ),
        );
      },
    );
  }
}
