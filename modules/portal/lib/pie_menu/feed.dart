import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../global_providers/displayed_provider.dart';
import '../screens/feed/components/browselist/utils/api.dart';
import '../screens/feed/provider/feed_pop/fav_provider.dart';
import '../screens/feed/provider/feed_pop/hide_provider.dart';

class ActionModel {
  final int id;
  ActionModel({required this.id});
}

List<PieAction> buildPieMenuActions(
  WidgetRef ref,
  dynamic action,
  BuildContext context,
) {
 final isFavorite = ref.watch(
    favAdsProvider.select(
      (a) => a.maybeWhen(
        data: (ads) => ads.any((ad) => ad.id == action.id),
        orElse: () => false,
      ),
    ),
  );

  final isOnBrowseList = ref.watch(
    browseListProvider.select(
      (a) => a.maybeWhen(
        data: (ads) => ads.any((ad) => ad.id == action.id),
        orElse: () => false,
      ),
    ),
  );

  final isHidden = ref.watch(
    hideAdsProvider.select(
      (a) => a.maybeWhen(
        data: (ads) => ads.any((ad) => ad.id == action.id),
        orElse: () => false,
      ),
    ),
  );

  return [
    PieAction(
      tooltip: isFavorite
          ? Text('remove_from_favorites'.tr)
          : Text('add_to_favorites'.tr),
      onSelect: () {
        handleFavoriteAction(ref, action, context);
      },
      child: FaIcon(
        isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
      ),
    ),
    PieAction(
      tooltip: isOnBrowseList
          ? Text('remove_from_browse_list'.tr)
          : Text('add_to_browse_list'.tr),
      onSelect: () {
        handleBrowseListAction(ref, action, context);
      },
      child: FaIcon(
        isOnBrowseList ? FontAwesomeIcons.listCheck : FontAwesomeIcons.list,
      ),
    ),
    PieAction(
      tooltip: isHidden ? Text('show_ad'.tr) : Text('hide_ad'.tr),
      onSelect: () {
        handleHideAction(ref, action, context);
      },
      child: FaIcon(
        isHidden ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
      ),
    ),
    PieAction(
      tooltip: Text('share_ad'.tr),
      onSelect: () {
        handleShareAction(action, context);
      },
      child: const FaIcon(FontAwesomeIcons.shareNodes),
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
    context.showSnackBarSafe('must_be_logged_in_to_favorite'.tr);
    return;
  }

  final notifier = ref.read(favAdsProvider.notifier);
  await notifier.toggleFavorite(ad.id, context);
}

Future<void> handleBrowseListAction(
  WidgetRef ref,
  AdsListViewModel ad,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  final notifier = ref.read(browseListProvider.notifier);
  final prefs = await SharedPreferences.getInstance();
  const offlineListKey = 'offline_browse_list';

  if (!isUserLoggedIn) {
    final offlineRaw = prefs.getStringList(offlineListKey) ?? [];

    final Set<int> existingIds = {};
    final List<String> deduplicatedRaw = [];
    final List<AdsListViewModel> loadedAds = [];

    for (final item in offlineRaw) {
      try {
        final decoded = json.decode(item);
        if (decoded is Map<String, dynamic> && decoded['id'] is int) {
          final id = decoded['id'];
          if (!existingIds.contains(id)) {
            existingIds.add(id);
            deduplicatedRaw.add(item);
            loadedAds.add(AdsListViewModel.fromJson(decoded));
          }
        }
      } catch (_) {}
    }

    // Add new ad only if it doesn't exist
    if (!existingIds.contains(ad.id)) {
      final encoded = json.encode(ad.toJson());
      deduplicatedRaw.add(encoded);
      loadedAds.add(ad);
      await prefs.setStringList(offlineListKey, deduplicatedRaw);
      debugPrint('✅ Stored offline browse list count: ${deduplicatedRaw.length}');
    }

    if (!context.mounted) return;
    context.showSnackBarSafe('added_locally_to_browse_list'.tr);

    // Update local list in Riverpod state immediately
    final currentAds = ref
        .read(browseListProvider)
        .maybeWhen(data: (ads) => ads, orElse: () => <AdsListViewModel>[]);
    final updated = [
      ...loadedAds.where((newAd) => !currentAds.any((a) => a.id == newAd.id)),
      ...currentAds,
    ];
    ref.read(browseListProvider.notifier).state = AsyncData(updated);
    return;
  }

  // 🔁 If user IS logged in — push all cached offline ads to API
  final offlineRaw = prefs.getStringList(offlineListKey) ?? [];
  final List<int> pushed = [];

  for (final raw in offlineRaw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        final offlineAd = AdsListViewModel.fromJson(decoded);
        await notifier.addToBrowseLists(offlineAd.id);
        pushed.add(offlineAd.id);
      }
    } catch (_) {}
  }

  if (pushed.isNotEmpty) {
    await prefs.remove(offlineListKey);
    debugPrint('✅ Pushed ${pushed.length} offline ads to server and cleared cache.');
  }

  // Proceed with current ad
  await notifier.toggleBrowseList(ad, context);
}

Future<void> handleHideAction(
  WidgetRef ref,
  dynamic ad,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (!isUserLoggedIn) {
    context.showSnackBarSafe('must_be_logged_in_to_hide'.tr);
    return;
  }

  final notifier = ref.read(hideAdsProvider.notifier);
  await notifier.toggleHide(ad.id, context);
}

Future<void> handleDisplayedAction(
  WidgetRef ref,
  dynamic ad,
  BuildContext context,
) async {
  final isUserLoggedIn = ApiServices.isUserLoggedIn();
  if (isUserLoggedIn) {
    final isDisplayed = await ref
        .read(displayedAdsProvider.notifier)
        .isDisplayed(ad.id);
    if (isDisplayed) {
      await ref.read(displayedAdsProvider.notifier).removeFromDisplayed(ad.id);
    } else {
      await ref.read(displayedAdsProvider.notifier).addToDisplayed(ad.id);
    }
  }
}

Future<void> handleShareAction(dynamic ad, BuildContext context) async {
  try {
    await Share.share(
      "https://www.hously.pro/offer/${ad.slug}/",
      subject: "Sprawdź to ogłoszenie!",
    );
  } catch (e) {
    debugPrint("Błąd podczas udostępniania: $e");
    if (!context.mounted) return;
   
  }
}

extension ContextSnackbars on BuildContext {
  void showSnackBarSafe(String message) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger != null) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return;
    }

    // Fallback, gdy nie ma ScaffoldMessenger (np. overlay)
    if (Get.isOverlaysOpen || Get.isDialogOpen == true) {
      Get.rawSnackbar(message: message, duration: const Duration(seconds: 2));
    } else {
      debugPrint('⚠️ Brak ScaffoldMessenger w kontekście – pomijam SnackBar.');
    }
  }
}
