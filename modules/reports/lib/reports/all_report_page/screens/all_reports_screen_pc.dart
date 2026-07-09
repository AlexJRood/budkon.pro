import 'dart:async';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reports/reports/all_report_page/components/report_list_card.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/all_report_page/provider/all_report_provider.dart';
import 'package:reports/reports/compare_report/compare_report_popup.dart';
import 'package:reports/reports/landing_page_report/widgets/search_widget_report.dart';
import 'package:reports/reports/report_editor/report_editor_all.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

class AllReportsScreenPc extends ConsumerStatefulWidget {
  const AllReportsScreenPc({super.key});

  @override
  ConsumerState<AllReportsScreenPc> createState() => _AllReportsScreenPcState();
}

class _AllReportsScreenPcState extends ConsumerState<AllReportsScreenPc> {
  Timer? _debounce;
  String _currentSortLabel = 'Newest';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(reportsPagingControllerProvider.notifier).setSearchQuery(query);
    });
  }

  void _onSortSelected(String label, String value) {
    setState(() {
      _currentSortLabel = label;
    });
    ref.read(reportsPagingControllerProvider.notifier).setSortBy(value);
  }

  @override
  Widget build(BuildContext context) {
    final pagingController = ref.watch(reportsPagingControllerProvider);
    final theme = ref.watch(themeColorsProvider);

    return 
       Stack(
         children: [
           CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
              const SliverToBoxAdapter(child: ResponsivePropertySearchWidget()),
              SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          SizedBox(width: constraints.maxWidth * 0.1),
                          SizedBox(
                            width: constraints.maxWidth * 0.8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 30),
                                TextField(
                                  onChanged: _onSearchChanged,
                                  cursorColor:
                                      CustomColors.secondaryWidgetTextColor(
                                        context,
                                        ref,
                                      ),
                                  style: TextStyle(
                                    color: CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(0),
                                    fillColor: CustomColors.secondaryWidgetColor(
                                      context,
                                      ref,
                                    ),
                                    filled: true,
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    hintText: "Search...".tr,
                                    hintStyle: TextStyle(
                                      color: CustomColors.secondaryWidgetTextColor(
                                        context,
                                        ref,
                                      ),
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: AppIcons.search(
                                        width: 20,
                                        height: 20,
                                        color:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ),
                                      ),
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Spacer(),
                                    Text(
                                      "Sort By:".tr,
                                      style: TextStyle(
                                        color:
                                            CustomColors.secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ).withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    PopupMenuButton<Map<String, String>>(
                                      tooltip: 'Sort options',
                                      offset: const Offset(0, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      color: CustomColors.secondaryWidgetColor(
                                        context,
                                        ref,
                                      ),
                                      onSelected: (item) {
                                        _onSortSelected(
                                          item['label']!,
                                          item['value']!,
                                        );
                                      },
                                      itemBuilder:
                                          (context) =>
                                              [
                                                    {
                                                      'label': 'Newest'.tr,
                                                      'value': '-created_at',
                                                    },
                                                    {
                                                      'label': 'Oldest'.tr,
                                                      'value': 'created_at',
                                                    },
                                                    {
                                                      'label': 'Price: High to Low'.tr,
                                                      'value': '-price_per_sqm',
                                                    },
                                                    {
                                                      'label': 'Price: Low to High'.tr,
                                                      'value': 'price_per_sqm',
                                                    },
                                                  ]
                                                  .map(
                                                    (item) => PopupMenuItem(
                                                      value: item,
                                                      child: Text(
                                                        item['label']!,
                                                        style: TextStyle(
                                                          color:
                                                              CustomColors.secondaryWidgetTextColor(
                                                                context,
                                                                ref,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              CustomColors.secondaryWidgetTextColor(
                                                context,
                                                ref,
                                              ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color:
                                                CustomColors.secondaryWidgetTextColor(
                                                  context,
                                                  ref,
                                                ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _currentSortLabel,
                                              style: TextStyle(
                                                color:
                                                    CustomColors.secondaryWidgetTextColor(
                                                      context,
                                                      ref,
                                                    ),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color:
                                                  CustomColors.secondaryWidgetTextColor(
                                                    context,
                                                    ref,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SettingsButton(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) =>
                                                  PropertyComparisonDialog(),
                                        );
                                      },
                                      isPc: true,
                                      buttonheight: 35,
                                      text: 'Compare Reports'.tr,
                                    ),
                                    const SizedBox(width: 10),
                                    SettingsButton(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ReportEditorAll(),
                                          ),
                                        );
                                      },
                                      isPc: true,
                                      buttonheight: 35,
                                      text: 'report_editor'.tr,
                                      icon: Icons.tune,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),
                          ),
                          SizedBox(width: constraints.maxWidth * 0.1),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                ),
                sliver: PagedSliverList<int, ReportsListModel>(
                  pagingController: pagingController,
                  builderDelegate: PagedChildBuilderDelegate<ReportsListModel>(
                    itemBuilder:
                        (_, report, __) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: RealEstateCard(
                            address1:
                                '${report.country ?? 'Unknown'}, ${report.state ?? 'Unknown'}',
                            address2:
                                '${report.city ?? 'Unknown'}, ${report.streetAddress ?? 'Unknown'}',
                            size:
                                report.floorArea != null
                                    ? '${report.floorArea!.toStringAsFixed(0)} m²'
                                    : 'N/A',
                            rooms:
                                report.bedrooms != 2147483647
                                    ? '${report.bedrooms} Rooms'
                                    : 'N/A',
                            baths:
                                report.bathrooms != 2147483647
                                    ? '${report.bathrooms} Bath'
                                    : 'N/A',
                            price: '100',
                          ),
                        ),
                    firstPageProgressIndicatorBuilder:
                        (_) =>  Center(child: AppLottie.loading(size: 120)),
                    newPageProgressIndicatorBuilder: (_) => const SizedBox.shrink(),
                    noItemsFoundIndicatorBuilder:
                        (_) => Center(
                          child: Text(
                            'No reports available'.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: 16,
                            ),
                          ),
                        ),
                    firstPageErrorIndicatorBuilder:
                        (_) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Failed to load reports'.tr,
                                style: TextStyle(
                                  color: CustomColors.secondaryWidgetTextColor(
                                    context,
                                    ref,
                                  ),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed:
                                    () =>
                                        ref
                                            .read(
                                              reportsPagingControllerProvider
                                                  .notifier,
                                            )
                                            .refresh(),
                                child: Text(
                                  'Retry'.tr,
                                  style: TextStyle(
                                    color: CustomColors.secondaryWidgetTextColor(
                                      context,
                                      ref,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ],
                 ),

                 
         ],
       );
  }
}
