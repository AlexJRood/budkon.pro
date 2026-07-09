import 'package:crm/draft/components/filters.dart';
import 'package:crm/draft/filter_model.dart';
import 'package:crm/draft/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/components/cards/va_list.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class DraftAdvertisementsList extends ConsumerStatefulWidget {
  const DraftAdvertisementsList({super.key});

  @override
  ConsumerState<DraftAdvertisementsList> createState() =>
      _DraftAdvertisementsListState();
}

class _DraftAdvertisementsListState
    extends ConsumerState<DraftAdvertisementsList> {
  int _currentPage = 1;

  void _showFilterDialog(BuildContext context) async {
    final filter = ref.read(draftFilterProvider);

    final result = await showDialog<DraftAdFilter>(
      context: context,
      builder: (context) => DraftAdFilterDialog(
        initial: filter,
        onApply: (newFilter) => Navigator.of(context).pop(newFilter),
      ),
    );

    if (result != null) {
      ref.read(draftFilterProvider.notifier).state = result;
      setState(() => _currentPage = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(draftAdvertsProvider(_currentPage));
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.read(navigationService);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.filter_alt_outlined, color: theme.textColor),
              label: Text(
                "filter".tr,
                style: TextStyle(color: theme.textColor),
              ),
              onPressed: () => _showFilterDialog(context),
            ),
            if (!isMobile) const Spacer(),
            IconButton(
              icon: Icon(Icons.chevron_left, color: theme.textColor),
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
            Text(
              "${'page_label'.tr} $_currentPage",
              style: TextStyle(color: theme.textColor),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: theme.textColor),
              onPressed: () => setState(() => _currentPage++),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: draftsAsync.when(
            data: (drafts) {
              if (drafts.isEmpty) {
                return Center(child: AppLottie.noResults(size: 450));
              }

              return ListView.builder(
                addAutomaticKeepAlives: false,
                cacheExtent: 300,
                itemCount: drafts.length,
                itemBuilder: (context, idx) {
                  final ad = drafts[idx];

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : screenWidth / 6,
                      vertical: 8,
                    ),
                    child: VictoriaNAlexCardWidgetList(
                      ad: ad,
                      tag: 'draft_${ad.id}_$idx',
                      mainImageUrl: ad.mainImageUrl ?? '',
                      isPro: true,
                      isDefaultDarkSystem: true,
                      color: Colors.amber,
                      textColor: Colors.red,
                      textFieldColor: Colors.blue,
                      buildShimmerPlaceholder: const Text(
                        'test',
                        style: TextStyle(color: Colors.yellow),
                      ),
                      buildPieMenuActions: buildPieMenuActions(
                        ref,
                        ad,
                        context,
                      ),
                      aspectRatio: 8,
                      isMobile: isMobile,
                      isDraft: true,
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: AppLottie.loading(size: 450)),
            error: (err, _) => Center(
              child: Text(
                '${'Error'.tr} $err',
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}