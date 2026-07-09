import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/user/login/login/login_navigation.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';

import 'package:get/get_utils/get_utils.dart';

class GetHomeRecommendation extends ConsumerWidget {
  const GetHomeRecommendation({super.key});

  @override
  Widget build(BuildContext context, ref) {



    return SizedBox(
      height: 454,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get home recommendations'.tr,
                  style: AppTextStyles.libreCaslonHeading.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.landingPageButtonTextcolor(
                          context, ref)),
                ),
                Text(
                  'Join us to access personalized recommendations, exclusive listings, and more features tailored just for you.'.tr,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CustomColors.landingPageSubHeadingColor(
                          context, ref)),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(260, 48),
                backgroundColor: AppColors.redBeige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => pushLoginNative(ref),
              child: Text(
                'Sign In'.tr,
                style: TextStyle(
                  color: CustomColors.landingpagewidgetcolor(context, ref),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              color: Colors.transparent,
              height: 220,
              width: 420,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 45,
                        top: 30,
                        child: Container(
                          width: 215,
                          height: 166,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color.fromRGBO(34, 57, 62, 1),
                                Color.fromRGBO(22, 25, 32, 1),
                              ]),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha((255 * 0.9).toInt()),
                                  spreadRadius: 8, // How far the shadow spreads
                                  blurRadius: 8, // Softness of the shadow
                                  offset: const Offset(
                                      0, 20), // Position of the shadow (x, y)
                                ),
                              ],
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/images/landingpage.webp'),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${'property_type_date'.tr}04 June 2024',
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.w400,
                                            color: Color.fromRGBO(
                                                145, 145, 145, 1)),
                                      ),
                                       Text(
                                        'parker_rd_allentown'.tr,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(
                                                145, 145, 145, 1)),
                                      ),
                                      Text(
                                        'Milan, ITALY'.tr,
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.w400,
                                            color: Color.fromRGBO(
                                                145, 145, 145, 1)),
                                      ),
                                      RichText(
                                          text: const TextSpan(children: [
                                        TextSpan(
                                          text: '\$165.00',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromRGBO(
                                                  145, 145, 145, 1)),
                                        ),
                                        TextSpan(
                                          text: '/1700 sq.ft',
                                          style: TextStyle(
                                              fontSize: 12.93,
                                              fontWeight: FontWeight.w400,
                                              color: Color.fromRGBO(
                                                  145, 145, 145, 1)),
                                        ),
                                      ])),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        left: 150,
                        child: Container(
                          width: 215,
                          height: 166,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Color.fromRGBO(34, 57, 62, 1),
                                Color.fromRGBO(22, 25, 32, 1),
                              ]),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/images/landingpage.webp'),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${'property_type_date'.tr}04 June 2024',
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.w400,
                                            color: Color.fromRGBO(
                                                145, 145, 145, 1)),
                                      ),
                                      Text(
                                        'parker_rd_allentown'.tr,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(
                                                145, 145, 145, 1)),
                                      ),
                                      Text(
                                        'Milan, ITALY'.tr,
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.w400,
                                            color: Color.fromRGBO(
                                                145, 145, 145, 1)),
                                      ),
                                      RichText(
                                          text: const TextSpan(children: [
                                        TextSpan(
                                          text: '\$165.00',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromRGBO(
                                                  145, 145, 145, 1)),
                                        ),
                                        TextSpan(
                                          text: '/1700 sq.ft',
                                          style: TextStyle(
                                              fontSize: 12.93,
                                              fontWeight: FontWeight.w400,
                                              color: Color.fromRGBO(
                                                  145, 145, 145, 1)),
                                        ),
                                      ])),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 90,
                    left: 0,
                    child: Container(
                      height: 34,
                      width: 134,
                      decoration: const BoxDecoration(
                          color: Color.fromRGBO(233, 233, 233, 1),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 23,
                            width: 23,
                            decoration: const BoxDecoration(
                                color: Color.fromRGBO(255, 255, 255, 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(32))),
                            child: const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended homes'.tr,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(35, 35, 35, 1)),
                              ),
                              Text(
                                'Based on your budget'.tr,
                                style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromRGBO(90, 90, 90, 1)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 50,
                    child: Container(
                      height: 28,
                      width: 70,
                      decoration: const BoxDecoration(
                          color: Color.fromRGBO(233, 233, 233, 1),
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.star,
                                  color: Colors.yellow.shade800, size: 10),
                              Icon(Icons.star,
                                  color: Colors.yellow.shade800, size: 10),
                              Icon(Icons.star,
                                  color: Colors.yellow.shade800, size: 10),
                              Icon(Icons.star,
                                  color: Colors.yellow.shade800, size: 10),
                            ],
                          ),
                          const Text(
                            '(238 reviews)',
                            style: TextStyle(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w400,
                                color: Color.fromRGBO(35, 35, 35, 1)),
                          )
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    right: 40,
                    child: Container(
                      height: 31,
                      width: 97,
                      decoration: const BoxDecoration(
                          color: Color.fromRGBO(233, 233, 233, 1),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 21,
                            width: 21,
                            decoration: const BoxDecoration(
                                color: Color.fromRGBO(35, 35, 35, 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(32))),
                            child: const Center(
                              child: Text(
                                '10K+',
                                style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(255, 255, 255, 1)),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Happy clients!'.tr,
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(35, 35, 35, 1)),
                              ),
                              Text(
                                'Feedback received'.tr,
                                style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromRGBO(90, 90, 90, 1)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
