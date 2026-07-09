import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/models/document.dart';
import 'package:docs/models/document_temp.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class TemplateFillScreen extends ConsumerWidget {
  final DocumentTemplate? template;
  final String? templateId;

  /// Route edytora dokumentów.
  final String documentEditorRoute;

  /// Publiczny route formularza klienta.
  /// Przykład:
  /// /docs/public/fill?token=...
  final String clientFillRoute;

  TemplateFillScreen({
    super.key,
    this.template,
    this.templateId,
    this.documentEditorRoute = '/docs/editor',
    this.clientFillRoute = '/docs/public/fill',
  });

  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      isChildExpanded: true,
      enableScrool: false,
      isTopAppBarHoveroverUI: false,
      isTopAppBarOff: true,
      layoutTypePc: LayoutTypePc.stack,
      layoutTypeTablet: LayoutTypeTablet.stack,
      layoutTypeMobile: LayoutTypeMobile.stack,
      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      childPc: TemplateFillConnectedView(
        template: template,
        templateId: templateId,
        documentEditorRoute: documentEditorRoute,
        clientFillRoute: clientFillRoute,
      ),
      childTablet: TemplateFillConnectedView(
        template: template,
        templateId: templateId,
        documentEditorRoute: documentEditorRoute,
        clientFillRoute: clientFillRoute,
      ),
      childMobile: TemplateFillConnectedView(
        template: template,
        templateId: templateId,
        documentEditorRoute: documentEditorRoute,
        clientFillRoute: clientFillRoute,
      ),
    );
  }
}

class TemplateFillConnectedView extends ConsumerStatefulWidget {
  final DocumentTemplate? template;
  final String? templateId;
  final String documentEditorRoute;
  final String clientFillRoute;

  const TemplateFillConnectedView({
    super.key,
    this.template,
    this.templateId,
    required this.documentEditorRoute,
    required this.clientFillRoute,
  });

  @override
  ConsumerState<TemplateFillConnectedView> createState() =>
      _TemplateFillConnectedViewState();
}

class _TemplateFillConnectedViewState
    extends ConsumerState<TemplateFillConnectedView> {
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final Map<String, TemplateFieldSpec> _fieldSpecs = {};
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, TextEditingController> _prefixControllers = {};
  final Map<String, String?> _dropdownValues = {};
  final Set<String> _skippedSegmentIds = {};

  List<TemplateSegmentSpec> _segments = [];

  DocumentTemplate? _template;
  DocumentFillSession? _createdFillSession;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSending = false;

  String? _error;
  String? _createdDocumentId;
  String? _createdFormLink;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveTemplate();
    });
  }

  @override
  void dispose() {
    _clientEmailController.dispose();
    _clientNameController.dispose();
    _messageController.dispose();

    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }

    for (final controller in _prefixControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _resolveTemplate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      DocumentTemplate? template = widget.template;
      String? templateId = widget.templateId;

      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is DocumentTemplate) {
        template = args;
      } else if (args is String) {
        templateId = args;
      } else if (args is Map) {
        final argTemplate = args['template'];
        final argTemplateId = args['templateId'] ?? args['template_id'];

        if (argTemplate is DocumentTemplate) {
          template = argTemplate;
        }

        if (argTemplateId != null) {
          templateId = argTemplateId.toString();
        }
      }

      if (template == null && templateId != null) {
        template = await DocumentService.getTemplate(templateId, ref);
      }

      if (template == null) {
        throw Exception('Nie przekazano template do wypełnienia.');
      }

      if (!mounted) return;

      _setTemplate(template);
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

  void _setTemplate(DocumentTemplate template) {
    _template = template;

    final parsed = TemplateFieldParser.parseDelta(template.deltaJson);

    final backendFields = TemplateFormFieldAdapter.fromBackendFields(
      template.formFields,
    );

    final fields = backendFields.isNotEmpty ? backendFields : parsed.fields;

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

    _createdDocumentId = null;
    _createdFillSession = null;
    _createdFormLink = null;

    _segments = parsed.segments;

    for (final spec in fields) {
      _fieldSpecs[spec.key] = spec;

      if (spec.isDropdown) {
        final defaultValue = spec.defaultValue?.trim();

        if (defaultValue != null &&
            defaultValue.isNotEmpty &&
            spec.options.any((option) => option.value == defaultValue)) {
          _dropdownValues[spec.key] = defaultValue;
        } else {
          _dropdownValues[spec.key] = null;
        }
      } else {
        _fieldControllers[spec.key] = TextEditingController(
          text: spec.defaultValue ?? '',
        );
      }

      if (spec.hasEditablePrefix) {
        _prefixControllers[spec.key] = TextEditingController(
          text: spec.defaultPrefix ?? '',
        );
      }
    }

    _messageController.text =
        'Cześć, przesyłam formularz do uzupełnienia dokumentu: ${template.name}.';

    _syncKnownFieldValues(force: true);
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

      final isEmpty = _isSegmentEmpty(segment);

      if (isEmpty) {
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

  void _syncKnownFieldValues({bool force = false}) {
    final clientName = _clientNameController.text.trim();
    final clientEmail = _clientEmailController.text.trim();

    void setIfNeeded(TemplateFieldSpec spec, String value) {
      final controller = _fieldControllers[spec.key];

      if (controller == null) return;
      if (value.isEmpty) return;

      if (force || controller.text.trim().isEmpty) {
        controller.text = value;
      }
    }

    for (final spec in _fieldSpecs.values) {
      final label = spec.label.toLowerCase().trim();
      final key = spec.key.toLowerCase().trim();

      if (spec.isEmail ||
          label.contains('email') ||
          label.contains('e-mail') ||
          label.contains('mail') ||
          key.contains('email') ||
          key.contains('mail')) {
        setIfNeeded(spec, clientEmail);
      }

      if (label.contains('imię') ||
          label.contains('imie') ||
          label.contains('nazwa') ||
          label.contains('klient') ||
          label.contains('full name') ||
          label.contains('name') ||
          key.contains('client_name') ||
          key.contains('customer_name') ||
          key.contains('name')) {
        setIfNeeded(spec, clientName);
      }
    }
  }

  String _previewText(DocumentTemplate template) {
    return TemplateFieldParser.replaceFieldsInText(
      text: TemplateFieldParser.plainTextFromDelta(template.deltaJson),
      values: _values,
      skippedSegmentIds: _effectiveSkippedSegmentIds(),
    );
  }

  Map<String, dynamic> _buildFilledDeltaJson(DocumentTemplate template) {
    return TemplateFieldParser.buildFilledDelta(
      deltaJson: template.deltaJson,
      values: _values,
      skippedSegmentIds: _effectiveSkippedSegmentIds(),
    );
  }

  String? _validateBeforeCreate() {
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

  Future<Documents> _createFilledDocument() async {
    final validationError = _validateBeforeCreate();

    if (validationError != null) {
      throw Exception(validationError);
    }

    final template = _template;

    if (template == null) {
      throw Exception('Brak template.');
    }

    final clientName = _clientNameController.text.trim();
    final clientEmail = _clientEmailController.text.trim();

    final suffix = clientName.isNotEmpty
        ? clientName
        : clientEmail.isNotEmpty
            ? clientEmail
            : 'klient';

    final document = await DocumentService.createDocument(
      templateId: template.id,
      title: '${template.name} - $suffix',
      currentDelta: _buildFilledDeltaJson(template),
      currentStyle: template.styleJson,
      ref: ref,
    );

    ref.read(documentProvider.notifier).setDocument(document);

    return document;
  }

  Future<void> _saveFilledDocument() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final document = await _createFilledDocument();

      if (!mounted) return;

      setState(() {
        _createdDocumentId = document.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokument został utworzony z template.'),
          backgroundColor: Colors.green,
        ),
      );

      _openDocument(document.id);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _sendFormToClient() async {
    if (_isSending) return;

    final template = _template;

    if (template == null) {
      setState(() {
        _error = 'Brak template.';
      });
      return;
    }

    final email = _clientEmailController.text.trim();

    final validEmail = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(email);

    if (!validEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Podaj poprawny adres e-mail klienta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
      _createdFormLink = null;
      _createdFillSession = null;
    });

    try {
      final values = <String, dynamic>{
        ..._values,
        '_meta': {
          'skipped_segment_ids': _effectiveSkippedSegmentIds().toList(),
          'template_name': template.name,
          'created_from': 'template_fill_screen',
        },
      };

      final session = await DocumentService.createFillSession(
        templateId: template.id,
        recipientEmail: email,
        recipientName: _clientNameController.text.trim(),
        message: _messageController.text.trim(),
        values: values,
        ref: ref,
      );

      final sentSession = await DocumentService.markFillSessionSent(
        sessionId: session.id,
        ref: ref,
      );

      final link = _buildClientFillLink(sentSession.publicToken);

      if (!mounted) return;

      setState(() {
        _createdFillSession = sentSession;
        _createdFormLink = link;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Formularz został przygotowany dla $email.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });
    }
  }

  String _buildClientFillLink(String token) {
    String origin = '';

    try {
      origin = Uri.base.origin;
    } catch (_) {
      origin = '';
    }

    final cleanRoute = widget.clientFillRoute.startsWith('/')
        ? widget.clientFillRoute
        : '/${widget.clientFillRoute}';

    final baseString = Uri.base.toString();
    final useHashRoute = baseString.contains('/#/');

    if (origin.trim().isEmpty) {
      return '$cleanRoute?token=$token';
    }

    if (useHashRoute) {
      return '$origin/#$cleanRoute?token=$token';
    }

    return '$origin$cleanRoute?token=$token';
  }

  Future<void> _copyFormLink() async {
    final link = _createdFormLink;

    if (link == null || link.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link do formularza skopiowany.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openDocument(String documentId) {
    ref.read(navigationService).pushNamedScreen(
          widget.documentEditorRoute,
          data: documentId,
        );
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
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: theme.textColor.withAlpha(165)),
          hintStyle: TextStyle(color: theme.textColor.withAlpha(120)),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: theme.dashboardContainer,
          textStyle: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Container(
        color: theme.dashboardContainer,
        child: SafeArea(
          child: _isLoading
              ? Center(child: AppLottie.loading(size: 320))
              : _error != null && _template == null
                  ? _TemplateFillError(
                      error: _error!,
                      onRetry: _resolveTemplate,
                    )
                  : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeColors theme) {
    final template = _template;

    if (template == null) {
      return _TemplateFillError(
        error: 'Brak template.',
        onRetry: _resolveTemplate,
      );
    }

    final preview = _previewText(template);

    return Column(
      children: [
        _TemplateFillHeader(
          templateName: template.name,
          isSaving: _isSaving,
          isSending: _isSending,
          createdDocumentId: _createdDocumentId,
          createdFormLink: _createdFormLink,
          onSave: _saveFilledDocument,
          onSend: _sendFormToClient,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _TemplateFillInlineError(
              error: _error!,
              onClose: () {
                setState(() {
                  _error = null;
                });
              },
            ),
          ),
        if (_createdFormLink != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _TemplateFillLinkBox(
              link: _createdFormLink!,
              recipientEmail: _createdFillSession?.recipientEmail ?? '',
              onCopy: _copyFormLink,
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
          const _SectionTitle(
            icon: Icons.assignment_outlined,
            title: 'Dane formularza',
            subtitle: 'Uzupełnij pola ręcznie albo wyślij formularz do klienta.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _clientEmailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              _syncKnownFieldValues();
              setState(() {});
            },
            cursorColor: theme.themeColor,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
            decoration: _inputDecoration(
              theme: theme,
              label: 'E-mail klienta',
              hint: 'np. klient@email.com',
              icon: Icons.mail_outline,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clientNameController,
            onChanged: (_) {
              _syncKnownFieldValues();
              setState(() {});
            },
            cursorColor: theme.themeColor,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
            decoration: _inputDecoration(
              theme: theme,
              label: 'Nazwa / imię klienta',
              hint: 'np. Jan Kowalski',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            minLines: 3,
            maxLines: 5,
            cursorColor: theme.themeColor,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
            decoration: _inputDecoration(
              theme: theme,
              label: 'Wiadomość do klienta',
              hint: 'Krótka wiadomość w mailu',
              icon: Icons.message_outlined,
            ),
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            icon: Icons.data_object_outlined,
            title: 'Pola z template',
            subtitle: allFields.isEmpty
                ? 'Nie wykryto pól formularza w treści template.'
                : 'Wykryto ${allFields.length} pól do uzupełnienia.',
          ),
          const SizedBox(height: 14),
          if (allFields.isEmpty)
            const _NoFieldsBox()
          else ...[
            if (ungroupedFields.isNotEmpty) ...[
              ...ungroupedFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDynamicField(field),
                ),
              ),
            ],
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  segment.label,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                if (segment.skipable)
                                  Text(
                                    'Sekcja zniknie z dokumentu, jeśli zostanie pusta albo ją pominiesz.',
                                    style: TextStyle(
                                      color: theme.textColor.withAlpha(135),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (segment.skipable) ...[
                            const SizedBox(width: 10),
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (effectivelySkipped)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.dashboardContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.dashboardBoarder,
                            ),
                          ),
                          child: Text(
                            manuallySkipped
                                ? 'Ta sekcja została ręcznie pominięta.'
                                : 'Ta sekcja jest pusta, więc zostanie automatycznie pominięta.',
                            style: TextStyle(
                              color: theme.textColor.withAlpha(155),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        ...segmentFields.map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDynamicField(field),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;

              final saveButton = _PrimaryTemplateButton(
                onPressed: _isSaving ? null : _saveFilledDocument,
                isLoading: _isSaving,
                icon: Icons.note_add_outlined,
                label: 'Utwórz dokument',
              );

              final sendButton = _SecondaryTemplateButton(
                onPressed: _isSending ? null : _sendFormToClient,
                isLoading: _isSending,
                icon: Icons.send_outlined,
                label: 'Wyślij formularz',
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    saveButton,
                    const SizedBox(height: 10),
                    sendButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: saveButton),
                  const SizedBox(width: 10),
                  Expanded(child: sendButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicField(TemplateFieldSpec spec) {
    return _TemplateDynamicField(
      spec: spec,
      controller: _fieldControllers[spec.key],
      prefixController: _prefixControllers[spec.key],
      value: _dropdownValues[spec.key],
      onDropdownChanged: (value) {
        setState(() {
          _dropdownValues[spec.key] = value;
        });
      },
      onChanged: (_) => setState(() {}),
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
          const _SectionTitle(
            icon: Icons.visibility_outlined,
            title: 'Podgląd dokumentu',
            subtitle: 'Pola formularza zostaną podstawione dynamicznie.',
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
              preview.trim().isEmpty ? 'Brak treści template.' : preview,
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

  InputDecoration _inputDecoration({
    required ThemeColors theme,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: theme.textColor.withAlpha(150)),
      labelText: label,
      hintText: hint,
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

class _TemplateFillHeader extends ConsumerWidget {
  final String templateName;
  final bool isSaving;
  final bool isSending;
  final String? createdDocumentId;
  final String? createdFormLink;
  final VoidCallback onSave;
  final VoidCallback onSend;

  const _TemplateFillHeader({
    required this.templateName,
    required this.isSaving,
    required this.isSending,
    required this.createdDocumentId,
    required this.createdFormLink,
    required this.onSave,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;

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
                      'Wypełnij template',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      templateName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(150),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (createdDocumentId != null)
                _StatusPill(
                  icon: Icons.check_circle,
                  label: 'Dokument utworzony',
                  color: Colors.green,
                ),
              if (createdFormLink != null)
                _StatusPill(
                  icon: Icons.link,
                  label: 'Link gotowy',
                  color: Colors.green,
                ),
              _SecondaryTemplateButton(
                onPressed: isSending ? null : onSend,
                isLoading: isSending,
                icon: Icons.send_outlined,
                label: 'Wyślij formularz',
              ),
              _PrimaryTemplateButton(
                onPressed: isSaving ? null : onSave,
                isLoading: isSaving,
                icon: Icons.note_add_outlined,
                label: 'Utwórz dokument',
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _TemplateDynamicField extends ConsumerWidget {
  final TemplateFieldSpec spec;
  final TextEditingController? controller;
  final TextEditingController? prefixController;
  final String? value;
  final ValueChanged<String?> onDropdownChanged;
  final ValueChanged<String> onChanged;

  const _TemplateDynamicField({
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
      return _FieldWithHelp(
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
          decoration: _fieldDecoration(
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
      decoration: _fieldDecoration(
        theme: theme,
        label: spec.required ? '${spec.label} *' : spec.label,
        hint: _hintForSpec(spec),
        icon: _iconForSpec(spec),
      ),
    );

    if (!spec.hasEditablePrefix || prefixController == null) {
      return _FieldWithHelp(
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
          decoration: _fieldDecoration(
            theme: theme,
            label: 'Prefix',
            hint: '+48',
            icon: Icons.tag_outlined,
          ),
        );

        if (compact) {
          return _FieldWithHelp(
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

        return _FieldWithHelp(
          spec: spec,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: prefixField,
              ),
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

  IconData _iconForSpec(TemplateFieldSpec spec) {
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

  String _hintForSpec(TemplateFieldSpec spec) {
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

  InputDecoration _fieldDecoration({
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

class _FieldWithHelp extends ConsumerWidget {
  final TemplateFieldSpec spec;
  final Widget child;

  const _FieldWithHelp({
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

class _TemplateFillLinkBox extends ConsumerWidget {
  final String link;
  final String recipientEmail;
  final VoidCallback onCopy;

  const _TemplateFillLinkBox({
    required this.link,
    required this.recipientEmail,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.link,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipientEmail.trim().isEmpty
                      ? 'Formularz klienta został utworzony'
                      : 'Formularz klienta został utworzony dla $recipientEmail',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  link,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(175),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: Icon(
              Icons.copy,
              color: theme.textColor,
              size: 18,
            ),
            label: Text(
              'Kopiuj',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.dashboardBoarder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends ConsumerWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
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

class _NoFieldsBox extends ConsumerWidget {
  const _NoFieldsBox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Text(
        'Dodaj w edytorze pola formularza, np. {...{Imię klienta}...}, {...{E-mail klienta}:[email, required]...}, {...{Telefon}:[phone, prefix:+48]...}, {...{Płeć}:[opt:{man:Mężczyzna, woman:Kobieta}]...}. Segment pomijalny: {...[segment:Dane dodatkowe, skipable]...} treść {...[/segment]...}.',
        style: TextStyle(
          color: theme.textColor.withAlpha(160),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrimaryTemplateButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final String label;

  const _PrimaryTemplateButton({
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: theme.dashboardBoarder.withAlpha(90),
        disabledForegroundColor: theme.textColor.withAlpha(120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            )
          : Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SecondaryTemplateButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final String label;

  const _SecondaryTemplateButton({
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        disabledForegroundColor: theme.textColor.withAlpha(90),
        side: BorderSide(color: theme.dashboardBoarder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            )
          : Icon(icon, color: theme.textColor),
      label: Text(
        label,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TemplateFillError extends ConsumerWidget {
  final String error;
  final VoidCallback onRetry;

  const _TemplateFillError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
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
              'Nie udało się otworzyć template',
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
            _PrimaryTemplateButton(
              onPressed: onRetry,
              isLoading: false,
              icon: Icons.refresh,
              label: 'Spróbuj ponownie',
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateFillInlineError extends ConsumerWidget {
  final String error;
  final VoidCallback onClose;

  const _TemplateFillInlineError({
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

enum TemplateFieldType {
  text,
  email,
  phone,
  number,
  dropdown,
}

class TemplateFieldOption {
  final String value;
  final String label;

  const TemplateFieldOption({
    required this.value,
    required this.label,
  });
}

class TemplateFieldSpec {
  final String key;
  final String label;
  final String rawToken;
  final TemplateFieldType type;
  final int? maxLength;
  final num? min;
  final num? max;
  final bool required;
  final String? defaultPrefix;
  final String? defaultValue;
  final String? helpText;
  final List<TemplateFieldOption> options;
  final String? segmentId;

  const TemplateFieldSpec({
    required this.key,
    required this.label,
    required this.rawToken,
    required this.type,
    this.maxLength,
    this.min,
    this.max,
    this.required = false,
    this.defaultPrefix,
    this.defaultValue,
    this.helpText,
    this.options = const [],
    this.segmentId,
  });

  bool get isDropdown => type == TemplateFieldType.dropdown;

  bool get isNumber => type == TemplateFieldType.number;

  bool get isEmail => type == TemplateFieldType.email;

  bool get isPhone => type == TemplateFieldType.phone;

  bool get hasEditablePrefix =>
      defaultPrefix != null && defaultPrefix!.trim().isNotEmpty;

  TemplateFieldSpec copyWith({
    String? segmentId,
    String? defaultValue,
    String? helpText,
  }) {
    return TemplateFieldSpec(
      key: key,
      label: label,
      rawToken: rawToken,
      type: type,
      maxLength: maxLength,
      min: min,
      max: max,
      required: required,
      defaultPrefix: defaultPrefix,
      defaultValue: defaultValue ?? this.defaultValue,
      helpText: helpText ?? this.helpText,
      options: options,
      segmentId: segmentId ?? this.segmentId,
    );
  }
}

class TemplateSegmentSpec {
  final String id;
  final String label;
  final bool skipable;

  final int start;
  final int end;
  final int contentStart;
  final int contentEnd;
  final int startTokenStart;
  final int startTokenEnd;
  final int endTokenStart;
  final int endTokenEnd;

  final List<String> fieldKeys;

  const TemplateSegmentSpec({
    required this.id,
    required this.label,
    required this.skipable,
    required this.start,
    required this.end,
    required this.contentStart,
    required this.contentEnd,
    required this.startTokenStart,
    required this.startTokenEnd,
    required this.endTokenStart,
    required this.endTokenEnd,
    this.fieldKeys = const [],
  });

  TemplateSegmentSpec copyWith({
    List<String>? fieldKeys,
  }) {
    return TemplateSegmentSpec(
      id: id,
      label: label,
      skipable: skipable,
      start: start,
      end: end,
      contentStart: contentStart,
      contentEnd: contentEnd,
      startTokenStart: startTokenStart,
      startTokenEnd: startTokenEnd,
      endTokenStart: endTokenStart,
      endTokenEnd: endTokenEnd,
      fieldKeys: fieldKeys ?? this.fieldKeys,
    );
  }
}

class TemplateParseResult {
  final List<TemplateFieldSpec> fields;
  final List<TemplateSegmentSpec> segments;

  const TemplateParseResult({
    required this.fields,
    required this.segments,
  });
}

class TemplateFormFieldAdapter {
  static List<TemplateFieldSpec> fromBackendFields(
    List<DocumentTemplateField> fields,
  ) {
    return fields.map(_fromBackendField).whereType<TemplateFieldSpec>().toList();
  }

  static TemplateFieldSpec? _fromBackendField(DocumentTemplateField field) {
    final key = field.key.trim();
    final label = field.label.trim();

    if (key.isEmpty && label.isEmpty) {
      return null;
    }

    final type = _mapBackendFieldType(field.fieldType);
    final validation = field.validation;

    final maxLength = _readInt(
      validation['max_length'] ??
          validation['maxlength'] ??
          validation['maxLength'] ??
          validation['len'],
    );

    final min = _readNum(validation['min']);
    final max = _readNum(validation['max']);

    final prefix = (validation['prefix'] ??
            validation['default_prefix'] ??
            validation['defaultPrefix'])
        ?.toString()
        .trim();

    final options = _mapOptions(field.options);

    return TemplateFieldSpec(
      key: key.isNotEmpty ? key : TemplateFieldParser._slugify(label),
      label: label.isNotEmpty ? label : key,
      rawToken: '',
      type: options.isNotEmpty ? TemplateFieldType.dropdown : type,
      maxLength: maxLength,
      min: min,
      max: max,
      required: field.required,
      defaultPrefix: prefix == null || prefix.isEmpty ? null : prefix,
      defaultValue: field.defaultValue.trim().isEmpty
          ? null
          : field.defaultValue.trim(),
      helpText: field.helpText.trim().isEmpty ? null : field.helpText.trim(),
      options: options,
      segmentId: null,
    );
  }

  static TemplateFieldType _mapBackendFieldType(String rawType) {
    switch (rawType.toLowerCase().trim()) {
      case 'email':
        return TemplateFieldType.email;

      case 'phone':
      case 'tel':
      case 'telephone':
        return TemplateFieldType.phone;

      case 'number':
      case 'money':
      case 'integer':
      case 'decimal':
      case 'float':
        return TemplateFieldType.number;

      case 'select':
      case 'dropdown':
      case 'choice':
      case 'multiselect':
        return TemplateFieldType.dropdown;

      case 'text':
      case 'textarea':
      case 'date':
      case 'datetime':
      case 'checkbox':
      case 'boolean':
      default:
        return TemplateFieldType.text;
    }
  }

  static List<TemplateFieldOption> _mapOptions(List<dynamic> rawOptions) {
    final result = <TemplateFieldOption>[];

    for (final option in rawOptions) {
      if (option is Map) {
        final value = option['value']?.toString() ??
            option['id']?.toString() ??
            option['key']?.toString() ??
            '';

        final label = option['label']?.toString() ??
            option['name']?.toString() ??
            option['title']?.toString() ??
            value;

        if (value.trim().isEmpty) continue;

        result.add(
          TemplateFieldOption(
            value: value.trim(),
            label: label.trim().isEmpty ? value.trim() : label.trim(),
          ),
        );

        continue;
      }

      final value = option.toString().trim();

      if (value.isEmpty) continue;

      result.add(
        TemplateFieldOption(
          value: value,
          label: value,
        ),
      );
    }

    return result;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();

    return int.tryParse(value.toString());
  }

  static num? _readNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;

    return num.tryParse(value.toString().replaceAll(',', '.'));
  }
}

class TemplateFieldParser {
  static final RegExp _fieldRegex = RegExp(
    r'\{\s*(?:\.{3}|…)\s*\{\s*([^{}\[\]\r\n]{1,140}?)\s*\}\s*(?::\s*\[([^\]]*)\]\s*)?(?:\.{3}|…)\s*\}',
    multiLine: true,
  );

  static final RegExp _segmentMarkerRegex = RegExp(
    r'\{\s*(?:\.{3}|…)\s*\[\s*(\/?segment)(?::\s*([^\]]*?))?\s*\]\s*(?:\.{3}|…)\s*\}',
    multiLine: true,
  );

  static TemplateParseResult parseDelta(Map<String, dynamic> deltaJson) {
    final text = plainTextFromDelta(deltaJson);
    return parseText(text);
  }

  static TemplateParseResult parseText(String text) {
    final segments = _parseSegments(text);
    final fieldsByKey = <String, TemplateFieldSpec>{};
    final segmentFieldKeys = <String, List<String>>{};

    for (final segment in segments) {
      segmentFieldKeys[segment.id] = [];
    }

    for (final match in _fieldRegex.allMatches(text)) {
      final label = _stripQuotes(match.group(1)?.trim() ?? '');
      final config = match.group(2)?.trim();

      if (label.isEmpty) continue;

      final segment = _segmentForRange(
        segments: segments,
        start: match.start,
        end: match.end,
      );

      final spec = _parseFieldSpec(
        label: label,
        rawToken: match.group(0) ?? '',
        config: config,
        segmentId: segment?.id,
      );

      if (!fieldsByKey.containsKey(spec.key)) {
        fieldsByKey[spec.key] = spec;
      }

      if (segment != null) {
        segmentFieldKeys[segment.id] ??= [];

        if (!segmentFieldKeys[segment.id]!.contains(spec.key)) {
          segmentFieldKeys[segment.id]!.add(spec.key);
        }
      }
    }

    final fields = fieldsByKey.values.toList();

    fields.sort((a, b) {
      final ap = _priority(a.label);
      final bp = _priority(b.label);

      if (ap != bp) return ap.compareTo(bp);

      return a.label.compareTo(b.label);
    });

    final segmentsWithFields = segments
        .map(
          (segment) => segment.copyWith(
            fieldKeys: segmentFieldKeys[segment.id] ?? const [],
          ),
        )
        .toList();

    return TemplateParseResult(
      fields: fields,
      segments: segmentsWithFields,
    );
  }

  static String plainTextFromDelta(Map<String, dynamic> deltaJson) {
    final ops = deltaJson['ops'];

    if (ops is! List) return '';

    return ops.map((op) {
      if (op is Map && op['insert'] is String) {
        return op['insert'] as String;
      }

      return '';
    }).join();
  }

  static String replaceFieldsInText({
    required String text,
    required Map<String, String> values,
    Set<String> skippedSegmentIds = const {},
  }) {
    final edits = _buildTextEdits(
      text: text,
      values: values,
      skippedSegmentIds: skippedSegmentIds,
    );

    return _applyEditsToString(text, edits);
  }

  static Map<String, dynamic> buildFilledDelta({
    required Map<String, dynamic> deltaJson,
    required Map<String, String> values,
    Set<String> skippedSegmentIds = const {},
  }) {
    final ops = deltaJson['ops'];

    if (ops is! List) {
      return {
        'ops': [
          {'insert': '\n'},
        ],
      };
    }

    final runs = _buildRuns(ops);
    final fullText = _textFromRuns(runs);
    final edits = _buildTextEdits(
      text: fullText,
      values: values,
      skippedSegmentIds: skippedSegmentIds,
    );

    final transformedOps = _applyEditsToRuns(runs, edits);

    if (transformedOps.isEmpty) {
      return {
        'ops': [
          {'insert': '\n'},
        ],
      };
    }

    return {'ops': transformedOps};
  }

  static List<_TextEdit> _buildTextEdits({
    required String text,
    required Map<String, String> values,
    required Set<String> skippedSegmentIds,
  }) {
    final segments = _parseSegments(text);
    final edits = <_TextEdit>[];

    for (final segment in segments) {
      if (skippedSegmentIds.contains(segment.id)) {
        edits.add(
          _TextEdit(
            start: segment.start,
            end: segment.end,
            replacement: '',
            priority: 100,
          ),
        );
      } else {
        edits.add(
          _TextEdit(
            start: segment.startTokenStart,
            end: segment.startTokenEnd,
            replacement: '',
            priority: 50,
          ),
        );
        edits.add(
          _TextEdit(
            start: segment.endTokenStart,
            end: segment.endTokenEnd,
            replacement: '',
            priority: 50,
          ),
        );
      }
    }

    for (final match in _fieldRegex.allMatches(text)) {
      final insideSkippedSegment = segments.any((segment) {
        return skippedSegmentIds.contains(segment.id) &&
            match.start >= segment.start &&
            match.end <= segment.end;
      });

      if (insideSkippedSegment) continue;

      final label = _stripQuotes(match.group(1)?.trim() ?? '');
      final config = match.group(2)?.trim();

      if (label.isEmpty) continue;

      final spec = _parseFieldSpec(
        label: label,
        rawToken: match.group(0) ?? '',
        config: config,
        segmentId: null,
      );

      final value = values[spec.key]?.trim();
      final replacement = value == null || value.isEmpty ? '______' : value;

      edits.add(
        _TextEdit(
          start: match.start,
          end: match.end,
          replacement: replacement,
          priority: 10,
        ),
      );
    }

    return _normalizeEdits(edits);
  }

  static List<TemplateSegmentSpec> _parseSegments(String text) {
    final result = <TemplateSegmentSpec>[];
    final stack = <_OpenSegment>[];

    for (final match in _segmentMarkerRegex.allMatches(text)) {
      final marker = (match.group(1) ?? '').trim().toLowerCase();
      final config = match.group(2)?.trim();

      if (marker == 'segment') {
        final parsed = _parseSegmentConfig(
          config: config,
          fallbackIndex: stack.length + result.length + 1,
        );

        stack.add(
          _OpenSegment(
            label: parsed.label,
            skipable: parsed.skipable,
            startTokenStart: match.start,
            startTokenEnd: match.end,
          ),
        );
      }

      if (marker == '/segment' && stack.isNotEmpty) {
        final open = stack.removeLast();
        final id = '${_slugify(open.label)}_${open.startTokenStart}';

        result.add(
          TemplateSegmentSpec(
            id: id,
            label: open.label,
            skipable: open.skipable,
            start: open.startTokenStart,
            end: match.end,
            contentStart: open.startTokenEnd,
            contentEnd: match.start,
            startTokenStart: open.startTokenStart,
            startTokenEnd: open.startTokenEnd,
            endTokenStart: match.start,
            endTokenEnd: match.end,
          ),
        );
      }
    }

    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  static _ParsedSegmentConfig _parseSegmentConfig({
    required String? config,
    required int fallbackIndex,
  }) {
    var label = 'Sekcja $fallbackIndex';
    var skipable = false;
    var hasCustomLabel = false;

    final parts = _splitTopLevel(config ?? '');

    for (final rawPart in parts) {
      final part = rawPart.trim();

      if (part.isEmpty) continue;

      final lower = part.toLowerCase();

      if (lower == 'skipable' ||
          lower == 'skippable' ||
          lower == 'optional' ||
          lower == 'skip') {
        skipable = true;
        continue;
      }

      final separatorIndex = part.indexOf(':');

      if (separatorIndex != -1) {
        final name = part.substring(0, separatorIndex).trim().toLowerCase();
        final value = part.substring(separatorIndex + 1).trim();

        if (name == 'label' || name == 'title' || name == 'name') {
          label = _stripQuotes(value);
          hasCustomLabel = true;
          continue;
        }

        if (name == 'skipable' || name == 'skippable' || name == 'optional') {
          skipable = _parseBool(value);
          continue;
        }
      }

      if (!hasCustomLabel) {
        label = _stripQuotes(part);
        hasCustomLabel = true;
      }
    }

    return _ParsedSegmentConfig(
      label: label.trim().isEmpty ? 'Sekcja $fallbackIndex' : label.trim(),
      skipable: skipable,
    );
  }

  static TemplateSegmentSpec? _segmentForRange({
    required List<TemplateSegmentSpec> segments,
    required int start,
    required int end,
  }) {
    TemplateSegmentSpec? best;

    for (final segment in segments) {
      final inside = start >= segment.contentStart && end <= segment.contentEnd;

      if (!inside) continue;

      if (best == null ||
          (segment.contentEnd - segment.contentStart) <
              (best.contentEnd - best.contentStart)) {
        best = segment;
      }
    }

    return best;
  }

  static TemplateFieldSpec _parseFieldSpec({
    required String label,
    required String rawToken,
    required String? config,
    required String? segmentId,
  }) {
    var type = TemplateFieldType.text;
    int? maxLength;
    num? min;
    num? max;
    var required = false;
    String? defaultPrefix;
    String? explicitKey;
    String? labelOverride;
    var options = <TemplateFieldOption>[];

    final parts = _splitTopLevel(config ?? '');

    for (final rawPart in parts) {
      final part = rawPart.trim();

      if (part.isEmpty) continue;

      final lower = part.toLowerCase();

      if (lower == 'required' || lower == 'req') {
        required = true;
        continue;
      }

      if (lower == 'text' || lower == 'char' || lower == 'string') {
        type = TemplateFieldType.text;
        continue;
      }

      if (lower == 'email' || lower == 'mail') {
        type = TemplateFieldType.email;
        continue;
      }

      if (lower == 'phone' || lower == 'tel' || lower == 'telephone') {
        type = TemplateFieldType.phone;
        continue;
      }

      if (lower == 'number' ||
          lower == 'num' ||
          lower == 'int' ||
          lower == 'decimal') {
        type = TemplateFieldType.number;
        continue;
      }

      final separatorIndex = part.indexOf(':');

      if (separatorIndex == -1) continue;

      final name = part.substring(0, separatorIndex).trim().toLowerCase();
      final value = part.substring(separatorIndex + 1).trim();

      switch (name) {
        case 'key':
        case 'id':
        case 'field':
          explicitKey = _slugify(_stripQuotes(value));
          break;

        case 'label':
        case 'title':
          labelOverride = _stripQuotes(value);
          break;

        case 'len':
        case 'maxlen':
        case 'maxlength':
        case 'max_length':
          maxLength = int.tryParse(_stripQuotes(value));
          break;

        case 'min':
          min = num.tryParse(_stripQuotes(value).replaceAll(',', '.'));
          break;

        case 'max':
          max = num.tryParse(_stripQuotes(value).replaceAll(',', '.'));
          break;

        case 'prefix':
          defaultPrefix = _stripQuotes(value);
          break;

        case 'type':
          final parsedType = _parseType(value);

          if (parsedType != null) {
            type = parsedType;
          }
          break;

        case 'opt':
        case 'opts':
        case 'option':
        case 'options':
        case 'select':
        case 'dropdown':
          options = _parseOptions(value);

          if (options.isNotEmpty) {
            type = TemplateFieldType.dropdown;
          }
          break;
      }
    }

    final finalLabel = labelOverride?.trim().isNotEmpty == true
        ? labelOverride!.trim()
        : label.trim();

    final key = explicitKey?.trim().isNotEmpty == true
        ? explicitKey!.trim()
        : _slugify(finalLabel);

    return TemplateFieldSpec(
      key: key,
      label: finalLabel,
      rawToken: rawToken,
      type: type,
      maxLength: maxLength,
      min: min,
      max: max,
      required: required,
      defaultPrefix: defaultPrefix,
      defaultValue: null,
      helpText: null,
      options: options,
      segmentId: segmentId,
    );
  }

  static TemplateFieldType? _parseType(String raw) {
    final value = _stripQuotes(raw).toLowerCase().trim();

    switch (value) {
      case 'text':
      case 'char':
      case 'string':
        return TemplateFieldType.text;

      case 'email':
      case 'mail':
        return TemplateFieldType.email;

      case 'phone':
      case 'tel':
      case 'telephone':
        return TemplateFieldType.phone;

      case 'number':
      case 'num':
      case 'int':
      case 'decimal':
        return TemplateFieldType.number;

      case 'select':
      case 'dropdown':
      case 'option':
      case 'options':
      case 'opt':
        return TemplateFieldType.dropdown;
    }

    return null;
  }

  static List<TemplateFieldOption> _parseOptions(String raw) {
    var value = raw.trim();

    if (value.startsWith('{') && value.endsWith('}')) {
      value = value.substring(1, value.length - 1);
    }

    final parts = _splitTopLevel(value);
    final options = <TemplateFieldOption>[];

    for (final rawPart in parts) {
      final part = rawPart.trim();

      if (part.isEmpty) continue;

      final separatorIndex = part.indexOf(':');

      if (separatorIndex == -1) {
        final optionValue = _stripQuotes(part);

        options.add(
          TemplateFieldOption(
            value: optionValue,
            label: _humanize(optionValue),
          ),
        );
      } else {
        final optionValue = _stripQuotes(
          part.substring(0, separatorIndex).trim(),
        );
        final optionLabel = _stripQuotes(
          part.substring(separatorIndex + 1).trim(),
        );

        options.add(
          TemplateFieldOption(
            value: optionValue,
            label: optionLabel,
          ),
        );
      }
    }

    return options;
  }

  static List<String> _splitTopLevel(String input) {
    final result = <String>[];
    final buffer = StringBuffer();

    var curly = 0;
    var square = 0;
    var round = 0;
    String? quote;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (quote != null) {
        buffer.write(char);

        if (char == quote && (i == 0 || input[i - 1] != '\\')) {
          quote = null;
        }

        continue;
      }

      if (char == '"' || char == "'") {
        quote = char;
        buffer.write(char);
        continue;
      }

      if (char == '{') curly++;
      if (char == '}') curly--;
      if (char == '[') square++;
      if (char == ']') square--;
      if (char == '(') round++;
      if (char == ')') round--;

      if (char == ',' && curly == 0 && square == 0 && round == 0) {
        result.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    final rest = buffer.toString().trim();

    if (rest.isNotEmpty) {
      result.add(rest);
    }

    return result;
  }

  static String _stripQuotes(String value) {
    var result = value.trim();

    if (result.length >= 2) {
      final first = result[0];
      final last = result[result.length - 1];

      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        result = result.substring(1, result.length - 1);
      }
    }

    return result.trim();
  }

  static bool _parseBool(String value) {
    final normalized = _stripQuotes(value).toLowerCase().trim();

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'tak';
  }

  static String _slugify(String value) {
    var text = value.toLowerCase().trim();

    const replacements = {
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ż': 'z',
      'ź': 'z',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    text = text.replaceAll(RegExp(r'^_+|_+$'), '');

    if (text.isEmpty) return 'field';

    if (!RegExp(r'^[a-z]').hasMatch(text)) {
      text = 'field_$text';
    }

    return text;
  }

  static String _humanize(String key) {
    final text = key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('.', ' ')
        .trim();

    if (text.isEmpty) return key;

    return text[0].toUpperCase() + text.substring(1);
  }

  static int _priority(String label) {
    final key = _slugify(label);

    const priorities = {
      'imie': 0,
      'imie_klienta': 1,
      'nazwisko': 2,
      'nazwa_klienta': 3,
      'email': 4,
      'e_mail': 5,
      'e_mail_klienta': 6,
      'telefon': 7,
      'telefon_klienta': 8,
      'firma': 9,
      'nazwa_firmy': 10,
      'plec': 11,
      'opiekun': 12,
    };

    return priorities[key] ?? 999;
  }

  static String _applyEditsToString(String text, List<_TextEdit> edits) {
    var result = text;

    final sorted = edits.toList()
      ..sort((a, b) {
        final byStart = b.start.compareTo(a.start);

        if (byStart != 0) return byStart;

        return b.priority.compareTo(a.priority);
      });

    for (final edit in sorted) {
      if (edit.start < 0 || edit.end > result.length || edit.start > edit.end) {
        continue;
      }

      result = result.replaceRange(edit.start, edit.end, edit.replacement);
    }

    return result.trim();
  }

  static List<_TextEdit> _normalizeEdits(List<_TextEdit> edits) {
    final sorted = edits.toList()
      ..sort((a, b) {
        final byStart = a.start.compareTo(b.start);

        if (byStart != 0) return byStart;

        final byPriority = b.priority.compareTo(a.priority);

        if (byPriority != 0) return byPriority;

        return b.end.compareTo(a.end);
      });

    final result = <_TextEdit>[];
    var cursor = -1;

    for (final edit in sorted) {
      if (edit.start < cursor) continue;

      result.add(edit);
      cursor = edit.end;
    }

    return result;
  }

  static List<_TextRun> _buildRuns(List<dynamic> ops) {
    final runs = <_TextRun>[];
    var cursor = 0;

    for (final op in ops) {
      if (op is! Map) continue;

      final insert = op['insert'];
      final attributes = op['attributes'] is Map
          ? Map<String, dynamic>.from(op['attributes'] as Map)
          : null;

      if (insert is String) {
        final start = cursor;
        final end = cursor + insert.length;

        runs.add(
          _TextRun(
            start: start,
            end: end,
            text: insert,
            insert: insert,
            attributes: attributes,
          ),
        );

        cursor = end;
      } else if (insert != null) {
        final start = cursor;
        final end = cursor + 1;

        runs.add(
          _TextRun(
            start: start,
            end: end,
            text: null,
            insert: insert,
            attributes: attributes,
          ),
        );

        cursor = end;
      }
    }

    return runs;
  }

  static String _textFromRuns(List<_TextRun> runs) {
    final buffer = StringBuffer();

    for (final run in runs) {
      if (run.text != null) {
        buffer.write(run.text);
      } else {
        buffer.write('\uFFFC');
      }
    }

    return buffer.toString();
  }

  static List<Map<String, dynamic>> _applyEditsToRuns(
    List<_TextRun> runs,
    List<_TextEdit> edits,
  ) {
    final result = <Map<String, dynamic>>[];
    final normalized = _normalizeEdits(edits);

    var cursor = 0;
    final fullLength = runs.isEmpty ? 0 : runs.last.end;

    for (final edit in normalized) {
      if (edit.start > cursor) {
        _copyOriginalRange(
          runs: runs,
          output: result,
          start: cursor,
          end: edit.start,
        );
      }

      if (edit.replacement.isNotEmpty) {
        _addTextOp(
          result,
          edit.replacement,
          _attributesAtPosition(runs, edit.start),
        );
      }

      cursor = edit.end;
    }

    if (cursor < fullLength) {
      _copyOriginalRange(
        runs: runs,
        output: result,
        start: cursor,
        end: fullLength,
      );
    }

    return result;
  }

  static void _copyOriginalRange({
    required List<_TextRun> runs,
    required List<Map<String, dynamic>> output,
    required int start,
    required int end,
  }) {
    if (start >= end) return;

    for (final run in runs) {
      final intersectionStart = start > run.start ? start : run.start;
      final intersectionEnd = end < run.end ? end : run.end;

      if (intersectionStart >= intersectionEnd) continue;

      if (run.text != null) {
        final localStart = intersectionStart - run.start;
        final localEnd = intersectionEnd - run.start;

        _addTextOp(
          output,
          run.text!.substring(localStart, localEnd),
          run.attributes,
        );
      } else {
        if (intersectionStart <= run.start && intersectionEnd >= run.end) {
          _addRawOp(output, run.insert, run.attributes);
        }
      }
    }
  }

  static Map<String, dynamic>? _attributesAtPosition(
    List<_TextRun> runs,
    int position,
  ) {
    for (final run in runs) {
      if (position >= run.start && position < run.end) {
        return run.attributes;
      }
    }

    if (runs.isNotEmpty) {
      return runs.last.attributes;
    }

    return null;
  }

  static void _addTextOp(
    List<Map<String, dynamic>> output,
    String text,
    Map<String, dynamic>? attributes,
  ) {
    if (text.isEmpty) return;

    final normalizedAttributes =
        attributes == null || attributes.isEmpty ? null : attributes;

    if (output.isNotEmpty &&
        output.last['insert'] is String &&
        _sameAttributes(
          output.last['attributes'] is Map
              ? Map<String, dynamic>.from(output.last['attributes'] as Map)
              : null,
          normalizedAttributes,
        )) {
      output.last['insert'] = '${output.last['insert']}$text';
      return;
    }

    final op = <String, dynamic>{'insert': text};

    if (normalizedAttributes != null) {
      op['attributes'] = Map<String, dynamic>.from(normalizedAttributes);
    }

    output.add(op);
  }

  static void _addRawOp(
    List<Map<String, dynamic>> output,
    dynamic insert,
    Map<String, dynamic>? attributes,
  ) {
    final op = <String, dynamic>{'insert': insert};

    if (attributes != null && attributes.isNotEmpty) {
      op['attributes'] = Map<String, dynamic>.from(attributes);
    }

    output.add(op);
  }

  static bool _sameAttributes(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    final aa = a == null || a.isEmpty ? null : a;
    final bb = b == null || b.isEmpty ? null : b;

    if (aa == null && bb == null) return true;
    if (aa == null || bb == null) return false;
    if (aa.length != bb.length) return false;

    for (final key in aa.keys) {
      if (!bb.containsKey(key)) return false;
      if (bb[key] != aa[key]) return false;
    }

    return true;
  }
}

class _OpenSegment {
  final String label;
  final bool skipable;
  final int startTokenStart;
  final int startTokenEnd;

  const _OpenSegment({
    required this.label,
    required this.skipable,
    required this.startTokenStart,
    required this.startTokenEnd,
  });
}

class _ParsedSegmentConfig {
  final String label;
  final bool skipable;

  const _ParsedSegmentConfig({
    required this.label,
    required this.skipable,
  });
}

class _TextEdit {
  final int start;
  final int end;
  final String replacement;
  final int priority;

  const _TextEdit({
    required this.start,
    required this.end,
    required this.replacement,
    required this.priority,
  });
}

class _TextRun {
  final int start;
  final int end;
  final String? text;
  final dynamic insert;
  final Map<String, dynamic>? attributes;

  const _TextRun({
    required this.start,
    required this.end,
    required this.text,
    required this.insert,
    required this.attributes,
  });
}