part of '../emma_notifier.dart';

/// Structured assistant blocks and tool-status event handling.
extension EmmaNotifierBlocks on ChatAiMessagesNotifier {
  Map<String, dynamic> _loadingBlock({
    required String blockId,
    required String title,
    required String detail,
    String source = '',
    String blockType = '',
    // Docelowe wymiary (obecnie dla generacji obrazu) — pozwalają zarezerwować
    // właściwe proporcje już podczas ładowania, bez skoku layoutu.
    Object? width,
    Object? height,
  }) {
    return {
      'type': 'loading',
      'block_id': blockId,
      'title': title,
      'label': title,
      'detail': detail,
      'description': detail,
      'source': source,
      'block_type': blockType,
      'status': 'pending',
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  Map<String, dynamic> _infoBlock({
    required String blockId,
    required String title,
    required String detail,
    String variant = 'info',
    String source = '',
  }) {
    return {
      'type': 'info',
      'block_id': blockId,
      'title': title,
      'label': title,
      'detail': detail,
      'description': detail,
      'variant': variant,
      'source': source,
    };
  }

  void _handleAssistantToolPlan(Map<String, dynamic> data) {
    final toolsAvailable =
        data['tools_available'] == true || data['will_consider_tools'] == true;

    if (!toolsAvailable) {
      _setActivity(
        title: 'emma_responding'.tr,
        detail: 'no_tools_needed'.tr,
      );
      return;
    }

    final rawNames = data['tool_names'];
    final names = rawNames is List
        ? rawNames
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : <String>[];

    _setActivity(
      title: 'emma_checking_tools'.tr,
      detail: names.isEmpty
          ? 'analyzing_system_actions'.tr
          : '${'available_tools_prefix'.tr} ${names.take(3).join(', ')}${names.length > 3 ? '...' : ''}',
    );

    state = state.copyWith(
      isLoading: true,
      canCancel: true,
    );

    _startLoadingWatchdog();
  }

  String _toolBlockId(Map<String, dynamic> data) {
    final explicit =
        (data['block_id'] ?? data['tool_call_id'] ?? data['id'] ?? '')
            .toString();

    if (explicit.trim().isNotEmpty) {
      return 'tool:$explicit';
    }

    final messageId = _resolveAssistantMessageId(data) ?? 0;
    final toolName = (data['tool_name'] ?? data['name'] ?? 'tool').toString();

    return 'tool:$messageId:$toolName';
  }

  /// Przyjazny (tytuł, szczegół) dla trwającego narzędzia — dedykowane komunikaty
  /// dla częstych/długich operacji (np. generacja obrazu).
  (String, String) _toolFriendlyLabel(String toolName) {
    final t = toolName.toLowerCase();
    if (t.contains('generate_image')) {
      return ('🎨 Generuję obraz…', 'To zwykle trwa kilka–kilkanaście sekund.');
    }
    if (t.contains('recall') || t.contains('search') || t.contains('universal')) {
      return ('🔎 Szukam…', toolName);
    }
    if (t.contains('schedule') || t.contains('reminder')) {
      return ('⏰ Ustawiam przypomnienie…', toolName);
    }
    return ('emma_using_tool'.tr, toolName);
  }

  void _handleAssistantToolCallStarted(Map<String, dynamic> data) {
    _handleActivityStatus(data);

    final toolName = (data['tool_name'] ?? data['name'] ?? 'tool').toString();
    // Preferuj gotową, ludzką etykietę z backendu; fallback do lokalnej mapy.
    final backendTitle = (data['action_label'] ?? data['title'] ?? '').toString().trim();
    final backendDetail = (data['action_detail'] ?? '').toString().trim();
    final (localTitle, localDetail) = _toolFriendlyLabel(toolName);
    final friendlyTitle = backendTitle.isNotEmpty ? backendTitle : localTitle;
    final friendlyDetail = backendDetail.isNotEmpty ? backendDetail : localDetail;

    final messageId = _resolveAssistantMessageId(data);
    if (!_isValidMessageIdForLocal(messageId)) {
      // Brak wiadomości do zakotwiczenia bloku — status niesie pływający bąbelek.
      _setActivity(title: friendlyTitle, detail: friendlyDetail);
      state = state.copyWith(activityInline: false);
      return;
    }

    final module = (data['module'] ?? '').toString();
    final blockId = _toolBlockId(data);

    _setActivity(title: friendlyTitle, detail: friendlyDetail);
    // Status jest już renderowany w bloku — ukryj bąbelek, żeby nie dublować.
    state = state.copyWith(activityInline: true);
    _upsertAssistantBlock(
      messageId: messageId!,
      keepLoading: true,
      block: _loadingBlock(
        blockId: blockId,
        title: friendlyTitle,
        detail: friendlyDetail.isNotEmpty
            ? friendlyDetail
            : (module.trim().isEmpty ? toolName : '$toolName • $module'),
        source: 'tool_call',
        blockType: toolName,
        width: data['width'],
        height: data['height'],
      ),
    );
  }

  void _handleAssistantToolCallFinished(Map<String, dynamic> data) {
    _handleActivityStatus(data);

    final messageId = _resolveAssistantMessageId(data);
    if (!_isValidMessageIdForLocal(messageId)) return;

    final toolName = (data['tool_name'] ?? data['name'] ?? 'tool').toString();
    final ok = data['ok'] != false;
    final blockId = _toolBlockId(data);

    // Sukces nie jest informacją — użytkownik widzi WYNIK (blok wydarzenia, obraz,
    // treść odpowiedzi). Zielony „Narzędzie zakończone" to czysty szum, więc po
    // udanym wywołaniu po prostu usuwamy blok ładowania.
    // Generacja obrazu: zostawiamy shimmer, bo obraz jest jeszcze w drodze
    // (upload + finalna wiadomość) — blok obrazu płynnie go zastąpi.
    if (ok) {
      if (toolName.toLowerCase().contains('generate_image')) return;
      _removeAssistantBlock(messageId: messageId!, blockId: blockId);
      return;
    }

    _upsertAssistantBlock(
      messageId: messageId!,
      keepLoading: true,
      block: _infoBlock(
        blockId: blockId,
        title: 'tool_returned_error'.tr,
        detail: toolName,
        variant: 'error',
        source: 'tool_call',
      ),
    );
  }

  void _handleAssistantBlockPending(Map<String, dynamic> data) {
    _handleActivityStatus(data);

    final messageId = _resolveAssistantMessageId(data);
    if (!_isValidMessageIdForLocal(messageId)) return;

    final blockId = (data['block_id'] ??
            'block:${messageId}:${DateTime.now().microsecondsSinceEpoch}')
        .toString();

    final blockType = (data['block_type'] ?? 'block').toString();

    _upsertAssistantBlock(
      messageId: messageId!,
      keepLoading: true,
      block: _loadingBlock(
        blockId: blockId,
        title: (data['title'] ?? 'emma_preparing_block'.tr).toString(),
        detail: (data['detail'] ?? '${'creating_block_prefix'.tr} $blockType.').toString(),
        source: 'assistant_block',
        blockType: blockType,
      ),
    );
  }

  void _handleAssistantBlockReady(Map<String, dynamic> data) {
    _handleActivityStatus(data);

    final messageId = _resolveAssistantMessageId(data);
    if (!_isValidMessageIdForLocal(messageId)) return;

    final rawBlock = data['block'];
    if (rawBlock is! Map) return;

    final block = Map<String, dynamic>.from(rawBlock);

    final blockId =
        (data['block_id'] ?? block['block_id'] ?? block['id'] ?? '').toString();

    if (blockId.trim().isNotEmpty) {
      block['block_id'] = blockId;
    }

    // Blok może dolecieć bez trwającej tury (np. przypomnienie dostarczone przez
    // Celery). Nie wolno mu WŁĄCZAĆ ładowania — inaczej „Emma pracuje…" wisi
    // w nieskończoność. Podtrzymujemy loading tylko, gdy tura faktycznie trwa.
    _upsertAssistantBlock(
      messageId: messageId!,
      keepLoading: state.isLoading,
      block: block,
    );
  }

  void _handleAssistantBlockError(Map<String, dynamic> data) {
    _handleActivityStatus(data);

    final messageId = _resolveAssistantMessageId(data);
    if (!_isValidMessageIdForLocal(messageId)) return;

    final blockId = (data['block_id'] ??
            'block_error:${messageId}:${DateTime.now().microsecondsSinceEpoch}')
        .toString();

    _upsertAssistantBlock(
      messageId: messageId!,
      keepLoading: true,
      block: _infoBlock(
        blockId: blockId,
        title: (data['title'] ?? 'failed_to_prepare_block'.tr).toString(),
        detail: (data['error'] ?? data['detail'] ?? '').toString(),
        variant: 'error',
        source: 'assistant_block',
      ),
    );
  }
}
