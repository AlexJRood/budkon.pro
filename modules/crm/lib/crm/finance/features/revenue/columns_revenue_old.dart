// // ignore_for_file: deprecated_member_use

// import 'dart:ui';

// import 'package:crm/crm/finance/features/revenue/revenue_card.dart';
// import 'package:crm/pie_menu/revenue_crm.dart';
// import 'package:crm/invoices/form/screen/add_invoice_screen.dart';
// import 'package:crm/invoices/widgets/invoice_details_view.dart';
// import 'package:crm/shared/models/revenue_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:pie_menu/pie_menu.dart';
// import 'package:core/theme/apptheme.dart';
// import 'package:core/theme/button_style.dart';
// import 'package:core/theme/design.dart';
// import 'package:core/theme/icons.dart';

// import '../../components/custom_vertical_divider.dart';

// class DraggableColumnOld extends StatelessWidget {
//   final String status;
//   final List<AgentRevenueModel> revenues;
//   final void Function(String) onAcceptColumn;
//   final void Function(AgentRevenueModel transaction, int newIndex) onReorder;
//   final void Function(
//     AgentRevenueModel transaction,
//     String newStatus,
//     int? newIndex,
//   )
//   onMove;
//   final WidgetRef ref;
//   final void Function(AgentRevenueModel transaction)
//   onTransactionSelected; // Dodajemy ten parametr

//   const DraggableColumnOld({
//     super.key,
//     required this.status,
//     required this.revenues,
//     required this.onAcceptColumn,
//     required this.onReorder,
//     required this.onMove,
//     required this.ref,
//     required this.onTransactionSelected, // Dodajemy ten parametr
//   });

//   @override
//   Widget build(BuildContext context) {
//     double screenHeight = MediaQuery.of(context).size.height;
//     double quarterScreenHeight = screenHeight / 4 * 3;
//     final bool isMobile = MediaQuery.of(context).size.width < 800;
//     final theme = ref.read(themeColorsProvider);
//     final screenSize = MediaQuery.of(context).size;

//     return DragTarget<String>(
//       onAccept: onAcceptColumn,
//       builder: (context, candidateData, rejectedData) {
//         return Row(
//           children: [
//             if (candidateData.isNotEmpty)
//               Container(
//                 color: AppColors.light50,
//                 child: Padding(
//                   padding: const EdgeInsets.all(15.0),
//                   child: Material(
//                     borderRadius: BorderRadius.circular(20),
//                     child: Container(
//                       width: 300,
//                       decoration: BoxDecoration(
//                         color: AppColors.light25,
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: AppColors.dark50,
//                             offset: Offset(0, 4),
//                             blurRadius: 25,
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           Container(
//                             height: 50,
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(8.0),
//                             decoration: BoxDecoration(
//                               gradient:
//                                   candidateData.isNotEmpty
//                                       ? CrmGradients.loginGradient
//                                       : CrmGradients.adGradient,
//                               borderRadius: const BorderRadius.only(
//                                 topLeft: Radius.circular(20),
//                                 topRight: Radius.circular(20),
//                               ),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 status,
//                                 style: AppTextStyles.interMedium14.copyWith(
//                                   color: theme.textColor,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           ...revenues.map((transaction) {
//                             return SizedBox(
//                               width: 300,
//                               // height: 50,
//                               child: TransactionCardRevenue(
//                                 revenue: transaction,
//                                 key: ValueKey(
//                                   transaction.id,
//                                 ), // Unique key for each transaction
//                               ),
//                             );
//                           }),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//             LongPressDraggable<String>(
//               data: status,
//               feedback: Material(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Container(
//                   width: 300,
//                   decoration: BoxDecoration(
//                     color: AppColors.light25,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: AppColors.dark50,
//                         offset: Offset(0, 4),
//                         blurRadius: 25,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         height: 50,
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(8.0),
//                         decoration: BoxDecoration(
//                           gradient:
//                               candidateData.isNotEmpty
//                                   ? CrmGradients.loginGradient
//                                   : CrmGradients.adGradient,
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(20),
//                             topRight: Radius.circular(20),
//                           ),
//                         ),
//                         child: Center(
//                           child: Text(
//                             status,
//                             style: AppTextStyles.interMedium14.copyWith(
//                               color: theme.textColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                       ...revenues.map((transaction) {
//                         return SizedBox(
//                           width: 300,
//                           // height: 50,
//                           child: TransactionCardRevenue(
//                             revenue: transaction,
//                             key: ValueKey(
//                               transaction.id,
//                             ), // Unique key for each transaction
//                           ),
//                         );
//                       }),
//                     ],
//                   ),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   DragTarget<AgentRevenueModel>(
//                     onWillAccept: (transaction) => true,
//                     onAccept:
//                         (transaction) => onMove(
//                           transaction,
//                           status,
//                           null,
//                         ), // Null oznacza, że element trafi na koniec listy
//                     builder: (context, candidateData, rejectedData) {
//                       return Container(
//                         width: 300,
//                         padding: const EdgeInsets.all(8.0),
//                         decoration: BoxDecoration(
//                           color:
//                               candidateData.isNotEmpty
//                                   ? AppColors.light50
//                                   : Colors.transparent,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Column(
//                           children: [
//                             Container(
//                               height: 50,
//                               width: double.infinity,
//                               padding: const EdgeInsets.all(8.0),
//                               decoration: BoxDecoration(
//                                 color: Colors.transparent,
//                                 borderRadius: BorderRadius.only(
//                                   topLeft: Radius.circular(20),
//                                   topRight: Radius.circular(20),
//                                 ),
//                               ),
//                               child: Text(
//                                 status,
//                                 style: AppTextStyles.interMedium14.copyWith(
//                                   color: theme.textColor,
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                               child: SingleChildScrollView(
//                                 child: Column(
//                                   children: [
//                                     ...revenues.asMap().entries.map((entry) {
//                                       final index = entry.key;
//                                       final transaction = entry.value;
//                                       final card = SizedBox(
//                                         width: 300,
//                                         child: TransactionCardRevenue(
//                                           revenue: transaction,
//                                           key: ValueKey(transaction.id),
//                                         ),
//                                       );

//                                       return Stack(
//                                         children: [
//                                           PieMenu(
//                                             key: ValueKey(transaction.id),
//                                             actions: pieMenuCrmRevenues(
//                                               ref: ref,
//                                               action: transaction,
//                                               actionId: transaction.id,
//                                               context: context,
//                                               textColor: theme.textColor,
//                                             ),
//                                             onPressedWithDevice: (kind) {
//                                               if (kind ==
//                                                       PointerDeviceKind.mouse ||
//                                                   kind ==
//                                                       PointerDeviceKind.touch) {
//                                                 if (isMobile) {
//                                                   showModalBottomSheet(
//                                                     context: context,
//                                                     isScrollControlled: true,
//                                                     backgroundColor:
//                                                         theme
//                                                             .dashboardContainer,
//                                                     shape: const RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.vertical(
//                                                             top:
//                                                                 Radius.circular(
//                                                                   12,
//                                                                 ),
//                                                           ),
//                                                     ),
//                                                     builder: (context) {
//                                                       return DraggableScrollableSheet(
//                                                         initialChildSize: 0.85,
//                                                         minChildSize: 0.4,
//                                                         maxChildSize: 0.95,
//                                                         expand: false,
//                                                         builder:
//                                                             (
//                                                               context,
//                                                               scrollController,
//                                                             ) => ExpensesViewDetailsWidget(
//                                                               revenue:
//                                                                   transaction,
//                                                               isMobile:
//                                                                   isMobile,
//                                                               scrollController:
//                                                                   scrollController,
//                                                             ),
//                                                       );
//                                                     },
//                                                   );
//                                                 }
//                                                 if (!isMobile) {
//                                                   showDialog(
//                                                     context: context,
//                                                     builder: (context) {
//                                                       return Dialog(
//                                                         insetPadding:
//                                                             const EdgeInsets.all(
//                                                               24,
//                                                             ), // Optional padding
//                                                         shape: RoundedRectangleBorder(
//                                                           borderRadius:
//                                                               BorderRadius.circular(
//                                                                 12,
//                                                               ),
//                                                         ),
//                                                         child: SizedBox(
//                                                           height:
//                                                               screenSize
//                                                                   .height /
//                                                               1.2,
//                                                           width:
//                                                               screenSize.width /
//                                                               1.2,
//                                                           child:
//                                                               ExpensesViewDetailsWidget(
//                                                                 revenue:
//                                                                     transaction,
//                                                               ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 }
//                                               }
//                                             },
//                                             child: DragTarget<
//                                               AgentRevenueModel
//                                             >(
//                                               onWillAccept: (incoming) => true,
//                                               onAccept: (incomingTransaction) {
//                                                 // Przenosimy transakcję na nową pozycję
//                                                 onMove(
//                                                   incomingTransaction,
//                                                   status,
//                                                   index,
//                                                 );
//                                               },
//                                               builder: (
//                                                 context,
//                                                 candidateData,
//                                                 rejectedData,
//                                               ) {
//                                                 return Column(
//                                                   children: [
//                                                     if (candidateData
//                                                         .isNotEmpty)
//                                                       // Separator przyciągania
//                                                       Container(
//                                                         color:
//                                                             AppColors.light50,
//                                                         child: Padding(
//                                                           padding:
//                                                               const EdgeInsets.all(
//                                                                 15.0,
//                                                               ),
//                                                           child: card,
//                                                         ),
//                                                       ),

//                                                     isMobile
//                                                         ? LongPressDraggable<
//                                                           AgentRevenueModel
//                                                         >(
//                                                           data: transaction,
//                                                           feedback: Material(
//                                                             color:
//                                                                 Colors
//                                                                     .transparent,
//                                                             child: Opacity(
//                                                               opacity: 0.7,
//                                                               child: card,
//                                                             ),
//                                                           ),
//                                                           childWhenDragging:
//                                                               Opacity(
//                                                                 opacity: 0.5,
//                                                                 child: card,
//                                                               ),
//                                                           child: card,
//                                                         )
//                                                         : Draggable<
//                                                           AgentRevenueModel
//                                                         >(
//                                                           data: transaction,
//                                                           feedback: Material(
//                                                             color:
//                                                                 Colors
//                                                                     .transparent,
//                                                             child: Opacity(
//                                                               opacity: 0.7,
//                                                               child: card,
//                                                             ),
//                                                           ),
//                                                           childWhenDragging:
//                                                               Opacity(
//                                                                 opacity: 0.5,
//                                                                 child: card,
//                                                               ),
//                                                           child: card,
//                                                         ),
//                                                   ],
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                           Positioned(
//                                             right: 2,
//                                             child: IconButton(
//                                               icon: AppIcons.delete(),
//                                               onPressed: () {
//                                                 debugPrint(
//                                                   'Mahdi: IconButton onPressed',
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         ],
//                                       );
//                                     }),
//                                     SizedBox(
//                                       width: double.infinity,
//                                       height: 45,
//                                       child: ElevatedButton(
//                                         style: elevatedButtonStyleRounded10,
//                                         onPressed: () {
//                                           if (isMobile) {
//                                             showModalBottomSheet(
//                                               context: context,
//                                               isScrollControlled: true,
//                                               backgroundColor:
//                                                   theme.dashboardContainer,
//                                               shape:
//                                                   const RoundedRectangleBorder(
//                                                     borderRadius:
//                                                         BorderRadius.vertical(
//                                                           top: Radius.circular(
//                                                             12,
//                                                           ),
//                                                         ),
//                                                   ),
//                                               builder: (context) {
//                                                 return DraggableScrollableSheet(
//                                                   initialChildSize: 0.85,
//                                                   minChildSize: 0.4,
//                                                   maxChildSize: 0.95,
//                                                   expand: false,
//                                                   builder:
//                                                       (
//                                                         context,
//                                                         scrollController,
//                                                       ) => AddInvoiceScreen(
//                                                         isMobile: isMobile,
//                                                         scrollController:
//                                                             scrollController,
//                                                       ),
//                                                 );
//                                               },
//                                             );
//                                           }
//                                           if (!isMobile) {
//                                             showDialog(
//                                               context: context,
//                                               barrierDismissible: true,
//                                               builder: (
//                                                 BuildContext dialogContext,
//                                               ) {
//                                                 return Dialog(
//                                                   insetPadding:
//                                                       const EdgeInsets.symmetric(
//                                                         horizontal: 24,
//                                                         vertical: 24,
//                                                       ),
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           12,
//                                                         ),
//                                                   ),
//                                                   child: SizedBox(
//                                                     width:
//                                                         MediaQuery.of(
//                                                           context,
//                                                         ).size.width *
//                                                         0.7,
//                                                     height:
//                                                         MediaQuery.of(
//                                                           context,
//                                                         ).size.height *
//                                                         0.85,
//                                                     child: AddInvoiceScreen(
//                                                       isMobile: false,
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );
//                                           }
//                                         },
//                                         child: AppIcons.add(
//                                           color: theme.textColor,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             DragTarget<AgentRevenueModel>(
//                               onWillAccept: (_) => true,
//                               onAccept: (incomingTransaction) {
//                                 onMove(
//                                   incomingTransaction,
//                                   status,
//                                   revenues.length,
//                                 );
//                               },
//                               builder: (context, candidateData, rejectedData) {
//                                 return candidateData.isNotEmpty
//                                     ? Container(
//                                       height: 10,
//                                       color:
//                                           candidateData.isNotEmpty
//                                               ? AppColors.light50
//                                               : theme.textColor,
//                                     )
//                                     : const SizedBox.shrink();
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                   const CustomVerticalDivider(),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
