import 'dart:convert';

import 'package:crm/invoices/models/invoice_item.dart';
import 'package:crm/invoices/urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';



/// List provider with optional search.
/// Handles BOTH payload shapes:
/// 1) DRF pagination: { "count":..., "results":[...] }
/// 2) plain list: [ {...}, {...} ]
final invoiceItemPresetListProvider =
    FutureProvider.autoDispose.family<List<InvoiceItemPresetModel>, String?>(
  (ref, search) async {
    // ✅ prevent autoDispose from killing the request while bottomSheet rebuilds
    final link = ref.keepAlive();
    ref.onDispose(link.close);

    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final Response? resp = await ApiServices.get(
      URLsInvoice.invoiceItemPresets,
      hasToken: true,
      ref: ref,
      queryParameters: queryParams,
    );

    if (resp == null) {
      throw Exception('No response from server');
    }

    if (resp.statusCode != 200) {
      debugPrint(
        'invoiceItemPresetListProvider bad status=${resp.statusCode} dataType=${resp.data.runtimeType}',
      );
      throw Exception('Failed to load presets: ${resp.statusCode}');
    }

    dynamic data;
    final raw = resp.data;

    // ---- bytes -> json
    if (raw is Uint8List) {
      final str = utf8.decode(raw);
      try {
        data = jsonDecode(str);
      } catch (e) {
        debugPrint('invoiceItemPresetListProvider JSON decode error: $e');
        debugPrint('Raw text (first 300): ${str.substring(0, str.length > 300 ? 300 : str.length)}');
        rethrow;
      }
    } else {
      data = raw;
    }

    debugPrint('invoiceItemPresetListProvider root=${data.runtimeType}');

    // ✅ Accept both: Map(with results) or List
    List<dynamic> results;

    if (data is Map) {
      final dynamic rawResults = data['results'];

      // Sometimes backend returns {"results": null} when empty; handle gracefully
      if (rawResults == null) {
        results = const [];
      } else if (rawResults is List) {
        results = rawResults;
      } else {
        debugPrint('Invalid "results" type: ${rawResults.runtimeType}');
        throw Exception('Invalid "results" field type: ${rawResults.runtimeType}');
      }
    } else if (data is List) {
      results = data;
    } else {
      throw Exception('Invalid presets payload root: ${data.runtimeType}');
    }

    final list = <InvoiceItemPresetModel>[];

    for (final e in results) {
      if (e is Map<String, dynamic>) {
        list.add(InvoiceItemPresetModel.fromJson(e));
      } else if (e is Map) {
        list.add(
          InvoiceItemPresetModel.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      } else {
        debugPrint(
          'invoiceItemPresetListProvider: skipping non-map element: ${e.runtimeType} value=$e',
        );
      }
    }

    debugPrint('invoiceItemPresetListProvider parsed=${list.length}');
    return list;
  },
);





/// Local form state for create/edit.
class InvoiceItemPresetFormState {
  final int? id;
  final String scope; // "company" | "user"
  final String name;
  final String description;
  final String unit;
  final String defaultQuantity;
  final String unitNetPrice;
  final String vatRate;
  final String currency;
  final bool isActive;
  final String internalCode;
  final bool isSaving;
  final String? errorMessage;

  InvoiceItemPresetFormState({
    this.id,
    this.scope = 'company',
    this.name = '',
    this.description = '',
    this.unit = 'szt',
    this.defaultQuantity = '1',
    this.unitNetPrice = '0.00',
    this.vatRate = '23.00',
    this.currency = 'PLN',
    this.isActive = true,
    this.internalCode = '',
    this.isSaving = false,
    this.errorMessage,
  });

  InvoiceItemPresetFormState copyWith({
    int? id,
    String? scope,
    String? name,
    String? description,
    String? unit,
    String? defaultQuantity,
    String? unitNetPrice,
    String? vatRate,
    String? currency,
    bool? isActive,
    String? internalCode,
    bool? isSaving,
    String? errorMessage,
  }) {
    return InvoiceItemPresetFormState(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      unitNetPrice: unitNetPrice ?? this.unitNetPrice,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      internalCode: internalCode ?? this.internalCode,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'scope': scope,
      'name': name,
      'description': description.isEmpty ? null : description,
      'unit': unit,
      'default_quantity': defaultQuantity,
      'unit_net_price': unitNetPrice,
      'vat_rate': vatRate,
      'currency': currency,
      'is_active': isActive,
      'internal_code': internalCode.isEmpty ? null : internalCode,
    };
  }

  factory InvoiceItemPresetFormState.fromModel(
      InvoiceItemPresetModel model) {
    return InvoiceItemPresetFormState(
      id: model.id,
      scope: model.scope,
      name: model.name,
      description: model.description ?? '',
      unit: model.unit,
      defaultQuantity: model.defaultQuantity,
      unitNetPrice: model.unitNetPrice,
      vatRate: model.vatRate,
      currency: model.currency,
      isActive: model.isActive,
      internalCode: model.internalCode ?? '',
    );
  }
}

class InvoiceItemPresetFormNotifier
    extends StateNotifier<InvoiceItemPresetFormState> {
  final Ref ref;

  InvoiceItemPresetFormNotifier(this.ref)
      : super(InvoiceItemPresetFormState());

  void reset() {
    state = InvoiceItemPresetFormState();
  }

  void loadFromModel(InvoiceItemPresetModel preset) {
    state = InvoiceItemPresetFormState.fromModel(preset);
  }

  void setScope(String value) =>
      state = state.copyWith(scope: value, errorMessage: null);
  void setName(String value) =>
      state = state.copyWith(name: value, errorMessage: null);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setUnit(String value) => state = state.copyWith(unit: value);
  void setDefaultQuantity(String value) =>
      state = state.copyWith(defaultQuantity: value);
  void setUnitNetPrice(String value) =>
      state = state.copyWith(unitNetPrice: value);
  void setVatRate(String value) => state = state.copyWith(vatRate: value);
  void setCurrency(String value) =>
      state = state.copyWith(currency: value);
  void setIsActive(bool value) =>
      state = state.copyWith(isActive: value);
  void setInternalCode(String value) =>
      state = state.copyWith(internalCode: value);

  Future<void> save() async {
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
          URLsInvoice.invoiceItemPresets,
          data: payload,
          hasToken: true,
          ref: ref,
        );
      } else {
        final url = '${URLsInvoice.invoiceItemPresets}${state.id}/';
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
        // Refresh list after save.
        ref.invalidate(invoiceItemPresetListProvider);
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save preset: ${resp.statusCode}',
        );
      }
    } catch (e, st) {
      debugPrint('Error saving invoice item preset: $e\n$st');
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final invoiceItemPresetFormProvider = StateNotifierProvider<
    InvoiceItemPresetFormNotifier, InvoiceItemPresetFormState>(
  (ref) => InvoiceItemPresetFormNotifier(ref),
);
