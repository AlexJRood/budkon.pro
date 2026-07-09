import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/articles_pop_page/providers/article_provider.dart';
import 'package:core/common/loading_widgets.dart';

class ArticlesHomepage extends ConsumerWidget {
  const ArticlesHomepage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsyncValue = ref.watch(articleProvider);
    double screenHeight = MediaQuery.of(context).size.height;
    const double maxHeight = 1080;
    const double minHeight = 300;
    const double maxDynamicPadding = 40;
    const double minDynamicPadding = 5;
    double dynamicPadding = (screenHeight - minHeight) /
            (maxHeight - minHeight) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);

    double articleHeight = screenHeight / 2;
    double articleWidth = articleHeight * 0.8;
    final themecolors = ref.watch(themeColorsProvider);

    final textColor = themecolors.themeTextColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('articles'.tr,
              style: AppTextStyles.interSemiBold18.copyWith(color: textColor)),
        ),
        const SizedBox(height: 20),
        articlesAsyncValue.when(
          data: (articles) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: articles.map((articles) {
                final tagArticlesPop = UniqueKey().toString();
                return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Hero(
                          tag: tagArticlesPop,
                          child: SizedBox(
                            height: articleHeight,
                            width: articleWidth,
                            child: CachedNetworkImage(
                              imageUrl: articles.thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => ShimmerPlaceholder(
                                  width: articleWidth, height: articleHeight),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: articleWidth,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(articles.title,
                                style: AppTextStyles.interSemiBold18,
                                maxLines: 4),
                            const SizedBox(height: 15),
                            Text(articles.body,
                                style: AppTextStyles.interLight, maxLines: 5),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                );
              }).toList(),
            ),
          ),
          error: (err, _) => Stack(
            children: [
              // Shimmer placeholder as the background
              Positioned.fill(
                child: ShimmerPlaceholder(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Centered "No article found".tr message
              Center(
                child: Text(
                  "No article found".tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          loading: () => SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                5, 
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    children: [
                      ShimmerPlaceholder(
                        width: articleWidth,
                        height: articleHeight,
                      ),
                      SizedBox(
                        width: articleWidth,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            ShimmerPlaceholder(
                              width: articleWidth *
                                  0.8, // Adjust width for text placeholder
                              height: 20, // Height for title shimmer
                            ),
                            const SizedBox(height: 15),
                            ShimmerPlaceholder(
                              width: articleWidth *
                                  0.9, // Adjust width for body text
                              height: 15, // Height for body shimmer
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}



