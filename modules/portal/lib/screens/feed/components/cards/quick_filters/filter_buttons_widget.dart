import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:network_monitoring/widgets/filter/fileds.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

class FilterButtonsWidget extends ConsumerWidget {
  final dynamic navigationHistoryProvider;

  const FilterButtonsWidget({
    super.key,
    required this.navigationHistoryProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = UniqueKey().toString();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 90,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                child: Column(
                  children: [
                      Expanded(
                      flex: 1,
                      child: Center(
                          child: Hero(
                            tag: tag,
                        child: InkWell(
                          onTap: () {
                            

                          },
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.transparent, // przezroczyste tło
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white, // białe obramowanie
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Center(
                                child: Text(
                                  'All filters'.tr,
                                  style: const TextStyle(
                                    color: Colors.white, // biały tekst
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12, 
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                           
                        Expanded(
                      flex: 3,
                      child: Center(
                        child: InkWell(
                          onTap: () {
                            ref.read(networkMonitoringFilterCacheProvider.notifier)
                                .clearFiltersNM();
                            ref.read(networkMonitoringFilterButtonProvider.notifier)
                                .clearUiFiltersNM(ref);
                            ref.read(networkMonitoringFilterProvider.notifier)
                                .applyFiltersFromCacheNM(
                    ref.read(networkMonitoringFilterCacheProvider.notifier),
                  );
                          },
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.transparent, // przezroczyste tło
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white, // białe obramowanie
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Center(
                              child: Text(
                                'Clear'.tr,
                                style: const TextStyle(
                                  color: Colors.white, // biały tekst
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12, 
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                             Expanded(
                              flex: 5,
                              child: Center(
                                child: InkWell(
                                  onTap: () {
                                    ref.read(networkMonitoringFilterProvider.notifier)
                                        .applyFiltersFromCacheNM(
                                            ref.read(networkMonitoringFilterCacheProvider
                                                .notifier),
                                            );
                                  },
                                  child: Material(
                                    child: Container(
                                      height: 30,
                                       decoration: BoxDecoration(
                                              color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'apply_filters'.tr,
                                style: const TextStyle(
                                  color: Colors.black, // biały tekst
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12, 
                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
    );
  }
}
