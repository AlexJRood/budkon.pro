import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/providers/saved_search/last_searches_provider.dart';
import 'package:network_monitoring/screens/network_home_page/widgets/search_history_list_widget.dart';
import 'package:network_monitoring/filters/new_screens/new_filter_pop_page.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:core/theme/apptheme.dart';

class NetworkHomeFilterPopWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final ScrollController? scrollController;
  final bool needNavigate;
  const NetworkHomeFilterPopWidget({super.key, this.scrollController, this.isMobile = false, this.needNavigate = true});

  @override
  ConsumerState<NetworkHomeFilterPopWidget> createState() => _NetworkHomeFilterPopWidgetState();
}

class _NetworkHomeFilterPopWidgetState extends ConsumerState<NetworkHomeFilterPopWidget> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(lastSearchProvider.notifier).fetchSavedSearches();
    },);
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    if (kDebugMode) print(screenWidth);
    final theme = ref.read(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
            child: Container(
              color: theme.adPopBackground.withAlpha(75),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 0 :28.0),
              child: SingleChildScrollView(controller: widget.scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing:50,
                  children: [
                    if(screenWidth> 1080)
                      const SearchHistoryList(),
                      SizedBox(
                        width: widget.isMobile ? screenWidth : math.max(screenWidth * 0.7, 450),
                        height: math.max(screenHeight * 0.91, 400),
                        child: NewFilterPopPage(needNavigate: widget.needNavigate, scrollController: widget.scrollController, ))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
