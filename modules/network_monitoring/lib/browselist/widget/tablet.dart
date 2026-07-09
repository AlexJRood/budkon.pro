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

/// Tablet-sized browse-list panel (800 – 1 200 px).
///
/// Differences from [BrowseListNetworkMonitoringPcWidget]:
/// • Default width is narrower (fixed 200 px collapsed / 280 px expanded)
///   so it doesn't steal too much space from the grid on an 800 px screen.
/// • The tab opens/collapses the same way as the PC version.
class BrowseListNetworkMonitoringTabletWidget extends StatefulWidget {
  final bool isWhiteSpaceNeeded;
  final int? transactionId;
  final int? clientId;
  final ScrollController? sheetScrollController;

  const BrowseListNetworkMonitoringTabletWidget({
    super.key,
    required this.isWhiteSpaceNeeded,
    this.transactionId,
    this.clientId,
    this.sheetScrollController,
  });

  @override
  _BrowseListNetworkMonitoringTabletWidgetState createState() =>
      _BrowseListNetworkMonitoringTabletWidgetState();
}

class _BrowseListNetworkMonitoringTabletWidgetState
    extends State<BrowseListNetworkMonitoringTabletWidget> {
  // Start collapsed on tablet to maximise grid real estate.
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
        .addToBrowseListsNMNM(adId, widget.transactionId, widget.clientId);

    await ProviderScope.containerOf(context, listen: false)
        .read(networkMonitoringBrowseListProvider(scope).notifier)
        .applyFilters(ProviderScope.containerOf(context, listen: false));

    if (!mounted) return;
    context.showSnackBarLikeSection('Added to viewing list'.tr);
  }

  @override
  Widget build(BuildContext context) {
    // Tablet uses a fixed narrow width — narrower than PC to save grid space.
    const double fullWidth = 180.0;
    const double peekWidth = 56.0;
    final double containerWidth = _isHidden ? peekWidth : fullWidth;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
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
            left: _isHidden ? 2 : 8,
            right: _isHidden ? 2 : 12,
            child: BrowseListActionsWidget(
              isHidden: _isHidden,
              toggleIsHidden: _toggleWidget,
              transactionId: widget.transactionId,
              clientId: widget.clientId,
              isTablet: true,
            ),
          ),
        ],
      ),
    );

    return DndReceiver(
      targets: [DndTargetType.browseListNm],
      showHoverFeedback: false,
      showSnackbar: false,
      onDrop: (payload) async {
        await _handleDrop(payload);
      },
      child: content,
    );
  }
}
