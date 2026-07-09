import 'package:get/get_utils/get_utils.dart';
enum LandingAdsTab {
  recentlyViewed,
  forYou,
  exclusiveOffers,
  newListing,
  openHouses,
  mostViewed,
}

extension LandingAdsTabX on LandingAdsTab {
  String get apiValue {
    switch (this) {
      case LandingAdsTab.recentlyViewed:
        return 'recently_viewed';
      case LandingAdsTab.forYou:
        return 'for_you';
      case LandingAdsTab.exclusiveOffers:
        return 'exclusive_offers';
      case LandingAdsTab.newListing:
        return 'new_listing';
      case LandingAdsTab.openHouses:
        return 'open_houses';
      case LandingAdsTab.mostViewed:
        return 'most_viewed';
    }
  }

  String trLabel() {
    switch (this) {
      case LandingAdsTab.recentlyViewed:
        return 'RECENTYLY VIEWED'.tr;
      case LandingAdsTab.forYou:
        return 'FOR YOU'.tr;
      case LandingAdsTab.exclusiveOffers:
        return 'EXCLUSIVE OFFERS'.tr;
      case LandingAdsTab.newListing:
        return 'NEW LISTING'.tr;
      case LandingAdsTab.openHouses:
        return 'OPEN HOUSES'.tr;
      case LandingAdsTab.mostViewed:
        return 'MOST VIEWED'.tr;
    }
  }
}