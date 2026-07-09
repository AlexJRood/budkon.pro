part of '../send_message_box.dart';

extension _SendMessageBoxFocus on _SendMessageBoxState {
  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_alive) return;
      FocusScope.of(context).requestFocus(_focusNode);
      _focusNode.requestFocus();
    });
  }

  void _requestFocusStable() {
    void focus() {
      if (!_alive) return;

      if (!_focusNode.canRequestFocus) {
        return;
      }

      try {
        FocusScope.of(context).requestFocus(_focusNode);
        _focusNode.requestFocus();
      } catch (_) {}
    }

    focus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focus();
    });

    Future.delayed(const Duration(milliseconds: 60), focus);
    Future.delayed(const Duration(milliseconds: 160), focus);
  }
}