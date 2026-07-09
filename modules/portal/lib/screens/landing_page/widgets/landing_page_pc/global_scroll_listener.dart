import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/landing_page/providers/scrolle_popup_manager_provider.dart';

class GlobalScrollListener extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalScrollListener({super.key, required this.child});

  @override
  ConsumerState<GlobalScrollListener> createState() =>
      _GlobalScrollListenerState();
}

class _GlobalScrollListenerState extends ConsumerState<GlobalScrollListener> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          // Debounce closing popups so we don't spam Riverpod on every frame.
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 60), () {
            ref.read(scrollPopupManagerProvider).closeAllPopups();
          });
        }
        return false;
      },
      child: widget.child,
    );
  }
}
