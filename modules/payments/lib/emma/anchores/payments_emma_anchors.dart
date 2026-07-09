import 'package:core/ui/anchors/anchor_spec.dart';

abstract final class PaymentsEmmaAnchors {
  static const String _module = 'payments';
  static const String _checkoutRoute = '/pro/checkout';
  static const String _goProRoute = '/pro/go-pro';
  static const String _successRoute = '/pro/payment-success';
  static const String _failureRoute = '/pro/payment-failure';


  static const EmmaUiAnchorSpec monthlyBillingOption = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.billing.monthly',
    frontendRef: 'PaymentsEmmaAnchors.monthlyBillingOption',
    label: 'Monthly billing option',
    description: 'Select monthly payment plan with recurring monthly charges',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'billing', 'monthly', 'plan', 'subscription'],
    meta: {
      'group': 'plan_selection',
      'billingInterval': 'month',
      'appModule': 'payments',
    },
    onboardingOrder: 1,
    onboardingMessage: 'Choose monthly billing to pay month by month',
  );

  static const EmmaUiAnchorSpec yearlyBillingOption = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.billing.yearly',
    frontendRef: 'PaymentsEmmaAnchors.yearlyBillingOption',
    label: 'Yearly billing option',
    description: 'Select yearly payment plan with discounted annual rate',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'billing', 'yearly', 'plan', 'subscription'],
    meta: {
      'group': 'plan_selection',
      'billingInterval': 'year',
      'appModule': 'payments',
    },
    onboardingOrder: 2,
    onboardingMessage: 'Save with yearly billing - pay once for the whole year',
  );

  static const EmmaUiAnchorSpec promotionCodeInput = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.promotion_code',
    frontendRef: 'PaymentsEmmaAnchors.promotionCodeInput',
    label: 'Promotion code input',
    description: 'Enter discount code to apply savings to your subscription',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['payments', 'promotion', 'discount', 'input'],
    meta: {
      'group': 'discounts',
      'appModule': 'payments',
    },
    onboardingOrder: 3,
    onboardingMessage: 'Got a discount code? Enter it here to save money',
  );

  static const EmmaUiAnchorSpec cardPaymentOption = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.payment.card',
    frontendRef: 'PaymentsEmmaAnchors.cardPaymentOption',
    label: 'Card payment option',
    description: 'Pay with credit or debit card',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'card', 'credit-card', 'payment-method'],
    meta: {
      'group': 'payment_methods',
      'appModule': 'payments',
    },
    onboardingOrder: 4,
    onboardingMessage: 'Pay securely with your credit or debit card',
  );

  static const EmmaUiAnchorSpec paypalPaymentOption = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.payment.paypal',
    frontendRef: 'PaymentsEmmaAnchors.paypalPaymentOption',
    label: 'PayPal payment option',
    description: 'Pay with your PayPal account',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'paypal', 'payment-method'],
    meta: {
      'group': 'payment_methods',
      'appModule': 'payments',
    },
    onboardingOrder: 5,
    onboardingMessage: 'Pay quickly and securely with PayPal',
  );

  static const EmmaUiAnchorSpec savedPaymentMethod = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.payment.saved_method',
    frontendRef: 'PaymentsEmmaAnchors.savedPaymentMethod',
    label: 'Saved payment method',
    description: 'Select from previously saved payment methods',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.listItem,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'saved', 'payment-method', 'card'],
    meta: {
      'group': 'saved_methods',
      'appModule': 'payments',
    },
    onboardingOrder: 6,
    onboardingMessage: 'Choose a saved card for faster checkout',
  );

  static const EmmaUiAnchorSpec addPaymentMethodButton = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.payment.add_new',
    frontendRef: 'PaymentsEmmaAnchors.addPaymentMethodButton',
    label: 'Add payment method button',
    description: 'Add a new credit card or payment method',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'add', 'payment-method', 'button', 'cta'],
    meta: {
      'group': 'payment_actions',
      'appModule': 'payments',
    },
    onboardingOrder: 7,
    onboardingMessage: 'Add a new card if you don\'t have one saved',
  );

  static const EmmaUiAnchorSpec nameOnCardInput = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.card.name_input',
    frontendRef: 'PaymentsEmmaAnchors.nameOnCardInput',
    label: 'Name on card input',
    description: 'Enter the name exactly as it appears on your card',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.onboarding,
    tags: ['payments', 'card', 'name', 'input', 'form'],
    meta: {
      'group': 'card_details',
      'appModule': 'payments',
    },
    onboardingOrder: 8,
    onboardingMessage: 'Enter your full name as shown on your card',
  );

  static const EmmaUiAnchorSpec countrySelection = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.card.country',
    frontendRef: 'PaymentsEmmaAnchors.countrySelection',
    label: 'Country selection',
    description: 'Select your billing country',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.input,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.onboarding,
    tags: ['payments', 'country', 'billing', 'dropdown'],
    meta: {
      'group': 'billing_address',
      'appModule': 'payments',
    },
    onboardingOrder: 9,
    onboardingMessage: 'Select your country for billing purposes',
  );

  static const EmmaUiAnchorSpec subscribeButton = EmmaUiAnchorSpec(
    anchorKey: 'payments.checkout.subscribe_button',
    frontendRef: 'PaymentsEmmaAnchors.subscribeButton',
    label: 'Subscribe button',
    description: 'Complete purchase and activate subscription',
    module: _module,
    screenKey: 'checkout',
    routePattern: _checkoutRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'subscribe', 'cta', 'button', 'checkout'],
    meta: {
      'group': 'primary_actions',
      'appModule': 'payments',
    },
    onboardingOrder: 10,
    onboardingMessage: 'Click here to complete your subscription',
  );

  static const EmmaUiAnchorSpec standardPlanCard = EmmaUiAnchorSpec(
    anchorKey: 'payments.go_pro.plan.standard',
    frontendRef: 'PaymentsEmmaAnchors.standardPlanCard',
    label: 'Standard plan card',
    description: 'Basic plan with essential features',
    module: _module,
    screenKey: 'go_pro',
    routePattern: _goProRoute,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'plan', 'standard', 'card', 'subscription'],
    meta: {
      'group': 'plan_cards',
      'tier': 'standard',
      'appModule': 'payments',
    },
    onboardingOrder: 11,
    onboardingMessage: 'Standard plan with basic features to get started',
  );

  static const EmmaUiAnchorSpec premiumPlanCard = EmmaUiAnchorSpec(
    anchorKey: 'payments.go_pro.plan.premium',
    frontendRef: 'PaymentsEmmaAnchors.premiumPlanCard',
    label: 'Premium plan card',
    description: 'Premium plan with advanced features and priority support',
    module: _module,
    screenKey: 'go_pro',
    routePattern: _goProRoute,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'plan', 'premium', 'card', 'subscription', 'popular'],
    meta: {
      'group': 'plan_cards',
      'tier': 'premium',
      'appModule': 'payments',
    },
    onboardingOrder: 12,
    onboardingMessage: 'Most popular - get advanced features and priority support',
  );

  static const EmmaUiAnchorSpec goldPlanCard = EmmaUiAnchorSpec(
    anchorKey: 'payments.go_pro.plan.gold',
    frontendRef: 'PaymentsEmmaAnchors.goldPlanCard',
    label: 'Gold plan card',
    description: 'Gold plan with all features and premium support',
    module: _module,
    screenKey: 'go_pro',
    routePattern: _goProRoute,
    targetKind: EmmaUiAnchorTargetKind.card,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'plan', 'gold', 'card', 'subscription'],
    meta: {
      'group': 'plan_cards',
      'tier': 'gold',
      'appModule': 'payments',
    },
    onboardingOrder: 13,
    onboardingMessage: 'Get everything with our Gold plan',
  );

  static const EmmaUiAnchorSpec billingIntervalToggle = EmmaUiAnchorSpec(
    anchorKey: 'payments.go_pro.billing_interval_toggle',
    frontendRef: 'PaymentsEmmaAnchors.billingIntervalToggle',
    label: 'Billing interval toggle',
    description: 'Switch between monthly and yearly billing',
    module: _module,
    screenKey: 'go_pro',
    routePattern: _goProRoute,
    targetKind: EmmaUiAnchorTargetKind.widget,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'billing', 'toggle', 'subscription'],
    meta: {
      'group': 'billing_options',
      'appModule': 'payments',
    },
    onboardingOrder: 14,
    onboardingMessage: 'Toggle between monthly and yearly billing',
  );

  static const EmmaUiAnchorSpec paymentSuccessPage = EmmaUiAnchorSpec(
    anchorKey: 'payments.success.page',
    frontendRef: 'PaymentsEmmaAnchors.paymentSuccessPage',
    label: 'Payment success page',
    description: 'Confirmation page shown after successful payment',
    module: _module,
    screenKey: 'payment_success',
    routePattern: _successRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.onboarding,
    tags: ['payments', 'success', 'confirmation', 'onboarding'],
    meta: {
      'group': 'results',
      'appModule': 'payments',
    },
    onboardingOrder: 15,
    onboardingMessage: 'Payment successful! Your subscription is now active',
  );

  static const EmmaUiAnchorSpec goToDashboardButton = EmmaUiAnchorSpec(
    anchorKey: 'payments.success.go_to_dashboard',
    frontendRef: 'PaymentsEmmaAnchors.goToDashboardButton',
    label: 'Go to dashboard button',
    description: 'Navigate to main dashboard after successful payment',
    module: _module,
    screenKey: 'payment_success',
    routePattern: _successRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'success', 'navigation', 'dashboard', 'button'],
    meta: {
      'group': 'result_actions',
      'appModule': 'payments',
    },
    onboardingOrder: 16,
    onboardingMessage: 'Click here to go to your dashboard',
  );

  static const EmmaUiAnchorSpec paymentFailurePage = EmmaUiAnchorSpec(
    anchorKey: 'payments.failure.page',
    frontendRef: 'PaymentsEmmaAnchors.paymentFailurePage',
    label: 'Payment failure page',
    description: 'Error page shown when payment fails',
    module: _module,
    screenKey: 'payment_failure',
    routePattern: _failureRoute,
    targetKind: EmmaUiAnchorTargetKind.section,
    runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
    tapMode: EmmaUiAnchorTapMode.disabled,
    usageMode: EmmaUiAnchorUsageMode.help,
    tags: ['payments', 'failure', 'error', 'help'],
    meta: {
      'group': 'results',
      'appModule': 'payments',
    },
  );

  static const EmmaUiAnchorSpec tryAgainButton = EmmaUiAnchorSpec(
    anchorKey: 'payments.failure.try_again',
    frontendRef: 'PaymentsEmmaAnchors.tryAgainButton',
    label: 'Try again button',
    description: 'Retry payment after failure',
    module: _module,
    screenKey: 'payment_failure',
    routePattern: _failureRoute,
    targetKind: EmmaUiAnchorTargetKind.button,
    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
    usageMode: EmmaUiAnchorUsageMode.both,
    tags: ['payments', 'failure', 'retry', 'button'],
    meta: {
      'group': 'result_actions',
      'appModule': 'payments',
    },
    onboardingOrder: 17,
    onboardingMessage: 'Click here to try your payment again',
  );

  static const List<EmmaUiAnchorSpec> values = [
    monthlyBillingOption,
    yearlyBillingOption,
    promotionCodeInput,
    cardPaymentOption,
    paypalPaymentOption,
    savedPaymentMethod,
    addPaymentMethodButton,
    nameOnCardInput,
    countrySelection,
    subscribeButton,
    standardPlanCard,
    premiumPlanCard,
    goldPlanCard,
    billingIntervalToggle,
    paymentSuccessPage,
    goToDashboardButton,
    paymentFailurePage,
    tryAgainButton,
  ];
}