import 'package:crm/pie_menu/clients_pro.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../components/button.dart';
import '../components/list.dart';
import '../utils/api.dart';

class BrowseListNetworkMonitoringPcWidget extends StatefulWidget {
  final bool isWhiteSpaceNeeded;
  final int? transactionId;
  final int? clientId;
  final bool isMobile;
  final ScrollController? sheetScrollController;

  const BrowseListNetworkMonitoringPcWidget({
    super.key,
    required this.isWhiteSpaceNeeded,
    this.transactionId,
    this.clientId,
    this.sheetScrollController,
    this.isMobile = false,
  });

  @override
  _BrowseListNetworkMonitoringPcWidgetState createState() =>
      _BrowseListNetworkMonitoringPcWidgetState();
}

class _BrowseListNetworkMonitoringPcWidgetState
    extends State<BrowseListNetworkMonitoringPcWidget> {
  bool _isHidden = true;

  void _toggleWidget() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  Future<void> _handleDrop(DndPayload payload) async {
    if (payload.type != DndPayloadType.nm_ad) return;

    final adId = int.tryParse(payload.id);
    if (adId == null) return;

    final scope = BrowseScope(
      transactionId: widget.transactionId,
      clientId: widget.clientId,
    );

    await ProviderScope.containerOf(context, listen: false)
        .read(networkMonitoringBrowseListProvider(scope).notifier)
        .addToBrowseListsNMNM(
          adId,
          widget.transactionId,
          widget.clientId,
        );

    await ProviderScope.containerOf(context, listen: false)
        .read(networkMonitoringBrowseListProvider(scope).notifier)
        .applyFilters(
          ProviderScope.containerOf(context, listen: false),
        );

    if (!mounted) return;
    context.showSnackBarLikeSection('Added to viewing list'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    const double maxWidth = 2800;
    const double minWidth = 1080;
    const double maxbrowseListWidth = 450;
    const double minbrowseListWidth = 180;

    double browseListWidth = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxbrowseListWidth - minbrowseListWidth) +
        minbrowseListWidth;

    browseListWidth =
        browseListWidth.clamp(minbrowseListWidth, maxbrowseListWidth);

    const double peekWidth = 80;
    final double containerWidth = _isHidden ? peekWidth : browseListWidth;

    final content = widget.isMobile
        ? Stack(
            children: [
              Positioned.fill(
                child: BrowseListWidgetNM(
                  disableHero: true,
                  isWhiteSpaceNeeded: widget.isWhiteSpaceNeeded,
                  isHidden: false,
                  transactionId: widget.transactionId,
                  sheetScrollController: widget.sheetScrollController,
                  clientId: widget.clientId,
                  isMobile: widget.isMobile,
                ),
              ),
              Positioned(
                bottom: 5,
                right: 20,
                left: 20,
                child: BrowseListActionsWidget(
                  isHidden: false,
                  toggleIsHidden: _toggleWidget,
                  transactionId: widget.transactionId,
                  clientId: widget.clientId,
                ),
              ),
            ],
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: containerWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BrowseListWidgetNM(
                    isWhiteSpaceNeeded: widget.isWhiteSpaceNeeded,
                    isHidden: _isHidden,
                    transactionId: widget.transactionId,
                    clientId: widget.clientId,
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
                  right: 20,
                  left: 10,
                  child: BrowseListActionsWidget(
                    isHidden: _isHidden,
                    toggleIsHidden: _toggleWidget,
                    transactionId: widget.transactionId,
                    clientId: widget.clientId,
                  ),
                ),
              ],
            ),
          );

    return DndReceiver(
      targets: const [DndTargetType.browseListNm],
      showHoverFeedback: false,
      showSnackbar: false,
      onDrop: (payload) async {
        await _handleDrop(payload);
      },
      builder: (
        context,
        hoveringPayload,
        isHovering,
        canAcceptDrop,
        child,
      ) {
        final showAccept = isHovering &&
            hoveringPayload?.type == DndPayloadType.nm_ad &&
            canAcceptDrop;

        final showReject =
            isHovering && hoveringPayload != null && !showAccept;

        Color borderColor = Colors.transparent;
        Color fillColor = Colors.transparent;

        if (showAccept) {
          borderColor = Colors.green.shade400;
          fillColor = Colors.green.withOpacity(0.06);
        } else if (showReject) {
          borderColor = Colors.red.shade400;
          fillColor = Colors.red.withOpacity(0.06);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.isMobile ? 0 : 12),
            border: borderColor.opacity == 0
                ? null
                : Border.all(
                    color: borderColor,
                    width: 2,
                  ),
            color: fillColor,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      child: content,
    );
  }
}