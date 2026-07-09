// lib/providers/ad_provider.dart
import 'package:crm/data/clients/client_fav_provider.dart';
import 'package:flutter/foundation.dart'; // Importujemy dla kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importujemy dla schowka
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/screens/feed_pop/providers/fav/provider.dart';
import 'package:network_monitoring/screens/feed_pop/providers/hide/provider.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';

import 'package:network_monitoring/browselist/utils/api.dart';
import 'package:network_monitoring/providers/displayed/provider.dart';

class ActionModel {
  final int id;
  ActionModel({required this.id});
}

List<PieAction> pieAdsClient(
  WidgetRef ref,
  dynamic action,
  BuildContext context,
  int? transactionId,
  int? clientId,
) {
  final favScope = FavScope(transactionId: transactionId, clientId: clientId);
  final hideScope = HideScope(transactionId: transactionId, clientId: clientId);
  final browseScope = BrowseScope(transactionId: transactionId, clientId: clientId);

  final isFavorite = isFavoriteInScope(ref, action.id, favScope);
  final isOnHide = isHideInScope(ref, action.id, hideScope);
  final isOnBrowseList = isBrowseInScope(ref, action.id, browseScope);

  return [

    PieAction(
      tooltip: Text(isFavorite 
      ? 'remove_from_favorites'.tr
      : 'add_to_favorites'.tr 
      ),
      onSelect: () {
        handleFavoriteActionNM(ref, action.id, transactionId, clientId, context);
      },
      child: FaIcon(
        isFavorite 
        ? FontAwesomeIcons.solidHeart 
        : FontAwesomeIcons.heart
      ),
    ),
    PieAction(
      tooltip: Text( isOnBrowseList 
      ? 'remove_from_browse_list'.tr
      : 'add_to_browse_list'.tr 
      ),
      onSelect: () {
        handleBrowseListActionNM(ref, action, transactionId, clientId,  context);
      },
      child: FaIcon(
        isOnBrowseList ? FontAwesomeIcons.listCheck : FontAwesomeIcons.list,
      ),
    ),
    PieAction(
      tooltip: Text(isOnHide 
      ? 'restore_ad_visibility'.tr
      : 'hide_ad'.tr 
      ),
      onSelect: () {
        handleHideActionNM(ref, action,  transactionId, clientId,  context);
      },
      child: FaIcon(
        isOnHide ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
      ),
    ),
    PieAction(
      tooltip: Text('share_ad'.tr),
      onSelect: () {
        handleShareActionNM(action.id, context);
      },
      child: const FaIcon(FontAwesomeIcons.shareNodes),
    ),
  ];
}




Future<void> handleFavoriteActionNM(
  WidgetRef ref,
  int adId,
  int? transactionId,
  int? clientId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  final scope = FavScope(transactionId: transactionId, clientId: clientId);
  if (isUserLoggedIn) {
    final notifier = ref.read(nMFavAdsProvider.notifier);  
    final isFav = isFavoriteInScope(ref, adId, scope);
    
    if (isFav) {
      await notifier.removeFromFavoritesNM(adId, transactionId, clientId);
      if (!context.mounted) return;
      context.showSnackBarLikeSection('removed_from_favorites'.tr);
    } else {
      await notifier.addToFavoritesNM(adId, transactionId ?? transactionId, clientId ?? clientId,);
      if (!context.mounted) return;
      context.showSnackBarLikeSection('added_to_favorites'.tr);
    }
    ref.invalidate(clientFavProvider(transactionId!));
    ref.invalidate(nmFavScopedIdsProvider(scope));
  } else {
    context.showSnackBarLikeSection(
      'login_required_to_add_to_favorites'.tr,
    );
  }
}


Future<void> handleBrowseListActionNM(
  WidgetRef ref,
  dynamic ad,
  int? transactionId,
  int? clientId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection(
      'login_required_to_add_to_browse_list'.tr,
    );
    return;
  }

  final browseScope = BrowseScope(transactionId: transactionId, clientId: clientId);
  final notifier = ref.read(networkMonitoringBrowseListProvider(browseScope).notifier);
  final message = await notifier.toggleBrowseListNM(ad, transactionId, clientId);
  if (message != null && context.mounted) {
    context.showSnackBarLikeSection(message);
  }
}





Future<void> handleHideActionNM(
  WidgetRef ref,
  dynamic ad,
  int? transactionId,
  int? clientId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection(
     'login_required_to_add_to_browse_list'.tr
    );
    return;
  }

  final hideScope = HideScope(transactionId: transactionId, clientId: clientId);
  final notifier = ref.read(nMHideAdsProvider(hideScope).notifier);
  await notifier.toggleHideNM(ad, transactionId, clientId, context);
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



Future<void> handleShareActionNM(int adId, BuildContext context) async {
  final url = 'hously.pro/network-monitoring/$adId';

  try {
    if (kIsWeb) {
      // Sprawdź, czy to przeglądarka mobilna
      if (await isMobileBrowser()) {
        debugPrint(
        'native_share_screen_mobile_browser'.tr,
        );
        await invokeWebShare(url);
      } else {
        debugPrint('Kopiowanie linku do schowka');
        await Clipboard.setData(ClipboardData(text: url));
        if (!context.mounted) return;
        context.showSnackBarLikeSection('link_copied_to_clipboard'.tr);
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      debugPrint('Udostępnianie na Android/iOS');
      await Share.share('${'check_out_this_ad'.tr} $url');
    }
  } catch (e) {
    debugPrint('Błąd podczas udostępniania: $e');
    if (!context.mounted) return;
    context.showSnackBarLikeSection('${'error_during_sharing'.tr} $e');
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
