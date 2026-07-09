import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/data/add_field/edit_sell_offer_provider.dart';

final privateEditOfferAdapterProvider =
    StateNotifierProvider.family<CrmEditOfferNotifier, EditOfferState, int?>(
  (ref, offerId) => CrmEditOfferNotifier(
    offerId: offerId,
    ref: ref,
    apiConfig: EditOfferApiConfig.portal(),
  ),
);