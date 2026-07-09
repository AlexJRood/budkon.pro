import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payments/go_pro/checkout/checkout_pc.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 1080) {
          // Jeśli jest to aplikacja webowa lub aplikacja desktopowa z szerokością większą niż 1420
          return const CheckoutPc();
        } else {
          // W przeciwnym razie (aplikacja mobilna lub aplikacja desktopowa z mniejszą szerokością)
          return const CheckoutPc();
        }
      },
    );
  }
}
