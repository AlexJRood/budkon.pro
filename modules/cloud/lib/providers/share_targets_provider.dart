import 'dart:convert';

import 'package:cloud/models/file_share_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

dynamic _decodeRaw(dynamic raw) {
  if (raw is List<int>) {
    final decoded = utf8.decode(raw);
    return json.decode(decoded);
  }

  if (raw is String) {
    return json.decode(raw);
  }

  return raw;
}

Map<String, dynamic> _asMap(dynamic raw) {
  final decoded = _decodeRaw(raw);

  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);

  throw Exception('Unsupported map response format: ${decoded.runtimeType}');
}

List<dynamic> _asList(dynamic raw) {
  final decoded = _decodeRaw(raw);

  if (decoded is List) return decoded;

  throw Exception('Unsupported list response format: ${decoded.runtimeType}');
}

List<dynamic> _extractResults(dynamic raw) {
  final decoded = _decodeRaw(raw);

  if (decoded is Map<String, dynamic>) {
    final results = decoded['results'];
    if (results is List) return results;
    return [];
  }

  if (decoded is Map) {
    final map = Map<String, dynamic>.from(decoded);
    final results = map['results'];
    if (results is List) return results;
    return [];
  }

  if (decoded is List) {
    return decoded;
  }

  throw Exception('Unsupported response format: ${decoded.runtimeType}');
}

class ShareUsersNotifier extends StateNotifier<ShareTargetState> {
  ShareUsersNotifier(this.ref) : super(ShareTargetState.initial());

  final Ref ref;

  Future<void> fetch({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.initialized && !forceRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiServices.get(
        'https://www.superbee.cloud/user/user_list/',
        ref: ref,
        hasToken: true,
      );

      if (response == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load users',
          initialized: true,
        );
        return;
      }

      if (response.statusCode != 200) {
        state = state.copyWith(
          isLoading: false,
          error: 'Users request failed: ${response.statusCode}',
          initialized: true,
        );
        return;
      }

      final rawList =
          response.data is List<int>
              ? json.decode(utf8.decode(response.data as List<int>)) as List
              : (response.data as List);

      final items =
          rawList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);

            final id = map['id'].toString();
            final firstName = (map['first_name'] ?? '').toString().trim();
            final lastName = (map['last_name'] ?? '').toString().trim();
            final email = (map['email'] ?? '').toString().trim();
            final username = (map['username'] ?? '').toString().trim();

            final fullName = '$firstName $lastName'.trim();
            final label =
                fullName.isNotEmpty
                    ? (email.isNotEmpty ? '$fullName ($email)' : fullName)
                    : (email.isNotEmpty ? email : username);

            return ShareTargetOption(id: id, label: label);
          }).toList();

      state = state.copyWith(
        isLoading: false,
        items: items,
        initialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        initialized: true,
      );
    }
  }
}

final shareUsersProvider =
    StateNotifierProvider<ShareUsersNotifier, ShareTargetState>((ref) {
      return ShareUsersNotifier(ref);
    });

class ShareCompaniesNotifier extends StateNotifier<ShareTargetState> {
  ShareCompaniesNotifier(this.ref) : super(ShareTargetState.initial());

  final Ref ref;

  Future<void> fetch({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.initialized && !forceRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiServices.get(
        'https://www.superbee.cloud/user/companies/',
        ref: ref,
        hasToken: true,
      );

      if (response == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load companies',
          initialized: true,
        );
        return;
      }

      if (response.statusCode != 200) {
        state = state.copyWith(
          isLoading: false,
          error: 'Companies request failed: ${response.statusCode}',
          initialized: true,
        );
        return;
      }

      final rawList = _extractResults(response.data);

      final items =
          rawList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            final id = map['id'].toString();
            final name = (map['company_name'] ?? '').toString().trim();
            final label = name.isNotEmpty ? name : 'Company #$id';
            return ShareTargetOption(id: id, label: label);
          }).toList();

      state = state.copyWith(
        isLoading: false,
        items: items,
        initialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        initialized: true,
      );
    }
  }
}

final shareCompaniesProvider =
    StateNotifierProvider<ShareCompaniesNotifier, ShareTargetState>((ref) {
      return ShareCompaniesNotifier(ref);
    });

class ShareTeamsNotifier extends StateNotifier<ShareTargetState> {
  ShareTeamsNotifier(this.ref) : super(ShareTargetState.initial());

  final Ref ref;

  Future<void> fetch({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.initialized && !forceRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiServices.get(
        'https://www.superbee.cloud/user/teams/',
        ref: ref,
        hasToken: true,
      );

      if (response == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load teams',
          initialized: true,
        );
        return;
      }

      if (response.statusCode != 200) {
        state = state.copyWith(
          isLoading: false,
          error: 'Teams request failed: ${response.statusCode}',
          initialized: true,
        );
        return;
      }

      final rawList = _extractResults(response.data);

      final items =
          rawList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            final id = map['id'].toString();
            final name = (map['name'] ?? '').toString().trim();
            final label = name.isNotEmpty ? name : 'Team #$id';
            return ShareTargetOption(id: id, label: label);
          }).toList();

      state = state.copyWith(
        isLoading: false,
        items: items,
        initialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        initialized: true,
      );
    }
  }
}

final shareTeamsProvider =
    StateNotifierProvider<ShareTeamsNotifier, ShareTargetState>((ref) {
      return ShareTeamsNotifier(ref);
    });
