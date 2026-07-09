import 'package:core/platform/url.dart';

/// network_monitoring feature API endpoints, decentralized out of core's URLs God-package.
class NetworkMonitoringUrls {
  const NetworkMonitoringUrls._();

static String addFavoriteNetwork(String adId) =>
      URLs.appendBaseUrl('/networkmonitoring/favorite/add/$adId/');
static String addHideMonitoring(String adId) =>
      URLs.appendBaseUrl('/networkmonitoring/hide/add/$adId/');
static String advertiseMonitoring(String adId) =>
      URLs.appendBaseUrl('/networkmonitoring/advertisements/$adId');
static String clientSavedSearch(String clientId, String savedSearchId) =>
      URLs.appendBaseUrl('/contacts/$clientId/add_saved_searches/$savedSearchId/');
static String deleteSavedSearch(String savedSearchId) =>
      URLs.appendBaseUrl('/saved_searches/$savedSearchId/delete/');
static final fetchNetworkSavedSearches = URLs.appendBaseUrl(
    '/networkmonitoring/user-search-history/',
  );
static String markAdInactive(String adId) =>
      URLs.appendBaseUrl('/space/mark-ad-inactive/$adId/');
static String monitoringDisplay(String adId) =>
      URLs.appendBaseUrl('/networkmonitoring/displayed/add/$adId/?sort=date_asc');
static final networkMonitoring = URLs.appendBaseUrl(
    '/networkmonitoring/displayed/?sort=date_asc',
  );
static String networkMonitoringBrowseListAdd(String adId) => URLs.appendBaseUrl(
    '/networkmonitoring/browselist/add/$adId/',
  ); //////////////[POST]///////////////

  static String networkMonitoringBrowseListRemove(String adId) => URLs.appendBaseUrl(
    '/networkmonitoring/browselist/remove/$adId/',
  ); //////////////[DELETE]///////////////

  static final networkMonitoringBrowseListClear = URLs.appendBaseUrl(
    '/networkmonitoring/browselist/clear/global/',
  ); //////////////[DELETE]///////////////

  static String networkMonitoringBrowseListClearClient(String clientId) =>
      URLs.appendBaseUrl(
        '/networkmonitoring/browselist/clear/client/$clientId/',
      ); //////////////[DELETE]///////////////

  static String networkMonitoringBrowseListClearTransaction(
    String transactionId,
  ) => URLs.appendBaseUrl(
    '/networkmonitoring/browselist/clear/transaction/$transactionId/',
  ); //////////////[DELETE]///////////////

  static final networkMonitoringBrowseList = URLs.appendBaseUrl(
    '/networkmonitoring/browselist/',
  ); //////////////[GET]///////////////
  //////////////[query_params]//////////////
  ///
  /// GET /networkmonitoring/browselist/
  ///
  /// Returns the user’s “Browse List” ads with optional scope selection
  /// and filters.
  ///
  /// Authorization:
  ///   - Requires `Authorization: Bearer <token>` (or your configured scheme).
  ///
  /// Query params (all optional unless stated otherwise):
  ///   - scope: String         — 'global' | 'client' | 'transaction'
  ///                              • default: 'global'
  ///                              • 'global' excludes items linked to a client/transaction
  ///   - client_id: int        — required when scope='client'
  ///   - transaction_id: int   — required when scope='transaction'
  ///
  ///   — Text filters (case-insensitive, comma-separated values):
  ///     - offer_type: String      e.g. "rent,sale"
  ///     - market_type: String     e.g. "primary,secondary"
  ///     - estate_type: String     e.g. "flat,house,plot"
  ///
  ///   — Numeric filters:
  ///     - min_price: double
  ///     - max_price: double
  ///     - min_square_footage: double
  ///     - max_square_footage: double
  ///
  ///   — Sorting (param `sort`):
  ///     - 'price_asc'    — ascending by price
  ///     - 'price_desc'   — descending by price
  ///     - 'date_asc'     — ascending by date added to Browse List
  ///     - 'date_desc'    — descending by date added to Browse List
  ///     - 'area_asc'     — ascending by area
  ///     - 'area_desc'    — descending by area
  ///
  /// Notes:
  ///   - Endpoint is NOT paginated (no `page/size`) — returns all items after filters.
  ///   - `price` / `square_footage` are cast to float server-side for filtering/sorting.
  ///   - When scope='global', only records without client/transaction are returned.
  ///
  /// Status codes:
  ///   - 200 OK
  ///   - 400 Bad Request — invalid scope or missing required IDs
  ///   - 401 Unauthorized
  ///   - 500 Internal Server Error
  ///
  /// Examples:
  ///   • Global (default):
  ///     GET /networkmonitoring/browselist/
  ///
  ///   • Global with filters:
  ///     GET /networkmonitoring/browselist/?offer_type=rent,sale&min_price=300000&sort=price_desc
  ///
  ///   • For client (id=12):
  ///     GET /networkmonitoring/browselist/?scope=client&client_id=12&estate_type=flat
  ///
  ///   • For transaction (id=42):
  ///     GET /networkmonitoring/browselist/?scope=transaction&transaction_id=42&sort=date_desc
  ///
  /// Sample 200 response (truncated):
  /// [
  ///   {
  ///     "id": 101,
  ///     "url": "https://example.com/ad/101",
  ///     "title": "2 rooms, city center",
  ///     "price": "489000",
  ///     "currency": "PLN",
  ///     "square_footage": "45",
  ///     "offer_type": "sale",
  ///     "market_type": "secondary",
  ///     "estate_type": "flat",
  ///     "address": "Warsaw, Śródmieście",
  ///     "browse_added_at": "2025-08-16T14:33:12Z"
  ///   }
static String removeFavoriteNetwork(String adId) =>
      URLs.appendBaseUrl('/networkmonitoring/favorite/remove/$adId/');
static String removeHideMonitoring(String adId) =>
      URLs.appendBaseUrl('/networkmonitoring/hide/remove/$adId/');
static String removeMonitoring(String adId) =>
      URLs.appendBaseUrl('/networkmonitoring/displayed/remove/$adId');
static final requestActiveCheck = URLs.appendBaseUrl(
    '/space/request-active-check/',
  );
static final savedSearches = URLs.appendBaseUrl('/saved_searches/');
}
