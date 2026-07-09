import 'package:crm/bars/top_app_bar_crm.dart';
import 'package:crm/crm/dashboard/dashboard_buttons.dart';
import 'package:crm/crm/dashboard/finance_chart.dart';
import 'package:crm/crm/dashboard/plans_chart.dart';
import 'package:crm/crm/dashboard/structure_chart.dart';
import 'package:crm/crm/dashboard/transactions_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/values.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:portal/global_widgets/card_seller/seller_card.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:crm/bars/agent/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class AgentDashboardPc extends ConsumerStatefulWidget {
  const AgentDashboardPc({super.key});

  @override
  _AgentDashboardPcState createState() => _AgentDashboardPcState();
}

class _AgentDashboardPcState extends ConsumerState<AgentDashboardPc>
    with AutomaticKeepAliveClientMixin {
  // Controllers for PageView
  late PageController _pageController1;
  int _currentPage1 = 10000;

  late PageController _pageController2;
  int _currentPage2 = 10000;

  // Screen dimensions
  late double screenWidth;
  late double screenHeight;
  late double halfScreenWidth;
  late double chartScreenHeight;
  late double pieChartScreenHeight;

  // Global keys for showcase
  late GlobalKey oneKey;
  late GlobalKey twoKey;
  late GlobalKey threeKey;
  late GlobalKey fourKey;
  late GlobalKey fiveKey;
  late GlobalKey sixkey;
  late GlobalKey sevenkey;
  late FocusNode _focusNode;

  // Listy widgetów dla PageView
  final List<Widget> _pageView1Widgets = [
    const TransactionTypePieChart(isExpenses: true),
    const TransactionTypePieChart(isExpenses: false),
  ];

  final List<Widget> _pageView2Widgets = [
    const RevenueExpensesChart(),
    const FinancialPlansBarChart(),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    // Initialize PageControllers
    _pageController1 = PageController(initialPage: _currentPage1);
    _pageController2 = PageController(initialPage: _currentPage2);

    // Initialize showcase keys using Riverpod providers
    oneKey = ref.read(crm1);
    twoKey = ref.read(crm2);
    threeKey = ref.read(crm3);
    fourKey = ref.read(crm4);
    fiveKey = ref.read(crm5);
    sixkey = ref.read(crm6);
    sevenkey = ref.read(crm7);

    // Start showcase if needed
    _checkAndStartShowCase();
  }

  Future<void> _checkAndStartShowCase() async {
    final prefs = await SharedPreferences.getInstance();
    //prefs.clear();
    final isShowCaseDisplayed = prefs.getBool('crm') ?? false;

    if (!isShowCaseDisplayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          oneKey,
          twoKey,
          threeKey,
          fourKey,
          fiveKey,
          sixkey,
          sevenkey,
        ]);
      });
      await prefs.setBool('crm', true); // Mark showcase as displayed
    }
  }

  @override
  void dispose() {
    _pageController1.dispose();
    _pageController2.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double halfScreenWidth = screenWidth / 2 - 60;
    double chartScreenHeight = screenHeight / 5 * 3 - 54;
    double pieChartScreenHeight = screenHeight / 5 * 2 - 54;

    // Obliczamy liczby stron i bieżące indeksy dla wskaźników
    final int pageCount1 = _pageView1Widgets.length;
    final int displayPageIndex1 = _currentPage1 % pageCount1;

    final int pageCount2 = _pageView2Widgets.length;
    final int displayPageIndex2 = _currentPage2 % pageCount2;
    final sideMenuKey = GlobalKey<SideMenuState>();

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        KeyBoardShortcuts().handleKeyNavigation(event, ref, context);
      },
      child: Scaffold(
        body: SideMenuManager.sideMenuSettings(
          menuKey: sideMenuKey,
          child: Container(
            decoration: BoxDecoration(
              gradient: CustomBackgroundGradients.customcrmright(context, ref),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    SidebarAgentCrm(sideMenuKey: sideMenuKey),
                    Expanded(
                      child: Column(
                        children: [
                          const TopAppBarCRM(),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 0,
                                bottom: 15,
                                left: 15,
                                right: 15,
                              ),
                              child: Center(
                                child: SizedBox(
                                  height: screenHeight,
                                  width: screenWidth,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                height: pieChartScreenHeight,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      CustomBackgroundGradients.crmadgradient(
                                                        context,
                                                        ref,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(10.0),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    PageView.builder(
                                                      controller:
                                                          _pageController1,
                                                      onPageChanged: (
                                                        int page,
                                                      ) {
                                                        setState(() {
                                                          _currentPage1 = page;
                                                        });
                                                      },
                                                      itemBuilder: (
                                                        context,
                                                        index,
                                                      ) {
                                                        final int actualIndex =
                                                            index % pageCount1;
                                                        return _pageView1Widgets[actualIndex];
                                                      },
                                                    ),
                                                    // Strzałka w lewo
                                                    Positioned(
                                                      left: 0,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: IconButton(
                                                        icon:
                                                            AppIcons.iosArrowLeft(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .iconTheme
                                                                      .color,
                                                            ),
                                                        onPressed: () {
                                                          _pageController1.previousPage(
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      300,
                                                                ),
                                                            curve:
                                                                Curves
                                                                    .easeInOut,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    // Strzałka w prawo
                                                    Positioned(
                                                      right: 0,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: IconButton(
                                                        icon:
                                                            AppIcons.iosArrowRight(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .iconTheme
                                                                      .color,
                                                            ),
                                                        onPressed: () {
                                                          _pageController1.nextPage(
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      300,
                                                                ),
                                                            curve:
                                                                Curves
                                                                    .easeInOut,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    // Wskaźnik stron (kropki)
                                                    Positioned(
                                                      bottom: 10,
                                                      left: 0,
                                                      right: 0,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: List.generate(pageCount1, (
                                                          index,
                                                        ) {
                                                          return Container(
                                                            margin:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                ),
                                                            width: 8,
                                                            height: 8,
                                                            decoration: BoxDecoration(
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                              color:
                                                                  displayPageIndex1 ==
                                                                          index
                                                                      ? Theme.of(
                                                                        context,
                                                                      ).iconTheme.color
                                                                      : Colors
                                                                          .grey,
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Container(
                                              width: screenWidth / 1.85,
                                              height: pieChartScreenHeight,
                                              decoration: BoxDecoration(
                                                gradient:
                                                    CustomBackgroundGradients.crmadgradient(
                                                      context,
                                                      ref,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Stack(
                                                children: [
                                                  PageView.builder(
                                                    controller:
                                                        _pageController2,
                                                    onPageChanged: (int page) {
                                                      setState(() {
                                                        _currentPage2 = page;
                                                      });
                                                    },
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      final int actualIndex =
                                                          index % pageCount2;
                                                      return _pageView2Widgets[actualIndex];
                                                    },
                                                  ),
                                                  // Strzałka w lewo
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    child: IconButton(
                                                      icon:
                                                          AppIcons.iosArrowLeft(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .iconTheme
                                                                    .color,
                                                          ),
                                                      onPressed: () {
                                                        _pageController2
                                                            .previousPage(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        300,
                                                                  ),
                                                              curve:
                                                                  Curves
                                                                      .easeInOut,
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                  // Strzałka w prawo
                                                  Positioned(
                                                    right: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    child: IconButton(
                                                      icon:
                                                          AppIcons.iosArrowRight(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .iconTheme
                                                                    .color,
                                                          ),
                                                      onPressed: () {
                                                        _pageController2.nextPage(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  // Wskaźnik stron (kropki)
                                                  Positioned(
                                                    bottom: 10,
                                                    left: 0,
                                                    right: 0,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: List.generate(
                                                        pageCount2,
                                                        (index) {
                                                          return Container(
                                                            margin:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                ),
                                                            width: 8,
                                                            height: 8,
                                                            decoration: BoxDecoration(
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                              color:
                                                                  displayPageIndex2 ==
                                                                          index
                                                                      ? Theme.of(
                                                                        context,
                                                                      ).iconTheme.color
                                                                      : Colors
                                                                          .grey,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Container(
                                              height: pieChartScreenHeight,
                                              decoration: BoxDecoration(
                                                gradient:
                                                    CustomBackgroundGradients.crmadgradient(
                                                      context,
                                                      ref,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: SellerCard(
                                                sellerId: 1,
                                                onTap: () {},
                                              ), // change to prodyuction
                                            ),
                                          ],
                                        ),
                                        // Reszta kodu...
                                        const SizedBox(height: 15),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  FinancialWidget(),
                                                  // Usunięto FinancialPlansBarChart, ponieważ jest teraz w PageView
                                                  const SizedBox(height: 15),
                                                  Container(
                                                    // width: halfScreenWidth,
                                                    height:
                                                        screenHeight / 2 - 40,
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          CustomBackgroundGradients.crmadgradient(
                                                            context,
                                                            ref,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(10.0),
                                                    ),
                                                    child:
                                                        const FinancialPlansBarChart(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Container(
                                              width: halfScreenWidth,
                                              height: chartScreenHeight,
                                              decoration: BoxDecoration(
                                                gradient:
                                                    CustomBackgroundGradients.crmadgradient(
                                                      context,
                                                      ref,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 10.0,
                                                  right: 10,
                                                  top: 80.0,
                                                  bottom: 10,
                                                ),
                                                child: RevenueExpensesChart(),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Container(
                                              height: chartScreenHeight,
                                              decoration: BoxDecoration(
                                                gradient:
                                                    CustomBackgroundGradients.crmadgradient(
                                                      context,
                                                      ref,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(10.0),
                                                    child: DashboardSideButtons(
                                                      ref: ref,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
