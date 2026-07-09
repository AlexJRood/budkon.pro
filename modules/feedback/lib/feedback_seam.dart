import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/kernel/kernel.dart';

import 'package:feedback/feedback.dart';
import 'package:feedback/src/provider/feedback_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/user/user/user_provider.dart';

int? _asIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

/// The in-app feedback flow, extracted from the shell's logo button so
/// `bar_manager` no longer imports the feedback feature. Installed into
/// [feedbackLauncherProvider] via [feedbackSeamOverrides].
Future<void> launchAppFeedback(BuildContext context, WidgetRef ref) async {
  final feedbackState = BetterFeedback.of(context);

  final userFuture = ref.read(userProvider.future);
  final navigation = ref.read(navigationService);
  final feedbackNotifier = ref.read(feedbackProvider.notifier);

  feedbackState.show((feedback) async {
    final userObj = await userFuture.catchError((_) => null);
    final int? userId = _asIntOrNull(userObj?.userId);

    String? currentPath;
    try {
      currentPath = navigation.currentPath.toString();
    } catch (_) {
      currentPath = null;
    }

    final model = FeedbackModel(
      title: feedback.extra?['title']?.toString() ?? '',
      description: feedback.extra?['description']?.toString() ?? feedback.text,
      note: feedback.extra?['note']?.toString() ?? '',
      image: feedback.screenshot,
      isSolved: false,
      user: userId ?? 0,
      problem: _asIntOrNull(feedback.extra?['problem']),
      problemString: feedback.extra?['problem_string']?.toString(),
      responsiblePerson: _asIntOrNull(feedback.extra?['responsible_person']),
      path: currentPath,
      app: feedback.extra?['app']?.toString() ?? 'hously',
      feature: feedback.extra?['feature']?.toString(),
      team: feedback.extra?['team']?.toString(),
      priority: feedback.extra?['priority']?.toString(),
    );

    await feedbackNotifier.sendFeedback(model);
  });
}

/// Installs [launchAppFeedback] into the kernel seam. Spread into every
/// entrypoint's overrides.
final List<Override> feedbackSeamOverrides = [
  feedbackLauncherProvider.overrideWith((ref) => launchAppFeedback),
];
