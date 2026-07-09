import 'dart:async';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reports/reports/all_report_page/components/report_list_card.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:reports/reports/all_report_page/provider/all_report_provider.dart';
import 'package:reports/reports/all_report_page/widget/add_clients_tosave_search_bottomsheet.dart';
import 'package:reports/reports/compare_report/compare_report_popup.dart';
import 'package:reports/reports/landing_page_report/widgets/search_widget_report.dart';
import 'package:reports/reports/report_editor/report_editor_all.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';

class AllReportScreenMobile extends ConsumerStatefulWidget {
  const AllReportScreenMobile({super.key});

  @override
  ConsumerState<AllReportScreenMobile> createState() =>
      _AllReportScreenMobileState();
}

class _AllReportScreenMobileState extends ConsumerState<AllReportScreenMobile> {
  Timer? _debounce;

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

  void _showSortOptions(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.secondaryWidgetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort By'.tr,
                style: TextStyle(
                  color: theme.themeTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildSortOption(context, 'Newest'.tr, '-created_at'),
              _buildSortOption(context, 'Oldest'.tr, 'created_at'),
              _buildSortOption(context, 'Price: High to Low'.tr, '-price_per_sqm'),
              _buildSortOption(context, 'Price: Low to High'.tr, 'price_per_sqm'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext context, String title, String value) {
    final theme = ref.read(themeColorsProvider);
    return ListTile(
      title: Text(title, style: TextStyle(color: theme.themeTextColor)),
      onTap: () {
        ref.read(reportsPagingControllerProvider.notifier).setSortBy(value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final pagingController = ref.watch(reportsPagingControllerProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return Column(
      children: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        Expanded(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
              const SliverToBoxAdapter(child: ResponsivePropertySearchWidget()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: _onSearchChanged,
                        cursorColor: theme.themeTextColor,
                        style: TextStyle(color: theme.themeTextColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(0),
                          fillColor: theme.settingsMenutile,
                          filled: true,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.themeTextColor),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          hintText: "Search...".tr,
                          hintStyle: TextStyle(color: theme.mobileTextcolor),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(10),
                            child: AppIcons.search(
                              width: 20,
                              height: 20,
                              color: theme.mobileTextcolor,
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                         SettingsButton(
                         isPc: false,
                         buttonheight: 40,
                         onTap: () async {
                        await showModalBottomSheet(
                       context: context,
                       isScrollControlled: true,
                       backgroundColor: theme.dashboardContainer,
                      builder: (_) {
                       return const PropertyComparisonBottomSheet();
                       },
                     );
                   },
                    text: "Compare Reports",
                   ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'report_editor'.tr,
                            icon: const Icon(Icons.tune),
                            color: theme.textColor,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReportEditorAll(),
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            iconAlignment: IconAlignment.end,
                            icon: AppIcons.sort(
                              color: theme.textColor,
                              width: 20,
                              height: 20,
                            ),
                            onPressed: () => _showSortOptions(context),
                            label: Text(
                              "Sort",
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: PagedSliverList<int, ReportsListModel>(
                  pagingController: pagingController,
                  builderDelegate: PagedChildBuilderDelegate<ReportsListModel>(
                    itemBuilder:
                        (_, report, __) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MobileRealEstateCard(
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
                        (_) => const Center(child: CircularProgressIndicator()),
                    newPageProgressIndicatorBuilder:
                        (_) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    noItemsFoundIndicatorBuilder:
                        (_) => Center(
                          child: Text(
                            'No reports available',
                            style: TextStyle(
                              color: theme.themeTextColor,
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
                                'Failed to load reports',
                                style: TextStyle(
                                  color: theme.themeTextColor,
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
                                  'Retry',
                                  style: TextStyle(color: theme.themeTextColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
        SizedBox(height: TopAppBarSize.withTopAppBar(context)),
      ],
    );
  }
}
