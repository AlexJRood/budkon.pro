import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/emma/docs_emma_service.dart';
import 'package:emma/provider/context.dart' show emmaContextProvider;
import 'package:emma/provider/docs_emma_state.dart';
import 'package:emma/screens/emma_inline.dart';
import 'package:emma/tools/emma_overlay_manager.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/back_button.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:country_code_picker/country_code_picker.dart';

import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/api/doc_web_socket.dart';
import 'package:docs/models/document.dart';
import 'package:docs/models/document_temp.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/provider/docs_toolbar_provider.dart';
import 'package:docs/provider/document_page_setup_provider.dart';
import 'package:docs/provider/template_provider.dart';

import 'package:docs/widgets/desktop/create_template_dialog.dart';
import 'package:docs/widgets/doc_editor_with_floating_toolbar.dart';
import 'package:docs/widgets/docs_quill_toolbar.dart';
import 'package:docs/widgets/document_editing_widget.dart';
import 'package:docs/widgets/document_exporter.dart';
import 'package:docs/widgets/document_page_break.dart';
import 'package:docs/widgets/document_page_setup_dialog.dart';
import 'package:docs/widgets/document_title_editor_widget.dart';
import 'package:docs/widgets/mobile/create_template_sheet.dart';
import 'package:docs/widgets/mobile/docs_mobile_toolbar_strip.dart';

import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/values.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:universal_platform/universal_platform.dart';

class SaveEditorIntent extends Intent {
  const SaveEditorIntent();
}

class PrintDocumentIntent extends Intent {
  const PrintDocumentIntent();
}

class GeneratePdfIntent extends Intent {
  const GeneratePdfIntent();
}

class OpenPageSetupIntent extends Intent {
  const OpenPageSetupIntent();
}

class NewPageIntent extends Intent {
  const NewPageIntent();
}

class OpenDocumentsLibraryIntent extends Intent {
  const OpenDocumentsLibraryIntent();
}

class OpenTemplatesLibraryIntent extends Intent {
  const OpenTemplatesLibraryIntent();
}

class CreateBlankDocumentIntent extends Intent {
  const CreateBlankDocumentIntent();
}

class InsertPageBreakIntent extends Intent {
  const InsertPageBreakIntent();
}

class ApplyHeading1Intent extends Intent {
  const ApplyHeading1Intent();
}

class ApplyHeading2Intent extends Intent {
  const ApplyHeading2Intent();
}

class ApplyHeading3Intent extends Intent {
  const ApplyHeading3Intent();
}

class ToggleBulletListIntent extends Intent {
  const ToggleBulletListIntent();
}

class ToggleOrderedListIntent extends Intent {
  const ToggleOrderedListIntent();
}

class ClearFormattingIntent extends Intent {
  const ClearFormattingIntent();
}


class RestorePreviousEditorScrollIntent extends Intent {
  const RestorePreviousEditorScrollIntent();
}

class AlignWritingPageIntent extends Intent {
  const AlignWritingPageIntent();
}

class SelectAllInDocumentIntent extends Intent {
  const SelectAllInDocumentIntent();
}

class SelectCurrentPageIntent extends Intent {
  const SelectCurrentPageIntent();
}



class DocumentEditorScreen extends ConsumerStatefulWidget {
  final dynamic routeData;
  final String? routeDocumentId;
  final String? routeTemplateId;
  final DocumentTemplate? routeTemplate;
  final String? routeMode;
  final bool routeCreateBlank;
  final bool routeIsEditingTemplate;

  const DocumentEditorScreen({
    super.key,
    this.routeData,
    this.routeDocumentId,
    this.routeTemplateId,
    this.routeTemplate,
    this.routeMode,
    this.routeCreateBlank = false,
    this.routeIsEditingTemplate = false,
  });

  @override
  ConsumerState<DocumentEditorScreen> createState() =>
      _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  late QuillController _controller;

  final _editorFocusNode = FocusNode(debugLabel: 'docs_editor_focus');
  final searchFocusNode = FocusNode(debugLabel: 'docs_search_focus');
  final _editorScrollController = ScrollController();
  double _editorFitScale = 1.0;
  final sideMenuKey = GlobalKey<SideMenuState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  DocumentWebSocketService? _webSocketService;

  bool _isInitialized = false;
  bool _isApplyingRemoteUpdate = false;
  bool _isNormalizingPageBreakSelection = false;
  bool _isFocused = false;
  bool _toolbarBound = false;

  bool _isEditingTemplateMode = false;
  String? _editingTemplateId;
  String? _editingTemplateName;

  bool _suppressControllerListener = false;
  bool _hasLocalUnsavedChanges = false;
  bool _isManualSaving = false;
  
  bool _screenDisposed = false;
  int _lifecycleToken = 0;


  bool _isDocumentHeaderVisible = true;

  DateTime? _lastLocalEditAt;

  int _editorRevision = 0;

  Delta? _lastSentDelta;

  Timer? _debounceTimer;
  Timer? _cursorDebounceTimer;

  static const _debounceDelay = Duration(milliseconds: 450);
  static const _remoteEchoGracePeriod = Duration(milliseconds: 1200);

  final Map<String, String> _placeholderValues = {};

  ProviderSubscription<AsyncValue<Documents?>>? _docSub;
  ProviderSubscription<DocsEmmaState>? _emmaSub;

  bool _emmaVisible = false;

  Timer? _selectionDebounceTimer;

  String? _routeContactId;
  String? _routeContactType;



  static const double _docsPageGap = 34.0;
  static const double _docsDesktopVerticalPadding = 30.0;
  static const double _docsMobileVerticalPadding = 18.0;
  double? _scrollBeforeAutoPageAlign;
  DateTime? _lastAutoPageAlignAt;




bool _isAlive([int? token]) {
  if (_screenDisposed) return false;
  if (!mounted) return false;
  if (token != null && token != _lifecycleToken) return false;
  return true;
}

int _effectiveLifecycleToken(int? token) {
  return token ?? _lifecycleToken;
}

String? _extractDocumentIdFromArgs(dynamic args) {
  if (args == null) return null;

  if (args is String && args.trim().isNotEmpty) {
    return args.trim();
  }

  if (args is Documents) {
    return args.id.toString();
  }

  if (args is Map) {
    final directId = _argString(args, 'documentId') ??
        _argString(args, 'document_id') ??
        _argString(args, 'docId') ??
        _argString(args, 'doc_id') ??
        _argString(args, 'document_id') ??
        _argString(args, 'documentId') ??
        _argString(args, 'id');

    if (directId != null) {
      return directId;
    }

    final documentValue = args['document'];

    if (documentValue is Documents) {
      return documentValue.id.toString();
    }

    if (documentValue is String && documentValue.trim().isNotEmpty) {
      return documentValue.trim();
    }

    if (documentValue is Map) {
      final documentMap = Map<String, dynamic>.from(documentValue);

      final nestedId = documentMap['id'] ??
          documentMap['documentId'] ??
          documentMap['document_id'] ??
          documentMap['docId'] ??
          documentMap['doc_id'];

      if (nestedId != null && nestedId.toString().trim().isNotEmpty) {
        return nestedId.toString().trim();
      }
    }
  }

  return null;
}






@override
void initState() {
  super.initState();

  _initializeController();

  _docSub = ref.listenManual<AsyncValue<Documents?>>(
    documentProvider,
    (previous, next) {
      if (!_isAlive()) return;
      if (_isApplyingRemoteUpdate) return;

      next.whenData((document) {
        if (!_isAlive()) return;
        if (document == null) return;

        final newDelta = _deltaFromMap(document.currentDelta);

        if (!_isInitialized) {
          debugPrint('Initializing from Riverpod listener');

          _updateControllerContent(newDelta);

          if (!_isAlive()) return;

          _isInitialized = true;
          _lastSentDelta = newDelta;
          _hasLocalUnsavedChanges = false;
          return;
        }

        final currentDelta = _controller.document.toDelta();

        if (_areDeltasEqual(currentDelta, newDelta)) {
          _lastSentDelta = newDelta;
          _hasLocalUnsavedChanges = false;

          if (_isAlive()) {
            setState(() {
              _editorRevision++;
            });
          }

          debugPrint('Save confirmed by backend');
          return;
        }

        if (_shouldIgnoreIncomingDelta(newDelta)) {
          return;
        }

        final isDifferentFromLastSent =
            !_areDeltasEqual(newDelta, _lastSentDelta ?? Delta());

        if (isDifferentFromLastSent) {
          debugPrint('Applying remote changes');
          _updateControllerContent(newDelta);
          _lastSentDelta = newDelta;
          _hasLocalUnsavedChanges = false;
        } else {
          debugPrint('Skipping remote update');
        }
      });
    },
  );

  _emmaSub = ref.listenManual<DocsEmmaState>(
    docsEmmaProvider,
    (previous, next) {
      if (!_isAlive()) return;
      final pending = next.pendingTextEdit;
      if (pending != null && pending != previous?.pendingTextEdit) {
        _applyEmmaTextEdit(pending);
      }
    },
  );

  // Close any floating Emma overlay and register a side-panel interceptor so
  // that future openEmmaOverlay calls (e.g. from the sidebar) toggle the panel
  // instead of opening a duplicate floating window.
  EmmaOverlayManager.closeActive();
  EmmaOverlayManager.setInterceptor(
    () => setState(() => _emmaVisible = !_emmaVisible),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final token = ++_lifecycleToken;

    if (!_isAlive(token)) return;

    _bindDocsToolbar();

    if (!_isAlive(token)) return;

    await _initializeDocument(lifecycleToken: token);
  });

  _editorFocusNode.addListener(() {
    if (!_isAlive()) return;

    _isFocused = _editorFocusNode.hasFocus;
  });
}




int _currentWritingPageIndex() {
  final selection = _controller.selection;
  final plainText = _controller.document.toPlainText();

  final rawOffset = selection.extentOffset >= 0
      ? selection.extentOffset
      : selection.baseOffset >= 0
          ? selection.baseOffset
          : plainText.length;

  final safeOffset = rawOffset.clamp(0, plainText.length).toInt();

  final pageIndex = DocumentPageBreakTools.countBeforeOffset(
    _controller.document.toDelta(),
    safeOffset,
  );

  return pageIndex.clamp(0, 999999).toInt();
}

double _targetScrollOffsetForPageIndex({
  required int pageIndex,
  required DocumentPageSetup pageSetup,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isCompact = screenWidth < 700;

  final verticalPadding =
      isCompact ? _docsMobileVerticalPadding : _docsDesktopVerticalPadding;

  final pageStride = (pageSetup.heightPx + _docsPageGap) * _editorFitScale;

  final pageTop =
      verticalPadding * _editorFitScale + pageIndex * pageStride;

  // Mały offset, żeby kartka nie była przyklejona piksel w piksel do góry.
  return math.max(0, pageTop - 8).toDouble();
}

void _rememberScrollBeforeAutoAlign() {
  if (!_editorScrollController.hasClients) return;

  _scrollBeforeAutoPageAlign = _editorScrollController.position.pixels;
  _lastAutoPageAlignAt = DateTime.now();
}

Future<void> _alignScrollToWritingPage({
  bool rememberPrevious = true,
  bool animate = true,
}) async {
  if (!_isAlive()) return;

  if (!_editorScrollController.hasClients) {
    return;
  }

  if (rememberPrevious) {
    _rememberScrollBeforeAutoAlign();
  }

  // Czekamy chwilę, bo page break embed dopiero po layoucie liczy wysokość.
  await Future<void>.delayed(const Duration(milliseconds: 48));

  if (!_isAlive()) return;
  if (!_editorScrollController.hasClients) return;

  final pageSetup = ref.read(documentPageSetupProvider);
  final pageIndex = _currentWritingPageIndex();

  final rawTarget = _targetScrollOffsetForPageIndex(
    pageIndex: pageIndex,
    pageSetup: pageSetup,
  );

  final position = _editorScrollController.position;

  final safeTarget = rawTarget
      .clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      )
      .toDouble();

  if ((position.pixels - safeTarget).abs() < 2) {
    _editorFocusNode.requestFocus();
    return;
  }

  if (animate) {
    await _editorScrollController.animateTo(
      safeTarget,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  } else {
    _editorScrollController.jumpTo(safeTarget);
  }

  if (!_isAlive()) return;

  _editorFocusNode.requestFocus();
}

Future<void> _restoreScrollBeforeAutoAlign() async {
  if (!_isAlive()) return;
  if (!_editorScrollController.hasClients) return;

  final previousOffset = _scrollBeforeAutoPageAlign;

  if (previousOffset == null) {
    _showSnackBar(
      message: 'Brak poprzedniej pozycji scrolla.',
      backgroundColor: Colors.orange,
    );
    return;
  }

  final position = _editorScrollController.position;

  final safeOffset = previousOffset
      .clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      )
      .toDouble();

  _scrollBeforeAutoPageAlign = null;
  _lastAutoPageAlignAt = null;

  await _editorScrollController.animateTo(
    safeOffset,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  );

  if (!_isAlive()) return;

  _editorFocusNode.requestFocus();
}




  void _initializeController() {
    _controller = QuillController(
      document: Document()..insert(0, '\n'),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _controller.addListener(_onTextChange);
  }

  void _bindDocsToolbar() {
    if (_toolbarBound) return;

    _toolbarBound = true;

    ref.read(docsToolbarProvider.notifier).bind(
          controller: _controller,
          editorFocusNode: _editorFocusNode,
          onMyDocumentPressed: _onMyDocumentsPressed,
          onCreateTemplatePressed: _onCreateTemplatePressed,
          onGeneratePressed: _generateDocument,
          onSavePressed: _saveCurrentEditorState,
          onInsertPageBreakPressed: _insertPageBreak,
          onNewPagePressed: _insertNewPage,
          onPrintPressed: _printDocument,
          onPageSetupPressed: _openPageSetup,
        );
  }

  String? _argString(dynamic data, String key) {
    if (data is Map) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }

  DocumentTemplate? _argTemplate(dynamic data) {
    if (data is DocumentTemplate) {
      return data;
    }

    if (data is Map) {
      final value = data['template'];

      if (value is DocumentTemplate) {
        return value;
      }

      if (value is Map) {
        return DocumentTemplate.fromJson(Map<String, dynamic>.from(value));
      }
    }

    return null;
  }

  bool _argBool(
    dynamic data,
    String key, {
    bool fallback = false,
  }) {
    if (data is Map) {
      final value = data[key];

      if (value is bool) return value;

      if (value is String) {
        final normalized = value.toLowerCase().trim();

        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }

        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }

    return fallback;
  }

  List<dynamic> _normalizePageBreakOps(List<dynamic> ops) {
    final normalized = <dynamic>[];

    Map<String, dynamic> textOp(
      String text,
      dynamic attributes,
    ) {
      final op = <String, dynamic>{
        'insert': text,
      };

      if (attributes != null) {
        op['attributes'] = attributes;
      }

      return op;
    }

    Map<String, dynamic> pageBreakEmbedOp() {
      return {
        'insert': {
          'custom': {
            'type': DocumentPageBreakTools.embedType,
            'data': '',
          },
        },
      };
    }

    for (final rawOp in ops) {
      if (rawOp is! Map) {
        normalized.add(rawOp);
        continue;
      }

      final op = Map<String, dynamic>.from(rawOp);
      final insert = op['insert'];

      if (insert is! String) {
        normalized.add(op);
        continue;
      }

      final matches =
          DocumentPageBreakTools.legacyTextRegex.allMatches(insert).toList();

      if (matches.isEmpty) {
        normalized.add(op);
        continue;
      }

      final attributes = op['attributes'];
      var cursor = 0;

      for (final match in matches) {
        final before = insert.substring(cursor, match.start);

        if (before.isNotEmpty) {
          normalized.add(textOp(before, attributes));
        }

        normalized.add({'insert': '\n'});
        normalized.add(pageBreakEmbedOp());
        normalized.add({'insert': '\n\n'});

        cursor = match.end;
      }

      final after = insert.substring(cursor);

      if (after.isNotEmpty) {
        normalized.add(textOp(after, attributes));
      }
    }

    return normalized;
  }

  Delta _deltaFromMap(Map<String, dynamic>? deltaJson) {
    try {
      final ops = deltaJson?['ops'];

      if (ops is List<dynamic>) {
        final normalizedOps = _normalizePageBreakOps(ops);
        return Delta.fromJson(normalizedOps);
      }

      if (ops is List) {
        final normalizedOps = _normalizePageBreakOps(ops.toList());
        return Delta.fromJson(normalizedOps);
      }
    } catch (e) {
      debugPrint('Error parsing delta: $e');
    }

    return Delta()..insert('\n');
  }


  bool _shouldIgnoreIncomingDelta(Delta incomingDelta) {
    if (_isEditingTemplateMode) {
      return true;
    }

    final lastEditAt = _lastLocalEditAt;
    final isFreshLocalEdit = lastEditAt != null &&
        DateTime.now().difference(lastEditAt) < _remoteEchoGracePeriod;

    final currentDelta = _controller.document.toDelta();

    // If backend sends exactly what we already have, it is not a remote edit.
    // It is probably an ACK/save confirmation handled in the listener.
    if (_areDeltasEqual(currentDelta, incomingDelta)) {
      return false;
    }

    // Snapshot-based collaboration protection:
    // do not replace local editor while user is actively typing.
    // Later, with OT/CRDT, this should be removed.
    if (_editorFocusNode.hasFocus &&
        isFreshLocalEdit &&
        _hasLocalUnsavedChanges) {
      debugPrint('Skipping incoming delta while user is actively typing');
      return true;
    }

    return false;
  }

  void _resetEditorRuntimeState({
    required bool isEditingTemplate,
    String? templateId,
    String? templateName,
  }) {
    _isInitialized = false;
    _lastSentDelta = null;
    _isApplyingRemoteUpdate = false;
    _suppressControllerListener = false;
    _hasLocalUnsavedChanges = false;
    _lastLocalEditAt = null;
    _isManualSaving = false;

    _isEditingTemplateMode = isEditingTemplate;
    _editingTemplateId = templateId;
    _editingTemplateName = templateName;
    _placeholderValues.clear();

    if (mounted) {
      setState(() {
        _editorRevision++;
      });
    }
  }

  void _onPlaceholderValueChanged(String key, String value) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _placeholderValues[key] = value;
      });

      _replacePlaceholderInEditor(key, value);

      debugPrint('Placeholder $key updated to: $value');
    });
  }

  void _replacePlaceholderInEditor(String key, String value) {
    final plainText = _controller.document.toPlainText();
    final reg = RegExp(r'\{\{\s*' + RegExp.escape(key) + r'\s*\}\}');
    final matches = reg.allMatches(plainText).toList();

    if (matches.isEmpty) return;

    _suppressControllerListener = true;

    try {
      for (final match in matches.reversed) {
        _controller.replaceText(
          match.start,
          match.end - match.start,
          value,
          TextSelection.collapsed(offset: match.start + value.length),
        );
      }
    } finally {
      _suppressControllerListener = false;
    }

    _onTextChange();
    _requestEditorFocus();
  }

  Future<void> _onMyDocumentsPressed() async {
    _navigateToDocuments();
  }



  Future<void> _onCreateTemplatePressed() async {
  if (!_isAlive()) return;

  final isMobile = MediaQuery.sizeOf(context).width < 600;

  final templateMap = isMobile
      ? await showCreateTemplateSheet(context)
      : await showDialog<Map<String, dynamic>?>(
          context: context,
          builder: (_) => const CreateTemplateDialog(),
        );

  if (!_isAlive()) return;
  if (templateMap == null) return;

  final template = templateMap['template'];

  if (template is! DocumentTemplate) {
    _showSnackBar(
      message: 'Nie udało się odczytać utworzonej template.',
      backgroundColor: Colors.red,
    );
    return;
  }

  final freshTemplate = await DocumentService.getTemplate(
    template.id.toString(),
    ref,
  );

  if (!_isAlive()) return;

  await _loadDocument(
    template: freshTemplate,
    isEditingTemplate: true,
  );
}





  Future<Map<String, dynamic>?> showCreateTemplateSheet(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.40,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return CreateTemplateSheet(scrollController: scrollController);
          },
        );
      },
    );
  }




bool _normalizeSelectionAwayFromPageBreakIfNeeded() {
  if (!_isAlive()) return false;
  if (_isNormalizingPageBreakSelection) return false;

  final selection = _controller.selection;

  if (!selection.isValid) return false;

  // IMPORTANT:
  // Do not normalize range selections.
  // This keeps Ctrl+A and mouse selection across pages working.
  if (!selection.isCollapsed) {
    return false;
  }

  final delta = _controller.document.toDelta();

  if (!DocumentPageBreakTools.isOffsetOnPageBreakCursorZone(
    delta,
    selection.baseOffset,
  )) {
    return false;
  }

  final normalizedOffset =
      DocumentPageBreakTools.normalizeCaretOffsetAwayFromPageBreak(
    delta,
    selection.baseOffset,
    preferAfter: true,
  );

  final maxOffset = math.max(0, _controller.document.length - 1);

  final safeOffset = normalizedOffset.clamp(0, maxOffset).toInt();

  if (safeOffset == selection.baseOffset) {
    return false;
  }

  _isNormalizingPageBreakSelection = true;

  try {
    _controller.updateSelection(
      TextSelection.collapsed(offset: safeOffset),
      ChangeSource.local,
    );
  } finally {
    _isNormalizingPageBreakSelection = false;
  }

  _editorFocusNode.requestFocus();

  return true;
}





Future<void> _initializeDocument({
  int? lifecycleToken,
}) async {
  final token = _effectiveLifecycleToken(lifecycleToken);

  if (!_isAlive(token)) return;

  _webSocketService = ref.read(documentWebSocketProvider);

  final modalArgs = ModalRoute.of(context)?.settings.arguments;
  final args = widget.routeData ?? modalArgs;

  debugPrint('Docs editor widget routeData: ${widget.routeData}');
  debugPrint('Docs editor modal args: $modalArgs');
  debugPrint('Docs editor resolved args: $args');

  if (!_isAlive(token)) return;

  final documentId =
      widget.routeDocumentId ?? _extractDocumentIdFromArgs(args);

  if (documentId != null && documentId.trim().isNotEmpty) {
    await _loadDocument(
      documentId: documentId.trim(),
      lifecycleToken: token,
    );
    return;
  }

  final template = widget.routeTemplate ?? _argTemplate(args);

  if (template != null) {
    await _loadDocument(
      template: template,
      isEditingTemplate: widget.routeIsEditingTemplate,
      lifecycleToken: token,
    );
    return;
  }

  final templateId = widget.routeTemplateId ??
      _argString(args, 'templateId') ??
      _argString(args, 'template_id');

  _routeContactId = _argString(args, 'contactId') ?? _argString(args, 'contact_id');
  _routeContactType = _argString(args, 'contactType') ?? _argString(args, 'contact_type');

  final mode = widget.routeMode ??
      _argString(args, 'mode')?.toLowerCase().trim();

  final createBlank = widget.routeCreateBlank ||
      _argBool(
        args,
        'createBlank',
        fallback: false,
      ) ||
      _argBool(
        args,
        'create_blank',
        fallback: false,
      ) ||
      mode == 'new' ||
      mode == 'create' ||
      mode == 'blank';

  final shouldEditTemplate = widget.routeIsEditingTemplate ||
      mode == 'edit' ||
      mode == 'template_edit';

  if (templateId != null) {
    final freshTemplate = await DocumentService.getTemplate(templateId, ref);

    if (!_isAlive(token)) return;

    await _loadDocument(
      template: freshTemplate,
      isEditingTemplate: shouldEditTemplate,
      lifecycleToken: token,
    );
    return;
  }

  if (createBlank) {
    await _createBlankDocument(lifecycleToken: token);
    return;
  }

  debugPrint(
    'Docs editor: missing documentId/template/createBlank args. '
    'Not creating a new document.',
  );

  // Nie wracaj automatycznie do listy, bo to maskuje problem routingu.
  // Możesz tu pokazać empty/error state, ale na razie tylko zostawiamy log.
}




Future<void> _loadDocument({
  String? documentId,
  DocumentTemplate? template,
  bool isEditingTemplate = false,
  int? lifecycleToken,
}) async {
  final token = _effectiveLifecycleToken(lifecycleToken);

  if (!_isAlive(token)) return;

  _webSocketService?.disconnect(clearPresence: true);

  if (!_isAlive(token)) return;

  _resetEditorRuntimeState(
    isEditingTemplate: isEditingTemplate,
    templateId: isEditingTemplate ? template?.id.toString() : null,
    templateName: isEditingTemplate ? template?.name : null,
  );

  if (!_isAlive(token)) return;

  ref.read(documentLoadingProvider.notifier).state = true;

  try {
    if (documentId != null && documentId.trim().isNotEmpty) {
      final cleanDocumentId = documentId.trim();

      debugPrint('Loading document: $cleanDocumentId');

      _resetEditorRuntimeState(isEditingTemplate: false);

      await ref.read(documentProvider.notifier).fetchDocument(
            cleanDocumentId,
            ref,
          );

      if (!_isAlive(token)) return;

      final document = ref.read(documentProvider).valueOrNull;

      if (document != null) {
        _loadDocumentContent(document);

        if (!_isAlive(token)) return;

        _webSocketService?.connect(document.id);
      } else {
        debugPrint('Document is null after fetch: $cleanDocumentId');
      }

      return;
    }

    if (template != null) {
      if (isEditingTemplate) {
        debugPrint('Editing template: ${template.name}');

        ref.read(documentProvider.notifier).clearDocument();

        if (!_isAlive(token)) return;

        final mockDocument = Documents(
          id: template.id.toString(),
          templateId: template.id,
          templateName: template.name,
          ownerId: template.ownerId,
          ownerUsername: template.ownerUsername,
          companyId: template.companyId,
          companyName: template.companyName,
          teamId: template.teamId,
          teamName: template.teamName,
          title: template.name,
          currentDelta: template.deltaJson,
          currentStyle: template.styleJson,
          revision: 0,
          lastEditedById: null,
          lastEditedByUsername: null,
          status: 'draft',
          isFinalized: false,
          createdAt: template.createdAt,
          updatedAt: template.updatedAt,
        );

        if (!_isAlive(token)) return;

        ref.read(documentProvider.notifier).setDocument(mockDocument);
        _loadTemplateContent(template);
        return;
      }

      debugPrint('Creating document from template: ${template.name}');

      final freshTemplate = await DocumentService.getTemplate(
        template.id.toString(),
        ref,
      );

      if (!_isAlive(token)) return;

      final document = await DocumentService.createDocument(
        templateId: freshTemplate.id,
        title: 'New ${freshTemplate.name}',
        currentDelta: freshTemplate.deltaJson,
        currentStyle: freshTemplate.styleJson,
        companyId: freshTemplate.companyId,
        teamId: freshTemplate.teamId,
        ref: ref,
      );

      if (!_isAlive(token)) return;

      _resetEditorRuntimeState(isEditingTemplate: false);

      if (!_isAlive(token)) return;

      ref.read(documentProvider.notifier).setDocument(document);
      _loadDocumentContent(document);

      if (!_isAlive(token)) return;

      _webSocketService?.connect(document.id);
      return;
    }

    debugPrint(
      'Load document called without documentId/template. '
      'Not creating blank document from _loadDocument.',
    );
  } catch (e) {
    debugPrint('Error loading document: $e');

    if (_isAlive(token)) {
      _showSnackBar(
        message: 'Nie udało się załadować dokumentu: $e',
        backgroundColor: Colors.red,
      );
    }
  } finally {
    if (_isAlive(token)) {
      ref.read(documentLoadingProvider.notifier).state = false;
    }
  }
}


  void _updateControllerContent(Delta newDelta) {
    if (_isApplyingRemoteUpdate) return;

    final currentDelta = _controller.document.toDelta();

    if (_areDeltasEqual(currentDelta, newDelta)) return;

    try {
      _isApplyingRemoteUpdate = true;
      _suppressControllerListener = true;

      final wasFocused = _editorFocusNode.hasFocus;
      final currentSelection = _controller.selection;

      final double? scrollPosition = _editorScrollController.hasClients
          ? _editorScrollController.position.pixels
          : null;

      final newDocument = Document.fromDelta(newDelta);
      _controller.document = newDocument;

      final newSelection =
          _calculateOptimalSelection(currentSelection, newDocument);

      _controller.updateSelection(newSelection, ChangeSource.remote);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (scrollPosition != null && _editorScrollController.hasClients) {
          _editorScrollController.jumpTo(scrollPosition);
        }

        if (wasFocused) {
          _editorFocusNode.requestFocus();
        }
      });

      _lastSentDelta = newDelta;

      if (mounted) {
        setState(() {
          _editorRevision++;
        });
      }
    } catch (e) {
      debugPrint('Error updating controller content: $e');
    } finally {
      _suppressControllerListener = false;
      _isApplyingRemoteUpdate = false;
    }                               
  }

  TextSelection _calculateOptimalSelection(
    TextSelection oldSelection,
    Document newDocument,
  ) {
    final documentLength = newDocument.length;

    if (_isFocused && oldSelection.extentOffset >= documentLength - 1) {
      return TextSelection.collapsed(offset: documentLength);
    }

    if (oldSelection.isValid && oldSelection.end <= documentLength) {
      return oldSelection;
    }

    return TextSelection.collapsed(offset: documentLength);
  }

  bool _areDeltasEqual(Delta delta1, Delta delta2) {
    try {
      final json1 = jsonEncode(delta1.toJson());
      final json2 = jsonEncode(delta2.toJson());

      return json1 == json2;
    } catch (_) {
      return false;
    }
  }

  void _loadDocumentContent(Documents document) {
    try {
      final delta = _deltaFromMap(document.currentDelta);

      _updateControllerContent(delta);

      _isInitialized = true;
      _lastSentDelta = delta;

      // Set Emma context for this document (includes contact if navigated from CRM)
      final pending = ref.read(docsEmmaProvider).pendingCreateFromContact;
      DocsEmmaService.setDocumentContext(
        ref,
        documentId: document.id.toString(),
        contactId: pending?.contactId ?? _routeContactId,
        contactType: pending?.contactType ?? _routeContactType,
      );
      if (pending != null) {
        ref.read(docsEmmaProvider.notifier).clearCreateFromContact();
      }
    } catch (e) {
      debugPrint('Error loading document content: $e');
    }
  }

  void _loadTemplateContent(DocumentTemplate template) {
    try {
      final delta = _deltaFromMap(template.deltaJson);

      _updateControllerContent(delta);

      _isInitialized = true;
      _lastSentDelta = delta;
    } catch (e) {
      debugPrint('Error loading template content: $e');
    }
  }

  Future<String> _ensureDefaultTemplateId() async {
    final templates = await DocumentService.getTemplates(ref);

    if (templates.isNotEmpty) {
      return templates.first.id;
    }

    final created = await DocumentService.createTemplate(
      name: 'Blank Document',
      description: 'Default blank document template',
      deltaJson: {
        'ops': [
          {'insert': '\n'},
        ],
      },
      styleJson: {},
      ref: ref,
    );

    ref.invalidate(documentTemplatesProvider);

    return created.id;
  }



Future<void> _createBlankDocument({
  int? lifecycleToken,
}) async {
  final token = _effectiveLifecycleToken(lifecycleToken);

  if (!_isAlive(token)) return;

  _webSocketService?.disconnect(clearPresence: true);

  if (!_isAlive(token)) return;

  _resetEditorRuntimeState(isEditingTemplate: false);

  if (!_isAlive(token)) return;

  ref.read(documentLoadingProvider.notifier).state = true;

  try {
    final defaultTemplateId = await _ensureDefaultTemplateId();

    if (!_isAlive(token)) return;

    final document = await DocumentService.createDocument(
      templateId: defaultTemplateId,
      title: 'Untitled Document'.tr,
      currentDelta: {
        'ops': [
          {'insert': '\n'},
        ],
      },
      currentStyle: {},
      ref: ref,
    );

    if (!_isAlive(token)) return;

    ref.read(documentProvider.notifier).setDocument(document);
    _loadDocumentContent(document);

    if (!_isAlive(token)) return;

    _webSocketService?.connect(document.id);
  } catch (e) {
    debugPrint('Error creating blank document: $e');

    if (_isAlive(token)) {
      _showSnackBar(
        message: 'Nie udało się utworzyć dokumentu: $e',
        backgroundColor: Colors.red,
      );
    }
  } finally {
    if (_isAlive(token)) {
      ref.read(documentLoadingProvider.notifier).state = false;
    }
  }
}




void _onTextChange() {
  if (!_isAlive()) return;

  if (_suppressControllerListener ||
      _isApplyingRemoteUpdate ||
      _isNormalizingPageBreakSelection) {
    return;
  }

  // Only collapsed caret is normalized.
  // Range selection, Ctrl+A and mouse selection across pages stay untouched.
  if (_controller.selection.isCollapsed &&
      _normalizeSelectionAwayFromPageBreakIfNeeded()) {
    return;
  }

  _updateSelectionContextDebounced();

  _lastLocalEditAt = DateTime.now();
  _hasLocalUnsavedChanges = true;

  if (_isAlive()) {
    setState(() {
      _editorRevision++;
    });
  }

  _sendCursorDebounced();

  _debounceTimer?.cancel();
  _debounceTimer = Timer(
    _debounceDelay,
    () {
      if (!_isAlive()) return;

      _sendUpdateIfNeeded();
    },
  );
}





Future<void> _sendUpdateIfNeeded({
  bool force = false,
}) async {
  if (!_isAlive()) return;

  if (_isEditingTemplateMode) {
    return;
  }

  if (!_isInitialized || _isApplyingRemoteUpdate) {
    return;
  }

  final currentDelta = _controller.document.toDelta();

  if (!force &&
      _lastSentDelta != null &&
      _areDeltasEqual(currentDelta, _lastSentDelta!)) {
    debugPrint('No changes detected - skipping send');
    return;
  }

  if (_webSocketService == null || !_webSocketService!.isConnected) {
    debugPrint('WebSocket unavailable - saving through REST fallback');
    await _saveDocumentViaApi(silent: true);
    return;
  }

  await _sendUpdate(currentDelta);
}




Future<void> _sendUpdate(Delta currentDelta) async {
  if (!_isAlive()) return;

  final deltaMap = DeltaUtils.deltaToMap(currentDelta);
  final style = StyleExtractor.extractStyle(_controller);
  final title = ref.read(documentProvider.notifier).getLocalTitle(ref);

  final baseRevision = ref.read(documentProvider).valueOrNull?.revision ??
      _webSocketService?.currentRevision ??
      0;

  final updateId = DateTime.now().microsecondsSinceEpoch.toString();

  final sent = _webSocketService?.sendUpdate(
        delta: deltaMap,
        style: style,
        title: title,
        baseRevision: baseRevision,
        updateId: updateId,
      ) ??
      false;

  if (!_isAlive()) return;

  if (!sent) {
    debugPrint('WebSocket send failed - saving through REST fallback');
    await _saveDocumentViaApi(silent: true);
    return;
  }

  debugPrint('WebSocket update sent, waiting for update_ack...');
}


Future<bool> _saveDocumentViaApi({
  bool silent = false,
}) async {
  if (!_isAlive()) return false;

  final currentDocument = ref.read(documentProvider).valueOrNull;

  if (currentDocument == null) {
    if (!silent && _isAlive()) {
      _showSnackBar(
        message: 'Brak dokumentu do zapisania.',
        backgroundColor: Colors.orange,
      );
    }

    return false;
  }

  try {
    final title = ref.read(documentProvider.notifier).getLocalTitle(ref);
    final currentDelta = _controller.document.toDelta();
    final deltaMap = DeltaUtils.deltaToMap(currentDelta);
    final style = StyleExtractor.extractStyle(_controller);

    final updated = await DocumentService.updateDocument(
      documentId: currentDocument.id,
      title: title,
      currentDelta: deltaMap,
      currentStyle: style,
      ref: ref,
    );

    if (!_isAlive()) return false;

    ref.read(documentProvider.notifier).setDocument(updated);
    ref.invalidate(documentsProvider);

    _lastSentDelta = currentDelta;
    _hasLocalUnsavedChanges = false;

    if (_isAlive()) {
      setState(() {
        _editorRevision++;
      });
    }

    return true;
  } catch (e) {
    debugPrint('REST document save failed: $e');

    if (!silent && _isAlive()) {
      _showSnackBar(
        message: 'Nie udało się zapisać dokumentu: $e',
        backgroundColor: Colors.red,
      );
    }

    return false;
  }
}

void _sendCursorDebounced() {
  if (!_isAlive()) return;
  if (_isEditingTemplateMode) return;
  if (_webSocketService == null || !_webSocketService!.isConnected) return;

  _cursorDebounceTimer?.cancel();
  _cursorDebounceTimer = Timer(const Duration(milliseconds: 180), () {
    if (!_isAlive()) return;

    _webSocketService?.sendCursor(selection: _controller.selection);
  });
}




Future<void> _saveVersionFromToolbar([
  String comment = 'Manual version save',
]) async {
  if (!_isAlive()) return;

  if (_isEditingTemplateMode) {
    await _saveTemplate();

    if (!_isAlive()) return;

    _showSnackBar(
      message:
          'Template zapisany. Wersjonowanie template można podpiąć osobnym endpointem.',
      backgroundColor: Colors.green,
    );
    return;
  }

  final currentDocument = ref.read(documentProvider).valueOrNull;

  if (currentDocument == null) {
    _showSnackBar(
      message: 'Brak dokumentu do zapisania jako wersja.',
      backgroundColor: Colors.orange,
    );
    return;
  }

  try {
    if (_webSocketService != null && _webSocketService!.isConnected) {
      _webSocketService?.saveVersion(
        comment: comment,
        controller: _controller,
        title: ref.read(documentProvider.notifier).getLocalTitle(ref),
      );
    } else {
      await _saveDocumentViaApi();

      if (!_isAlive()) return;

      await DocumentService.saveDocumentVersion(
        documentId: currentDocument.id,
        comment: comment,
        ref: ref,
      );
    }

    if (!_isAlive()) return;

    _showSnackBar(
      message: 'Zapisano wersję dokumentu.',
      backgroundColor: Colors.green,
    );
  } catch (e) {
    if (!_isAlive()) return;

    _showSnackBar(
      message: 'Nie udało się zapisać wersji: $e',
      backgroundColor: Colors.red,
    );
  }
}


  void _togglePaperPreviewMode() {
  final current = ref.read(documentPaperPreviewModeProvider);

  final next = current == DocumentPaperPreviewMode.whitePaper
      ? DocumentPaperPreviewMode.themePaper
      : DocumentPaperPreviewMode.whitePaper;

  ref.read(documentPaperPreviewModeProvider.notifier).state = next;

  if (mounted) {
    setState(() {
      _editorRevision++;
    });
  }
}


  Future<void> _generateDocument() async {
    final currentDocument = ref.read(documentProvider).value;

    if (currentDocument == null) return;

    if (_isEditingTemplateMode) {
      _showSnackBar(
        message: 'Najpierw zapisz template albo utwórz dokument z template.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final localTitle = ref.read(documentProvider.notifier).getLocalTitle(ref);
      final pageSetup = ref.read(documentPageSetupProvider);

      final filePath = await DocumentExporter.exportToPdfFromController(
        controller: _controller,
        title: localTitle,
        pageSetup: pageSetup,
      );

      if (filePath == null && !UniversalPlatform.isWeb) {
        throw Exception('Failed to generate PDF');
      }

      if (UniversalPlatform.isWeb) {
        _showSnackBar(
          message: "PDF '$localTitle' Downloaded Successfully!",
          backgroundColor: Colors.green,
        );
        return;
      }

      await DocumentService.generateDocument(
        documentId: currentDocument.id,
        filePath: filePath!,
        ref: ref,
      );

      _showSnackBar(
        message: 'Wygenerowano dokument PDF.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      debugPrint('PDF Error: $e');

      if (mounted) {
        _showSnackBar(
          message: 'Nie udało się wygenerować PDF: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _insertNewPage() {
    _insertPageBreak();
  }

  Future<void> _openPageSetup() async {
    final theme = ref.read(themeColorsProvider);
    final currentSetup = ref.read(documentPageSetupProvider);

    final result = await showDialog<DocumentPageSetup?>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return DocumentPageSetupDialog(
          initial: currentSetup,
          theme: theme,
        );
      },
    );

    if (!mounted || result == null) return;

    ref.read(documentPageSetupProvider.notifier).update(result);

    setState(() {
      _editorRevision++;
    });

    _showSnackBar(
      message: 'Zmieniono ustawienia strony.',
      backgroundColor: Colors.green,
    );
  }

  Future<void> _printDocument() async {
    if (_isEditingTemplateMode) {
      _showSnackBar(
        message: 'Najpierw utwórz dokument z template albo zapisz template.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final currentDocument = ref.read(documentProvider).valueOrNull;

    if (currentDocument == null) {
      _showSnackBar(
        message: 'Brak dokumentu do wydrukowania.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      if (_hasLocalUnsavedChanges) {
        await _saveCurrentEditorState();
      }

      final title = ref.read(documentProvider.notifier).getLocalTitle(ref);
      final pageSetup = ref.read(documentPageSetupProvider);

      await DocumentExporter.printFromController(
        controller: _controller,
        title: title,
        pageSetup: pageSetup,
      );

      _showSnackBar(
        message: 'Otworzono drukowanie.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      debugPrint('Print Error: $e');

      _showSnackBar(
        message: 'Nie udało się wydrukować dokumentu: $e',
        backgroundColor: Colors.red,
      );
    }
  }

void _navigateToDocuments() {
  if (!_isAlive()) return;

  ref.read(navigationService).pushNamedScreen(
    Routes.docsLibrary,
    data: {
      'tab': 'documents',
    },
  );
}

  void _navigateToTemplates() {
    ref.read(navigationService).pushNamedScreen(
      Routes.docsLibrary,
      data: {
        'tab': 'templates',
      },
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    if (!mounted) return;

    final messenger = _scaffoldMessengerKey.currentState;

    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor),
      
    );
  }

  void _requestEditorFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editorFocusNode.requestFocus();
    });
  }

  int get _pageCount {
    final count = DocumentPageBreakTools.countInDelta(
      _controller.document.toDelta(),
    );

    return count + 1;
  }

  int get _currentPageNumber {
    final selection = _controller.selection;
    final offset = selection.baseOffset < 0 ? 0 : selection.baseOffset;

    final count = DocumentPageBreakTools.countBeforeOffset(
      _controller.document.toDelta(),
      offset,
    );

    return count + 1;
  }

  void _insertTextAtSelection(String text) {
    final selection = _controller.selection;
    final documentLength = _controller.document.length;
    final fallbackIndex = (documentLength - 1).clamp(0, documentLength).toInt();

    final selectionIsValid =
        selection.isValid && selection.start >= 0 && selection.end >= 0;

    final int index = selectionIsValid
        ? selection.start.clamp(0, fallbackIndex).toInt()
        : fallbackIndex;

    final int length = selectionIsValid && !selection.isCollapsed
        ? (selection.end - selection.start).clamp(0, documentLength).toInt()
        : 0;

    final newSelection = TextSelection.collapsed(
      offset: index + text.length,
    );

    _controller.replaceText(
      index,
      length,
      text,
      newSelection,
    );

    setState(() {
      _editorRevision++;
    });

    _requestEditorFocus();
  }





void _insertPageBreak() {
  if (!_isAlive()) return;

  _rememberScrollBeforeAutoAlign();

  final caretOffset = DocumentPageBreakTools.insertAtSelection(_controller);

  if (_isAlive()) {
    setState(() {
      _editorRevision++;
    });
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_isAlive()) return;

    final maxCursorOffset = math.max(0, _controller.document.length - 1);
    final safeCaretOffset = caretOffset
        .clamp(0, maxCursorOffset)
        .toInt();

    _controller.updateSelection(
      TextSelection.collapsed(offset: safeCaretOffset),
      ChangeSource.local,
    );

    _normalizeSelectionAwayFromPageBreakIfNeeded();

    _editorFocusNode.requestFocus();

    _alignScrollToWritingPage(
      rememberPrevious: false,
      animate: true,
    );
  });

  _showSnackBar(
    message:
        'Dodano nową stronę. Naciśnij Esc, żeby wrócić do poprzedniego miejsca.',
    backgroundColor: Colors.green,
  );
}



  void _toggleAttribute(Attribute attribute) {
    final selectionStyle = _controller.getSelectionStyle();
    final currentAttribute = selectionStyle.attributes[attribute.key];

    final isActive = currentAttribute?.value == attribute.value;

    _controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );

    setState(() {
      _editorRevision++;
    });

    _requestEditorFocus();
  }

  void _clearFormatting() {
    final style = _controller.getSelectionStyle();

    if (style.attributes.isEmpty) {
      return;
    }

    for (final attribute in style.attributes.values) {
      _controller.formatSelection(
        Attribute.clone(attribute, null),
      );
    }

    setState(() {
      _editorRevision++;
    });

    _requestEditorFocus();
  }

  String _formattedToday() {
    final now = DateTime.now();

    return '${now.day.toString().padLeft(2, '0')}.'
        '${now.month.toString().padLeft(2, '0')}.'
        '${now.year}';
  }

  String _selectedText() {
    final selection = _controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      return '';
    }

    final text = _controller.document.toPlainText();
    final start = selection.start.clamp(0, text.length).toInt();
    final end = selection.end.clamp(0, text.length).toInt();

    if (start >= end) return '';

    return text.substring(start, end);
  }

  Future<void> _copySelectedText() async {
    final selected = _selectedText();

    if (selected.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: selected));
  }

  Future<void> _cutSelectedText() async {
    final selection = _controller.selection;

    if (!selection.isValid || selection.isCollapsed) return;

    final text = _controller.document.toPlainText();
    final start = selection.start.clamp(0, text.length).toInt();
    final end = selection.end.clamp(0, text.length).toInt();

    if (start >= end) return;

    final selected = text.substring(start, end);
    if (selected.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: selected));

    _controller.replaceText(
      start,
      end - start,
      '',
      TextSelection.collapsed(offset: start),
    );

    setState(() {
      _editorRevision++;
    });

    _requestEditorFocus();
  }

  Future<void> _pasteClipboardText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.isEmpty) return;

    _insertTextAtSelection(text);
  }

Future<void> _saveCurrentEditorState() async {
  if (!_isAlive()) return;
  if (_isManualSaving) return;

  _isManualSaving = true;

  try {
    if (_isEditingTemplateMode) {
      await _saveTemplate();

      if (!_isAlive()) return;

      _showSnackBar(
        message: 'Template zapisany.',
        backgroundColor: Colors.green,
      );

      return;
    }

    final saved = await _saveDocumentViaApi();

    if (!_isAlive()) return;

    if (saved) {
      _showSnackBar(
        message: 'Dokument zapisany.',
        backgroundColor: Colors.green,
      );
    }
  } finally {
    _isManualSaving = false;
  }
}

  Widget _buildEditorShortcuts({
    required Widget child,
  }) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            SaveEditorIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            SaveEditorIntent(),

        SingleActivator(LogicalKeyboardKey.keyP, control: true):
            PrintDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyP, meta: true):
            PrintDocumentIntent(),

        SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true):
            OpenPageSetupIntent(),
        SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true):
            OpenPageSetupIntent(),

        SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true):
            OpenDocumentsLibraryIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true):
            OpenDocumentsLibraryIntent(),

        SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true):
            OpenTemplatesLibraryIntent(),
        SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true):
            OpenTemplatesLibraryIntent(),

        SingleActivator(LogicalKeyboardKey.keyN, control: true, alt: true):
            CreateBlankDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true, alt: true):
            CreateBlankDocumentIntent(),

        SingleActivator(LogicalKeyboardKey.enter, control: true):
            InsertPageBreakIntent(),
        SingleActivator(LogicalKeyboardKey.enter, meta: true):
            InsertPageBreakIntent(),

        SingleActivator(LogicalKeyboardKey.digit1, control: true, alt: true):
            ApplyHeading1Intent(),
        SingleActivator(LogicalKeyboardKey.digit1, meta: true, alt: true):
            ApplyHeading1Intent(),

        SingleActivator(LogicalKeyboardKey.digit2, control: true, alt: true):
            ApplyHeading2Intent(),
        SingleActivator(LogicalKeyboardKey.digit2, meta: true, alt: true):
            ApplyHeading2Intent(),

        SingleActivator(LogicalKeyboardKey.digit3, control: true, alt: true):
            ApplyHeading3Intent(),
        SingleActivator(LogicalKeyboardKey.digit3, meta: true, alt: true):
            ApplyHeading3Intent(),

        SingleActivator(LogicalKeyboardKey.digit7, control: true, shift: true):
            ToggleOrderedListIntent(),
        SingleActivator(LogicalKeyboardKey.digit7, meta: true, shift: true):
            ToggleOrderedListIntent(),

        SingleActivator(LogicalKeyboardKey.digit8, control: true, shift: true):
            ToggleBulletListIntent(),
        SingleActivator(LogicalKeyboardKey.digit8, meta: true, shift: true):
            ToggleBulletListIntent(),

        SingleActivator(LogicalKeyboardKey.keyX, control: true, shift: true):
            ClearFormattingIntent(),
        SingleActivator(LogicalKeyboardKey.keyX, meta: true, shift: true):
            ClearFormattingIntent(),
        SingleActivator(LogicalKeyboardKey.escape):
          RestorePreviousEditorScrollIntent(),

        SingleActivator(LogicalKeyboardKey.keyL, control: true, alt: true):
            AlignWritingPageIntent(),
        SingleActivator(LogicalKeyboardKey.keyL, meta: true, alt: true):
            AlignWritingPageIntent(),

        // Ctrl+A → select all text in document (overrides Quill's per-page select-all)
        SingleActivator(LogicalKeyboardKey.keyA, control: true):
            SelectAllInDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            SelectAllInDocumentIntent(),

        // Ctrl+Shift+A → select current page only
        SingleActivator(LogicalKeyboardKey.keyA, control: true, shift: true):
            SelectCurrentPageIntent(),
        SingleActivator(LogicalKeyboardKey.keyA, meta: true, shift: true):
            SelectCurrentPageIntent(),

      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveEditorIntent: CallbackAction<SaveEditorIntent>(
            onInvoke: (_) {
              _saveCurrentEditorState();
              return null;
            },
          ),
          PrintDocumentIntent: CallbackAction<PrintDocumentIntent>(
            onInvoke: (_) {
              _printDocument();
              return null;
            },
          ),
          OpenPageSetupIntent: CallbackAction<OpenPageSetupIntent>(
            onInvoke: (_) {
              _openPageSetup();
              return null;
            },
          ),
          GeneratePdfIntent: CallbackAction<GeneratePdfIntent>(
            onInvoke: (_) {
              _generateDocument();
              return null;
            },
          ),
          OpenDocumentsLibraryIntent:
              CallbackAction<OpenDocumentsLibraryIntent>(
            onInvoke: (_) {
              _navigateToDocuments();
              return null;
            },
          ),
          OpenTemplatesLibraryIntent:
              CallbackAction<OpenTemplatesLibraryIntent>(
            onInvoke: (_) {
              _navigateToTemplates();
              return null;
            },
          ),
          CreateBlankDocumentIntent:
              CallbackAction<CreateBlankDocumentIntent>(
            onInvoke: (_) {
              _createBlankDocument();
              return null;
            },
          ),
          InsertPageBreakIntent: CallbackAction<InsertPageBreakIntent>(
            onInvoke: (_) {
              _insertPageBreak();
              return null;
            },
          ),
          NewPageIntent: CallbackAction<NewPageIntent>(
            onInvoke: (_) {
              _insertNewPage();
              return null;
            },
          ),
          ApplyHeading1Intent: CallbackAction<ApplyHeading1Intent>(
            onInvoke: (_) {
              _toggleAttribute(Attribute.h1);
              return null;
            },
          ),
          ApplyHeading2Intent: CallbackAction<ApplyHeading2Intent>(
            onInvoke: (_) {
              _toggleAttribute(Attribute.h2);
              return null;
            },
          ),
          ApplyHeading3Intent: CallbackAction<ApplyHeading3Intent>(
            onInvoke: (_) {
              _toggleAttribute(Attribute.h3);
              return null;
            },
          ),
          ToggleBulletListIntent: CallbackAction<ToggleBulletListIntent>(
            onInvoke: (_) {
              _toggleAttribute(Attribute.ul);
              return null;
            },
          ),
          ToggleOrderedListIntent: CallbackAction<ToggleOrderedListIntent>(
            onInvoke: (_) {
              _toggleAttribute(Attribute.ol);
              return null;
            },
          ),
          ClearFormattingIntent: CallbackAction<ClearFormattingIntent>(
            onInvoke: (_) {
              _clearFormatting();
              return null;
            },
          ),
          RestorePreviousEditorScrollIntent:
              CallbackAction<RestorePreviousEditorScrollIntent>(
            onInvoke: (_) {
              _restoreScrollBeforeAutoAlign();
              return null;
            },
          ),

          AlignWritingPageIntent: CallbackAction<AlignWritingPageIntent>(
            onInvoke: (_) {
              _alignScrollToWritingPage(
                rememberPrevious: true,
                animate: true,
              );
              return null;
            },
          ),
          SelectAllInDocumentIntent: CallbackAction<SelectAllInDocumentIntent>(
            onInvoke: (_) {
              _selectAllInDocument();
              return null;
            },
          ),
          SelectCurrentPageIntent: CallbackAction<SelectCurrentPageIntent>(
            onInvoke: (_) {
              _selectCurrentPage();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }


  void _selectAllInDocument() {
    if (!_isAlive()) return;
    final length = math.max(0, _controller.document.length - 1);
    _controller.updateSelection(
      TextSelection(baseOffset: 0, extentOffset: length),
      ChangeSource.local,
    );
  }

  // Scans the master delta for page-break embed positions and returns the
  // [start, end] offsets of the page that contains [cursorOffset].
  // Structure between pages in the composed delta:
  //   ... [page content] \n [embed(1 char)] \n [next page content] ...
  // so a page break embed at offset P means:
  //   \n is at P-1 (separator before embed), \n at P+1 (separator after).
  //   Next page starts at P+2.
  ({int start, int end}) _pageContaining(int cursorOffset) {
    final delta = _controller.document.toDelta();
    final masterLength = math.max(0, _controller.document.length - 1);

    final breakPositions = <int>[];
    int pos = 0;
    for (final rawOp in delta.toJson()) {
      if (rawOp is! Map) continue;
      final insert = rawOp['insert'];
      if (insert is Map) {
        final custom = insert['custom'];
        if (custom is Map &&
            custom['type'] == DocumentPageBreakTools.embedType) {
          breakPositions.add(pos);
        }
        pos += 1;
      } else if (insert is String) {
        pos += insert.length;
      }
    }

    for (var i = 0; i <= breakPositions.length; i++) {
      final segStart = i == 0 ? 0 : breakPositions[i - 1] + 2;
      final segEnd = i < breakPositions.length
          ? breakPositions[i] - 1
          : masterLength;

      if (cursorOffset >= segStart && cursorOffset <= segEnd) {
        return (start: segStart, end: segEnd);
      }
    }

    return (start: 0, end: masterLength);
  }

  void _selectCurrentPage() {
    if (!_isAlive()) return;
    final selection = _controller.selection;
    final cursor = selection.isValid
        ? (selection.isCollapsed ? selection.baseOffset : selection.start)
        : 0;
    final bounds = _pageContaining(cursor);
    _controller.updateSelection(
      TextSelection(baseOffset: bounds.start, extentOffset: bounds.end),
      ChangeSource.local,
    );
  }

  void _updateSelectionContextDebounced() {
    _selectionDebounceTimer?.cancel();
    _selectionDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!_isAlive()) return;
      final selection = _controller.selection;
      // When selection collapses (including when focus moves to Emma's input),
      // we keep the last selected_text so Emma still has context when the user
      // sends a message after clicking into her chat box.
      // selected_text is cleared on document load or screen dispose.
      if (!selection.isCollapsed) {
        final text = _controller.document.toPlainText();
        final start = selection.start.clamp(0, text.length);
        final end = selection.end.clamp(0, text.length);
        if (start < end) {
          DocsEmmaService.setSelectedText(ref, text.substring(start, end));
        }
      }
    });
  }

  void _applyEmmaTextEdit(DocsTextEditRequest request) {
    if (!_isAlive()) return;
    if (!_isInitialized) return;
    if (request.original.isEmpty || request.rewritten.isEmpty) {
      ref.read(docsEmmaProvider.notifier).clearTextEdit();
      return;
    }

    final plainText = _controller.document.toPlainText();
    final index = plainText.indexOf(request.original);
    if (index == -1) {
      ref.read(docsEmmaProvider.notifier).clearTextEdit();
      return;
    }

    _suppressControllerListener = true;
    try {
      _controller.replaceText(
        index,
        request.original.length,
        request.rewritten,
        TextSelection.collapsed(offset: index + request.rewritten.length),
      );
      _hasLocalUnsavedChanges = true;
      _lastLocalEditAt = DateTime.now();
    } finally {
      _suppressControllerListener = false;
    }

    ref.read(docsEmmaProvider.notifier).clearTextEdit();

    if (_isAlive()) {
      setState(() => _editorRevision++);
    }
  }

  @override
  void dispose() {
    _screenDisposed = true;
    _lifecycleToken++;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    _cursorDebounceTimer?.cancel();
    _cursorDebounceTimer = null;

    _selectionDebounceTimer?.cancel();
    _selectionDebounceTimer = null;

    _docSub?.close();
    _docSub = null;

    _emmaSub?.close();
    _emmaSub = null;

    _webSocketService?.disconnect(clearPresence: true);
    _webSocketService = null;

    _controller.removeListener(_onTextChange);
    _controller.dispose();

    _editorFocusNode.dispose();
    searchFocusNode.dispose();
    _editorScrollController.dispose();

    // Release the overlay interceptor so other screens can open floating Emma.
    EmmaOverlayManager.setInterceptor(null);

    // Defer Emma context clear to avoid mutating Riverpod state while a
    // pointer event is still being dispatched (causes !_debugDuringDeviceUpdate).
    final emmaNotifier = ref.read(emmaContextProvider.notifier);
    Future.microtask(emmaNotifier.clearModuleContext);

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final isLoading = ref.watch(documentLoadingProvider);
    final documentAsync = ref.watch(documentProvider);
    final isConnected = _isEditingTemplateMode
        ? false
        : ref.watch(documentWebSocketConnectedProvider);

    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.documentEditorScreen.anchorKey,

      spec: DocsEmmaAnchors.documentEditorScreen,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.agentCrm,
        isTopAppBarOff: true,
        isBottomBarOff: true,
        enableScrool: false,
        childPc: _buildMaterialShell(
          theme: theme,
          isMobile: false,
          isLoading: isLoading,
          documentAsync: documentAsync,
          isConnected: isConnected,
        ),
        childMobile: _buildMaterialShell(
          theme: theme,
          isMobile: true,
          isLoading: isLoading,
          documentAsync: documentAsync,
          isConnected: isConnected,
        ),
      ),
    );
  }

  Widget _buildMaterialShell({
    required ThemeColors theme,
    required bool isMobile,
    required bool isLoading,
    required AsyncValue<Documents?> documentAsync,
    required bool isConnected,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      supportedLocales: mobilecodes,
      color: theme.dashboardContainer,
      localizationsDelegates: [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        CountryLocalizations.delegate,
        GlobalFeedbackLocalizationsDelegate(),
      ],
      home: Builder(
        builder: (context) {
          final pageSetup = ref.watch(documentPageSetupProvider);
          final paperPreviewMode = ref.watch(documentPaperPreviewModeProvider);
          final whitePaperMode = paperPreviewMode.isWhitePaper;

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isMobile ? 12 : 18),
                  if (isMobile)
                    EmmaUiAnchorTarget(
                      anchorKey:
                          DocsEmmaAnchors.docsMobileToolbarStrip.anchorKey,
                      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                      tapMode: EmmaUiAnchorTapMode.disabled,
                      child: const DocsMobileToolbarStrip(),
                    ),
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(72, 0, 72, 16),
                      child: DocsQuillToolbar(
                        whitePaperMode: whitePaperMode,
                        onTogglePaperModePressed: _togglePaperPreviewMode,
                        controller: _controller,
                        editorFocusNode: _editorFocusNode,
                        resolvedTheme: theme,
                        sidebarColor: theme.dashboardContainer,
                        compact: isMobile,
                        isTemplateMode: _isEditingTemplateMode,
                        isConnected: isConnected,
                        hasUnsavedChanges: _hasLocalUnsavedChanges,
                        isDocumentHeaderVisible: _isDocumentHeaderVisible,
                        onToggleDocumentHeaderPressed: () {
                          if (!mounted) return;

                          setState(() {
                            _isDocumentHeaderVisible =
                                !_isDocumentHeaderVisible;
                          });
                        },
                        header: _buildUnifiedDocumentHeader(
                          documentAsync: documentAsync,
                          isConnected: isConnected,
                          isTemplate: _isEditingTemplateMode,
                        ),
                        onMyDocumentPressed: _onMyDocumentsPressed,
                        onCreateTemplatePressed: _onCreateTemplatePressed,
                        onSavePressed: _saveCurrentEditorState,
                        onSaveVersionPressed: _saveVersionFromToolbar,
                        onInsertPageBreakPressed: _insertPageBreak,
                        onNewPagePressed: _insertNewPage,
                        onPrintPressed: _printDocument,
                        onPageSetupPressed: _openPageSetup,
                        onGeneratePressed: _generateDocument,
                        emmaActive: _emmaVisible,
                        onEmmaTogglePressed: () =>
                            setState(() => _emmaVisible = !_emmaVisible),
                      ),
                    ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: isLoading
                              ? Center(
                                  child: AppLottie.loading(size: 450),
                                )
                              : EmmaUiAnchorTarget(
                                  anchorKey:
                                      DocsEmmaAnchors.quillEditor.anchorKey,
                                  runtimeMode:
                                      EmmaUiAnchorRuntimeMode.onDemand,
                                  tapMode: EmmaUiAnchorTapMode.disabled,
                                  child: _buildEditorShortcuts(
                                    child: DocEditorWithFloatingToolbar(
                                      whitePaperMode: whitePaperMode,
                                      controller: _controller,
                                      editorFocusNode: _editorFocusNode,
                                      editorScrollController:
                                          _editorScrollController,
                                      resolvedTheme: theme,
                                      sidebarColor: theme.dashboardContainer,
                                      textColor: theme.themeTextColor,
                                      pageSetup: pageSetup,
                                      onFitScaleChanged: (scale) {
                                        _editorFitScale = scale;
                                      },
                                      showFloatingQuickActions: false,
                                      onMyDocumentPressed: null,
                                      onCreateTemplatePressed: null,
                                      onSaveVersionPressed: null,
                                      onGeneratePressed: null,
                                      showTemplatePlaceholders:
                                          _isEditingTemplateMode,
                                      templatePlaceholders:
                                          _resolveTemplatePlaceholderKeys(
                                        documentAsync,
                                      ),
                                      placeholderValues: _placeholderValues,
                                      onPlaceholderValueChanged:
                                          _onPlaceholderValueChanged,
                                    ),
                                  ),
                                ),
                        ),
                        if (_emmaVisible && !isMobile) ...[
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: theme.dashboardBoarder,
                          ),
                          const SizedBox(
                            width: 380,
                            child: EmmaChatInline(fillParent: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _resolveTemplatePlaceholderKeys(
    AsyncValue<Documents?> documentAsync,
  ) {
    if (!_isEditingTemplateMode) {
      return const [];
    }

    final fields = ref.read(templateProvider).valueOrNull?.formFields ?? [];

    if (fields.isNotEmpty) {
      return fields.map((field) => field.key).toList();
    }

    return const [
      'name',
      'last_name',
      'gender',
      'company_name',
      'owner',
    ];
  }

  Widget _buildUnifiedDocumentHeader({
    required AsyncValue<Documents?> documentAsync,
    required bool isConnected,
    required bool isTemplate,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = ref.watch(themeColorsProvider);
        final presenceCount = ref.watch(documentPresenceProvider).length;
        final revision = documentAsync.valueOrNull?.revision ?? 0;
        final isNarrow = constraints.maxWidth < 1050;

        final statusWidgets = <Widget>[
          _EditorModePill(
            isEditingTemplate: _isEditingTemplateMode,
            isConnected: isConnected,
          ),
          _ToolbarDivider(),
          _EditorStatusPill(
            icon: Icons.description_outlined,
            label: 'Strona $_currentPageNumber/$_pageCount',
          ),
          _EditorStatusPill(
            icon: Icons.history_outlined,
            label: 'Rev. $revision',
          ),
          if (presenceCount > 0)
            _EditorStatusPill(
              icon: Icons.people_alt_outlined,
              label: '$presenceCount online',
            ),
          if (_hasLocalUnsavedChanges) const _EditorUnsavedPill(),
        ];

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildHeaderTitle(documentAsync)),
                  const SizedBox(width: 12),
                  _buildNavigationButtons(theme),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildHeaderMenuBar(theme),
                  if (isTemplate) _buildSaveTemplateButton(),
                  ...statusWidgets,
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeaderMenuBar(theme),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildNavigationButtons(theme),
                    if (isTemplate) _buildSaveTemplateButton(),
                    ...statusWidgets,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 220,
                maxWidth: 420,
              ),
              child: _buildHeaderTitle(documentAsync),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSaveTemplateButton() {
    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.saveTemplateButton.anchorKey,

      spec: DocsEmmaAnchors.saveTemplateButton,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      child: _EditorToolbarButton(
        icon: Icons.save_as,
        label: 'Save Template',
        tooltip: 'Save Template',
        onTap: _saveTemplate,
      ),
    );
  }

  Widget _buildHeaderTitle(AsyncValue<Documents?> documentAsync) {
    final theme = ref.watch(themeColorsProvider);

    return documentAsync.when(
      data: (document) {
        if (document == null) return const SizedBox();

        return EmmaUiAnchorTarget(
          anchorKey: DocsEmmaAnchors.documentTitleEditor.anchorKey,

          spec: DocsEmmaAnchors.documentTitleEditor,
          runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
          tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
          child: DocumentTitleEditor(documentId: document.id),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => Text(
        'Error loading title',
        style: TextStyle(color: theme.textColor),
      ),
    );
  }

  Widget _buildHeaderMenuBar(ThemeColors theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BackButtonHously(),
        _DocumentHeaderMenuButton(
          label: 'Plik',
          theme: theme,
          items: _fileMenuItems(),
          onSelected: _handleHeaderMenuAction,
        ),
        _DocumentHeaderMenuButton(
          label: 'Wstaw',
          theme: theme,
          items: _insertMenuItems(),
          onSelected: _handleHeaderMenuAction,
        ),
        _DocumentHeaderMenuButton(
          label: 'Format',
          theme: theme,
          items: _formatMenuItems(),
          onSelected: _handleHeaderMenuAction,
        ),
        _DocumentHeaderMenuButton(
          label: 'Narzędzia',
          theme: theme,
          items: _toolsMenuItems(),
          onSelected: _handleHeaderMenuAction,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ThemeColors theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmmaUiAnchorTarget(
          anchorKey: DocsEmmaAnchors.goToDocumentsButton.anchorKey,

          spec: DocsEmmaAnchors.goToDocumentsButton,
          runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
          tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
          child: Tooltip(
            message: 'Go to Documents',
            child: _HeaderIconButton(
              icon: Icons.description_outlined,
              theme: theme,
              onTap: _navigateToDocuments,
            ),
          ),
        ),
        const SizedBox(width: 6),
        EmmaUiAnchorTarget(
          anchorKey: DocsEmmaAnchors.goToTemplatesButton.anchorKey,

          spec: DocsEmmaAnchors.goToTemplatesButton,
          runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
          tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
          child: Tooltip(
            message: 'Go to Templates',
            child: _HeaderIconButton(
              icon: Icons.dashboard_customize_outlined,
              theme: theme,
              onTap: _navigateToTemplates,
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _popupHeader(String label) {
    final theme = ref.read(themeColorsProvider);

    return PopupMenuItem<String>(
      enabled: false,
      height: 30,
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor.withAlpha(145),
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupAction({
    required String value,
    required IconData icon,
    required String label,
    bool enabled = true,
  }) {
    final theme = ref.read(themeColorsProvider);

    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 40,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: enabled ? theme.textColor : theme.textColor.withAlpha(90),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    enabled ? theme.textColor : theme.textColor.withAlpha(90),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _fileMenuItems() {
    return [
      _popupHeader('Plik'),
      _popupAction(
        value: 'documents',
        icon: Icons.folder_copy_outlined,
        label: 'Moje dokumenty',
      ),
      _popupAction(
        value: 'templates',
        icon: Icons.dashboard_customize_outlined,
        label: 'Biblioteka template',
      ),
      _popupAction(
        value: 'create_template',
        icon: Icons.add_box_outlined,
        label: 'Utwórz template',
      ),
      const PopupMenuDivider(),
      _popupAction(
        value: 'save',
        icon: Icons.save_outlined,
        label: 'Zapisz',
      ),
      _popupAction(
        value: 'version',
        icon: Icons.history_outlined,
        label: 'Zapisz wersję',
      ),
      const PopupMenuDivider(),
      _popupAction(
        value: 'page_setup',
        icon: Icons.tune_outlined,
        label: 'Ustawienia strony',
      ),
      _popupAction(
        value: 'print',
        icon: Icons.print_outlined,
        label: 'Drukuj',
      ),
      _popupAction(
        value: 'pdf',
        icon: Icons.picture_as_pdf_outlined,
        label: 'Generuj PDF',
      ),
    ];
  }

  List<PopupMenuEntry<String>> _insertMenuItems() {
    return [
      _popupHeader('Wstaw'),
      _popupAction(
        value: 'new_page',
        icon: Icons.note_add_outlined,
        label: 'Nowa strona',
      ),
      _popupAction(
        value: 'page_break',
        icon: Icons.splitscreen_outlined,
        label: 'Podział strony',
      ),
      _popupAction(
        value: 'date',
        icon: Icons.today_outlined,
        label: 'Data',
      ),
      _popupAction(
        value: 'line',
        icon: Icons.horizontal_rule,
        label: 'Linia pozioma',
      ),
    ];
  }

  List<PopupMenuEntry<String>> _formatMenuItems() {
    return [
      _popupHeader('Tekst'),
      _popupAction(
        value: 'bold',
        icon: Icons.format_bold,
        label: 'Pogrubienie',
      ),
      _popupAction(
        value: 'italic',
        icon: Icons.format_italic,
        label: 'Kursywa',
      ),
      _popupAction(
        value: 'underline',
        icon: Icons.format_underlined,
        label: 'Podkreślenie',
      ),
      _popupAction(
        value: 'clear',
        icon: Icons.format_clear,
        label: 'Wyczyść formatowanie',
      ),
      const PopupMenuDivider(),
      _popupHeader('Akapit'),
      _popupAction(
        value: 'h1',
        icon: Icons.title,
        label: 'Nagłówek 1',
      ),
      _popupAction(
        value: 'h2',
        icon: Icons.title,
        label: 'Nagłówek 2',
      ),
      _popupAction(
        value: 'h3',
        icon: Icons.title,
        label: 'Nagłówek 3',
      ),
      _popupAction(
        value: 'ul',
        icon: Icons.format_list_bulleted,
        label: 'Lista punktowana',
      ),
      _popupAction(
        value: 'ol',
        icon: Icons.format_list_numbered,
        label: 'Lista numerowana',
      ),
    ];
  }

  List<PopupMenuEntry<String>> _toolsMenuItems() {
    return [
      _popupHeader('Narzędzia'),
      _popupAction(
        value: 'copy',
        icon: Icons.content_copy,
        label: 'Kopiuj zaznaczenie',
      ),
      _popupAction(
        value: 'cut',
        icon: Icons.content_cut,
        label: 'Wytnij zaznaczenie',
      ),
      _popupAction(
        value: 'paste',
        icon: Icons.content_paste,
        label: 'Wklej',
      ),
    ];
  }

  void _handleHeaderMenuAction(String value) {
    switch (value) {
      case 'documents':
        _navigateToDocuments();
        break;

      case 'templates':
        _navigateToTemplates();
        break;

      case 'create_template':
        _onCreateTemplatePressed();
        break;

      case 'save':
        _saveCurrentEditorState();
        break;

      case 'version':
        _saveVersionFromToolbar();
        break;

      case 'page_setup':
        _openPageSetup();
        break;

      case 'print':
        _printDocument();
        break;

      case 'pdf':
        _generateDocument();
        break;

      case 'new_page':
        _insertNewPage();
        break;

      case 'page_break':
        _insertPageBreak();
        break;

      case 'date':
        _insertTextAtSelection(_formattedToday());
        break;

      case 'line':
        _insertTextAtSelection('\n────────────────────────────\n');
        break;

      case 'bold':
        _toggleAttribute(Attribute.bold);
        break;

      case 'italic':
        _toggleAttribute(Attribute.italic);
        break;

      case 'underline':
        _toggleAttribute(Attribute.underline);
        break;

      case 'clear':
        _clearFormatting();
        break;

      case 'h1':
        _toggleAttribute(Attribute.h1);
        break;

      case 'h2':
        _toggleAttribute(Attribute.h2);
        break;

      case 'h3':
        _toggleAttribute(Attribute.h3);
        break;

      case 'ul':
        _toggleAttribute(Attribute.ul);
        break;

      case 'ol':
        _toggleAttribute(Attribute.ol);
        break;

      case 'copy':
        _copySelectedText();
        break;

      case 'cut':
        _cutSelectedText();
        break;

      case 'paste':
        _pasteClipboardText();
        break;
    }
  }

  Future<void> _saveTemplate() async {
    if (!_isEditingTemplateMode || _editingTemplateId == null) {
      _showSnackBar(
        message: 'Nie jesteś w trybie edycji template.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final templateId = _editingTemplateId!;

    final deltaMap = {
      'ops': _controller.document.toDelta().toJson(),
    };

    final style = StyleExtractor.extractStyle(_controller);

    try {
      await DocumentService.updateTemplate(
        templateId: templateId,
        deltaJson: deltaMap,
        styleJson: style,
        ref: ref,
      );

      ref.invalidate(documentTemplatesProvider);

      _lastSentDelta = _controller.document.toDelta();
      _hasLocalUnsavedChanges = false;

      _showSnackBar(
        message:
            'Template "${_editingTemplateName ?? templateId}" saved successfully!',
        backgroundColor: Colors.green,
      );

      if (mounted) {
        setState(() {
          _editorRevision++;
        });
      }
    } catch (e) {
      debugPrint('Detailed error saving template: $e');

      _showSnackBar(
        message: 'Error saving template: $e',
        backgroundColor: Colors.red,
      );
    }
  }
}

class _DocumentHeaderMenuButton extends StatelessWidget {
  final String label;
  final ThemeColors theme;
  final List<PopupMenuEntry<String>> items;
  final ValueChanged<String> onSelected;

  const _DocumentHeaderMenuButton({
    required this.label,
    required this.theme,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: label,
      color: theme.dashboardContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.dashboardContainer.withAlpha(120),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.dashboardBoarder.withAlpha(140),
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: theme.textColor.withAlpha(190),
          ),
        ),
      ),
    );
  }
}

class _EditorToolbarButton extends ConsumerWidget {
  final IconData icon;
  final String? label;
  final String tooltip;
  final VoidCallback onTap;

  const _EditorToolbarButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? 9 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: theme.textColor),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorStatusPill extends ConsumerWidget {
  final IconData icon;
  final String label;

  const _EditorStatusPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.textColor.withAlpha(160)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorModePill extends ConsumerWidget {
  final bool isEditingTemplate;
  final bool isConnected;

  const _EditorModePill({
    required this.isEditingTemplate,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final color = isEditingTemplate
        ? Colors.blue
        : isConnected
            ? Colors.green
            : Colors.orange;

    final icon = isEditingTemplate
        ? Icons.dashboard_customize_outlined
        : isConnected
            ? Icons.cloud_done
            : Icons.cloud_off;

    final label = isEditingTemplate
        ? 'Template'
        : isConnected
            ? 'Online'
            : 'Łączenie';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorUnsavedPill extends ConsumerWidget {
  const _EditorUnsavedPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.amber.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.edit_note_outlined,
            size: 15,
            color: Colors.amber,
          ),
          const SizedBox(width: 6),
          Text(
            'Niezapisane',
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarDivider extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.dashboardBoarder,
    );
  }
}
