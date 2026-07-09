import 'dart:ui' as ui;
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_appbar.dart';

import 'package:shimmer/shimmer.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crm/shared/models/transaction/agent_transaction_model.dart';

import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/secure_storage.dart';

import '../../../navigation/sidebar_client_panel.dart';
import 'package:crm/contact_panel/navigation/enum.dart';

class ClientShimmer extends ConsumerStatefulWidget {
  final ContactType contactType;
  const ClientShimmer({super.key, this.contactType = ContactType.client});

  @override
  ConsumerState<ClientShimmer> createState() => _ClientShimmerState();
}

class _ClientShimmerState extends ConsumerState<ClientShimmer> {
  late String mainImageUrl;
  final SecureStorage secureStorage = SecureStorage();


  String activeSection = 'dashboard';
  String openTransaction = '';

  @override
  void initState() {
    super.initState();

    setState(() {});
  }

  // void _activateMap() {
  //   setState(() {
  //   });
  // }

  // void _toggleMapVisibility() {
  //   setState(() {
  //     _isMapVisible = !_isMapVisible;
  //   });
  // }

  void openTransactionSection(String section, AgentTransactionModel transaction) {
    setState(() {
      activeSection = section;
      openTransaction = transaction.id.toString();
    });
  }

  // Changing section
  void _changeSection(String section) {
    setState(() {
      activeSection = section;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = ref.watch(themeColorsProvider);
    final clientTilecolor = theme.clientTilecolor;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withAlpha((255 * 0.85).toInt()),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(navigationService).beamPop(),
          ),
          Stack(
            children: [
              SizedBox(
                width: screenWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 70),
                        Shimmer.fromColors(
                          baseColor: clientTilecolor.withAlpha((255 * 75).toInt()),
                          highlightColor: clientTilecolor.withAlpha((255 * 25).toInt()),
                          child: SidebarClientAgentCrm(
                            onTabSelected: _changeSection,
                            activeSection: activeSection,
                            contactType: widget.contactType,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50),
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.85,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 15),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  height: 523,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex:
                                                            screenWidth >= 1415
                                                                ? 50
                                                                : 29,
                                                        child: Column(
                                                          children: [
                                                            Shimmer.fromColors(
                                                              baseColor:
                                                                  clientTilecolor
                                                                      .withAlpha(
                                                                          75),
                                                              highlightColor:
                                                                  clientTilecolor
                                                                      .withAlpha(
                                                                          25),
                                                              child: Container(
                                                                height: 152,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5),
                                                                  color:
                                                                      clientTilecolor,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 25),
                                                            Shimmer.fromColors(
                                                              baseColor:
                                                                  clientTilecolor
                                                                      .withAlpha(75),
                                                              highlightColor:
                                                                  clientTilecolor
                                                                      .withAlpha(25),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 15,
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          345,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(5),
                                                                        color:
                                                                            clientTilecolor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const Expanded(
                                                                      flex: 1,
                                                                      child:
                                                                          SizedBox()),
                                                                  Expanded(
                                                                    flex: 45,
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          345,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(5),
                                                                        color:
                                                                            clientTilecolor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const Expanded(
                                                          flex: 1,
                                                          child: SizedBox()),
                                                      Expanded(
                                                        flex: 15,
                                                        child:
                                                            Shimmer.fromColors(
                                                          baseColor:
                                                              clientTilecolor
                                                                  .withAlpha(75),
                                                          highlightColor:
                                                              clientTilecolor
                                                                  .withAlpha(25),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              color:
                                                                  clientTilecolor,
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
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 15),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  height: 350,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex:
                                                            screenWidth >= 1415
                                                                ? 50
                                                                : 29,
                                                        child:
                                                            Shimmer.fromColors(
                                                          baseColor:
                                                              clientTilecolor
                                                                  .withAlpha(75),
                                                          highlightColor:
                                                              clientTilecolor
                                                                  .withAlpha(25),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              color:
                                                                  clientTilecolor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const Expanded(
                                                          flex: 1,
                                                          child: SizedBox()),
                                                      Expanded(
                                                        flex: 15,
                                                        child:
                                                            Shimmer.fromColors(
                                                          baseColor:
                                                              clientTilecolor
                                                                  .withAlpha(75),
                                                          highlightColor:
                                                              clientTilecolor
                                                                  .withAlpha(25),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              color:
                                                                  clientTilecolor,
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
                                        ],
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
                  ],
                ),
              ),
              const Align(
                  alignment: Alignment.topRight, child: NewClientAppbar()),
            ],
          ),
        ],
      ),
    );
  }
}
