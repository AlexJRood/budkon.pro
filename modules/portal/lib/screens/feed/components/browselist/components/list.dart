import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:portal/browselist/components/card.dart';
import 'package:portal/screens/feed/components/browselist/utils/api.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';

class BrowseListWidget extends ConsumerStatefulWidget {
  final bool isWhiteSpaceNeeded;
  final bool isHidden;
  final bool isMobile;

  const BrowseListWidget({
    super.key,
    required this.isWhiteSpaceNeeded,
    required this.isHidden,
    this.isMobile = false,
  });

  @override
  ConsumerState<BrowseListWidget> createState() => _BrowseListWidgetState();
}

class _BrowseListWidgetState extends ConsumerState<BrowseListWidget> {
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  List<T> _dedupeById<T>(
    List<T> items,
    Object? Function(T item) idGetter,
  ) {
    final seen = <Object?>{};
    final result = <T>[];

    for (final item in items) {
      final id = idGetter(item);

      if (id == null) {
        result.add(item);
        continue;
      }

      if (seen.add(id)) {
        result.add(item);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final customFormat = NumberFormat.decimalPattern('fr');

    const double maxWidth = 1920;
    const double minWidth = 1080;

    const double minBaseTextSize = 5;
    const double maxBaseTextSize = 15;

    double baseTextSize =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxBaseTextSize - minBaseTextSize) +
        minBaseTextSize;

    baseTextSize = baseTextSize.clamp(minBaseTextSize, maxBaseTextSize);

    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          slivers: [
            widget.isWhiteSpaceNeeded
                ? const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  )
                : const SliverToBoxAdapter(
                    child: SizedBox(height: 60),
                  ),
            ref.watch(browseListProvider).when(
                  data: (filteredAdvertisements) {
                    final uniqueAdvertisements = _dedupeById(
                      filteredAdvertisements,
                      (ad) => ad.id,
                    );

                    if (uniqueAdvertisements.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Center(child: AppLottie.fileSearch(size: 250)),
                          ],
                        ),
                      );
                    }

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: widget.isMobile ? 3 : 2,
                        mainAxisSpacing: widget.isMobile ? 0 : 5,
                        crossAxisSpacing: widget.isMobile ? 0 : 5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final feedAd = uniqueAdvertisements[index];
                          final adId = feedAd.id ?? 'no_id_$index';

                          final keyTag = 'browselist_portal_${adId}_$index';
                          final formattedPrice =
                              customFormat.format(feedAd.price);

                          final mainImageUrl = feedAd.images.isNotEmpty
                              ? feedAd.images.first
                              : 'default_image_url';

                          return HeroMode(
                            enabled: false,
                            child: PortalBrowseListCardWidget(
                              key: ValueKey('browselist_card_${adId}_$index'),
                              isHidden: widget.isHidden,
                              feedAd: feedAd,
                              isMobile: widget.isMobile,
                              keyTag: keyTag,
                              mainImageUrl: mainImageUrl,
                              formattedPrice: formattedPrice,
                            ),
                          );
                        },
                        childCount: uniqueAdvertisements.length,
                      ),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    child: Center(child: AppLottie.loading(size: 350)),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: Center(
                      child: Text(
                        '${'An error occurred'.tr}: $error'.tr,
                        style: AppTextStyles.interLight,
                      ),
                    ),
                  ),
                ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 65),
            ),
          ],
        ),
      ],
    );
  }
}