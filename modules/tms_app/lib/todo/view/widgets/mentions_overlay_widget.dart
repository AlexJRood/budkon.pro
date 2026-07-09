import 'package:flutter/material.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/provider/mentions_provider.dart';

class MentionsOverlay extends StatelessWidget {
  final LayerLink link;
  final double width;
  final dynamic theme;
  final MentionState state;
  final ScrollController scrollController;
  final ValueChanged<int> onHoverIndex;
  final void Function(dynamic item) onTapItem;

  const MentionsOverlay({
    super.key,
    required this.link,
    required this.width,
    required this.theme,
    required this.state,
    required this.scrollController,
    required this.onHoverIndex,
    required this.onTapItem,
  });

  static const double _maxPopupHeight = 250;
  static const double _rowHeight = 36;

  @override
  Widget build(BuildContext context) {
    if (!state.open) return const SizedBox.shrink();

    final desiredHeight =
        (state.items.isEmpty ? 3 : state.items.length) * _rowHeight + 8;
    final popupHeight = desiredHeight.clamp(56, _maxPopupHeight).toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final viewExtent = popupHeight;
      final targetTop = state.activeIndex * _rowHeight;
      final targetBottom = targetTop + _rowHeight;

      final current = scrollController.offset;
      final visibleTop = current;
      final visibleBottom = current + viewExtent;

      double newOffset = current;
      if (targetTop < visibleTop) {
        newOffset = targetTop;
      } else if (targetBottom > visibleBottom) {
        newOffset = targetBottom - viewExtent;
      }
      newOffset = newOffset.clamp(
        scrollController.position.minScrollExtent,
        scrollController.position.maxScrollExtent,
      );
      if ((newOffset - current).abs() > 1) {
        scrollController.jumpTo(newOffset);
      }
    });

    return CompositedTransformFollower(
      link: link,
      showWhenUnlinked: false,
      offset: const Offset(0, 40),
      child: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: popupHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.textFieldColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.textColor.withAlpha((255 * 0.35).toInt()),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (state.loading) {
      return  Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: Center(child: AppLottie.loading()),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          'No results',
          style: TextStyle(color: theme.textColor, fontSize: 13),
        ),
      );
    }

    final isMembers = state.mode == MentionMode.members;

    return ListView.builder(
      addAutomaticKeepAlives: false,
      cacheExtent: 300.0,
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      physics: const ClampingScrollPhysics(),
      itemCount: state.items.length,
      itemExtent: _rowHeight,
      itemBuilder: (context, i) {
        final item = state.items[i];
        final display =
            isMembers
                ? MentionController.memberName(item)
                : MentionController.clientName(item);

        final highlighted = i == state.activeIndex;

        return MouseRegion(
          onEnter: (_) => onHoverIndex(i),
          child: InkWell(
            onTap: () => onTapItem(item),
            child: Container(
              color:
                  highlighted
                      ? theme.dashboardContainer.withAlpha(128)
                      : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: theme.dashboardBoarder,
                    child: Text(
                      (display.isNotEmpty ? display[0] : '?').toUpperCase(),
                      style: TextStyle(fontSize: 11, color: theme.textColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 13,
                        fontWeight:
                            highlighted ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          highlighted
                              ? theme.themeColor.withAlpha(38)
                              : theme.dashboardContainer,
                    ),
                    child: Text(
                      isMembers ? '@@' : '@',
                      style: TextStyle(fontSize: 10, color: theme.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
