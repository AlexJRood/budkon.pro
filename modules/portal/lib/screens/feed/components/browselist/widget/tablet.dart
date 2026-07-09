import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/components/browselist/utils/api.dart';

import '../components/button.dart';
import '../components/list.dart';

/// Tablet-sized browse-list panel (800 – 1 200 px).
///
/// Features a narrower design than the PC version to conserve grid space:
/// • Width: 56 px (collapsed/peek) and 180 px (expanded).
class BrowseListTabletWidget extends StatefulWidget {
  final bool isWhiteSpaceNeeded;
  const BrowseListTabletWidget({super.key, required this.isWhiteSpaceNeeded});

  @override
  _BrowseListTabletWidgetState createState() => _BrowseListTabletWidgetState();
}

class _BrowseListTabletWidgetState extends State<BrowseListTabletWidget> {
  bool _isHidden = true;

  void _toggleWidget() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  Future<void> _handleDrop(DndPayload payload) async {
    if (payload.type != DndPayloadType.advertisement) return;

    final adId = int.tryParse(payload.id);
    if (adId == null) return;

    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(browseListProvider.notifier).addToBrowseLists(adId);
    await container
        .read(browseListProvider.notifier)
        .applyFilters(container);

    if (!mounted) return;
    context.showSnackBarSafe('added_to_browse_list'.tr);
  }

  @override
  Widget build(BuildContext context) {
    const double fullWidth = 260.0;
    const double peekWidth = 56.0;
    final double containerWidth = _isHidden ? peekWidth : fullWidth;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: containerWidth,
      child: Stack(
        children: [
          Positioned.fill(
            child: BrowseListWidget(
              isWhiteSpaceNeeded: widget.isWhiteSpaceNeeded,
              isHidden: _isHidden,
            ),
          ),
          Positioned(
            top: widget.isWhiteSpaceNeeded ? 58 : 0,
            right: 0,
            left: 0,
            child: BrowseListButtonBarWidget(
              isHidden: _isHidden,
              toggleIsHidden: _toggleWidget,
            ),
          ),
          Positioned(
            bottom: 10,
            left: _isHidden ? 2 : 8,
            right: _isHidden ? 2 : 12,
            child: BrowseListActionsWidget(
              isHidden: _isHidden,
              toggleIsHidden: _toggleWidget,
            ),
          ),
        ],
      ),
    );

    return DndReceiver(
      targets: const [DndTargetType.browseListPortal],
      showHoverFeedback: false,
      showSnackbar: false,
      onDrop: (payload) async {
        await _handleDrop(payload);
      },
      builder: (context, hoveringPayload, isHovering, canAcceptDrop, child) {
        final showAccept = isHovering &&
            hoveringPayload?.type == DndPayloadType.advertisement &&
            canAcceptDrop;
        final showReject =
            isHovering && hoveringPayload != null && !showAccept;

        Color borderColor = Colors.transparent;
        Color fillColor = Colors.transparent;

        if (showAccept) {
          borderColor = Colors.green.shade400;
          fillColor = Colors.green.withValues(alpha: 0.06);
        } else if (showReject) {
          borderColor = Colors.red.shade400;
          fillColor = Colors.red.withValues(alpha: 0.06);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor.a == 0
                ? null
                : Border.all(color: borderColor, width: 2),
            color: fillColor,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      child: content,
    );
  }
}
