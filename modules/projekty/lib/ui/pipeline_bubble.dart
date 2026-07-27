import 'package:core/platform/navigation_service.dart';
import 'package:core/ui/chat_head/bubble_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pipeline_model.dart';
import '../data/providers/pipeline_provider.dart';

const _kBubbleId = 'projekty-pipeline';

/// Wywołaj po kliknięciu "Minimalizuj" na ekranie uploadu.
/// Używa [ProviderSubscription] (nie ref.listen) więc bezpieczne poza build().
void showPipelineBubble(BuildContext context, WidgetRef ref) {
  _PipelineBubbleController(context, ref).start();
}

class _PipelineBubbleController {
  _PipelineBubbleController(this._context, this._ref);

  final BuildContext _context;
  final WidgetRef _ref;
  ProviderSubscription<PipelineState>? _sub;

  void start() {
    // Natychmiast pokaż bąbelek z aktualnym stanem.
    _sync(_ref.read(pipelineProvider));

    // listenManual działa poza build() — bezpieczne w callbackach gestów.
    _sub = _ref.listenManual(
      pipelineProvider,
      (_, next) => _sync(next),
    );
  }

  void _sync(PipelineState state) {
    if (!_context.mounted) {
      _sub?.close();
      return;
    }

    // Ukryj gdy pipeline zakończony, błąd lub brak aktywnego.
    if (!state.isActive && !state.isUploading) {
      BubbleStack.instance.hide(_kBubbleId);
      _sub?.close();
      return;
    }

    final currentIdx = state.status != null
        ? pipelineStepIndex(state.status!.currentStep)
        : 0;
    final progress  = (currentIdx + 1) / pipelineSteps.length;
    final stepLabel = state.isUploading
        ? 'Przesyłanie…'
        : pipelineSteps[currentIdx].$2;

    BubbleStack.instance.show(
      context: _context,
      spec: MinimizedBubbleSpec(
        id:       _kBubbleId,
        label:    stepLabel,
        color:    const Color(0xFFB71C1C),
        icon:     Icons.architecture,
        progress: state.isUploading ? null : progress,
        topBound: 80,
        onExpand: () {
          BubbleStack.instance.hide(_kBubbleId);
          _ref.read(navigationService).pushNamedScreen('/projekty/upload');
        },
        onClose: () {
          BubbleStack.instance.hide(_kBubbleId);
          _sub?.close();
          // Pipeline działa dalej na serwerze — tu tylko chowamy UI.
        },
      ),
    );
  }
}
