import 'dart:js_interop';
import 'package:web/web.dart' as web;

void vibrate(List<int> pattern) {
  try {
    final jsPattern = pattern.map((ms) => ms.toJS).toList().toJS;
    web.window.navigator.vibrate(jsPattern);
  } catch (_) {
    // no-op
  }
}