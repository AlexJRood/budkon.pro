import 'dart:convert';
import 'package:reports/reports_urls.dart';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/platform/api_services.dart';

class Property {
  final int id;
  final String imageUrl;
  final String address;
  final String price;

  Property({
    required this.id,
    required this.imageUrl,
    required this.address,
    required this.price,
  });

  // Convert from ReportsListModel to Property for comparison
  factory Property.fromReportModel(ReportsListModel report, int index) {
    return Property(
      id: report.id!,
      imageUrl: 'https://images.unsplash.com/photo-1565402170291-8491f14678db?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8cmVhbCUyMGVzdGF0ZXxlbnwwfHwwfHx8MA%3D%3D', // Default image for now
      address: '${report.city ?? 'Unknown'}, ${report.streetAddress ?? 'Unknown'}',
      price:report.pricePerSqm.toString(), // Default price for now
    );
  }
}

// Pagination controller provider for compare dialog
final compareReportsPagingControllerProvider =
    StateNotifierProvider<CompareReportsPagingControllerNotifier, PagingController<int, Property>>(
  (ref) => CompareReportsPagingControllerNotifier(ref),
);

class CompareReportsPagingControllerNotifier
    extends StateNotifier<PagingController<int, Property>> {
  final Ref ref;
  static const _pageSize = 10;
  bool _isInitialized = false;

  CompareReportsPagingControllerNotifier(this.ref)
      : super(PagingController<int, Property>(firstPageKey: 0)) {
    _initialize();
  }

  void _initialize() {
    if (!_isInitialized) {
      log('Initializing CompareReportsPagingController');
      state.addPageRequestListener((pageKey) {
        _fetchPage(pageKey);
      });
      _isInitialized = true;

      // Force initial load
      Future.microtask(() {
        if (mounted && (state.itemList?.isEmpty ?? true)) {
          log('Triggering initial refresh for compare reports');
          state.refresh();
        }
      });
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!_isInitialized) {
      log('Controller not initialized, skipping fetch');
      return;
    }

    try {
      log('Fetching  page: $pageKey');
      
      final offset = pageKey;
      final url = '${ReportsUrls.getReports}?limit=$_pageSize&offset=$offset';
      final response = await ApiServices.get(ref: ref, url, hasToken: true);

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final Map<String, dynamic> responseData = json.decode(decodedBody);
        // Try both 'results' and 'reports' keys to match API response
        final List<dynamic> reportsJson = responseData['results'] ?? responseData['reports'] ?? [];
        
        log('Compare reports API response: ${reportsJson.length} items found');
        
        final reports = reportsJson
            .map((json) => ReportsListModel.fromJson(json))
            .toList();
        
        // Convert to Property objects for comparison
        final properties = reports.asMap().entries.map((entry) {
          final index = pageKey + entry.key;
          return Property.fromReportModel(entry.value, index);
        }).toList();

        log('Converted ${properties.length} reports to properties');
        
        if (!mounted) {
          log('Controller disposed, not updating state');
          return;
        }

        final isLastPage = properties.length < _pageSize;
        if (isLastPage) {
          state.appendLastPage(properties);
          log('Last page appended for compare reports');
        } else {
          final nextPageKey = pageKey + properties.length;
          state.appendPage(properties, nextPageKey);
          log('Page appended for compare reports, next key: $nextPageKey');
        }
      } else {
        log('Error: ${response!.statusCode}');
        state.error = 'Failed to load reports';
      }
    } catch (error, stackTrace) {
      log('Exception in _fetchPage: $error', stackTrace: stackTrace);
      state.error = error;
    }
  }

  void refresh() {
    if (!mounted) return;
    log('Refreshing compare reports');
    state.refresh();
  }

  @override
  void dispose() {
    log('Disposing CompareReportsPagingController');
    _isInitialized = false;
    state.dispose();
    super.dispose();
  }
}

// Riverpod provider for managing selected properties
final selectedPropertyIdsProvider =
    StateNotifierProvider<SelectedPropertyIdsNotifier, List<int>>((ref) {
  return SelectedPropertyIdsNotifier();
});

class SelectedPropertyIdsNotifier extends StateNotifier<List<int>> {
  SelectedPropertyIdsNotifier() : super([]);

  void toggleProperty(int id) {
    if (state.contains(id)) {
      state = state.where((p) => p != id).toList();
    } else if (state.length < 3) {
      state = [...state, id];
    }
  }

  bool isSelected(int id) => state.contains(id);
}
