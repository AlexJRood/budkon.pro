import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:xml/xml.dart';

/// =======================
/// API URLs
/// =======================
class ImportApiUrls {
  static const String base = 'https://www.superbee.cloud/data/import';

  static const String options = '$base/batch/';
  static const String legacyOptions = '$base/';
  static const String legacyImport = '$base/';

  static const String import = '$base/';
  static const String jobs = '$base/jobs/';
  static String jobStatus(String id) => '$base/jobs/$id/';

  static const String batchSend = '$base/batch/send/';

  static const String emmaGuidelines = '$base/emma/guidelines/';
  static const String emmaSuggestSplit = '$base/emma/suggest-split/';
  static const String emmaSuggestFullPlan = '$base/emma/suggest-full-plan/';

  /// Review flow. Optional for later.
  static const String reviewStart = '$base/review/start/';
  static String reviewSession(String id) => '$base/review/$id/';
  static String reviewRowResolve(String sessionId, int rowIndex) =>
      '$base/review/$sessionId/row/$rowIndex/resolve/';
  static String reviewBulkResolve(String sessionId) =>
      '$base/review/$sessionId/bulk-resolve/';
  static String reviewCommit(String sessionId) =>
      '$base/review/$sessionId/commit/';
}

/// =======================
/// MODELS
/// =======================

class ImportOptions {
  /// key: target_model name, value: raw field spec from MODEL_FIELDS.
  final Map<String, dynamic> targetModels;
  final List<Map<String, dynamic>> fileTypes;
  final List<Map<String, dynamic>> operations;
  final bool reviewSupported;
  final bool directImportSupported;

  ImportOptions({
    required this.targetModels,
    required this.fileTypes,
    this.operations = const [],
    this.reviewSupported = false,
    this.directImportSupported = true,
  });
}

class _PreparedImportRow {
  final int previewRowIndex;
  final Map<String, dynamic> data;

  _PreparedImportRow({
    required this.previewRowIndex,
    required this.data,
  });
}

class ImportJobSummary {
  final String id;
  final String fileName;
  final String fileType;
  final String status;
  final int progress;
  final int totalRows;
  final int successfulRows;
  final int failedRows;
  final DateTime? createdAt;
  final DateTime? completedAt;

  ImportJobSummary({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.status,
    required this.progress,
    required this.totalRows,
    required this.successfulRows,
    required this.failedRows,
    this.createdAt,
    this.completedAt,
  });

  factory ImportJobSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    int parseInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return ImportJobSummary(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      progress: parseInt(json['progress']),
      totalRows: parseInt(json['total_rows']),
      successfulRows: parseInt(json['successful_rows']),
      failedRows: parseInt(json['failed_rows']),
      createdAt: parseDate(json['created_at']),
      completedAt: parseDate(json['completed_at']),
    );
  }
}

class RowImportError {
  /// 1-based row number displayed to user.
  final int row;
  final String error;

  RowImportError({
    required this.row,
    required this.error,
  });

  factory RowImportError.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return RowImportError(
      row: parseInt(json['row']),
      error: json['error']?.toString() ?? '',
    );
  }
}

class BatchImportResult {
  final int batchIndex;
  final String targetModel;
  final int totalRows;
  final int successfulRows;
  final int failedRows;
  final List<RowImportError> errors;

  BatchImportResult({
    required this.batchIndex,
    required this.targetModel,
    required this.totalRows,
    required this.successfulRows,
    required this.failedRows,
    required this.errors,
  });

  factory BatchImportResult.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    final errorsRaw = json['errors'];
    final List<RowImportError> errors = [];

    if (errorsRaw is List) {
      for (final item in errorsRaw) {
        if (item is Map) {
          errors.add(RowImportError.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return BatchImportResult(
      batchIndex: parseInt(json['batch_index']),
      targetModel: json['target_model']?.toString() ?? '',
      totalRows: parseInt(json['total_rows']),
      successfulRows: parseInt(json['successful_rows']),
      failedRows: parseInt(json['failed_rows']),
      errors: errors,
    );
  }

  BatchImportResult copyWith({
    int? batchIndex,
    String? targetModel,
    int? totalRows,
    int? successfulRows,
    int? failedRows,
    List<RowImportError>? errors,
  }) {
    return BatchImportResult(
      batchIndex: batchIndex ?? this.batchIndex,
      targetModel: targetModel ?? this.targetModel,
      totalRows: totalRows ?? this.totalRows,
      successfulRows: successfulRows ?? this.successfulRows,
      failedRows: failedRows ?? this.failedRows,
      errors: errors ?? this.errors,
    );
  }

  BatchImportResult mergeWith(BatchImportResult other) {
    return BatchImportResult(
      batchIndex: batchIndex,
      targetModel: targetModel,
      totalRows: totalRows + other.totalRows,
      successfulRows: successfulRows + other.successfulRows,
      failedRows: failedRows + other.failedRows,
      errors: [
        ...errors,
        ...other.errors,
      ],
    );
  }
}

/// Transform type sent to legacy backend mapping.
enum TransformType { raw, split, regex, constant }

extension TransformTypeName on TransformType {
  String get backendName {
    switch (this) {
      case TransformType.raw:
        return 'raw';
      case TransformType.split:
        return 'split';
      case TransformType.regex:
        return 'regex';
      case TransformType.constant:
        return 'const';
    }
  }
}

class ColumnTransformRule {
  final String id;
  final String sourceColumn;
  final String outputColumn;
  final TransformType transform;

  final String? separator;
  final int? splitIndex;
  final bool takeRemainder;

  final String? regexPattern;
  final int? regexGroup;

  final bool regexStripSourceValue;
  final bool regexStripSourceKey;
  final bool regexStripLeadingSeparator;
  final bool regexStripTrailingSeparator;
  final bool regexNormalizeDigits;
  final bool skipIfNoMatch;

  final String? constValue;

  ColumnTransformRule({
    required this.id,
    required this.sourceColumn,
    required this.outputColumn,
    this.transform = TransformType.raw,
    this.separator,
    this.splitIndex,
    this.takeRemainder = false,
    this.regexPattern,
    this.regexGroup,
    this.regexStripSourceValue = false,
    this.regexStripSourceKey = false,
    this.regexStripLeadingSeparator = false,
    this.regexStripTrailingSeparator = false,
    this.regexNormalizeDigits = false,
    this.skipIfNoMatch = false,
    this.constValue,
  });

  ColumnTransformRule copyWith({
    String? id,
    String? sourceColumn,
    String? outputColumn,
    TransformType? transform,
    String? separator,
    int? splitIndex,
    bool? takeRemainder,
    String? regexPattern,
    int? regexGroup,
    bool? regexStripSourceValue,
    bool? regexStripSourceKey,
    bool? regexStripLeadingSeparator,
    bool? regexStripTrailingSeparator,
    bool? regexNormalizeDigits,
    bool? skipIfNoMatch,
    String? constValue,
  }) {
    return ColumnTransformRule(
      id: id ?? this.id,
      sourceColumn: sourceColumn ?? this.sourceColumn,
      outputColumn: outputColumn ?? this.outputColumn,
      transform: transform ?? this.transform,
      separator: separator ?? this.separator,
      splitIndex: splitIndex ?? this.splitIndex,
      takeRemainder: takeRemainder ?? this.takeRemainder,
      regexPattern: regexPattern ?? this.regexPattern,
      regexGroup: regexGroup ?? this.regexGroup,
      regexStripSourceValue:
          regexStripSourceValue ?? this.regexStripSourceValue,
      regexStripSourceKey: regexStripSourceKey ?? this.regexStripSourceKey,
      regexStripLeadingSeparator:
          regexStripLeadingSeparator ?? this.regexStripLeadingSeparator,
      regexStripTrailingSeparator:
          regexStripTrailingSeparator ?? this.regexStripTrailingSeparator,
      regexNormalizeDigits:
          regexNormalizeDigits ?? this.regexNormalizeDigits,
      skipIfNoMatch: skipIfNoMatch ?? this.skipIfNoMatch,
      constValue: constValue ?? this.constValue,
    );
  }
}

class FieldMappingRule {
  final String id;
  final String columnName;
  final String targetModel;
  final String targetField;

  FieldMappingRule({
    required this.id,
    required this.columnName,
    required this.targetModel,
    required this.targetField,
  });

  FieldMappingRule copyWith({
    String? id,
    String? columnName,
    String? targetModel,
    String? targetField,
  }) {
    return FieldMappingRule(
      id: id ?? this.id,
      columnName: columnName ?? this.columnName,
      targetModel: targetModel ?? this.targetModel,
      targetField: targetField ?? this.targetField,
    );
  }
}

/// =======================
/// PROVIDERS + UTILS
/// =======================

dynamic decodeResponseData(Response res) {
  final data = res.data;
  if (data == null) return null;

  if (data is Uint8List) {
    final str = utf8.decode(data);
    return jsonDecode(str);
  }

  if (data is List<int>) {
    final str = utf8.decode(data);
    return jsonDecode(str);
  }

  if (data is String) {
    try {
      return jsonDecode(data);
    } catch (_) {
      return data;
    }
  }

  return data;
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _normalizeFileTypes(dynamic raw) {
  if (raw is! List) return [];

  final out = <Map<String, dynamic>>[];

  for (final item in raw) {
    if (item is Map) {
      out.add(Map<String, dynamic>.from(item));
      continue;
    }

    if (item is List && item.length >= 2) {
      out.add({
        'value': item[0]?.toString() ?? '',
        'label': item[1]?.toString() ?? '',
      });
      continue;
    }
  }

  return out;
}

List<Map<String, dynamic>> _normalizeOperations(dynamic raw) {
  if (raw is! List) return [];

  final out = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is Map) {
      out.add(Map<String, dynamic>.from(item));
    }
  }

  return out;
}

final importOptionsProvider = FutureProvider<ImportOptions>((ref) async {
  Response? res = await ApiServices.get(
    ImportApiUrls.options,
    hasToken: true,
    ref: ref,
  );

  // Fallback, bo jeśli /batch/ padnie albo route nie jest jeszcze na serwerze,
  // edytor nadal może działać na legacy /data/import/.
  res ??= await ApiServices.get(
    ImportApiUrls.legacyOptions,
    hasToken: true,
    ref: ref,
  );

  if (res == null) {
    throw Exception(
      'Brak odpowiedzi z serwera. Sprawdź endpoint: ${ImportApiUrls.options}',
    );
  }

  final body = _asStringMap(decodeResponseData(res));

  final targetModels = _asStringMap(body['target_models']);
  final fileTypes = _normalizeFileTypes(body['file_types']);
  final operations = _normalizeOperations(body['operations']);

  if (targetModels.isEmpty) {
    throw Exception(
      'Serwer odpowiedział, ale nie zwrócił target_models.',
    );
  }

  return ImportOptions(
    targetModels: targetModels,
    fileTypes: fileTypes,
    operations: operations,
    reviewSupported: body['review_supported'] == true,
    directImportSupported: body['direct_import_supported'] != false,
  );
});

final importJobsProvider =
    FutureProvider.autoDispose<List<ImportJobSummary>>((ref) async {
  final res = await ApiServices.get(
    ImportApiUrls.jobs,
    hasToken: true,
    ref: ref,
  );

  if (res == null) return [];

  final body = _asStringMap(decodeResponseData(res));
  final jobsRaw = body['jobs'];

  if (jobsRaw is! List) return [];

  return jobsRaw
      .whereType<Map>()
      .map((e) => ImportJobSummary.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

/// =======================
/// FORM STATE
/// =======================
class ImportFormState {
  final PlatformFile? file;
  final String? selectedTargetModel;

  final List<String> originalColumns;
  final List<List<String>> originalData;

  final List<String> previewColumns;
  final List<List<String>> previewData;

  final List<ColumnTransformRule> transforms;
  final List<FieldMappingRule> fieldMappings;

  /// Full relational plan generated by Emma.
  ///
  /// Shape expected by backend:
  /// {
  ///   "entities": [...],
  ///   "relations": [...],
  ///   "identity_strategy": {...}
  /// }
  final Map<String, dynamic>? emmaEntityPlan;

  final bool saveTemplate;
  final String templateName;
  final bool isSubmitting;
  final double uploadProgress;
  final String? lastMessage;
  final String? lastJobId;
  final String? error;

  final int currentPage;
  final int pageSize;

  final List<int> selectedRowIndexes;

  final bool isBatchRunning;
  final double batchProgress;
  final String? batchStatusText;
  final List<BatchImportResult> batchResults;

  /// XLSX multi-sheet support
  final List<String> xlsxSheetNames;
  final String? xlsxSelectedSheet;

  /// File encoding ('utf-8', 'utf-16', 'windows-1250', 'iso-8859-2')
  final String fileEncoding;

  /// Set when parsed file exceeds 5 000 rows
  final String? largeFileWarning;

  ImportFormState({
    this.file,
    this.selectedTargetModel,
    this.originalColumns = const [],
    this.originalData = const [],
    this.previewColumns = const [],
    this.previewData = const [],
    this.transforms = const [],
    this.fieldMappings = const [],
    this.emmaEntityPlan,
    this.saveTemplate = false,
    this.templateName = '',
    this.isSubmitting = false,
    this.uploadProgress = 0.0,
    this.lastMessage,
    this.lastJobId,
    this.error,
    this.currentPage = 0,
    this.pageSize = 100,
    this.selectedRowIndexes = const [],
    this.isBatchRunning = false,
    this.batchProgress = 0.0,
    this.batchStatusText,
    this.batchResults = const [],
    this.xlsxSheetNames = const [],
    this.xlsxSelectedSheet,
    this.fileEncoding = 'utf-8',
    this.largeFileWarning,
  });

  ImportFormState copyWith({
    PlatformFile? file,
    bool clearFile = false,
    String? selectedTargetModel,
    bool clearSelectedTargetModel = false,
    List<String>? originalColumns,
    List<List<String>>? originalData,
    List<String>? previewColumns,
    List<List<String>>? previewData,
    List<ColumnTransformRule>? transforms,
    List<FieldMappingRule>? fieldMappings,
    Map<String, dynamic>? emmaEntityPlan,
    bool clearEmmaEntityPlan = false,
    bool? saveTemplate,
    String? templateName,
    bool? isSubmitting,
    double? uploadProgress,
    String? lastMessage,
    bool clearLastMessage = false,
    String? lastJobId,
    bool clearLastJobId = false,
    String? error,
    int? currentPage,
    int? pageSize,
    List<int>? selectedRowIndexes,
    bool? isBatchRunning,
    double? batchProgress,
    String? batchStatusText,
    bool clearBatchStatusText = false,
    List<BatchImportResult>? batchResults,
    List<String>? xlsxSheetNames,
    String? xlsxSelectedSheet,
    bool clearXlsxSelectedSheet = false,
    String? fileEncoding,
    String? largeFileWarning,
    bool clearLargeFileWarning = false,
  }) {
    return ImportFormState(
      file: clearFile ? null : (file ?? this.file),
      selectedTargetModel: clearSelectedTargetModel
          ? null
          : (selectedTargetModel ?? this.selectedTargetModel),
      originalColumns: originalColumns ?? this.originalColumns,
      originalData: originalData ?? this.originalData,
      previewColumns: previewColumns ?? this.previewColumns,
      previewData: previewData ?? this.previewData,
      transforms: transforms ?? this.transforms,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      emmaEntityPlan: clearEmmaEntityPlan
          ? null
          : (emmaEntityPlan ?? this.emmaEntityPlan),
      saveTemplate: saveTemplate ?? this.saveTemplate,
      templateName: templateName ?? this.templateName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      lastJobId: clearLastJobId ? null : (lastJobId ?? this.lastJobId),
      error: error,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      selectedRowIndexes: selectedRowIndexes ?? this.selectedRowIndexes,
      isBatchRunning: isBatchRunning ?? this.isBatchRunning,
      batchProgress: batchProgress ?? this.batchProgress,
      batchStatusText:
          clearBatchStatusText ? null : (batchStatusText ?? this.batchStatusText),
      batchResults: batchResults ?? this.batchResults,
      xlsxSheetNames: xlsxSheetNames ?? this.xlsxSheetNames,
      xlsxSelectedSheet: clearXlsxSelectedSheet
          ? null
          : (xlsxSelectedSheet ?? this.xlsxSelectedSheet),
      fileEncoding: fileEncoding ?? this.fileEncoding,
      largeFileWarning: clearLargeFileWarning
          ? null
          : (largeFileWarning ?? this.largeFileWarning),
    );
  }
}

/// =======================
/// TRANSFORM HELPERS
/// =======================

bool _isWordChar(String ch) {
  return RegExp(r'[0-9A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]').hasMatch(ch);
}

String normalizeDigitSequence(String input) {
  return input.replaceAll(RegExp(r'[^0-9]'), '');
}

String applyTransformRuleValue(ColumnTransformRule rule, String value) {
  switch (rule.transform) {
    case TransformType.raw:
      return value;

    case TransformType.split:
      final sep = rule.separator ?? ' ';
      final parts = value.split(sep);
      final idx = rule.splitIndex ?? 0;

      if (parts.isEmpty) return '';

      if (rule.takeRemainder) {
        if (idx < 0 || idx >= parts.length) return '';
        return parts.sublist(idx).join(sep).trim();
      }

      if (idx < 0 || idx >= parts.length) return '';
      return parts[idx].trim();

    case TransformType.regex:
      final pattern = rule.regexPattern;
      if (pattern == null || pattern.isEmpty) {
        return value;
      }

      final re = RegExp(pattern, caseSensitive: false);
      final match = re.firstMatch(value);

      final bool hasStrip = rule.regexStripSourceKey ||
          rule.regexStripSourceValue ||
          rule.regexStripLeadingSeparator ||
          rule.regexStripTrailingSeparator;

      if (match == null) {
        return hasStrip ? value : '';
      }

      if (hasStrip) {
        final original = value;

        final fullStart = match.start;
        final fullEnd = match.end;

        int valueStart;
        int valueEnd;

        if (match.groupCount >= 1 && (match.group(1)?.isNotEmpty ?? false)) {
          final fullMatch = match.group(0)!;
          final valueText = match.group(1)!;
          final innerOffset = fullMatch.indexOf(valueText);
          final safeOffset = innerOffset < 0 ? 0 : innerOffset;
          valueStart = fullStart + safeOffset;
          valueEnd = valueStart + valueText.length;
        } else {
          valueStart = fullStart;
          valueEnd = fullEnd;
        }

        final keyStart = fullStart;
        final keyEnd = valueStart.clamp(fullStart, fullEnd);

        int beforeEnd = fullStart;
        int afterStart = valueEnd;

        if (rule.regexStripLeadingSeparator && beforeEnd > 0) {
          final ch = original[beforeEnd - 1];
          if (!_isWordChar(ch)) beforeEnd -= 1;
        }

        if (rule.regexStripTrailingSeparator && afterStart < original.length) {
          final ch = original[afterStart];
          if (!_isWordChar(ch)) afterStart += 1;
        }

        final before = original.substring(0, beforeEnd);
        final keyChunk = original.substring(keyStart, keyEnd);
        final valueChunk = original.substring(valueStart, valueEnd);
        final after = original.substring(afterStart);

        final keepKey = !rule.regexStripSourceKey;
        final keepValue = !rule.regexStripSourceValue;

        final buffer = StringBuffer();
        buffer.write(before);
        if (keepKey) buffer.write(keyChunk);
        if (keepValue) buffer.write(valueChunk);
        buffer.write(after);

        return buffer.toString().trim();
      }

      var g = rule.regexGroup ?? 1;

      if (g < 0 || g > match.groupCount) {
        g = 0;
      }

      var out = match.group(g) ?? '';

      if (rule.regexNormalizeDigits) {
        out = normalizeDigitSequence(out);
      }

      return out.trim();

    case TransformType.constant:
      return rule.constValue ?? '';
  }
}

/// =======================
/// FORM NOTIFIER
/// =======================

class ImportFormNotifier extends StateNotifier<ImportFormState> {
  ImportFormNotifier() : super(ImportFormState());

  FieldMappingRule? getMappingForTarget(String targetModel, String targetField) {
    for (final m in state.fieldMappings) {
      if (m.targetModel == targetModel && m.targetField == targetField) {
        return m;
      }
    }
    return null;
  }

  bool isRowSelected(int previewRowIndex) {
    return state.selectedRowIndexes.contains(previewRowIndex);
  }

  Future<Map<String, dynamic>> requestEmmaSplitSuggestions(
    WidgetRef ref, {
    String? targetModel,
    List<String>? focusColumns,
    int maxRules = 20,
    bool selectedRowsOnly = false,
  }) async {
    final model = (targetModel ?? state.selectedTargetModel ?? '').trim();

    if (model.isEmpty) {
      return {
        'ok': false,
        'error': 'Najpierw wybierz model docelowy importu.',
      };
    }

    if (state.previewColumns.isEmpty || state.previewData.isEmpty) {
      return {
        'ok': false,
        'error': 'Brak danych w edytorze importu.',
      };
    }

    final profile = buildEmmaDatasetProfile(
      maxRows: 40,
      maxSamplesPerColumn: 15,
      selectedRowsOnly: selectedRowsOnly,
    );

    final payload = {
      'target_model': model,
      'dataset_profile': profile,
      'focus_columns': focusColumns ?? <String>[],
      'max_rules': maxRules,
    };

    try {
      final res = await ApiServices.post(
        ImportApiUrls.emmaSuggestSplit,
        hasToken: true,
        data: payload,
        ref: ref,
      );

      if (res == null) {
        return {
          'ok': false,
          'error': 'Brak odpowiedzi z API Emmy importera.',
        };
      }

      final body = _asStringMap(decodeResponseData(res));

      if (res.statusCode != 200 && res.statusCode != 201) {
        return {
          'ok': false,
          'error': body['error']?.toString() ??
              'Błąd API Emmy importera: ${res.statusCode}',
          'response': body,
        };
      }

      return body;
    } catch (e) {
      return {
        'ok': false,
        'error': 'Wyjątek podczas wywołania API Emmy importera: $e',
      };
    }
  }

  Future<Map<String, dynamic>> requestEmmaFullPlan(
    WidgetRef ref, {
    String? targetModel,
    List<String>? focusColumns,
    int maxRules = 40,
    int maxEntities = 5,
    bool selectedRowsOnly = false,
  }) async {
    final model = (targetModel ?? state.selectedTargetModel ?? '').trim();

    if (model.isEmpty) {
      return {
        'ok': false,
        'error': 'Najpierw wybierz model docelowy importu.',
      };
    }

    if (state.previewColumns.isEmpty || state.previewData.isEmpty) {
      return {
        'ok': false,
        'error': 'Brak danych w edytorze importu.',
      };
    }

    final profile = buildEmmaDatasetProfile(
      maxRows: 50,
      maxSamplesPerColumn: 15,
      selectedRowsOnly: selectedRowsOnly,
    );

    final payload = {
      'target_model': model,
      'dataset_profile': profile,
      'focus_columns': focusColumns ?? <String>[],
      'max_rules': maxRules,
      'max_entities': maxEntities,
      'current_entity_plan': state.emmaEntityPlan,
    };

    try {
      final res = await ApiServices.post(
        ImportApiUrls.emmaSuggestFullPlan,
        hasToken: true,
        data: payload,
        ref: ref,
      );

      if (res == null) {
        return {
          'ok': false,
          'error': 'Brak odpowiedzi z API pełnego planu Emmy importera.',
        };
      }

      final body = _asStringMap(decodeResponseData(res));

      if (res.statusCode == 404) {
        final split = await requestEmmaSplitSuggestions(
          ref,
          targetModel: model,
          focusColumns: focusColumns,
          maxRules: maxRules,
          selectedRowsOnly: selectedRowsOnly,
        );

        return {
          'ok': split['ok'] == true,
          'target_model': model,
          'summary': split['summary'] ??
              'Backend nie ma jeszcze endpointu full-plan, użyto suggest-split.',
          'split': split,
          'entity_plan': {
            'ok': false,
            'plan': null,
            'warning': 'Missing backend endpoint: suggest-full-plan.',
          },
          'rules': split['rules'] ?? <dynamic>[],
          'mapping_hints': split['mapping_hints'] ?? <dynamic>[],
          'warnings': split['warnings'] ?? <dynamic>[],
          'fallback_used': true,
        };
      }

      if (res.statusCode != 200 && res.statusCode != 201) {
        return {
          'ok': false,
          'error': body['error']?.toString() ??
              'Błąd API pełnego planu Emmy importera: ${res.statusCode}',
          'response': body,
        };
      }

      return body;
    } catch (e) {
      return {
        'ok': false,
        'error': 'Wyjątek podczas wywołania pełnego planu Emmy importera: $e',
      };
    }
  }

  Future<Map<String, dynamic>> applyEmmaFullPlanResult(
    Map<String, dynamic> result, {
    bool applyTransforms = true,
    bool applyMappings = true,
    bool saveEntityPlan = true,
    double minMappingConfidence = 0.35,
  }) async {
    Map<String, dynamic> transformResult = {
      'ok': true,
      'applied_count': 0,
      'skipped_count': 0,
      'message': 'Transforms not applied.',
    };

    Map<String, dynamic> mappingResult = {
      'ok': true,
      'applied_count': 0,
      'skipped_count': 0,
      'message': 'Mappings not applied.',
    };

    var entityPlanSaved = false;
    final warnings = <String>[];

    if (applyTransforms) {
      final rules = _extractEmmaRulesFromResult(result);
      if (rules.isNotEmpty) {
        transformResult = await applyEmmaTransformRules(
          rules,
          clearExisting: false,
          replaceSameOutputColumn: true,
        );
      }
    }

    if (applyMappings) {
      final hints = _extractEmmaMappingHintsFromResult(result);
      if (hints.isNotEmpty) {
        mappingResult = await applyEmmaMappingHints(
          hints,
          replaceExistingForTargetField: true,
          minConfidence: minMappingConfidence,
        );
      }
    }

    if (saveEntityPlan) {
      final plan = _extractEmmaEntityPlanFromResult(result);

      if (plan.isNotEmpty) {
        state = state.copyWith(
          emmaEntityPlan: plan,
          error: null,
          lastMessage: 'Emma zapisała plan encji i relacji importu.'.tr,
        );
        entityPlanSaved = true;
      } else {
        warnings.add('Brak planu encji / relacji do zapisania.');
      }
    }

    return {
      'ok': true,
      'transform_result': transformResult,
      'mapping_result': mappingResult,
      'entity_plan_saved': entityPlanSaved,
      'emma_entity_plan': state.emmaEntityPlan,
      'warnings': warnings,
    };
  }

  void setRowSelected(int previewRowIndex, bool selected) {
    final set = state.selectedRowIndexes.toSet();

    if (selected) {
      set.add(previewRowIndex);
    } else {
      set.remove(previewRowIndex);
    }

    final updated = set.toList()..sort();
    state = state.copyWith(selectedRowIndexes: updated, error: null);
  }

  void toggleRowSelection(int previewRowIndex) {
    setRowSelected(previewRowIndex, !isRowSelected(previewRowIndex));
  }

  void selectAllRows([List<int>? rowIndexes]) {
    final target = rowIndexes ??
        List<int>.generate(state.previewData.length, (index) => index);

    final updated = {
      ...state.selectedRowIndexes,
      ...target.where((i) => i >= 0 && i < state.previewData.length),
    }.toList()
      ..sort();

    state = state.copyWith(selectedRowIndexes: updated, error: null);
  }

  void clearSelectedRows([List<int>? rowIndexes]) {
    if (rowIndexes == null) {
      state = state.copyWith(selectedRowIndexes: [], error: null);
      return;
    }

    final removeSet = rowIndexes.toSet();
    final updated = state.selectedRowIndexes
        .where((i) => !removeSet.contains(i))
        .toList()
      ..sort();

    state = state.copyWith(selectedRowIndexes: updated, error: null);
  }

  void selectOnlyRows(List<int> rowIndexes) {
    final updated = rowIndexes
        .where((i) => i >= 0 && i < state.previewData.length)
        .toSet()
        .toList()
      ..sort();

    state = state.copyWith(selectedRowIndexes: updated, error: null);
  }

  Future<Map<String, dynamic>> applyEmmaMappingHints(
    List<dynamic> rawHints, {
    bool replaceExistingForTargetField = true,
    double minConfidence = 0.70,
  }) async {
    if (rawHints.isEmpty) {
      return {
        'ok': false,
        'applied_count': 0,
        'skipped_count': 0,
        'message': 'No mapping hints provided.',
      };
    }

    final existingColumns = state.previewColumns.toSet();
    final parsed = <FieldMappingRule>[];
    final skipped = <Map<String, dynamic>>[];

    for (var i = 0; i < rawHints.length; i++) {
      final raw = rawHints[i];

      if (raw is! Map) {
        skipped.add({
          'index': i,
          'reason': 'Hint is not an object.',
        });
        continue;
      }

      final map = Map<String, dynamic>.from(raw);

      final outputColumn = _emmaString(
        map['output_column'] ??
            map['outputColumn'] ??
            map['column_name'] ??
            map['columnName'] ??
            map['source_column'] ??
            map['sourceColumn'],
      );

      final targetModel = _emmaString(
        map['target_model'] ?? map['targetModel'] ?? state.selectedTargetModel,
      );

      final targetField = _emmaString(
        map['target_field'] ?? map['targetField'] ?? map['field'],
      );

      final confidenceRaw = map['confidence'];
      final confidence = confidenceRaw is num
          ? confidenceRaw.toDouble()
          : double.tryParse(confidenceRaw?.toString() ?? '') ?? 1.0;

      if (confidence < minConfidence) {
        skipped.add({
          'index': i,
          'reason': 'Confidence too low: $confidence',
          'hint': map,
        });
        continue;
      }

      if (outputColumn.isEmpty) {
        skipped.add({
          'index': i,
          'reason': 'Missing output_column.',
          'hint': map,
        });
        continue;
      }

      if (!existingColumns.contains(outputColumn)) {
        skipped.add({
          'index': i,
          'reason': 'Column does not exist in preview: $outputColumn',
          'hint': map,
        });
        continue;
      }

      if (targetModel.isEmpty || targetField.isEmpty) {
        skipped.add({
          'index': i,
          'reason': 'Missing target_model or target_field.',
          'hint': map,
        });
        continue;
      }

      parsed.add(
        FieldMappingRule(
          id: 'emma_map_${DateTime.now().microsecondsSinceEpoch}_$i',
          columnName: outputColumn,
          targetModel: targetModel,
          targetField: targetField,
        ),
      );
    }

    if (parsed.isEmpty) {
      return {
        'ok': false,
        'applied_count': 0,
        'skipped_count': skipped.length,
        'skipped': skipped,
        'message': 'No valid mapping hints to apply.',
      };
    }

    var updated = List<FieldMappingRule>.from(state.fieldMappings);

    if (replaceExistingForTargetField) {
      final pairs = parsed.map((m) => '${m.targetModel}.${m.targetField}').toSet();

      updated = updated.where((m) {
        return !pairs.contains('${m.targetModel}.${m.targetField}');
      }).toList();
    }

    for (final mapping in parsed) {
      final alreadyExists = updated.any(
        (m) =>
            m.columnName == mapping.columnName &&
            m.targetModel == mapping.targetModel &&
            m.targetField == mapping.targetField,
      );

      if (!alreadyExists) {
        updated.add(mapping);
      }
    }

    state = state.copyWith(
      fieldMappings: updated,
      error: null,
      lastMessage:
          'Emma zastosowała ${parsed.length} sugestii mapowania pól.'.tr,
    );

    return {
      'ok': true,
      'applied_count': parsed.length,
      'skipped_count': skipped.length,
      'skipped': skipped,
    };
  }

  void setMappingForTarget({
    required String? columnName,
    required String targetModel,
    required String targetField,
  }) {
    if (columnName == null || columnName.isEmpty) {
      final updated = state.fieldMappings
          .where(
            (m) => !(m.targetModel == targetModel && m.targetField == targetField),
          )
          .toList(growable: false);

      state = state.copyWith(fieldMappings: updated, error: null);
      return;
    }

    final List<FieldMappingRule> updated = [];
    var found = false;

    for (final m in state.fieldMappings) {
      if (m.targetModel == targetModel && m.targetField == targetField) {
        updated.add(m.copyWith(columnName: columnName));
        found = true;
      } else {
        updated.add(m);
      }
    }

    if (!found) {
      updated.add(
        FieldMappingRule(
          id: 'map_${DateTime.now().microsecondsSinceEpoch}',
          columnName: columnName,
          targetModel: targetModel,
          targetField: targetField,
        ),
      );
    }

    state = state.copyWith(fieldMappings: updated, error: null);
  }

  void clearEmmaEntityPlan() {
    state = state.copyWith(
      clearEmmaEntityPlan: true,
      lastMessage: 'Wyczyszczono plan encji i relacji Emmy.'.tr,
      error: null,
    );
  }

  void clearMessages() {
    state = state.copyWith(
      error: null,
      clearLastMessage: true,
    );
  }

  /// Changes file encoding and re-parses the current file.
  Future<void> setEncoding(String encoding) async {
    if (state.fileEncoding == encoding) return;
    final file = state.file;
    if (file == null || file.bytes == null) {
      state = state.copyWith(fileEncoding: encoding);
      return;
    }
    state = state.copyWith(fileEncoding: encoding);
    await setFile(file);
  }

  /// Selects an XLSX sheet by name and re-parses.
  Future<void> selectXlsxSheet(String sheetName) async {
    if (state.xlsxSelectedSheet == sheetName) return;
    final file = state.file;
    if (file == null || file.bytes == null) return;
    state = state.copyWith(xlsxSelectedSheet: sheetName);
    await setFile(file);
  }

  /// Retries only the rows that failed in the last batch run.
  Future<void> retryFailedRows(WidgetRef ref) async {
    final failedIndexes = <int>{};
    for (final result in state.batchResults) {
      for (final err in result.errors) {
        final idx = err.row - 1;
        if (idx >= 0 && idx < state.previewData.length) {
          failedIndexes.add(idx);
        }
      }
    }
    if (failedIndexes.isEmpty) return;
    state = state.copyWith(
      selectedRowIndexes: failedIndexes.toList()..sort(),
    );
    await submitBatch(ref);
  }

  /// Renames a column header across originalColumns, transforms and fieldMappings.
  void renameColumn(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;

    final origIdx = state.originalColumns.indexOf(oldName);
    if (origIdx < 0) return;

    final newOrig = List<String>.from(state.originalColumns);
    newOrig[origIdx] = trimmed;

    final newTransforms = state.transforms.map((t) {
      if (t.sourceColumn == oldName && t.outputColumn == oldName) {
        return t.copyWith(sourceColumn: trimmed, outputColumn: trimmed);
      }
      if (t.sourceColumn == oldName) return t.copyWith(sourceColumn: trimmed);
      if (t.outputColumn == oldName) return t.copyWith(outputColumn: trimmed);
      return t;
    }).toList();

    final newMappings = state.fieldMappings.map((m) {
      if (m.columnName == oldName) return m.copyWith(columnName: trimmed);
      return m;
    }).toList();

    state = state.copyWith(
      originalColumns: newOrig,
      transforms: newTransforms,
      fieldMappings: newMappings,
      error: null,
    );
    _recomputePreviewWithTransforms();
  }

  void _resetPagination() {
    state = state.copyWith(currentPage: 0, error: null);
  }

  void setPage(int page) {
    if (page < 0) page = 0;

    final totalRows = state.previewData.length;
    if (totalRows == 0) {
      state = state.copyWith(currentPage: 0, error: null);
      return;
    }

    final totalPages = ((totalRows - 1) ~/ state.pageSize) + 1;
    if (page >= totalPages) page = totalPages - 1;

    state = state.copyWith(currentPage: page, error: null);
  }

  void setPageSize(int size) {
    if (size <= 0) size = 50;

    state = state.copyWith(
      pageSize: size,
      currentPage: 0,
      error: null,
    );
  }

  Future<void> setFile(PlatformFile? file) async {
    if (file == null) {
      state = state.copyWith(
        clearFile: true,
        clearSelectedTargetModel: true,
        clearEmmaEntityPlan: true,
        originalColumns: [],
        originalData: [],
        previewColumns: [],
        previewData: [],
        transforms: [],
        fieldMappings: [],
        selectedRowIndexes: [],
        error: null,
        currentPage: 0,
        batchResults: [],
        isBatchRunning: false,
        isSubmitting: false,
        batchProgress: 0.0,
        clearBatchStatusText: true,
        clearLastMessage: true,
        clearLastJobId: true,
      );
      return;
    }

    state = state.copyWith(
      file: file,
      clearEmmaEntityPlan: true,
      originalColumns: [],
      originalData: [],
      previewColumns: [],
      previewData: [],
      transforms: [],
      fieldMappings: [],
      selectedRowIndexes: [],
      error: null,
      currentPage: 0,
      batchResults: [],
      isBatchRunning: false,
      isSubmitting: false,
      batchProgress: 0.0,
      clearBatchStatusText: true,
      clearLastMessage: true,
      clearLastJobId: true,
    );

    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = (file.extension ?? '').toLowerCase();

    switch (ext) {
      case 'csv':
      case 'tsv':
        _parseCsvOrTsv(bytes);
        break;
      case 'json':
        _parseJson(bytes);
        break;
      case 'xlsx':
      case 'xls':
        _parseXlsx(bytes);
        break;
      case 'xml':
        _parseXml(bytes);
        break;
      default:
        state = state.copyWith(
          error: 'Nieobsługiwany format pliku: .$ext'.tr,
        );
    }
  }

  // ── Codepage tables (bytes 0x80–0xFF → Unicode codepoints) ──────────────

  static const List<int> _kCp1250 = [
    0x20AC, 0x0081, 0x201A, 0x0083, 0x201E, 0x2026, 0x2020, 0x2021,
    0x0088, 0x2030, 0x0160, 0x2039, 0x015A, 0x0164, 0x017D, 0x0179,
    0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x0098, 0x2122, 0x0161, 0x203A, 0x015B, 0x0165, 0x017E, 0x017A,
    0x00A0, 0x02C7, 0x02D8, 0x0141, 0x00A4, 0x0104, 0x00A6, 0x00A7,
    0x00A8, 0x00A9, 0x015E, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x017B,
    0x00B0, 0x00B1, 0x02DB, 0x0142, 0x00B4, 0x00B5, 0x00B6, 0x00B7,
    0x00B8, 0x0105, 0x015F, 0x00BB, 0x013D, 0x02DD, 0x013E, 0x017C,
    0x0154, 0x00C1, 0x00C2, 0x0102, 0x00C4, 0x0139, 0x0106, 0x00C7,
    0x010C, 0x00C9, 0x0118, 0x00CB, 0x011A, 0x00CD, 0x00CE, 0x010E,
    0x0110, 0x0143, 0x0147, 0x00D3, 0x00D4, 0x0150, 0x00D6, 0x00D7,
    0x0158, 0x016E, 0x00DA, 0x0170, 0x00DC, 0x00DD, 0x0162, 0x00DF,
    0x0155, 0x00E1, 0x00E2, 0x0103, 0x00E4, 0x013A, 0x0107, 0x00E7,
    0x010D, 0x00E9, 0x0119, 0x00EB, 0x011B, 0x00ED, 0x00EE, 0x010F,
    0x0111, 0x0144, 0x0148, 0x00F3, 0x00F4, 0x0151, 0x00F6, 0x00F7,
    0x0159, 0x016F, 0x00FA, 0x0171, 0x00FC, 0x00FD, 0x0163, 0x02D9,
  ];

  static const List<int> _kLatin2 = [
    0x0080, 0x0081, 0x0082, 0x0083, 0x0084, 0x0085, 0x0086, 0x0087,
    0x0088, 0x0089, 0x008A, 0x008B, 0x008C, 0x008D, 0x008E, 0x008F,
    0x0090, 0x0091, 0x0092, 0x0093, 0x0094, 0x0095, 0x0096, 0x0097,
    0x0098, 0x0099, 0x009A, 0x009B, 0x009C, 0x009D, 0x009E, 0x009F,
    0x00A0, 0x0104, 0x02D8, 0x0141, 0x00A4, 0x013D, 0x015A, 0x00A7,
    0x00A8, 0x0160, 0x015E, 0x0164, 0x0179, 0x00AD, 0x017D, 0x017B,
    0x00B0, 0x0105, 0x02DB, 0x0142, 0x00B4, 0x013E, 0x015B, 0x02C7,
    0x00B8, 0x0161, 0x015F, 0x0165, 0x017A, 0x02DD, 0x017E, 0x017C,
    0x0154, 0x00C1, 0x00C2, 0x0102, 0x00C4, 0x0139, 0x0106, 0x00C7,
    0x010C, 0x00C9, 0x0118, 0x00CB, 0x011A, 0x00CD, 0x00CE, 0x010E,
    0x0110, 0x0143, 0x0147, 0x00D3, 0x00D4, 0x0150, 0x00D6, 0x00D7,
    0x0158, 0x016E, 0x00DA, 0x0170, 0x00DC, 0x00DD, 0x0162, 0x00DF,
    0x0155, 0x00E1, 0x00E2, 0x0103, 0x00E4, 0x013A, 0x0107, 0x00E7,
    0x010D, 0x00E9, 0x0119, 0x00EB, 0x011B, 0x00ED, 0x00EE, 0x010F,
    0x0111, 0x0144, 0x0148, 0x00F3, 0x00F4, 0x0151, 0x00F6, 0x00F7,
    0x0159, 0x016F, 0x00FA, 0x0171, 0x00FC, 0x00FD, 0x0163, 0x02D9,
  ];

  static String _decodeCodepage(Uint8List bytes, List<int> table) {
    final buf = StringBuffer();
    for (final b in bytes) {
      if (b < 0x80) {
        buf.writeCharCode(b);
      } else {
        final idx = b - 0x80;
        buf.writeCharCode(idx < table.length ? table[idx] : b);
      }
    }
    return buf.toString();
  }

  String _decodeFileBytes(Uint8List bytes) {
    switch (state.fileEncoding) {
      case 'utf-16':
        // Strip BOM if present, then decode as UTF-16 LE (Windows default)
        if (bytes.length >= 2 &&
            ((bytes[0] == 0xFF && bytes[1] == 0xFE) ||
                (bytes[0] == 0xFE && bytes[1] == 0xFF))) {
          return utf8.decode(bytes, allowMalformed: true);
        }
        return utf8.decode(bytes, allowMalformed: true);
      case 'windows-1250':
        return _decodeCodepage(bytes, _kCp1250);
      case 'iso-8859-2':
        return _decodeCodepage(bytes, _kLatin2);
      default:
        return utf8.decode(bytes, allowMalformed: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _applyParsedData(List<String> columns, List<List<String>> rows) {
    if (columns.isEmpty) {
      state = state.copyWith(
        error: 'Plik nie zawiera kolumn danych.'.tr,
      );
      return;
    }
    final warning = rows.length > 5000
        ? 'Plik zawiera ${rows.length} wierszy. Import może potrwać dłużej. Rozważ podział na mniejsze pliki.'
            .tr
        : null;
    state = state.copyWith(
      originalColumns: columns,
      originalData: rows,
      selectedRowIndexes: List<int>.generate(rows.length, (i) => i),
      error: null,
      largeFileWarning: warning,
      clearLargeFileWarning: warning == null,
    );
    _recomputePreviewWithTransforms();
  }

  void _parseCsvOrTsv(Uint8List bytes) {
    final content = _decodeFileBytes(bytes);
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    final delimiter = _detectDelimiter(lines.first);
    final header = _splitCsvLineBasic(lines.first, delimiter);
    final data = <List<String>>[];
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      data.add(_splitCsvLineBasic(line, delimiter));
    }
    _applyParsedData(header, data);
  }

  void _parseJson(Uint8List bytes) {
    try {
      final content = _decodeFileBytes(bytes);
      final decoded = jsonDecode(content);

      if (decoded is! List || decoded.isEmpty) {
        state = state.copyWith(
          error: 'JSON musi zawierać tablicę obiektów lub tablic.'.tr,
        );
        return;
      }

      final first = decoded.first;
      List<String> columns;
      List<List<String>> rows;

      if (first is Map) {
        columns = first.keys.map((k) => k.toString()).toList();
        rows = decoded.map<List<String>>((item) {
          if (item is! Map) return List.filled(columns.length, '');
          return columns
              .map((col) => item[col]?.toString() ?? '')
              .toList();
        }).toList();
      } else if (first is List) {
        columns = first.map((v) => v.toString()).toList();
        rows = decoded.skip(1).map<List<String>>((item) {
          if (item is! List) return List.filled(columns.length, '');
          return List.generate(
            columns.length,
            (i) => i < item.length ? item[i].toString() : '',
          );
        }).toList();
      } else {
        state = state.copyWith(
          error: 'Nieobsługiwana struktura JSON. Oczekiwano tablicy obiektów lub tablic.'.tr,
        );
        return;
      }

      _applyParsedData(columns, rows);
    } catch (e) {
      state = state.copyWith(
        error: 'Błąd parsowania JSON: $e'.tr,
      );
    }
  }

  void _parseXlsx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // Read shared strings table
      final sharedStrings = <String>[];
      final ssFile = archive.findFile('xl/sharedStrings.xml');
      if (ssFile != null) {
        final ssXml = XmlDocument.parse(
          utf8.decode(ssFile.content as List<int>, allowMalformed: true),
        );
        for (final si in ssXml.findAllElements('si')) {
          final tEls = si.findElements('t').toList();
          if (tEls.isNotEmpty) {
            sharedStrings.add(tEls.first.innerText);
          } else {
            // Rich text: collect all <r><t> segments
            final buf = StringBuffer();
            for (final r in si.findElements('r')) {
              for (final t in r.findElements('t')) {
                buf.write(t.innerText);
              }
            }
            sharedStrings.add(buf.toString());
          }
        }
      }

      // ── Extract sheet names from workbook.xml ─────────────────────────
      final sheetNames = <String>[];
      final sheetFiles = <String, String>{}; // sheetName → path in archive
      final wbFile = archive.findFile('xl/workbook.xml');
      if (wbFile != null) {
        final wbXml = XmlDocument.parse(
          utf8.decode(wbFile.content as List<int>, allowMalformed: true),
        );
        for (final sheet in wbXml.findAllElements('sheet')) {
          final name = sheet.getAttribute('name') ?? '';
          final rId = sheet.getAttribute('r:id') ??
              sheet.getAttribute('id') ??
              '';
          if (name.isNotEmpty) sheetNames.add(name);
          // Map rId to file via workbook.xml.rels
          sheetFiles[rId] = name;
        }
      }

      // Also read _rels to map rId → xl/worksheets/sheetN.xml path
      final relMap = <String, String>{}; // rId → archive path
      final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
      if (relsFile != null) {
        final relsXml = XmlDocument.parse(
          utf8.decode(relsFile.content as List<int>, allowMalformed: true),
        );
        for (final rel in relsXml.findAllElements('Relationship')) {
          final id = rel.getAttribute('Id') ?? '';
          final target = rel.getAttribute('Target') ?? '';
          if (target.startsWith('worksheets/')) {
            relMap[id] = 'xl/$target';
          }
        }
      }

      // Store sheet names in state (only update if different to avoid flickering)
      if (sheetNames.isNotEmpty) {
        state = state.copyWith(xlsxSheetNames: sheetNames);
      }

      // Select the target worksheet
      String? selectedSheet = state.xlsxSelectedSheet;
      if (selectedSheet == null || !sheetNames.contains(selectedSheet)) {
        selectedSheet = sheetNames.isNotEmpty ? sheetNames.first : null;
      }

      // Find the archive file for the selected sheet
      ArchiveFile? wsFile;
      if (selectedSheet != null) {
        // Find rId for selectedSheet name
        final rId = sheetFiles.entries
            .cast<MapEntry<String, String>?>()
            .firstWhere(
              (e) => e!.value == selectedSheet,
              orElse: () => null,
            )
            ?.key;
        if (rId != null && relMap.containsKey(rId)) {
          wsFile = archive.findFile(relMap[rId]!);
        }
      }
      // Fallback: try common paths
      if (wsFile == null) {
        for (final candidate in [
          'xl/worksheets/sheet1.xml',
          'xl/worksheets/Sheet1.xml',
        ]) {
          wsFile = archive.findFile(candidate);
          if (wsFile != null) break;
        }
      }
      wsFile ??= archive.files.cast<ArchiveFile?>().firstWhere(
            (f) =>
                f!.name.startsWith('xl/worksheets/') &&
                f.name.endsWith('.xml'),
            orElse: () => null,
          );

      if (wsFile == null) {
        state = state.copyWith(
          error: 'Plik XLSX nie zawiera arkuszy danych.'.tr,
        );
        return;
      }

      final wsXml = XmlDocument.parse(
        utf8.decode(wsFile.content as List<int>, allowMalformed: true),
      );
      final xmlRows = wsXml.findAllElements('row').toList();

      if (xmlRows.isEmpty) {
        state = state.copyWith(error: 'Arkusz XLSX jest pusty.'.tr);
        return;
      }

      final parsedRows = <List<String>>[];
      int maxCols = 0;

      for (final row in xmlRows) {
        final cellMap = <int, String>{};
        for (final cell in row.findElements('c')) {
          final ref = cell.getAttribute('r') ?? '';
          final colIdx = _xlColIndex(ref);
          final cellType = cell.getAttribute('t') ?? '';

          String value = '';
          if (cellType == 's') {
            final vEls = cell.findElements('v').toList();
            if (vEls.isNotEmpty) {
              final idx = int.tryParse(vEls.first.innerText) ?? -1;
              if (idx >= 0 && idx < sharedStrings.length) {
                value = sharedStrings[idx];
              }
            }
          } else if (cellType == 'inlineStr') {
            final isEls = cell.findElements('is').toList();
            if (isEls.isNotEmpty) {
              final tEls = isEls.first.findElements('t').toList();
              if (tEls.isNotEmpty) value = tEls.first.innerText;
            }
          } else {
            final vEls = cell.findElements('v').toList();
            if (vEls.isNotEmpty) value = vEls.first.innerText;
          }

          cellMap[colIdx] = value;
          if (colIdx + 1 > maxCols) maxCols = colIdx + 1;
        }

        parsedRows.add(
          List.generate(maxCols, (i) => cellMap[i] ?? ''),
        );
      }

      if (parsedRows.isEmpty) {
        state = state.copyWith(error: 'Arkusz XLSX jest pusty.'.tr);
        return;
      }

      // Normalise row lengths
      for (int i = 0; i < parsedRows.length; i++) {
        if (parsedRows[i].length < maxCols) {
          parsedRows[i] = [
            ...parsedRows[i],
            ...List.filled(maxCols - parsedRows[i].length, ''),
          ];
        }
      }

      final columns = parsedRows.first;
      final dataRows = parsedRows
          .skip(1)
          .where((r) => r.any((c) => c.isNotEmpty))
          .toList();

      _applyParsedData(columns, dataRows);
    } catch (e) {
      state = state.copyWith(
        error: 'Błąd parsowania XLSX: $e'.tr,
      );
    }
  }

  /// Converts an Excel cell reference (e.g. "AB3") to a 0-based column index.
  int _xlColIndex(String cellRef) {
    int col = 0;
    for (int i = 0; i < cellRef.length; i++) {
      final c = cellRef.codeUnitAt(i);
      if (c < 65 || c > 90) break; // stop at first non-letter (A–Z)
      col = col * 26 + (c - 64);
    }
    return col - 1;
  }

  void _parseXml(Uint8List bytes) {
    try {
      final content = _decodeFileBytes(bytes);
      final document = XmlDocument.parse(content);
      final root = document.rootElement;
      final children = root.childElements.toList();

      if (children.isEmpty) {
        state = state.copyWith(
          error: 'XML nie zawiera elementów danych.'.tr,
        );
        return;
      }

      final firstChild = children.first;
      final hasChildElements = firstChild.childElements.isNotEmpty;
      List<String> columns;
      List<List<String>> rows;

      if (hasChildElements) {
        final colSet = <String>[];
        for (final child in children) {
          for (final sub in child.childElements) {
            final name = sub.name.local;
            if (!colSet.contains(name)) colSet.add(name);
          }
        }
        columns = colSet;
        rows = children.map((el) {
          return columns.map((col) {
            final matches = el.findElements(col).toList();
            return matches.isNotEmpty ? matches.first.innerText.trim() : '';
          }).toList();
        }).toList();
      } else {
        // Flat attributes: <record col1="val1" col2="val2"/>
        columns = firstChild.attributes.map((a) => a.name.local).toList();
        rows = children.map((el) {
          return columns.map((col) => el.getAttribute(col) ?? '').toList();
        }).toList();
      }

      if (columns.isEmpty) {
        state = state.copyWith(
          error: 'Nie udało się wykryć kolumn w pliku XML.'.tr,
        );
        return;
      }

      _applyParsedData(columns, rows);
    } catch (e) {
      state = state.copyWith(
        error: 'Błąd parsowania XML: $e'.tr,
      );
    }
  }

  void _recomputePreviewWithTransforms() {
    var cols = List<String>.from(state.originalColumns);
    var rows = state.originalData
        .map((r) => List<String>.from(r))
        .toList(growable: true);

    if (cols.isEmpty) {
      state = state.copyWith(
        previewColumns: cols,
        previewData: rows,
        selectedRowIndexes: [],
        error: null,
      );
      return;
    }

    for (final rule in state.transforms) {
      final isConstant = rule.transform == TransformType.constant;
      final srcIdx = cols.indexOf(rule.sourceColumn);

      if (srcIdx == -1 && !isConstant) continue;

      var outIdx = cols.indexOf(rule.outputColumn);
      if (outIdx == -1) {
        cols.add(rule.outputColumn);
        outIdx = cols.length - 1;

        for (final r in rows) {
          while (r.length < cols.length) {
            r.add('');
          }
        }
      }

      for (final r in rows) {
        final val = isConstant
            ? ''
            : (srcIdx >= 0 && srcIdx < r.length ? r[srcIdx] : '');

        final transformed = applyTransformRuleValue(rule, val);

        if (outIdx >= r.length) {
          r.addAll(List.filled(outIdx + 1 - r.length, ''));
        }

        final existing = r[outIdx];

        if (rule.skipIfNoMatch && existing.isNotEmpty && transformed.isEmpty) {
          continue;
        }

        r[outIdx] = transformed;
      }
    }

    final cleanedSelection = state.selectedRowIndexes
        .where((i) => i >= 0 && i < rows.length)
        .toSet()
        .toList()
      ..sort();

    state = state.copyWith(
      previewColumns: cols,
      previewData: rows,
      selectedRowIndexes: cleanedSelection,
      error: null,
    );

    _resetPagination();
  }

  void setTargetModel(String? model) {
    final previous = state.selectedTargetModel;
    final next = model?.trim().isEmpty == true ? null : model;

    state = state.copyWith(
      selectedTargetModel: next,
      clearSelectedTargetModel: next == null,
      clearEmmaEntityPlan: previous != next,
      error: null,
    );
  }

  void setSaveTemplate(bool value) {
    state = state.copyWith(saveTemplate: value, error: null);
  }

  void setTemplateName(String value) {
    state = state.copyWith(templateName: value, error: null);
  }

  void setProgress(double value) {
    state = state.copyWith(uploadProgress: value);
  }

  List<ColumnTransformRule> getTransformsForSource(String columnName) {
    return state.transforms
        .where((t) => t.sourceColumn == columnName)
        .toList(growable: false);
  }

  void removeTransformsForSource(String columnName) {
    final updated = state.transforms
        .where((t) => t.sourceColumn != columnName)
        .toList(growable: false);

    state = state.copyWith(
      transforms: updated,
      clearEmmaEntityPlan: true,
      error: null,
    );
    _recomputePreviewWithTransforms();
  }

  void addTransformRule(ColumnTransformRule rule) {
    final updated = [...state.transforms, rule];

    state = state.copyWith(
      transforms: updated,
      clearEmmaEntityPlan: true,
      error: null,
    );
    _recomputePreviewWithTransforms();
  }

  FieldMappingRule? getFieldMappingForColumn(String columnName) {
    for (final m in state.fieldMappings) {
      if (m.columnName == columnName) return m;
    }

    return null;
  }

  void upsertFieldMappingForColumn(
    String columnName, {
    required String? targetModel,
    required String? targetField,
  }) {
    if (targetModel == null ||
        targetModel.isEmpty ||
        targetField == null ||
        targetField.isEmpty) {
      final updated = state.fieldMappings
          .where((m) => m.columnName != columnName)
          .toList(growable: false);

      state = state.copyWith(fieldMappings: updated, error: null);
      return;
    }

    final List<FieldMappingRule> updated = [];
    var found = false;

    for (final m in state.fieldMappings) {
      if (m.columnName == columnName) {
        updated.add(
          m.copyWith(
            targetModel: targetModel,
            targetField: targetField,
          ),
        );
        found = true;
      } else {
        updated.add(m);
      }
    }

    if (!found) {
      updated.add(
        FieldMappingRule(
          id: 'map_${DateTime.now().microsecondsSinceEpoch}',
          columnName: columnName,
          targetModel: targetModel,
          targetField: targetField,
        ),
      );
    }

    state = state.copyWith(fieldMappings: updated, error: null);
  }

  /// Legacy mapping builder.
  Map<String, Map<String, dynamic>> buildFieldMappingsPerModel() {
    final Map<String, Map<String, dynamic>> result = {};

    for (final mapping in state.fieldMappings) {
      if (mapping.targetModel.isEmpty || mapping.targetField.isEmpty) continue;

      ColumnTransformRule? rule;
      for (final t in state.transforms) {
        if (t.outputColumn == mapping.columnName) {
          rule = t;
        }
      }

      final spec = <String, dynamic>{
        'transform': (rule?.transform ?? TransformType.raw).backendName,
      };

      if (rule == null || rule.transform != TransformType.constant) {
        spec['source'] = rule?.sourceColumn ?? mapping.columnName;
      }

      final Map<String, dynamic> args = {};

      if (rule != null) {
        switch (rule.transform) {
          case TransformType.raw:
            break;
          case TransformType.split:
            if (rule.separator != null && rule.separator!.isNotEmpty) {
              args['separator'] = rule.separator;
            }
            if (rule.splitIndex != null) {
              args['index'] = rule.splitIndex;
            }
            if (rule.takeRemainder) {
              args['take_remainder'] = true;
            }
            break;
          case TransformType.regex:
            if (rule.regexPattern != null && rule.regexPattern!.isNotEmpty) {
              args['pattern'] = rule.regexPattern;
            }
            if (rule.regexGroup != null) {
              args['group'] = rule.regexGroup;
            }
            break;
          case TransformType.constant:
            args['value'] = rule.constValue ?? '';
            break;
        }
      }

      if (args.isNotEmpty) {
        spec['args'] = args;
      }

      final modelMap = result.putIfAbsent(
        mapping.targetModel,
        () => <String, dynamic>{},
      );

      modelMap[mapping.targetField] = spec;
    }

    return result;
  }

  /// Direct batch mapping builder.
  ///
  /// Frontend already applied transformations into previewData.
  Map<String, Map<String, dynamic>> buildDirectFieldMappingsPerModel() {
    final Map<String, Map<String, dynamic>> result = {};

    for (final mapping in state.fieldMappings) {
      if (mapping.targetModel.isEmpty || mapping.targetField.isEmpty) continue;
      if (mapping.columnName.isEmpty) continue;
      if (!state.previewColumns.contains(mapping.columnName)) continue;

      final modelMap = result.putIfAbsent(
        mapping.targetModel,
        () => <String, dynamic>{},
      );

      modelMap[mapping.targetField] = {
        'source': mapping.columnName,
        'transform': 'raw',
      };
    }

    return result;
  }

  /// =======================
  /// EMMA DATASET PROFILE
  /// =======================

  Map<String, dynamic> buildEmmaDatasetProfile({
    int maxRows = 30,
    int maxSamplesPerColumn = 12,
    bool selectedRowsOnly = false,
  }) {
    final columns = List<String>.from(state.previewColumns);
    final allRows = state.previewData;

    final selectedSet = state.selectedRowIndexes.toSet();

    final sourceRowIndexes = <int>[];
    for (var i = 0; i < allRows.length; i++) {
      if (selectedRowsOnly && !selectedSet.contains(i)) continue;
      sourceRowIndexes.add(i);
    }

    final sampleRowIndexes = sourceRowIndexes.take(maxRows).toList();

    final sampleRows = sampleRowIndexes.map((rowIndex) {
      final row = allRows[rowIndex];

      final map = <String, dynamic>{
        '_row_index': rowIndex + 1,
      };

      for (var i = 0; i < columns.length; i++) {
        final column = columns[i];
        map[column] = i < row.length ? row[i] : '';
      }

      return map;
    }).toList(growable: false);

    final columnSamples = <String, List<String>>{};
    final columnStats = <String, Map<String, dynamic>>{};

    for (final column in columns) {
      final colIndex = columns.indexOf(column);
      final samples = <String>[];

      var emptyCount = 0;
      var emailCount = 0;
      var phoneCount = 0;
      var nipCount = 0;
      var regonCount = 0;
      var postalCodeCount = 0;
      var amountCount = 0;
      var dateCount = 0;
      var personNameLikeCount = 0;
      var companyNameLikeCount = 0;

      final uniqueValues = <String>{};

      for (final rowIndex in sourceRowIndexes) {
        if (rowIndex < 0 || rowIndex >= allRows.length) continue;

        final row = allRows[rowIndex];
        final value = colIndex < row.length ? row[colIndex].trim() : '';

        if (value.isEmpty) {
          emptyCount += 1;
          continue;
        }

        uniqueValues.add(value);

        if (samples.length < maxSamplesPerColumn && !samples.contains(value)) {
          samples.add(value);
        }

        if (_emmaEmailRegex.hasMatch(value)) emailCount += 1;
        if (_emmaLooksLikePhone(value)) phoneCount += 1;
        if (_emmaNipRegex.hasMatch(value)) nipCount += 1;
        if (_emmaRegonRegex.hasMatch(value)) regonCount += 1;
        if (_emmaLooksLikePostalCode(value)) postalCodeCount += 1;
        if (_emmaLooksLikeAmount(value)) amountCount += 1;
        if (_emmaLooksLikeDate(value)) dateCount += 1;
        if (_emmaLooksLikePersonName(value)) personNameLikeCount += 1;
        if (_emmaLooksLikeCompanyName(value)) companyNameLikeCount += 1;
      }

      columnSamples[column] = samples;

      columnStats[column] = {
        'row_count': sourceRowIndexes.length,
        'sample_count': samples.length,
        'empty_count': emptyCount,
        'unique_count': uniqueValues.length,
        'email_count': emailCount,
        'phone_count': phoneCount,
        'nip_count': nipCount,
        'regon_count': regonCount,
        'postal_code_count': postalCodeCount,
        'amount_count': amountCount,
        'date_count': dateCount,
        'person_name_like_count': personNameLikeCount,
        'company_name_like_count': companyNameLikeCount,
        'samples': samples,
      };
    }

    return {
      'source': 'budkon_flutter_importer',
      'version': 2,
      'selected_target_model': state.selectedTargetModel,
      'columns': columns,
      'row_count': allRows.length,
      'selected_row_count': state.selectedRowIndexes.length,
      'selected_rows_only': selectedRowsOnly,
      'sample_rows': sampleRows,
      'column_samples': columnSamples,
      'column_stats': columnStats,
      'current_mappings': state.fieldMappings.map((m) {
        return {
          'column_name': m.columnName,
          'target_model': m.targetModel,
          'target_field': m.targetField,
        };
      }).toList(),
      'current_transforms': state.transforms.map((t) {
        return {
          'id': t.id,
          'source_column': t.sourceColumn,
          'output_column': t.outputColumn,
          'transform': t.transform.backendName,
          'separator': t.separator,
          'split_index': t.splitIndex,
          'take_remainder': t.takeRemainder,
          'regex_pattern': t.regexPattern,
          'regex_group': t.regexGroup,
          'regex_strip_source_value': t.regexStripSourceValue,
          'regex_strip_source_key': t.regexStripSourceKey,
          'regex_strip_leading_separator': t.regexStripLeadingSeparator,
          'regex_strip_trailing_separator': t.regexStripTrailingSeparator,
          'regex_normalize_digits': t.regexNormalizeDigits,
          'skip_if_no_match': t.skipIfNoMatch,
          'const_value': t.constValue,
        };
      }).toList(),
      'current_entity_plan': state.emmaEntityPlan,
    };
  }

  Future<Map<String, dynamic>> applyEmmaTransformRules(
    List<dynamic> rawRules, {
    bool clearExisting = false,
    bool replaceSameOutputColumn = true,
  }) async {
    if (rawRules.isEmpty) {
      return {
        'ok': false,
        'message': 'No transform rules provided.',
        'applied_count': 0,
        'skipped_count': 0,
      };
    }

    final existingColumns = state.previewColumns.toSet();
    final parsedRules = <ColumnTransformRule>[];
    final skipped = <Map<String, dynamic>>[];

    for (var i = 0; i < rawRules.length; i++) {
      final raw = rawRules[i];

      if (raw is! Map) {
        skipped.add({
          'index': i,
          'reason': 'Rule is not an object.',
        });
        continue;
      }

      final map = Map<String, dynamic>.from(raw);

      final sourceColumn = _emmaString(
        map['source_column'] ??
            map['sourceColumn'] ??
            map['source'] ??
            map['column'],
      );

      final outputColumn = _emmaString(
        map['output_column'] ??
            map['outputColumn'] ??
            map['target_column'] ??
            map['targetColumn'],
      );

      final transformRaw = _emmaString(
        map['transform'] ??
            map['type'] ??
            map['transform_type'] ??
            map['transformType'],
      );

      final transform = _emmaParseTransformType(transformRaw);

      if (outputColumn.isEmpty) {
        skipped.add({
          'index': i,
          'reason': 'Missing output_column.',
          'rule': map,
        });
        continue;
      }

      if (sourceColumn.isEmpty && transform != TransformType.constant) {
        skipped.add({
          'index': i,
          'reason': 'Missing source_column.',
          'rule': map,
        });
        continue;
      }

      if (sourceColumn.isNotEmpty &&
          !existingColumns.contains(sourceColumn) &&
          transform != TransformType.constant) {
        skipped.add({
          'index': i,
          'reason': 'Source column does not exist: $sourceColumn',
          'rule': map,
        });
        continue;
      }

      final id = _emmaString(map['id']).isNotEmpty
          ? _emmaString(map['id'])
          : 'emma_transform_${DateTime.now().microsecondsSinceEpoch}_$i';

      parsedRules.add(
        ColumnTransformRule(
          id: id,
          sourceColumn: sourceColumn.isNotEmpty
              ? sourceColumn
              : (state.previewColumns.isNotEmpty
                  ? state.previewColumns.first
                  : outputColumn),
          outputColumn: outputColumn,
          transform: transform,
          separator: _emmaNullableString(map['separator']),
          splitIndex: _emmaNullableInt(
            map['split_index'] ?? map['splitIndex'] ?? map['index'],
          ),
          takeRemainder: _emmaBool(
            map['take_remainder'] ?? map['takeRemainder'],
            fallback: false,
          ),
          regexPattern: _emmaNullableString(
            map['regex_pattern'] ?? map['regexPattern'] ?? map['pattern'],
          ),
          regexGroup: _emmaNullableInt(
            map['regex_group'] ?? map['regexGroup'] ?? map['group'],
          ),
          regexStripSourceValue: _emmaBool(
            map['regex_strip_source_value'] ?? map['regexStripSourceValue'],
            fallback: false,
          ),
          regexStripSourceKey: _emmaBool(
            map['regex_strip_source_key'] ?? map['regexStripSourceKey'],
            fallback: false,
          ),
          regexStripLeadingSeparator: _emmaBool(
            map['regex_strip_leading_separator'] ??
                map['regexStripLeadingSeparator'],
            fallback: false,
          ),
          regexStripTrailingSeparator: _emmaBool(
            map['regex_strip_trailing_separator'] ??
                map['regexStripTrailingSeparator'],
            fallback: false,
          ),
          regexNormalizeDigits: _emmaBool(
            map['regex_normalize_digits'] ??
                map['regexNormalizeDigits'] ??
                map['normalize_digits'] ??
                map['normalizeDigits'],
            fallback: false,
          ),
          skipIfNoMatch: _emmaBool(
            map['skip_if_no_match'] ?? map['skipIfNoMatch'],
            fallback: false,
          ),
          constValue: _emmaNullableString(
            map['const_value'] ?? map['constValue'] ?? map['value'],
          ),
        ),
      );
    }

    if (parsedRules.isEmpty) {
      return {
        'ok': false,
        'message': 'No valid transform rules to apply.',
        'applied_count': 0,
        'skipped_count': skipped.length,
        'skipped': skipped,
      };
    }

    var updatedTransforms = <ColumnTransformRule>[];

    if (!clearExisting) {
      updatedTransforms = List<ColumnTransformRule>.from(state.transforms);
    }

    if (replaceSameOutputColumn) {
      final outputColumns = parsedRules.map((r) => r.outputColumn).toSet();
      updatedTransforms = updatedTransforms
          .where((t) => !outputColumns.contains(t.outputColumn))
          .toList(growable: true);
    }

    updatedTransforms.addAll(parsedRules);

    state = state.copyWith(
      transforms: updatedTransforms,
      clearEmmaEntityPlan: true,
      error: null,
      clearLastMessage: true,
    );

    _recomputePreviewWithTransforms();

    state = state.copyWith(
      lastMessage:
          'Emma zastosowała ${parsedRules.length} reguł podziału danych.'.tr,
      error: null,
    );

    return {
      'ok': true,
      'message': 'Transform rules applied.',
      'applied_count': parsedRules.length,
      'skipped_count': skipped.length,
      'skipped': skipped,
      'created_columns': parsedRules.map((r) => r.outputColumn).toList(),
      'dataset_profile': buildEmmaDatasetProfile(
        maxRows: 10,
        maxSamplesPerColumn: 5,
      ),
    };
  }

  /// =======================
  /// LEGACY IMPORT FLOW
  /// =======================

  Future<void> submit(WidgetRef ref) async {
    if (state.file == null) {
      state = state.copyWith(error: 'Wybierz plik do importu'.tr);
      return;
    }

    if (state.fieldMappings.isEmpty) {
      state = state.copyWith(
        error:
            'Dodaj przynajmniej jedną regułę mapowania kolumny na pole docelowe.'
                .tr,
      );
      return;
    }

    final perModel = buildFieldMappingsPerModel();
    if (perModel.isEmpty) {
      state = state.copyWith(
        error:
            'Brak poprawnych mapowań. Upewnij się, że wybrałeś model i pole docelowe.'
                .tr,
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      error: null,
      clearLastMessage: true,
      uploadProgress: 0,
    );

    try {
      final file = state.file!;
      final bytes = file.bytes;

      if (bytes == null) {
        state = state.copyWith(
          isSubmitting: false,
          error:
              'Brak danych pliku (bytes == null). Upewnij się, że pickFiles używa withData: true.'
                  .tr,
        );
        return;
      }

      final totalModels = perModel.length;
      var processedModels = 0;

      String? lastJobId;
      final msgBuffer = StringBuffer();

      for (final entry in perModel.entries) {
        final modelName = entry.key;
        final fieldMappings = entry.value;

        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: file.name,
          ),
          'target_model': modelName,
          'field_mappings': jsonEncode(fieldMappings),
          'batch_size': 100,
          'save_template': state.saveTemplate.toString(),
          if (state.saveTemplate && state.templateName.trim().isNotEmpty)
            'template_name': state.templateName.trim(),
        });

        final res = await ApiServices.post(
          ImportApiUrls.legacyImport,
          hasToken: true,
          formData: formData,
          ref: ref,
          onSendProgress: (sent, total) {
            if (total != 0) {
              final localProgress = sent / total;
              final globalProgress =
                  (processedModels + localProgress) / totalModels;
              setProgress(globalProgress);
            }
          },
        );

        if (res == null) {
          state = state.copyWith(
            isSubmitting: false,
            error:
                'Brak odpowiedzi z serwera przy imporcie modelu $modelName.'
                    .tr,
          );
          return;
        }

        final body = _asStringMap(decodeResponseData(res));

        if (res.statusCode == 200 || res.statusCode == 201) {
          final jobId = body['import_job_id']?.toString();
          final msg = body['message']?.toString() ??
              'Import dla modelu $modelName zakończony pomyślnie.'.tr;

          lastJobId = jobId;
          msgBuffer.writeln(msg);
        } else {
          final err = body['error']?.toString() ??
              'Błąd importu dla modelu $modelName (status: ${res.statusCode})'
                  .tr;

          state = state.copyWith(
            isSubmitting: false,
            error: err,
          );
          return;
        }

        processedModels += 1;
      }

      state = state.copyWith(
        isSubmitting: false,
        lastMessage: msgBuffer.toString().trim().isEmpty
            ? 'Import zakończony pomyślnie dla $totalModels modeli.'.tr
            : msgBuffer.toString(),
        lastJobId: lastJobId,
        uploadProgress: 1.0,
        error: null,
      );

      ref.invalidate(importJobsProvider);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Wyjątek podczas importu: $e'.tr,
      );
    }
  }

  /// =======================
  /// DIRECT BATCH IMPORT
  /// =======================

  List<_PreparedImportRow> _buildSelectedRowsFromPreview() {
    final cols = state.previewColumns;
    final data = state.previewData;
    final rows = <_PreparedImportRow>[];

    for (final rowIndex in state.selectedRowIndexes) {
      if (rowIndex < 0 || rowIndex >= data.length) continue;

      final row = data[rowIndex];
      final map = <String, dynamic>{};

      for (var i = 0; i < cols.length; i++) {
        final key = cols[i];
        final value = i < row.length ? row[i] : '';
        map[key] = value;
      }

      rows.add(
        _PreparedImportRow(
          previewRowIndex: rowIndex,
          data: map,
        ),
      );
    }

    return rows;
  }

  List<BatchImportResult> _mergeBatchResultIntoList(
    List<BatchImportResult> current,
    BatchImportResult incoming,
  ) {
    final updated = <BatchImportResult>[];
    var merged = false;

    for (final item in current) {
      if (item.targetModel == incoming.targetModel) {
        updated.add(item.mergeWith(incoming));
        merged = true;
      } else {
        updated.add(item);
      }
    }

    if (!merged) {
      updated.add(incoming);
    }

    return updated;
  }

  Future<void> submitBatch(WidgetRef ref) async {
    if (state.previewColumns.isEmpty || state.previewData.isEmpty) {
      state = state.copyWith(
        batchResults: [],
        isBatchRunning: false,
        isSubmitting: false,
        batchProgress: 0.0,
        batchStatusText:
            'Brak danych do wysłania. Upewnij się, że plik został wczytany.'
                .tr,
        error: 'Brak danych do wysłania.'.tr,
      );
      return;
    }

    final hasEntityPlan = _hasValidEntityPlan(state.emmaEntityPlan);

    if (state.fieldMappings.isEmpty && !hasEntityPlan) {
      state = state.copyWith(
        batchResults: [],
        isBatchRunning: false,
        isSubmitting: false,
        batchProgress: 0.0,
        batchStatusText:
            'Dodaj przynajmniej jedną regułę mapowania przed importem.'.tr,
        error: 'Brak mapowań do importu.'.tr,
      );
      return;
    }

    if (state.selectedRowIndexes.isEmpty) {
      state = state.copyWith(
        batchResults: [],
        isBatchRunning: false,
        isSubmitting: false,
        batchProgress: 0.0,
        batchStatusText: 'Nie zaznaczono żadnych wierszy do importu.'.tr,
        error: 'Zaznacz przynajmniej jeden wiersz do importu.'.tr,
      );
      return;
    }

    final perModel = buildDirectFieldMappingsPerModel();
    if (perModel.isEmpty && !hasEntityPlan) {
      state = state.copyWith(
        batchResults: [],
        isBatchRunning: false,
        isSubmitting: false,
        batchProgress: 0.0,
        batchStatusText:
            'Brak poprawnych mapowań. Upewnij się, że wybrałeś model i pole docelowe.'
                .tr,
        error: 'Brak poprawnych mapowań.'.tr,
      );
      return;
    }

    final preparedRows = _buildSelectedRowsFromPreview();
    final totalRows = preparedRows.length;

    if (totalRows == 0) {
      state = state.copyWith(
        batchResults: [],
        isBatchRunning: false,
        isSubmitting: false,
        batchProgress: 0.0,
        batchStatusText: 'Brak zaznaczonych wierszy do importu.'.tr,
        error: 'Brak zaznaczonych wierszy do importu.'.tr,
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      isBatchRunning: true,
      batchProgress: 0.0,
      batchStatusText: hasEntityPlan
          ? 'Start importu relacyjnego...'.tr
          : 'Start importu...'.tr,
      batchResults: [],
      error: null,
      clearLastMessage: true,
      clearLastJobId: true,
    );

    const int chunkSize = 50;

    int processedInputRows = 0;
    int okOperations = 0;
    int errorOperations = 0;
    List<BatchImportResult> allResults = [];

    try {
      for (int start = 0; start < totalRows; start += chunkSize) {
        final end = (start + chunkSize > totalRows)
            ? totalRows
            : (start + chunkSize);

        final chunkPrepared = preparedRows.sublist(start, end);
        final chunkRows =
            chunkPrepared.map((e) => e.data).toList(growable: false);
        final chunkPreviewIndexes =
            chunkPrepared.map((e) => e.previewRowIndex).toList(growable: false);

        final chunkNumber = (start ~/ chunkSize) + 1;
        final chunkCount = ((totalRows - 1) ~/ chunkSize) + 1;

        state = state.copyWith(
          batchProgress: processedInputRows / totalRows,
          batchStatusText: hasEntityPlan
              ? 'Wysyłanie relacyjnej paczki $chunkNumber/$chunkCount (wiersze ${start + 1}–$end z $totalRows)...'
                  .tr
              : 'Wysyłanie paczki $chunkNumber/$chunkCount (wiersze ${start + 1}–$end z $totalRows)...'
                  .tr,
        );

        final Map<String, dynamic> payload;

        if (hasEntityPlan) {
          payload = {
            'mode': 'entity_plan',
            'entity_plan': state.emmaEntityPlan,
            'rows': chunkRows,
            'preview_row_indexes':
                chunkPreviewIndexes.map((i) => i + 1).toList(growable: false),
            'target_model': state.selectedTargetModel,
          };
        } else {
          final List<Map<String, dynamic>> batches = [];

          perModel.forEach((modelName, fieldMappings) {
            batches.add({
              'target_model': modelName,
              'field_mappings': fieldMappings,
              'rows': chunkRows,
            });
          });

          payload = {
            'batches': batches,
          };
        }

        final res = await ApiServices.post(
          ImportApiUrls.batchSend,
          hasToken: true,
          data: payload,
          ref: ref,
        );

        if (res == null) {
          state = state.copyWith(
            isSubmitting: false,
            isBatchRunning: false,
            batchProgress: processedInputRows / totalRows,
            batchStatusText:
                'Brak odpowiedzi z serwera przy paczce $chunkNumber.'.tr,
            error: 'Brak odpowiedzi z serwera.'.tr,
          );
          return;
        }

        final body = _asStringMap(decodeResponseData(res));

        if (res.statusCode != 200 && res.statusCode != 201) {
          final err = body['error']?.toString() ??
              'Błąd importu (status: ${res.statusCode}) w paczce $chunkNumber.'
                  .tr;

          state = state.copyWith(
            isSubmitting: false,
            isBatchRunning: false,
            batchProgress: processedInputRows / totalRows,
            batchStatusText: err,
            error: err,
          );
          return;
        }

        final chunkResults = _extractBatchResultsFromBody(body);

        for (final r in chunkResults) {
          okOperations += r.successfulRows;
          errorOperations += r.failedRows;

          final adjustedErrors = r.errors.map((err) {
            final localIndex = err.row - 1;
            final previewRowIndex =
                (localIndex >= 0 && localIndex < chunkPreviewIndexes.length)
                    ? chunkPreviewIndexes[localIndex]
                    : -1;

            return RowImportError(
              row: previewRowIndex >= 0 ? previewRowIndex + 1 : err.row,
              error: err.error,
            );
          }).toList();

          final adjustedResult = r.copyWith(errors: adjustedErrors);
          allResults = _mergeBatchResultIntoList(allResults, adjustedResult);
        }

        if (chunkResults.isEmpty) {
          final successfulRows = _emmaInt(
            body['successful_rows'] ?? body['created_count'] ?? body['ok_count'],
          );
          final failedRows = _emmaInt(
            body['failed_rows'] ?? body['error_count'],
          );

          okOperations += successfulRows;
          errorOperations += failedRows;
        }

        processedInputRows = end;

        state = state.copyWith(
          batchProgress: (processedInputRows / totalRows).clamp(0.0, 1.0),
          batchStatusText:
              'Przetworzono $processedInputRows / $totalRows wierszy (operacje OK: $okOperations, błędy: $errorOperations)...'
                  .tr,
          batchResults: List<BatchImportResult>.from(allResults),
        );
      }

      state = state.copyWith(
        isSubmitting: false,
        isBatchRunning: false,
        batchProgress: 1.0,
        batchStatusText:
            'Import zakończony. Wiersze: $totalRows/$totalRows • operacje OK: $okOperations • błędy: $errorOperations.'
                .tr,
        batchResults: List<BatchImportResult>.from(allResults),
        lastMessage:
            'Import zakończony. Wysłane rekordy: $totalRows • operacje OK: $okOperations • błędy: $errorOperations.'
                .tr,
        error: null,
      );

      ref.invalidate(importJobsProvider);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isBatchRunning: false,
        batchProgress: totalRows == 0
            ? 0.0
            : (processedInputRows / totalRows).clamp(0.0, 1.0),
        batchStatusText: 'Wyjątek podczas importu: $e',
        error: 'Wyjątek podczas importu: $e',
      );
    }
  }

  Future<void> resendFailedForModel(WidgetRef ref, String targetModel) async {
    final perModel = buildDirectFieldMappingsPerModel();
    final mapping = perModel[targetModel];

    if (mapping == null) {
      state = state.copyWith(
        batchStatusText:
            'Brak mapowań dla modelu $targetModel – nie można ponowić wysyłki.'
                .tr,
      );
      return;
    }

    final existingResults =
        state.batchResults.where((r) => r.targetModel == targetModel).toList();

    if (existingResults.isEmpty) {
      state = state.copyWith(
        batchStatusText:
            'Brak poprzednich wyników importu dla modelu $targetModel.'.tr,
      );
      return;
    }

    final result = existingResults.first;

    if (result.errors.isEmpty) {
      state = state.copyWith(
        batchStatusText:
            'Brak błędnych wierszy do ponownej wysyłki dla modelu $targetModel.'
                .tr,
      );
      return;
    }

    final cols = state.previewColumns;
    final data = state.previewData;

    final rowsToResend = <Map<String, dynamic>>[];
    final resendPreviewIndexes = <int>[];

    for (final err in result.errors) {
      final idx = err.row - 1;
      if (idx < 0 || idx >= data.length) continue;

      final row = data[idx];
      final map = <String, dynamic>{};

      for (var i = 0; i < cols.length; i++) {
        final key = cols[i];
        final value = i < row.length ? row[i] : '';
        map[key] = value;
      }

      rowsToResend.add(map);
      resendPreviewIndexes.add(idx);
    }

    if (rowsToResend.isEmpty) {
      state = state.copyWith(
        batchStatusText:
            'Nie udało się zbudować wierszy do ponownej wysyłki dla modelu $targetModel.'
                .tr,
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      isBatchRunning: true,
      batchProgress: 0.2,
      batchStatusText:
          'Ponowne wysyłanie błędnych wierszy dla modelu $targetModel...'.tr,
      error: null,
    );

    try {
      final payload = {
        'batches': [
          {
            'target_model': targetModel,
            'field_mappings': mapping,
            'rows': rowsToResend,
          }
        ],
      };

      final res = await ApiServices.post(
        ImportApiUrls.batchSend,
        hasToken: true,
        data: payload,
        ref: ref,
      );

      if (res == null) {
        state = state.copyWith(
          isSubmitting: false,
          isBatchRunning: false,
          batchProgress: 0.0,
          batchStatusText:
              'Brak odpowiedzi z serwera przy ponownej wysyłce dla $targetModel.'
                  .tr,
          error: 'Brak odpowiedzi z serwera.'.tr,
        );
        return;
      }

      final body = _asStringMap(decodeResponseData(res));

      if (res.statusCode != 200 && res.statusCode != 201) {
        final err = body['error']?.toString() ??
            'Błąd ponownej wysyłki (status: ${res.statusCode})'.tr;

        state = state.copyWith(
          isSubmitting: false,
          isBatchRunning: false,
          batchProgress: 0.0,
          batchStatusText: err,
          error: err,
        );
        return;
      }

      final newResultList = _extractBatchResultsFromBody(body);

      BatchImportResult? newResult;
      if (newResultList.isNotEmpty) {
        newResult = newResultList.firstWhere(
          (r) => r.targetModel == targetModel,
          orElse: () => newResultList.first,
        );

        final adjustedErrors = newResult.errors.map((err) {
          final localIndex = err.row - 1;
          final previewRowIndex =
              (localIndex >= 0 && localIndex < resendPreviewIndexes.length)
                  ? resendPreviewIndexes[localIndex]
                  : -1;

          return RowImportError(
            row: previewRowIndex >= 0 ? previewRowIndex + 1 : err.row,
            error: err.error,
          );
        }).toList();

        newResult = newResult.copyWith(errors: adjustedErrors);
      }

      final updatedBatchResults = <BatchImportResult>[];

      for (final r in state.batchResults) {
        if (r.targetModel == targetModel && newResult != null) {
          updatedBatchResults.add(newResult);
        } else {
          updatedBatchResults.add(r);
        }
      }

      state = state.copyWith(
        isSubmitting: false,
        isBatchRunning: false,
        batchProgress: 1.0,
        batchStatusText:
            'Ponowna wysyłka błędnych wierszy dla modelu $targetModel zakończona.'
                .tr,
        batchResults: updatedBatchResults,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isBatchRunning: false,
        batchProgress: 0.0,
        batchStatusText: 'Wyjątek podczas ponownej wysyłki: $e',
        error: 'Wyjątek podczas ponownej wysyłki: $e',
      );
    }
  }
}

final importFormProvider =
    StateNotifierProvider<ImportFormNotifier, ImportFormState>(
  (ref) => ImportFormNotifier(),
);

/// =======================
/// EMMA IMPORTER HELPERS
/// =======================

final RegExp _emmaEmailRegex = RegExp(
  r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  caseSensitive: false,
);

final RegExp _emmaPhoneRegex = RegExp(
  r'(\+?\d[\d\s().\-]{6,}\d)',
);

final RegExp _emmaNipRegex = RegExp(
  r'(?:NIP[:\s]*)?(\d{3}[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2})',
  caseSensitive: false,
);

final RegExp _emmaRegonRegex = RegExp(
  r'(?:REGON[:\s]*)?(\d{9}|\d{14})',
  caseSensitive: false,
);

final RegExp _emmaPostalCodeRegex = RegExp(
  r'^\s*\d{2}[\-\s]?\d{3}\s*$',
);

final RegExp _emmaAmountRegex = RegExp(
  r'^\s*-?(?:\d{1,3}(?:[\s\u00A0]?\d{3})+|\d+)(?:[,.]\d{1,2})?\s*(?:zł|pln|eur|usd)?\s*$',
  caseSensitive: false,
);

final RegExp _emmaDateRegex = RegExp(
  r'^\s*(\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})\s*$',
);

String _emmaString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _emmaNullableString(dynamic value) {
  final text = _emmaString(value);
  return text.isEmpty ? null : text;
}

int? _emmaNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int _emmaInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

bool _emmaBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;

  final text = value.toString().trim().toLowerCase();

  if (['true', '1', 'yes', 'y', 'tak', 'on'].contains(text)) return true;
  if (['false', '0', 'no', 'n', 'nie', 'off'].contains(text)) return false;

  return fallback;
}

TransformType _emmaParseTransformType(String value) {
  final text = value.trim().toLowerCase();

  switch (text) {
    case 'split':
      return TransformType.split;
    case 'regex':
      return TransformType.regex;
    case 'const':
    case 'constant':
      return TransformType.constant;
    case 'raw':
    default:
      return TransformType.raw;
  }
}

bool _emmaLooksLikePhone(String value) {
  final text = value.trim();
  if (text.isEmpty) return false;
  if (_emmaLooksLikeDate(text)) return false;
  if (_emmaLooksLikePostalCode(text)) return false;
  if (_emmaEmailRegex.hasMatch(text)) return false;

  final digits = normalizeDigitSequence(text);
  if (digits.length < 7 || digits.length > 15) return false;

  return _emmaPhoneRegex.hasMatch(text);
}

bool _emmaLooksLikePostalCode(String value) {
  return _emmaPostalCodeRegex.hasMatch(value.trim());
}

bool _emmaLooksLikeAmount(String value) {
  final text = value.trim();
  if (text.isEmpty) return false;
  if (_emmaEmailRegex.hasMatch(text)) return false;
  if (_emmaLooksLikeDate(text)) return false;
  if (_emmaLooksLikePhone(text)) return false;
  if (_emmaLooksLikePostalCode(text)) return false;

  return _emmaAmountRegex.hasMatch(text);
}

bool _emmaLooksLikeDate(String value) {
  return _emmaDateRegex.hasMatch(value.trim());
}

bool _emmaLooksLikePersonName(String value) {
  final text = value.trim();
  if (text.isEmpty) return false;

  if (_emmaEmailRegex.hasMatch(text)) return false;
  if (_emmaLooksLikePhone(text)) return false;
  if (_emmaNipRegex.hasMatch(text)) return false;
  if (_emmaRegonRegex.hasMatch(text)) return false;
  if (_emmaLooksLikeDate(text)) return false;
  if (_emmaLooksLikeAmount(text)) return false;

  final parts = text
      .split(RegExp(r'\s+'))
      .where((p) => p.trim().isNotEmpty)
      .toList();

  if (parts.length < 2 || parts.length > 4) return false;

  final lowered = parts
      .map((p) => p.toLowerCase().replaceAll(RegExp(r'[.,]'), ''))
      .toSet();

  const companyTokens = {
    'sp',
    'z',
    'oo',
    'o',
    'o.o',
    'sa',
    's.a',
    'nieruchomości',
    'nieruchomosci',
    'biuro',
    'agencja',
    'estate',
    'real',
    'company',
    'group',
  };

  if (lowered.intersection(companyTokens).isNotEmpty) return false;

  return parts.every(
    (p) => RegExp(r'[A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]').hasMatch(p),
  );
}

bool _emmaLooksLikeCompanyName(String value) {
  final text = value.toLowerCase().trim();
  if (text.isEmpty) return false;

  const tokens = [
    'sp.',
    'sp z o.o',
    'spółka',
    'spolka',
    's.a',
    'sa',
    'nieruchomości',
    'nieruchomosci',
    'biuro',
    'agencja',
    'estate',
    'real estate',
    'property',
    'group',
    'invest',
    'development',
    'dom',
    'mieszkania',
  ];

  return tokens.any((token) => text.contains(token));
}

String _detectDelimiter(String line) {
  final candidates = [',', ';', '\t', '|'];
  String best = ',';
  int bestCount = -1;

  for (final d in candidates) {
    final count = _splitCsvLineBasic(line, d).length;
    if (count > bestCount) {
      bestCount = count;
      best = d;
    }
  }

  return best;
}

List<String> _splitCsvLineBasic(String line, String delimiter) {
  final result = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
      if (inQuotes && nextIsQuote) {
        buffer.write('"');
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (!inQuotes && char == delimiter) {
      result.add(buffer.toString().trim());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }

  result.add(buffer.toString().trim());
  return result;
}

List<dynamic> _extractEmmaRulesFromResult(Map<String, dynamic> result) {
  final split = _asStringMap(result['split']);
  final frontend = _asStringMap(result['frontend']);
  final frontendPayload = _asStringMap(frontend['payload']);
  final llmResult = _asStringMap(result['llm_result']);

  final candidates = [
    split['rules'],
    result['rules'],
    frontendPayload['rules'],
    llmResult['rules'],
  ];

  for (final candidate in candidates) {
    if (candidate is List) return candidate;
  }

  return <dynamic>[];
}

List<dynamic> _extractEmmaMappingHintsFromResult(Map<String, dynamic> result) {
  final split = _asStringMap(result['split']);
  final frontend = _asStringMap(result['frontend']);
  final frontendPayload = _asStringMap(frontend['payload']);
  final llmResult = _asStringMap(result['llm_result']);
  final entityPlanResult = _asStringMap(result['entity_plan']);
  final plan = _asStringMap(entityPlanResult['plan']);

  final candidates = [
    split['mapping_hints'],
    result['mapping_hints'],
    frontendPayload['mapping_hints'],
    llmResult['mapping_hints'],
    plan['mapping_hints'],
  ];

  for (final candidate in candidates) {
    if (candidate is List) return candidate;
  }

  final entities = plan['entities'];
  if (entities is List) {
    final hints = <Map<String, dynamic>>[];

    for (final entityRaw in entities) {
      if (entityRaw is! Map) continue;
      final entity = Map<String, dynamic>.from(entityRaw);
      final targetModel = _emmaString(entity['target_model']);
      final mappings = entity['mappings'];

      if (mappings is! Map) continue;

      mappings.forEach((targetFieldRaw, sourceColumnRaw) {
        final targetField = _emmaString(targetFieldRaw);
        final sourceColumn = _emmaString(sourceColumnRaw);

        if (targetModel.isEmpty || targetField.isEmpty || sourceColumn.isEmpty) {
          return;
        }

        hints.add({
          'output_column': sourceColumn,
          'target_model': targetModel,
          'target_field': targetField,
          'confidence': entity['confidence'] ?? 1.0,
          'reason': entity['reason'] ?? 'Mapping from entity plan.',
        });
      });
    }

    return hints;
  }

  return <dynamic>[];
}

Map<String, dynamic> _extractEmmaEntityPlanFromResult(
  Map<String, dynamic> result,
) {
  final entityPlanResult = _asStringMap(result['entity_plan']);
  final directPlan = _asStringMap(result['entity_plan_payload']);
  final planFromEntityResult = _asStringMap(entityPlanResult['plan']);
  final llmResult = _asStringMap(result['llm_result']);
  final llmPlan = _asStringMap(llmResult['entity_plan']);

  final candidates = [
    planFromEntityResult,
    directPlan,
    llmPlan,
    _asStringMap(result['plan']),
  ];

  for (final candidate in candidates) {
    if (_hasValidEntityPlan(candidate)) {
      return candidate;
    }
  }

  return <String, dynamic>{};
}

bool _hasValidEntityPlan(Map<String, dynamic>? plan) {
  if (plan == null || plan.isEmpty) return false;
  final entities = plan['entities'];
  return entities is List && entities.isNotEmpty;
}

List<BatchImportResult> _extractBatchResultsFromBody(Map<String, dynamic> body) {
  final out = <BatchImportResult>[];

  void addFrom(dynamic raw) {
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          out.add(BatchImportResult.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return;
    }

    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          map.putIfAbsent('target_model', () => key.toString());
          out.add(BatchImportResult.fromJson(map));
        }
      });
    }
  }

  addFrom(body['results']);
  addFrom(body['results_by_model']);
  addFrom(body['batches']);

  return out;
}
