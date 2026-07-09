import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:get/get_utils/get_utils.dart';

final selectedFinanceViewProvider = StateProvider.autoDispose<String>(
    (ref) => '/pro/finance');

class ViewPopPageChangerCrmFinance extends ConsumerWidget {
  const ViewPopPageChangerCrmFinance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return PopPageManager(
              tag: 'StatusPopRevenue-${UniqueKey().toString()}',
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                         Material(
                          color: Colors.transparent,
                          child: Text(
                            'Wybierz widok wyszukiwania'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: buttonSearchBar,
                          onPressed: () {
                            ref
                                    .read(selectedFinanceViewProvider.notifier)
                                    .state =
                                '/pro/finance-draggable'; // Aktualizacja Providera
                            ref
                                .read(navigationService)
                                .pushNamedScreen(Routes.proDraggable);
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 320,
                                  height: 180,
                                  child: Image.asset(
                                      'assets/images/map_view.webp'),
                                ),
                                const SizedBox(height: 10),
                                 Text(
                                  'Mapa'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // const SizedBox(height: 10),
                        ElevatedButton(
                          style: buttonSearchBar,
                          onPressed: () {
                            ref
                                    .read(selectedFinanceViewProvider.notifier)
                                    .state =
                                '/pro/finance'; // Aktualizacja Providera
                            ref
                                .read(navigationService)
                                .pushNamedScreen(Routes.proFinance);
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 320,
                                  height: 180,
                                  child: Image.asset(
                                      'assets/images/feed_view.webp'),
                                ),
                                const SizedBox(
                                    height:
                                        10), // Dodaj trochę przestrzeni między obrazem a tekstem
                                 Text(
                                  'Widok siatki'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // // const SizedBox(height: 10),
                        //  ElevatedButton(
                        //   style: buttonSearchBar,
                        //       onPressed: () {
                        //     ref.read(selectedFinanceViewProvider.notifier).state = '/fullsize'; // Aktualizacja Providera
                        //     Navigator.of(context).pushNamed('/fullsize'); // Natychmiastowa nawigacja do wybranej strony
                        //   },
                        //   child: Material(
                        //   color: Colors.transparent,
                        //     child: Column(
                        //       children: [
                        //         SizedBox(
                        //           width: 320,
                        //           height: 180,
                        //           child:
                        //               Image.asset('assets/images/full_size_view.webp'),
                        //         ),
                        //         const SizedBox(height: 10),
                        //         Text(
                        //           'Fill size'.tr,
                        //           style: TextStyle(
                        //               color: Colors.white,
                        //               fontSize: 20,),),

                        //       ],
                        //     ),
                        //   ),
                        // ),

                        // // const SizedBox(height: 10),
                        //  ElevatedButton(
                        //   style: buttonSearchBar,
                        //       onPressed: () {
                        //     ref.read(selectedFinanceViewProvider.notifier).state = '/listview'; // Aktualizacja Providera
                        //     Navigator.of(context).pushNamed('/listview'); // Natychmiastowa nawigacja do wybranej strony
                        //   },
                        //   child: Material(
                        //   color: Colors.transparent,
                        //     child: Column(
                        //       children: [
                        //         SizedBox(
                        //           width: 320,
                        //           height: 180,
                        //           child:
                        //               Image.asset('assets/images/full_size_view.webp'),
                        //         ),
                        //         const SizedBox(height: 10),
                        //         Text(
                        //           'List view'.tr,
                        //           style: TextStyle(
                        //               color: Colors.white,
                        //               fontSize: 20,),),

                        //       ],
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
    );
  }
}
