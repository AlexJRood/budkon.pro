class InvoiceItemPresetModel {
  final int id;
  final String uuid;
  final String scope; // "company" | "user"
  final int? company; // id
  final int? owner;   // id
  final String name;
  final String? description;
  final String unit;
  final String defaultQuantity; // trzymamy jako String (pod formularz)
  final String unitNetPrice;    // String – łatwiej w polu tekstowym
  final String vatRate;         // j.w.
  final String currency;
  final bool isActive;
  final String? internalCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceItemPresetModel({
    required this.id,
    required this.uuid,
    required this.scope,
    required this.company,
    required this.owner,
    required this.name,
    required this.description,
    required this.unit,
    required this.defaultQuantity,
    required this.unitNetPrice,
    required this.vatRate,
    required this.currency,
    required this.isActive,
    required this.internalCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceItemPresetModel.fromJson(Map<String, dynamic> json) {
    String _numToString(dynamic v, {String fallback = '0'}) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is num) return v.toString();
      return fallback;
    }

    final createdAtStr = json['created_at'] as String?;
    final updatedAtStr = json['updated_at'] as String?;

    return InvoiceItemPresetModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      scope: json['scope'] as String,
      company: json['company'] as int?, // id, bez fromJson
      owner: json['owner'] as int?,     // id, bez fromJson
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: (json['unit'] as String?) ?? 'szt',
      defaultQuantity: _numToString(json['default_quantity'], fallback: '1'),
      unitNetPrice: _numToString(json['unit_net_price'], fallback: '0.00'),
      vatRate: _numToString(json['vat_rate'], fallback: '23.00'),
      currency: (json['currency'] as String?) ?? 'PLN',
      isActive: json['is_active'] as bool? ?? true,
      internalCode: json['internal_code'] as String?,
      createdAt: createdAtStr != null
          ? DateTime.parse(createdAtStr)
          : DateTime.now(),
      updatedAt: updatedAtStr != null
          ? DateTime.parse(updatedAtStr)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'scope': scope,
      'company': company,
      'owner': owner,
      'name': name,
      'description': description,
      'unit': unit,
      'default_quantity': defaultQuantity,
      'unit_net_price': unitNetPrice,
      'vat_rate': vatRate,
      'currency': currency,
      'is_active': isActive,
      'internal_code': internalCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InvoiceItemPresetModel copyWith({
    int? id,
    String? uuid,
    String? scope,
    int? company,
    int? owner,
    String? name,
    String? description,
    String? unit,
    String? defaultQuantity,
    String? unitNetPrice,
    String? vatRate,
    String? currency,
    bool? isActive,
    String? internalCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceItemPresetModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      scope: scope ?? this.scope,
      company: company ?? this.company,
      owner: owner ?? this.owner,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      unitNetPrice: unitNetPrice ?? this.unitNetPrice,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      internalCode: internalCode ?? this.internalCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
