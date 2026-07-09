import 'dart:ui' as ui;

import 'package:core/common/chrome/appbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:core/common/install_popup.dart';

import 'package:get/get_utils/get_utils.dart';

void copyToClipboard(BuildContext context, String listingUrl) {
  Clipboard.setData(ClipboardData(text: listingUrl)).then((_) {
    final snackBar = Customsnackbar().showSnackBar(
      "Success".tr,
      "Link skopiowany do schowka!".tr,
      "success",
      () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  });
}

class ArticlePopMobile extends ConsumerStatefulWidget {
  final dynamic articlePop;
  final String tagArticlePop;

  const ArticlePopMobile({
    super.key,
    required this.articlePop,
    required this.tagArticlePop,
  });

  @override
  ArticlePopMobileState createState() => ArticlePopMobileState();
}

class ArticlePopMobileState extends ConsumerState<ArticlePopMobile> {
  late String mainImageUrl;
  final SecureStorage secureStorage = SecureStorage();
  bool _atTop = true;
  bool _atBottom = false; // Add this flag for bottom detection
  double _dragDistance = 0.0;
  final double _requiredDragDistance = 100.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    mainImageUrl = widget.articlePop.thumbnailUrl;
    _scrollController.addListener(_updateScrollStatus);
  }

  void _updateScrollStatus() {
    if (!_scrollController.hasClients) return;
    
    final atTop = _scrollController.position.pixels <= 
        _scrollController.position.minScrollExtent + 1.0;
    final atBottom = _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 1.0;
    
    if (_atTop != atTop || _atBottom != atBottom) {
      setState(() {
        _atTop = atTop;
        _atBottom = atBottom;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    final theme = ref.read(themeColorsProvider);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double mainImageHeight = screenHeight * 0.75;

    const double maxWidth = 1920;
    const double minWidth = 480;
    const double maxLogoSize = 30;
    const double minLogoSize = 16;

    double logoSize = (screenWidth - minWidth) / (maxWidth - minWidth) * (maxLogoSize - minLogoSize) + minLogoSize;
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);

    return userAsyncValue.when(
      data: (user) {
        return PopupListener(
          child: SafeArea(
            top: false,
            bottom: false,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (notification) {
                  if (notification.leading) {
                    notification.disallowIndicator();
                  }
                  return true;
                },
                child: NotificationListener<OverscrollNotification>(
                  onNotification: (OverscrollNotification notification) {
                    if (_atTop && notification.overscroll < 0) {
                      _dragDistance -= notification.overscroll;
                      if (_dragDistance >= _requiredDragDistance) {
                        ref.read(navigationService).beamPop();
                        _dragDistance = 0.0;
                      }
                    } 
                    else if (_atBottom && notification.overscroll > 0) {
                      _dragDistance += notification.overscroll;
                      if (_dragDistance >= _requiredDragDistance) {
                        ref.read(navigationService).beamPop();
                        _dragDistance = 0.0;
                      }
                    }
                    else {
                      _dragDistance = 0.0;
                    }
                    return true;
                  },
                  child: Stack(
                    children: [
                      BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: theme.adPopBackground.withAlpha(120),
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref.read(navigationService).beamPop(),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              SizedBox(
                                width: screenWidth,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Hero(
                                            tag: widget.tagArticlePop,
                                            child: GestureDetector(
                                              onTap: () {},
                                              child: Image.network(
                                                mainImageUrl,
                                                width: screenWidth,
                                                height: mainImageHeight,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            child: TopAppBarWithBack(),
                                          ),
                                        ],
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            widget.articlePop.title,
                                            style: TextStyle(
                                              color: theme.textColor,
                                              fontSize: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 50),
                                      Material(
                                        color: Colors.transparent,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            widget.articlePop.body,
                                            style: TextStyle(
                                              color: theme.textColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 25),
                                      const Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [Expanded(child: SizedBox())],
                                      ),
                                      const SizedBox(height: 75),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Błąd: $error'.tr),
    );
  }
}