import 'package:crm/data/clients/client_fav_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/providers/displayed/provider.dart';
import 'package:network_monitoring/screens/feed_pop/providers/fav/provider.dart';
import 'package:pie_menu/pie_menu.dart';
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
  int? transactionId,
  int? clientId,
) {

  final favScope = FavScope(transactionId: transactionId, clientId: clientId);

  final isFavorite = isFavoriteInScope(ref, action.id, favScope);

  return [
    PieAction(
      tooltip: Text(isFavorite 
      ? 'Remove from likes'.tr
      : 'Add to favorites'.tr
      ),
      onSelect: () {
        handleFavoriteActionNM(ref, action, transactionId, clientId, context);
      },
      child: FaIcon(
        isFavorite 
        ? FontAwesomeIcons.solidHeart 
        : FontAwesomeIcons.heart
      ),
    ),
    PieAction(
      tooltip: Text('Share the ad'.tr),
      onSelect: () {
        handleShareActionNM(action.id, context);
      },
      child: const FaIcon(FontAwesomeIcons.shareNodes),
    ),
    PieAction(
      tooltip: Text('Remove from viewing list'.tr),
      onSelect: () {
        handleBrowseListRemoveActionNM(ref, action, context, transactionId, clientId);
      },
      child: const FaIcon(FontAwesomeIcons.xmark),
    ),
  ];
}

Future<void> handleFavoriteActionNM(
  WidgetRef ref,
  dynamic ad,
  int? transactionId,
  int? clientId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection(
      'You must be logged in to add an ad to your favorites.'.tr,
    );
    return;
  }

  final notifier = ref.read(nMFavAdsProvider.notifier);
  await notifier.toggleFavorite(ad, transactionId, clientId, context, );
}


Future<void> handleDisplayedActionNM(
  WidgetRef ref,
  dynamic ad,
  int? transactionId,
  int? clientId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (isUserLoggedIn) {
    
  final displayedScope = DisplayedScope(transactionId: transactionId, clientId: clientId);
  final notifier = ref.read(nMDisplayedAdsProvider(displayedScope).notifier);


    final isDisplayed = notifier.isDisplayedNM(ad.id);

    if (!isDisplayed) {
      await notifier.addToDisplayedNM(ad.id, transactionId, clientId);
    } 
    ref.invalidate(nMDisplayedAdsProvider);
  }
}


Future<void> handleBrowseListRemoveActionNM(
  WidgetRef ref,
  dynamic ad,
  BuildContext context,
  int? transactionId,
  int? clientId,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection(
      'You must be logged in to add an ad to your favorites.'.tr,
    );
    return;
  }

      final scope = BrowseScope(
      transactionId: transactionId,
      clientId: clientId,
    );


  final notifier = ref.read(networkMonitoringBrowseListProvider(scope).notifier);
  final message = await notifier.toggleBrowseListNM(ad, null, null);
  if (message != null && context.mounted) {
    context.showSnackBarLikeSection(message);
  }
}





Future<void> handleShareActionNM(int adId, BuildContext context) async {
  final ctx = context; // bezpieczne użycie kontekstu
  final url = 'hously.pro/network-monitoring/$adId';

  try {
    if (kIsWeb) {
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
        ctx.showSnackBarLikeSection('Link copied to clipboard'.tr);
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      debugPrint('Udostępnianie na Android/iOS');
      await Share.share('check_out_this_ad'.tr + url);
    }
  } catch (e) {
    debugPrint('Błąd podczas udostępniania: $e');

    if (!context.mounted) return;
    ctx.showSnackBarLikeSection('${'Error while sharing:'.tr} $e');
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
