// import 'dart:math' as math;

// import 'package:core/ui/anchors/anchor_target.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get_utils/get_utils.dart';
// import 'package:importer/tabs/batch_import_overlay.dart';
// import 'package:importer/tabs/mapping/models.dart';
// import 'package:core/theme/apptheme.dart';

// import '../import_state.dart';

// // ignore: unused_import
// import 'package:importer/emma/anchors/anchors_importer.dart';

// enum MapperViewMode {
//   list,
//   canvas,
// }

// class ImportTabFieldMapper extends ConsumerStatefulWidget {
//   final AsyncValue<ImportOptions> optionsAsync;
//   final ImportFormState formState;
//   final ImportFormNotifier formNotifier;

//   const ImportTabFieldMapper({
//     super.key,
//     required this.optionsAsync,
//     required this.formState,
//     required this.formNotifier,
//   });

//   @override
//   ConsumerState<ImportTabFieldMapper> createState() =>
//       _ImportTabFieldMapperState();
// }

// class _ImportTabFieldMapperState extends ConsumerState<ImportTabFieldMapper> {
//   String _sourceSearch = '';
//   String _targetSearch = '';
//   String? _selectedColumn;

//   bool _showOnlyUnmappedTargets = false;
//   bool _isEmmaPlanning = false;

//   MapperViewMode _viewMode = MapperViewMode.canvas;

//   bool get _isCompact => MediaQuery.of(context).size.width < 980;

//   void _showSnack(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message.tr)),
//     );
//   }

//   Future<void> _suggestFullPlanWithEmma({
//     required ThemeColors theme,
//     required ImportFormState formState,
//     required ImportFormNotifier formNotifier,
//   }) async {
//     final targetModel = formState.selectedTargetModel?.trim();

//     if (targetModel == null || targetModel.isEmpty) {
//       _showSnack('Najpierw wybierz model docelowy importu.');
//       return;
//     }

//     if (formState.previewColumns.isEmpty || formState.previewData.isEmpty) {
//       _showSnack('Brak danych w edytorze importu.');
//       return;
//     }

//     setState(() {
//       _isEmmaPlanning = true;
//     });

//     try {
//       final result = await formNotifier.requestEmmaFullPlan(
//         ref,
//         targetModel: targetModel,
//         maxRules: 40,
//         maxEntities: 5,
//         selectedRowsOnly: false,
//       );

//       if (!mounted) return;

//       if (result['ok'] != true) {
//         _showSnack(
//           result['error']?.toString() ?? 'Emma nie zwróciła planu importu.',
//         );
//         return;
//       }

//       await _showEmmaFullPlanSheet(
//         theme: theme,
//         formNotifier: formNotifier,
//         result: result,
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isEmmaPlanning = false;
//         });
//       }
//     }
//   }

//   Future<void> _showEmmaFullPlanSheet({
//     required ThemeColors theme,
//     required ImportFormNotifier formNotifier,
//     required Map<String, dynamic> result,
//   }) async {
//     final split = _asStringMap(result['split']);
//     final entityPlanResult = _asStringMap(result['entity_plan']);

//     final rulesRaw = split['rules'] ?? result['rules'];
//     final mappingHintsRaw = split['mapping_hints'] ?? result['mapping_hints'];
//     final warningsRaw = split['warnings'] ?? result['warnings'];

//     final entityPlan = _asStringMap(
//       entityPlanResult['plan'] ?? result['entity_plan_object'],
//     );

//     final rules = rulesRaw is List ? rulesRaw : <dynamic>[];
//     final mappingHints =
//         mappingHintsRaw is List ? mappingHintsRaw : <dynamic>[];
//     final warnings = warningsRaw is List ? warningsRaw : <dynamic>[];

//     final entitiesRaw = entityPlan['entities'];
//     final relationsRaw = entityPlan['relations'];

//     final entities = entitiesRaw is List ? entitiesRaw : <dynamic>[];
//     final relations = relationsRaw is List ? relationsRaw : <dynamic>[];

//     final summary = result['summary']?.toString() ??
//         split['summary']?.toString() ??
//         entityPlanResult['summary']?.toString() ??
//         'Emma przygotowała plan importu.';

//     await showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) {
//         return FractionallySizedBox(
//           heightFactor: 0.9,
//           child: Container(
//             decoration: BoxDecoration(
//               color: theme.dashboardContainer,
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(24),
//               ),
//               border: Border.all(
//                 color: theme.dashboardBoarder.withAlpha(120),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 42,
//                         height: 42,
//                         decoration: BoxDecoration(
//                           color: theme.themeColor.withAlpha(18),
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                         child: Icon(
//                           Icons.auto_awesome_rounded,
//                           color: theme.themeColor,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Plan Emmy'.tr,
//                               style: TextStyle(
//                                 color: theme.textColor,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w800,
//                               ),
//                             ),
//                             const SizedBox(height: 3),
//                             Text(
//                               summary.tr,
//                               style: TextStyle(
//                                 color: theme.textColor.withAlpha(170),
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () => Navigator.of(ctx).pop(),
//                         icon: Icon(
//                           Icons.close_rounded,
//                           color: theme.textColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Divider(
//                   height: 1,
//                   color: theme.dashboardBoarder.withAlpha(120),
//                 ),
//                 Expanded(
//                   child: ListView(
//                     padding: const EdgeInsets.all(16),
//                     children: [
//                       _EmmaMapperPlanSection(
//                         theme: theme,
//                         title: 'Transformacje / podział danych'.tr,
//                         emptyText: 'Brak transformacji do zastosowania.'.tr,
//                         items: rules,
//                         itemBuilder: (item) {
//                           final map = item is Map
//                               ? Map<String, dynamic>.from(item)
//                               : <String, dynamic>{};

//                           final source =
//                               map['source_column']?.toString() ?? '-';
//                           final output =
//                               map['output_column']?.toString() ?? '-';
//                           final transform =
//                               map['transform']?.toString() ?? '-';
//                           final confidence =
//                               _formatConfidence(map['confidence']);
//                           final reason = map['reason']?.toString() ?? '';

//                           return _EmmaMapperPlanCard(
//                             theme: theme,
//                             icon: Icons.functions_rounded,
//                             title: '$source → $output',
//                             subtitle: confidence.isEmpty
//                                 ? 'Transformacja: $transform'
//                                 : 'Transformacja: $transform • confidence: $confidence',
//                             description: reason,
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 14),
//                       _EmmaMapperPlanSection(
//                         theme: theme,
//                         title: 'Mapowania pól'.tr,
//                         emptyText: 'Brak sugestii mapowania.'.tr,
//                         items: mappingHints,
//                         itemBuilder: (item) {
//                           final map = item is Map
//                               ? Map<String, dynamic>.from(item)
//                               : <String, dynamic>{};

//                           final output =
//                               map['output_column']?.toString() ?? '-';
//                           final targetModel =
//                               map['target_model']?.toString() ?? '-';
//                           final targetField =
//                               map['target_field']?.toString() ?? '-';
//                           final confidence =
//                               _formatConfidence(map['confidence']);
//                           final reason = map['reason']?.toString() ?? '';

//                           return _EmmaMapperPlanCard(
//                             theme: theme,
//                             icon: Icons.link_rounded,
//                             title: '$output → $targetModel.$targetField',
//                             subtitle: confidence.isEmpty
//                                 ? 'Mapowanie'
//                                 : 'Mapowanie • confidence: $confidence',
//                             description: reason,
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 14),
//                       _EmmaMapperPlanSection(
//                         theme: theme,
//                         title: 'Encje / modele'.tr,
//                         emptyText:
//                             'Brak planu relacyjnego — import zostanie wykonany klasycznie.'
//                                 .tr,
//                         items: entities,
//                         itemBuilder: (item) {
//                           final map = item is Map
//                               ? Map<String, dynamic>.from(item)
//                               : <String, dynamic>{};

//                           final alias = map['alias']?.toString() ?? '-';
//                           final model = map['target_model']?.toString() ?? '-';
//                           final mappings = map['mappings'];
//                           final count = mappings is Map ? mappings.length : 0;

//                           return _EmmaMapperPlanCard(
//                             theme: theme,
//                             icon: Icons.account_tree_rounded,
//                             title: '$alias → $model',
//                             subtitle: 'Pól w encji: $count',
//                             description: map['reason']?.toString() ?? '',
//                           );
//                         },
//                       ),
//                       if (relations.isNotEmpty) ...[
//                         const SizedBox(height: 14),
//                         _EmmaMapperPlanSection(
//                           theme: theme,
//                           title: 'Relacje FK'.tr,
//                           emptyText: '',
//                           items: relations,
//                           itemBuilder: (item) {
//                             final map = item is Map
//                                 ? Map<String, dynamic>.from(item)
//                                 : <String, dynamic>{};

//                             final from =
//                                 map['from_alias']?.toString() ?? '-';
//                             final field = map['field']?.toString() ?? '-';
//                             final to = map['to_alias']?.toString() ?? '-';

//                             return _EmmaMapperPlanCard(
//                               theme: theme,
//                               icon: Icons.call_split_rounded,
//                               title: '$from.$field → $to',
//                               subtitle: 'ForeignKey',
//                               description: map['reason']?.toString() ?? '',
//                             );
//                           },
//                         ),
//                       ],
//                       if (warnings.isNotEmpty) ...[
//                         const SizedBox(height: 14),
//                         _EmmaMapperPlanSection(
//                           theme: theme,
//                           title: 'Ostrzeżenia'.tr,
//                           emptyText: '',
//                           items: warnings,
//                           itemBuilder: (item) {
//                             return _EmmaMapperPlanCard(
//                               theme: theme,
//                               icon: Icons.warning_amber_rounded,
//                               title: 'Uwaga'.tr,
//                               subtitle: item.toString(),
//                               description: '',
//                               accentColor: Colors.orangeAccent,
//                             );
//                           },
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//                 SafeArea(
//                   top: false,
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                     child: Row(
//                       children: [
//                         OutlinedButton(
//                           style: _outlinedActionStyle(theme),
//                           onPressed: () => Navigator.of(ctx).pop(),
//                           child: Text(
//                             'Anuluj'.tr,
//                             style: TextStyle(color: theme.textColor),
//                           ),
//                         ),
//                         const Spacer(),
//                         ElevatedButton.icon(
//                           style: _filledActionStyle(theme),
//                           onPressed: () async {
//                             final applyResult =
//                                 await formNotifier.applyEmmaFullPlanResult(
//                               result,
//                               applyTransforms: true,
//                               applyMappings: true,
//                               saveEntityPlan: true,
//                               minMappingConfidence: 0.35,
//                             );

//                             if (!ctx.mounted) return;

//                             Navigator.of(ctx).pop();

//                             final transformApplied = _emmaInt(
//                               _asStringMap(
//                                 applyResult['transform_result'],
//                               )['applied_count'],
//                             );

//                             final mappingApplied = _emmaInt(
//                               _asStringMap(
//                                 applyResult['mapping_result'],
//                               )['applied_count'],
//                             );

//                             final entityPlanSaved =
//                                 applyResult['entity_plan_saved'] == true;

//                             _showSnack(
//                               entityPlanSaved
//                                   ? 'Emma zastosowała: transformacje $transformApplied, mapowania $mappingApplied i zapisała plan relacji.'
//                                   : 'Emma zastosowała: transformacje $transformApplied, mapowania $mappingApplied.',
//                             );
//                           },
//                           icon: const Icon(Icons.check_rounded),
//                           label: Text('Zastosuj plan'.tr),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = ref.watch(themeColorsProvider);
//     final formState = widget.formState;
//     final formNotifier = widget.formNotifier;

//     final previewColumns = formState.previewColumns;
//     final previewData = formState.previewData;

//     return widget.optionsAsync.when(
//       data: (options) {
//         if (formState.file == null) {
//           return Center(
//             child: Text(
//               'Najpierw w zakładce "Plik" wybierz plik do importu.'.tr,
//               style: TextStyle(
//                 color: theme.textColor.withAlpha(178),
//               ),
//             ),
//           );
//         }

//         if (formState.previewColumns.isEmpty) {
//           return Center(
//             child: Text(
//               'Mapper pól wymaga podglądu kolumn (obsługiwany dla plików CSV).'
//                   .tr,
//               style: TextStyle(
//                 color: theme.textColor.withAlpha(178),
//               ),
//             ),
//           );
//         }

//         final allModelNames = options.targetModels.keys.toList()..sort();

//         if (allModelNames.isEmpty) {
//           return Center(
//             child: Text(
//               'Brak zdefiniowanych modeli docelowych po stronie backendu.'.tr,
//               style: TextStyle(color: theme.textColor),
//             ),
//           );
//         }

//         final selectedTargetModel = formState.selectedTargetModel?.trim();

//         final modelNames = [
//           if (selectedTargetModel != null &&
//               selectedTargetModel.isNotEmpty &&
//               allModelNames.contains(selectedTargetModel))
//             selectedTargetModel,
//           ...allModelNames.where((m) => m != selectedTargetModel),
//         ];

//         final validSelectedColumn =
//             _selectedColumn != null && previewColumns.contains(_selectedColumn)
//                 ? _selectedColumn
//                 : null;

//         final mappedColumns = previewColumns.where((col) {
//           return formState.fieldMappings.any((m) => m.columnName == col);
//         }).toList(growable: false);

//         final mappingSummary = formState.fieldMappings
//             .where(
//               (m) =>
//                   previewColumns.contains(m.columnName) &&
//                   m.targetModel.isNotEmpty &&
//                   m.targetField.isNotEmpty,
//             )
//             .toList(growable: false);

//         final sourceSearchLower = _sourceSearch.trim().toLowerCase();

//         final filteredSourceColumns = previewColumns.where((col) {
//           if (sourceSearchLower.isEmpty) return true;
//           return col.toLowerCase().contains(sourceSearchLower);
//         }).toList(growable: false);

//         return EmmaUiAnchorTarget(
//           // @emma-backend: ImporterEmmaAnchors.importMapperRoot
//           anchorKey: 'importer.mapper.root',
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   EmmaUiAnchorTarget(
//                     // @emma-backend: ImporterEmmaAnchors.importMapperToolbar
//                     anchorKey: 'importer.mapper.toolbar',
//                     child:  _MapperTopToolbar(
//                         theme: theme,
//                         viewMode: _viewMode,
//                         selectedColumn: validSelectedColumn,
//                         mappedCount: mappedColumns.length,
//                         totalCount: previewColumns.length,
//                         currentMappings: mappingSummary.length,
//                         hasEntityPlan:
//                             _hasValidEmmaEntityPlan(formState.emmaEntityPlan),
//                         isEmmaPlanning: _isEmmaPlanning,
//                         targetModels: allModelNames,
//                         selectedTargetModel: selectedTargetModel,
//                         onTargetModelChanged: (model) {
//                           formNotifier.setTargetModel(model);

//                           setState(() {
//                             _targetSearch = '';
//                           });
//                         },
//                         onSuggestWithEmma: () {
//                           _suggestFullPlanWithEmma(
//                             theme: theme,
//                             formState: formState,
//                             formNotifier: formNotifier,
//                           );
//                         },
//                         onChangeView: (mode) {
//                           setState(() {
//                             _viewMode = mode;
//                           });
//                         },
//                         onClearSelected: () {
//                           setState(() {
//                             _selectedColumn = null;
//                           });
//                         },
//                     ),
//                   ),
//                   Expanded(
//                     child: _viewMode == MapperViewMode.canvas
//                         ? EmmaUiAnchorTarget(
//                             // @emma-backend: ImporterEmmaAnchors.importMapperCanvas
//                             anchorKey: 'importer.mapper.canvas_container',
//                             child: MapperCanvasView(
//                               rootAnchorKey: 'importer.mapper.canvas',
//                               theme: theme,
//                               options: options,
//                               formState: formState,
//                               formNotifier: formNotifier,
//                               selectedColumn: validSelectedColumn,
//                               selectedTargetModel: selectedTargetModel,
//                               minScale: 0.16,
//                               maxScale: 2.4,
//                               showFullscreenButton: true,
//                               onOpenFullscreen: () {
//                                 _openCanvasFullscreen(
//                                   context: context,
//                                   theme: theme,
//                                   options: options,
//                                   formNotifier: formNotifier,
//                                   initialSelectedColumn: validSelectedColumn,
//                                   initialSelectedTargetModel:
//                                       selectedTargetModel,
//                                 );
//                               },
//                               onSelectColumn: (column) {
//                                 setState(() {
//                                   _selectedColumn = column;
//                                 });
//                               },
//                             ),
//                           )
//                         : (_isCompact
//                             ? Column(
//                                 children: [
//                                   Expanded(
//                                     child: EmmaUiAnchorTarget(
//                                       // @emma-backend: ImporterEmmaAnchors.importMapperSourcePanel
//                                       anchorKey:
//                                           'importer.mapper.source_columns_panel',
//                                       child: _SourceColumnsPanel(
//                                         theme: theme,
//                                         columns: filteredSourceColumns,
//                                         previewColumns: previewColumns,
//                                         previewData: previewData,
//                                         formState: formState,
//                                         selectedColumn: validSelectedColumn,
//                                         sourceSearch: _sourceSearch,
//                                         onSearchChanged: (value) {
//                                           setState(() {
//                                             _sourceSearch = value;
//                                           });
//                                         },
//                                         onSelectColumn: (column) {
//                                           setState(() {
//                                             _selectedColumn = column;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 12),
//                                   Expanded(
//                                     child: EmmaUiAnchorTarget(
//                                       // @emma-backend: ImporterEmmaAnchors.importMapperTargetPanel
//                                       anchorKey:
//                                           'importer.mapper.target_models_panel',
//                                       child: _TargetModelsPanel(
//                                         theme: theme,
//                                         options: options,
//                                         modelNames: modelNames,
//                                         selectedTargetModel:
//                                             selectedTargetModel,
//                                         previewColumns: previewColumns,
//                                         previewData: previewData,
//                                         formState: formState,
//                                         formNotifier: formNotifier,
//                                         targetSearch: _targetSearch,
//                                         showOnlyUnmappedTargets:
//                                             _showOnlyUnmappedTargets,
//                                         selectedColumn: validSelectedColumn,
//                                         onSearchChanged: (value) {
//                                           setState(() {
//                                             _targetSearch = value;
//                                           });
//                                         },
//                                         onToggleOnlyUnmapped: (value) {
//                                           setState(() {
//                                             _showOnlyUnmappedTargets = value;
//                                           });
//                                         },
//                                         onAssignFromSelected: (model, field) {
//                                           if (validSelectedColumn == null) {
//                                             return;
//                                           }

//                                           formNotifier.setMappingForTarget(
//                                             columnName: validSelectedColumn,
//                                             targetModel: model,
//                                             targetField: field,
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             : Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     flex: 11,
//                                     child: EmmaUiAnchorTarget(
//                                       // @emma-backend: ImporterEmmaAnchors.importMapperSourcePanel
//                                       anchorKey:
//                                           'importer.mapper.source_columns_panel',
//                                       child: _SourceColumnsPanel(
//                                         theme: theme,
//                                         columns: filteredSourceColumns,
//                                         previewColumns: previewColumns,
//                                         previewData: previewData,
//                                         formState: formState,
//                                         selectedColumn: validSelectedColumn,
//                                         sourceSearch: _sourceSearch,
//                                         onSearchChanged: (value) {
//                                           setState(() {
//                                             _sourceSearch = value;
//                                           });
//                                         },
//                                         onSelectColumn: (column) {
//                                           setState(() {
//                                             _selectedColumn = column;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     flex: 16,
//                                     child: EmmaUiAnchorTarget(
//                                       // @emma-backend: ImporterEmmaAnchors.importMapperTargetPanel
//                                       anchorKey:
//                                           'importer.mapper.target_models_panel',
//                                       child: _TargetModelsPanel(
//                                         theme: theme,
//                                         options: options,
//                                         modelNames: modelNames,
//                                         selectedTargetModel:
//                                             selectedTargetModel,
//                                         previewColumns: previewColumns,
//                                         previewData: previewData,
//                                         formState: formState,
//                                         formNotifier: formNotifier,
//                                         targetSearch: _targetSearch,
//                                         showOnlyUnmappedTargets:
//                                             _showOnlyUnmappedTargets,
//                                         selectedColumn: validSelectedColumn,
//                                         onSearchChanged: (value) {
//                                           setState(() {
//                                             _targetSearch = value;
//                                           });
//                                         },
//                                         onToggleOnlyUnmapped: (value) {
//                                           setState(() {
//                                             _showOnlyUnmappedTargets = value;
//                                           });
//                                         },
//                                         onAssignFromSelected: (model, field) {
//                                           if (validSelectedColumn == null) {
//                                             return;
//                                           }

//                                           formNotifier.setMappingForTarget(
//                                             columnName: validSelectedColumn,
//                                             targetModel: model,
//                                             targetField: field,
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               )),
//                   ),
//                 ],
//               ),
//         );
//       },
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (err, _) => Center(
//         child: Text(
//           'Błąd pobierania opcji importu: $err',
//           style: const TextStyle(color: Colors.redAccent),
//         ),
//       ),
//     );
//   }

//   void _openBatchOverlay(BuildContext context, ThemeColors theme) {
//     final isCompact = MediaQuery.of(context).size.width < 900;

//     if (isCompact) {
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (ctx) {
//           return SafeArea(
//             child: Container(
//               height: MediaQuery.of(ctx).size.height * 0.92,
//               decoration: BoxDecoration(
//                 color: theme.dashboardContainer,
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(24),
//                 ),
//               ),
//               child: const BatchImportOverlay(),
//             ),
//           );
//         },
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) {
//         return Dialog(
//           backgroundColor: theme.dashboardContainer,
//           insetPadding: const EdgeInsets.all(24),
//           child: const SizedBox(
//             width: 800,
//             height: 520,
//             child: BatchImportOverlay(),
//           ),
//         );
//       },
//     );
//   }

//   void _openCanvasFullscreen({
//     required BuildContext context,
//     required ThemeColors theme,
//     required ImportOptions options,
//     required ImportFormNotifier formNotifier,
//     required String? initialSelectedColumn,
//     required String? initialSelectedTargetModel,
//   }) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierColor: Colors.black.withAlpha(220),
//       builder: (dialogContext) {
//         String? fullscreenSelectedColumn = initialSelectedColumn;

//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return Consumer(
//               builder: (context, ref, _) {
//                 final latestFormState = ref.watch(importFormProvider);
//                 final latestSelectedTargetModel =
//                     latestFormState.selectedTargetModel?.trim();

//                 return EmmaUiAnchorTarget(
//                   // @emma-backend: ImporterEmmaAnchors.importMapperCanvasFullscreen
//                   anchorKey: 'importer.mapper.canvas_fullscreen',
//                   child: Dialog(
//                     insetPadding: EdgeInsets.zero,
//                     backgroundColor: Colors.transparent,
//                     child: Material(
//                       color: theme.dashboardContainer,
//                       child: SafeArea(
//                         child: Column(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                               decoration: BoxDecoration(
//                                 border: Border(
//                                   bottom: BorderSide(
//                                     color:
//                                         theme.dashboardBoarder.withAlpha(110),
//                                   ),
//                                 ),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.open_in_full_rounded,
//                                     color: theme.themeColor,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Text(
//                                       'Mapper canvas — fullscreen'.tr,
//                                       style: TextStyle(
//                                         color: theme.textColor,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                                   ),
//                                   if (latestSelectedTargetModel != null &&
//                                       latestSelectedTargetModel.isNotEmpty)
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 10,
//                                         vertical: 6,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: theme.themeColor.withAlpha(24),
//                                         borderRadius:
//                                             BorderRadius.circular(999),
//                                         border: Border.all(
//                                           color:
//                                               theme.themeColor.withAlpha(120),
//                                         ),
//                                       ),
//                                       child: Text(
//                                         'Model: $latestSelectedTargetModel',
//                                         style: TextStyle(
//                                           color: theme.textColor,
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                   if (fullscreenSelectedColumn != null) ...[
//                                     const SizedBox(width: 10),
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 10,
//                                         vertical: 6,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: theme.themeColor.withAlpha(24),
//                                         borderRadius:
//                                             BorderRadius.circular(999),
//                                         border: Border.all(
//                                           color:
//                                               theme.themeColor.withAlpha(120),
//                                         ),
//                                       ),
//                                       child: Text(
//                                         'Aktywna: $fullscreenSelectedColumn',
//                                         style: TextStyle(
//                                           color: theme.textColor,
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                   const SizedBox(width: 10),
//                                   IconButton(
//                                     tooltip: 'Zamknij'.tr,
//                                     onPressed: () =>
//                                         Navigator.of(dialogContext).pop(),
//                                     icon: const Icon(Icons.close_rounded),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Expanded(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(12),
//                                 child: MapperCanvasView(
//                                   rootAnchorKey:
//                                       'importer.mapper.canvas_fullscreen.body',
//                                   theme: theme,
//                                   options: options,
//                                   formState: latestFormState,
//                                   formNotifier: formNotifier,
//                                   selectedColumn: fullscreenSelectedColumn,
//                                   selectedTargetModel:
//                                       latestSelectedTargetModel ??
//                                           initialSelectedTargetModel,
//                                   minScale: 0.06,
//                                   maxScale: 3.2,
//                                   showFullscreenButton: false,
//                                   onOpenFullscreen: null,
//                                   onSelectColumn: (column) {
//                                     setModalState(() {
//                                       fullscreenSelectedColumn = column;
//                                     });

//                                     setState(() {
//                                       _selectedColumn = column;
//                                     });
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }

// class _MapperHeaderAndToolbar extends StatelessWidget {
//   final ThemeColors theme;
//   final bool isCompact;
//   final Widget toolbar;

//   const _MapperHeaderAndToolbar({
//     required this.theme,
//     required this.isCompact,
//     required this.toolbar,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final title = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Mapper pól – widok wizualny'.tr,
//           style: TextStyle(
//             color: theme.textColor,
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Najpierw wybierz model docelowy, potem przypnij kolumny do pól. '
//                   'Pola relacyjne są oznaczone jako FK.'
//               .tr,
//           style: TextStyle(
//             color: theme.textColor.withAlpha(178),
//             fontSize: 11,
//           ),
//         ),
//       ],
//     );

//     if (isCompact) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           title,
//           const SizedBox(height: 10),
//           toolbar,
//         ],
//       );
//     }

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(child: title),
//         const SizedBox(width: 16),
//         Flexible(
//           child: Align(
//             alignment: Alignment.centerRight,
//             child: toolbar,
//           ),
//         ),
//       ],
//     );
//   }
// }













// const double _mapperToolbarControlHeight = 34.0;
// const double _mapperToolbarOneLineHeight = 46.0;
// const double _mapperToolbarIconButtonWidth = 36.0;
// const double _mapperToolbarRadius = 12.0;

// class _MapperTopToolbar extends StatelessWidget {
//   final ThemeColors theme;
//   final MapperViewMode viewMode;
//   final String? selectedColumn;
//   final int mappedCount;
//   final int totalCount;
//   final int currentMappings;
//   final bool hasEntityPlan;
//   final bool isEmmaPlanning;

//   final List<String> targetModels;
//   final String? selectedTargetModel;
//   final ValueChanged<String?> onTargetModelChanged;

//   final ValueChanged<MapperViewMode> onChangeView;
//   final VoidCallback onClearSelected;
//   final VoidCallback onSuggestWithEmma;

//   const _MapperTopToolbar({
//     required this.theme,
//     required this.viewMode,
//     required this.selectedColumn,
//     required this.mappedCount,
//     required this.totalCount,
//     required this.currentMappings,
//     required this.hasEntityPlan,
//     required this.isEmmaPlanning,
//     required this.targetModels,
//     required this.selectedTargetModel,
//     required this.onTargetModelChanged,
//     required this.onChangeView,
//     required this.onClearSelected,
//     required this.onSuggestWithEmma,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final oneLine = constraints.maxWidth >= 1100;

//         final toolbarChildren = <Widget>[
          
//           Row(
//             spacing: 6,
//             children: [
              
//           EmmaUiAnchorTarget(
//             anchorKey: 'importer.mapper.emma_suggest_full_plan',
//             child: _MapperToolbarPrimaryButton(
//               theme: theme,
//               isLoading: isEmmaPlanning,
//               onPressed: isEmmaPlanning ? null : onSuggestWithEmma,
//             ),
//           ),
//           _MapperTargetModelSelect(
//             theme: theme,
//             width: oneLine ? 250 : 300,
//             models: targetModels,
//             selectedModel: selectedTargetModel,
//             onChanged: onTargetModelChanged,
//           ),

          
//             ],
//           ),



//           _MapperToolbarStatsStrip(
//             theme: theme,
//             mappedCount: mappedCount,
//             totalCount: totalCount,
//             currentMappings: currentMappings,
//             hasEntityPlan: hasEntityPlan,
//           ),

//           Row(
//             spacing: 6,
//             children: [
//           if (selectedColumn != null)
//             EmmaUiAnchorTarget(
//               anchorKey: 'importer.mapper.active_column_chip',
//               child: _MapperActiveColumnChip(
//                 theme: theme,
//                 selectedColumn: selectedColumn!,
//                 onClearSelected: onClearSelected,
//               ),
//             ),
//           EmmaUiAnchorTarget(
//             anchorKey: 'importer.mapper.view_mode_switch',
//             child: _MapperToolbarViewModeSwitch(
//               theme: theme,
//               viewMode: viewMode,
//               onChangeView: onChangeView,
//                 ),
//               ),
//             ],
//           ),
//         ];

//         return SizedBox(
//           width: double.infinity,
//           child: Container(
//             width: double.infinity,
//             height: oneLine ? _mapperToolbarOneLineHeight : null,
//             padding: EdgeInsets.symmetric(
//               horizontal: 8,
//               vertical: oneLine ? 6 : 8,
//             ),
//             decoration: BoxDecoration(
//               color: theme.adPopBackground,
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: theme.dashboardBoarder.withAlpha(90),
//               ),
//             ),
//             child: oneLine
//                 ? SizedBox(
//                     height: _mapperToolbarControlHeight,
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       physics: const ClampingScrollPhysics(),
//                       child: ConstrainedBox(
//                         constraints: BoxConstraints(
//                           minWidth: math.max(0, constraints.maxWidth - 16),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.max,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             for (var i = 0;
//                                 i < toolbarChildren.length;
//                                 i++) ...[
//                               toolbarChildren[i],
//                               if (i != toolbarChildren.length - 1)
//                                 const SizedBox(width: 7),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),
//                   )
//                 : Wrap(
//                     spacing: 7,
//                     runSpacing: 7,
//                     crossAxisAlignment: WrapCrossAlignment.center,
//                     children: toolbarChildren,
//                   ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _MapperTargetModelSelect extends StatelessWidget {
//   final ThemeColors theme;
//   final double width;
//   final List<String> models;
//   final String? selectedModel;
//   final ValueChanged<String?> onChanged;

//   const _MapperTargetModelSelect({
//     required this.theme,
//     required this.width,
//     required this.models,
//     required this.selectedModel,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final safeSelected =
//         selectedModel != null && models.contains(selectedModel)
//             ? selectedModel
//             : null;

//     return SizedBox(
//       width: width,
//       height: _mapperToolbarControlHeight,
//       child: EmmaUiAnchorTarget(
//         anchorKey: 'importer.mapper.target_model_picker',
//         child: DropdownButtonFormField<String>(
//           value: safeSelected,
//           dropdownColor: theme.dashboardContainer,
//           isDense: true,
//           iconSize: 18,
//           iconEnabledColor: theme.textColor.withAlpha(145),
//           iconDisabledColor: theme.textColor.withAlpha(80),
//           hint: Text(
//             'Wybierz model'.tr,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: theme.textColor.withAlpha(120),
//               fontSize: 11.5,
//               height: 1.0,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           style: TextStyle(
//             color: theme.textColor,
//             fontSize: 11.5,
//             height: 1.0,
//             fontWeight: FontWeight.w600,
//           ),
//           decoration: _mapperToolbarInputDecoration(
//             theme: theme,
//             hint: '',
//             icon: Icons.account_tree_rounded,
//           ).copyWith(
//             hintText: null,
//             hintStyle: null,
//           ),
//           selectedItemBuilder: (context) {
//             return models.map((model) {
//               return Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   model,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: theme.textColor,
//                     fontSize: 11.5,
//                     height: 1.0,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               );
//             }).toList();
//           },
//           items: models.map((model) {
//             final active = model == safeSelected;

//             return DropdownMenuItem<String>(
//               value: model,
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.table_chart_rounded,
//                     size: 15,
//                     color: active
//                         ? theme.themeColor
//                         : theme.textColor.withAlpha(150),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       model,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: theme.textColor,
//                         fontSize: 12,
//                         height: 1.0,
//                         fontWeight:
//                             active ? FontWeight.w800 : FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }
// }

// class _MapperToolbarPrimaryButton extends StatelessWidget {
//   final ThemeColors theme;
//   final bool isLoading;
//   final VoidCallback? onPressed;

//   const _MapperToolbarPrimaryButton({
//     required this.theme,
//     required this.isLoading,
//     required this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: _mapperToolbarControlHeight,
//       child: ElevatedButton.icon(
//         style: _mapperToolbarFilledStyle(theme),
//         onPressed: onPressed,
//         icon: isLoading
//             ? const SizedBox(
//                 width: 13,
//                 height: 13,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               )
//             : const Icon(
//                 Icons.auto_awesome_rounded,
//                 size: 15,
//               ),
//         label: Text(
//           isLoading ? 'Analizuje...'.tr : 'Emma: mapowanie'.tr,
//           style: const TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w800,
//             height: 1.0,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MapperToolbarStatsStrip extends StatelessWidget {
//   final ThemeColors theme;
//   final int mappedCount;
//   final int totalCount;
//   final int currentMappings;
//   final bool hasEntityPlan;

//   const _MapperToolbarStatsStrip({
//     required this.theme,
//     required this.mappedCount,
//     required this.totalCount,
//     required this.currentMappings,
//     required this.hasEntityPlan,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: _mapperToolbarControlHeight,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: theme.dashboardContainer.withAlpha(165),
//         borderRadius: BorderRadius.circular(_mapperToolbarRadius),
//         border: Border.all(
//           color: theme.dashboardBoarder.withAlpha(85),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _MapperToolbarStatText(
//             theme: theme,
//             label: 'Mapowania'.tr,
//             value: '$currentMappings',
//             icon: Icons.link_rounded,
//             accent: currentMappings > 0,
//           ),
//           _MapperToolbarMiniDivider(theme: theme),
//           _MapperToolbarStatText(
//             theme: theme,
//             label: 'Zmapowane'.tr,
//             value: '$mappedCount/$totalCount',
//             icon: Icons.check_circle_outline,
//             accent: mappedCount > 0,
//           ),
//           _MapperToolbarMiniDivider(theme: theme),
//           _MapperToolbarStatText(
//             theme: theme,
//             label: 'Plan FK'.tr,
//             value: hasEntityPlan ? 'OK'.tr : 'Brak'.tr,
//             icon: Icons.account_tree_rounded,
//             accent: hasEntityPlan,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MapperToolbarStatText extends StatelessWidget {
//   final ThemeColors theme;
//   final String label;
//   final String value;
//   final IconData icon;
//   final bool accent;

//   const _MapperToolbarStatText({
//     required this.theme,
//     required this.label,
//     required this.value,
//     required this.icon,
//     this.accent = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Tooltip(
//       message: '$label: $value',
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: 13,
//             color: accent ? theme.themeColor : theme.textColor.withAlpha(135),
//           ),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: theme.textColor.withAlpha(145),
//               fontSize: 10,
//               fontWeight: FontWeight.w600,
//               height: 1.0,
//             ),
//           ),
//           const SizedBox(width: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: accent ? theme.themeColor : theme.textColor,
//               fontSize: 11,
//               fontWeight: FontWeight.w900,
//               height: 1.0,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MapperActiveColumnChip extends StatelessWidget {
//   final ThemeColors theme;
//   final String selectedColumn;
//   final VoidCallback onClearSelected;

//   const _MapperActiveColumnChip({
//     required this.theme,
//     required this.selectedColumn,
//     required this.onClearSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: _mapperToolbarControlHeight,
//       constraints: const BoxConstraints(maxWidth: 260),
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: theme.themeColor.withAlpha(22),
//         borderRadius: BorderRadius.circular(_mapperToolbarRadius),
//         border: Border.all(
//           color: theme.themeColor.withAlpha(130),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.ads_click_rounded,
//             size: 15,
//             color: theme.themeColor,
//           ),
//           const SizedBox(width: 6),
//           Flexible(
//             child: Text(
//               '${'Aktywna'.tr}: $selectedColumn',
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 color: theme.textColor,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w800,
//                 height: 1.0,
//               ),
//             ),
//           ),
//           const SizedBox(width: 6),
//           InkWell(
//             borderRadius: BorderRadius.circular(999),
//             onTap: onClearSelected,
//             child: Padding(
//               padding: const EdgeInsets.all(2),
//               child: Icon(
//                 Icons.close_rounded,
//                 size: 14,
//                 color: theme.textColor.withAlpha(170),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MapperToolbarViewModeSwitch extends StatelessWidget {
//   final ThemeColors theme;
//   final MapperViewMode viewMode;
//   final ValueChanged<MapperViewMode> onChangeView;

//   const _MapperToolbarViewModeSwitch({
//     required this.theme,
//     required this.viewMode,
//     required this.onChangeView,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: _mapperToolbarControlHeight,
//       padding: const EdgeInsets.all(3),
//       decoration: BoxDecoration(
//         color: theme.dashboardContainer.withAlpha(190),
//         borderRadius: BorderRadius.circular(_mapperToolbarRadius),
//         border: Border.all(
//           color: theme.dashboardBoarder.withAlpha(95),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _MapperViewModeSegment(
//             anchorKey: 'importer.mapper.view_mode.list',
//             theme: theme,
//             label: 'Lista'.tr,
//             icon: Icons.view_list_rounded,
//             isActive: viewMode == MapperViewMode.list,
//             onTap: () => onChangeView(MapperViewMode.list),
//           ),
//           const SizedBox(width: 3),
//           _MapperViewModeSegment(
//             anchorKey: 'importer.mapper.view_mode.canvas',
//             theme: theme,
//             label: 'Canvas'.tr,
//             icon: Icons.hub_rounded,
//             isActive: viewMode == MapperViewMode.canvas,
//             onTap: () => onChangeView(MapperViewMode.canvas),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MapperViewModeSegment extends StatelessWidget {
//   final String anchorKey;
//   final ThemeColors theme;
//   final String label;
//   final IconData icon;
//   final bool isActive;
//   final VoidCallback onTap;

//   const _MapperViewModeSegment({
//     required this.anchorKey,
//     required this.theme,
//     required this.label,
//     required this.icon,
//     required this.isActive,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return EmmaUiAnchorTarget(
//       anchorKey: anchorKey,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(9),
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 140),
//           height: _mapperToolbarControlHeight - 8,
//           padding: const EdgeInsets.symmetric(horizontal: 9),
//           decoration: BoxDecoration(
//             color: isActive
//                 ? theme.themeColor.withAlpha(24)
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(9),
//             border: Border.all(
//               color: isActive
//                   ? theme.themeColor.withAlpha(130)
//                   : Colors.transparent,
//             ),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 size: 14,
//                 color: isActive
//                     ? theme.themeColor
//                     : theme.textColor.withAlpha(170),
//               ),
//               const SizedBox(width: 5),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: theme.textColor,
//                   fontSize: 10.5,
//                   fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
//                   height: 1.0,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MapperToolbarMiniDivider extends StatelessWidget {
//   final ThemeColors theme;

//   const _MapperToolbarMiniDivider({
//     required this.theme,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 1,
//       height: 16,
//       margin: const EdgeInsets.symmetric(horizontal: 8),
//       color: theme.dashboardBoarder.withAlpha(80),
//     );
//   }
// }

// InputDecoration _mapperToolbarInputDecoration({
//   required ThemeColors theme,
//   required String hint,
//   required IconData icon,
// }) {
//   return InputDecoration(
//     hintText: hint.trim().isEmpty ? null : hint,
//     hintStyle: TextStyle(
//       color: theme.textColor.withAlpha(120),
//       fontSize: 11.5,
//       height: 1.0,
//     ),
//     isDense: true,
//     filled: true,
//     fillColor: theme.dashboardContainer.withAlpha(190),
//     constraints: const BoxConstraints.tightFor(
//       height: _mapperToolbarControlHeight,
//     ),
//     contentPadding: const EdgeInsets.symmetric(
//       horizontal: 8,
//       vertical: 0,
//     ),
//     prefixIcon: Icon(
//       icon,
//       color: theme.textColor.withAlpha(145),
//       size: 15,
//     ),
//     prefixIconConstraints: const BoxConstraints(
//       minWidth: 30,
//       minHeight: _mapperToolbarControlHeight,
//     ),
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(_mapperToolbarRadius),
//       borderSide: BorderSide(
//         color: theme.dashboardBoarder.withAlpha(90),
//       ),
//     ),
//     enabledBorder: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(_mapperToolbarRadius),
//       borderSide: BorderSide(
//         color: theme.dashboardBoarder.withAlpha(90),
//       ),
//     ),
//     focusedBorder: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(_mapperToolbarRadius),
//       borderSide: BorderSide(
//         color: theme.themeColor.withAlpha(155),
//       ),
//     ),
//   );
// }

// ButtonStyle _mapperToolbarFilledStyle(ThemeColors theme) {
//   return ElevatedButton.styleFrom(
//     foregroundColor: Colors.white,
//     backgroundColor: theme.themeColor,
//     minimumSize: const Size(0, _mapperToolbarControlHeight),
//     maximumSize: const Size(double.infinity, _mapperToolbarControlHeight),
//     padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
//     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     visualDensity: VisualDensity.compact,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(_mapperToolbarRadius),
//     ),
//     elevation: 0,
//   );
// }





// class _SourceColumnsPanel extends StatelessWidget {
//   final ThemeColors theme;
//   final List<String> columns;
//   final List<String> previewColumns;
//   final List<List<String>> previewData;
//   final ImportFormState formState;
//   final String? selectedColumn;
//   final String sourceSearch;
//   final ValueChanged<String> onSearchChanged;
//   final ValueChanged<String> onSelectColumn;

//   const _SourceColumnsPanel({
//     required this.theme,
//     required this.columns,
//     required this.previewColumns,
//     required this.previewData,
//     required this.formState,
//     required this.selectedColumn,
//     required this.sourceSearch,
//     required this.onSearchChanged,
//     required this.onSelectColumn,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: theme.adPopBackground,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: theme.dashboardBoarder.withAlpha(100)),
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         children: [
//           _PanelHeader(
//             theme: theme,
//             title: 'Kolumny źródłowe'.tr,
//             subtitle: 'Kliknij kolumnę, żeby ustawić ją jako aktywną.'.tr,
//           ),
//           const SizedBox(height: 10),
//           EmmaUiAnchorTarget(
//             // @emma-backend: ImporterEmmaAnchors.importMapperSourceSearch
//             anchorKey: 'importer.mapper.source_search',
//             child: TextField(
//               onChanged: onSearchChanged,
//               decoration: InputDecoration(
//                 isDense: true,
//                 prefixIcon: const Icon(Icons.search_rounded),
//                 filled: true,
//                 fillColor: theme.dashboardContainer,
//                 labelText: 'Szukaj kolumny'.tr,
//                 labelStyle: TextStyle(
//                   color: theme.textColor.withAlpha(160),
//                   fontSize: 12,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Expanded(
//             child: columns.isEmpty
//                 ? Center(
//                     child: Text(
//                       'Brak kolumn pasujących do wyszukiwania.'.tr,
//                       style: TextStyle(
//                         color: theme.textColor.withAlpha(170),
//                       ),
//                     ),
//                   )
//                 : ListView.separated(
//                     itemCount: columns.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 8),
//                     itemBuilder: (ctx, index) {
//                       final col = columns[index];
//                       final mappings = formState.fieldMappings
//                           .where((m) => m.columnName == col)
//                           .toList(growable: false);

//                       final samples = _samplesForColumn(
//                         previewColumns: previewColumns,
//                         previewData: previewData,
//                         columnName: col,
//                         maxItems: 3,
//                       );

//                       return _SourceColumnCard(
//                         theme: theme,
//                         columnName: col,
//                         isSelected: selectedColumn == col,
//                         mappings: mappings,
//                         samples: samples,
//                         onTap: () => onSelectColumn(col),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SourceColumnCard extends StatelessWidget {
//   final ThemeColors theme;
//   final String columnName;
//   final bool isSelected;
//   final List<FieldMappingRule> mappings;
//   final List<String> samples;
//   final VoidCallback onTap;

//   const _SourceColumnCard({
//     required this.theme,
//     required this.columnName,
//     required this.isSelected,
//     required this.mappings,
//     required this.samples,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isMapped = mappings.isNotEmpty;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(14),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 160),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? theme.themeColor.withAlpha(26)
//               : theme.dashboardContainer,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isSelected
//                 ? theme.themeColor
//                 : theme.dashboardBoarder.withAlpha(120),
//             width: isSelected ? 1.4 : 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   isMapped
//                       ? Icons.check_circle_rounded
//                       : Icons.radio_button_unchecked_rounded,
//                   size: 16,
//                   color: isMapped
//                       ? Colors.greenAccent.shade400
//                       : theme.textColor.withAlpha(130),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     columnName,
//                     style: TextStyle(
//                       color: theme.textColor,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//                 if (isSelected)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: theme.themeColor,
//                       borderRadius: BorderRadius.circular(999),
//                     ),
//                     child: const Text(
//                       'ACTIVE',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 9,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             if (mappings.isEmpty)
//               Text(
//                 'Jeszcze nieprzypisana'.tr,
//                 style: TextStyle(
//                   color: theme.textColor.withAlpha(160),
//                   fontSize: 11,
//                 ),
//               )
//             else
//               Wrap(
//                 spacing: 6,
//                 runSpacing: 6,
//                 children: mappings.map((m) {
//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: theme.adPopBackground,
//                       borderRadius: BorderRadius.circular(999),
//                       border: Border.all(
//                         color: theme.dashboardBoarder.withAlpha(100),
//                       ),
//                     ),
//                     child: Text(
//                       '${m.targetModel}.${m.targetField}',
//                       style: TextStyle(
//                         color: theme.textColor,
//                         fontSize: 10,
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             if (samples.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 6,
//                 runSpacing: 6,
//                 children: samples.map((s) {
//                   return Container(
//                     constraints: const BoxConstraints(maxWidth: 220),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: theme.adPopBackground,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Text(
//                       s,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: theme.textColor.withAlpha(210),
//                         fontSize: 10,
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TargetModelsPanel extends StatelessWidget {
//   final ThemeColors theme;
//   final ImportOptions options;
//   final List<String> modelNames;
//   final String? selectedTargetModel;
//   final List<String> previewColumns;
//   final List<List<String>> previewData;
//   final ImportFormState formState;
//   final ImportFormNotifier formNotifier;
//   final String targetSearch;
//   final bool showOnlyUnmappedTargets;
//   final String? selectedColumn;
//   final ValueChanged<String> onSearchChanged;
//   final ValueChanged<bool> onToggleOnlyUnmapped;
//   final void Function(String model, String field) onAssignFromSelected;

//   const _TargetModelsPanel({
//     required this.theme,
//     required this.options,
//     required this.modelNames,
//     required this.selectedTargetModel,
//     required this.previewColumns,
//     required this.previewData,
//     required this.formState,
//     required this.formNotifier,
//     required this.targetSearch,
//     required this.showOnlyUnmappedTargets,
//     required this.selectedColumn,
//     required this.onSearchChanged,
//     required this.onToggleOnlyUnmapped,
//     required this.onAssignFromSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final searchLower = targetSearch.trim().toLowerCase();

//     final visibleModels = modelNames.where((modelName) {
//       final rawSpec = options.targetModels[modelName];
//       final fieldSpecs = _extractFieldSpecsFromRawSpec(rawSpec);

//       final filteredSpecs = fieldSpecs.where((spec) {
//         final matchesSearch = searchLower.isEmpty ||
//             spec.name.toLowerCase().contains(searchLower) ||
//             spec.type.toLowerCase().contains(searchLower) ||
//             modelName.toLowerCase().contains(searchLower) ||
//             (spec.relatedModel?.toLowerCase().contains(searchLower) ?? false);

//         if (!matchesSearch) return false;

//         if (!showOnlyUnmappedTargets) return true;

//         final current = formNotifier.getMappingForTarget(modelName, spec.name);
//         return current == null;
//       }).toList(growable: false);

//       return filteredSpecs.isNotEmpty;
//     }).toList(growable: false);

//     return Container(
//       decoration: BoxDecoration(
//         color: theme.adPopBackground,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: theme.dashboardBoarder.withAlpha(100)),
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         children: [
//           _PanelHeader(
//             theme: theme,
//             title: 'Pola docelowe'.tr,
//             subtitle:
//                 'Model główny jest podświetlony. Pola FK pokazują powiązany model.'
//                     .tr,
//           ),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               Expanded(
//                 child: EmmaUiAnchorTarget(
//                   // @emma-backend: ImporterEmmaAnchors.importMapperTargetSearch
//                   anchorKey: 'importer.mapper.target_search',
//                   child: TextField(
//                     onChanged: onSearchChanged,
//                     decoration: InputDecoration(
//                       isDense: true,
//                       prefixIcon: const Icon(Icons.search_rounded),
//                       filled: true,
//                       fillColor: theme.dashboardContainer,
//                       labelText: 'Szukaj modelu, pola lub relacji'.tr,
//                       labelStyle: TextStyle(
//                         color: theme.textColor.withAlpha(160),
//                         fontSize: 12,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               EmmaUiAnchorTarget(
//                 // @emma-backend: ImporterEmmaAnchors.importMapperOnlyUnmappedToggle
//                 anchorKey: 'importer.mapper.only_unmapped_toggle',
//                 child: FilterChip(
//                   selected: showOnlyUnmappedTargets,
//                   label: Text('Tylko wolne'.tr),
//                   onSelected: onToggleOnlyUnmapped,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Expanded(
//             child: visibleModels.isEmpty
//                 ? Center(
//                     child: Text(
//                       'Brak pól pasujących do filtrów.'.tr,
//                       style: TextStyle(
//                         color: theme.textColor.withAlpha(170),
//                       ),
//                     ),
//                   )
//                 : ListView.separated(
//                     itemCount: visibleModels.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 10),
//                     itemBuilder: (ctx, index) {
//                       final modelName = visibleModels[index];
//                       final rawSpec = options.targetModels[modelName];
//                       final fieldSpecs = _extractFieldSpecsFromRawSpec(rawSpec);

//                       final filteredSpecs = fieldSpecs.where((spec) {
//                         final matchesSearch = searchLower.isEmpty ||
//                             spec.name.toLowerCase().contains(searchLower) ||
//                             spec.type.toLowerCase().contains(searchLower) ||
//                             modelName.toLowerCase().contains(searchLower) ||
//                             (spec.relatedModel
//                                     ?.toLowerCase()
//                                     .contains(searchLower) ??
//                                 false);

//                         if (!matchesSearch) return false;

//                         if (!showOnlyUnmappedTargets) return true;

//                         final current = formNotifier.getMappingForTarget(
//                           modelName,
//                           spec.name,
//                         );

//                         return current == null;
//                       }).toList(growable: false);

//                       return _TargetModelCard(
//                         theme: theme,
//                         modelName: modelName,
//                         fieldSpecs: filteredSpecs,
//                         previewColumns: previewColumns,
//                         previewData: previewData,
//                         formState: formState,
//                         formNotifier: formNotifier,
//                         selectedColumn: selectedColumn,
//                         isSelectedTargetModel: selectedTargetModel == modelName,
//                         onAssignFromSelected: (field) {
//                           onAssignFromSelected(modelName, field);
//                         },
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TargetModelCard extends StatelessWidget {
//   final ThemeColors theme;
//   final String modelName;
//   final List<_TargetFieldSpec> fieldSpecs;
//   final List<String> previewColumns;
//   final List<List<String>> previewData;
//   final ImportFormState formState;
//   final ImportFormNotifier formNotifier;
//   final String? selectedColumn;
//   final bool isSelectedTargetModel;
//   final ValueChanged<String> onAssignFromSelected;

//   const _TargetModelCard({
//     required this.theme,
//     required this.modelName,
//     required this.fieldSpecs,
//     required this.previewColumns,
//     required this.previewData,
//     required this.formState,
//     required this.formNotifier,
//     required this.selectedColumn,
//     required this.isSelectedTargetModel,
//     required this.onAssignFromSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final mappedCount = fieldSpecs.where((spec) {
//       return formNotifier.getMappingForTarget(modelName, spec.name) != null;
//     }).length;

//     final relationCount = fieldSpecs.where((spec) => spec.isRelation).length;

//     return Container(
//       decoration: BoxDecoration(
//         color: theme.dashboardContainer,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: isSelectedTargetModel
//               ? theme.themeColor.withAlpha(180)
//               : theme.dashboardBoarder.withAlpha(110),
//           width: isSelectedTargetModel ? 1.5 : 1,
//         ),
//       ),
//       child: ExpansionTile(
//         initiallyExpanded: selectedColumn != null || isSelectedTargetModel,
//         tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
//         childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//         title: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 modelName,
//                 style: TextStyle(
//                   color: theme.textColor,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//             if (isSelectedTargetModel)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: theme.themeColor.withAlpha(22),
//                   borderRadius: BorderRadius.circular(999),
//                   border: Border.all(
//                     color: theme.themeColor.withAlpha(120),
//                   ),
//                 ),
//                 child: Text(
//                   'GŁÓWNY'.tr,
//                   style: TextStyle(
//                     color: theme.themeColor,
//                     fontSize: 9,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         subtitle: Text(
//           'Pól: ${fieldSpecs.length} • FK: $relationCount • zmapowane: $mappedCount'
//               .tr,
//           style: TextStyle(
//             color: theme.textColor.withAlpha(170),
//             fontSize: 11,
//           ),
//         ),
//         children: fieldSpecs.map((spec) {
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: _TargetFieldTile(
//               theme: theme,
//               modelName: modelName,
//               fieldSpec: spec,
//               previewColumns: previewColumns,
//               previewData: previewData,
//               formState: formState,
//               formNotifier: formNotifier,
//               selectedColumn: selectedColumn,
//               onAssignFromSelected: () => onAssignFromSelected(spec.name),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _TargetFieldTile extends StatelessWidget {
//   final ThemeColors theme;
//   final String modelName;
//   final _TargetFieldSpec fieldSpec;
//   final List<String> previewColumns;
//   final List<List<String>> previewData;
//   final ImportFormState formState;
//   final ImportFormNotifier formNotifier;
//   final String? selectedColumn;
//   final VoidCallback onAssignFromSelected;

//   const _TargetFieldTile({
//     required this.theme,
//     required this.modelName,
//     required this.fieldSpec,
//     required this.previewColumns,
//     required this.previewData,
//     required this.formState,
//     required this.formNotifier,
//     required this.selectedColumn,
//     required this.onAssignFromSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final fieldName = fieldSpec.name;

//     final current = formNotifier.getMappingForTarget(modelName, fieldName);
//     final currentColumn = current?.columnName;
//     final isAssignedFromSelected =
//         selectedColumn != null && currentColumn == selectedColumn;

//     String dropdownValue = '';
//     if (currentColumn != null && previewColumns.contains(currentColumn)) {
//       dropdownValue = currentColumn;
//     }

//     final samples = <String>[];

//     if (dropdownValue.isNotEmpty) {
//       final colIndex = previewColumns.indexOf(dropdownValue);

//       if (colIndex != -1) {
//         for (final row in previewData.take(4)) {
//           final value = colIndex < row.length ? row[colIndex] : '';

//           if (value.trim().isNotEmpty) {
//             samples.add(value);
//           }
//         }
//       }
//     }

//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: isAssignedFromSelected
//             ? theme.themeColor.withAlpha(20)
//             : fieldSpec.isRelation
//                 ? theme.themeColor.withAlpha(8)
//                 : theme.adPopBackground,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isAssignedFromSelected
//               ? theme.themeColor.withAlpha(150)
//               : fieldSpec.isRelation
//                   ? theme.themeColor.withAlpha(90)
//                   : theme.dashboardBoarder.withAlpha(100),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 fieldSpec.isRelation
//                     ? Icons.account_tree_rounded
//                     : Icons.label_outline_rounded,
//                 size: 15,
//                 color: fieldSpec.isRelation
//                     ? theme.themeColor
//                     : theme.textColor.withAlpha(160),
//               ),
//               const SizedBox(width: 7),
//               Expanded(
//                 child: Text(
//                   fieldName,
//                   style: TextStyle(
//                     color: theme.textColor,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//               if (fieldSpec.required)
//                 _FieldMetaBadge(
//                   theme: theme,
//                   label: 'required'.tr,
//                   accent: Colors.redAccent,
//                 ),
//               if (fieldSpec.isRelation) ...[
//                 const SizedBox(width: 6),
//                 _FieldMetaBadge(
//                   theme: theme,
//                   label: fieldSpec.relatedModel == null
//                       ? 'FK'
//                       : 'FK → ${fieldSpec.relatedModel}',
//                   accent: theme.themeColor,
//                 ),
//               ],
//               if (selectedColumn != null) ...[
//                 const SizedBox(width: 8),
//                 OutlinedButton.icon(
//                   style: _outlinedActionStyle(theme),
//                   onPressed: onAssignFromSelected,
//                   icon: const Icon(Icons.arrow_downward_rounded, size: 16),
//                   label: Text(
//                     selectedColumn == currentColumn
//                         ? 'Przypięte'.tr
//                         : 'Przypnij'.tr,
//                     style: TextStyle(color: theme.textColor),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             fieldSpec.type.isEmpty
//                 ? 'Typ pola nie został określony'.tr
//                 : fieldSpec.type,
//             style: TextStyle(
//               color: theme.textColor.withAlpha(145),
//               fontSize: 10,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           DropdownButtonFormField<String>(
//             value: dropdownValue,
//             dropdownColor: theme.dashboardContainer,
//             decoration: InputDecoration(
//               isDense: true,
//               filled: true,
//               fillColor: theme.dashboardContainer,
//               labelText: 'Kolumna źródłowa'.tr,
//               labelStyle: TextStyle(
//                 color: theme.textColor.withAlpha(180),
//                 fontSize: 11,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                   color: theme.dashboardBoarder,
//                 ),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(
//                   color: theme.themeColor,
//                   width: 1.5,
//                 ),
//               ),
//             ),
//             items: [
//               DropdownMenuItem(
//                 value: '',
//                 child: Text(
//                   '— brak —'.tr,
//                   style: TextStyle(
//                     color: theme.textColor.withAlpha(204),
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//               ...previewColumns.map(
//                 (col) => DropdownMenuItem(
//                   value: col,
//                   child: Text(
//                     col,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: theme.textColor,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//             onChanged: (val) {
//               if (val == null || val.isEmpty) {
//                 formNotifier.setMappingForTarget(
//                   columnName: null,
//                   targetModel: modelName,
//                   targetField: fieldName,
//                 );
//               } else {
//                 formNotifier.setMappingForTarget(
//                   columnName: val,
//                   targetModel: modelName,
//                   targetField: fieldName,
//                 );
//               }
//             },
//           ),
//           if (currentColumn != null) ...[
//             const SizedBox(height: 8),
//             Text(
//               'Aktualnie z: $currentColumn'.tr,
//               style: TextStyle(
//                 color: theme.textColor.withAlpha(175),
//                 fontSize: 10,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//           if (samples.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 6,
//               runSpacing: 6,
//               children: samples.map((s) {
//                 return Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: theme.dashboardBoarder.withAlpha(120),
//                     ),
//                   ),
//                   child: Text(
//                     s,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: theme.textColor.withAlpha(204),
//                       fontSize: 10,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _FieldMetaBadge extends StatelessWidget {
//   final ThemeColors theme;
//   final String label;
//   final Color accent;

//   const _FieldMetaBadge({
//     required this.theme,
//     required this.label,
//     required this.accent,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 7,
//         vertical: 3,
//       ),
//       decoration: BoxDecoration(
//         color: accent.withAlpha(18),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(
//           color: accent.withAlpha(100),
//         ),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: accent,
//           fontSize: 9,
//           fontWeight: FontWeight.w800,
//         ),
//       ),
//     );
//   }
// }

// class _PanelHeader extends StatelessWidget {
//   final ThemeColors theme;
//   final String title;
//   final String subtitle;

//   const _PanelHeader({
//     required this.theme,
//     required this.title,
//     required this.subtitle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             color: theme.textColor,
//             fontSize: 14,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const SizedBox(height: 3),
//         Text(
//           subtitle,
//           style: TextStyle(
//             color: theme.textColor.withAlpha(170),
//             fontSize: 11,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class MapperCanvasView extends StatefulWidget {
//   final String rootAnchorKey;
//   final ThemeColors theme;
//   final ImportOptions options;
//   final ImportFormState formState;
//   final ImportFormNotifier formNotifier;
//   final String? selectedColumn;
//   final String? selectedTargetModel;
//   final ValueChanged<String> onSelectColumn;

//   final double minScale;
//   final double maxScale;
//   final bool showFullscreenButton;
//   final VoidCallback? onOpenFullscreen;

//   const MapperCanvasView({
//     super.key,
//     this.rootAnchorKey = 'importer.mapper.canvas',
//     required this.theme,
//     required this.options,
//     required this.formState,
//     required this.formNotifier,
//     required this.selectedColumn,
//     required this.selectedTargetModel,
//     required this.onSelectColumn,
//     this.minScale = 0.16,
//     this.maxScale = 2.4,
//     this.showFullscreenButton = true,
//     this.onOpenFullscreen,
//   });

//   @override
//   State<MapperCanvasView> createState() => _MapperCanvasViewState();
// }

// class _MapperCanvasViewState extends State<MapperCanvasView> {
//   late final TransformationController _transformationController;

//   @override
//   void initState() {
//     super.initState();
//     _transformationController = TransformationController();
//   }

//   @override
//   void dispose() {
//     _transformationController.dispose();
//     super.dispose();
//   }

//   double get _currentScale =>
//       _transformationController.value.getMaxScaleOnAxis();

//   void _zoomBy(double factor) {
//     final current = _currentScale;
//     final target = (current * factor).clamp(widget.minScale, widget.maxScale);
//     final safeCurrent = current == 0 ? 1.0 : current;
//     final ratio = target / safeCurrent;

//     final nextMatrix = Matrix4.copy(_transformationController.value)
//       ..scale(ratio);

//     _transformationController.value = nextMatrix;
//     setState(() {});
//   }

//   void _resetView() {
//     _transformationController.value = Matrix4.identity();
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = widget.theme;
//     final formState = widget.formState;
//     final formNotifier = widget.formNotifier;

//     final sourceColumns = formState.previewColumns;

//     final allModelNames = widget.options.targetModels.keys.toList()..sort();

//     final selectedTargetModel = widget.selectedTargetModel?.trim();

//     final modelNames = [
//       if (selectedTargetModel != null &&
//           selectedTargetModel.isNotEmpty &&
//           allModelNames.contains(selectedTargetModel))
//         selectedTargetModel,
//       ...allModelNames.where((m) => m != selectedTargetModel),
//     ];

//     const double sourceX = 48;
//     const double targetX = 760;
//     const double sourceWidth = 270;
//     const double targetWidth = 540;
//     const double sourceHeight = 86;
//     const double sourceGap = 16;
//     const double canvasWidth = 1420;

//     final Map<String, Rect> sourceRects = {};
//     final Map<String, Rect> targetRects = {};
//     final List<Widget> sourceWidgets = [];
//     final List<Widget> targetWidgets = [];

//     double sourceY = 90;

//     for (final column in sourceColumns) {
//       final rect = Rect.fromLTWH(sourceX, sourceY, sourceWidth, sourceHeight);
//       sourceRects[column] = rect;

//       final samples = _samplesForColumn(
//         previewColumns: formState.previewColumns,
//         previewData: formState.previewData,
//         columnName: column,
//       );

//       final mappings = formState.fieldMappings
//           .where((m) => m.columnName == column)
//           .toList(growable: false);

//       sourceWidgets.add(
//         Positioned(
//           left: rect.left,
//           top: rect.top,
//           width: rect.width,
//           height: rect.height,
//           child: LongPressDraggable<String>(
//             data: column,
//             feedback: Material(
//               color: Colors.transparent,
//               child: SizedBox(
//                 width: rect.width,
//                 child: _CanvasSourceNode(
//                   theme: theme,
//                   title: column,
//                   samples: samples,
//                   mappings: mappings,
//                   isSelected: true,
//                   compact: true,
//                   onTap: () {},
//                 ),
//               ),
//             ),
//             childWhenDragging: Opacity(
//               opacity: 0.35,
//               child: _CanvasSourceNode(
//                 theme: theme,
//                 title: column,
//                 samples: samples,
//                 mappings: mappings,
//                 isSelected: widget.selectedColumn == column,
//                 onTap: () => widget.onSelectColumn(column),
//               ),
//             ),
//             child: _CanvasSourceNode(
//               theme: theme,
//               title: column,
//               samples: samples,
//               mappings: mappings,
//               isSelected: widget.selectedColumn == column,
//               onTap: () => widget.onSelectColumn(column),
//             ),
//           ),
//         ),
//       );

//       sourceY += sourceHeight + sourceGap;
//     }

//     double targetY = 90;

//     for (final modelName in modelNames) {
//       final rawSpec = widget.options.targetModels[modelName];
//       final fields = _extractFieldSpecsFromRawSpec(rawSpec);

//       const double modelHeaderHeight = 48;
//       const double fieldHeight = 64;
//       const double fieldGap = 10;
//       const double innerPadding = 12;

//       final double modelHeight = modelHeaderHeight +
//           innerPadding +
//           (fields.length * (fieldHeight + fieldGap)) +
//           8;

//       final isMainModel = selectedTargetModel == modelName;

//       targetWidgets.add(
//         Positioned(
//           left: targetX,
//           top: targetY,
//           width: targetWidth,
//           height: modelHeight,
//           child: Container(
//             decoration: BoxDecoration(
//               color: theme.dashboardContainer,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: isMainModel
//                     ? theme.themeColor.withAlpha(180)
//                     : theme.dashboardBoarder.withAlpha(110),
//                 width: isMainModel ? 1.5 : 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(18),
//                   blurRadius: 14,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 Positioned(
//                   left: 14,
//                   right: 14,
//                   top: 12,
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           modelName,
//                           style: TextStyle(
//                             color: theme.textColor,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                       if (isMainModel)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: theme.themeColor.withAlpha(22),
//                             borderRadius: BorderRadius.circular(999),
//                             border: Border.all(
//                               color: theme.themeColor.withAlpha(120),
//                             ),
//                           ),
//                           child: Text(
//                             'GŁÓWNY'.tr,
//                             style: TextStyle(
//                               color: theme.themeColor,
//                               fontSize: 9,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 ...List.generate(fields.length, (index) {
//                   final spec = fields[index];
//                   final top = modelHeaderHeight +
//                       innerPadding +
//                       index * (fieldHeight + fieldGap);

//                   final fieldRect = Rect.fromLTWH(
//                     targetX + 14,
//                     targetY + top,
//                     targetWidth - 28,
//                     fieldHeight,
//                   );

//                   targetRects['$modelName.${spec.name}'] = fieldRect;

//                   final current =
//                       formNotifier.getMappingForTarget(modelName, spec.name);

//                   return Positioned(
//                     left: 14,
//                     top: top,
//                     width: targetWidth - 28,
//                     height: fieldHeight,
//                     child: DragTarget<String>(
//                       onWillAcceptWithDetails: (_) => true,
//                       onAcceptWithDetails: (details) {
//                         formNotifier.setMappingForTarget(
//                           columnName: details.data,
//                           targetModel: modelName,
//                           targetField: spec.name,
//                         );
//                       },
//                       builder: (context, candidateData, rejectedData) {
//                         final isHovering = candidateData.isNotEmpty;

//                         return _CanvasTargetFieldNode(
//                           theme: theme,
//                           modelName: modelName,
//                           fieldSpec: spec,
//                           currentColumn: current?.columnName,
//                           isHighlightedBySelectedColumn:
//                               widget.selectedColumn != null &&
//                                   current?.columnName == widget.selectedColumn,
//                           isDropHover: isHovering,
//                           onTap: () {
//                             if (widget.selectedColumn == null) return;

//                             formNotifier.setMappingForTarget(
//                               columnName: widget.selectedColumn,
//                               targetModel: modelName,
//                               targetField: spec.name,
//                             );
//                           },
//                           onClear: current == null
//                               ? null
//                               : () {
//                                   formNotifier.setMappingForTarget(
//                                     columnName: null,
//                                     targetModel: modelName,
//                                     targetField: spec.name,
//                                   );
//                                 },
//                         );
//                       },
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//         ),
//       );

//       targetY += modelHeight + 26;
//     }

//     final canvasHeight = math.max(sourceY + 120, targetY + 80);

//     return EmmaUiAnchorTarget(
//       anchorKey: widget.rootAnchorKey,
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
//             child: Row(
//               children: [
//                 Icon(Icons.hub_rounded, color: theme.themeColor, size: 18),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Canvas mapper — przeciągnij kolumnę na pole albo kliknij kolumnę i potem pole. Pola FK są oznaczone osobnym badge.'
//                         .tr,
//                     style: TextStyle(
//                       color: theme.textColor.withAlpha(190),
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _CanvasControlButton(
//                   anchorKey: '${widget.rootAnchorKey}.zoom_out',
//                   theme: theme,
//                   tooltip: 'Oddal'.tr,
//                   icon: Icons.remove_rounded,
//                   onTap: () => _zoomBy(0.8),
//                 ),
//                 const SizedBox(width: 6),
//                 _CanvasControlButton(
//                   anchorKey: '${widget.rootAnchorKey}.zoom_in',
//                   theme: theme,
//                   tooltip: 'Przybliż'.tr,
//                   icon: Icons.add_rounded,
//                   onTap: () => _zoomBy(1.25),
//                 ),
//                 const SizedBox(width: 6),
//                 _CanvasControlButton(
//                   anchorKey: '${widget.rootAnchorKey}.reset_view',
//                   theme: theme,
//                   tooltip: 'Reset widoku'.tr,
//                   icon: Icons.center_focus_strong_rounded,
//                   onTap: _resetView,
//                 ),
//                 if (widget.showFullscreenButton &&
//                     widget.onOpenFullscreen != null) ...[
//                   const SizedBox(width: 6),
//                   _CanvasControlButton(
//                     anchorKey: '${widget.rootAnchorKey}.fullscreen',
//                     theme: theme,
//                     tooltip: 'Fullscreen'.tr,
//                     icon: Icons.open_in_full_rounded,
//                     onTap: widget.onOpenFullscreen!,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           Expanded(
//             child: Stack(
//               children: [
//                 InteractiveViewer(
//                   transformationController: _transformationController,
//                   boundaryMargin: const EdgeInsets.all(600),
//                   minScale: widget.minScale,
//                   maxScale: widget.maxScale,
//                   constrained: false,
//                   child: SizedBox(
//                     width: canvasWidth,
//                     height: canvasHeight,
//                     child: Stack(
//                       children: [
//                         Positioned.fill(
//                           child: CustomPaint(
//                             painter: _MapperConnectionsPainter(
//                               theme: theme,
//                               mappings: formState.fieldMappings,
//                               sourceRects: sourceRects,
//                               targetRects: targetRects,
//                               selectedColumn: widget.selectedColumn,
//                             ),
//                           ),
//                         ),
//                         ...sourceWidgets,
//                         ...targetWidgets,
//                       ],
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   right: 12,
//                   bottom: 12,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 7,
//                     ),
//                     decoration: BoxDecoration(
//                       color: theme.dashboardContainer.withAlpha(235),
//                       borderRadius: BorderRadius.circular(999),
//                       border: Border.all(
//                         color: theme.dashboardBoarder.withAlpha(120),
//                       ),
//                     ),
//                     child: Text(
//                       'Zoom ${(_currentScale * 100).toStringAsFixed(0)}%',
//                       style: TextStyle(
//                         color: theme.textColor,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CanvasControlButton extends StatelessWidget {
//   final String anchorKey;
//   final ThemeColors theme;
//   final String tooltip;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _CanvasControlButton({
//     required this.anchorKey,
//     required this.theme,
//     required this.tooltip,
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return EmmaUiAnchorTarget(
//       anchorKey: anchorKey,
//       child: Tooltip(
//         message: tooltip,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(10),
//           onTap: onTap,
//           child: Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: theme.dashboardContainer,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(
//                 color: theme.dashboardBoarder.withAlpha(120),
//               ),
//             ),
//             child: Icon(
//               icon,
//               size: 18,
//               color: theme.textColor,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CanvasSourceNode extends StatelessWidget {
//   final ThemeColors theme;
//   final String title;
//   final List<String> samples;
//   final List<FieldMappingRule> mappings;
//   final bool isSelected;
//   final bool compact;
//   final VoidCallback onTap;

//   const _CanvasSourceNode({
//     required this.theme,
//     required this.title,
//     required this.samples,
//     required this.mappings,
//     required this.isSelected,
//     required this.onTap,
//     this.compact = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 160),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? theme.themeColor.withAlpha(24)
//               : theme.dashboardContainer,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected
//                 ? theme.themeColor
//                 : theme.dashboardBoarder.withAlpha(110),
//             width: isSelected ? 1.4 : 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.table_rows_rounded,
//                   size: 16,
//                   color: theme.themeColor,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       color: theme.textColor,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             if (!compact) ...[
//               const SizedBox(height: 8),
//               if (mappings.isNotEmpty)
//                 Wrap(
//                   spacing: 6,
//                   runSpacing: 6,
//                   children: mappings.map((m) {
//                     return Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: theme.adPopBackground,
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: Text(
//                         '${m.targetModel}.${m.targetField}',
//                         style: TextStyle(
//                           color: theme.textColor.withAlpha(220),
//                           fontSize: 10,
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 )
//               else
//                 Text(
//                   'Niepołączona'.tr,
//                   style: TextStyle(
//                     color: theme.textColor.withAlpha(150),
//                     fontSize: 10,
//                   ),
//                 ),
//               if (samples.isNotEmpty) ...[
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 6,
//                   runSpacing: 6,
//                   children: samples.map((s) {
//                     return Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: theme.adPopBackground,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         s,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: theme.textColor.withAlpha(210),
//                           fontSize: 10,
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _CanvasTargetFieldNode extends StatelessWidget {
//   final ThemeColors theme;
//   final String modelName;
//   final _TargetFieldSpec fieldSpec;
//   final String? currentColumn;
//   final bool isHighlightedBySelectedColumn;
//   final bool isDropHover;
//   final VoidCallback onTap;
//   final VoidCallback? onClear;

//   const _CanvasTargetFieldNode({
//     required this.theme,
//     required this.modelName,
//     required this.fieldSpec,
//     required this.currentColumn,
//     required this.isHighlightedBySelectedColumn,
//     required this.isDropHover,
//     required this.onTap,
//     required this.onClear,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 120),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         decoration: BoxDecoration(
//           color: isDropHover
//               ? theme.themeColor.withAlpha(24)
//               : isHighlightedBySelectedColumn
//                   ? theme.themeColor.withAlpha(16)
//                   : fieldSpec.isRelation
//                       ? theme.themeColor.withAlpha(8)
//                       : theme.adPopBackground,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isDropHover
//                 ? theme.themeColor
//                 : isHighlightedBySelectedColumn
//                     ? theme.themeColor.withAlpha(140)
//                     : fieldSpec.isRelation
//                         ? theme.themeColor.withAlpha(90)
//                         : theme.dashboardBoarder.withAlpha(100),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               fieldSpec.isRelation
//                   ? Icons.account_tree_rounded
//                   : Icons.label_outline_rounded,
//               size: 15,
//               color: fieldSpec.isRelation
//                   ? theme.themeColor
//                   : theme.textColor.withAlpha(150),
//             ),
//             const SizedBox(width: 7),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     fieldSpec.name,
//                     style: TextStyle(
//                       color: theme.textColor,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   if (fieldSpec.isRelation)
//                     Text(
//                       fieldSpec.relatedModel == null
//                           ? 'ForeignKey'
//                           : 'FK → ${fieldSpec.relatedModel}',
//                       style: TextStyle(
//                         color: theme.themeColor,
//                         fontSize: 9,
//                         fontWeight: FontWeight.w800,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                 ],
//               ),
//             ),
//             if (currentColumn != null)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: theme.dashboardContainer,
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//                 child: Text(
//                   currentColumn!,
//                   style: TextStyle(
//                     color: theme.textColor.withAlpha(220),
//                     fontSize: 10,
//                   ),
//                 ),
//               )
//             else
//               Text(
//                 'drop here'.tr,
//                 style: TextStyle(
//                   color: theme.textColor.withAlpha(130),
//                   fontSize: 10,
//                 ),
//               ),
//             if (onClear != null) ...[
//               const SizedBox(width: 8),
//               InkWell(
//                 onTap: onClear,
//                 child: Icon(
//                   Icons.close_rounded,
//                   size: 16,
//                   color: theme.textColor.withAlpha(150),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _MapperConnectionsPainter extends CustomPainter {
//   final ThemeColors theme;
//   final List<FieldMappingRule> mappings;
//   final Map<String, Rect> sourceRects;
//   final Map<String, Rect> targetRects;
//   final String? selectedColumn;

//   _MapperConnectionsPainter({
//     required this.theme,
//     required this.mappings,
//     required this.sourceRects,
//     required this.targetRects,
//     required this.selectedColumn,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final gridPaint = Paint()
//       ..color = theme.textColor.withAlpha(10)
//       ..strokeWidth = 1;

//     for (double x = 0; x < size.width; x += 48) {
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }

//     for (double y = 0; y < size.height; y += 48) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }

//     for (final mapping in mappings) {
//       final sourceRect = sourceRects[mapping.columnName];
//       final targetRect =
//           targetRects['${mapping.targetModel}.${mapping.targetField}'];

//       if (sourceRect == null || targetRect == null) continue;

//       final start = Offset(
//         sourceRect.right,
//         sourceRect.top + sourceRect.height / 2,
//       );
//       final end = Offset(
//         targetRect.left,
//         targetRect.top + targetRect.height / 2,
//       );

//       final isHighlighted =
//           selectedColumn != null && selectedColumn == mapping.columnName;

//       final paint = Paint()
//         ..color =
//             isHighlighted ? theme.themeColor : theme.textColor.withAlpha(70)
//         ..strokeWidth = isHighlighted ? 2.6 : 1.6
//         ..style = PaintingStyle.stroke;

//       final path = Path()
//         ..moveTo(start.dx, start.dy)
//         ..cubicTo(
//           start.dx + 120,
//           start.dy,
//           end.dx - 120,
//           end.dy,
//           end.dx,
//           end.dy,
//         );

//       canvas.drawPath(path, paint);

//       canvas.drawCircle(
//         start,
//         3,
//         Paint()..color = paint.color,
//       );

//       canvas.drawCircle(
//         end,
//         3,
//         Paint()..color = paint.color,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _MapperConnectionsPainter oldDelegate) {
//     return true;
//   }
// }

// class _EmmaMapperPlanSection extends StatelessWidget {
//   final ThemeColors theme;
//   final String title;
//   final String emptyText;
//   final List<dynamic> items;
//   final Widget Function(dynamic item) itemBuilder;

//   const _EmmaMapperPlanSection({
//     required this.theme,
//     required this.title,
//     required this.emptyText,
//     required this.items,
//     required this.itemBuilder,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: theme.adPopBackground,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.dashboardBoarder.withAlpha(110),
//         ),
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: theme.textColor,
//               fontSize: 13,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 10),
//           if (items.isEmpty)
//             Text(
//               emptyText,
//               style: TextStyle(
//                 color: theme.textColor.withAlpha(160),
//                 fontSize: 12,
//               ),
//             )
//           else
//             ...items.map(
//               (item) => Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: itemBuilder(item),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _EmmaMapperPlanCard extends StatelessWidget {
//   final ThemeColors theme;
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final String description;
//   final Color? accentColor;

//   const _EmmaMapperPlanCard({
//     required this.theme,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.description,
//     this.accentColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final accent = accentColor ?? theme.themeColor;

//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: theme.dashboardContainer,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: accent.withAlpha(70),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: accent, size: 18),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: theme.textColor,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     color: theme.textColor.withAlpha(185),
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 if (description.trim().isNotEmpty) ...[
//                   const SizedBox(height: 5),
//                   Text(
//                     description,
//                     style: TextStyle(
//                       color: theme.textColor.withAlpha(160),
//                       fontSize: 11,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TargetFieldSpec {
//   final String name;
//   final String type;
//   final String? relatedModel;
//   final bool required;

//   const _TargetFieldSpec({
//     required this.name,
//     required this.type,
//     required this.relatedModel,
//     required this.required,
//   });

//   bool get isRelation {
//     final lowerType = type.toLowerCase();

//     return lowerType == 'foreignkey' ||
//         lowerType == 'onetoonefield' ||
//         lowerType == 'manytomanyfield' ||
//         relatedModel != null;
//   }
// }

// List<_TargetFieldSpec> _extractFieldSpecsFromRawSpec(dynamic rawSpec) {
//   if (rawSpec is! List) return [];

//   final specs = <_TargetFieldSpec>[];

//   for (final raw in rawSpec) {
//     if (raw is! Map) continue;

//     final map = Map<String, dynamic>.from(raw);

//     final name = (map['field_name'] ?? '').toString().trim();
//     if (name.isEmpty) continue;

//     final type = (map['field_type'] ?? '').toString().trim();

//     final relatedModelRaw =
//         map['field_related_model'] ?? map['related_model'];

//     final relatedModelText = relatedModelRaw?.toString().trim();

//     specs.add(
//       _TargetFieldSpec(
//         name: name,
//         type: type,
//         relatedModel: relatedModelText == null || relatedModelText.isEmpty
//             ? null
//             : relatedModelText,
//         required: map['field_required'] == true || map['required'] == true,
//       ),
//     );
//   }

//   specs.sort((a, b) {
//     if (a.isRelation != b.isRelation) {
//       return a.isRelation ? -1 : 1;
//     }

//     if (a.required != b.required) {
//       return a.required ? -1 : 1;
//     }

//     return a.name.compareTo(b.name);
//   });

//   return specs;
// }

// List<String> _extractFieldNamesFromRawSpec(dynamic rawSpec) {
//   return _extractFieldSpecsFromRawSpec(rawSpec)
//       .map((spec) => spec.name)
//       .toSet()
//       .toList()
//     ..sort();
// }

// List<String> _samplesForColumn({
//   required List<String> previewColumns,
//   required List<List<String>> previewData,
//   required String columnName,
//   int maxItems = 3,
// }) {
//   final colIndex = previewColumns.indexOf(columnName);
//   if (colIndex == -1) return [];

//   final out = <String>[];

//   for (final row in previewData.take(maxItems)) {
//     final value = colIndex < row.length ? row[colIndex] : '';

//     if (value.trim().isNotEmpty) {
//       out.add(value);
//     }
//   }

//   return out;
// }

// bool _hasValidEmmaEntityPlan(dynamic value) {
//   final map = _asStringMap(value);

//   if (map.isEmpty) return false;

//   final entities = map['entities'];
//   final relations = map['relations'];

//   return (entities is List && entities.isNotEmpty) ||
//       (relations is List && relations.isNotEmpty);
// }

// Map<String, dynamic> _asStringMap(dynamic value) {
//   if (value is Map<String, dynamic>) return value;
//   if (value is Map) return Map<String, dynamic>.from(value);
//   return <String, dynamic>{};
// }

// int _emmaInt(dynamic value, [int fallback = 0]) {
//   if (value is int) return value;
//   if (value is num) return value.toInt();
//   return int.tryParse(value?.toString() ?? '') ?? fallback;
// }

// String _formatConfidence(dynamic value) {
//   if (value == null) return '';

//   if (value is num) {
//     return value.toStringAsFixed(2);
//   }

//   final parsed = double.tryParse(value.toString());
//   if (parsed == null) return value.toString();

//   return parsed.toStringAsFixed(2);
// }

// ButtonStyle _outlinedActionStyle(ThemeColors theme) {
//   return OutlinedButton.styleFrom(
//     foregroundColor: theme.textColor,
//     backgroundColor: theme.dashboardContainer,
//     side: BorderSide(
//       color: theme.dashboardBoarder.withAlpha(130),
//     ),
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(12),
//     ),
//   );
// }

// ButtonStyle _filledActionStyle(ThemeColors theme) {
//   return ElevatedButton.styleFrom(
//     foregroundColor: Colors.white,
//     backgroundColor: theme.themeColor,
//     disabledForegroundColor: Colors.white.withAlpha(170),
//     disabledBackgroundColor: theme.themeColor.withAlpha(120),
//     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(12),
//     ),
//     elevation: 0,
//   );
// }