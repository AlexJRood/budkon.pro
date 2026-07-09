// association_member_provider.dart
// Uses your ApiServices (Dio) instead of http.
// Comments in English per your preference.

import 'package:association/models/members_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/url.dart';
import 'package:dio/dio.dart';
import 'package:core/platform/api_services.dart'; // <- path to your ApiServices

/// --- DRF pagination DTO ---
class PageDto<T> {
  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  PageDto({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });
}

/// --- API Repository using your ApiServices (Dio) ---
class AssociationMemberApi {
  AssociationMemberApi(this.ref);

  final Ref ref;
  static const String _path = '/association/members/';
  String get _base => URLs.baseUrl; // e.g. https://www.superbee.cloud/api
  String _url([String? extra]) => '$_base$_path${extra ?? ""}';

  /// List with DRF pagination & optional filters.
  Future<PageDto<AssociationMemberModel>> list({
    int? associationId,
    String? status, // 'active' | 'suspended' | 'pending' | 'former'
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (associationId != null) 'association_id': associationId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final Response? resp = await ApiServices.get(
      _url(),
      queryParameters: query,
      hasToken: true,
      responseType: ResponseType.json, // important: expect JSON
      ref: ref,
    );

    if (resp != null && resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
      final data = resp.data as Map<String, dynamic>;
      final items = (data['results'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AssociationMemberModel.fromJson)
          .toList();

      return PageDto<AssociationMemberModel>(
        results: items,
        count: (data['count'] as int?) ?? items.length,
        next: data['next'] as String?,
        previous: data['previous'] as String?,
      );
    }

    throw Exception('Failed to load members: ${resp?.statusCode} ${resp?.data}');
  }

  Future<AssociationMemberModel> retrieve(String uuid) async {
    final Response? resp = await ApiServices.get(
      _url('$uuid/'),
      hasToken: true,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (resp != null && resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
      return AssociationMemberModel.fromJson(resp.data as Map<String, dynamic>);
    }
    throw Exception('Failed to get member $uuid: ${resp?.statusCode} ${resp?.data}');
  }

  /// Create member using either an existing userId OR an inline user_contact payload.
  /// Backend expects `association_id` (NOT `association`).
  Future<AssociationMemberModel> create({
    required int associationId,
    int? userId,                          // optional
    Map<String, dynamic>? userContact,    // optional: inline contact per create serializer
    String? companyName,
    String? phone,
    String? address,
    String? location,
    String status = 'pending',
    String? history,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'association_id': associationId,                // IMPORTANT: association_id
      if (userId != null) 'user': userId,
      if (userContact != null) 'user_contact': userContact,

      if (companyName != null) 'company_name': companyName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      'status': status,
      if (history != null) 'history': history,
      if (notes != null) 'notes': notes,
    };

    final Response? resp = await ApiServices.post(
      _url(),
      data: payload,
      hasToken: true,
      ref: ref,
    );

    // ApiServices.post validates <500; handle 4xx/2xx here
    if (resp != null && (resp.statusCode == 201 || resp.statusCode == 200)) {
      return AssociationMemberModel.fromJson(resp.data as Map<String, dynamic>);
    }
    throw Exception('Failed to create member: ${resp?.statusCode} ${resp?.data}');
  }

  Future<AssociationMemberModel> update(String uuid, Map<String, dynamic> patch) async {
    final Response? resp = await ApiServices.patch(
      _url('$uuid/'),
      data: patch,
      hasToken: true,
      ref: ref,
    );
    if (resp != null && resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
      return AssociationMemberModel.fromJson(resp.data as Map<String, dynamic>);
    }
    throw Exception('Failed to update member $uuid: ${resp?.statusCode} ${resp?.data}');
  }

  Future<void> delete(String uuid) async {
    final Response? resp = await ApiServices.delete(
      _url('$uuid/'),
      hasToken: true,
    );
    if (resp == null || resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
      throw Exception('Failed to delete member $uuid: ${resp?.statusCode} ${resp?.data}');
    }
  }

  Future<String> activate(String uuid) async {
    final Response? resp = await ApiServices.post(
      _url('$uuid/activate/'),
      hasToken: true,
      ref: ref,
    );
    if (resp != null && resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
      final data = resp.data as Map<String, dynamic>;
      return (data['status']?.toString()) ?? 'active';
    }
    throw Exception('Failed to activate member $uuid: ${resp?.statusCode} ${resp?.data}');
  }

  Future<String> suspend(String uuid) async {
    final Response? resp = await ApiServices.post(
      _url('$uuid/suspend/'),
      hasToken: true,
      ref: ref,
    );
    if (resp != null && resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
      final data = resp.data as Map<String, dynamic>;
      return (data['status']?.toString()) ?? 'suspended';
    }
    throw Exception('Failed to suspend member $uuid: ${resp?.statusCode} ${resp?.data}');
  }
}

/// --- Providers bootstrap ---
final associationMemberApiProvider = Provider<AssociationMemberApi>((ref) {
  return AssociationMemberApi(ref);
});

/// Filters state (global)
class AssociationMemberFilters {
  final int? associationId;
  final String? status;
  final String? search;
  final int page;
  final int pageSize;

  const AssociationMemberFilters({
    this.associationId,
    this.status,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  AssociationMemberFilters copyWith({
    int? associationId,
    String? status,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return AssociationMemberFilters(
      associationId: associationId ?? this.associationId,
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

final associationMemberFiltersProvider =
    StateProvider<AssociationMemberFilters>((ref) {
  return const AssociationMemberFilters();
});

/// Paginated list provider reacting to filters
final associationMembersProvider =
    FutureProvider<PageDto<AssociationMemberModel>>((ref) async {
  final api = ref.watch(associationMemberApiProvider);
  final f = ref.watch(associationMemberFiltersProvider);
  return api.list(
    associationId: f.associationId,
    status: f.status,
    search: f.search,
    page: f.page,
    pageSize: f.pageSize,
  );
});

/// Detail provider (per member UUID)
final associationMemberDetailProvider =
    FutureProvider.family<AssociationMemberModel, String>((ref, uuid) async {
  final api = ref.watch(associationMemberApiProvider);
  return api.retrieve(uuid);
});

/// --- Action controllers (create / update / delete / status) ---
class CreateMemberController extends AsyncNotifier<AssociationMemberModel?> {
  @override
  Future<AssociationMemberModel?> build() async => null;

  /// You can pass either `userId` OR `userContact` (inline map).
  Future<AssociationMemberModel> create({
    required int associationId,
    int? userId,                          // optional
    Map<String, dynamic>? userContact,    // optional
    String? companyName,
    String? phone,
    String? address,
    String? location,
    String status = 'pending',
    String? history,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(associationMemberApiProvider);

      // Soft guard: require at least identifier when creating via UI.
      if (userId == null && (userContact == null || (userContact['name']?.toString().trim().isEmpty ?? true))) {
        throw ArgumentError('Provide userId or userContact with at least a name.');
      }

      final created = await api.create(
        associationId: associationId,
        userId: userId,
        userContact: userContact,
        companyName: companyName,
        phone: phone,
        address: address,
        location: location,
        status: status,
        history: history,
        notes: notes,
      );

      // Refresh list after create
      ref.invalidate(associationMembersProvider);
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createMemberControllerProvider =
    AsyncNotifierProvider<CreateMemberController, AssociationMemberModel?>(
        CreateMemberController.new);

class UpdateMemberController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> patch(String uuid, Map<String, dynamic> patch) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(associationMemberApiProvider);
      await api.update(uuid, patch);
      ref.invalidate(associationMembersProvider);
      ref.invalidate(associationMemberDetailProvider(uuid));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> remove(String uuid) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(associationMemberApiProvider);
      await api.delete(uuid);
      ref.invalidate(associationMembersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> activate(String uuid) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(associationMemberApiProvider);
      await api.activate(uuid);
      ref.invalidate(associationMembersProvider);
      ref.invalidate(associationMemberDetailProvider(uuid));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> suspend(String uuid) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(associationMemberApiProvider);
      await api.suspend(uuid);
      ref.invalidate(associationMembersProvider);
      ref.invalidate(associationMemberDetailProvider(uuid));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateMemberControllerProvider =
    AsyncNotifierProvider<UpdateMemberController, void>(
        UpdateMemberController.new);
