library importer_field_mapper;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:importer/tabs/batch_import_overlay.dart';
import 'package:importer/tabs/mapping/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/theme/apptheme.dart';

import '../import_state.dart';

// ignore: unused_import
import 'package:importer/emma/anchors/anchors_importer.dart';

part 'field_mapper_parts/field_mapper_state.dart';
part 'field_mapper_parts/mapper_header.dart';
part 'field_mapper_parts/mapper_toolbar.dart';
part 'field_mapper_parts/source_columns_panel.dart';
part 'field_mapper_parts/target_models_panel.dart';
part 'field_mapper_parts/shared_widgets.dart';
part 'field_mapper_parts/mapper_canvas_view.dart';
part 'field_mapper_parts/emma_plan_widgets.dart';
part 'field_mapper_parts/mapper_helpers.dart';
part 'field_mapper_parts/schema_explorer.dart';

enum MapperViewMode {
  list,
  canvas,
}

class ImportTabFieldMapper extends ConsumerStatefulWidget {
  final AsyncValue<ImportOptions> optionsAsync;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final bool isTablet;


  const ImportTabFieldMapper({
    super.key,
    required this.optionsAsync,
    required this.formState,
    required this.formNotifier,
    this.isTablet = false,
  });

  @override
  ConsumerState<ImportTabFieldMapper> createState() =>
      _ImportTabFieldMapperState();
}
