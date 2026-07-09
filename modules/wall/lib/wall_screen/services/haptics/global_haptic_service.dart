// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'web_haptic_stub.dart'
//     if (dart.library.html) 'web_haptic_html.dart' as web_haptics;

// // ─── Provider ────────────────────────────────────────────────────────────────

// final hapticServiceProvider = Provider<HapticService>((ref) {
//   return HapticService();
// });

// // ─── Intensity enum ──────────────────────────────────────────────────────────

// enum HapticIntensity {
//   light,
//   medium,
//   heavy,
//   selection,
//   success,
//   warning,
//   error,
// }

// // ─── Service ─────────────────────────────────────────────────────────────────

// class HapticService {
//   /// Light tap — toggles, checkboxes, small selections
//   Future<void> light() => _trigger(HapticIntensity.light);

//   /// Medium tap — likes, button presses, confirmations
//   Future<void> medium() => _trigger(HapticIntensity.medium);

//   /// Heavy tap — celebrations, destructive actions
//   Future<void> heavy() => _trigger(HapticIntensity.heavy);

//   /// Subtle click — list item selection, tab switching
//   Future<void> selection() => _trigger(HapticIntensity.selection);

//   /// Success pattern — form submit, payment done
//   Future<void> success() => _trigger(HapticIntensity.success);

//   /// Warning pattern — validation warning, caution
//   Future<void> warning() => _trigger(HapticIntensity.warning);

//   /// Error pattern — failed action, destructive confirm
//   Future<void> error() => _trigger(HapticIntensity.error);

//   Future<void> _trigger(HapticIntensity intensity) async {
//     if (kIsWeb) {
//       _triggerWeb(intensity);
//       return;
//     }

//     await _triggerNative(intensity);
//   }

//   // ── Native (Android + iOS + safe desktop fallback) ────────────────────────

//   Future<void> _triggerNative(HapticIntensity intensity) async {
//     try {
//       switch (intensity) {
//         case HapticIntensity.light:
//           await HapticFeedback.lightImpact();
//           break;

//         case HapticIntensity.medium:
//           await HapticFeedback.mediumImpact();
//           break;

//         case HapticIntensity.heavy:
//           await HapticFeedback.heavyImpact();
//           break;

//         case HapticIntensity.selection:
//           await HapticFeedback.selectionClick();
//           break;

//         case HapticIntensity.success:
//           await HapticFeedback.mediumImpact();
//           await Future.delayed(const Duration(milliseconds: 100));
//           await HapticFeedback.lightImpact();
//           break;

//         case HapticIntensity.warning:
//           await HapticFeedback.mediumImpact();
//           await Future.delayed(const Duration(milliseconds: 80));
//           await HapticFeedback.mediumImpact();
//           break;

//         case HapticIntensity.error:
//           await HapticFeedback.heavyImpact();
//           await Future.delayed(const Duration(milliseconds: 80));
//           await HapticFeedback.heavyImpact();
//           await Future.delayed(const Duration(milliseconds: 80));
//           await HapticFeedback.heavyImpact();
//           break;
//       }
//     } catch (_) {
//       // Haptics are optional enhancement only
//     }
//   }

//   // ── Web ────────────────────────────────────────────────────────────────────

//   void _triggerWeb(HapticIntensity intensity) {
//     try {
//       switch (intensity) {
//         case HapticIntensity.light:
//           _vibrate(const [10]);
//           break;

//         case HapticIntensity.medium:
//           _vibrate(const [20]);
//           break;

//         case HapticIntensity.heavy:
//           _vibrate(const [40]);
//           break;

//         case HapticIntensity.selection:
//           _vibrate(const [5]);
//           break;

//         case HapticIntensity.success:
//           _vibrate(const [10, 50, 10]);
//           break;

//         case HapticIntensity.warning:
//           _vibrate(const [20, 60, 20]);
//           break;

//         case HapticIntensity.error:
//           _vibrate(const [40, 40, 40, 40, 40]);
//           break;
//       }
//     } catch (_) {
//       // Desktop browsers / unsupported browsers: no-op
//     }
//   }

//   void _vibrate(List<int> pattern) {
//     try {
//       web_haptics.vibrate(pattern);
//     } catch (_) {
//       // no-op
//     }
//   }
// }
