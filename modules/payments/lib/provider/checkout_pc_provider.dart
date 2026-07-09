import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

/// =======================
/// Riverpod UI Providers
/// =======================

/// 'Monthly' | 'Yearly' (stored as translated string, same as before)
final selectedTypeProvider = StateProvider<String>((ref) => 'Monthly'.tr);

/// 'Card' | 'Paypal' (stored as translated string, same as before)
final paymentMethodProvider = StateProvider<String>((ref) => 'Card'.tr);

/// Promo toggle
final hasPromoProvider = StateProvider<bool>((ref) => false);

/// Selected country for card / PayPal
final selectedCountryCardProvider = StateProvider<String?>((ref) => null);

/// Subscribe button submitting flag
final isSubmittingProvider = StateProvider<bool>((ref) => false);

/// Text field error providers (for inline validation)
final cardNumberErrorProvider = StateProvider<String?>((ref) => null);
final expiryDateErrorProvider = StateProvider<String?>((ref) => null);
final cvvErrorProvider = StateProvider<String?>((ref) => null);
final nameOnCardErrorProvider = StateProvider<String?>((ref) => null);

/// Whether user is currently adding a new card (vs. seeing saved cards)
final isAddingNewCardProvider = StateProvider<bool>((ref) => true);
