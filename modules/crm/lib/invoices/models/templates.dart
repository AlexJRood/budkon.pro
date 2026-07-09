// lib/invoices/models/templates.dart

class InvoiceTemplateModel {
  final int id;
  final String name;
  final String scope; // 'company' | 'user'
  final bool isDefault;

  final String paperSize;    // 'A4', 'Letter'
  final String orientation;  // 'portrait' | 'landscape'

  final String? logoUrl;

  // ✅ NEW: advanced logo fields (optional)
  // - source: 'none' | 'url' | 'file'
  final String? logoSource;
  final String? logoFileBase64;
  final String? logoMime;
  final String? logoFit; // 'contain' | 'cover' | 'fill'
  final int? logoMaxWidth;
  final int? logoMaxHeight;

  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String fontFamily;

  final int marginTop;
  final int marginBottom;
  final int marginLeft;
  final int marginRight;

  /// Raw sections config from backend.
  final Map<String, dynamic> sectionsConfig;

  final String footerText;
  final String extraNotesLabel;
  final String paymentTermsLabel;

  InvoiceTemplateModel({
    required this.id,
    required this.name,
    required this.scope,
    required this.isDefault,
    required this.paperSize,
    required this.orientation,
    this.logoUrl,

    // ✅ NEW
    this.logoSource,
    this.logoFileBase64,
    this.logoMime,
    this.logoFit,
    this.logoMaxWidth,
    this.logoMaxHeight,

    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.fontFamily,
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
    required this.sectionsConfig,
    required this.footerText,
    required this.extraNotesLabel,
    required this.paymentTermsLabel,
  });

  factory InvoiceTemplateModel.fromJson(Map<String, dynamic> json) {
    // Safe cast for sections_config – backend might send Map<dynamic,dynamic>
    final rawSectionsConfig = json['sections_config'];
    Map<String, dynamic> sectionsConfig;

    if (rawSectionsConfig is Map<String, dynamic>) {
      sectionsConfig = rawSectionsConfig;
    } else if (rawSectionsConfig is Map) {
      sectionsConfig = rawSectionsConfig.map((k, v) => MapEntry(k.toString(), v));
    } else {
      sectionsConfig = <String, dynamic>{};
    }

    int? _intOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return InvoiceTemplateModel(
      id: json['id'] as int,
      name: json['name'] as String,
      scope: json['scope'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      paperSize: json['paper_size'] as String? ?? 'A4',
      orientation: json['orientation'] as String? ?? 'portrait',
      logoUrl: json['logo_url'] as String?,

      // ✅ NEW (top-level fields)
      logoSource: json['logo_source'] as String?,
      logoFileBase64: json['logo_file_base64'] as String?,
      logoMime: json['logo_mime'] as String?,
      logoFit: json['logo_fit'] as String?,
      logoMaxWidth: _intOrNull(json['logo_max_width']),
      logoMaxHeight: _intOrNull(json['logo_max_height']),

      primaryColor: json['primary_color'] as String? ?? '#000000',
      secondaryColor: json['secondary_color'] as String? ?? '#666666',
      accentColor: json['accent_color'] as String? ?? '#F5F5F5',
      fontFamily: json['font_family'] as String? ?? 'Inter',
      marginTop: json['margin_top'] as int? ?? 15,
      marginBottom: json['margin_bottom'] as int? ?? 15,
      marginLeft: json['margin_left'] as int? ?? 10,
      marginRight: json['margin_right'] as int? ?? 10,
      sectionsConfig: sectionsConfig,
      footerText: json['footer_text'] as String? ?? '',
      extraNotesLabel: json['extra_notes_label'] as String? ?? 'Additional notes',
      paymentTermsLabel: json['payment_terms_label'] as String? ?? 'Payment terms',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'scope': scope,
      'paper_size': paperSize,
      'orientation': orientation,
      'logo_url': logoUrl,

      // ✅ NEW
      'logo_source': logoSource,
      'logo_file_base64': logoFileBase64,
      'logo_mime': logoMime,
      'logo_fit': logoFit,
      'logo_max_width': logoMaxWidth,
      'logo_max_height': logoMaxHeight,

      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
      'font_family': fontFamily,
      'margin_top': marginTop,
      'margin_bottom': marginBottom,
      'margin_left': marginLeft,
      'margin_right': marginRight,
      'sections_config': sectionsConfig,
      'footer_text': footerText,
      'extra_notes_label': extraNotesLabel,
      'payment_terms_label': paymentTermsLabel,
    };
  }

  InvoiceTemplateModel copyWith({
    String? name,
    String? scope,
    String? paperSize,
    String? orientation,
    String? logoUrl,

    // ✅ NEW
    String? logoSource,
    String? logoFileBase64,
    String? logoMime,
    String? logoFit,
    int? logoMaxWidth,
    int? logoMaxHeight,

    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? fontFamily,
    int? marginTop,
    int? marginBottom,
    int? marginLeft,
    int? marginRight,
    Map<String, dynamic>? sectionsConfig,
    String? footerText,
    String? extraNotesLabel,
    String? paymentTermsLabel,
  }) {
    return InvoiceTemplateModel(
      id: id,
      name: name ?? this.name,
      scope: scope ?? this.scope,
      isDefault: isDefault,
      paperSize: paperSize ?? this.paperSize,
      orientation: orientation ?? this.orientation,
      logoUrl: logoUrl ?? this.logoUrl,

      // ✅ NEW
      logoSource: logoSource ?? this.logoSource,
      logoFileBase64: logoFileBase64 ?? this.logoFileBase64,
      logoMime: logoMime ?? this.logoMime,
      logoFit: logoFit ?? this.logoFit,
      logoMaxWidth: logoMaxWidth ?? this.logoMaxWidth,
      logoMaxHeight: logoMaxHeight ?? this.logoMaxHeight,

      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      sectionsConfig: sectionsConfig ?? this.sectionsConfig,
      footerText: footerText ?? this.footerText,
      extraNotesLabel: extraNotesLabel ?? this.extraNotesLabel,
      paymentTermsLabel: paymentTermsLabel ?? this.paymentTermsLabel,
    );
  }
}
