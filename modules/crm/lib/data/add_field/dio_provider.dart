
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/revenue/crm_revenue_upload_model.dart';
import 'package:crm/data/add_field/sell_offer_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/foundation.dart';

final crmClientTransactionOfferProvider =
    StateNotifierProvider<CrmClientTransactionOfferNotifier, AsyncValue<void>>(
        (ref) {
  return CrmClientTransactionOfferNotifier();
});

class CrmClientTransactionOfferNotifier
    extends StateNotifier<AsyncValue<void>> {
  CrmClientTransactionOfferNotifier() : super(const AsyncValue.data(null));

  Future<void> addClientTransactionOffer({
    required UserContactModel client,
    required CrmRevenueUploadModel transaction,
    required CrmAddSellOfferState offer,
  }) async {
    try {
      final response = await ApiServices.post(
        URLs.estateAgentAddSellOffer,
        hasToken: true,
        data: {
          'client': client.toJson(),
          'transaction': transaction.toJson(),
          'offer': offer.toJson(),
        },
      );

      if (response != null && response.statusCode == 201) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          Exception('Failed to create client, transaction, and offer'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) print('Error creating client, transaction, and offer: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
