import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:articles/articles_pop_page/article_pop_full.dart';
import 'package:articles/articles_pop_page/article_pop_mobile.dart';

class ArticlePop extends ConsumerStatefulWidget {
  final dynamic articlePop;
  final String tagArticlePop;

  const ArticlePop({
    super.key,
    required this.articlePop,
    required this.tagArticlePop,
  });

  @override
  FeedPopState createState() => FeedPopState();
}

class FeedPopState extends ConsumerState<ArticlePop> {
  @override
  Widget build(BuildContext context) {
  
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sprawdzenie, czy szerokość ekranu jest większa niż 1200 px
        if (constraints.maxWidth > 1080) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // Użycie 'widget.adFeedPop' i 'widget.tagFeedPop' do przekazania danych
                child: ArticlePopFull(
                    articlePop: widget.articlePop,
                    tagArticlePop: widget.tagArticlePop),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // Użycie 'widget.adFeedPop' i 'widget.tagFeedPop' do przekazania danych
                child: ArticlePopMobile(
                    articlePop: widget.articlePop,
                    tagArticlePop: widget.tagArticlePop),
              ),
            ],
          );
        }
      },
    );
  }
}
