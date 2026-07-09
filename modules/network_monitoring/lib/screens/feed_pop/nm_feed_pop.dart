import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/screens/feed_pop/nm_feed_pop_full_page.dart';
import 'package:network_monitoring/screens/feed_pop/nm_feed_pop_mid_page.dart';
import 'package:network_monitoring/screens/feed_pop/nm_feed_pop_mobile_page.dart';

class NMFeedPop extends ConsumerWidget {
  final dynamic adNetworkPop;
  final String tagNetworkPop;

  const NMFeedPop({
    super.key,
    required this.adNetworkPop,
    required this.tagNetworkPop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: NMFeedPopFullPage(
                    adNetworkPop: adNetworkPop, tagNetworkPop: tagNetworkPop),
              ),
            ],
          );
        } else if (constraints.maxWidth > 1080) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // Użycie 'widget.adFeedPop' i 'widget.tagFeedPop' do przekazania danych
                child: NMFeedPopMidPage(
                    adNetworkPop: adNetworkPop, tagFeedPop: tagNetworkPop),
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
                child: NMFeedPopMobilePage(
                    adFeedPop: adNetworkPop, tagFeedPop: tagNetworkPop),
              ),
            ],
          );
        }
      },
    );
  }
}
