import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';

class UniversalOfferDropZone extends ConsumerWidget {
  final Widget child;
  final bool enabled;
  final bool showOverlayMessage;

  const UniversalOfferDropZone({
    super.key,
    required this.child,
    this.enabled = true,
    this.showOverlayMessage = true,
  });

  bool get _isDnDSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled || !_isDnDSupported) {
      return child;
    }

    return _OfferDropArea(
      showOverlayMessage: showOverlayMessage,
      child: child,
    );
  }
}

class _OfferDropArea extends ConsumerStatefulWidget {
  final Widget child;
  final bool showOverlayMessage;

  const _OfferDropArea({
    required this.child,
    required this.showOverlayMessage,
  });

  @override
  ConsumerState<_OfferDropArea> createState() => _OfferDropAreaState();
}

class _OfferDropAreaState extends ConsumerState<_OfferDropArea> {
  bool _highlight = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        return DropTarget(
          onDragEntered: (_) {
            if (!mounted) return;
            setState(() => _highlight = true);
          },
          onDragExited: (_) {
            if (!mounted) return;
            setState(() => _highlight = false);
          },
          onDragDone: (details) async {
            if (!mounted) return;
            setState(() => _highlight = false);

            await ref.read(addOfferProvider.notifier).addDroppedXFiles(
                  details.files,
                );
          },
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minHeight,
                  minWidth: double.infinity,
                ),
                child: widget.child,
              ),
              if (_highlight && widget.showOverlayMessage)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withAlpha(90),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(130),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          'Drop files here'.tr,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}