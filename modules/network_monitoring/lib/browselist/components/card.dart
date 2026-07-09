import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_handle.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import '../utils/pie_menu.dart';

class BrowseListCardWidget extends ConsumerWidget {
  final MonitoringAdsModel ad;
  final int? transactionId;
  final int? clientId;
  final String keyTag;
  final String mainImageUrl;
  final String formattedPrice;
  final bool isHidden;
  final bool ifIsFav;
  final bool isSelectable;
  final bool isSelected;
  final bool isUnorganizedWidget;
  final bool disableHero;
  final double aspectRatio;

  const BrowseListCardWidget({
    super.key,
    this.disableHero = false,
    this.transactionId,
    this.clientId,
    required this.isHidden,
    required this.ad,
    required this.keyTag,
    required this.mainImageUrl,
    required this.formattedPrice,
    this.ifIsFav = false,
    this.isSelectable = false,
    this.isSelected = false,
    this.isUnorganizedWidget = false,
    this.aspectRatio = 0,
  });

  Widget _wrapHero({
    required String tag,
    required Widget child,
    required bool disableHero,
  }) {
    if (disableHero) return child;
    return Hero(tag: tag, child: child);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final card = Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: isSelectable && isSelected
            ? BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: ifIsFav
            ? SizedBox(
                height: double.infinity,
                child: _buildCardContent(
                  context,
                  ref,
                  theme,
                  isUnorganizedWidget,
                ),
              )
            : AspectRatio(
                aspectRatio: 1,
                child: _buildCardContent(
                  context,
                  ref,
                  theme,
                  isUnorganizedWidget,
                ),
              ),
      ),
    );

    // DndHandle is a Stack sibling of PieMenu (inside _buildCardContent),
    // so there is no gesture-arena conflict between DnD and pie menu.
    return card;
  }

  Widget _buildCardContent(
    BuildContext context,
    WidgetRef ref,
    ThemeColors theme,
    bool isUnorganizedProperties,
  ) {
    return MiddleClickDetector(
      onMiddleClick: () {
        debugPrint('Middle click detected!');
        handleBrowseListRemoveActionNM(
          ref,
          ad,
          context,
          transactionId,
          clientId,
        );
      },
      child: Stack(
        children: [
          PieMenu(
            theme: PieTheme.of(context).copyWith(
              overlayColor: (() {
                final theme = ref.watch(themeColorsProvider);
                final bool uiIsDark =
                    theme.textColor.computeLuminance() > 0.5;
                final base = uiIsDark ? Colors.black : Colors.white;
                return base.withValues(alpha: 0.70);
              })(),
            ),
            onPressedWithDevice: (PointerDeviceKind kind) async {
              if (kind == PointerDeviceKind.mouse ||
                  kind == PointerDeviceKind.touch) {
                await openAdUrl(
                  context,
                  ref,
                  ad,
                  transactionId,
                  clientId,
                  '${ad.id}',
                );
              }
            },
            actions: browseListPieMenuActions(
              ref,
              ad,
              context,
              transactionId,
              clientId,
            ),
            child: _wrapHero(
              disableHero: disableHero,
              tag: keyTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: aspectRatio > 0
                          ? aspectRatio
                          : isUnorganizedProperties
                              ? 3 / 4
                              : 2,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Image.network(
                          mainImageUrl,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey,
                            alignment: Alignment.center,
                            child: Text(
                              'No picture'.tr,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: ad.isActive == false
                            ? BoxDecoration(
                                color: theme.themeColor.withAlpha(150),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : BoxDecoration(
                                gradient: const LinearGradient(
                                  end: Alignment.topRight,
                                  begin: Alignment.bottomLeft,
                                  colors: [
                                    AppColors.dark50,
                                    AppColors.dark15,
                                  ],
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
                            if (ad.isActive == true)
                              Text(
                                '$formattedPrice ${ad.currency}',
                                style: AppTextStyles.interBold.copyWith(
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            if (ad.isActive == false)
                              Text(
                                'ad_has_expired'.tr,
                                style: AppTextStyles.interBold.copyWith(
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            Text(
                              '${ad.city}, ${ad.street}',
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
          if (!isHidden)
            Positioned(
              right: 8,
              top: 0,
              child: SizedBox(
                height: 30,
                width: 30,
                child: ElevatedButton(
                  style: elevatedButtonStyleRounded5Transparent,
                  onPressed: () {
                    handleBrowseListRemoveActionNM(
                      ref,
                      ad,
                      context,
                      transactionId,
                      clientId,
                    );
                  },
                  child: const Icon(Icons.close, size: 20),
                ),
              ),
            ),

          // Drag handle: sits on top of PieMenu as a Stack sibling so there
          // is no gesture-arena race. On mobile, long-press the handle to drag;
          // long-press elsewhere on the card opens the pie menu.
          Positioned(
            left: 6,
            top: 6,
            child: DndHandle(
              payload: DndPayload(
                action: 'add_to_favorites',
                type: DndPayloadType.nm_ad,
                id: ad.id.toString(),
                data: {
                  'advertisement': ad.id,
                  'advertisement_id': ad.id,
                  'title': ad.title,
                  'source': 'browse_list',
                },
              ),
              feedbackBuilder: (ctx) => DragFeedbackBuilders.nmAdFeedback(
                ctx,
                ad.title ?? 'Property Ad',
              ),
            ),
          ),
        ],
      ),
    );
  }
}