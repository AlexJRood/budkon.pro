import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/add_search.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_view.dart';
import 'package:crm/pie_menu/ads_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/screens/feed/widgets/map/map_page.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import '../../../../data/clients/ad_provider.dart';
import 'package:network_monitoring/browselist/widget/pc.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

class AdListClient extends ConsumerStatefulWidget {
  final AdViewMode viewMode;
  final int? transactionId;
  final int? clientId;
  final bool isMobile;

  const AdListClient({
    super.key,
    this.isMobile = false,
    required this.viewMode,
    this.transactionId,
    this.clientId,
  });

  @override
  ConsumerState<AdListClient> createState() => _AdListClientState();
}

class _AdListClientState extends ConsumerState<AdListClient> {
  void updateFilteredAds(List<AdsListViewModel> ads) {}

  late final ScrollController _scrollController;

  static const int _pageSize = 25; // możesz zmienić do 50 (max w backend)
  final PagingController<int, MonitoringAdsModel> _pagingController =
      PagingController(firstPageKey: 1);

  Timer? _refreshDebounce;
  ProviderSubscription? _filtersSub;

  Map<String, dynamic> _decodeRoot(dynamic data) {
    // ✅ Map
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    // ✅ raw JSON string
    if (data is String) {
      final decoded = json.decode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw Exception('Decoded JSON is not a map (String->${decoded.runtimeType})');
    }

    // ✅ bytes
    if (data is List<int>) {
      final decoded = json.decode(utf8.decode(data));
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw Exception('Decoded JSON is not a map (bytes->${decoded.runtimeType})');
    }

    // ✅ czasem ktoś zwraca samą listę results
    if (data is List) {
      // zamieniamy to w “root” jak z DRF
      return <String, dynamic>{
        'count': data.length,
        'next': null,
        'previous': null,
        'results': data,
      };
    }

    throw Exception('Unexpected response format (${data.runtimeType})');
  }

  Map<String, dynamic> _buildQueryParameters({
    required int page,
    required int pageSize,
  }) {
    final notifier = ref.read(filterProvider.notifier) as FiltersLogicNotifier;

    Map<String, dynamic> authFilters = {};
    if (ApiServices.token != null && ApiServices.token!.isNotEmpty) {
      authFilters = {
        if (notifier.filters.containsKey('exclude_favorites'))
          'exclude_favorites': notifier.filters['exclude_favorites'],
        if (notifier.filters.containsKey('exclude_hide'))
          'exclude_hide': notifier.filters['exclude_hide'],
        if (notifier.filters.containsKey('exclude_displayed'))
          'exclude_displayed': notifier.filters['exclude_displayed'],
      };
    }

    final multiCsv = notifier.selectedSavedSearchIds.isNotEmpty
        ? notifier.selectedSavedSearchIds.join(',')
        : (notifier.selectedSavedSearchId.isNotEmpty ? notifier.selectedSavedSearchId : '');

    final qp = <String, dynamic>{
      ...notifier.filters,
      if (notifier.searchQuery.isNotEmpty) 'search': notifier.searchQuery,
      if (notifier.excludeQuery.isNotEmpty) 'exclude': notifier.excludeQuery,
      if (notifier.sortOrder.isNotEmpty) 'sort': notifier.sortOrder,
      'currency': notifier.selectedCurrency,
      ...authFilters,
      if (multiCsv.isNotEmpty) 'saved_search_id': multiCsv,
      if (notifier.savedSearchClientId.isNotEmpty)
        'saved_search_client_id': notifier.savedSearchClientId,
      if (notifier.savedSearchTransactionId.isNotEmpty)
        'saved_search_transaction_id': notifier.savedSearchTransactionId,
      if (notifier.clientId.isNotEmpty) 'client': notifier.clientId,
      if (notifier.transactionId.isNotEmpty) 'transaction': notifier.transactionId,
      'page': page,
      'page_size': pageSize,
    };

    qp.removeWhere((k, v) {
      if (v == null) return true;
      if (v is String) return v.trim().isEmpty;
      if (v is Iterable) return v.isEmpty; // ✅ handles List/Set
      if (v is Map) return v.isEmpty;      // ✅ handles Map
      return false;
    });
    return qp;
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;
    try {
      final qp = _buildQueryParameters(page: pageKey, pageSize: _pageSize);
      debugPrint('younis QP => ${jsonEncode(qp)}');

      final response = await ApiServices.get(
        ref: ref,
        URLs.singleAdMonitoring,
        hasToken: true,
        queryParameters: qp,
      );
 if (!mounted) return; 
      if (response == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // ✅ TU BYŁ BŁĄD: data nie zawsze jest Map
      final root = _decodeRoot(response.data);

      final resultsRaw = (root['results'] as List<dynamic>? ?? const []);
      final items = resultsRaw
          .map((e) => MonitoringAdsModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final nextUrl = root['next']; // String? / null
      final isLastPage = nextUrl == null;
if (!mounted) return;
      if (isLastPage) {
        _pagingController.appendLastPage(items);
      } else {
        _pagingController.appendPage(items, pageKey + 1);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  void _refreshPagingDebounced() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _pagingController.refresh();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _pagingController.addPageRequestListener(_fetchPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pagingController.refresh();
    });

    _filtersSub = ref.listenManual(filterProvider, (prev, next) {
      _refreshPagingDebounced();
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _filtersSub?.close();
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // tylko żeby zmiany filtrów robiły rebuild (i odpalały listenManual)
    ref.watch(filterProvider);

    final screenSize = MediaQuery.of(context).size;
    final theme = ref.read(themeColorsProvider);

    final cardType = ref.watch(selectedCardProviderNM);
    final cardRatio = cardType.aspectRatio;
    final grid = cardType.gridCount(context);
    final double paddingByCard = cardType.basePadding;
    final bool isMap = cardType == CardTypeNM.map;

    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);
   final double adFiledSize = math.max(
  0.0,
  screenSize.width - (widget.isMobile ? 0.0 : 440.0),
);


    // Map view zostawiam jak było (u Ciebie bazuje na providerze)
    if (isMap) {
      final asyncFilteredAds = ref.watch(filterProvider);
      return asyncFilteredAds.when(
        data: (filteredAdvertisements) {
          if (filteredAdvertisements.isEmpty) {
            return Center(
              child: Column(
                children: [
                  AppLottie.noResults(),
                  Text(
                    'no_search_results_message'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              PortalMapPage(onFilteredAdsChanged: updateFilteredAds),
              Positioned(
                right: 10,
                top: 10,
                bottom: 10,
                child: SizedBox(
                  width: 400,
                  height: screenSize.height - 30,
                  child: ListView.builder(
                    addAutomaticKeepAlives: false,
                    cacheExtent: 300.0,
                    controller: _scrollController,
                    itemCount: filteredAdvertisements.length,
                    itemBuilder: (context, index) {
                      final ad = filteredAdvertisements[index];
                      final tag = 'fullSize${ad.id}-${UniqueKey()}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SelectedCardWidgetNM(
                          isMobile: false,
                          aspectRatio: cardRatio,
                          ad: ad,
                          tag: tag,
                          mainImageUrl: ad.mainImageUrl,
                          isPro: ad.isPro,
                          isDefaultDarkSystem: isDefaultDarkSystem,
                          color: theme.themeColor,
                          textColor: theme.textColor,
                          textFieldColor: theme.textFieldColor,
                          buildShimmerPlaceholder: ShimmerPlaceholderWidget(
                            adFiledSize: adFiledSize,
                            crossAxisCount: 1,
                          ),
                          transactionId: widget.transactionId,
                          clientId: widget.clientId,
                          buildPieMenuActions: pieAdsClient(
                            ref,
                            ad,
                            context,
                            widget.transactionId,
                            widget.clientId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${'error_occurred_prefix'.tr} $e')),
      );
    }

    return Row(
      children: [
        if (widget.isMobile) ...[const SizedBox(width: 5)],
        Expanded(
          child: CustomScrollView(
            cacheExtent: 800,
            controller: _scrollController,
            key: const PageStorageKey('client_panel_scroll'),
            slivers: [
              if(widget.isMobile)
              SliverToBoxAdapter(
                child: SizedBox(height: TopAppBarSize.resolve(context)+5)
              ),
              PagedSliverGrid<int, MonitoringAdsModel>(
                pagingController: _pagingController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grid,
                  mainAxisSpacing: paddingByCard,
                  crossAxisSpacing: paddingByCard,
                  childAspectRatio: cardRatio,
                ),
                builderDelegate: PagedChildBuilderDelegate<MonitoringAdsModel>(
                  itemBuilder: (context, ad, index) {
                    final tag = 'fullSize${ad.id}-$index';
                    return SelectedCardWidgetNM(
                      isMobile: false,
                      aspectRatio: cardRatio,
                      ad: ad,
                      tag: tag,
                      mainImageUrl: ad.mainImageUrl,
                      isPro: ad.isPro,
                      isDefaultDarkSystem: isDefaultDarkSystem,
                      color: theme.themeColor,
                      textColor: theme.textColor,
                      textFieldColor: theme.textFieldColor,
                      buildShimmerPlaceholder: ShimmerPlaceholderWidget(
                        adFiledSize: adFiledSize,
                        crossAxisCount: grid,
                      ),
                      transactionId: widget.transactionId,
                      clientId: widget.clientId,
                      buildPieMenuActions: pieAdsClient(
                        ref,
                        ad,
                        context,
                        widget.transactionId,
                        widget.clientId,
                      ),
                    );
                  },

                  firstPageProgressIndicatorBuilder: (_) => Center(
                    child: ShimmerPlaceholderWidget(
                      adFiledSize: adFiledSize,
                      crossAxisCount: grid,
                    ),
                  ),

                  newPageProgressIndicatorBuilder: (_) => const Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),

                  noItemsFoundIndicatorBuilder: (_) => Center(
                    child: Column(
                      children: [
                        AppLottie.noResults(),
                        Text(
                          'no_search_results_message'.tr,
                          style: TextStyle(color: theme.textColor),
                        ),
                      ],
                    ),
                  ),

                  firstPageErrorIndicatorBuilder: (_) {
                    final msg = _pagingController.error.toString();
                    if (msg.contains('No saved filters for this transaction')) {
                      return SingleChildScrollView(
                        child: Padding(
                          padding: widget.isMobile
                              ? EdgeInsets.only(
                                  top: TopAppBarSize.resolve(context),
                                  bottom: BottomBarSize.resolve(context),
                                )
                              : const EdgeInsets.only(right: 105.0),
                          child: AddSearchClientPanel(
                            isMobile: widget.isMobile,
                            transactionId: widget.transactionId,
                            clientId: widget.clientId,
                            headline: 'add_first_saved_search_title'.tr,
                            hasPop: false,
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${'error_occurred_prefix'.tr} $msg'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _pagingController.refresh(),
                            child: Text('try_again_button'.tr),
                          ),
                        ],
                      ),
                    );
                  },

                  newPageErrorIndicatorBuilder: (_) => Center(
                    child: TextButton(
                      onPressed: () => _pagingController.retryLastFailedRequest(),
                      child: Text('error_loading_next_page'.tr),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
        if (!widget.isMobile) ...[
          const SizedBox(width: 25),
          BrowseListNetworkMonitoringPcWidget(
            isWhiteSpaceNeeded: false,
            transactionId: widget.transactionId,
            clientId: widget.clientId,
          ),
        ],
        if (widget.isMobile) ...[const SizedBox(width: 5)],
      ],
    );
  }
}

class ShimmerPlaceholderWidget extends StatelessWidget {
  final double adFiledSize;
  final int crossAxisCount;

  const ShimmerPlaceholderWidget({
    super.key,
    required this.adFiledSize,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    final safe = adFiledSize <= 0 ? 1.0 : adFiledSize; 
    return SizedBox(
      height: safe,
      width: safe,
      child: ShimmerAdvertisementGrid(crossAxisCount: crossAxisCount),
    );
  }
}
