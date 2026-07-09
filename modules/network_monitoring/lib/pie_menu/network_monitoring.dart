// lib/providers/ad_provider.dart
import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/data/clients/client_fav_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/screens/feed_pop/providers/fav/provider.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:share_plus/share_plus.dart';
import 'package:core/theme/apptheme.dart';
import 'package:universal_io/io.dart';

import 'package:network_monitoring/browselist/utils/api.dart';
import 'package:network_monitoring/providers/displayed/provider.dart';
import 'package:network_monitoring/providers/freshness/freshness_service.dart';
import 'package:network_monitoring/screens/feed_pop/providers/hide/provider.dart';
import 'package:reports/reports/report_pdf_page/widgets/ad_report_dialog.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/chat/send_ad_to_chat_overlay.dart';

class ActionModel {
  final int id;
  ActionModel({required this.id});
}

List<PieAction> buildPieMenuActionsNM(
  WidgetRef ref,
  dynamic action, // pins and ads
  BuildContext context,
  int? transactionId,
  int? clientId,
) {
  final scope = BrowseScope(transactionId: transactionId, clientId: clientId);
  final hideScope = HideScope(transactionId: transactionId, clientId: clientId);
  final favScope = FavScope(transactionId: transactionId, clientId: clientId);

  final isFavorite = isFavoriteInScope(ref, action.id, favScope);
  final isOnHide = isHideInScope(ref, action.id, hideScope);
  final isOnBrowseList = isBrowseInScope(ref, action.id, scope);
  final theme = ref.watch(themeColorsProvider);

  return [
    PieAction(
      tooltip: Text(
        isFavorite ? 'Remove from likes'.tr : 'Add to favorites'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () async {
        await handleFavoriteActionNM(
          ref,
          action.id,
          transactionId,
          clientId,
          context,
        );
      },
      child: FaIcon(
        isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
      ),
    ),
    PieAction(
      tooltip: Text(
        isOnBrowseList
            ? 'Remove from viewing list'.tr
            : 'Add to viewing list'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () {
        handleBrowseListActionNM(ref, action, transactionId, clientId, context);
      },
      child: FaIcon(
        isOnBrowseList ? FontAwesomeIcons.listCheck : FontAwesomeIcons.list,
      ),
    ),
    PieAction(
      tooltip: Text(
        isOnHide ? 'restore_your_ads_visibility'.tr : 'hide_ad'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () {
        handleHideActionNM(ref, action, transactionId, clientId, context);
      },
      child: FaIcon(
        isOnHide ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
      ),
    ),
    PieAction(
      tooltip: Text(
        'Share the ad'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () {
        handleShareActionNM(action, context);
      },
      child: const FaIcon(FontAwesomeIcons.shareNodes),
    ),
    PieAction(
      tooltip: Text(
        'Copy link'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () async {
        await handleCopyLinkActionNM(action, context);
      },
      child: const FaIcon(FontAwesomeIcons.link),
    ),
    PieAction(
      tooltip: Text(
        'send_in_chat'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () async {
        await handleSendToChatActionNM(ref, action, context);
      },
      child: const FaIcon(FontAwesomeIcons.paperPlane),
    ),
    PieAction(
      tooltip: Text(
        "Generate PDF".tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () {
        handleGeneratePdfAction(action.id, context, isNm: true);
      },
      child: const FaIcon(FontAwesomeIcons.filePdf),
    ),

    // Debug-only freshness tools — visible only in debug builds.
    if (kDebugMode) ...[
      PieAction(
        tooltip: Text(
          'Verify freshness (debug)'.tr,
          style: TextStyle(color: theme.textColor),
        ),
        onSelect: () async {
          final url = (action.url ?? '').toString().trim();
          if (url.isEmpty) return;
          await ref
              .read(freshnessServiceProvider.notifier)
              .checkFreshness(url, adId: action.id as int?);
          if (!context.mounted) return;
          final result = ref.read(freshnessServiceProvider).lastResult;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == null
                    ? 'Freshness check failed'
                    : 'isActive=${result.isActive}  '
                        'confidence=${result.confidence.toStringAsFixed(2)}  '
                        'reason=${result.reason ?? "-"}',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        },
        child: const FaIcon(FontAwesomeIcons.magnifyingGlass),
      ),
      PieAction(
        tooltip: Text(
          'Mark as outdated (debug)'.tr,
          style: TextStyle(color: theme.textColor),
        ),
        onSelect: () async {
          final adId = action.id as int?;
          final url = (action.url ?? '').toString().trim();
          if (adId == null || url.isEmpty) return;
          final ok = await ref
              .read(freshnessServiceProvider.notifier)
              .markInactive(adId, url);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Marked as inactive in DB' : 'Failed to mark inactive',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        child: const FaIcon(FontAwesomeIcons.ban),
      ),
    ],
  ];
}

Future<void> handleGeneratePdfAction(
  int adId,
  BuildContext context, {
  bool isNm = false,
}) async {
  debugPrint('[nm report] $adId');
  await PopPageManager.show(
    context,
    child: AdReportDialog(advertisementId: adId, isNm: isNm),
    tag: 'ad_report_dialog_$adId',
    isBig: true,
    autoHeight: false,
    hasBackButton: true,
  );
}

Future<void> handleFavoriteActionNM(
  WidgetRef ref,
  int adId,
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
  final favScope = FavScope(transactionId: transactionId, clientId: clientId);

  final favIds = ref
      .read(nmFavScopedIdsProvider(favScope))
      .maybeWhen(data: (s) => s, orElse: () => const <int>{});

  final isFav = favIds.contains(adId);
  if (isFav) {
    await notifier.removeFromFavoritesNM(adId, transactionId, clientId);
    if (!context.mounted) return;
    context.showSnackBarLikeSection('fav_removed'.tr);
  } else {
    await notifier.addToFavoritesNM(adId, transactionId, clientId);
    if (!context.mounted) return;
    context.showSnackBarLikeSection('fav_added'.tr);
  }

  ref.invalidate(nmFavScopedIdsProvider(favScope));
  if (transactionId != null) {
    ref.invalidate(clientFavProvider(transactionId));
  }
}

Future<void> handleBrowseListActionNM(
  WidgetRef ref,
  MonitoringAdsModel ad,
  int? transactionId,
  int? clientId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection(
      'must_be_logged_in_to_add_to_viewing_list'.tr,
    );
    return;
  }

  final scope = BrowseScope(transactionId: transactionId, clientId: clientId);
  final notifier = ref.read(
    networkMonitoringBrowseListProvider(scope).notifier,
  );
  final message = await notifier.toggleBrowseListNM(ad, transactionId, clientId);
  if (message != null && context.mounted) {
    context.showSnackBarLikeSection(message);
  }
}

Future<void> handleHideActionNM(
  WidgetRef ref,
  MonitoringAdsModel ad,
  int? transactionId,
  int? clientId,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection(
      'must_be_logged_in_to_add_to_viewing_list'.tr,
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
    final displayedScope = DisplayedScope(
      transactionId: transactionId,
      clientId: clientId,
    );
    final notifier = ref.read(nMDisplayedAdsProvider(displayedScope).notifier);

    final isDisplayed = notifier.isDisplayedNM(ad.id);

    if (!isDisplayed) {
      await notifier.addToDisplayedNM(ad.id, transactionId, clientId);
    }
    ref.invalidate(nMDisplayedAdsProvider);
  }
}

Future<void> handleSendToChatActionNM(
  WidgetRef ref,
  MonitoringAdsModel ad,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarLikeSection(
      'must_be_logged_in_to_post_chat_ad'.tr,
    );
    return;
  }

  await showSendAdToChatOverlay(
    context: context,
    ref: ref,
    ad: ad,
  );
}

Future<void> handleShareActionNM(
  MonitoringAdsModel ad,
  BuildContext context,
) async {
  final dynamic rawUrl = ad.url;
  final String url = rawUrl?.toString().trim() ?? '';

  if (url.isEmpty) {
    context.showSnackBarLikeSection('no_link_to_share'.tr);
    return;
  }

  try {
    if (kIsWeb) {
      if (await isMobileBrowser()) {
        debugPrint(
          'Wywoływanie natywnego ekranu udostępniania w przeglądarce mobilnej'
              .tr,
        );
        await invokeWebShare(url);
      } else {
        debugPrint('Kopiowanie linku do schowka');
        await Clipboard.setData(ClipboardData(text: url));
        if (!context.mounted) return;
        context.showSnackBarLikeSection('Link copied to clipboard'.tr);
      }
    } else {
      debugPrint('Udostępnianie natywne');
      await Share.share('check_out_this_ad'.tr + url);
    }
  } catch (e) {
    debugPrint('Błąd podczas udostępniania: $e');
    if (!context.mounted) return;
    context.showSnackBarLikeSection('${'error_while_sharing'.tr}: $e');
  }
}

Future<void> handleCopyLinkActionNM(
  MonitoringAdsModel ad,
  BuildContext context,
) async {
  final dynamic rawUrl = ad.url;
  final String url = rawUrl?.toString().trim() ?? '';

  if (url.isEmpty) {
    context.showSnackBarLikeSection('No link to copy'.tr);
    return;
  }

  try {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    context.showSnackBarLikeSection('Link copied to clipboard'.tr);
  } catch (e) {
    debugPrint('Błąd podczas kopiowania linku: $e');
    if (!context.mounted) return;
    context.showSnackBarLikeSection('${'error_copying_link'.tr}: $e');
  }
}

extension ContextExtension on BuildContext {
  void showSnackBarLikeSection(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}