import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/theme/lottie.dart';
import 'package:profile/providers/profile_ads_provider.dart';
import 'package:core/user/user/user_provider.dart';

class AllWidgetSliver extends ConsumerStatefulWidget {
  final int grid;
  final UserModel? profile;

  const AllWidgetSliver({super.key, required this.grid, this.profile});

  @override
  ConsumerState<AllWidgetSliver> createState() => _AllWidgetSliverState();
}

class _AllWidgetSliverState extends ConsumerState<AllWidgetSliver> {
  static const int _pageSize = 10;
  final PagingController<int, AdsListViewModel> _pagingController =
      PagingController(firstPageKey: 1);
 bool _disposed = false;
  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_disposed) return;
    try {
      final profileState = ref.read(userStateProvider);
      final userId = widget.profile?.userId ?? profileState?.userId;

      if (userId == null) {
        _pagingController.error = Exception(
          'User profile not available. Please log in to view your ads.',
        );
        return;
      }

      final advertisements = await ref
          .read(profileAdsProvider.notifier)
          .fetchUserAdvertisements(pageKey, _pageSize, int.tryParse(userId ?? '') ?? 0, ref);
 if (_disposed) return;          
      final isLastPage = advertisements.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(advertisements);
      } else {
        _pagingController.appendPage(advertisements, pageKey + 1);
      }
    } catch (error) {
      if (_disposed) return;
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
     _disposed = true; 
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return PagedSliverGrid<int, AdsListViewModel>(
      pagingController: _pagingController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.grid,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      builderDelegate: PagedChildBuilderDelegate<AdsListViewModel>(
        itemBuilder: (context, ad, index) {
          return SelectedCardWidget(
            ad: ad,
            tag: 'all-project-${ad.id}',
            mainImageUrl: ad.images.isNotEmpty ? ad.images.first : '',
            isPro: ad.isPro,
            isDefaultDarkSystem:
                Theme.of(context).brightness == Brightness.dark,
            color: theme.sideBarbackground,
            textColor: theme.textColor,
            textFieldColor: theme.textFieldColor,
            buildShimmerPlaceholder: _buildShimmerPlaceholder(theme),
            buildPieMenuActions: _buildPieMenuActions(ref, ad, context),
            aspectRatio: 0.8,
            isMobile: MediaQuery.of(context).size.width < 600,
          );
        },
        firstPageProgressIndicatorBuilder:
            (_) => Center(child: AppLottie.loading(size: 120)),
        newPageProgressIndicatorBuilder:
            (_) => Center(child: AppLottie.loading(size: 120)),
        noItemsFoundIndicatorBuilder:
            (_) => Center(child: AppLottie.noResults(size: 200)),
        firstPageErrorIndicatorBuilder:
            (_) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.textColor.withAlpha(153),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load all projects',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(204),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _pagingController.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
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
        child: Icon(
          Icons.home,
          size: 48,
          color: theme.textColor.withAlpha(128),
        ),
      ),
    );
  }
}
