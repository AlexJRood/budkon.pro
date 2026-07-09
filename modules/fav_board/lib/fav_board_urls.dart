import 'package:core/platform/url.dart';

/// fav_board feature API endpoints, decentralized out of core's URLs God-package.
class FavBoardUrls {
  const FavBoardUrls._();

static String deleteFavBoard(String boardId) =>
      URLs.appendBaseUrl('/portal/favorite/boards/$boardId/');
static String deleteMonitoringFavBoard(String boardId) =>
      URLs.appendBaseUrl('/networkmonitoring/favorite/boards/$boardId/');
static final networkAddOrganizeToBoard = URLs.appendBaseUrl(
    '/networkmonitoring/favorite/add/stack/',
  );
static String networkBoardShareLink(String boardId) =>
      URLs.appendBaseUrl('/networkmonitoring/favorite/boards/$boardId/share-link/');
static String networkFavSingleBoard(String boardId) =>
      URLs.appendBaseUrl('/networkmonitoring/favorite/boards/$boardId/');
static final networkFavorite = URLs.appendBaseUrl('/networkmonitoring/favorite/');
static final networkFavoriteBoards = URLs.appendBaseUrl(
    '/networkmonitoring/favorite/boards/',
  );
static final portalAddOrganizeToBoard = URLs.appendBaseUrl(
    '/portal/favorite/add/stack/',
  );
static String portalBoardShareLink(String boardId) =>
      URLs.appendBaseUrl('/portal/favorite/boards/$boardId/share-link/');
static String portalEditBoard(String id) =>
      URLs.appendBaseUrl('/portal/favorite/boards/$id/');
static final portalFavBoards = URLs.appendBaseUrl('/portal/favorite/boards/');
static String portalSimilarAds(String id) =>
      URLs.appendBaseUrl('/portal/advertisements/$id/similar-ads/');
}
