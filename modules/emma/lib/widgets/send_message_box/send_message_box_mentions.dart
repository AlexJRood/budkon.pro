part of '../send_message_box.dart';

extension _SendMessageBoxMentions on _SendMessageBoxState {
  void _syncHasTypedText() {
    final hasText = _controller.text.trim().isNotEmpty;

    if (_hasTypedText == hasText) return;

    if (!_alive) {
      _hasTypedText = hasText;
      return;
    }

    setState(() {
      _hasTypedText = hasText;
    });
  }

  void _onTextChanged() {
    if (_isDisposed) return;

    this._queueDraftSave();
    this._syncHasTypedText();

    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    if (cursorPos <= 0 || cursorPos > text.length) {
      this._hideMentions();
      return;
    }

    var start = cursorPos - 1;

    while (start > 0) {
      final ch = text[start];

      if (ch == ' ' || ch == '\n' || ch == '\t') {
        start += 1;
        break;
      }

      start -= 1;
    }

    if (start < 0) start = 0;

    final currentWord = text.substring(start, cursorPos);

    if (currentWord.isEmpty) {
      this._hideMentions();
      return;
    }

    final firstChar = currentWord[0];

    if (firstChar != '@' && firstChar != '#' && firstChar != '/') {
      this._hideMentions();
      return;
    }

    // „/" traktujemy jak komendę TYLKO na początku wiadomości (nie w środku tekstu).
    if (firstChar == '/' && start != 0) {
      this._hideMentions();
      return;
    }

    final query = currentWord.substring(1);

    if (!_alive) return;

    ref.read(sendMessageBoxUiProvider.notifier).setMentionState(
          mentionStartIndex: start,
          mentionQuery: query,
          showMentions: true,
          currentTriggerChar: firstChar,
        );
  }

  void _hideMentions() {
    if (!_alive) return;

    ref.read(sendMessageBoxUiProvider.notifier).hideMentions();
  }

  void _insertMention(MentionItem item) {
    if (!_alive) return;

    final uiState = ref.read(sendMessageBoxUiProvider);

    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    if (uiState.mentionStartIndex < 0 ||
        uiState.mentionStartIndex > text.length ||
        cursorPos < uiState.mentionStartIndex) {
      return;
    }

    final before = text.substring(0, uiState.mentionStartIndex);
    final after = text.substring(cursorPos);

    final prefix =
        uiState.currentTriggerChar.isEmpty ? '@' : uiState.currentTriggerChar;

    final tag = item.tag.isNotEmpty ? item.tag : '$prefix${item.displayName}';
    // Dla slash-komend tag = sama nazwa toola → dopnij wiodące „/".
    final needsSlash = prefix == '/' && !tag.startsWith('/');
    final mentionText = '${needsSlash ? '/' : ''}$tag ';

    final newText = '$before$mentionText$after';
    final newCursorPos = (before + mentionText).length;

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newCursorPos);

    ref.read(sendMessageBoxUiProvider.notifier).hideMentions();

    this._syncHasTypedText();
    this._requestFocusStable();
  }

  bool _handleBackspaceOnMention() {
    if (_isDisposed) return false;

    final text = _controller.text;

    if (text.isEmpty) return false;

    final selection = _controller.selection;

    if (!selection.isCollapsed) return false;

    final cursorPos = selection.baseOffset;

    if (cursorPos <= 0) return false;

    final matches = mentionRe.allMatches(text).toList();

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      if (cursorPos > start && cursorPos <= end) {
        final kind = match.group(1);

        final deleteStart = start;
        var deleteEnd = end;

        if (kind == 'tx' && deleteEnd < text.length && text[deleteEnd] == ' ') {
          deleteEnd += 1;
        }

        final newText = text.replaceRange(deleteStart, deleteEnd, '');

        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: deleteStart);

        this._syncHasTypedText();

        return true;
      }
    }

    return false;
  }
}