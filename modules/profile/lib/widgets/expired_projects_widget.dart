import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profile/models/dummy_data.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:core/theme/apptheme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/models/ad_list_view_model.dart';

class ExpiredProjectsWidgetSliver extends ConsumerWidget {
  final int grid;

  const ExpiredProjectsWidgetSliver({super.key, required this.grid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final expiredAds = dummyAdsData.skip(8).take(4).toList();

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: grid,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final ad = expiredAds[index];
          return SelectedCardWidget(
            ad: ad,
            tag: 'expired-project-${ad.id}',
            mainImageUrl: ad.images.isNotEmpty ? ad.images.first : '',
            isPro: ad.isPro,
            isDefaultDarkSystem: Theme.of(context).brightness == Brightness.dark,
            color: theme.sideBarbackground,
            textColor: theme.textColor,
            textFieldColor: theme.textFieldColor,
            buildShimmerPlaceholder: _buildShimmerPlaceholder(theme),
            buildPieMenuActions: _buildPieMenuActions(ref, ad, context),
            aspectRatio: 0.8,
            isMobile: MediaQuery.of(context).size.width < 600,
          );
        },
        childCount: expiredAds.length,
      ),
    );
  }

  List<PieAction> _buildPieMenuActions(
    WidgetRef ref,
    AdsListViewModel ad,
    BuildContext context,
  ) {
    return [
      PieAction(
        tooltip: const Text("hello"),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.solidHeart),
      ),
      PieAction(
        tooltip: Text('Dodaj do listy przeglądania'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.list),
      ),
      PieAction(
        tooltip: Text('Ukryj ogłoszenie'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.eyeSlash),
      ),
      PieAction(
        tooltip: Text('Udostępnij ogłoszenie'.tr),
        onSelect: () {},
        child: const FaIcon(FontAwesomeIcons.shareNodes),
      ),
    ];
  }

  Widget _buildShimmerPlaceholder(ThemeColors theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(76),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.home, size: 48, color: theme.textColor.withAlpha(128)),
      ),
    );
  }
}
