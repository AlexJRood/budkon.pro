import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:intl/intl.dart';
import 'package:get/get_utils/get_utils.dart';

import '../utils/api.dart';
import 'card.dart';

class BrowseListWidgetNM extends ConsumerStatefulWidget {
  final bool isWhiteSpaceNeeded;
  final bool isHidden;
  final int? transactionId;
  final int? clientId;
  final bool isMobile;
  final ScrollController? sheetScrollController;
  final bool disableHero;

  const BrowseListWidgetNM({
    super.key,
    this.isMobile = false,
    this.disableHero = false,
    required this.isWhiteSpaceNeeded,
    required this.isHidden,
    this.sheetScrollController,
    this.transactionId,
    this.clientId,
  });

  @override
  _BrowseListWidgetNMState createState() => _BrowseListWidgetNMState();
}

class _BrowseListWidgetNMState extends ConsumerState<BrowseListWidgetNM> {
  late final ScrollController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.sheetScrollController != null) {
      _controller = widget.sheetScrollController!;
      _ownsController = false;
    } else {
      _controller = ScrollController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final customFormat = NumberFormat.decimalPattern('fr');

    const double maxWidth = 1920;
    const double minWidth = 1080;
    const double minBaseTextSize = 5;
    const double maxBaseTextSize = 15;

    double baseTextSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxBaseTextSize - minBaseTextSize) +
        minBaseTextSize;

    baseTextSize = baseTextSize.clamp(minBaseTextSize, maxBaseTextSize);

    final theme = ref.watch(themeColorsProvider);
    final scope = BrowseScope(
      transactionId: widget.transactionId,
      clientId: widget.clientId,
    );

    return Container(
      decoration: widget.isMobile
          ? const BoxDecoration()
          : BoxDecoration(
              gradient: CustomBackgroundGradients.getMainMenuBackground(
                context,
                ref,
              ),
            ),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        thickness: 4,
        radius: const Radius.circular(8.0),
        child: CustomScrollView(
          controller: _controller,
          primary: false,
          slivers: [
            widget.isWhiteSpaceNeeded
                ? const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  )
                : SliverToBoxAdapter(
                    child: SizedBox(height: widget.isMobile ? 0 : 60),
                  ),
            ref.watch(networkMonitoringBrowseListProvider(scope)).when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: AppLottie.noResults(size: 450),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 2,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final feedAd = items[index];
                      final keyTag = 'browselist_nm${feedAd.id}';
                      final formattedPrice = (feedAd.price == null)
                          ? ' - '
                          : customFormat.format(feedAd.price);
                      final mainImageUrl = (feedAd.images?.isNotEmpty ?? false)
                          ? feedAd.images!.first
                          : 'default_image_url';

                      return BrowseListCardWidget(
                        disableHero: widget.disableHero,
                        isHidden: widget.isHidden,
                        ad: feedAd,
                        keyTag: keyTag,
                        mainImageUrl: mainImageUrl,
                        formattedPrice: formattedPrice,
                        transactionId: widget.transactionId,
                        clientId: widget.clientId,
                      );
                    },
                    childCount: items.length,
                  ),
                );
              },
              loading: () => SliverFillRemaining(
                child: Center(
                  child: AppLottie.loading(size: 350),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    '${'An error occurred'.tr}: $error',
                    style: AppTextStyles.interLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}