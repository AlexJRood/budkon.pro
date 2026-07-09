import 'package:payments/payments_urls.dart';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:core/platform/api_services.dart';
// import 'package:core/platform/url.dart';
//
// final stripeProvider = ChangeNotifierProvider((ref) => StripeProvider());
//
// /// Build-time toggles
// const bool _FRONT_FAKE_PAYMENT =
// bool.fromEnvironment('FRONT_FAKE_PAYMENT', defaultValue: false);
//
// const bool _FORCE_DUMMY_PRICES =
// bool.fromEnvironment('FORCE_DUMMY_PRICES', defaultValue: false);
//
// const String _DEV_MONTHLY_PRICE_ID =
// String.fromEnvironment('DEV_MONTHLY_PRICE_ID', defaultValue: 'price_dummy_monthly');
//
// const String _DEV_YEARLY_PRICE_ID =
// String.fromEnvironment('DEV_YEARLY_PRICE_ID', defaultValue: 'price_dummy_yearly');
//
// class StripeProvider extends ChangeNotifier {
//   // ────────────────────────────────────────────────────────────────────────────
//   // PRICES
//   // ────────────────────────────────────────────────────────────────────────────
//   Future<Map<String, dynamic>> fetchPricesForPremiumPlan() async {
//     // Front-only prices: either full mock mode or forced dummy price IDs.
//     if (_FRONT_FAKE_PAYMENT || _FORCE_DUMMY_PRICES) {
//       debugPrint('[prices] using front dummy prices '
//           '(monthly=$_DEV_MONTHLY_PRICE_ID, yearly=$_DEV_YEARLY_PRICE_ID)');
//       return <String, dynamic>{
//         'monthly': _DEV_MONTHLY_PRICE_ID,
//         'yearly': _DEV_YEARLY_PRICE_ID,
//         'currency': 'usd',
//         'amount_monthly': 8900,
//         'amount_yearly': 89000,
//       };
//     }
//
//     // Real fetch from your API
//     final resp = await ApiServices.get(
//       ref: null,
//       PaymentsUrls.stripeProducts,
//       hasToken: true,
//     );
//     final data = _asJson(resp);
//
//     if (data is Map && data['premium'] is Map) {
//       return Map<String, dynamic>.from(data['premium'] as Map);
//     }
//     if (data is List) {
//       String? monthly, yearly;
//       for (final item in data) {
//         final prices = (item['prices'] ?? []) as List;
//         for (final p in prices) {
//           final rec = (p['recurring'] ?? {}) as Map<String, dynamic>;
//           final interval = rec['interval'];
//           if (interval == 'month' && monthly == null) monthly = p['id'] as String?;
//           if (interval == 'year' && yearly == null) yearly = p['id'] as String?;
//         }
//       }
//       return {'monthly': monthly, 'yearly': yearly};
//     }
//     return {};
//   }
//
//   // ────────────────────────────────────────────────────────────────────────────
//   // PROMO
//   // ────────────────────────────────────────────────────────────────────────────
//   Future<String?> validatePromotionCode(String code) async {
//     if (_FRONT_FAKE_PAYMENT) {
//       // Simple mock: PROMO10 accepted, others rejected
//       if (code.trim().toUpperCase() == 'PROMO10') {
//         debugPrint('[promo] accepted PROMO10 (mock)');
//         return 'promo_dummy_10';
//       }
//       debugPrint('[promo] rejected (mock): $code');
//       throw Exception('Invalid promotion code');
//     }
//
//     try {
//       final resp = await ApiServices.post(
//         PaymentsUrls.stripePromotionUse,
//         hasToken: true,
//         data: {'code': code},
//       );
//
//       final data = _asJson(resp);
//
//       if (data is Map && data['id'] is String) {
//         return data['id'] as String;
//       }
//       if (data is Map) {
//         _printApiErrors(data, context: 'validatePromotionCode');
//       } else {
//         debugPrint('[validatePromotionCode] Unexpected response: $data');
//       }
//     } catch (e, st) {
//       debugPrint('[validatePromotionCode] Exception: $e');
//       debugPrintStack(stackTrace: st);
//     }
//     return null;
//   }
//
//   // ────────────────────────────────────────────────────────────────────────────
//   // SUBSCRIPTION CREATE
//   // ────────────────────────────────────────────────────────────────────────────
//   Future<Map<String, dynamic>> createSubscription({
//     required String priceId,
//     String? promotionCodeId,
//   }) async {
//     if (_FRONT_FAKE_PAYMENT) {
//       // Mock Stripe-like response:
//       // monthly -> immediate success
//       // yearly  -> requires_action (3DS), then your UI proceeds to wait/confirm
//       final bool requiresAction = priceId == _DEV_YEARLY_PRICE_ID;
//       final map = <String, dynamic>{
//         'subscription': {
//           'id': 'sub_mock_123',
//           'status': requiresAction ? 'incomplete' : 'active',
//           'latest_invoice': {
//             'id': 'in_mock_123',
//             'payment_intent': {
//               'id': 'pi_mock_123',
//               'status': requiresAction ? 'requires_action' : 'succeeded',
//               'client_secret': requiresAction ? 'pi_mock_123_secret_abc' : '',
//               'next_action': requiresAction
//                   ? {
//                 'redirect_to_url': {
//                   'url': 'https://example.org/mock-3ds' // not actually opened here
//                 }
//               }
//                   : null,
//             },
//           },
//         }
//       };
//       debugPrint('[createSubscription] mock response -> '
//           '${requiresAction ? 'requires_action' : 'succeeded'}');
//       return map;
//     }
//
//     try {
//       final resp = await ApiServices.post(
//         PaymentsUrls.stripeSubscriptionCreate,
//         hasToken: true,
//         data: {
//           'price_id': priceId,
//           if (promotionCodeId != null) 'promotion_code_id': promotionCodeId,
//         },
//       );
//       final data = _asJson(resp);
//       if (data is Map) {
//         if (data['error'] != null || data['detail'] != null || data['message'] != null) {
//           debugPrint('[createSubscription] server error: $data');
//         }
//         return Map<String, dynamic>.from(data);
//       }
//       debugPrint('[createSubscription] unexpected response type: $data');
//       return {'error': 'Unexpected response from server'};
//     } catch (e, st) {
//       debugPrint('[createSubscription] Exception: $e');
//       debugPrintStack(stackTrace: st);
//       return {'error': e.toString()};
//     }
//   }
//
//   // ────────────────────────────────────────────────────────────────────────────
//   // PAYMENT INTENT CONFIRM / POLL
//   // ────────────────────────────────────────────────────────────────────────────
//   Future<void> confirmPaymentIntent(String paymentIntentId) async {
//     if (_FRONT_FAKE_PAYMENT) {
//       debugPrint('[pi] (mock) confirm $paymentIntentId');
//       return;
//     }
//     await ApiServices.post(
//       PaymentsUrls.stripePaymentConfirm,
//       hasToken: true,
//       data: {'payment_intent_id': paymentIntentId},
//     );
//   }
//
//   /// Web: poll server for PI status (mock just waits briefly).
//   Future<void> waitForPaymentIntent(String paymentIntentId) async {
//     if (_FRONT_FAKE_PAYMENT) {
//       debugPrint('[pi] (mock) wait for $paymentIntentId …');
//       await Future.delayed(const Duration(seconds: 2));
//       return;
//     }
//     for (int i = 0; i < 6; i++) {
//       await Future.delayed(const Duration(milliseconds: 1500));
//       final resp = await ApiServices.get(
//         ref: null,
//         PaymentsUrls.stripePaymentIntentsStatus(paymentIntentId),
//         hasToken: true,
//       );
//       final data = _asJson(resp);
//       final status = (data is Map) ? (data['status'] as String?) : null;
//       if (status != null && status != 'requires_action' && status != 'processing') {
//         break;
//       }
//     }
//   }
//
//   // ────────────────────────────────────────────────────────────────────────────
//   // STATUS
//   // ────────────────────────────────────────────────────────────────────────────
//   Future<String> checkSubscriptionStatus() async {
//     if (_FRONT_FAKE_PAYMENT) {
//       return 'active';
//     }
//
//     final resp = await ApiServices.get(
//       ref: null,
//       PaymentsUrls.stripeSubscriptionStatus,
//       hasToken: true,
//     );
//     final data = _asJson(resp);
//     if (data is Map && data['status'] is String) return data['status'] as String;
//     return 'unknown';
//   }
//
//   // ────────────────────────────────────────────────────────────────────────────
//   // PAYPAL (mocked too)
//   // ────────────────────────────────────────────────────────────────────────────
//   Future<String?> createPaypalSubscription({required String priceId}) async {
//     if (_FRONT_FAKE_PAYMENT) {
//       return 'https://example.org/mock-paypal';
//     }
//
//     final resp = await ApiServices.post(
//       PaymentsUrls.stripePurchaseCreate,
//       hasToken: true,
//       data: {'provider': 'paypal', 'price_id': priceId},
//     );
//     final data = _asJson(resp);
//     if (data is Map && data['approval_url'] is String) return data['approval_url'] as String;
//     if (data is Map && data['redirect_url'] is String) return data['redirect_url'] as String;
//     return null;
//   }
//
//   // ────────────────────────────────────────────────────────────────────────────
//   // Helpers
//   // ────────────────────────────────────────────────────────────────────────────
//   dynamic _asJson(dynamic resp) {
//     if (resp is Map || resp is List) return resp;
//     if (resp is String) {
//       try {
//         return jsonDecode(resp);
//       } catch (_) {}
//     }
//     return resp;
//   }
//
//   /// Pretty-print common API error shapes.
//   void _printApiErrors(Map data, {String context = ''}) {
//     final prefix = context.isEmpty ? '' : '[$context] ';
//
//     if (data['error'] is String) {
//       debugPrint('${prefix}API error: ${data['error']}');
//       return;
//     }
//     if (data['detail'] is String) {
//       debugPrint('${prefix}API detail: ${data['detail']}');
//       return;
//     }
//
//     if (data['errors'] is Map) {
//       final errs = data['errors'] as Map;
//       if (errs.isEmpty) {
//         debugPrint('${prefix}API errors: (empty map)');
//         return;
//       }
//       errs.forEach((k, v) {
//         if (v is List) {
//           debugPrint('${prefix}API validation $k: ${v.join(" | ")}');
//         } else {
//           debugPrint('${prefix}API validation $k: $v');
//         }
//       });
//       return;
//     }
//
//     bool printedAny = false;
//     for (final entry in data.entries) {
//       final k = entry.key;
//       final v = entry.value;
//       if (v is List) {
//         debugPrint('${prefix}API validation $k: ${v.join(" | ")}');
//         printedAny = true;
//       } else if (v is String) {
//         debugPrint('${prefix}API $k: $v');
//         printedAny = true;
//       }
//     }
//     if (!printedAny) {
//       debugPrint('${prefix}API error payload (unrecognized shape): $data');
//     }
//   }
// }
