import 'dart:convert';
import 'package:fav_board/fav_board_urls.dart';
import 'package:fav_board/models/portal_fav_board_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:flutter/foundation.dart';

import 'network_board_provider.dart';

class PortalBoardsNotifier extends StateNotifier<List<Board>> {
  final Ref ref;
  PortalBoardsNotifier(this.ref) : super([]);

  bool _hasLoadedOnce = false;
  bool _isLoading = false;
  final Map<int, List<BoardDetails>> _similarAdsMap = {};
  final Set<int> _similarLoadedBoards = <int>{};
  final Map<int, bool> _similarLoading = <int, bool>{};
  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    state = [...state];
  }

  void addBoard(Board board) {
    state = [...state, board];
  }

  void removeBoard(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void removeBoardById(String boardId) {
    state = state.where((board) => board.id.toString() != boardId).toList();
  }

  Future<void> fetchPortalBoards() async {
    final previousLength = state.length;

    try {
      final response = await ApiServices.get(
        FavBoardUrls.portalFavBoards,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.data));
        final boardsResponse = BoardsResponse.fromJson(decoded);

        if (_hasLoadedOnce &&
            boardsResponse.results.length == previousLength &&
            state.isNotEmpty) {
          if (kDebugMode) debugPrint('⚠️ Skipping reload: already loaded and board count unchanged');
          return;
        }

        if (kDebugMode) debugPrint('✅ Boards fetched successfully');

        state =
            boardsResponse.results
                .map(
                  (b) => Board(
                    id: b.id,
                    title: b.title,
                    description: b.description,
                    dataDodania: b.dataDodania,
                    boardIndex: b.boardIndex,
                    isLocked: b.isLocked,
                    user: b.user,
                    client: b.client,
                    savedSearch: b.savedSearch,
                    advertisements: [],
                  ),
                )
                .toList();

        for (int i = 0; i < state.length; i++) {
          final board = state[i];
          final adsResponse = await ApiServices.get(
            URLs.apiFavorite,
            ref: ref,
            hasToken: true,
            queryParameters: {'board_id': board.id.toString()},
          );

          List<BoardDetails> adDetails = [];
          if (adsResponse != null && adsResponse.statusCode == 200) {
            final decodedAds = jsonDecode(utf8.decode(adsResponse.data));
            if (decodedAds is Map && decodedAds['results'] is List) {
              adDetails =
                  (decodedAds['results'] as List)
                      .map((json) => BoardDetails.fromJson(json))
                      .toList();

              // for (final ad in adDetails) {
              //   fetchSimilarAds(ad.id.toString(), board.id!);
              // }
            } else {
              if (kDebugMode) debugPrint('⚠️ Unexpected ads format: $decodedAds');
            }
          } else {
            if (kDebugMode) debugPrint('❌ Ads fetch failed for board ID ${board.id}');
          }
          state = [
            ...state.sublist(0, i),
            state[i].copyWith(advertisements: adDetails),
            ...state.sublist(i + 1),
          ];
        }
        _hasLoadedOnce = true;
      } else {
        if (kDebugMode) debugPrint('❌ Boards fetch failed: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Exception while fetching boards: $e');
    }
  }

// [CHANGE 5A] REPLACE the whole fetchSimilarAds method with this
// [FIX 1B] REPLACE fetchSimilarAds with this version
  Future<void> fetchSimilarAds(String adId, int boardId) async {
    try {
      final response = await ApiServices.get(
        FavBoardUrls.portalSimilarAds(adId),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.data));

        // Accept both: a raw list OR {results: [...]}
        final List<dynamic> rawList = decoded is List
            ? decoded
            : (decoded is Map && decoded['results'] is List)
            ? (decoded['results'] as List)
            : const [];

        if (rawList.isNotEmpty) {
          final incoming = rawList
              .map<BoardDetails?>((json) {
            try {
              return BoardDetails.fromJson(json);
            } catch (_) {
              return null;
            }
          })
              .whereType<BoardDetails>()
              .toList();

          // Merge + dedupe by id
          final existing = _similarAdsMap[boardId] ?? const <BoardDetails>[];
          final existingIds = existing.map((e) => e.id).toSet();
          final uniqueNew = incoming.where((a) => !existingIds.contains(a.id)).toList();

          if (uniqueNew.isNotEmpty) {
            _similarAdsMap[boardId] = [...existing, ...uniqueNew];
            if (kDebugMode) {
              debugPrint('🟦 Similar ads for board $boardId → +${uniqueNew.length} (total ${_similarAdsMap[boardId]!.length})');
            }
            // 🔔 IMPORTANT: notify watchers so selectedBoardSimilarAdsProvider rebuilds
            state = [...state];
          }
        } else {
          if (kDebugMode) debugPrint('⚠️ Similar ads empty for ad $adId (board $boardId)');
        }
      } else {
        if (kDebugMode) debugPrint('⚠️ Failed to fetch similar ads for ad $adId (board $boardId)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Exception while fetching similar ads: $e');
    }
  }

  Future<void> ensureSimilarForBoard(int boardId) async {
    // Prevent duplicate concurrent loads
    if (_similarLoading[boardId] == true) return;
    _similarLoading[boardId] = true;

    try {
      // If we already loaded similar ads for this board once, skip
      if (_similarLoadedBoards.contains(boardId)) return;

      // 1) Make sure the board exists in state
      final idx = state.indexWhere((b) => b.id == boardId);
      if (idx == -1) return;

      var board = state[idx];

      // 2) If this board has no ads loaded yet, fetch its ads first
      if ((board.advertisements ?? []).isEmpty) {
        final adsResponse = await ApiServices.get(
          URLs.apiFavorite,
          ref: ref,
          hasToken: true,
          queryParameters: {'board_id': boardId.toString()},
        );

        if (adsResponse != null && adsResponse.statusCode == 200) {
          final decodedAds = jsonDecode(utf8.decode(adsResponse.data));
          if (decodedAds is Map && decodedAds['results'] is List) {
            final adDetails = (decodedAds['results'] as List)
                .map((json) => BoardDetails.fromJson(json))
                .toList();

            // Update state for that board with its ads
            state = [
              ...state.sublist(0, idx),
              state[idx].copyWith(advertisements: adDetails),
              ...state.sublist(idx + 1),
            ];
            board = state[idx];
          }
        }
      }

      // 3) Fetch similar ads for each ad on this board
      final ads = board.advertisements ?? const <BoardDetails>[];
      for (final ad in ads) {
        if (ad.id != null) {
          await fetchSimilarAds(ad.id.toString(), boardId);
        }
      }

      _similarLoadedBoards.add(boardId);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ensureSimilarForBoard error: $e');
    } finally {
      _similarLoading[boardId] = false;
    }
  }

  void invalidateSimilarForBoard(int boardId) {
    _similarLoadedBoards.remove(boardId);
    _similarAdsMap.remove(boardId);
  }


  List<BoardDetails> getSimilarAdsForBoard(int boardId) {
    final list = _similarAdsMap[boardId];
    if (list == null) return [];
    return list.whereType<BoardDetails>().toList(); // ensures type safety
  }

  Future<void> createBoard(String title) async {
    if (isLoading) return;
    isLoading = true;
    try {
      final userAsync = await ref.read(userProvider.future);
      if (userAsync?.userId == null) {
        if (kDebugMode) debugPrint('❌ User not logged in');
        return;
      }

      final fetchResponse = await ApiServices.get(
        FavBoardUrls.portalFavBoards,
        ref: ref,
        hasToken: true,
      );

      int newBoardIndex = 0;

      if (fetchResponse != null &&
          fetchResponse.statusCode == 200 &&
          fetchResponse.data != null) {
        try {
          final decoded = jsonDecode(utf8.decode(fetchResponse.data));
          final boardsResponse = BoardsResponse.fromJson(decoded);

          if (boardsResponse.results.isNotEmpty) {
            final maxIndex = boardsResponse.results
                .map((b) => b.boardIndex ?? 0)
                .fold<int>(0, (prev, curr) => curr > prev ? curr : prev);
            newBoardIndex = maxIndex + 1;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Failed to decode boards: $e');
        }
      }

      final data = Board(
        title: title,
        boardIndex: newBoardIndex,
        isLocked: false,
        user: int.parse(userAsync!.userId),
        sharedToUsers: [userAsync.userId.toString()],
      );

      if (kDebugMode) debugPrint('younis: ${data.toJson()}');

      final response = await ApiServices.post(
        FavBoardUrls.portalFavBoards,
        hasToken: true,
        data: data.toJson(),
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final createdBoard = Board.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : jsonDecode(utf8.decode(response.data)),
        );
        addBoard(createdBoard);
        if (kDebugMode) debugPrint('✅ Board added successfully with index $newBoardIndex');
      } else {
        if (kDebugMode) debugPrint('❌ Failed to add board - Status: ${response?.statusCode}');
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('❌ Error while creating board: $e');
      if (kDebugMode) debugPrint(stack.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteBoard(String boardId) async {
    isLoading = true;
    try {
      final response = await ApiServices.delete(
        FavBoardUrls.deleteFavBoard(boardId),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        if (kDebugMode) debugPrint('Board deleted successfully');
        removeBoardById(boardId);
      } else {
        if (kDebugMode) debugPrint('Board deletion failed');
      }
    } catch (e) {
      if (kDebugMode) debugPrint(e.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<void> editBoard(
    String boardId,
    String boardName,
    String boardDescription,
    int boardIndex,
  ) async {
    if (isLoading) return;
    isLoading = true;
    try {
      final data = Board(
        id: int.tryParse(boardId),
        title: boardName,
        description: boardDescription,
        boardIndex: boardIndex,
      );

      if (kDebugMode) debugPrint(FavBoardUrls.portalEditBoard(boardId));
      if (kDebugMode) debugPrint(data.toEditJson().toString());

      final response = await ApiServices.patch(
        FavBoardUrls.portalEditBoard(boardId),
        hasToken: true,
        data: data.toEditJson(),
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) debugPrint('Board updated successfully');

        final updatedBoards =
            state.map((board) {
              if (board.id.toString() == boardId) {
                return board.copyWith(
                  title: boardName,
                  description: boardDescription,
                  boardIndex: boardIndex,
                );
              }
              return board;
            }).toList();

        state = updatedBoards;
      } else {
        if (kDebugMode) debugPrint('Board update failed: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error editing board: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<bool> addOrganizeToBoard(List<int> adsIds, int boardId) async {
    try {
      final data = {
        "ads_ids": adsIds,
        "board_id": boardId,
      };
      if (kDebugMode) debugPrint(data.toString());
      if (kDebugMode) debugPrint(FavBoardUrls.portalAddOrganizeToBoard);

      final response = await ApiServices.post(
        FavBoardUrls.portalAddOrganizeToBoard,
        hasToken: true,
        data: data,
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) debugPrint('✅ Organize added to portal board successfully');

        // Fetch only the new ads for this board
        final adsResponse = await ApiServices.get(
          URLs.apiFavorite,
          ref: ref,
          hasToken: true,
          queryParameters: {
            'board_id': boardId.toString(),
            'ads_ids': adsIds.map((id) => id.toString()).join(','),
          },
        );

        if (adsResponse != null && adsResponse.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(adsResponse.data));

          final List<BoardDetails> newAds = (decoded['results'] as List)
              .map<BoardDetails>((json) => BoardDetails.fromJson(json))
              .toList();

          // Update state locally, avoiding duplicates
          final updatedBoards = state.map((board) {
            if (board.id == boardId) {
              final existingAds = board.advertisements ?? [];
              final existingAdIds = existingAds.map((ad) => ad.id).toSet();

              final uniqueNewAds = newAds.where((ad) => !existingAdIds.contains(ad.id)).toList();
              final updatedAds = [...existingAds, ...uniqueNewAds];

              return board.copyWith(advertisements: updatedAds);
            }
            return board;
          }).toList();

          state = updatedBoards;
        }

        return true;
      } else {
        if (kDebugMode) debugPrint('❌ Organize added to board failed');
        return false;
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('❌ Exception in portal addOrganizeToBoard: $e');
      if (kDebugMode) debugPrint(stack.toString());
      return false;
    }
  }

  Future<void> portalBoardShareLink(BuildContext context, String boardId,String selectedBoardName) async {
    try {
      final response = await ApiServices.get(
        FavBoardUrls.portalBoardShareLink(boardId),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.data));
        final shareLink = decoded['share_link'] ?? '';

        if (shareLink.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: shareLink));

  if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedBoardName.toUpperCase()} Link copied successfully'),
              backgroundColor: Colors.green,
            ),
          );

          if (kDebugMode) debugPrint('Share link copied: $shareLink');
        } else {
          if (kDebugMode) debugPrint('Share link not found');
        }
      } else {
        if (kDebugMode) debugPrint('Getting share link failed');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Exception while getting share link: $e');
    }
  }}

final portalBoardsProvider =
    StateNotifierProvider<PortalBoardsNotifier, List<Board>>((ref) {
      return PortalBoardsNotifier(ref);
    });

final selectedSortProvider = StateProvider<String>(
  (ref) => 'price_low_to_high',
);
final selectedBoardIdProvider = StateProvider<int?>((ref) => null);

final selectedBoardProvider = Provider<Board?>((ref) {
  final selectedTabIndex = ref.watch(selectedTabProvider);
  final boards =
      selectedTabIndex == 0
          ? ref.watch(portalBoardsProvider)
          : ref.watch(networkBoardsProvider);
  final selectedId = ref.watch(selectedBoardIdProvider);
  if (boards.isEmpty) return null;
  if (selectedId == null) {
    Future.microtask(() {
      ref.read(selectedBoardIdProvider.notifier).state = boards.first.id;
    });
    return null;
  }

  return boards.firstWhere(
    (b) => b.id == selectedId,
    orElse: () => boards.first,
  );
});

final selectedPropertyTypeProvider = StateProvider<String?>((ref) => null);
final hoveredBoardIdProvider = StateProvider<int?>((ref) => null);

// [FIX 2] REPLACE selectedBoardSimilarAdsProvider
final selectedBoardSimilarAdsProvider = Provider<List<BoardDetails>>((ref) {
  final tab = ref.watch(selectedTabProvider); // force rebuild on tab change
  if (tab != 0) return []; // similar ads currently only for portal boards

  final boards = ref.watch(portalBoardsProvider);
  final selectedId = ref.watch(selectedBoardIdProvider);
  final notifier = ref.read(portalBoardsProvider.notifier);

  if (boards.isEmpty) return [];
  if (selectedId == null) {
    Future.microtask(() {
      if (boards.isNotEmpty) {
        ref.read(selectedBoardIdProvider.notifier).state = boards.first.id;
      }
    });
    return [];
  }

  return notifier.getSimilarAdsForBoard(selectedId);
});


final selectedTabProvider = StateProvider<int>((ref) => 0);
// [CHANGE 2A] ADD: FutureProvider you call from the Board Details screen
final similarAdsForBoardProvider = FutureProvider.family<void, int>((ref, boardId) async {
  await ref.read(portalBoardsProvider.notifier).ensureSimilarForBoard(boardId);
});
