import 'package:core/kernel/kernel.dart';
import 'routing.dart';

import 'package:payments/settings/settings_payment_pc.dart';
import 'package:payments/settings/settings_payments_mobile.dart';

/// Registration surface for the payments module. Owns the payment/billing
/// settings screens and contributes them through the [SettingsContribution]
/// registry so core/settings no longer imports them directly.
class PaymentsModule extends AppModule {
  @override
  String get id => 'payments';

  @override
  List<SettingsContribution> settingsSections() => [
        SettingsContribution(
          id: 'payments',
          titleKey: 'Payments',
          iconKey: 'payment',
          order: 30,
          pcPage: (context, args) => const SettingsPaymentPc(),
          mobilePage: (context, args) => const SettingsPaymentsMobile(),
        ),
      ];

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => paymentsRoutes;
}
