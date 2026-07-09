import 'package:flutter/foundation.dart';

// Singleton tracking the active Emma floating overlay.
// Allows any module to: close the active overlay, or intercept
// future overlay-open requests (e.g. docs redirects them to its side panel).
class EmmaOverlayManager {
  EmmaOverlayManager._();

  // Close callback for the currently-open floating overlay, if any.
  static VoidCallback? _closeActive;

  // If set, openEmmaOverlay calls this instead of showing a new overlay.
  // Used by screens (e.g. docs) that embed Emma inline and want to own it.
  static VoidCallback? _interceptor;

  /// Register a new overlay. Closes any existing overlay first (one at a time).
  static void registerOverlay(VoidCallback close) {
    _closeActive?.call();
    _closeActive = close;
  }

  /// Must be called when the overlay closes (by user or programmatically).
  static void onOverlayClosed() {
    _closeActive = null;
  }

  /// Programmatically close the active overlay, if any.
  static void closeActive() {
    _closeActive?.call();
    _closeActive = null;
  }

  static bool get hasActiveOverlay => _closeActive != null;

  /// Register a screen-level interceptor.
  /// When set, [openEmmaOverlay] will call this instead of opening a new overlay.
  static void setInterceptor(VoidCallback? cb) {
    _interceptor = cb;
  }

  static VoidCallback? get interceptor => _interceptor;
}
