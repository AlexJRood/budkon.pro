import 'package:core/platform/navigation_service.dart';
import 'package:core/ui/chat_head/bubble_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pipeline_model.dart';
import '../data/providers/pipeline_provider.dart';

const _kBubbleId = 'projekty-pipeline';

/// Uruchom bąbelek po minimalizacji ekranu uploadu.
/// Przekaż [context] z ekranu — używany tylko do zakotwiczenia overlay.
void showPipelineBubble(BuildContext context, WidgetRef ref) {
  _PipelineBubbleController(ref).attach(context);
}

class _PipelineBubbleController {
  _PipelineBubbleController(this._ref);

  final WidgetRef _ref;
  BuildContext? _ctx;

  void attach(BuildContext context) {
    _ctx = context;
    // Nasłuchuj zmian stanu pipeline i aktualizuj bąbelek.
    _ref.listen(pipelineProvider, (_, next) => _sync(next));
    _sync(_ref.read(pipelineProvider));
  }

  void _sync(PipelineState state) {
    final ctx = _ctx;
    if (ctx == null || !ctx.mounted) return;

    // Ukryj bąbelek gdy pipeline zakończony lub nie ma aktywnego.
    if (!state.isActive && !state.isUploading) {
      BubbleStack.instance.hide(_kBubbleId);
      return;
    }

    final currentIdx  = state.status != null
        ? pipelineStepIndex(state.status!.currentStep)
        : 0;
    final progress    = (currentIdx + 1) / pipelineSteps.length;
    final stepLabel   = state.isUploading
        ? 'Przesyłanie…'
        : pipelineSteps[currentIdx].$2;

    BubbleStack.instance.show(
      context: ctx,
      spec: MinimizedBubbleSpec(
        id:          _kBubbleId,
        label:       stepLabel,
        color:       const Color(0xFFB71C1C),
        icon:        Icons.architecture,
        progress:    state.isUploading ? null : progress,
        topBound:    80,
        onExpand: () {
          BubbleStack.instance.hide(_kBubbleId);
          _ref.read(navigationService).pushNamedScreen('/projekty/upload');
        },
        onClose: () {
          BubbleStack.instance.hide(_kBubbleId);
          // Nie anulujemy pipeline — działa w tle na serwerze.
        },
      ),
    );
  }
}

// ── Provider globalny (autoDispose = false — żyje przez całą sesję) ───────────

/// Możesz wywołać [pipelineBubbleProvider] w dowolnym miejscu aplikacji żeby
/// zarejestrować nasłuchiwanie — bąbelek pojawi się automatycznie gdy pipeline
/// jest aktywny (np. po powrocie do listy projektów).
final pipelineBubbleProvider = Provider<_PipelineBubbleWatcher>((ref) {
  return _PipelineBubbleWatcher(ref);
});

class _PipelineBubbleWatcher {
  _PipelineBubbleWatcher(this._ref);
  final Ref _ref;

  void watchFrom(BuildContext context) {
    _ref.listen(pipelineProvider, (_, next) {
      if (!context.mounted) return;
      showPipelineBubble(context, _ref as WidgetRef);
    });
  }
}
