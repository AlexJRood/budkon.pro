import 'package:crm/data/finance/dio_provider.dart';
import 'package:crm/pie_menu/revenue_crm.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:core/platform/url.dart';

const configUrl = URLs.baseUrl;

const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';

class CrmRevenueList extends ConsumerWidget {
  final Color textColor;
  const CrmRevenueList({super.key, required this.textColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crmRevenueProviderAsyncValue = ref.watch(crmRevenueProvider);
    double screenWidth = MediaQuery.of(context).size.width;

    return crmRevenueProviderAsyncValue.when(
      data: (revenueCrm) {
        if (revenueCrm.isEmpty) {
          return Center(
            child: Text(
              'Brak przychodów'.tr,
              style: AppTextStyles.interRegular16,
            ),
          );
        }
        return ListView.builder(
          addAutomaticKeepAlives: false,
          cacheExtent: 300.0,
          itemCount: revenueCrm.length,
          itemBuilder: (context, index) {
            final revenue = revenueCrm[index];
            return PieMenu(
               theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
              onPressedWithDevice: (kind) {
                if (kind == PointerDeviceKind.mouse ||
                    kind == PointerDeviceKind.touch) {
                  Navigator.pushNamed(
                    context,
                    '/pro/finance/revenue/${revenue.id}',
                  );
                }
              },
              actions: pieMenuCrmRevenues(
                ref: ref,
                action: revenue,
                actionId: revenue.id,
                context: context,
                textColor: textColor,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    width: screenWidth / 5 * 3,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: BackgroundGradients.adGradient,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  defaultAvatarUrl,
                                ), // Obsługa domyślnego awatara
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Flexible(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      revenue.name,
                                      style: AppTextStyles.interMedium18,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${revenue.note}',
                                      style: AppTextStyles.interMedium,
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      revenue.amount,
                                      style: AppTextStyles.interMedium18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        return Center(
          child: Text('Error: $err'.tr, style: AppTextStyles.interMedium),
        );
      },
    );
  }
}
