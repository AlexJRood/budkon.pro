part of '../emma_notifier.dart';

/// Akcje Emmy związane z automatyzacją.
///
/// Bloki [AutomationWorkflowBlock], [AutomationDryRunBlock] i
/// [AutomationSetupWizardBlock] wywołują te metody przez
/// `ref.read(chatAiMessageProvider.notifier)`.
extension EmmaNotifierAutomation on ChatAiMessagesNotifier {
  /// Uruchamia dry-run przez REST i wstawia wynik jako blok Emmy.
  ///
  /// Używane przez przycisk "Dry run" na karcie workflow.
  Future<void> runAutomationDryRun(String workflowId) async {
    if (workflowId.trim().isEmpty) return;

    // Pesymistyczny blok ładowania — user widzi że coś się dzieje.
    _emitLoadingActivity('automation_dry_run_running'.tr);

    try {
      final svc = ref.read(emmaAutomationServiceProvider);
      final result = await svc.dryRun(workflowId);

      final blockPayload = <String, dynamic>{
        'type': 'automation_dry_run',
        'dry_run': {
          'workflow_id': workflowId,
          'status': result.isSuccess ? 'ok' : 'failed',
          'steps': result.steps,
          'error': result.errorMessage,
          'duration_ms': result.durationMs,
        },
      };

      _injectSyntheticAssistantBlock(blockPayload);
    } catch (e) {
      _clearLoadingActivity();
      if (kDebugMode) debugPrint('Emma automation dry-run error: $e');
      _injectSyntheticAssistantBlock(<String, dynamic>{
        'type': 'info',
        'level': 'error',
        'message': 'automation_dry_run_failed_info'.tr,
      });
    }
  }

  /// Dezaktywuje (wstrzymuje) workflow i wstawia zaktualizowaną kartę.
  Future<void> deactivateAutomationWorkflow(String workflowId) async {
    if (workflowId.trim().isEmpty) return;

    _emitLoadingActivity('automation_deactivating'.tr);

    try {
      final svc = ref.read(emmaAutomationServiceProvider);
      final updated = await svc.deactivateWorkflow(workflowId);

      _injectSyntheticAssistantBlock(<String, dynamic>{
        'type': 'automation_workflow',
        'operation': 'deactivate',
        'workflow': {
          ...updated,
          'status': updated['status'] ?? 'paused',
          'operation': 'deactivate',
        },
      });

      _injectSyntheticAssistantText('automation_deactivated_confirmation'.tr);
    } catch (e) {
      _clearLoadingActivity();
      if (kDebugMode) debugPrint('Emma automation deactivate error: $e');
      _injectSyntheticAssistantBlock(<String, dynamic>{
        'type': 'info',
        'level': 'error',
        'message': 'automation_activate_failed_info'.tr,
      });
    }
  }

  /// Aktywuje workflow przez REST i wstawia zaktualizowaną kartę jako blok.
  ///
  /// Używane przez przycisk "Aktywuj" na karcie dry-run lub workflow.
  Future<void> activateAutomationWorkflow(String workflowId) async {
    if (workflowId.trim().isEmpty) return;

    _emitLoadingActivity('automation_activating'.tr);

    try {
      final svc = ref.read(emmaAutomationServiceProvider);
      final updated = await svc.activateWorkflow(workflowId);

      final blockPayload = <String, dynamic>{
        'type': 'automation_workflow',
        'operation': 'activate',
        'workflow': {
          ...updated,
          'status': updated['status'] ?? 'active',
          'operation': 'activate',
        },
      };

      _injectSyntheticAssistantBlock(blockPayload);

      // Krótka wiadomość tekstowa — Emma potwierdza aktywację.
      _injectSyntheticAssistantText(
        'automation_activated_confirmation'.tr,
      );
    } catch (e) {
      _clearLoadingActivity();
      if (kDebugMode) debugPrint('Emma automation activate error: $e');
      _injectSyntheticAssistantBlock(<String, dynamic>{
        'type': 'info',
        'level': 'error',
        'message': 'automation_activate_failed_info'.tr,
      });
    }
  }

  /// Wysyła odpowiedzi z wizarda do backendu i kontynuuje flow.
  ///
  /// Jeśli mamy `workflowId` — wywołujemy `refineWorkflow` bezpośrednio
  /// przez REST i wstrzykujemy wynik jako blok (bez WS round-trip).
  /// W przeciwnym razie wysyłamy podsumowanie jako wiadomość czatową,
  /// żeby Emma mogła doprecyzować na podstawie tekstu.
  Future<void> submitAutomationWizardAnswers({
    required String workflowId,
    required Map<String, String> answers,
    required String summaryText,
  }) async {
    // Zawsze pokaż odpowiedź usera w widoku czatu.
    _injectSyntheticUserText(
      summaryText.isNotEmpty ? summaryText : answers.values.join(', '),
    );

    if (workflowId.isNotEmpty) {
      // Ścieżka REST: znamy workflowId → refinujemy bezpośrednio.
      _emitLoadingActivity('automation_dry_run_running'.tr);
      try {
        final svc = ref.read(emmaAutomationServiceProvider);
        final result = await svc.refineWorkflow(
          workflowId: workflowId,
          answers: Map<String, dynamic>.from(answers),
        );

        if (result.needsMoreInfo) {
          // Backnd chce więcej — wstrzyknij kolejny wizard.
          _injectSyntheticAssistantBlock(<String, dynamic>{
            'type': 'automation_setup_wizard',
            'wizard': {
              'workflow_id': workflowId,
              'questions': result.questions,
              'step': 2,
            },
          });
        } else if (result.workflow.isNotEmpty) {
          _injectSyntheticAssistantBlock(<String, dynamic>{
            'type': 'automation_workflow',
            'operation': 'create',
            'workflow': result.workflow,
          });
        }
      } catch (e) {
        _clearLoadingActivity();
        if (kDebugMode) debugPrint('Emma automation refine error: $e');
        _injectSyntheticAssistantBlock(<String, dynamic>{
          'type': 'info',
          'level': 'error',
          'message': 'automation_dry_run_failed_info'.tr,
        });
      }
    } else {
      // Nie mamy workflowId — wyślij tekst do Emmy przez WS,
      // backend sam rozpozna kontekst.
      await sendMessage(
        summaryText.isNotEmpty ? summaryText : answers.values.join(', '),
      );
    }
  }

  // ---------- helpers ----------

  void _emitLoadingActivity(String title) {
    if (!_canEmit) return;
    _emitFrom(
      (s) => s.copyWith(
        isLoading: true,
        canCancel: false,
        activityTitle: title,
        activityDetail: '',
      ),
    );
  }

  void _clearLoadingActivity() {
    if (!_canEmit) return;
    _emitFrom(
      (s) => s.copyWith(
        isLoading: false,
        canCancel: false,
        clearActivity: true,
      ),
    );
  }

  /// Wstawia syntetyczny blok asystenta do listy wiadomości.
  ///
  /// Blok jest widoczny natychmiast, bez czekania na WebSocket.
  void _injectSyntheticAssistantBlock(Map<String, dynamic> blockPayload) {
    if (!_canEmit) return;

    final now = DateTime.now();
    final tempId = now.microsecondsSinceEpoch * -1;

    final syntheticMsg = ChatMessageDto(
      id: tempId,
      sessionId: _currentSessionId ?? -1,
      role: 'assistant',
      kind: 'block',
      content: '',
      createdAt: now,
      likesCount: 0,
      dislikesCount: 0,
      meta: {
        'blocks': [blockPayload],
        'synthetic': true,
      },
      isSeen: true,
      seenAt: now,
    );

    final updated = [...state.messages, syntheticMsg]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _emitFrom(
      (s) => s.copyWith(
        messages: updated,
        isLoading: false,
        canCancel: false,
        clearActivity: true,
      ),
    );
  }

  /// Wstawia syntetyczną wiadomość tekstową użytkownika (widoczna w czacie).
  void _injectSyntheticUserText(String text) {
    if (!_canEmit) return;
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final tempId = now.microsecondsSinceEpoch * -1;

    final syntheticMsg = ChatMessageDto(
      id: tempId,
      sessionId: _currentSessionId ?? -1,
      role: 'user',
      kind: 'text',
      content: text,
      createdAt: now,
      likesCount: 0,
      dislikesCount: 0,
      meta: {'synthetic': true},
      isSeen: true,
      seenAt: now,
    );

    final updated = [...state.messages, syntheticMsg]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _emitFrom((s) => s.copyWith(messages: updated));
  }

  /// Wstawia syntetyczną wiadomość tekstową asystenta.
  void _injectSyntheticAssistantText(String text) {
    if (!_canEmit) return;
    if (text.trim().isEmpty) return;

    final now = DateTime.now().add(const Duration(milliseconds: 50));
    final tempId = now.microsecondsSinceEpoch * -1;

    final syntheticMsg = ChatMessageDto(
      id: tempId,
      sessionId: _currentSessionId ?? -1,
      role: 'assistant',
      kind: 'text',
      content: text,
      createdAt: now,
      likesCount: 0,
      dislikesCount: 0,
      meta: {'synthetic': true},
      isSeen: true,
      seenAt: now,
    );

    final updated = [...state.messages, syntheticMsg]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _emitFrom((s) => s.copyWith(messages: updated));
  }
}
