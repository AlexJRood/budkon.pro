import 'package:emma/blocks/core/block_actions.dart';
import 'package:emma/local_engine/emma_local_engine_lifecycle.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emma/screens/mobile.dart';
import 'package:emma/screens/pc.dart';
import 'package:get/get_utils/get_utils.dart';

class ChatAiPage extends ConsumerWidget {
  const ChatAiPage({super.key});

  Future<void> _ensureSessionAndSendPrompt({
    required WidgetRef ref,
    required String prompt,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final notifier = ref.read(chatAiMessageProvider.notifier);

    int? sessionId = notifier.currentSessionId;

    if (sessionId == null) {
      final selectedRaw = ref.read(selectedAiRoomProvider).trim();
      sessionId = int.tryParse(selectedRaw);
    }

    ref.read(emmaChatBootstrappingProvider.notifier).state = true;

    try {
      if (sessionId == null) {
        final room = await ref
            .read(chatAiRoomsProvider.notifier)
            .createRoomAndReturn(title: 'New chat');

        if (room == null) return;

        sessionId = room.id;
        ref.read(selectedAiRoomProvider.notifier).state = sessionId.toString();

        await notifier.connectToSession(sessionId);

        try {
          await notifier.waitForWsReady();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Emma block action: WS not ready after creating room: $e');
          }
          return;
        }

        await notifier.sendMessage(trimmed);
        return;
      }

      if (notifier.currentSessionId != sessionId) {
        await notifier.connectToSession(sessionId);
      }

      try {
        await notifier.waitForWsReady();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Emma block action: WS not ready: $e');
        }
        return;
      }

      final chatState = ref.read(chatAiMessageProvider);
      final messages = chatState.messages;

      final isBlocked = chatState.isLoading &&
          messages.isNotEmpty &&
          messages.last.isUser;

      if (isBlocked) return;

      await notifier.sendMessage(trimmed);
    } finally {
      ref.read(emmaChatBootstrappingProvider.notifier).state = false;
    }
  }

  void _openRouteFromClientAction({
    required BuildContext context,
    required Map<String, dynamic> action,
  }) {
    final clientAction = (action['client_action'] ?? '').toString().trim();
    final payloadRaw = action['payload'];
    final payload = payloadRaw is Map
        ? Map<String, dynamic>.from(payloadRaw)
        : <String, dynamic>{};

    String route = '';

    switch (clientAction) {
      case 'open_calendar':
        route = '/calendar';
        break;

      case 'open_tasks':
        route = '/tms';
        break;

      case 'open_mailbox':
        route = '/mail';
        break;

      case 'open_network_monitoring':
        route = '/network-monitoring';
        break;

      case 'open_daily_market_overview':
        route = '/reports/daily-market-overview';
        break;

      case 'open_emma_chat':
        route = '/emma';
        break;

      default:
        route = (action['route'] ?? payload['route'] ?? '').toString().trim();
        break;
    }

    if (route.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('no_action_handler_message'.tr),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      Navigator.of(context).pushNamed(
        route,
        arguments: {
          'action': action,
          'payload': payload,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Emma block action route error: $e');
      }

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('${'failed_to_open_route'.tr} $route'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleEmmaBlockAction({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> action,
    required String messageId,
    required Map<String, dynamic> block,
  }) async {
    final kind = (action['kind'] ?? '').toString().trim();
    final prompt = (action['prompt'] ?? '').toString().trim();
    final clientAction = (action['client_action'] ?? '').toString().trim();

    if (kind == 'prompt' && prompt.isNotEmpty) {
      await _ensureSessionAndSendPrompt(
        ref: ref,
        prompt: prompt,
      );
      return;
    }

    if (kind == 'client_action' || clientAction.isNotEmpty) {
      _openRouteFromClientAction(
        context: context,
        action: action,
      );
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('unsupported_memo_action'.tr),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activates the local engine lifecycle watcher on desktop.
    // No-op on web/mobile — handled inside the provider.
    ref.watch(emmaLocalEngineLifecycleProvider);

    return ProviderScope(
      overrides: [
        emmaBlockActionHandlerProvider.overrideWithValue(
          ({
            required BuildContext context,
            required WidgetRef ref,
            required Map<String, dynamic> action,
            required String messageId,
            required Map<String, dynamic> block,
          }) async {
            await _handleEmmaBlockAction(
              context: context,
              ref: ref,
              action: action,
              messageId: messageId,
              block: block,
            );
          },
        ),
      ],
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 1080) {
            return const ChatAiPc();
          }

          return ChatAiMobile();
        },
      ),
    );
  }
}