import 'package:flutter/material.dart';
import 'package:network_monitoring/screens/saved_search_new_screens/widgets/price_range_slider_widget.dart';
import 'package:network_monitoring/screens/saved_search_new_screens/widgets/price_slider_widget.dart';

import 'package:get/get_utils/get_utils.dart';

class MonitoringSavePcFilters extends StatelessWidget {
  const MonitoringSavePcFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 240,
        child: Column(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter'.tr,
              style: TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Container(
              height: 46,
              width: 240,
              decoration: const BoxDecoration(
                  color: Color.fromRGBO(41, 41, 41, 1),
                  borderRadius:
                  BorderRadius.all(Radius.circular(6))),
              child: Center(
                child: Row(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Affordable Options'.tr,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                          Color.fromRGBO(233, 233, 233, 1)),
                    ),
                    Image.asset('assets/images/vector-(5).png')
                  ],
                ),
              ),
            ),
            Container(
              height: 46,
              width: 240,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color.fromRGBO(166, 215, 227, 1)
                        .withAlpha((255 * 0.25).toInt()),
                    const Color.fromRGBO(87, 148, 221, 1)
                        .withAlpha((255 * 0.25).toInt()),
                  ]),
                  borderRadius: const BorderRadius.all(
                      Radius.circular(6))),
              child: Center(
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: [
                      Text(
                        'For Sale'.tr,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color.fromRGBO(
                                233, 233, 233, 1)),
                      ),
                      Icon(
                        Icons.expand_more_outlined,
                        color: Color.fromRGBO(255, 255, 255, 1),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'property_type'.tr,
              style: TextStyle(
                  color: Color.fromRGBO(233, 233, 233, 1),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            GridView.builder(
              addAutomaticKeepAlives: false,
              addSemanticIndexes: false,
              cacheExtent: 160,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two items per row
                crossAxisSpacing: 8, // Spacing between columns
                mainAxisSpacing: 8, // Spacing between rows
              ),
              itemBuilder: (context, index) {
                return Container(
                  height: 54,
                  width: 116,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color:
                      const Color.fromRGBO(35, 35, 35, 1)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.house_outlined,
                          size: 24,
                          color:
                          Color.fromRGBO(255, 255, 255, 1),
                        ),
                        Text(
                          'All types'.tr,
                          style: TextStyle(
                              color: Color.fromRGBO(
                                  255, 255, 255, 1),
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            Text(
              'Location'.tr,
              style: TextStyle(
                  color: Color.fromRGBO(233, 233, 233, 1),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            Container(
              height: 46,
              width: 240,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color.fromRGBO(166, 215, 227, 1)
                        .withAlpha((255 * 0.25).toInt()),
                    const Color.fromRGBO(87, 148, 221, 1)
                        .withAlpha((255 * 0.25).toInt()),
                  ]),
                  borderRadius: const BorderRadius.all(
                      Radius.circular(6))),
              child: Center(
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Location'.tr,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color.fromRGBO(
                                233, 233, 233, 1)),
                      ),
                      Icon(
                        Icons.location_on_outlined,
                        color: Color.fromRGBO(255, 255, 255, 1),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'Price'.tr,
              style: TextStyle(
                  color: Color.fromRGBO(233, 233, 233, 1),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const PriceSliderWidget(),
            Text(
              'Floor area'.tr,
              style: TextStyle(
                  color: Color.fromRGBO(233, 233, 233, 1),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const PriceRangeSliderWidget(),
            Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Rooms'.tr,
                  style: TextStyle(
                      color: Color.fromRGBO(233, 233, 233, 1),
                      fontSize: 13),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '4',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '5',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Bathrooms'.tr,
                  style: TextStyle(
                      color: Color.fromRGBO(233, 233, 233, 1),
                      fontSize: 13),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '4',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 41,
                        width: 41,
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                35, 35, 35, 1),
                            borderRadius:
                            BorderRadius.circular(10)),
                        child: const Center(
                          child: Text(
                            '5',
                            style: TextStyle(
                                color: Color.fromRGBO(
                                    233, 233, 233, 1),
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              height: 32,
              width: 240,
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color.fromRGBO(
                          200, 200, 200, 1))),
              child: Center(
                child: Text(
                  'Search'.tr,
                  style: TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Container(
              height: 32,
              width: 240,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'Clear filters'.tr,
                  style: TextStyle(
                      color: Color.fromRGBO(5, 35, 35, 1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
  }
}
