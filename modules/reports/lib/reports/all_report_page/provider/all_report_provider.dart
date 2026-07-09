import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/platform/api_services.dart';

final reportsPagingControllerProvider = StateNotifierProvider<
    ReportsPagingControllerNotifier,
    PagingController<int, ReportsListModel>>(
      (ref) => ReportsPagingControllerNotifier(ref),
);

class ReportsPagingControllerNotifier
    extends StateNotifier<PagingController<int, ReportsListModel>> {
  ReportsPagingControllerNotifier(this.ref)
      : super(PagingController<int, ReportsListModel>(firstPageKey: 0)) {
    state.addPageRequestListener(_fetchPage);
  }

  final Ref ref;

  static const int _pageSize = 10;

  String _searchQuery = '';
  String _sortBy = '-created_at';

  int _requestId = 0;

  void setSearchQuery(String query) {
    final cleanedQuery = query.trim();

    if (_searchQuery == cleanedQuery) return;

    _searchQuery = cleanedQuery;
    _requestId++;

    log('[REPORTS] Search changed: "$_searchQuery"');

    state.refresh();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) return;

    _sortBy = sortBy;
    _requestId++;

    log('[REPORTS] Sort changed: "$_sortBy"');

    state.refresh();
  }

  Future<void> _fetchPage(int offset) async {
    final int currentRequestId = _requestId;
    final String search = _searchQuery;
    final String ordering = _sortBy;

    try {
      log(
        '[REPORTS] Fetching offset=$offset, limit=$_pageSize, search="$search", ordering="$ordering"',
      );

      final newItems = await fetchReports(
        offset: offset,
        limit: _pageSize,
        search: search,
        ordering: ordering,
        ref: ref,
      );

      if (!mounted) return;

      if (currentRequestId != _requestId) {
        log('[REPORTS] Ignoring stale response for search="$search"');
        return;
      }

      log('[REPORTS] Fetched ${newItems.length} reports');

      final isLastPage = newItems.length < _pageSize;

      if (isLastPage) {
        state.appendLastPage(newItems);
      } else {
        state.appendPage(newItems, offset + _pageSize);
      }
      log('[REPORTS] TOTAL ITEMS NOW: ${state.itemList?.length}');
    } catch (error, stackTrace) {
      log('[REPORTS] Error: $error');
      log('[REPORTS] Stack trace: $stackTrace');

      if (mounted && currentRequestId == _requestId) {
        state.error = error;
      }
    }
  }

  void refresh() {
    if (!mounted) return;

    _requestId++;
    state.refresh();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }
}

Future<List<ReportsListModel>> fetchReports({
  required int offset,
  required int limit,
  String search = '',
  String ordering = '-created_at',
  required Ref ref,
}) async {
  final trimmedSearch = search.trim();

  final uri = Uri.parse(ReportsUrls.getReports).replace(
    queryParameters: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (trimmedSearch.isNotEmpty) 'search': trimmedSearch,
      'ordering': ordering,
    },
  );

  log('[REPORTS] URL: $uri');

  final response = await ApiServices.get(
    ref: ref,
    uri.toString(),
    hasToken: true,
  );

  if (response != null && response.statusCode == 200) {
    final decodedBody = utf8.decode(response.data);
    final reportsJson = json.decode(decodedBody) as Map<dynamic, dynamic>;
    final results = (reportsJson['results'] as List<dynamic>?) ?? [];
    final reports = results.map((json) => ReportsListModel.fromJson(json)).toList();

    for (final report in reports) {
      log(
        '[REPORTS] RESULT: country=${report.country}, state=${report.state}, city=${report.city}, street=${report.streetAddress}',
      );
    }
    return results.map((json) => ReportsListModel.fromJson(json)).toList();
  }

  throw Exception('Failed to load reports');
}

final reportsListProvider = FutureProvider<List<ReportsListModel>>((ref) async {
  return fetchReports(offset: 0, limit: 100, ref: ref);
});