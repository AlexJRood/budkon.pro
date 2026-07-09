import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/dashboard_report/provider/dashboard_provider.dart';
import 'package:reports/reports/dashboard_report/widgets/components/report_proprty_card.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';
class PropertyList extends ConsumerStatefulWidget {
  final bool isMobile;

  const PropertyList({super.key, this.isMobile = false});

  @override
  ConsumerState<PropertyList> createState() => _PropertyListState();
}

class _PropertyListState extends ConsumerState<PropertyList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      data: (dashboardData) {
        final reports = dashboardData.lastReports;

        if (reports.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('No reports available'.tr)),
          );
        }

        return SizedBox(
          height: widget.isMobile ? 230 : 210,
          child: DragScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                controller: _scrollController,
                addAutomaticKeepAlives: false,
                cacheExtent: 300.0,
                scrollDirection: Axis.horizontal,
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final report = reports[index];

                  final formatter = NumberFormat.currency(
                    symbol: _currencySymbol(report.currency),
                    decimalDigits: 0,
                  );

                  final price =
                      report.valueEstimate != null
                          ? formatter.format(report.valueEstimate)
                          : 'N/A';

                  final addressParts = <String>[
                    if (report.streetAddress.isNotEmpty) report.streetAddress,
                    if (report.city.isNotEmpty) report.city,
                    if (report.state.isNotEmpty) report.state,
                  ];

                  final address =
                      addressParts.isEmpty
                          ? report.country
                          : addressParts.join(', ');

                  return SizedBox(
                    width: widget.isMobile ? 260 : 320,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ReprtPropertyCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1565402170291-8491f14678db?w=600&auto=format&fit=crop&q=60',
                        address: address,
                        reportId: report.id,
                        price: price,
                        isMobile: widget.isMobile,
                        ref: ref,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading:
          () =>  SizedBox(
            height: 200,
            child: Center(child: AppLottie.loading()),
          ),
      error:
          (error, stack) => SizedBox(
            height: 200,
            child: Center(child: Text('error_loading_reports'.tr)),
          ),
    );
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'PLN':
        return 'zł ';
      default:
        return '$currency ';
    }
  }
}