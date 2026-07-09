// import 'package:flutter/material.dart';
// import 'package:core/theme/design.dart';

// import '../landing_page_pc/here_to_help_widget.dart';

// import 'package:get/get_utils/get_utils.dart';

// class HereToHelpWidget extends StatelessWidget {
//   const HereToHelpWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(color: Color.fromRGBO(255, 255, 255, 1)),
//       height: 850,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Here to Help You Move\nForward',
//               style: AppTextStyles.libreCaslonHeading.copyWith(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: const Color.fromRGBO(35, 35, 35, 1)),
//             ),
//             const SizedBox(height: 30),
//             // First InfoCard
//             Expanded(
//               child: InfoCardWidget(
//                 title: 'Buy a home'.tr,
//                 description:
//                 'Buying a home is a big decision. Whether you\'re a\nfirst-time buyer or an experienced investor, we\nprovide the tools, insights, and AI-powered search\nto help you find the best deals on properties that\nmatch your needs.',
//                 buttonText: 'Browse homes'.tr,
//               ),
//             ),

//             // First Divider
//             const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//                 child: Divider(
//                   color: Color.fromRGBO(200, 200, 200, 1),
//                 )),

//             // Second InfoCard
//             Expanded(
//               child: InfoCardWidget(
//                 title: 'Sell a home'.tr,
//                 description:
//                 'Ready to sell your property? We make the process\nsimple, fast, and profitable. Our platform connects\nyou with a wide network of buyers and helps you\nset the best price based on real-time market data.',
//                 buttonText: 'See your options'.tr,
//               ),
//             ),

//             // Second Divider
//             const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//                 child: Divider(
//                   color: Color.fromRGBO(200, 200, 200, 1),
//                 )),

//             // Third InfoCard
//             Expanded(
//               child: InfoCardWidget(
//                 title: 'Rent a home'.tr,
//                 description:
//                 'Looking to rent? We have a wide selection of\nrental properties to fit your lifestyle and budget.\nFrom city apartments to suburban homes, find\nyour ideal space quickly with our tailored searchconst noptions.',
//                 buttonText: 'Find rentals'.tr,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
