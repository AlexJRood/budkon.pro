import 'dart:convert';
import 'package:network_monitoring/network_monitoring_urls.dart';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

import 'freshness_result.dart';

class FreshnessState {
  final bool isChecking;
  final bool isMarking;
  final FreshnessCheckResult? lastResult;
  final int? lastAdId;
  final String? lastAdUrl;

  const FreshnessState({
    this.isChecking = false,
    this.isMarking = false,
    this.lastResult,
    this.lastAdId,
    this.lastAdUrl,
  });

  FreshnessState copyWith({
    bool? isChecking,
    bool? isMarking,
    FreshnessCheckResult? lastResult,
    int? lastAdId,
    String? lastAdUrl,
  }) {
    return FreshnessState(
      isChecking: isChecking ?? this.isChecking,
      isMarking: isMarking ?? this.isMarking,
      lastResult: lastResult ?? this.lastResult,
      lastAdId: lastAdId ?? this.lastAdId,
      lastAdUrl: lastAdUrl ?? this.lastAdUrl,
    );
  }
}

class FreshnessServiceNotifier extends StateNotifier<FreshnessState> {
  final Ref ref;

  FreshnessServiceNotifier(this.ref) : super(const FreshnessState());

  /// POST to Extractly — verify whether [url] is still a live listing.
  /// Returns null on error.
  Future<FreshnessCheckResult?> checkFreshness(String url, {int? adId}) async {
    state = state.copyWith(isChecking: true, lastAdUrl: url, lastAdId: adId);

    try {
      final response = await ApiServices.post(
        URLs.extractlyFreshnessCheck,
        ref: ref,
        hasToken: false,
        data: {
          'url': url,
          if (adId != null) 'ad_id': adId,
        },
      );

      if (response == null) {
        debugPrint('[freshness] No response from Extractly');
        return null;
      }

      dynamic json = response.data;
      if (json is Uint8List) {
        json = jsonDecode(utf8.decode(json));
      }

      final result = FreshnessCheckResult.fromJson(
        json as Map<String, dynamic>,
      );
      state = state.copyWith(isChecking: false, lastResult: result);
      debugPrint('[freshness] $result');
      return result;
    } catch (e) {
      debugPrint('[freshness] checkFreshness error: $e');
      state = state.copyWith(isChecking: false);
      return null;
    }
  }

  /// Mark [adId] as inactive in Superbee.
  Future<bool> _markInactiveInDb(int adId) async {
    try {
      final response = await ApiServices.post(
        NetworkMonitoringUrls.markAdInactive(adId.toString()),
        ref: ref,
        hasToken: true,
        data: {},
      );
      final ok = response != null &&
          (response.statusCode == 200 || response.statusCode == 204);
      debugPrint('[freshness] markInactiveInDb adId=$adId ok=$ok');
      return ok;
    } catch (e) {
      debugPrint('[freshness] markInactiveInDb error: $e');
      return false;
    }
  }

  /// Full "mark as outdated" flow:
  ///   1. POST to Extractly to verify detection works (debug signal).
  ///   2. POST to Superbee to persist the inactive status.
  Future<bool> markInactive(int adId, String url) async {
    state = state.copyWith(isMarking: true, lastAdId: adId, lastAdUrl: url);

    // Step 1 — send to Extractly (verification / debug signal).
    await checkFreshness(url, adId: adId);

    // Step 2 — mark in Superbee regardless of Extractly result
    //           (user explicitly decided this listing is outdated).
    final ok = await _markInactiveInDb(adId);

    state = state.copyWith(isMarking: false);
    return ok;
  }

  /// Called automatically from the WebView when stale signals are detected.
  /// Sends to Extractly and, if confidence is high enough, auto-marks in DB.
  Future<void> autoHandleIfInactive(int adId, String url) async {
    final result = await checkFreshness(url, adId: adId);
    if (result != null && result.isConfidentlyInactive) {
      debugPrint(
        '[freshness] auto-marking adId=$adId inactive '
        '(confidence=${result.confidence})',
      );
      await _markInactiveInDb(adId);
    }
  }
}

final freshnessServiceProvider =
    StateNotifierProvider<FreshnessServiceNotifier, FreshnessState>((ref) {
  return FreshnessServiceNotifier(ref);
});
