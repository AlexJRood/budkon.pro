import 'dart:async';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

// class CreateDocumentSheet extends ConsumerStatefulWidget {
//   const CreateDocumentSheet({
//     super.key,
//     required this.scrollController,
//   });

//   final ScrollController scrollController;

//   @override
//   ConsumerState<CreateDocumentSheet> createState() =>
//       _CreateDocumentSheetState();
// }

// class _CreateDocumentSheetState extends ConsumerState<CreateDocumentSheet> {
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       ref.invalidate(documentsProvider);
//       ref.invalidate(documentTemplatesProvider);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // final documentsAsync = ref.watch(documentsProvider);
//     // final templatesAsync = ref.watch(documentTemplatesProvider);
//     final theme = ref.watch(themeColorsProvider);

//     return Container(
//       decoration: BoxDecoration(
//         color: theme.dashboardContainer,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
//       ),
//       child: DefaultTabController(
//         length: 2,
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 10),
//               child: Center(
//                 child: Container(
//                   width: 44,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: theme.textColor.withAlpha(80),
//                     borderRadius: BorderRadius.circular(99),
//                   ),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       "Documents",
//                       style: TextStyle(
//                         color: theme.textColor,
//                         fontWeight: FontWeight.w700,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.close, color: theme.textColor),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ],
//               ),
//             ),

//             TabBar(
//               labelColor: theme.textColor,
//               unselectedLabelColor: theme.textColor.withAlpha(153),
//               dividerColor: theme.bordercolor,
//               indicatorColor: theme.themeColor,
//               tabs: const [
//                 Tab(text: 'My Documents'),
//                 Tab(text: 'Templates'),
//               ],
//             ),

//             const SizedBox(height: 8),
//             Expanded(
//               child: TabBarView(
//                 children: [
//                   documentsAsync.when(
//                     loading: () => Center(child: AppLottie.loading(size: 250)),
//                     error: (error, _) => Center(
//                       child: Text(
//                         'Error: $error',
//                         style: TextStyle(color: theme.textColor),
//                       ),
//                     ),
//                     data: (documents) {
//                       if (documents.isEmpty) {
//                         return Center(child: AppLottie.noResults(size: 280));
//                       }

//                       return ListView.separated(
//                         controller: widget.scrollController,
//                         padding: const EdgeInsets.all(12),
//                         separatorBuilder: (_, __) =>
//                             Divider(color: theme.bordercolor),
//                         itemCount: documents.length,
//                         itemBuilder: (context, index) {
//                           final document = documents[index];
//                           return ListTile(
//                             title: Text(
//                               document.templateName,
//                               style: TextStyle(color: theme.textColor),
//                             ),
//                             subtitle: Text(
//                               'Last updated: ${DateFormat.yMd().add_Hm().format(document.updatedAt)}',
//                               style: TextStyle(
//                                 color: theme.textColor.withAlpha(204),
//                                 fontSize: 13,
//                               ),
//                             ),
//                             trailing: Chip(
//                               label: Text(
//                                 document.status,
//                                 style: TextStyle(color: theme.textColor),
//                               ),
//                               backgroundColor: theme.dashboardContainer,
//                             ),
//                             onTap: () {
//                               Navigator.pop(context, {
//                                 'type': 'document',
//                                 'id': document.id,
//                               });
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//                   templatesAsync.when(
//                     loading: () => Center(child: AppLottie.loading(size: 250)),
//                     error: (error, _) => Center(
//                       child: Text(
//                         'Error: $error',
//                         style: TextStyle(color: theme.textColor),
//                       ),
//                     ),
//                     data: (templates) {
//                       if (templates.isEmpty) {
//                         return Center(child: AppLottie.noResults(size: 280));
//                       }

//                       return ListView.separated(
//                         controller: widget.scrollController,
//                         padding: const EdgeInsets.all(12),
//                         separatorBuilder: (_, __) =>
//                             Divider(color: theme.bordercolor),
//                         itemCount: templates.length,
//                         itemBuilder: (context, index) {
//                           final template = templates[index];
//                           return ListTile(
//                             title: Text(
//                               template.name,
//                               style: TextStyle(color: theme.textColor),
//                             ),
//                             subtitle: Text(
//                               template.description,
//                               style: TextStyle(
//                                 color: theme.textColor.withAlpha(204),
//                               ),
//                             ),
//                             trailing: Icon(
//                               Icons.description_outlined,
//                               color: theme.textColor,
//                             ),
//                             onTap: () {
//                               Navigator.pop(context, {
//                                 'type': 'template',
//                                 'template': template,
//                                  'mode': 'edit',
//                               });
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: Text(
//                       'Close',
//                       style: TextStyle(color: theme.textColor),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
