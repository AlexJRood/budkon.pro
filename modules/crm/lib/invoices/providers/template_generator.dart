// lib/invoices/template_generator/provider.dart
// State + notifier for invoice template builder.
//
// - Adds logo fields (source/url/file/base64/mime/fit/maxW/maxH)
// - Fixes: model.extra doesn't exist => reads from model.sectionsConfig['logo']
// - Saves logo payload under sections_config.logo

import 'dart:convert';
import 'dart:typed_data';

import 'package:crm/invoices/models/templates.dart';
import 'package:crm/invoices/urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

String _generateId(String prefix) {
  final ts = DateTime.now().microsecondsSinceEpoch;
  return '${prefix}_$ts';
}

class InvoiceSectionConfig {
  final String id;
  final String label;
  final String type; // "system" | "custom"
  final bool visible;

  final String? customText;

  final bool useCustomBranding;
  final String? backgroundColor;
  final String? textColor;
  final int? paddingVertical;
  final bool hasBorder;

  const InvoiceSectionConfig({
    required this.id,
    required this.label,
    required this.type,
    this.visible = true,
    this.customText,
    this.useCustomBranding = false,
    this.backgroundColor,
    this.textColor,
    this.paddingVertical,
    this.hasBorder = true,
  });

  InvoiceSectionConfig copyWith({
    String? id,
    String? label,
    String? type,
    bool? visible,
    String? customText,
    bool? useCustomBranding,
    String? backgroundColor,
    String? textColor,
    int? paddingVertical,
    bool? hasBorder,
  }) {
    return InvoiceSectionConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      visible: visible ?? this.visible,
      customText: customText ?? this.customText,
      useCustomBranding: useCustomBranding ?? this.useCustomBranding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      paddingVertical: paddingVertical ?? this.paddingVertical,
      hasBorder: hasBorder ?? this.hasBorder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'visible': visible,
      if (customText != null) 'custom_text': customText,
      'use_custom_branding': useCustomBranding,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (textColor != null) 'text_color': textColor,
      if (paddingVertical != null) 'padding_vertical': paddingVertical,
      'has_border': hasBorder,
    };
  }

  factory InvoiceSectionConfig.fromJson(Map<String, dynamic> json) {
    return InvoiceSectionConfig(
      id: json['id'] as String? ?? _generateId('section'),
      label: json['label'] as String? ?? 'Section',
      type: json['type'] as String? ?? 'system',
      visible: json['visible'] as bool? ?? true,
      customText: json['custom_text'] as String?,
      useCustomBranding: json['use_custom_branding'] as bool? ?? false,
      backgroundColor: json['background_color'] as String?,
      textColor: json['text_color'] as String?,
      paddingVertical: json['padding_vertical'] as int?,
      hasBorder: json['has_border'] as bool? ?? true,
    );
  }
}

List<InvoiceSectionConfig> _defaultSections() {
  return const [
    InvoiceSectionConfig(id: 'header', label: 'Header', type: 'system', visible: true),
    InvoiceSectionConfig(id: 'parties', label: 'Seller & buyer', type: 'system', visible: true),
    InvoiceSectionConfig(id: 'items', label: 'Items table', type: 'system', visible: true),
    InvoiceSectionConfig(id: 'payments', label: 'Payments & bank', type: 'system', visible: true),
    InvoiceSectionConfig(id: 'footer', label: 'Footer / notes', type: 'system', visible: true),
  ];
}

class InvoiceTemplateFormState {
  final int? id;
  final String name;
  final String scope;
  final String paperSize;
  final String orientation;

  final String? logoUrl;

  // Branding colors
  final String primaryColor;   // brand
  final String secondaryColor; // borders
  final String accentColor;    // text
  final String fontFamily;

  final int marginTop;
  final int marginBottom;
  final int marginLeft;
  final int marginRight;

  final String logoPosition;
  final String logoPlacement;
  final int sectionSpacing;

  final List<InvoiceSectionConfig> sections;
  final String? activeSectionId;

  final bool showLogo;
  final bool showPaymentTerms;
  final bool showBankAccount;
  final List<String> columns;

  final String footerText;
  final String extraNotesLabel;
  final String paymentTermsLabel;

  // ---- NEW: logo config ----
  final String logoSource; // 'none' | 'url' | 'file'
  final String? logoFileBase64;
  final String? logoMime;
  final String logoFit; // contain/cover/fill/fitWidth/fitHeight
  final int logoMaxWidth;
  final int logoMaxHeight;

  final bool isSaving;
  final String? errorMessage;

  InvoiceTemplateFormState({
    this.id,
    this.name = '',
    this.scope = 'company',
    this.paperSize = 'A4',
    this.orientation = 'portrait',
    this.logoUrl,

    // ✅ Better defaults for paper style
    this.primaryColor = '#2F80ED',
    this.secondaryColor = '#E0E0E0',
    this.accentColor = '#111111',
    this.fontFamily = 'Inter',

    this.marginTop = 15,
    this.marginBottom = 15,
    this.marginLeft = 10,
    this.marginRight = 10,

    this.logoPosition = 'left',
    this.logoPlacement = 'header',
    this.sectionSpacing = 12,
    List<InvoiceSectionConfig>? sections,
    this.activeSectionId,

    this.showLogo = true,
    this.showPaymentTerms = true,
    this.showBankAccount = true,
    this.columns = const [
      'name',
      'quantity',
      'unit_net_price',
      'vat',
      'line_gross_amount',
    ],

    this.footerText = '',
    this.extraNotesLabel = 'Additional notes',
    this.paymentTermsLabel = 'Payment terms',

    // logo config defaults
    this.logoSource = 'url',
    this.logoFileBase64,
    this.logoMime,
    this.logoFit = 'contain',
    this.logoMaxWidth = 140,
    this.logoMaxHeight = 80,

    this.isSaving = false,
    this.errorMessage,
  }) : sections = sections ?? _defaultSections();

  Map<String, dynamic> toApiPayload() {
    return {
      'name': name,
      'scope': scope,
      'paper_size': paperSize,
      'orientation': orientation,

      // Keep logoUrl on root for backward compatibility
      'logo_url': logoUrl,

      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
      'font_family': fontFamily,

      'margin_top': marginTop,
      'margin_bottom': marginBottom,
      'margin_left': marginLeft,
      'margin_right': marginRight,

      'sections_config': {
        'show_logo': showLogo,
        'show_payment_terms': showPaymentTerms,
        'show_bank_account': showBankAccount,
        'columns': columns,
        'logo_position': logoPosition,
        'logo_placement': logoPlacement,
        'section_spacing': sectionSpacing,
        'sections': sections.map((s) => s.toJson()).toList(),

        // ✅ new logo payload (safe for backend: it can ignore)
        'logo': {
          'source': logoSource,
          'url': logoUrl,
          'file_base64': logoFileBase64,
          'mime': logoMime,
          'fit': logoFit,
          'max_width': logoMaxWidth,
          'max_height': logoMaxHeight,
        },
      },

      'footer_text': footerText,
      'extra_notes_label': extraNotesLabel,
      'payment_terms_label': paymentTermsLabel,
    };
  }

  InvoiceTemplateFormState copyWith({
    int? id,
    String? name,
    String? scope,
    String? paperSize,
    String? orientation,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? fontFamily,
    int? marginTop,
    int? marginBottom,
    int? marginLeft,
    int? marginRight,
    String? logoPosition,
    String? logoPlacement,
    int? sectionSpacing,
    List<InvoiceSectionConfig>? sections,
    String? activeSectionId,
    bool? showLogo,
    bool? showPaymentTerms,
    bool? showBankAccount,
    List<String>? columns,
    String? footerText,
    String? extraNotesLabel,
    String? paymentTermsLabel,

    // logo config
    String? logoSource,
    String? logoFileBase64,
    String? logoMime,
    String? logoFit,
    int? logoMaxWidth,
    int? logoMaxHeight,

    bool? isSaving,
    String? errorMessage,
  }) {
    return InvoiceTemplateFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      scope: scope ?? this.scope,
      paperSize: paperSize ?? this.paperSize,
      orientation: orientation ?? this.orientation,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      logoPosition: logoPosition ?? this.logoPosition,
      logoPlacement: logoPlacement ?? this.logoPlacement,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      sections: sections ?? this.sections,
      activeSectionId: activeSectionId ?? this.activeSectionId,
      showLogo: showLogo ?? this.showLogo,
      showPaymentTerms: showPaymentTerms ?? this.showPaymentTerms,
      showBankAccount: showBankAccount ?? this.showBankAccount,
      columns: columns ?? this.columns,
      footerText: footerText ?? this.footerText,
      extraNotesLabel: extraNotesLabel ?? this.extraNotesLabel,
      paymentTermsLabel: paymentTermsLabel ?? this.paymentTermsLabel,

      logoSource: logoSource ?? this.logoSource,
      logoFileBase64: logoFileBase64 ?? this.logoFileBase64,
      logoMime: logoMime ?? this.logoMime,
      logoFit: logoFit ?? this.logoFit,
      logoMaxWidth: logoMaxWidth ?? this.logoMaxWidth,
      logoMaxHeight: logoMaxHeight ?? this.logoMaxHeight,

      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  factory InvoiceTemplateFormState.fromModel(InvoiceTemplateModel model) {
    final sectionsCfg = model.sectionsConfig;

    // ---- parse sections list safely ----
    final dynamic rawSections = sectionsCfg['sections'];
    List<InvoiceSectionConfig> parsedSections;

    if (rawSections is List) {
      parsedSections = [];
      for (final e in rawSections) {
        if (e is Map<String, dynamic>) {
          parsedSections.add(InvoiceSectionConfig.fromJson(e));
        } else if (e is Map) {
          parsedSections.add(
            InvoiceSectionConfig.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
          );
        }
      }
      if (parsedSections.isEmpty) parsedSections = _defaultSections();
    } else {
      parsedSections = _defaultSections();
    }

    // ---- FIX: model.extra doesn't exist => read from sectionsConfig['logo'] ----
    final dynamic rawLogo = sectionsCfg['logo'];
    Map<String, dynamic> logo;
    if (rawLogo is Map<String, dynamic>) {
      logo = rawLogo;
    } else if (rawLogo is Map) {
      logo = rawLogo.map((k, v) => MapEntry(k.toString(), v));
    } else {
      logo = <String, dynamic>{};
    }

    final String logoSource = (logo['source'] ?? 'url').toString();
    final String? logoFileBase64 = logo['file_base64'] as String?;
    final String? logoMime = logo['mime'] as String?;
    final String logoFit = (logo['fit'] ?? 'contain').toString();
    final int logoMaxWidth = int.tryParse((logo['max_width'] ?? 140).toString()) ?? 140;
    final int logoMaxHeight = int.tryParse((logo['max_height'] ?? 80).toString()) ?? 80;

    // Back-compat: if backend only sends root logo_url
    final String? logoUrl = (logo['url'] as String?) ?? model.logoUrl;

    return InvoiceTemplateFormState(
      id: model.id,
      name: model.name,
      scope: model.scope,
      paperSize: model.paperSize,
      orientation: model.orientation,
      logoUrl: logoUrl,
      primaryColor: model.primaryColor,
      secondaryColor: model.secondaryColor,
      accentColor: model.accentColor,
      fontFamily: model.fontFamily,
      marginTop: model.marginTop,
      marginBottom: model.marginBottom,
      marginLeft: model.marginLeft,
      marginRight: model.marginRight,

      showLogo: sectionsCfg['show_logo'] as bool? ?? true,
      showPaymentTerms: sectionsCfg['show_payment_terms'] as bool? ?? true,
      showBankAccount: sectionsCfg['show_bank_account'] as bool? ?? true,
      columns: (sectionsCfg['columns'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      logoPosition: sectionsCfg['logo_position'] as String? ?? 'left',
      logoPlacement: sectionsCfg['logo_placement'] as String? ?? 'header',
      sectionSpacing: sectionsCfg['section_spacing'] as int? ?? 12,
      sections: parsedSections,

      footerText: model.footerText,
      extraNotesLabel: model.extraNotesLabel,
      paymentTermsLabel: model.paymentTermsLabel,
      activeSectionId: null,

      logoSource: logoSource,
      logoFileBase64: logoFileBase64,
      logoMime: logoMime,
      logoFit: logoFit,
      logoMaxWidth: logoMaxWidth,
      logoMaxHeight: logoMaxHeight,
    );
  }
}

class InvoiceTemplateFormNotifier extends StateNotifier<InvoiceTemplateFormState> {
  final Ref ref;

  InvoiceTemplateFormNotifier(this.ref) : super(InvoiceTemplateFormState());

  void loadFromModel(InvoiceTemplateModel model) {
    state = InvoiceTemplateFormState.fromModel(model);
  }

  void reset() {
    state = InvoiceTemplateFormState();
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setScope(String value) => state = state.copyWith(scope: value);
  void setPaperSize(String value) => state = state.copyWith(paperSize: value);
  void setOrientation(String value) => state = state.copyWith(orientation: value);

  void setLogoUrl(String value) => state = state.copyWith(logoUrl: value);
  void setPrimaryColor(String value) => state = state.copyWith(primaryColor: value);
  void setSecondaryColor(String value) => state = state.copyWith(secondaryColor: value);
  void setAccentColor(String value) => state = state.copyWith(accentColor: value);
  void setFontFamily(String value) => state = state.copyWith(fontFamily: value);

  void setMargins({int? top, int? bottom, int? left, int? right}) {
    state = state.copyWith(
      marginTop: top ?? state.marginTop,
      marginBottom: bottom ?? state.marginBottom,
      marginLeft: left ?? state.marginLeft,
      marginRight: right ?? state.marginRight,
    );
  }

  void setLogoPosition(String value) => state = state.copyWith(logoPosition: value);
  void setLogoPlacement(String value) => state = state.copyWith(logoPlacement: value);
  void setSectionSpacing(int value) => state = state.copyWith(sectionSpacing: value);

  void toggleShowLogo(bool value) => state = state.copyWith(showLogo: value);
  void toggleShowPaymentTerms(bool value) => state = state.copyWith(showPaymentTerms: value);
  void toggleShowBankAccount(bool value) => state = state.copyWith(showBankAccount: value);

  void toggleColumn(String columnKey) {
    final columns = List<String>.from(state.columns);
    if (columns.contains(columnKey)) {
      columns.remove(columnKey);
    } else {
      columns.add(columnKey);
    }
    state = state.copyWith(columns: columns);
  }

  void setFooterText(String value) => state = state.copyWith(footerText: value);
  void setExtraNotesLabel(String value) => state = state.copyWith(extraNotesLabel: value);
  void setPaymentTermsLabel(String value) => state = state.copyWith(paymentTermsLabel: value);

  void setActiveSection(String? id) {
    state = state.copyWith(activeSectionId: id);
  }

  void reorderSections(int oldIndex, int newIndex) {
    final list = List<InvoiceSectionConfig>.from(state.sections);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(sections: list);
  }

  void setSectionVisible(String id, bool visible) {
    final updated = state.sections.map((s) => s.id == id ? s.copyWith(visible: visible) : s).toList();
    state = state.copyWith(sections: updated);
  }

  void removeSection(String id) {
    final updated = state.sections.where((s) => s.id != id).toList(growable: false);
    if (updated.isEmpty) return;

    String? newActive = state.activeSectionId;
    if (state.activeSectionId == id) {
      newActive = updated.isNotEmpty ? updated.first.id : null;
    }
    state = state.copyWith(sections: updated, activeSectionId: newActive);
  }

  void addSection(String type) {
    final current = List<InvoiceSectionConfig>.from(state.sections);
    final existingIds = current.map((s) => s.id).toSet();

    InvoiceSectionConfig newSection;

    switch (type) {
      case 'header':
      case 'parties':
      case 'items':
      case 'payments':
      case 'footer':
        if (existingIds.contains(type)) return;
        String label;
        switch (type) {
          case 'header':
            label = 'Header';
            break;
          case 'parties':
            label = 'Seller & buyer';
            break;
          case 'items':
            label = 'Items table';
            break;
          case 'payments':
            label = 'Payments & bank';
            break;
          case 'footer':
            label = 'Footer / notes';
            break;
          default:
            label = type;
        }
        newSection = InvoiceSectionConfig(id: type, label: label, type: 'system', visible: true);
        break;

      case 'custom':
      default:
        final customCount = current.where((s) => s.type == 'custom').length + 1;
        final id = _generateId('custom');
        newSection = InvoiceSectionConfig(
          id: id,
          label: 'Custom section $customCount',
          type: 'custom',
          visible: true,
          customText: 'Custom content $customCount',
        );
    }

    current.add(newSection);
    state = state.copyWith(sections: current, activeSectionId: newSection.id);
  }

  void updateSectionLabel(String id, String label) {
    final updated = state.sections.map((s) => s.id == id ? s.copyWith(label: label) : s).toList();
    state = state.copyWith(sections: updated);
  }

  void updateSectionCustomText(String id, String text) {
    final updated = state.sections.map((s) => s.id == id ? s.copyWith(customText: text) : s).toList();
    state = state.copyWith(sections: updated);
  }

  void updateSectionBranding(
    String id, {
    bool? useCustomBranding,
    String? backgroundColor,
    String? textColor,
    int? paddingVertical,
    bool? hasBorder,
  }) {
    final updated = state.sections.map((s) {
      if (s.id != id) return s;
      return s.copyWith(
        useCustomBranding: useCustomBranding ?? s.useCustomBranding,
        backgroundColor: backgroundColor ?? s.backgroundColor,
        textColor: textColor ?? s.textColor,
        paddingVertical: paddingVertical ?? s.paddingVertical,
        hasBorder: hasBorder ?? s.hasBorder,
      );
    }).toList();
    state = state.copyWith(sections: updated);
  }

  // =======================
  // LOGO METHODS
  // =======================

  void setLogoSource(String value) {
    // When switching source, do not destroy URL unless needed
    if (value == 'none') {
      state = state.copyWith(logoSource: value, logoFileBase64: null, logoMime: null);
      return;
    }
    if (value == 'url') {
      state = state.copyWith(logoSource: value, logoFileBase64: null, logoMime: null);
      return;
    }
    if (value == 'file') {
      state = state.copyWith(logoSource: value);
      return;
    }
    state = state.copyWith(logoSource: value);
  }

  void setLogoFileBase64(String? value) => state = state.copyWith(logoFileBase64: value);
  void setLogoMime(String? value) => state = state.copyWith(logoMime: value);
  void setLogoFit(String value) => state = state.copyWith(logoFit: value);
  void setLogoMaxWidth(int value) => state = state.copyWith(logoMaxWidth: value);
  void setLogoMaxHeight(int value) => state = state.copyWith(logoMaxHeight: value);

  void clearLogoFile() {
    state = state.copyWith(logoFileBase64: null, logoMime: null);
  }

  // Helper: read dropped file bytes (supports XFile-like API).
  Future<Uint8List> readDroppedFileAsBytes(dynamic file) async {
    // Most platforms: XFile from cross_file has readAsBytes()
    final bytes = await file.readAsBytes();
    if (bytes is Uint8List) return bytes;
    return Uint8List.fromList(List<int>.from(bytes));
  }

  Future<String> tryGetFileName(dynamic file) async {
    // XFile has name getter; fallback empty
    try {
      final n = file.name;
      if (n is String) return n;
    } catch (_) {}
    return '';
  }

  String guessMimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  // =======================
  // API
  // =======================

  Future<void> downloadSampleInvoice() async {
    debugPrint('Download sample invoice – TODO implement API call');
  }

  Future<void> saveTemplate() async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Name is required');
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final payload = state.toApiPayload();

      Response? resp;
      if (state.id == null) {
        resp = await ApiServices.post(
          URLsInvoice.invoiceTemplates,
          data: payload,
          hasToken: true,
          ref: ref,
        );
      } else {
        final url = '${URLsInvoice.invoiceTemplates}${state.id}/';
        resp = await ApiServices.patch(
          url,
          data: jsonEncode(payload),
          hasToken: true,
          ref: ref,
        );
      }

      if (resp == null) {
        throw Exception('No response from server');
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        state = state.copyWith(isSaving: false, errorMessage: null);
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save template: ${resp.statusCode}',
        );
      }
    } catch (e, st) {
      debugPrint('Error saving invoice template: $e\n$st');
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }
}

final invoiceTemplateFormProvider =
    StateNotifierProvider<InvoiceTemplateFormNotifier, InvoiceTemplateFormState>(
  (ref) => InvoiceTemplateFormNotifier(ref),
);
