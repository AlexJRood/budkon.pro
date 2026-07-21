// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:get/get_utils/get_utils.dart';
// import 'package:budkon_flutter/state_managers/data/network_monitoring/saved_search/remove.dart';
// import 'package:core/platform/navigation_service.dart';
// import 'package:budkon_flutter/widgets/crm/clients/show_pop_up_status.dart';
// import 'package:pie_menu/pie_menu.dart';

// List<PieAction> buildPieMenuActionsClientsPro(
//     WidgetRef ref, dynamic action, dynamic actionId, BuildContext context) {
//   return [
//     PieAction(
//       tooltip: const Text('Archiwizuj klienta'),
//       onSelect: () async {
//         final confirmed = await showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text('Potwierdzenie'.tr),
//             content: Text(
//                 'Jesteś pewnien że chcesz zarchiwizować tego klienta?'.tr),
//             actions: [
//               TextButton(
//                 onPressed: () => ref.read(navigationService).beamPop(false),
//                 child:  Text('Anuluj'.tr),
//               ),
//               TextButton(
//                 onPressed: () => ref.read(navigationService).beamPop(true),
//                 child:  Text('Usuń'.tr),
//               ),
//             ],
//           ),
//         );

//         if (confirmed == true) {
//           await ref.read(removeSavedSearchProvider).removeSavedSearch(action);
//         }
//       },
//       child: FaIcon(FontAwesomeIcons.trash),
//     ),
//     PieAction(
//       tooltip: const Text('Statusy'),
//       onSelect: () async {
//         showFilterPopup(context, ref);
//       },
//       child: const FaIcon(FontAwesomeIcons.filter),
//     ),
//   ];
// }

// extension ContextExtension on BuildContext {
//   void showSnackBarLikeSection(String message) {
//     ScaffoldMessenger.of(this).removeCurrentSnackBar();
//     ScaffoldMessenger.of(this).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }
// }
