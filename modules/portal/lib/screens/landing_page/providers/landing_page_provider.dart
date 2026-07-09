import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedLocationProvider = StateProvider<String>((ref) => '');
final isLocationVisibleProvider = StateProvider<bool>((ref) => false);
final isPropertyVisibleProvider = StateProvider<bool>((ref) => false);
final selectedPropertyProvider = StateProvider<String>((ref) => '');
final selectedTypeProvider = StateProvider<String>((ref) => '');
final selectedPriceRangeProvider = StateProvider<String>((ref) => '');
final isPriceSelectedProvider = StateProvider<bool>((ref) => false);
final selectedMeterRangeProvider = StateProvider<String>((ref) => '');
final isSelectedMeterRangeProvider = StateProvider<bool>((ref) => false);

void resetLandingFilterUiProviders(WidgetRef ref) {
  ref.read(selectedLocationProvider.notifier).state = '';
  ref.read(isLocationVisibleProvider.notifier).state = false;
  ref.read(isPropertyVisibleProvider.notifier).state = false;
  ref.read(selectedPropertyProvider.notifier).state = '';
  ref.read(selectedTypeProvider.notifier).state = '';
  ref.read(selectedPriceRangeProvider.notifier).state = '';
  ref.read(isPriceSelectedProvider.notifier).state = false;
  ref.read(selectedMeterRangeProvider.notifier).state = '';
  ref.read(isSelectedMeterRangeProvider.notifier).state = false;
}