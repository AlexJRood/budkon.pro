import 'package:fav_board/widgets/client_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:crm/data/clients/client_provider.dart';

import 'package:get/get_utils/get_utils.dart';

class ClientList extends ConsumerWidget {
  final ScrollController? scrollController;
  final bool isEdit;

  const ClientList({
    super.key,
    required this.scrollController,
    required this.isEdit,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientListAsyncValue = ref.watch(clientProvider);
    final theme = ref.read(themeColorsProvider);

    return clientListAsyncValue.when(
      data: (clients) => clients.isEmpty
          ? Center(
        child: Text(
          'No clients available'.tr,
          style: AppTextStyles.interRegular12
          .copyWith(color: theme.textColor),
        ),
      )
          : Column(  // Changed from ListView to Column
        children: clients
            .map((client) => ClientCardWidget(client: client, isEdit: isEdit))
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(child: Icon(Icons.error, color: Colors.red)),
    );
  }

}
