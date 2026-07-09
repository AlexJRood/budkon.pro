import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

import 'package:crm/dynamic_dashboard/models/daily_market_overview_model.dart';

import 'package:dio/dio.dart';

final dailyMarketOverviewProvider =
    FutureProvider<DailyMarketOverviewModel>((ref) async {
  final response = await ApiServices.get(
    URLs.dailyMarketOverview,
    ref: ref,
    hasToken: true,
    responseType: ResponseType.json
  );

  if (response == null || response.statusCode != 200) {
   throw Exception('failed_to_load_market_overview'.tr);
  }

  debugPrint('[DASHBOARD OVERVIEW] response.data: ${response.data}');
  return DailyMarketOverviewModel.fromJson(response.data);
});