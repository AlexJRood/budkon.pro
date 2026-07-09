import 'dart:async';
import 'dart:convert';

import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/user_contact_status_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

final clientStatusesProvider =
    FutureProvider.autoDispose<List<UserContactStatusModel>>((ref) {
  return ref.read(clientProvider.notifier).fetchStatuses(ref);
});

final clientsShouldRefetchProvider = StateProvider<bool>((_) => false);

final clientProvider =
    StateNotifierProvider<ClientNotifier, AsyncValue<List<UserContactModel>>>(
  (ref) => ClientNotifier(ref),
);

class ClientNotifier extends StateNotifier<AsyncValue<List<UserContactModel>>> {
  ClientNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();

    _ref.listen<bool>(clientsShouldRefetchProvider, (prev, next) async {
      if (next == true) {
        await fetchClients();
        if (mounted) {
          _ref.read(clientsShouldRefetchProvider.notifier).state = false;
        }
      }
    });
  }

  bool _lastIncludeTransactionsPreview = true;
  int _lastTransactionsPreviewLimit = 5;
  int _lastTransactionsPreviewOffset = 0;

  final Ref _ref;

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int? _lastStatus;
  String? _lastSort;
  String? _lastSearchQuery;
  List<int>? _lastContactTypeIds;

  String? _lastRawResponse;

  static const int _pageSize = 30;
  static const Object _unset = Object();

  void _setDataSafe(List<UserContactModel> clients, {bool append = false}) {
    if (!mounted) return;

    if (append && state is AsyncData<List<UserContactModel>>) {
      final existing = (state as AsyncData<List<UserContactModel>>).value;
      state = AsyncValue.data([...existing, ...clients]);
    } else {
      state = AsyncValue.data(clients);
    }
  }

  void _setErrorSafe(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    state = AsyncValue.error(error, stackTrace);
  }

  Future<void> _init() async {
    try {
      await Future.wait([
        fetchStatuses(_ref),
        fetchClients(
          includeTransactionsPreview: true,
          transactionsPreviewLimit: 5,
          transactionsPreviewOffset: 0,
        ),
      ]);
    } catch (_) {}
  }

  Future<void> refreshStatuses() async {
    _ref.invalidate(clientStatusesProvider);
    await _ref.read(clientStatusesProvider.future);
  }

  Future<List<UserContactStatusModel>> fetchStatuses(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        ref: _ref,
        URLs.addUserContactsStatuses,
        hasToken: true,
      );

      if (response?.data == null) {
        throw Exception('No response or data is null');
      }

      if (response!.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final listingsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
        final statusesResults = listingsJson['results'] as List<dynamic>;

        final statuses = statusesResults
            .map(
              (item) => UserContactStatusModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        return statuses;
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load statuses: $error');
    }
  }

  String? _orderingFromUiKey(String? key) {
    switch (key) {
      case 'date_created_desc':
      case 'date_create_desc':
        return '-date_created';
      case 'date_created_asc':
      case 'date_create_asc':
        return 'date_created';
      case 'last_updated_desc':
      case 'date_update_desc':
        return '-last_updated';
      case 'last_updated_asc':
      case 'date_update_asc':
        return 'last_updated';
    }
    return null;
  }

  bool _isLastViewedDescSort(String? sort) {
    final normalized = (sort ?? '').trim();
    return normalized.isEmpty ||
        normalized == 'last_viewed_desc' ||
        normalized == 'last_viewed';
  }

  bool get isLastViewedDescSortActive => _isLastViewedDescSort(_lastSort);

  void _updateOpenedClientInPlace(
    int contactId, {
    DateTime? viewedAt,
    int? viewsCount,
    bool incrementViewCount = false,
  }) {
    if (!mounted) return;

    final current = state;
    if (current is! AsyncData<List<UserContactModel>>) return;

    final list = List<UserContactModel>.from(current.value);
    final index = list.indexWhere((c) => c.id == contactId);
    if (index == -1) return;

    final old = list[index];

    list[index] = old.copyWith(
      lastViewedAtMe: viewedAt ?? old.lastViewedAtMe ?? DateTime.now(),
      viewsCountMe: viewsCount ??
          (incrementViewCount
              ? ((old.viewsCountMe ?? 0) + 1)
              : old.viewsCountMe),
    );

    state = AsyncValue.data(list);
  }

  void moveClientToTopLocally(
    int contactId, {
    DateTime? viewedAt,
    bool incrementViewCount = true,
  }) {
    if (!mounted) return;

    final current = state;
    if (current is! AsyncData<List<UserContactModel>>) return;

    if (!isLastViewedDescSortActive) {
      _updateOpenedClientInPlace(
        contactId,
        viewedAt: viewedAt,
        incrementViewCount: incrementViewCount,
      );
      return;
    }

    final list = List<UserContactModel>.from(current.value);
    final index = list.indexWhere((c) => c.id == contactId);
    if (index == -1) return;

    final old = list.removeAt(index);

    final updated = old.copyWith(
      lastViewedAtMe: viewedAt ?? DateTime.now(),
      viewsCountMe:
          incrementViewCount ? ((old.viewsCountMe ?? 0) + 1) : old.viewsCountMe,
    );

    list.insert(0, updated);
    state = AsyncValue.data(list);
  }

  void applyOpenedClientServerData(
    int contactId, {
    DateTime? lastViewedAt,
    int? viewsCount,
  }) {
    if (!mounted) return;

    final current = state;
    if (current is! AsyncData<List<UserContactModel>>) return;

    if (!isLastViewedDescSortActive) {
      _updateOpenedClientInPlace(
        contactId,
        viewedAt: lastViewedAt,
        viewsCount: viewsCount,
      );
      return;
    }

    final list = List<UserContactModel>.from(current.value);
    final index = list.indexWhere((c) => c.id == contactId);
    if (index == -1) return;

    final old = list.removeAt(index);

    final updated = old.copyWith(
      lastViewedAtMe: lastViewedAt ?? old.lastViewedAtMe ?? DateTime.now(),
      viewsCountMe: viewsCount ?? old.viewsCountMe,
    );

    list.insert(0, updated);
    state = AsyncValue.data(list);
  }

  Future<void> fetchClients({
    Object? status = _unset,
    Object? sort = _unset,
    Object? searchQuery = _unset,
    Object? contactTypeIds = _unset,
    Object? includeTransactionsPreview = _unset,
    Object? transactionsPreviewLimit = _unset,
    Object? transactionsPreviewOffset = _unset,
    bool append = false,
    bool silentIfUnchanged = false,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      if (!identical(status, _unset)) {
        _lastStatus = status as int?;
      }
      if (!identical(sort, _unset)) {
        _lastSort = sort as String?;
      }
      if (!identical(searchQuery, _unset)) {
        final q = (searchQuery as String?)?.trim();
        _lastSearchQuery = (q == null || q.isEmpty) ? null : q;
      }
      if (!identical(contactTypeIds, _unset)) {
        _lastContactTypeIds =
            (contactTypeIds as List<int>?)?.whereType<int>().toList();
      }
      if (!identical(includeTransactionsPreview, _unset)) {
        _lastIncludeTransactionsPreview =
            (includeTransactionsPreview as bool?) ?? false;
      }
      if (!identical(transactionsPreviewLimit, _unset)) {
        _lastTransactionsPreviewLimit =
            (transactionsPreviewLimit as int?) ?? 5;
      }
      if (!identical(transactionsPreviewOffset, _unset)) {
        _lastTransactionsPreviewOffset =
            (transactionsPreviewOffset as int?) ?? 0;
      }

      final ordering = _orderingFromUiKey(_lastSort);
      final nextPage = append ? (_currentPage + 1) : 1;

      final queryParams = <String, dynamic>{
        'page': nextPage,
        'page_size': _pageSize,
        if (ordering != null) 'ordering': ordering,
        if (ordering == null && _lastSort != null) 'sort': _lastSort,
        if (_lastSearchQuery != null) 'search': _lastSearchQuery,
        if (_lastStatus != null) 'status': _lastStatus,
        if (_lastIncludeTransactionsPreview)
          'include_transactions_preview': 'true',
        if (_lastIncludeTransactionsPreview)
          'transactions_preview_limit': _lastTransactionsPreviewLimit,
        if (_lastIncludeTransactionsPreview &&
            _lastTransactionsPreviewOffset > 0)
          'transactions_preview_offset': _lastTransactionsPreviewOffset,
        if (_lastContactTypeIds != null && _lastContactTypeIds!.isNotEmpty)
          if (_lastContactTypeIds!.length == 1)
            'contact_type': _lastContactTypeIds!.first
          else
            'contact_type__in': _lastContactTypeIds!.join(','),
      };

      if (kDebugMode) debugPrint('Clients QP: $queryParams');

      final response = await ApiServices.get(
        ref: _ref,
        URLs.userContacts,
        queryParameters: queryParams,
        hasToken: true,
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200) {
        final raw = response.data is String
            ? response.data as String
            : utf8.decode(response.data as List<int>);

        if (!append && silentIfUnchanged && raw == _lastRawResponse) {
          if (kDebugMode) {
            debugPrint('ClientNotifier: no changes detected (page 1).');
          }
          return;
        }

        _lastRawResponse = raw;

        final listingsJson = json.decode(raw) as Map<String, dynamic>;
        final newList =
            (listingsJson['results'] as List).cast<Map<String, dynamic>>();

        final clients =
            newList.map((item) => UserContactModel.fromJson(item)).toList();

        _currentPage = nextPage;
        _hasMore = listingsJson['next'] != null;

        if (append) {
          _setDataSafe(clients, append: true);
        } else {
          _currentPage = 1;
          _setDataSafe(clients);
        }
      } else {
        if (!silentIfUnchanged) {
          _setErrorSafe('Failed to load contacts', StackTrace.current);
        }
      }
    } catch (error, stackTrace) {
      if (!silentIfUnchanged) {
        _setErrorSafe(error, stackTrace);
      } else {
        if (kDebugMode) {
          debugPrint('ClientNotifier (silent) error: $error');
        }
      }
    } finally {
      _isFetching = false;
    }
  }

  void markClientsDirty() {
    if (!mounted) return;
    _ref.read(clientsShouldRefetchProvider.notifier).state = true;
  }

  Future<void> refreshClients() async {
    await fetchClients(silentIfUnchanged: false);
    await fetchStatuses(_ref);
  }

  Future<List<UserContactModel>> fetchClientsList({
    int? status,
    String? sort,
    String? searchQuery,
  }) async {
    try {
      _lastStatus = status ?? _lastStatus;
      _lastSort = sort ?? _lastSort;
      _lastSearchQuery = searchQuery ?? _lastSearchQuery;

      final queryParams = {
        'page': 1,
        'page_size': _pageSize,
        if (_lastStatus != null) 'status': _lastStatus,
        if (_lastSort != null) 'sort': _lastSort,
        if (_lastSearchQuery != null) 'search': _lastSearchQuery,
      };

      if (kDebugMode) {
        debugPrint(
          'Mahdi: fetchClientsList: $queryParams : ${URLs.userContacts}',
        );
      }

      final response = await ApiServices.get(
        ref: _ref,
        URLs.userContacts,
        queryParameters: queryParams,
        hasToken: true,
      );

      if (!mounted) return [];

      if (response != null && response.statusCode == 200) {
        final raw = utf8.decode(response.data);
        _lastRawResponse = raw;

        final listingsJson = json.decode(raw) as Map<String, dynamic>;
        final newList = listingsJson['results'] as List<dynamic>;

        final clients = newList
            .map(
              (item) => UserContactModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        _currentPage = 1;
        _hasMore = listingsJson['next'] != null;

        _setDataSafe(clients);
        return clients;
      } else {
        throw Exception("API error: ${response?.statusCode}");
      }
    } catch (error, stackTrace) {
      _setErrorSafe(error, stackTrace);
      if (kDebugMode) debugPrint("Error in fetchClientsList: $error");
      return [];
    }
  }

  Future<void> addClient(UserContactModel client) async {
    final response = await ApiServices.post(
      URLs.clientsCreate,
      data: client.toCreateJson(),
      hasToken: true,
    );

    if (!mounted) return;

    if (response != null && response.statusCode == 201) {
      markClientsDirty();
    } else {
      throw Exception('Failed to create client (HTTP ${response?.statusCode})');
    }
  }

  Future<void> updateClient(int id, UserContactModel client) async {
    try {
      final response = await ApiServices.put(
        URLs.clientsUpdate('$id'),
        data: client.toJson(),
        hasToken: true,
      );

      if (!mounted) return;

      if (response == null) {
        _setErrorSafe(Exception('Invalid request.'), StackTrace.current);
        return;
      }

      markClientsDirty();
    } catch (error, stackTrace) {
      _setErrorSafe(error, stackTrace);
    }
  }

  Future<void> patchClient(int id, Map<String, dynamic> patch) async {
    try {
      final resp = await ApiServices.patch(
        URLs.clientsUpdate('$id'),
        hasToken: true,
        data: patch,
      );

      if (!mounted) return;

      if (resp != null &&
          resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        final current = state;
        if (current is AsyncData<List<UserContactModel>>) {
          final list = current.value;
          final idx = list.indexWhere((c) => c.id == id);
          if (idx != -1) {
            final updated = List<UserContactModel>.from(list);
            final old = updated[idx];

            updated[idx] = UserContactModel(
              id: old.id,
              favoriteBoards: old.favoriteBoards,
              invoiceData: old.invoiceData,
              secureData: old.secureData,
              isStar: old.isStar,
              avatar: old.avatar,
              name: old.name,
              lastName: old.lastName,
              email: old.email,
              phoneNumber: old.phoneNumber,
              gender: old.gender,
              birthDate: old.birthDate,
              nationality: old.nationality,
              description: old.description,
              note: old.note,
              dateCreated: old.dateCreated,
              lastUpdated: DateTime.now(),
              contactType: patch.containsKey('contact_type')
                  ? patch['contact_type'] as int?
                  : old.contactType,
              contactStatus: patch.containsKey('contact_status')
                  ? patch['contact_status']?.toString()
                  : old.contactStatus,
              serviceType: patch.containsKey('service_type')
                  ? patch['service_type']?.toString()
                  : old.serviceType,
              createdBy: old.createdBy,
              responsiblePerson: old.responsiblePerson,
              transactionsPreview: old.transactionsPreview,
              lastViewedAtMe: old.lastViewedAtMe,
              viewsCountMe: old.viewsCountMe,
            );

            _setDataSafe(updated);
          }
        }

        markClientsDirty();
      } else {
        throw Exception('PATCH failed: ${resp?.statusCode}');
      }
    } catch (e, st) {
      _setErrorSafe(e, st);
      rethrow;
    }
  }

  Future<void> patchClientContactType(int id, int? contactTypeId) async {
    await patchClient(id, {'contact_type': contactTypeId});
  }

  Future<void> patchClientServiceType(int id, int? serviceTypeId) async {
    await patchClient(id, {'service_type': serviceTypeId});
  }

  Future<void> patchClientStatusId(int id, int? statusId) async {
    await patchClient(id, {'contact_status': statusId});
  }

  Future<void> deleteClient(int id) async {
    try {
      final response = await ApiServices.delete(
        URLs.clientsDelete('$id'),
        hasToken: true,
      );

      if (!mounted) return;

      if (response == null) {
        _setErrorSafe(Exception('Invalid request.'), StackTrace.current);
        return;
      }

      markClientsDirty();
    } catch (error, stackTrace) {
      _setErrorSafe(error, stackTrace);
    }
  }

  Future<void> updateClientStatus(int id, int newStatus) async {
    try {
      final response = await ApiServices.post(
        URLs.userContactStatusUpdate(id),
        hasToken: true,
        data: {'status': newStatus},
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200) {
        fetchStatuses(_ref);
        markClientsDirty();
      } else {
        throw Exception('Failed to update status');
      }
    } catch (error, stackTrace) {
      _setErrorSafe(error, stackTrace);
      rethrow;
    }
  }
}