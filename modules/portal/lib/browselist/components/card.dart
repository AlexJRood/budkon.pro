import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:portal/screens/feed/components/browselist/utils/pie_menu.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:get/get_utils/get_utils.dart';

class PortalBrowseListCardWidget extends ConsumerWidget {
  final AdsListViewModel feedAd; // Model oferty
  final String keyTag; // Klucz/tag dla Hero
  final String mainImageUrl; // URL głównego zdjęcia
  final String formattedPrice; // Sformatowana cena (np. "12,00")
  final bool isHidden;
  final bool isMobile;
  final bool isSelectable;
  final bool isSelected;
  final bool remove;
  final bool isUnorganizedProperties;
  final double aspectRatio;
  final bool isFeedPop;

  const PortalBrowseListCardWidget({
    super.key,
    required this.isHidden,
    required this.feedAd,
    required this.keyTag,
    required this.mainImageUrl,
    required this.formattedPrice,
    this.remove = true,
    this.isMobile = false,
    this.isSelectable = false,
    this.isSelected = false,
    this.isUnorganizedProperties = false,
    this.aspectRatio = 0,
    this.isFeedPop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationService);

    final currentPath = nav.currentPath;
    final path = currentPath == '/' ? '' : currentPath;

    final route = isFeedPop ? '/offer/${feedAd.id}' : '$path/offer/${feedAd.id}';

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration:
            isSelectable && isSelected
                ? BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(6),
                )
                : null,
        child: MiddleClickDetector(
          onMiddleClick: () {
            debugPrint('Middle click detected!');
            // Akcja usuwania z browselist przy środkowym kliknięciu.
            handleBrowseListRemoveAction(ref, feedAd, context);
          },
          child: Stack(
            children: [
              // Obszar interaktywny otwierający widok ogłoszenia
              PieMenu(
                theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
                onPressedWithDevice: (PointerDeviceKind kind) {
                  if (kind == PointerDeviceKind.mouse ||
                      kind == PointerDeviceKind.touch) {
                    // Logika przed przejściem
                    handleDisplayedAction(ref, feedAd.id, context);
                    // Nawigacja do widoku ogłoszenia
                    nav.openPopup(
                          route,
                          data: {'tag': keyTag, 'ad': feedAd},
                        );
                  }
                },
                actions: browseListPieMenuActions(ref, feedAd, context),
                child: Hero(
                  tag: keyTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        // Zdjęcie ogłoszenia
                        AspectRatio(
                          aspectRatio: aspectRatio > 0
                              ? aspectRatio
                              : isUnorganizedProperties
                              ? 3 / 4
                              : 2,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final dpr = MediaQuery.of(context).devicePixelRatio;
                              final targetW =
                              (constraints.maxWidth * dpr).round().clamp(200, 1200);

                              return Image.network(
                                mainImageUrl,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low,
                                cacheWidth: targetW, // <-- important downscale
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey,
                                  alignment: Alignment.center,
                                  child:Text(
                                    'no_image'.tr,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                end: Alignment.topRight,
                                begin: Alignment.bottomLeft,
                                colors: [AppColors.dark50, AppColors.dark15],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        if (!isHidden)
                          Positioned(
                            left: 8,
                            bottom: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$formattedPrice ${feedAd.currency}',
                                  style: AppTextStyles.interBold.copyWith(
                                    fontSize: 16,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  '${feedAd.city}, ${feedAd.street}',
                                  style: AppTextStyles.interRegular.copyWith(
                                    fontSize: 12,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Przycisk "X" do usunięcia z browselist – umieszczony poza PieMenu
              if (!isHidden && remove)
                Positioned(
                  right: 8,
                  top: 0,
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: ElevatedButton(
                      style: elevatedButtonStyleRounded5Transparent,
                      onPressed: () {
                        // Tylko usuń element, nie otwierając widoku ogłoszenia.
                        handleBrowseListRemoveAction(ref, feedAd, context);
                      },
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
