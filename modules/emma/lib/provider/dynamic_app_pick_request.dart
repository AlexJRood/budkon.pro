import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple event bus for "please pick a node in Dynamic App builder".
/// Builder screen should listen to changes and open node picker overlay.
final emmaDynamicAppPickRequestProvider = StateProvider<int>((ref) => 0);
