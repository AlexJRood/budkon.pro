// =====================================================================
// lib/router_web/modules/docs_routes.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:docs/screens/cloud_docs_screen.dart'
    deferred as docs_editor;      // DocumentEditorScreen
import 'package:docs/screens/documents_list_screen.dart'
    deferred as docs_library;     // DocsLibraryScreen + DocsLibraryTab
import 'package:docs/screens/temp_fill_screen.dart'
    deferred as docs_temp_fill;   // TemplateFillScreen

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _routeStringArg(dynamic data, BeamState state, String key) {
  if (data is Map) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  final q = state.uri.queryParameters[key];
  if (q != null && q.trim().isNotEmpty) return q.trim();
  return null;
}

bool _routeBoolArg(
  dynamic data,
  BeamState state,
  String key, {
  bool fallback = false,
}) {
  final raw = _routeStringArg(data, state, key);
  if (raw == null) return fallback;
  final n = raw.toLowerCase().trim();
  if (n == 'true' || n == '1' || n == 'yes' || n == 'tak') return true;
  if (n == 'false' || n == '0' || n == 'no' || n == 'nie') return false;
  return fallback;
}

String? _routeDocumentIdArg(dynamic data, BeamState state) {
  if (data is String && data.trim().isNotEmpty) return data.trim();
  if (data is Map) {
    final direct = _routeStringArg(data, state, 'documentId') ??
        _routeStringArg(data, state, 'document_id') ??
        _routeStringArg(data, state, 'docId') ??
        _routeStringArg(data, state, 'doc_id') ??
        _routeStringArg(data, state, 'id');
    if (direct != null) return direct;

    final doc = data['document'];
    if (doc is String && doc.trim().isNotEmpty) return doc.trim();
    if (doc is Map) {
      final nested = doc['id'] ?? doc['documentId'] ?? doc['document_id'] ??
          doc['docId'] ?? doc['doc_id'];
      if (nested != null && nested.toString().trim().isNotEmpty) {
        return nested.toString().trim();
      }
    }
  }
  return _routeStringArg(data, state, 'documentId') ??
      _routeStringArg(data, state, 'document_id') ??
      _routeStringArg(data, state, 'docId') ??
      _routeStringArg(data, state, 'doc_id') ??
      _routeStringArg(data, state, 'id');
}

// Local tab sentinel to capture tab choice before deferred load
bool _isTemplatesTab(dynamic data, BeamState state) {
  final tab = _routeStringArg(data, state, 'tab')?.toLowerCase().trim();
  return tab == 'template' || tab == 'templates' || tab == 'templatki';
}

// ── Route map ────────────────────────────────────────────────────────────────

final Map<Pattern, BeamRouteBuilder> docsRoutes = {
  Routes.docs: (context, state, data) {
    final documentId = _routeDocumentIdArg(data, state);
    final templateId = _routeStringArg(data, state, 'templateId') ??
        _routeStringArg(data, state, 'template_id');
    final mode = _routeStringArg(data, state, 'mode');

    final createBlank = _routeBoolArg(data, state, 'createBlank') ||
        _routeBoolArg(data, state, 'create_blank') ||
        mode == 'new' || mode == 'create' || mode == 'blank';

    final isEditingTemplate =
        _routeBoolArg(data, state, 'isEditingTemplate') ||
            mode == 'template_edit';

    final keyValue = documentId ?? templateId ?? mode ?? 'editor';

    setupMetaTag(context);
    return BeamPage(
      key: ValueKey('${Routes.docs}_$keyValue'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        docs_editor.loadLibrary,
        () => docs_editor.DocumentEditorScreen(
          routeData: data,
          routeDocumentId: documentId,
          routeTemplateId: templateId,
          routeTemplate: null,
          routeMode: mode,
          routeCreateBlank: createBlank,
          routeIsEditingTemplate: isEditingTemplate,
        ),
      ),
    );
  },

  Routes.docsLibrary: (context, state, data) {
    final isTemplates = _isTemplatesTab(data, state);
    final title = _routeStringArg(data, state, 'title') ?? 'Dokumenty';

    setupMetaTag(context);
    return BeamPage(
      key: ValueKey('${Routes.docsLibrary}_${isTemplates ? 'templates' : 'documents'}'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        docs_library.loadLibrary,
        () => docs_library.DocsLibraryScreen(
          initialTab: isTemplates
              ? docs_library.DocsLibraryTab.templates
              : docs_library.DocsLibraryTab.documents,
          title: title,
          documentEditorRoute: Routes.docs,
          templateFillRoute: Routes.docsTemplateFill,
        ),
      ),
    );
  },

  Routes.docsTemplateFill: (context, state, data) {
    final templateId = _routeStringArg(data, state, 'templateId') ??
        _routeStringArg(data, state, 'template_id');

    setupMetaTag(context);
    return BeamPage(
      key: ValueKey('${Routes.docsTemplateFill}_${templateId ?? 'new'}'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        docs_temp_fill.loadLibrary,
        () => docs_temp_fill.TemplateFillScreen(
          template: null,
          templateId: templateId,
          documentEditorRoute: Routes.docs,
        ),
      ),
    );
  },
};
