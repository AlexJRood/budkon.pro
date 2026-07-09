import 'package:flutter/material.dart';
import 'package:portal/screens/feed/widgets/feed_pop/feed_pop_full.dart';
import 'package:portal/screens/feed/widgets/feed_pop/feed_pop_mid.dart';
import 'package:portal/screens/feed/widgets/feed_pop/feed_pop_mobile.dart';

class FeedPopPage extends StatelessWidget {
  final dynamic adFeedPop;
  final String tagFeedPop;
  final bool isChat;

  const FeedPopPage({
    super.key,
    required this.adFeedPop,
    required this.tagFeedPop,
    this.isChat = false
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sprawdzenie, czy szerokość ekranu jest większa niż 1200 px
        if (constraints.maxWidth > 1420) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // Użycie 'widget.adFeedPop' i 'widget.tagFeedPop' do przekazania danych
                child: FeedPopFull(adFeedPop: adFeedPop, tagFeedPop: tagFeedPop,isChat:isChat),
              ),
            ],
          );
        } else if (constraints.maxWidth > 1080) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // Użycie 'widget.adFeedPop' i 'tagFeedPop' do przekazania danych
                child: FeedPopMid(adFeedPop: adFeedPop, tagFeedPop: tagFeedPop),
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
                child:
                    FeedPopMobile(adFeedPop: adFeedPop, tagFeedPop: tagFeedPop),
              ),
            ],
          );
        }
      },
    );
  }
}
