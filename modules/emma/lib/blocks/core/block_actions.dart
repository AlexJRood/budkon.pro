import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

typedef EmmaBlockActionCallback = Future<void> Function({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> action,
  required String messageId,
  required Map<String, dynamic> block,
});

final emmaBlockActionHandlerProvider =
    Provider<EmmaBlockActionCallback?>((ref) => null);

String _asText(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

void _showSnack(
  BuildContext context,
  String text, {
  bool error = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.redAccent : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String _routeForClientAction(String clientAction) {
  switch (clientAction) {
    case 'open_calendar':
      return '/calendar';
    case 'open_tasks':
      return '/tms';
    case 'open_mailbox':
      return '/mail';
    case 'open_network_monitoring':
      return '/network-monitoring';
    case 'open_daily_market_overview':
      return '/reports/daily-market-overview';
    case 'open_emma_chat':
      return '/emma';
    default:
      return '';
  }
}

Future<void> runEmmaBlockAction({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> action,
  required String messageId,
  required Map<String, dynamic> block,
}) async {
  final customHandler = ref.read(emmaBlockActionHandlerProvider);

  if (customHandler != null) {
    await customHandler(
      context: context,
      ref: ref,
      action: action,
      messageId: messageId,
      block: block,
    );
    return;
  }

  final kind = _asText(action['kind']);
  final clientAction = _asText(action['client_action']);
  final type = _asText(action['type']);
  final prompt = _asText(action['prompt']);
  final label = _asText(action['label']).isNotEmpty
      ? _asText(action['label'])
      : _asText(action['text']);

  if (kind == 'prompt' && prompt.isNotEmpty) {
    await Clipboard.setData(ClipboardData(text: prompt));
    if (context.mounted) {
      _showSnack(
        context,
        'prompt_copied_message'.tr,
      );
    }
    return;
  }

  final payload = _asMap(action['payload']);

  final explicitRoute = _asText(action['route']).isNotEmpty
      ? _asText(action['route'])
      : _asText(payload['route']);

  final route = explicitRoute.isNotEmpty
      ? explicitRoute
      : _routeForClientAction(
          clientAction.isNotEmpty ? clientAction : type,
        );

  if (route.isEmpty) {
    if (context.mounted) {
      _showSnack(
        context,
        label.isNotEmpty
            ? '${'action_label_prefix'.tr} $label'
            : 'no_action_handler_message'.tr,
      );
    }
    return;
  }

  try {
    if (!context.mounted) return;

    Navigator.of(context).pushNamed(
      route,
      arguments: {
        'action': action,
        'payload': payload,
        'message_id': messageId,
        'block': block,
      },
    );
  } catch (_) {
    if (!context.mounted) return;

    _showSnack(
      context,
      '${'failed_to_open_route'.tr} $route',
      error: true,
    );
  }
}