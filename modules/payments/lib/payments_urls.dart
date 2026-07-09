import 'package:core/platform/url.dart';

/// payments feature API endpoints, decentralized out of core's URLs God-package.
class PaymentsUrls {
  const PaymentsUrls._();

static final stripePaymentConfirm = URLs.appendBaseUrl('/stripe/payment/confirm/');
static String stripePaymentIntentsStatus(String paymentIntentId)=> URLs.appendBaseUrl('/stripe/payment_intents/$paymentIntentId/status/');
static final stripePaymentMethods = URLs.appendBaseUrl('/stripe/payment/methods/');
static final stripePaymentMethodsAttach = URLs.appendBaseUrl('/stripe/payment/methods/attach/');
static final stripePaymentSetupIntent = URLs.appendBaseUrl('/stripe/payment/setup-intent/');
static final stripeProducts = URLs.appendBaseUrl('/stripe/products/');
static final stripePromotionUse = URLs.appendBaseUrl('/stripe/promotion/use/');
static final stripePurchaseCreate = URLs.appendBaseUrl('/stripe/purchase/create/');
static final stripeSubscriptionCreate = URLs.appendBaseUrl('/stripe/subscriptions/create/');
static final stripeSubscriptionStatus = URLs.appendBaseUrl('/stripe/subscription/status/');
}
