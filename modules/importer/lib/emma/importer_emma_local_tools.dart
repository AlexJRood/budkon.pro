import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../import_state.dart';

class ImporterEmmaToolNames {
  static const String getDatasetProfile = 'importer_get_dataset_profile';
  static const String applyTransformRules = 'importer_apply_transform_rules';

  static const Set<String> all = {
    getDatasetProfile,
    applyTransformRules,
  };
}

class ImporterEmmaLocalTools {
  const ImporterEmmaLocalTools._();

  static bool canHandle(String toolName) {
    return ImporterEmmaToolNames.all.contains(toolName);
  }

  static Future<Map<String, dynamic>> handle({
    required WidgetRef ref,
    required String toolName,
    Map<String, dynamic>? arguments,
  }) async {
    final args = arguments ?? <String, dynamic>{};

    switch (toolName) {
      case ImporterEmmaToolNames.getDatasetProfile:
        return _getDatasetProfile(ref: ref, args: args);

      case ImporterEmmaToolNames.applyTransformRules:
        return _applyTransformRules(ref: ref, args: args);

      default:
        return {
          'ok': false,
          'error': 'Unsupported importer local tool: $toolName',
        };
    }
  }

  static Map<String, dynamic> _getDatasetProfile({
    required WidgetRef ref,
    required Map<String, dynamic> args,
  }) {
    final notifier = ref.read(importFormProvider.notifier);
    final state = ref.read(importFormProvider);

    final maxRows = _intArg(args['max_rows'] ?? args['maxRows'], fallback: 30);
    final maxSamplesPerColumn = _intArg(
      args['max_samples_per_column'] ?? args['maxSamplesPerColumn'],
      fallback: 12,
    );

    final selectedRowsOnly = _boolArg(
      args['selected_rows_only'] ?? args['selectedRowsOnly'],
      fallback: false,
    );

    final targetModelFromArgs = _stringArg(
      args['target_model'] ?? args['targetModel'],
    );

    if (targetModelFromArgs.isNotEmpty &&
        targetModelFromArgs != state.selectedTargetModel) {
      notifier.setTargetModel(targetModelFromArgs);
    }

    final profile = notifier.buildEmmaDatasetProfile(
      maxRows: maxRows,
      maxSamplesPerColumn: maxSamplesPerColumn,
      selectedRowsOnly: selectedRowsOnly,
    );

    final currentState = ref.read(importFormProvider);

    return {
      'ok': true,
      'tool_name': ImporterEmmaToolNames.getDatasetProfile,
      'has_file': currentState.file != null,
      'has_preview': currentState.previewColumns.isNotEmpty,
      'selected_target_model': currentState.selectedTargetModel,
      'dataset_profile': profile,
      'llm_result': {
        'ok': true,
        'selected_target_model': currentState.selectedTargetModel,
        'dataset_profile': profile,
        'instruction': 'Use dataset_profile with importer_suggest_data_split.',
      },
    };
  }

  static Future<Map<String, dynamic>> _applyTransformRules({
    required WidgetRef ref,
    required Map<String, dynamic> args,
  }) async {
    final notifier = ref.read(importFormProvider.notifier);

    final rawRules = args['rules'];
    final rules = rawRules is List ? rawRules : <dynamic>[];

    final clearExisting = _boolArg(
      args['clear_existing'] ?? args['clearExisting'],
      fallback: false,
    );

    final replaceSameOutputColumn = _boolArg(
      args['replace_same_output_column'] ?? args['replaceSameOutputColumn'],
      fallback: true,
    );

    final result = await notifier.applyEmmaTransformRules(
      rules,
      clearExisting: clearExisting,
      replaceSameOutputColumn: replaceSameOutputColumn,
    );

    return {
      ...result,
      'tool_name': ImporterEmmaToolNames.applyTransformRules,
      'llm_result': {
        ...result,
        'note': result['ok'] == true
            ? 'Transform rules were applied on the frontend importer state.'
            : 'Transform rules were not applied.',
      },
    };
  }

  static String _stringArg(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static int _intArg(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool _boolArg(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;

    final text = value.toString().trim().toLowerCase();

    if (['true', '1', 'yes', 'y', 'tak', 'on'].contains(text)) return true;
    if (['false', '0', 'no', 'n', 'nie', 'off'].contains(text)) return false;

    return fallback;
  }
}