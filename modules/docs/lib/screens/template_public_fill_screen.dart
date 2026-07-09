import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/models/document.dart';
import 'package:docs/screens/temp_fill_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class TemplatePublicFillScreen extends ConsumerStatefulWidget {
  final String? token;

  const TemplatePublicFillScreen({
    super.key,
    this.token,
  });

  @override
  ConsumerState<TemplatePublicFillScreen> createState() =>
      _TemplatePublicFillScreenState();
}

class _TemplatePublicFillScreenState
    extends ConsumerState<TemplatePublicFillScreen> {
  final Map<String, TemplateFieldSpec> _fieldSpecs = {};
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, TextEditingController> _prefixControllers = {};
  final Map<String, String?> _dropdownValues = {};
  final Set<String> _skippedSegmentIds = {};

  List<TemplateSegmentSpec> _segments = [];

  DocumentFillSession? _session;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitted = false;

  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAndLoad();
    });
  }

  @override
  void dispose() {
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }

    for (final controller in _prefixControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _resolveAndLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? token = widget.token;

      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String && args.trim().isNotEmpty) {
        token = args.trim();
      } else if (args is Map) {
        final value = args['token'] ?? args['publicToken'] ?? args['public_token'];

        if (value != null && value.toString().trim().isNotEmpty) {
          token = value.toString().trim();
        }
      }

      token ??= Uri.base.queryParameters['token'];

      if (token == null || token.trim().isEmpty) {
        throw Exception('Brak tokenu formularza.');
      }

      _token = token.trim();

      final session = await DocumentService.getPublicFillSession(
        token: _token!,
        ref: ref,
      );

      if (!mounted) return;

      _setSession(session);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setSession(DocumentFillSession session) {
    _session = session;
    _submitted = session.isSubmitted;

    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }

    for (final controller in _prefixControllers.values) {
      controller.dispose();
    }

    _fieldSpecs.clear();
    _fieldControllers.clear();
    _prefixControllers.clear();
    _dropdownValues.clear();
    _skippedSegmentIds.clear();

    final parsed = TemplateFieldParser.parseDelta(session.templateDeltaJson);

    final backendFields = TemplateFormFieldAdapter.fromBackendFields(
      session.templateFields,
    );

    final fields = backendFields.isNotEmpty ? backendFields : parsed.fields;

    _segments = parsed.segments;

    final initialValues = Map<String, dynamic>.from(session.values);

    final meta = initialValues['_meta'];

    if (meta is Map && meta['skipped_segment_ids'] is List) {
      _skippedSegmentIds.addAll(
        (meta['skipped_segment_ids'] as List)
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty),
      );
    }

    for (final spec in fields) {
      _fieldSpecs[spec.key] = spec;

      final initialValue = initialValues[spec.key]?.toString() ??
          spec.defaultValue?.toString() ??
          '';

      if (spec.isDropdown) {
        if (initialValue.trim().isNotEmpty &&
            spec.options.any((option) => option.value == initialValue)) {
          _dropdownValues[spec.key] = initialValue;
        } else {
          _dropdownValues[spec.key] = null;
        }
      } else {
        _fieldControllers[spec.key] = TextEditingController(
          text: initialValue,
        );
      }

      if (spec.hasEditablePrefix) {
        _prefixControllers[spec.key] = TextEditingController(
          text: spec.defaultPrefix ?? '',
        );
      }
    }

    if (fields.isEmpty && session.templateDeltaJson.isEmpty) {
      _error =
          'Backend nie zwrócił pól formularza ani treści template. Publiczny endpoint musi zwracać template_delta_json albo template_fields.';
    }
  }

  Map<String, String> get _values {
    final result = <String, String>{};

    for (final spec in _fieldSpecs.values) {
      result[spec.key] = _valueForSpec(spec);
    }

    return result;
  }

  String _rawValueForSpec(TemplateFieldSpec spec) {
    if (spec.isDropdown) {
      return _dropdownValues[spec.key]?.trim() ?? '';
    }

    return _fieldControllers[spec.key]?.text.trim() ?? '';
  }

  String _valueForSpec(TemplateFieldSpec spec) {
    final rawValue = _rawValueForSpec(spec);

    if (rawValue.isEmpty) {
      return '';
    }

    final prefix = _prefixControllers[spec.key]?.text.trim() ?? '';

    if (prefix.isEmpty) {
      return rawValue;
    }

    if (rawValue.startsWith(prefix)) {
      return rawValue;
    }

    return '$prefix $rawValue'.trim();
  }

  Set<String> _effectiveSkippedSegmentIds() {
    final result = <String>{..._skippedSegmentIds};

    for (final segment in _segments) {
      if (!segment.skipable) continue;

      if (_isSegmentEmpty(segment)) {
        result.add(segment.id);
      }
    }

    return result;
  }

  bool _isSegmentEmpty(TemplateSegmentSpec segment) {
    final fields = _fieldSpecs.values
        .where((field) => field.segmentId == segment.id)
        .toList();

    if (fields.isEmpty) return false;

    return fields.every((field) => _rawValueForSpec(field).trim().isEmpty);
  }

  bool _isSegmentSkipped(TemplateSegmentSpec segment) {
    return _effectiveSkippedSegmentIds().contains(segment.id);
  }

  String _previewText() {
    final session = _session;

    if (session == null) return '';

    return TemplateFieldParser.replaceFieldsInText(
      text: TemplateFieldParser.plainTextFromDelta(session.templateDeltaJson),
      values: _values,
      skippedSegmentIds: _effectiveSkippedSegmentIds(),
    );
  }

  String? _validateBeforeSubmit() {
    final skippedSegmentIds = _effectiveSkippedSegmentIds();

    for (final spec in _fieldSpecs.values) {
      if (spec.segmentId != null && skippedSegmentIds.contains(spec.segmentId)) {
        continue;
      }

      final rawValue = _rawValueForSpec(spec);

      if (spec.required && rawValue.trim().isEmpty) {
        return 'Pole "${spec.label}" jest wymagane.';
      }

      if (rawValue.trim().isEmpty) {
        continue;
      }

      if (spec.maxLength != null && rawValue.length > spec.maxLength!) {
        return 'Pole "${spec.label}" może mieć maksymalnie ${spec.maxLength} znaków.';
      }

      if (spec.isEmail) {
        final validEmail = RegExp(
          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
        ).hasMatch(rawValue.trim());

        if (!validEmail) {
          return 'Pole "${spec.label}" musi zawierać poprawny adres e-mail.';
        }
      }

      if (spec.isNumber) {
        final number = num.tryParse(rawValue.replaceAll(',', '.'));

        if (number == null) {
          return 'Pole "${spec.label}" musi być liczbą.';
        }

        if (spec.min != null && number < spec.min!) {
          return 'Pole "${spec.label}" musi być większe lub równe ${spec.min}.';
        }

        if (spec.max != null && number > spec.max!) {
          return 'Pole "${spec.label}" musi być mniejsze lub równe ${spec.max}.';
        }
      }
    }

    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final token = _token;

    if (token == null || token.trim().isEmpty) {
      setState(() {
        _error = 'Brak tokenu formularza.';
      });
      return;
    }

    final session = _session;

    if (session == null) {
      setState(() {
        _error = 'Brak sesji formularza.';
      });
      return;
    }

    if (session.isExpired) {
      setState(() {
        _error = 'Ten formularz wygasł.';
      });
      return;
    }

    final validationError = _validateBeforeSubmit();

    if (validationError != null) {
      setState(() {
        _error = validationError;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final values = <String, dynamic>{
        ..._values,
        '_meta': {
          'skipped_segment_ids': _effectiveSkippedSegmentIds().toList(),
          'submitted_from': 'public_template_fill_screen',
          'submitted_at_client': DateTime.now().toIso8601String(),
        },
      };

      await DocumentService.submitPublicFillSession(
        token: token,
        values: values,
        ref: ref,
      );

      if (!mounted) return;

      setState(() {
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: theme.dashboardContainer,
        textTheme: baseTheme.textTheme.apply(
          bodyColor: theme.textColor,
          displayColor: theme.textColor,
        ),
        iconTheme: IconThemeData(color: theme.textColor),
      ),
      child: Scaffold(
        backgroundColor: theme.dashboardContainer,
        body: SafeArea(
          child: _isLoading
              ? Center(child: AppLottie.loading(size: 320))
              : _submitted
                  ? _buildSuccess(theme)
                  : _error != null && _session == null
                      ? _PublicFillError(
                          error: _error!,
                          onRetry: _resolveAndLoad,
                        )
                      : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeColors theme) {
    final session = _session;

    if (session == null) {
      return _PublicFillError(
        error: 'Nie udało się załadować formularza.',
        onRetry: _resolveAndLoad,
      );
    }

    if (session.isExpired) {
      return _PublicFillExpired(
        templateName: session.templateName,
      );
    }

    final preview = _previewText();

    return Column(
      children: [
        _PublicFillHeader(
          templateName: session.templateName,
          recipientName: session.recipientName,
          message: session.message,
          isSubmitting: _isSubmitting,
          onSubmit: _submit,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _PublicFillInlineError(
              error: _error!,
              onClose: () {
                setState(() {
                  _error = null;
                });
              },
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              if (isNarrow) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _buildFormCard(theme),
                    const SizedBox(height: 14),
                    _buildPreviewCard(theme, preview),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 10, 24),
                      children: [
                        _buildFormCard(theme),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(10, 4, 20, 24),
                      children: [
                        _buildPreviewCard(theme, preview),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(ThemeColors theme) {
    final allFields = _fieldSpecs.values.toList();
    final segmentIds = _segments.map((segment) => segment.id).toSet();

    final ungroupedFields = allFields
        .where(
          (field) =>
              field.segmentId == null || !segmentIds.contains(field.segmentId),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PublicSectionTitle(
            icon: Icons.assignment_outlined,
            title: 'Formularz dokumentu',
            subtitle: 'Uzupełnij dane potrzebne do przygotowania dokumentu.',
          ),
          const SizedBox(height: 18),
          if (allFields.isEmpty)
            _PublicInfoBox(
              text:
                  'Ten formularz nie ma skonfigurowanych pól. Skontaktuj się z osobą, która wysłała link.',
            )
          else ...[
            if (ungroupedFields.isNotEmpty)
              ...ungroupedFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PublicDynamicField(
                    spec: field,
                    controller: _fieldControllers[field.key],
                    prefixController: _prefixControllers[field.key],
                    value: _dropdownValues[field.key],
                    onDropdownChanged: (value) {
                      setState(() {
                        _dropdownValues[field.key] = value;
                      });
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ..._segments.map((segment) {
              final segmentFields = allFields
                  .where((field) => field.segmentId == segment.id)
                  .toList();

              if (segmentFields.isEmpty) {
                return const SizedBox.shrink();
              }

              final manuallySkipped = _skippedSegmentIds.contains(segment.id);
              final effectivelySkipped = _isSegmentSkipped(segment);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: effectivelySkipped
                          ? theme.textColor.withAlpha(60)
                          : theme.dashboardBoarder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.segment_outlined,
                            color: theme.textColor.withAlpha(170),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              segment.label,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (segment.skipable)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pomiń',
                                  style: TextStyle(
                                    color: theme.textColor.withAlpha(160),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                Checkbox(
                                  value: manuallySkipped,
                                  activeColor: theme.themeColor,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: theme.dashboardBoarder,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _skippedSegmentIds.add(segment.id);
                                      } else {
                                        _skippedSegmentIds.remove(segment.id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (effectivelySkipped)
                        _PublicInfoBox(
                          text: manuallySkipped
                              ? 'Ta sekcja została pominięta.'
                              : 'Ta sekcja jest pusta, więc zostanie automatycznie pominięta.',
                        )
                      else
                        ...segmentFields.map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PublicDynamicField(
                              spec: field,
                              controller: _fieldControllers[field.key],
                              prefixController: _prefixControllers[field.key],
                              value: _dropdownValues[field.key],
                              onDropdownChanged: (value) {
                                setState(() {
                                  _dropdownValues[field.key] = value;
                                });
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.dashboardBoarder.withAlpha(90),
                disabledForegroundColor: theme.textColor.withAlpha(120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isSubmitting
                  ? SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.textColor,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text(
                'Wyślij formularz',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ThemeColors theme, String preview) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PublicSectionTitle(
            icon: Icons.visibility_outlined,
            title: 'Podgląd',
            subtitle: 'Tak mogą wyglądać podstawione dane w dokumencie.',
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: SelectableText(
              preview.trim().isEmpty ? 'Brak podglądu dokumentu.' : preview,
              style: TextStyle(
                color: theme.textColor,
                height: 1.55,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(ThemeColors theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 58,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Formularz został wysłany',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dziękujemy. Dane zostały zapisane i przekazane do przygotowania dokumentu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(165),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicFillHeader extends ConsumerWidget {
  final String templateName;
  final String recipientName;
  final String message;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _PublicFillHeader({
    required this.templateName,
    required this.recipientName,
    required this.message,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final title = Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipientName.trim().isEmpty
                          ? 'Uzupełnij formularz'
                          : 'Cześć, $recipientName',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      templateName.trim().isEmpty
                          ? 'Dokument do uzupełnienia'
                          : templateName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(150),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(165),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isSubmitting
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.textColor,
                    ),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text(
              'Wyślij',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: button,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 14),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _PublicDynamicField extends ConsumerWidget {
  final TemplateFieldSpec spec;
  final TextEditingController? controller;
  final TextEditingController? prefixController;
  final String? value;
  final ValueChanged<String?> onDropdownChanged;
  final ValueChanged<String> onChanged;

  const _PublicDynamicField({
    required this.spec,
    required this.controller,
    required this.prefixController,
    required this.value,
    required this.onDropdownChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    if (spec.isDropdown) {
      return _PublicFieldWithHelp(
        spec: spec,
        child: DropdownButtonFormField<String>(
          value: value,
          dropdownColor: theme.dashboardContainer,
          iconEnabledColor: theme.textColor,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
          items: spec.options.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(
                option.label,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
          onChanged: onDropdownChanged,
          decoration: _decoration(
            theme: theme,
            label: spec.required ? '${spec.label} *' : spec.label,
            hint: 'Wybierz wartość',
            icon: Icons.arrow_drop_down_circle_outlined,
          ),
        ),
      );
    }

    final textField = TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: spec.maxLength,
      keyboardType: _keyboardType(spec),
      cursorColor: theme.themeColor,
      style: TextStyle(
        color: theme.textColor,
        fontWeight: FontWeight.w700,
      ),
      decoration: _decoration(
        theme: theme,
        label: spec.required ? '${spec.label} *' : spec.label,
        hint: _hint(spec),
        icon: _icon(spec),
      ),
    );

    if (!spec.hasEditablePrefix || prefixController == null) {
      return _PublicFieldWithHelp(
        spec: spec,
        child: textField,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;

        final prefixField = TextField(
          controller: prefixController,
          onChanged: onChanged,
          cursorColor: theme.themeColor,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
          ),
          decoration: _decoration(
            theme: theme,
            label: 'Prefix',
            hint: '+48',
            icon: Icons.tag_outlined,
          ),
        );

        if (compact) {
          return _PublicFieldWithHelp(
            spec: spec,
            child: Column(
              children: [
                prefixField,
                const SizedBox(height: 10),
                textField,
              ],
            ),
          );
        }

        return _PublicFieldWithHelp(
          spec: spec,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 130, child: prefixField),
              const SizedBox(width: 10),
              Expanded(child: textField),
            ],
          ),
        );
      },
    );
  }

  TextInputType _keyboardType(TemplateFieldSpec spec) {
    switch (spec.type) {
      case TemplateFieldType.email:
        return TextInputType.emailAddress;
      case TemplateFieldType.phone:
        return TextInputType.phone;
      case TemplateFieldType.number:
        return const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        );
      case TemplateFieldType.text:
      case TemplateFieldType.dropdown:
        return TextInputType.text;
    }
  }

  IconData _icon(TemplateFieldSpec spec) {
    switch (spec.type) {
      case TemplateFieldType.email:
        return Icons.mail_outline;
      case TemplateFieldType.phone:
        return Icons.phone_outlined;
      case TemplateFieldType.number:
        return Icons.numbers_outlined;
      case TemplateFieldType.dropdown:
        return Icons.arrow_drop_down_circle_outlined;
      case TemplateFieldType.text:
        return Icons.edit_note_outlined;
    }
  }

  String _hint(TemplateFieldSpec spec) {
    switch (spec.type) {
      case TemplateFieldType.email:
        return 'np. klient@email.com';
      case TemplateFieldType.phone:
        return 'np. 500 600 700';
      case TemplateFieldType.number:
        return 'Wpisz liczbę';
      case TemplateFieldType.dropdown:
        return 'Wybierz wartość';
      case TemplateFieldType.text:
        if (spec.maxLength != null) {
          return 'Maksymalnie ${spec.maxLength} znaków';
        }

        return 'Wpisz wartość';
    }
  }

  InputDecoration _decoration({
    required ThemeColors theme,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: theme.textColor.withAlpha(150)),
      labelText: label,
      hintText: hint,
      counterStyle: TextStyle(
        color: theme.textColor.withAlpha(130),
        fontWeight: FontWeight.w600,
      ),
      labelStyle: TextStyle(
        color: theme.textColor.withAlpha(165),
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: TextStyle(
        color: theme.themeColor,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: TextStyle(
        color: theme.textColor.withAlpha(120),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: theme.dashboardContainer,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dashboardBoarder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dashboardBoarder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.themeColor, width: 1.5),
      ),
    );
  }
}

class _PublicFieldWithHelp extends ConsumerWidget {
  final TemplateFieldSpec spec;
  final Widget child;

  const _PublicFieldWithHelp({
    required this.spec,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final help = spec.helpText?.trim();

    if (help == null || help.isEmpty) {
      return child;
    }

    final theme = ref.watch(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            help,
            style: TextStyle(
              color: theme.textColor.withAlpha(135),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _PublicSectionTitle extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PublicSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Row(
      children: [
        Icon(icon, color: theme.textColor.withAlpha(170), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.textColor.withAlpha(145),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicInfoBox extends ConsumerWidget {
  final String text;

  const _PublicInfoBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textColor.withAlpha(155),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PublicFillInlineError extends ConsumerWidget {
  final String error;
  final VoidCallback onClose;

  const _PublicFillInlineError({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: theme.textColor),
          ),
        ],
      ),
    );
  }
}

class _PublicFillError extends ConsumerWidget {
  final String error;
  final VoidCallback onRetry;

  const _PublicFillError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.red.withAlpha(120)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
            const SizedBox(height: 14),
            Text(
              'Nie udało się otworzyć formularza',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicFillExpired extends ConsumerWidget {
  final String templateName;

  const _PublicFillExpired({
    required this.templateName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off_outlined,
              size: 54,
              color: theme.textColor.withAlpha(170),
            ),
            const SizedBox(height: 14),
            Text(
              'Formularz wygasł',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              templateName.trim().isEmpty
                  ? 'Ten link nie jest już aktywny.'
                  : 'Link do formularza „$templateName” nie jest już aktywny.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}