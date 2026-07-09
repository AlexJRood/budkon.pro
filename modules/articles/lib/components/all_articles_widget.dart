import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:articles/article_provider.dart';
import 'package:articles/components/article_card.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/ui/device_type_util.dart';


final showTermsProvider = StateProvider<bool>((ref) => true);

class AllArticlesWidget extends ConsumerWidget {
  final bool isMobile;
  final bool isTablet;
  const AllArticlesWidget({super.key, this.isMobile = false, this.isTablet = false});

@override
Widget build(BuildContext context, WidgetRef ref) {
  final theme = ref.watch(themeColorsProvider);
  final isTerms = ref.watch(showTermsProvider);

  return CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: SizedBox(height: TopAppBarSize.resolve(context))),
      SliverToBoxAdapter(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : isTablet ? 40 : 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildToggleButton(
                label: 'category_selector_label'.tr,
                isActive: isTerms,
                onTap: () => ref.read(showTermsProvider.notifier).state = true,
                theme: theme,
              ),
              const SizedBox(width: 12),
              _buildToggleButton(
                label: 'some_category_label'.tr,
                isActive: !isTerms,
                onTap: () => ref.read(showTermsProvider.notifier).state = false,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),

      if (isTerms)
        _buildArticleGrid(ref, isMobile, context,isTablet)
      else
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : (isTablet ? 50 : 100)),
            child: Text(
              'privacy_policy_text'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
    ],
  );
}

  Widget _buildArticleGrid(WidgetRef ref, bool isMobile, BuildContext context, bool isTablet) {
    final articlesAsync = ref.watch(articleProvider);
    final theme = ref.watch(themeColorsProvider);

    return articlesAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: AppLottie.loading(size: 450),
          ),
        ),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Center(
          child: Text(
            '${'Error'.tr}: $error',
            style: TextStyle(color: theme.textColor),
          ),
        ),
      ),
      data: (articles) {
        final crossAxisCount = isMobile
            ? 1
            :isTablet? 2 : MediaQuery.of(ref.context).size.width > 1200
            ? 4
            : MediaQuery.of(ref.context).size.width > 900
            ? 3
            : 2;

  return SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : (isTablet ? 50 : 70)),
    sliver: SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final data = articles[index];
          return ArticleCardWidget(
            imageUrl: data.thumbnailUrl,
            title: data.title,
            description: data.body,
            readMoreUrl: "#",
            tag: 'articleTag${data.slug}',
            article: data,
          );
        },
        childCount: articles.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isTablet? 0.55 :0.85,
      ),
    ),
  );
      },
    );
  }



  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeColors theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? theme.themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.white : theme.textColor,
          ),
        ),
      ),
    );
  }
}
