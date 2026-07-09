import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hously_flutter/const/backgroundgradient.dart';
import 'package:hously_flutter/const/route_constant.dart';
import 'package:hously_flutter/const/url.dart';
import 'package:core/theme/design.dart';
import 'package:hously_flutter/state_managers/data/network_monitoring/saved_search/api.dart';
import 'package:hously_flutter/state_managers/data/network_monitoring/search_page/filters_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:hously_flutter/utils/pie_menu/saved_search_nm.dart';
import 'package:hously_flutter/widgets/crm/appbar_crm.dart';
import 'package:hously_flutter/widgets/network_monitoring/filter/fileds.dart';
import 'package:hously_flutter/widgets/side_menu/side_menu_manager.dart';
import 'package:hously_flutter/widgets/sidebar/sidebar_network_monitoring.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:hously_flutter/widgets/side_menu/slide_rotate_menu.dart';

import 'package:get/get_utils/get_utils.dart';

class SaveMonitoringPcPage extends ConsumerWidget {
  const SaveMonitoringPcPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSearchesAsyncValue = ref.watch(savedSearchesProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return PieCanvas(
      theme: const PieTheme(
        rightClickShowsMenu: true,
        leftClickShowsMenu: false,
        buttonTheme: PieButtonTheme(
          backgroundColor: AppColors.themeColor,
          iconColor: Colors.white,
        ),
        buttonThemeHovered: PieButtonTheme(
          backgroundColor: Color.fromARGB(96, 58, 58, 58),
          iconColor: Colors.white,
        ),
      ),
      child: Scaffold(
        body: SideMenuManager.sideMenuSettings(
          menuKey: sideMenuKey,
          child: Container(
            decoration: BoxDecoration(
                gradient: CustomBackgroundGradients.getMainMenuBackground(
                    context, ref)),
            child: Row(
              children: [
                SidebarNetworkMonitoring(
                  sideMenuKey: sideMenuKey,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const TopAppBarCRM(
                        routeName: Routes.saveNetworkMonitoring,
                      ),
                      Expanded(
                        child: Center(
                          child: savedSearchesAsyncValue.when(
                            data: (savedSearches) => GridView.builder(
                              addAutomaticKeepAlives: false,
                              addSemanticIndexes: false,
                              cacheExtent: 160,
                              padding: const EdgeInsets.all(16.0),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                childAspectRatio: 3 / 2,
                              ),
                              itemCount: savedSearches.length,
                              itemBuilder: (context, index) {
                                final search = savedSearches[index];
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
                                      ref
                                          .read(
                                              networkMonitoringFilterCacheProvider
                                                  .notifier)
                                          .setFiltersFromJson(search.toJson());
                                      ref
                                          .read(networkMonitoringFilterProvider
                                              .notifier)
                                          .applyFiltersFromCacheNM(
                                              ref.read(
                                                  networkMonitoringFilterCacheProvider
                                                      .notifier),
                                              ref);
                                      ref
                                          .read(
                                              networkMonitoringFilterButtonProvider
                                                  .notifier)
                                          .loadSavedFilters(ref
                                              .read(
                                                  networkMonitoringFilterCacheProvider
                                                      .notifier)
                                              .state); // Load saved filters to buttons
                                      ref
                                          .read(navigationService)
                                          .pushNamedScreen(
                                              Routes.networkMonitoring);
                                    }
                                  },
                                  actions: buildPieMenuActionsNMsavedSearch(
                                      ref, search, search.id, context),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    elevation: 5,
                                    child: InkWell(
                                      onTap: () {
                                        // Tu możesz dodać logikę do otwarcia szczegółów zapisanych wyszukiwań
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 120,
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius
                                                  .vertical(
                                                  top: Radius.circular(10.0)),
                                              image: DecorationImage(
                                                image: search.avatar != null
                                                    ? const AssetImage(
                                                            'assets/images/landingpage.webp')
                                                        as ImageProvider
                                                    : NetworkImage(
                                                        '${URLs.baseUrl}/media/${search.avatar}',
                                                      ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  search.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  search.description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tags: ${search.tags}'.tr,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Offers: ${search.lastCount}'.tr,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
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
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (error, stack) => Text(
                              'Failed to load saved searches: $error'.tr,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
