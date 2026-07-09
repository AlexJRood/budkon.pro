
import 'package:get/get_utils/get_utils.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter/foundation.dart';

// lib/providers/ad_provider.dart

import 'dart:convert';

import 'package:crm/crm/clients/clients_view_page.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/design.dart';
import 'package:crm/contact_panel/navigation/enum.dart';

final clientProvider = FutureProvider.family<UserContactModel, int>((
  ref,
  clientId,
) async {
  final response = await ApiServices.get(
    ref: ref,
    CrmUrls.singleUserContacts('$clientId'),
    hasToken: true,
  );
  if (kDebugMode) print('Mahdi: checking: user: 2: ');

  if (response != null && response.statusCode == 200) {
    final decodedBody = utf8.decode(response.data);
    final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
    if (kDebugMode) print('Mahdi: checking: user: 3: $listingsJson');
    return UserContactModel.fromJson(listingsJson as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load client'.tr);
  }
});

class ClientsFetcher extends ConsumerWidget {
  final int clientId;
  final String tagClientViewPop;
  final String activeSection;
  final String activeAd;
  final ContactType contactType;

  const ClientsFetcher({
    this.contactType = ContactType.client,
    required this.clientId,
    required this.tagClientViewPop,
    required this.activeAd,
    required this.activeSection,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adAsyncValue = ref.watch(clientProvider(clientId));

    return adAsyncValue.when(
      data: (client) {
        return ClientsViewPop(
          clientViewPop: client,
          tagClientViewPop: tagClientViewPop,
          activeSection: activeSection,
          activeAd: activeAd,
          contactType: contactType,
        );
      },
      loading:
          () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.light,
                strokeWidth: 2,
              ),
            ),
          ),
      error:
          (error, stack) =>
              Scaffold(body: Center(child: Text('Error: $error'.tr))),
    );
  }
}
