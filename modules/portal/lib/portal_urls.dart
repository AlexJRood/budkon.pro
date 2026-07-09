import 'package:core/platform/url.dart';

/// portal feature API endpoints, decentralized out of core's URLs God-package.
class PortalUrls {
  const PortalUrls._();

static final addAdvertisement = URLs.appendBaseUrl('/portal/add_advertisement/');
static String addDisplayed(String adId) =>
      URLs.appendBaseUrl('/portal/displayed/add/$adId/?sort=date_asc');
static String advertisementsArchive(String adId) =>
      URLs.appendBaseUrl('/portal/archive/advertisements/$adId/');
static String advertisementsTempImageDelete (int offerId) =>
      URLs.appendBaseUrl('/portal/advertisements/temp-image-upload/$offerId/');
static final advertisementsTempImageUpload = URLs.appendBaseUrl(
    '/portal/advertisements/temp-image-upload/',
  );
static final apiAdvertisementsMapPins = URLs.appendBaseUrl('/portal/advertisements/map-pins/');
static final apiDisplayed = URLs.appendBaseUrl('/portal/displayed/?sort=date_asc');
static String apiFavoriteRemove(String adId) =>
      URLs.appendBaseUrl('/portal/favorite/remove/$adId/');
static final apiHide = URLs.appendBaseUrl('/portal/hide/');
static String apiHideAdd(String adId) =>
      URLs.appendBaseUrl('/portal/hide/add/$adId/');
static String apiHideRemove(String adId) =>
      URLs.appendBaseUrl('/portal/hide/remove/$adId/');
static final feedbackContact = URLs.appendBaseUrl('/feedback/contact/');
static const String landingPageAds = '${URLs.baseUrl}/portal/landing-page-ads/';
static String nearbyAdvertisements(String offerId) =>
      URLs.appendBaseUrl('/portal/advertisements/$offerId/nearby/');
static final newsletterSubscribe = URLs.appendBaseUrl('/api/newsletter/subscribe/');
static String nominatimMap(String encodedAddress) =>
      'https://nominatim.openstreetmap.org/search?format=json&q=$encodedAddress';
static String portalBrowseListAdd(String adId) => URLs.appendBaseUrl(
    '/portal/browselist/add/$adId/',
  ); //////////////[POST]///////////////
  static String portalBrowseListRemove(String adId) => URLs.appendBaseUrl(
    '/portal/browselist/remove/$adId/',
  ); //////////////[DELETE]///////////////
  static final portalBrowseListClear = URLs.appendBaseUrl(
    '/portal/browselist/clear/',
  ); //////////////[DELETE]///////////////
  static final portalBrowseList = URLs.appendBaseUrl(
    '/portal/browselist/',
  ); //////////////[GET]///////////////
  ///
  ///
  ///
  ///
  ///
  ////////////////////////////////// Network monitoring url's //////////////////////////////////
  ///
  /// Fetch offers
  /// 
  
static String removeDisplayed(String adId) =>
      URLs.appendBaseUrl('/portal/displayed/remove/$adId/');
static String similarAdvertisements(String offerId) =>
      URLs.appendBaseUrl('/portal/advertisements/$offerId/similar-ads/');
}
