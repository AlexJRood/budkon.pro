import 'dart:convert';
import 'package:fav_board/fav_board_urls.dart';
import 'package:flutter/foundation.dart';

import 'package:fav_board/models/network_brows_list_model.dart';
import 'package:fav_board/models/portal_fav_board_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/user/user/user_provider.dart';

class NetworkBoardsNotifier extends StateNotifier<List<Board>> {
  final Ref ref;
  NetworkBoardsNotifier(this.ref) : super([]);
  bool _hasLoadedOnce = false;
  bool _isLoading = false;
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

  Future<void> fetchNetworkFavBoards() async {
    final previousLength = state.length;

    try {
      if (kDebugMode) print('younis 1');
      final response = await ApiServices.get(
        FavBoardUrls.networkFavoriteBoards,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.data));
        final boardsResponse = BoardsResponse.fromJson(decoded);
        if (kDebugMode) print('younis 2');

        if (_hasLoadedOnce &&
            boardsResponse.results.length == previousLength &&
            state.isNotEmpty) {
          if (kDebugMode) print('⚠️ Skipping reload: already loaded and board count unchanged');
          return;
        }

        if (kDebugMode) print('younis 3');
        if (kDebugMode) print('✅ Network Boards fetched successfully');

        state = boardsResponse.results.map(
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
        ).toList();

        if (kDebugMode) print('younis 4');

        for (int i = 0; i < state.length; i++) {
          final board = state[i];
          final adsResponse = await ApiServices.get(
            FavBoardUrls.networkFavorite,
            ref: ref,
            hasToken: true,
            queryParameters: {'board_id': board.id.toString()},
          );

          List<BoardDetails> adDetails = [];

          if (adsResponse != null && adsResponse.statusCode == 200) {
            if (kDebugMode) print('network fav fetched successfully for board ID: ${board.id}');

            final decodedAds = jsonDecode(utf8.decode(adsResponse.data));
            if (kDebugMode) print('⬇️ Raw Ads Response for board ID ${board.id}');
            if (kDebugMode) print(decodedAds);

            if (decodedAds is Map && decodedAds['results'] is List && decodedAds['results'].isNotEmpty) {
              adDetails = (decodedAds['results'] as List).map((json) {
                final ad = NetworkBrowseListModel.fromJson(json);

                if (kDebugMode) print('✅ Parsed Ad → id: ${ad.id}, title: ${ad.title}, price: ${ad.price}, squareFootage: ${ad.squareFootage}');

                return BoardDetails(
                  id: ad.id,
                  title: ad.title,
                  price: double.tryParse(ad.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                  description: ad.description,
                  advertisementImages: ad.images.images,
                  images: ad.images.images,
                  squareFootage: ad.squareFootage,
                  rooms: ad.rooms ?? 0,
                  bathrooms: ad.bathroomNumber ?? 0,
                  floor: ad.floor ?? 0,
                  totalFloors: ad.floorsNum ?? 0,
                  propertyForm: '',
                  marketType: ad.marketType,
                  offerType: ad.offerType ?? '',
                  country: '',
                  phoneNumber: 'brak numeru',
                  latitude: 0.0,
                  longitude: 0.0,
                  activeValidityDate: DateTime.now(),
                  createdAt: DateTime.now(),
                );
              }).toList();
            } else {
              if (kDebugMode) print('⚠️ No ads found for board ID: ${board.id}');
            }
          } else {
            if (kDebugMode) print('❌ Ads fetch failed for board ID: ${board.id}');
          }


          state = [
            ...state.sublist(0, i),
            state[i].copyWith(advertisements: adDetails),
            ...state.sublist(i + 1),
          ];
        }

        if (kDebugMode) print('younis 5');
        _hasLoadedOnce = true;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Exception while fetching network boards: $e');
    }
  }

  Future<void> createBoard(String title) async {
    if (isLoading) return;
    isLoading = true;
    try {
      final userAsync = await ref.read(userProvider.future);
      if (userAsync?.userId == null) {
        if (kDebugMode) print('❌ User not logged in');
        return;
      }

      final fetchResponse = await ApiServices.get(
        FavBoardUrls.networkFavoriteBoards,
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
          if (kDebugMode) print('❌ Failed to decode boards: $e');
        }
      }

      final data = Board(
        title: title,
        boardIndex: newBoardIndex,
        isLocked: false,
        user: int.parse(userAsync!.userId),
        sharedToUsers: [userAsync.userId.toString()],
      );

      if (kDebugMode) print('younis: ${data.toJson()}');

      final response = await ApiServices.post(
        FavBoardUrls.networkFavoriteBoards,
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
        if (kDebugMode) print('✅ Board added successfully with index $newBoardIndex');
      } else {
        if (kDebugMode) print('❌ Failed to add board - Status: ${response?.statusCode}');
      }
    } catch (e, stack) {
      if (kDebugMode) print('❌ Error while creating board: $e');
      if (kDebugMode) print(stack);
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteBoard(String boardId) async {
    isLoading = true;
    try {
      if (kDebugMode) print(FavBoardUrls.deleteMonitoringFavBoard(boardId));
      final response = await ApiServices.delete(
        FavBoardUrls.deleteMonitoringFavBoard(boardId),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        if (kDebugMode) print('Board deleted successfully');
        removeBoardById(boardId);
      } else {
        if (kDebugMode) print('Board deletion failed');
      }
    } catch (e) {
      if (kDebugMode) print(e);
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

      if (kDebugMode) print(FavBoardUrls.networkFavSingleBoard(boardId));
      if (kDebugMode) print(data.toEditJson());

      final response = await ApiServices.patch(
        FavBoardUrls.networkFavSingleBoard(boardId),
        hasToken: true,
        data: data.toEditJson(),
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) print('Board updated successfully');

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
        if (kDebugMode) print('Board update failed: ${response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error editing board: $e');
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
      if (kDebugMode) print(data);
      if (kDebugMode) print(FavBoardUrls.networkAddOrganizeToBoard);

      final response = await ApiServices.post(
        FavBoardUrls.networkAddOrganizeToBoard,
        hasToken: true,
        data: data,
      );

      if (response != null && response.statusCode == 200) {
        if (kDebugMode) print('✅ Organize added to board successfully');

        // 🔁 Fetch only the new ads
        final adsResponse = await ApiServices.get(
          FavBoardUrls.networkFavorite,
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
              .map<BoardDetails>((json) {
            final ad = NetworkBrowseListModel.fromJson(json);
            return BoardDetails(
              id: ad.id,
              title: ad.title,
              price: double.tryParse(ad.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
              description: ad.description,
              advertisementImages: ad.images.images,
              images: ad.images.images,
              squareFootage: ad.squareFootage,
              rooms: ad.rooms ?? 0,
              bathrooms: ad.bathroomNumber ?? 0,
              floor: ad.floor ?? 0,
              totalFloors: ad.floorsNum ?? 0,
              propertyForm: '',
              marketType: ad.marketType,
              offerType: ad.offerType ?? '',
              country: '',
              phoneNumber: 'brak numeru',
              latitude: 0.0,
              longitude: 0.0,
              activeValidityDate: DateTime.now(),
              createdAt: DateTime.now(),
            );
          }).toList();

          // 🧠 Update state locally, avoiding duplicates
          final updatedBoards = state.map((board) {
            if (board.id == boardId) {
              final existingAds = board.advertisements ?? [];
              final existingAdIds = existingAds.map((ad) => ad.id).toSet();

              // Filter out ads that already exist
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
        if (kDebugMode) print('❌ Organize added to board failed');
        return false;
      }
    } catch (e, stack) {
      if (kDebugMode) print('❌ Exception in addOrganizeToBoard: $e');
      if (kDebugMode) print(stack);
      return false;
    }
  }

  Future<void> networkBoardShareLink(BuildContext context, String boardId,String selectedBoardName) async {
    try {
      final response = await ApiServices.get(
        FavBoardUrls.networkBoardShareLink(boardId),
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

          if (kDebugMode) print('Share link copied: $shareLink');
        } else {
          if (kDebugMode) print('Share link not found');
        }
      } else {
        if (kDebugMode) print('Getting share link failed');
      }
    } catch (e) {
      if (kDebugMode) print('Exception while getting share link: $e');
    }
  }
}


final networkBoardsProvider =
    StateNotifierProvider<NetworkBoardsNotifier, List<Board>>(
      (ref) => NetworkBoardsNotifier(ref),
    );
