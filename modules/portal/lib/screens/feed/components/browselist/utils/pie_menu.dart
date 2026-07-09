import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/global_providers/displayed_provider.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';

import 'api.dart';

class ActionModel {
  final int id;
  ActionModel({required this.id});
}

List<PieAction> browseListPieMenuActions(
  WidgetRef ref,
  dynamic action,
  BuildContext context,
) {
  final isFavorite = ref
      .watch(favAdsProvider)
      .maybeWhen(
        data: (ads) => ads.any((ad) => ad.id == action.id),
        orElse: () => false,
      );

  return [
    PieAction(
      tooltip: Text('add_to_favorites'.tr),
      onSelect: () {
        handleFavoriteAction(ref, action, context);
      },
      child: FaIcon(
        isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
      ),
    ),
    PieAction(
      tooltip: Text('share_ad'.tr),
      onSelect: () {
        handleShareAction(action.id, context);
      },
      child: const FaIcon(FontAwesomeIcons.shareNodes),
    ),
    PieAction(
      tooltip: Text('remove_from_browse_list'.tr),
      onSelect: () {
        handleBrowseListRemoveAction(ref, action, context);
      },
      child: const FaIcon(FontAwesomeIcons.xmark),
    ),
  ];
}

Future<void> handleFavoriteAction(
  WidgetRef ref,
  dynamic ad,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection('must_be_logged_in_to_favorite'.tr);
    return;
  }

  final notifier = ref.read(favAdsProvider.notifier);
  await notifier.toggleFavorite(ad.id, context);
}

Future<void> handleDisplayedAction(
  WidgetRef ref,
  int adId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (isUserLoggedIn) {
    final isDisplayed = await ref
        .read(displayedAdsProvider.notifier)
        .isDisplayed(adId);
    if (isDisplayed) {
      await ref.read(displayedAdsProvider.notifier).removeFromDisplayed(adId);
    } else {
      await ref.read(displayedAdsProvider.notifier).addToDisplayed(adId);
    }
  }
}

Future<void> handleBrowseListRemoveAction(
  WidgetRef ref,
  dynamic ad,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection('must_be_logged_in_to_favorite'.tr);
    return;
  }

  final notifier = ref.read(browseListProvider.notifier);
  await notifier.toggleBrowseList(ad, context);
}

Future<void> handleShareAction(int adId, BuildContext context) async {
  final url = 'hously.pro/ad/$adId';

  try {
    if (kIsWeb) {
      // Sprawdź, czy to przeglądarka mobilna
      if (await isMobileBrowser()) {
        debugPrint(
          'Wywoływanie natywnego ekranu udostępniania w przeglądarce mobilnej'
              .tr,
        );
        await invokeWebShareFeed(url);
      } else {
        debugPrint('Kopiowanie linku do schowka');
        await Clipboard.setData(ClipboardData(text: url));
        if (!context.mounted) return;
        context.showSnackBarLikeSection('Link skopiowany do schowka');
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      debugPrint('Udostępnianie na Android/iOS');
      await Share.share('Sprawdź to ogłoszenie: $url');
    }
  } catch (e) {
    debugPrint('Błąd podczas udostępniania: $e');
    if (!context.mounted) return;
    context.showSnackBarLikeSection('error_during_sharing'.tr + e.toString());
  }
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
