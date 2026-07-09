import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/articles_pop_page/providers/article_provider.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:articles/components/article_card.dart';
import 'package:get/get_utils/get_utils.dart';

class FeaturedNewsWidget extends ConsumerStatefulWidget {
  final double paddingDynamic;
  final bool isMobile;
  const FeaturedNewsWidget({
    super.key,
    required this.paddingDynamic,
    this.isMobile = false,
  });

  @override
  ConsumerState<FeaturedNewsWidget> createState() => _FeaturedNewsWidgetState();
}

class _FeaturedNewsWidgetState extends ConsumerState<FeaturedNewsWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicVerticalPadding = widget.paddingDynamic / 3;
    final theme = ref.read(themeColorsProvider);
    final nav = ref.read(navigationService);
    final articlesAsync = ref.watch(articleProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = widget.isMobile
        ? (screenWidth * 0.7).clamp(220.0, 280.0)
        : max(150.0, min(screenWidth / 1500 * 240, 250.0));
    final itemHeight = itemWidth * (300 / 260);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dynamicVerticalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.paddingDynamic),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Featured News & Insights for New Homes'.tr,
                    style: TextStyle(
                      fontSize:widget.isMobile?16:24,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
                if (!widget.isMobile)
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            nav.pushNamedScreen(Routes.articlePage);
                          },
                          style: elevatedButtonStyleRounded10,
                          child: Row(
                            children: [
                              Text(
                                'Read all articles'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textColor,
                                ),
                              ),
                              AppIcons.iosArrowRight(color: theme.textColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          SizedBox(
            height: 555,
            child: articlesAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.only(left: widget.paddingDynamic),
                child: ShimmerLoadingRow(
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  placeholderwidget: ShimmerPlaceholder(
                    width: itemWidth,
                    height: itemHeight,
                  ),
                ),
              ),
              error: (error, stackTrace) {
                final screenWidth = MediaQuery.of(context).size.width;

               final itemWidth = widget.isMobile
                     ? screenWidth * 0.78
                     : max(150.0, min(screenWidth / 1500 * 240, 250.0));

               final itemHeight = widget.isMobile 
                     ? itemWidth * 0.75 
                     : itemWidth * (300 / 260);
                return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: widget.paddingDynamic),
              
                    SizedBox(
                        width: widget.isMobile ? screenWidth - 32 : itemWidth * 5,
                        height: itemHeight,
                      child: Stack(
                        children: [
                          Shimmer.fromColors(
                            baseColor: ShimmerColors.base(context),
                            highlightColor: ShimmerColors.highlight(context),
                            child: Container(
                              width: double.infinity,
                              height: itemHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: ShimmerColors.background(context),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    (error is String)
                                        ? error
                                        :"Something Went Wrong".tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              
                    SizedBox(width: widget.paddingDynamic),
                  ],
                ),
              );
              },
              data: (articles) {
                if (articles.isEmpty) {
                  return Center(
                    child: Text(
                      'no_articles_to_display'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  );
                }
                return Padding(
                  padding:  EdgeInsets.only(right: widget.paddingDynamic),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 505,
                        child: DragScrollView(
                          controller: _scrollController,
                          child: ListView.separated(
                            controller: _scrollController,
                            separatorBuilder:
                                (context, index) =>
                                    index == 0
                                        ? const SizedBox(width: 0)
                                        : const SizedBox(width: 30),
                            itemCount: articles.length + 2, // Paddingy
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              if (index == 0 || index == articles.length + 1) {
                                return SizedBox(width: widget.paddingDynamic);
                              }
                              final data = articles[index - 1];
                              return SizedBox(
                                height: itemHeight,
                                width: itemWidth,
                                child: ArticleCardWidget(
                                  imageUrl: data.thumbnailUrl,
                                  title: data.title,
                                  description: data.body,
                                  readMoreUrl: '#',
                                  tag: 'articleTag${data.slug}landingpage',
                                  article: data,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                if (widget.isMobile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            nav.pushNamedScreen(Routes.articlePage);
                          },
                          style: elevatedButtonStyleRounded10,
                          child: Row(
                            children: [
                              Text(
                                'Read all articles'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textColor,
                                ),
                              ),
                              AppIcons.iosArrowRight(color: theme.textColor),
                            ],
                          ),
                        ),
                      ),
                    ],),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
