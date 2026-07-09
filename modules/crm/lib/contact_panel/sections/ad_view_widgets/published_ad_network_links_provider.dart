import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import 'published_ad_network_link.dart';

const String _linksBase =
    'https://www.superbee.cloud/portal-exports/publication-links/';

const String _settingsEndpoint =
    'https://www.superbee.cloud/portal-exports/publication-link-settings/me/';

class PublishedAdNetworkLinksScope {
  const PublishedAdNetworkLinksScope({
    required this.appLabel,
    required this.model,
    required this.objectId,
  });

  final String appLabel;
  final String model;
  final String objectId;

  Map<String, dynamic> toPayload() {
    return {
      'app_label': appLabel,
      'model': model,
      'object_id': objectId,
    };
  }

  String get query {
    return 'app_label=${Uri.encodeComponent(appLabel)}'
        '&model=${Uri.encodeComponent(model)}'
        '&object_id=${Uri.encodeComponent(objectId)}';
  }

  @override
  bool operator ==(Object other) {
    return other is PublishedAdNetworkLinksScope &&
        other.appLabel == appLabel &&
        other.model == model &&
        other.objectId == objectId;
  }

  @override
  int get hashCode => Object.hash(appLabel, model, objectId);
}

class PublishedAdNetworkLinksState {
  const PublishedAdNetworkLinksState({
    required this.isLoading,
    required this.isFinding,
    required this.isActionRunning,
    required this.links,
    required this.settings,
    this.error,
  });

  final bool isLoading;
  final bool isFinding;
  final bool isActionRunning;
  final List<PublishedAdNetworkLink> links;
  final PublishedAdMatchingSettings? settings;
  final String? error;

  bool get canShowOverlay {
    final currentSettings = settings;

    if (currentSettings == null) return false;
    if (!currentSettings.enabled) return false;
    if (!currentSettings.showOverlay) return false;

    return links.where((item) => !item.isRejected).isNotEmpty;
  }

  factory PublishedAdNetworkLinksState.initial() {
    return const PublishedAdNetworkLinksState(
      isLoading: false,
      isFinding: false,
      isActionRunning: false,
      links: [],
      settings: null,
    );
  }

  PublishedAdNetworkLinksState copyWith({
    bool? isLoading,
    bool? isFinding,
    bool? isActionRunning,
    List<PublishedAdNetworkLink>? links,
    PublishedAdMatchingSettings? settings,
    String? error,
    bool clearError = false,
  }) {
    return PublishedAdNetworkLinksState(
      isLoading: isLoading ?? this.isLoading,
      isFinding: isFinding ?? this.isFinding,
      isActionRunning: isActionRunning ?? this.isActionRunning,
      links: links ?? this.links,
      settings: settings ?? this.settings,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final publishedAdNetworkLinksProvider = StateNotifierProvider.family<
    PublishedAdNetworkLinksNotifier,
    PublishedAdNetworkLinksState,
    PublishedAdNetworkLinksScope>((ref, scope) {
  return PublishedAdNetworkLinksNotifier(scope, ref: ref);
});

class PublishedAdNetworkLinksNotifier
    extends StateNotifier<PublishedAdNetworkLinksState> {
  final Ref ref;

  PublishedAdNetworkLinksNotifier(this.scope, {required this.ref})
      : super(PublishedAdNetworkLinksState.initial());

  final PublishedAdNetworkLinksScope scope;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await loadSettings();
      await loadLinks();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadSettings() async {
    final response = await ApiServices.get(
      ref: ref,
      _settingsEndpoint,
      hasToken: true,
    );

    final data = _extractMap(response?.data);

    if (data.isEmpty) return;

    state = state.copyWith(
      settings: PublishedAdMatchingSettings.fromJson(data),
      clearError: true,
    );
  }

  Future<void> saveSettings(PublishedAdMatchingSettings settings) async {
    final previous = state.settings;

    state = state.copyWith(
      settings: settings,
      isActionRunning: true,
      clearError: true,
    );

    try {
      final response = await ApiServices.patch(
        _settingsEndpoint,
        hasToken: true,
        data: settings.toJson(),
      );

      final data = _extractMap(response?.data);

      if (data.isNotEmpty) {
        state = state.copyWith(
          settings: PublishedAdMatchingSettings.fromJson(data),
        );
      }
    } catch (error) {
      state = state.copyWith(
        settings: previous,
        error: error.toString(),
      );
    } finally {
      state = state.copyWith(isActionRunning: false);
    }
  }

  Future<void> loadLinks({bool includeRejected = false}) async {
    final endpoint = '$_linksBase'
        'candidates/?${scope.query}'
        '${includeRejected ? '&include_rejected=1' : ''}';

    final response = await ApiServices.get(
      ref:ref,
      endpoint,
      hasToken: true,
    );

    final data = _decodeDynamic(response?.data);
    final list = _extractResultsList(data);

    state = state.copyWith(
      links: list
          .whereType<Map>()
          .map((item) => PublishedAdNetworkLink.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      clearError: true,
    );
  }

  Future<void> findCandidates({bool force = false}) async {
    state = state.copyWith(isFinding: true, clearError: true);

    try {
      await ApiServices.post(
        '${_linksBase}find-candidates/',
        hasToken: true,
        data: {
          ...scope.toPayload(),
          'force': force,
        },
      );

      await loadLinks();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(isFinding: false);
    }
  }

  Future<void> confirm(int linkId) async {
    await _runAction(() async {
      await ApiServices.post(
        '${_linksBase}confirm/',
        hasToken: true,
        data: {
          'link_id': linkId,
        },
      );

      await loadLinks();
    });
  }

  Future<void> reject(
    int linkId, {
    String reason = 'To nie jest to ogłoszenie',
  }) async {
    await _runAction(() async {
      await ApiServices.post(
        '${_linksBase}reject/',
        hasToken: true,
        data: {
          'link_id': linkId,
          'reason': reason,
        },
      );

      await loadLinks();
    });
  }

  Future<void> addManualLink({
    required String url,
    String? portalCode,
    String? portalName,
  }) async {
    await _runAction(() async {
      await ApiServices.post(
        '${_linksBase}manual/',
        hasToken: true,
        data: {
          ...scope.toPayload(),
          'url': url,
          if (portalCode != null && portalCode.trim().isNotEmpty)
            'portal_code': portalCode.trim(),
          if (portalName != null && portalName.trim().isNotEmpty)
            'portal_name': portalName.trim(),
        },
      );

      await loadLinks();
    });
  }

  Future<void> checkActive({
    int? linkId,
    String? url,
  }) async {
    await _runAction(() async {
      await ApiServices.post(
        '${_linksBase}check-active/',
        hasToken: true,
        data: {
          if (linkId != null) 'link_id': linkId,
          if (url != null && url.trim().isNotEmpty) 'url': url.trim(),
        },
      );

      await loadLinks();
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    state = state.copyWith(isActionRunning: true, clearError: true);

    try {
      await action();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(isActionRunning: false);
    }
  }
}

dynamic _decodeDynamic(dynamic data) {
  if (data == null) return null;

  if (data is List<int>) {
    try {
      return json.decode(utf8.decode(data));
    } catch (_) {
      return data;
    }
  }

  if (data is String) {
    try {
      return json.decode(data);
    } catch (_) {
      return data;
    }
  }

  return data;
}

Map<String, dynamic> _extractMap(dynamic data) {
  final decoded = _decodeDynamic(data);

  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }

  return const {};
}

List<dynamic> _extractResultsList(dynamic data) {
  final decoded = _decodeDynamic(data);

  if (decoded is List) return decoded;

  if (decoded is Map) {
    final results = decoded['results'];
    if (results is List) return results;

    final dataList = decoded['data'];
    if (dataList is List) return dataList;

    return [decoded];
  }

  return const [];
}