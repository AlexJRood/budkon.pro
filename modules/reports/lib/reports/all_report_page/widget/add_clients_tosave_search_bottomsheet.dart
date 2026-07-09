import 'package:crm/data/clients/client_provider.dart';
import 'package:flutter/material.dart';import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:reports/reports/compare_report/provider/report_compare_provider.dart';
import 'package:reports/reports/compare_report/components/property_compare_tile.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'dart:math' as math;
class PropertyComparisonBottomSheet extends ConsumerWidget {
  const PropertyComparisonBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogHeight = screenWidth <= 1920
        ? 500
        : math.min(1200, 700 + (screenWidth - 1920) * 0.1);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CustomColors.secondaryWidgetColor(context, ref)
                    .withAlpha(204),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  // ✅ Scrollable content (everything except buttons)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: CustomColors.secondaryWidgetTextColor(
                                  context,
                                  ref,
                                ).withAlpha(76),
                              ),
                            ),
                          ),

                          Text(
                            'Compare reports'.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'choose_3_properties_to_compare'.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Selected properties images (same logic)
                          Consumer(
                            builder: (context, ref, child) {
                              final selectedIds =
                                  ref.watch(selectedPropertyIdsProvider);
                              final pagingController = ref.watch(
                                compareReportsPagingControllerProvider,
                              );

                              final selectedProps =
                                  pagingController.itemList
                                          ?.where(
                                            (property) => selectedIds
                                                .contains(property.id),
                                          )
                                          .toList() ??
                                      [];

                              return Row(
                                children: List.generate(3, (index) {
                                  Widget content;
                                  if (index < selectedProps.length) {
                                    final property = selectedProps[index];
                                    content = ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(6.0),
                                      child: Image.network(
                                        property.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.error,
                                          color: CustomColors
                                              .secondaryWidgetTextColor(
                                            context,
                                            ref,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    content = const Center();
                                  }

                                  return Expanded(
                                    child: Container(
                                      height: screenWidth <= 1920
                                          ? 100
                                          : 100 + dialogHeight * 0.05,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: index < selectedProps.length
                                            ? Colors.transparent
                                            : CustomColors
                                                    .secondaryWidgetTextColor(
                                              context,
                                              ref,
                                            ).withAlpha(26),
                                        border: index < selectedProps.length
                                            ? null
                                            : Border.all(
                                                color: CustomColors
                                                    .secondaryWidgetTextColor(
                                                  context,
                                                  ref,
                                                ).withAlpha(76),
                                              ),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: content,
                                    ),
                                  );
                                }),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Search bar (same UI - placeholder)
                          TextField(
                            enabled: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: CustomColors
                                      .secondaryWidgetTextColor(context, ref)
                                  .withAlpha(26),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: CustomColors
                                      .secondaryWidgetTextColor(
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

                          const SizedBox(height: 16),

                          // List (same logic). IMPORTANT:
                          // - Do NOT use Expanded inside SingleChildScrollView
                          // - Make list non-scrollable & shrink wrapped
                          Consumer(
                            builder: (context, ref, child) {
                              final pagingController = ref.watch(
                                compareReportsPagingControllerProvider,
                              );

                              return PagedListView<int, Property>(
                                pagingController: pagingController,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                builderDelegate:
                                    PagedChildBuilderDelegate<Property>(
                                  itemBuilder: (context, property, index) {
                                    final selectedIds = ref.watch(
                                      selectedPropertyIdsProvider,
                                    );
                                    return GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(selectedPropertyIdsProvider
                                                .notifier)
                                            .toggleProperty(property.id);
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: PropertyTile(
                                          imageUrl: property.imageUrl,
                                          address: property.address,
                                          price: property.price,
                                          isSelected: selectedIds
                                              .contains(property.id),
                                        ),
                                      ),
                                    );
                                  },
                                  firstPageErrorIndicatorBuilder:
                                      (context) => Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: CustomColors
                                                  .secondaryWidgetTextColor(
                                                context,
                                                ref,
                                              )
                                              .withAlpha(153),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'failed_to_load_properties'.tr,
                                          style: TextStyle(
                                            color: CustomColors
                                                    .secondaryWidgetTextColor(
                                                  context,
                                                  ref,
                                                )
                                                .withAlpha(204),
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () =>
                                              pagingController.refresh(),
                                          child: Text(
                                            'Retry'.tr,
                                            style: TextStyle(
                                              color: Colors.cyan,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  newPageErrorIndicatorBuilder:
                                      (context) => Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            'failed_to_load_more_properties'.tr,
                                            style: TextStyle(
                                              color: CustomColors
                                                      .secondaryWidgetTextColor(
                                                    context,
                                                    ref,
                                                  )
                                                  .withAlpha(204),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () =>
                                                pagingController
                                                    .retryLastFailedRequest(),
                                            child: Text(
                                              'Retry'.tr,
                                              style: TextStyle(
                                                color: Colors.cyan,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  firstPageProgressIndicatorBuilder:
                                      (context) => const Center(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.cyan,
                                      ),
                                    ),
                                  ),
                                  newPageProgressIndicatorBuilder:
                                      (context) => const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.cyan,
                                        ),
                                      ),
                                    ),
                                  ),
                                  noItemsFoundIndicatorBuilder:
                                      (context) => Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 48,
                                          color: CustomColors
                                                  .secondaryWidgetTextColor(
                                                context,
                                                ref,
                                              )
                                              .withAlpha(153),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'no_properties_found'.tr,
                                          style: TextStyle(
                                            color: CustomColors
                                                    .secondaryWidgetTextColor(
                                                  context,
                                                  ref,
                                                )
                                                .withAlpha(204),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ✅ Pinned buttons (same UI/logic, just not scrollable)
                  SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel'.tr,
                            style: TextStyle(
                              color: CustomColors.secondaryWidgetTextColor(
                                context,
                                ref,
                              ).withAlpha(178),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final selectedIds =
                                ref.watch(selectedPropertyIdsProvider);
                            return CustomElevatedButton(
                              borderRadius: 3,
                              onTap: selectedIds.length == 3
                                  ? () {
                                      final url =
                                          '/compare/${selectedIds[0]}/${selectedIds[1]}/${selectedIds[2]}';
                                      ref
                                          .read(navigationService)
                                          .pushNamedScreen(url);
                                    }
                                  : null,
                              text: 'Confirm'.tr,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
