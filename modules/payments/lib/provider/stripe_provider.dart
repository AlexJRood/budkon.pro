import 'dart:convert';
import 'package:payments/payments_urls.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:payments/models/stripe_models.dart';
import 'package:core/platform/api_services.dart';

/// Simple local model for saved payment methods
class SavedPaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final int? expMonth;
  final int? expYear;

  SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });
}

/// UI state
class StripeState {
  final bool isLoading;
  final List<StripeProduct> products;
  final String? error;
  final List<SavedPaymentMethod> paymentMethods;

  const StripeState({
    required this.isLoading,
    required this.products,
    required this.error,
    required this.paymentMethods,
  });

  factory StripeState.initial() => const StripeState(
    isLoading: false,
    products: <StripeProduct>[],
    error: null,
    paymentMethods: <SavedPaymentMethod>[],
  );

  StripeState copyWith({
    bool? isLoading,
    List<StripeProduct>? products,
    String? error,
    List<SavedPaymentMethod>? paymentMethods,
  }) {
    return StripeState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      error: error,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}

/// Notifier
class StripeNotifier extends StateNotifier<StripeState> {
  final Ref ref;
  StripeNotifier(this.ref) : super(StripeState.initial());

  String? _lastSetupIntentClientSecret;
  String? _lastPaymentMethodId;
  String? _lastCustomerId;

  // =======================
  // Products
  // =======================
  Future<void> fetchStripeProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiServices.get(
        PaymentsUrls.stripeProducts,
        ref: ref,
        hasToken: true,
      );

      if (response == null) {
        throw Exception('empty_response_error'.tr);
      }

      final statusCode = response.statusCode ?? 0;
      if (statusCode != 200) {
        final errBody = _tryReadBody(response);
        throw Exception('HTTP $statusCode ${errBody ?? ""}'.trim());
      }

      final normalized = _normalizeToMap(_extractData(response));
      final parsed = StripeProductsResponse.fromJson(normalized);

      state = state.copyWith(
        isLoading: false,
        products: parsed.results,
        error: null,
      );

      debugPrint('✅ Stripe Products Fetched: ${parsed.results.length}');
      for (final product in parsed.results) {
        debugPrint('----------------------------------------');
        debugPrint('🛍️ Product: ${product.name}');
        debugPrint('ID: ${product.id}');
        debugPrint('Description: ${product.description ?? "—"}');
        debugPrint('Prices:');
        if (product.prices.isEmpty) {
          debugPrint('  No prices found.');
        } else {
          for (final price in product.prices) {
            debugPrint(
              '  💰 ${price.amount} ${price.currency.toUpperCase()}  |  ID: ${price.id}  |  Interval: ${price.interval ?? "—"}',
            );
          }
        }
      }
      debugPrint('----------------------------------------');
      debugPrint('✅ All products printed successfully.\n');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      debugPrint('❌ Product fetching failed: $e');
    }
  }

  dynamic _extractData(dynamic response) {
    try {
      if (_hasProp(response, 'data')) {
        return (response as dynamic).data;
      }
    } catch (_) {}
    try {
      if (_hasProp(response, 'body')) {
        return (response as dynamic).body;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _normalizeToMap(dynamic data) {
    debugPrint('↪︎ Raw payload type: ${data.runtimeType}');

    if (data == null) {
      throw Exception('Unexpected null payload');
    }

    if (data is Map<String, dynamic>) return data;

    if (data is Uint8List ||
        (data is List && data.isNotEmpty && data.first is int)) {
      final decoded = jsonDecode(utf8.decode(List<int>.from(data)));
      return _normalizeToMap(decoded);
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      return _normalizeToMap(decoded);
    }

    if (data is List) {
      return <String, dynamic>{
        'count': data.length,
        'next': null,
        'previous': null,
        'results': data,
      };
    }

    try {
      final decoded = jsonDecode(data.toString());
      return _normalizeToMap(decoded);
    } catch (_) {}

    throw Exception('Unexpected payload type: ${data.runtimeType}');
  }

  dynamic _tryReadBody(dynamic response) {
    try {
      if (_hasProp(response, 'data')) return (response as dynamic).data;
    } catch (_) {}
    try {
      if (_hasProp(response, 'body')) return (response as dynamic).body;
    } catch (_) {}
    return null;
  }

  bool _hasProp(Object o, String prop) {
    try {
      final dyn = o as dynamic;
      if (prop == 'data') {
        final v = dyn.data;
        return v != null;
      }
      if (prop == 'body') {
        final v = dyn.body;
        return v != null;
      }
    } catch (_) {}
    return false;
  }

  // =======================
  // Subscription (uses price + paymentMethod)
  // =======================
  Future<bool> stripeSubscriptionCreate(
      BuildContext context,
      String priceId,
      String paymentMethodId,
      ) async {
    try {
      // Clear previous error
      state = state.copyWith(error: null);

      final requestBody = {
        "price_id": priceId,
        "payment_method_id": paymentMethodId,
      };
      debugPrint('Younis Azizi test $requestBody');
      final response = await ApiServices.post(
        PaymentsUrls.stripeSubscriptionCreate,
        hasToken: true,
        data: requestBody,
      );

      if (response == null) {
        final msg ='no_response_from_subscription_endpoint'.tr;
        debugPrint('❌ $msg');
        state = state.copyWith(error: msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return false; // ❌ failed
      }

      final statusCode = response.statusCode ?? 0;

      dynamic body = (() {
        try {
          final dyn = response as dynamic;
          if (dyn.data != null) return dyn.data; // dio
        } catch (_) {}
        try {
          final dyn = response as dynamic;
          if (dyn.body != null) return dyn.body; // http
        } catch (_) {}
        return null;
      })();

      String printable;
      try {
        if (body == null) {
          printable = '(empty body)';
        } else if (body is List<int>) {
          final s = utf8.decode(body);
          printable = _prettyJsonIfPossible(s);
        } else if (body is String) {
          printable = _prettyJsonIfPossible(body);
        } else {
          printable = _prettyJsonIfPossible(jsonEncode(body));
        }
      } catch (_) {
        printable = body.toString();
      }

      debugPrint('— Stripe Subscription Create —');
      debugPrint('Status: $statusCode');
      debugPrint('Response:');
      debugPrint(printable);

      if (statusCode == 200 || statusCode == 201) {
        final okMsg = 'subscription_created_success'.tr;
        debugPrint('✅ $okMsg');
        state = state.copyWith(error: null);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(okMsg)),
        );
        return true; // ✅ success
      } else {
        final msg = '${'subscription_failed_error'.tr} (HTTP $statusCode): $printable';
        debugPrint('❌ $msg');
        state = state.copyWith(error: msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return false; // ❌ failed
      }
    } catch (e, st) {
      final msg = '${'exception_during_subscription_create'.tr} $e';
      debugPrint('❌ $msg');
      debugPrint(st.toString());
      state = state.copyWith(error: msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return false; // ❌ failed
    }
  }



  String _prettyJsonIfPossible(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  // ====================================================
  // FETCH SAVED PAYMENT METHODS
  // ====================================================
  Future<void> fetchSavedPaymentMethods() async {
    debugPrint('🔎 [fetchSavedPaymentMethods] START');
    debugPrint(
      '🔎 [fetchSavedPaymentMethods] Hitting URL: ${PaymentsUrls.stripePaymentMethods}',
    );

    try {
      final response = await ApiServices.get(
        PaymentsUrls.stripePaymentMethods, // /stripe/payment/methods/
        ref: ref,
        hasToken: true,
      );

      if (response == null) {
        debugPrint('❌ [fetchSavedPaymentMethods] Response is NULL');
        throw Exception('empty_response_payment_methods'.tr);
      }

      final statusCode = response.statusCode ?? 0;
      debugPrint('🔎 [fetchSavedPaymentMethods] statusCode = $statusCode');
      debugPrint(
        '🔎 [fetchSavedPaymentMethods] response.runtimeType = ${response.runtimeType}',
      );

      if (statusCode != 200) {
        final errBody = _tryReadBody(response);
        debugPrint('❌ [fetchSavedPaymentMethods] Non-200 body: $errBody');
        throw Exception('HTTP $statusCode ${errBody ?? ""}'.trim());
      }

      // ---- extract raw body ----
      dynamic raw;
      try {
        final dyn = response as dynamic;
        raw = dyn.data ?? dyn.body;
      } catch (e) {
        debugPrint('⚠️ [fetchSavedPaymentMethods] Could not read data/body: $e');
        raw = null;
      }

      if (raw == null) {
        debugPrint('❌ [fetchSavedPaymentMethods] raw body is NULL');
        throw Exception('empty_body_payment_methods'.tr);
      }

      if (raw is List<int>) {
        final s = utf8.decode(raw);
        debugPrint(
          '🔎 [fetchSavedPaymentMethods] raw is List<int>, decoded string: $s',
        );
        raw = s;
      } else {
        debugPrint(
          '🔎 [fetchSavedPaymentMethods] raw.runtimeType = ${raw.runtimeType}',
        );
        if (raw is String) {
          final preview = raw.length > 500 ? raw.substring(0, 500) : raw;
          debugPrint(
            '🔎 [fetchSavedPaymentMethods] raw (string, preview): $preview',
          );
        } else {
          debugPrint('🔎 [fetchSavedPaymentMethods] raw (non-string): $raw');
        }
      }

      // ---- decode JSON ----
      final decoded = raw is String ? jsonDecode(raw) : raw;
      debugPrint(
        '🔎 [fetchSavedPaymentMethods] decoded.runtimeType = ${decoded.runtimeType}',
      );

      // Endpoint returns a top-level list; also support {"results":[...]}
      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
        debugPrint(
          '🔎 [fetchSavedPaymentMethods] decoded is List, length = ${list.length}',
        );
      } else if (decoded is Map<String, dynamic> &&
          decoded['results'] is List) {
        list = decoded['results'] as List<dynamic>;
        debugPrint(
          '🔎 [fetchSavedPaymentMethods] decoded is Map with "results", length = ${list.length}',
        );
      } else {
        debugPrint(
          '❌ [fetchSavedPaymentMethods] Unexpected decoded shape: $decoded',
        );
        throw Exception(
          '${'unexpected_payment_methods_shape'.tr} ${decoded.runtimeType}',
        );
      }

      final methods = <SavedPaymentMethod>[];

      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        debugPrint(
          '🔎 [fetchSavedPaymentMethods] item[$i] runtimeType = ${item.runtimeType}',
        );
        debugPrint('🔎 [fetchSavedPaymentMethods] item[$i] = $item');

        if (item is! Map) {
          debugPrint(
            '⚠️ [fetchSavedPaymentMethods] item[$i] is not a Map, skipping',
          );
          continue;
        }

        final card = item['card'] as Map?;
        debugPrint('🔎 [fetchSavedPaymentMethods] item[$i].card = $card');

        final expMonthRaw = card?['exp_month'];
        final expYearRaw = card?['exp_year'];

        final method = SavedPaymentMethod(
          id: item['id'] as String? ?? '',
          brand: card?['brand'] as String? ?? '',
          last4: card?['last4'] as String? ?? '',
          expMonth: expMonthRaw is int
              ? expMonthRaw
              : int.tryParse(expMonthRaw?.toString() ?? ''),
          expYear: expYearRaw is int
              ? expYearRaw
              : int.tryParse(expYearRaw?.toString() ?? ''),
        );

        debugPrint(
          '✅ [fetchSavedPaymentMethods] Parsed method[$i]: '
              'id=${method.id}, brand=${method.brand}, last4=${method.last4}, '
              'exp=${method.expMonth}/${method.expYear}',
        );

        methods.add(method);
      }

      state = state.copyWith(paymentMethods: methods, error: state.error);

      debugPrint(
        '✅ [fetchSavedPaymentMethods] Saved payment methods length: ${methods.length}',
      );
      for (final m in methods) {
        debugPrint(
          '  • ${m.brand.toUpperCase()} **** **** **** ${m.last4}  exp: ${m.expMonth}/${m.expYear}',
        );
      }

      debugPrint('🔎 [fetchSavedPaymentMethods] END');
    } catch (e, st) {
      debugPrint('❌ [fetchSavedPaymentMethods] Failed: $e');
      debugPrint(st.toString());
    }
  }

  // ====================================================
  // Create a PaymentMethod from CardField (web-safe)
  // and attach it via /stripe/payment/methods/attach/
  // ====================================================
  Future<String?> createPaymentMethodFromCardField({
    required BuildContext context,
    required String nameOnCard,
    String? country, // currently unused, but kept for API compatibility
  }) async {
    try {
      // 1) Create PaymentMethod from CardField
      final pm = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: nameOnCard,
              // address omitted – Address requires many fields in this SDK
            ),
          ),
        ),
      );

      final pmId = pm.id;
      _lastPaymentMethodId = pmId;
      debugPrint('✅ Created PaymentMethod: $pmId');

      // 2) Attach PaymentMethod to customer via your backend
      final response = await ApiServices.post(
        PaymentsUrls.stripePaymentMethodsAttach, // /stripe/payment/methods/attach/
        hasToken: true,
        data: {'payment_method_id': pmId},
      );

      if (response == null) {
        throw Exception('No response from /stripe/payment/methods/attach/');
      }

      final statusCode = response.statusCode ?? 0;

      dynamic raw;
      try {
        final dyn = response as dynamic;
        raw = dyn.data ?? dyn.body;
      } catch (_) {
        raw = null;
      }

      String printable;
      try {
        if (raw == null) {
          printable = '(empty body)';
        } else if (raw is List<int>) {
          printable = utf8.decode(raw);
        } else if (raw is String) {
          printable = raw;
        } else {
          printable = jsonEncode(raw);
        }
      } catch (_) {
        printable = raw.toString();
      }

      debugPrint('— Attach Payment Method —');
      debugPrint('Status: $statusCode');
      debugPrint('Response: $printable');

      if (statusCode == 200 || statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('payment_method_saved_success'.tr)),
        );

        // refresh list so UI shows the new card
        await fetchSavedPaymentMethods();
      } else {
        throw Exception('${'failed_to_attach_payment_method'.tr} (HTTP $statusCode)');
      }

      return pmId;
    } catch (e, st) {
      debugPrint('❌ Error creating/attaching payment method: $e');
      debugPrint(st.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${'Error'.tr}: $e')));
      return null;
    }
  }

  // ========= Optional: mobile PaymentSheet helpers (kept) =========

  Future<void> initAddPaymentMethodSheet() async {
    final response = await ApiServices.post(
      PaymentsUrls.stripePaymentSetupIntent,
      hasToken: true,
    );

    if (response == null) {
      throw Exception('backend_null_response_setup_intent'.tr);
    }

    dynamic raw;
    try {
      final dyn = response as dynamic;
      raw = dyn.data ?? dyn.body;
    } catch (_) {
      raw = null;
    }

    if (raw == null) {
      throw Exception('backend_empty_response_setup_intent'.tr);
    }

    final data = raw is String ? jsonDecode(raw) : raw as Map<String, dynamic>;

    final customerId = data['customerId'] as String?;
    final ephKey = data['ephemeralKeySecret'] as String?;
    final setupSecret = data['setupIntentClientSecret'] as String?;

    if (customerId == null || ephKey == null || setupSecret == null) {
      throw Exception('missing_fields_setup_intent'.tr);
    }

    _lastSetupIntentClientSecret = setupSecret;
    _lastCustomerId = customerId;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'Hously',
        customerId: customerId,
        customerEphemeralKeySecret: ephKey,
        setupIntentClientSecret: setupSecret,
        allowsDelayedPaymentMethods: true,
        billingDetailsCollectionConfiguration:
        const BillingDetailsCollectionConfiguration(
          name: CollectionMode.automatic,
          email: CollectionMode.automatic,
        ),
      ),
    );
  }

  Future<void> presentAddPaymentMethodSheet(BuildContext context) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      if (_lastSetupIntentClientSecret != null) {
        final setupIntent = await Stripe.instance.retrieveSetupIntent(
          _lastSetupIntentClientSecret!,
        );

        debugPrint('✅ Saved payment method: ${setupIntent.paymentMethodId}');
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('payment_method_saved_message'.tr)));
    } on StripeException catch (e) {
      debugPrint('StripeException: ${e.error.localizedMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'stripe_error_prefix'.tr} ${e.error.localizedMessage}')),
      );
    } catch (e) {
      debugPrint('Unexpected error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${'Error'.tr}: $e')));
    }
  }
}

/// Provider to use in UI
final stripeProvider =
StateNotifierProvider<StripeNotifier, StripeState>((ref) {
  return StripeNotifier(ref);
});
