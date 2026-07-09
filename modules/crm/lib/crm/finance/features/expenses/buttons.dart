// import 'package:crm/crm/finance/features/expenses/add_expenses.dart';
// import 'package:crm/invoices/form/screen/add_invoice_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:core/platform/route_constant.dart';
// import 'package:core/platform/navigation_service.dart';
// import 'package:crm/crm/finance/components/side_buttons.dart';

// class FinanaceExpensesButtons extends StatelessWidget {
//   final WidgetRef ref;
//   final bool isMobile;

//   const FinanaceExpensesButtons({
//     super.key,
//     required this.ref,
//     this.isMobile = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final nav = ref.read(navigationService);
//     final path = nav.currentPath;

//     return Align(
//       alignment: Alignment.center,
//       child: IntrinsicWidth(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: SizedBox(
//             height: 45.h,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   SideButtonsDashboard(
//                     onPressed: () {
//                       nav.pushNamedScreen(
//                         '$path/${Routes.statusPopExpenses}',
//                         data: {'isFilter': false},
//                       );
//                     },
//                     icon: Icons.edit,
//                     text: 'Edytuj statusy'.tr,
//                   ),
//                   const SizedBox(width: 10),
//                   SideButtonsDashboard(
//                     onPressed: () {
//                       if (isMobile) {
//                         // ✅ Open as bottom sheet on mobile
//                         showModalBottomSheet(
//                           context: context,
//                           isScrollControlled: true,
//                           shape: const RoundedRectangleBorder(
//                             borderRadius: BorderRadius.vertical(
//                               top: Radius.circular(16),
//                             ),
//                           ),
//                           builder:
//                               (context) => Padding(
//                                 padding: EdgeInsets.only(
//                                   bottom:
//                                       MediaQuery.of(context).viewInsets.bottom,
//                                 ),
//                                 child: SizedBox(
//                                   height:
//                                       MediaQuery.of(context).size.height * 0.95,
//                                   child: AddInvoiceScreen(isMobile: true),
//                                 ),
//                               ),
//                         );
//                       } else {
//                         // ✅ Open as dialog on larger screens
//                         showDialog(
//                           context: context,
//                           barrierDismissible: true,
//                           builder: (BuildContext dialogContext) {
//                             return Dialog(
//                               insetPadding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 24,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: SizedBox(
//                                 width: MediaQuery.of(context).size.width * 0.7,
//                                 height:
//                                     MediaQuery.of(context).size.height * 0.85,
//                                 child: AddInvoiceScreen(isMobile: false),
//                               ),
//                             );
//                           },
//                         );
//                       }
//                     },
//                     icon: Icons.add,
//                     text: 'Add expenses'.tr,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
