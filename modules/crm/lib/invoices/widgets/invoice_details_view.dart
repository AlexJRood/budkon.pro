import 'dart:async';

import 'package:core/ui/device_type_util.dart';
import 'package:crm/invoices/components/runtime_invoice_preview.dart';
import 'package:crm/invoices/models/templates.dart';
import 'package:crm/invoices/providers/template_active.dart';
import 'package:crm/invoices/utils/pdf_downloader_stub.dart'
    if (dart.library.html) 'package:crm/invoices/utils/pdf_downloader_web.dart';
import 'package:crm/invoices/widgets/invoice_pdf.dart';
import 'package:crm/shared/models/expense/crm_expenses_download_model.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/compensation/commission_integration/models/commission_integration_models.dart';
import 'package:crm/compensation/commission_integration/widgets/commission_integration_controller_widget.dart';
import 'package:crm/data/finance/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

typedef InvoiceChangedCallback = FutureOr<void> Function();

/// Backs the commission panel's "assign to transaction" search: filters the
/// agent's loaded transactions (from [transactionProvider]) by [query] and maps
/// them to [CommissionTransactionOption]s the assign dialog can display.
Future<List<CommissionTransactionOption>> _searchCommissionTransactions(
  WidgetRef ref,
  String query,
) async {
  final txs = ref.read(transactionProvider).asData?.value.transactions ??
      const <AgentTransactionModel>[];

  final q = query.trim().toLowerCase();
  final matched = q.isEmpty
      ? txs
      : txs.where((t) {
          final haystack =
              '${t.name} ${t.transactionName ?? ''} ${t.client.name} '
                      '${t.client.lastName ?? ''}'
                  .toLowerCase();
          return haystack.contains(q);
        }).toList();

  return matched.take(30).map((t) {
    final title =
        (t.transactionName?.trim().isNotEmpty ?? false) ? t.transactionName! : t.name;
    final subtitle =
        '${t.client.name} ${t.client.lastName ?? ''}'.trim();
    return CommissionTransactionOption(
      id: t.id,
      title: title,
      subtitle: subtitle,
      amount: double.tryParse(t.amount) ?? 0,
      currency: t.currency,
      isClosed: t.dateClosed != null,
    );
  }).toList();
}

class ExpensesViewDetailsWidget extends ConsumerWidget {
  final AgentRevenueModel? revenue;
  final CrmExpensesDownloadModel? expense;
  final TransactionExpensesModel? transaction;
  final bool isMobile;
  final ScrollController? scrollController;

  final InvoiceRelationAction? onOpenClient;
  final InvoiceRelationAction? onAttachClient;
  final InvoiceRelationAction? onOpenContractor;
  final InvoiceRelationAction? onAttachContractor;
  final InvoiceRelationAction? onOpenTransaction;
  final InvoiceRelationAction? onAttachTransaction;

  final InvoiceRelationAction? onSendReminder;
  final InvoiceRelationAction? onMarkAsPaid;
  final InvoiceRelationAction? onMarkAsUnpaid;

  final InvoiceChangedCallback? onChanged;

  const ExpensesViewDetailsWidget({
    super.key,
    this.revenue,
    this.expense,
    this.transaction,
    this.isMobile = false,
    this.scrollController,
    this.onOpenClient,
    this.onAttachClient,
    this.onOpenContractor,
    this.onAttachContractor,
    this.onOpenTransaction,
    this.onAttachTransaction,
    this.onSendReminder,
    this.onMarkAsPaid,
    this.onMarkAsUnpaid,
    this.onChanged,
  });

  Object? get _sourceData => revenue ?? expense ?? transaction;

  bool get _isRevenue => revenue != null;
  bool get _isExpense => expense != null;

  String? get _entitySegment {
    if (_isRevenue) return 'revenues';
    if (_isExpense) return 'expenses';
    return null;
  }

  int? get _entityId {
    if (revenue != null) return revenue!.id;
    if (expense != null) return expense!.id;
    return null;
  }

  Future<void> _runChangedCallback() async {
    final result = onChanged?.call();
    if (result is Future) {
      await result;
    }
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFB3261E) : const Color(0xFF1F8B4C),
      ),
    );
  }

  String _extractErrorMessage(dynamic responseData) {
    if (responseData is Map) {
      final detail = responseData['detail'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      final error = responseData['error'];
      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString();
      }

      for (final entry in responseData.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return 'something_went_wrong'.tr;
  }

  Future<int?> _showIntInputDialog(
    BuildContext context, {
    required String title,
    required String label,
    String? initialValue,
  }) async {
    if (!context.mounted) return null;

    final controller = TextEditingController(text: initialValue ?? '');

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            onSubmitted: (_) {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.of(dialogContext).pop(parsed);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(parsed);
              },
              child: Text('Save'.tr),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _postFinanceAction(
    BuildContext context,
    WidgetRef ref, {
    required RevenueInvoicePreviewVm vm,
    required String action,
    Map<String, dynamic>? data,
    required String successMessage,
  }) async {
    final segment = _entitySegment;
    final entityId = vm.id ?? _entityId;

    if (segment == null || entityId == null) {
      if (!context.mounted) return;
      _showSnack(context, 'cannot_perform_action'.tr, isError: true);
      return;
    }

    final response = await ApiServices.post(
      'https://www.superbee.cloud/finance/$segment/$entityId/$action/',
      hasToken: true,
      ref: ref,
      data: data ?? <String, dynamic>{},
    );

    if (!context.mounted) return;

    if (response == null) {
      _showSnack(context, 'network_error_try_again'.tr, isError: true);
      return;
    }

    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      _showSnack(context, successMessage);
      await _runChangedCallback();
      return;
    }

    _showSnack(context, _extractErrorMessage(response.data), isError: true);
  }

  Future<void> _patchFinanceEntity(
    BuildContext context,
    WidgetRef ref, {
    required RevenueInvoicePreviewVm vm,
    required Map<String, dynamic> data,
    required String successMessage,
  }) async {
    final segment = _entitySegment;
    final entityId = vm.id ?? _entityId;

    if (segment == null || entityId == null) {
      if (!context.mounted) return;
      _showSnack(context, 'cannot_perform_action'.tr, isError: true);
      return;
    }

    final response = await ApiServices.patch(
      'https://www.superbee.cloud/finance/$segment/$entityId/',
      hasToken: true,
      ref: ref,
      data: data,
    );

    if (!context.mounted) return;

    if (response == null) {
      _showSnack(context, 'network_error_try_again'.tr, isError: true);
      return;
    }

    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      _showSnack(context, successMessage);
      await _runChangedCallback();
      return;
    }

    _showSnack(context, _extractErrorMessage(response.data), isError: true);
  }

  Future<bool> _confirmMarkAsUnpaid(BuildContext context) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('set_as_unpaid_question'.tr),
          content: Text('confirm_mark_as_unpaid'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('yes_set_as_unpaid'.tr),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _handleSendReminder(
    BuildContext context,
    WidgetRef ref,
    RevenueInvoicePreviewVm vm,
  ) async {
    await _postFinanceAction(
      context,
      ref,
      vm: vm,
      action: 'send-reminder',
      successMessage: 'reminder_sent_success'.tr,
    );
  }

  Future<void> _handleMarkAsPaid(
    BuildContext context,
    WidgetRef ref,
    RevenueInvoicePreviewVm vm,
  ) async {
    if (!vm.isPaid) {
      final today = DateTime.now();
      final paymentDate =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      await _patchFinanceEntity(
        context,
        ref,
        vm: vm,
        data: {'is_paid': true, 'payment_date': paymentDate},
        successMessage: 'invoice_marked_paid'.tr,
      );
      return;
    }

    if (!context.mounted) return;
    _showSnack(context, 'invoice_already_paid'.tr);
  }

  Future<void> _handleMarkAsUnpaid(
    BuildContext context,
    WidgetRef ref,
    RevenueInvoicePreviewVm vm,
  ) async {
    if (!vm.isPaid) {
      if (!context.mounted) return;
      _showSnack(context, 'invoice_already_unpaid'.tr);
      return;
    }

    final confirmed = await _confirmMarkAsUnpaid(context);
    if (!context.mounted) return;
    if (!confirmed) return;

    await _patchFinanceEntity(
      context,
      ref,
      vm: vm,
      data: {'is_paid': false, 'payment_date': null},
      successMessage: 'invoice_marked_unpaid'.tr,
    );
  }

  Future<void> _handleAttachClient(
    BuildContext context,
    WidgetRef ref,
    RevenueInvoicePreviewVm vm,
  ) async {
    final clientId = await _showIntInputDialog(
      context,
      title: vm.hasClientReference ? 'change_client'.tr : 'attach_client'.tr,
      label: 'client_id'.tr,
      initialValue:
          vm.relatedClientId != null ? vm.relatedClientId.toString() : '',
    );

    if (!context.mounted) return;
    if (clientId == null) return;

    await _postFinanceAction(
      context,
      ref,
      vm: vm,
      action: 'assign-client',
      data: {'client_id': clientId},
      successMessage:
          vm.hasClientReference
              ? 'client_updated_success'.tr
              : 'client_attached_success'.tr,
    );
  }

  Future<void> _handleAttachTransaction(
    BuildContext context,
    WidgetRef ref,
    RevenueInvoicePreviewVm vm,
  ) async {
    final transactionId = await _showIntInputDialog(
      context,
      title:
          vm.hasTransactionReference
              ? 'change_transaction'.tr
              : 'attach_transaction'.tr,
      label: 'transaction_id'.tr,
      initialValue:
          vm.relatedTransactionId != null
              ? vm.relatedTransactionId.toString()
              : '',
    );

    if (!context.mounted) return;
    if (transactionId == null) return;

    await _postFinanceAction(
      context,
      ref,
      vm: vm,
      action: 'assign-transaction',
      data: {'transaction_id': transactionId},
      successMessage:
          vm.hasTransactionReference
              ? 'transaction_updated_success'.tr
              : 'transaction_attached_success'.tr,
    );
  }

  Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k.toString(), _deepNormalize(v)));
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _deepNormalize(v)));
    }
    return <String, dynamic>{};
  }

  dynamic _deepNormalize(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _deepNormalize(v)));
    }
    if (value is List) {
      return value.map(_deepNormalize).toList();
    }
    return value;
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .map((e) => _asStringKeyMap(e))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final normalized = value.toString().replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  String _formatMoney(dynamic value) {
    final v = _asDouble(value);
    return v.toStringAsFixed(2);
  }

  String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final v in values) {
      final s = _asString(v).trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  Map<String, dynamic> _extractSourceJson(Object data) {
    try {
      final dynamic raw = (data as dynamic).toJson();
      return _asStringKeyMap(raw);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> _normalizeInvoiceJson(Map<String, dynamic> input) {
    final j = Map<String, dynamic>.from(input);

    if (j['invoice_item'] == null && j['invoiceItem'] != null) {
      j['invoice_item'] = j['invoiceItem'];
    }

    if (j['invoice_item'] == null && j['invoiceItems'] is List) {
      j['invoice_item'] = {'items': j['invoiceItems']};
    }

    final inv = j['invoice_item'];

    if (inv is List) {
      j['invoice_item'] = {'items': inv};
      return j;
    }

    if (inv is Map) {
      final root = _asStringKeyMap(inv);

      if (root['items'] == null && root['invoiceItems'] is List) {
        root['items'] = root['invoiceItems'];
      }
      if (root['items'] == null && root['invoice_items'] is List) {
        root['items'] = root['invoice_items'];
      }
      if (root['items'] == null && root['rows'] is List) {
        root['items'] = root['rows'];
      }
      if (root['items'] == null && root['positions'] is List) {
        root['items'] = root['positions'];
      }

      j['invoice_item'] = root;
      return j;
    }

    return j;
  }

  List<Map<String, dynamic>> _normalizeLegacyItems(
    Map<String, dynamic> json,
    String currency,
  ) {
    final invoiceItem = _asStringKeyMap(json['invoice_item']);
    if (invoiceItem.isEmpty) return const [];

    List<dynamic> rawItems = [];

    if (invoiceItem['items'] is List) {
      rawItems = invoiceItem['items'] as List<dynamic>;
    } else {
      rawItems = invoiceItem.values.toList();
    }

    final normalized = <Map<String, dynamic>>[];

    for (int i = 0; i < rawItems.length; i++) {
      final item = _asStringKeyMap(rawItems[i]);
      if (item.isEmpty) continue;

      final quantity = _asDouble(item['quantity']);
      final unitNetPrice = _asDouble(
        item['unit_net_price'] ?? item['unit_price'],
      );
      final vatRate = _asDouble(item['vat_rate']);
      final lineNetAmount =
          item.containsKey('line_net_amount')
              ? _asDouble(item['line_net_amount'])
              : quantity * unitNetPrice;
      final lineVatAmount =
          item.containsKey('line_vat_amount')
              ? _asDouble(item['line_vat_amount'])
              : _asDouble(
                item['vat_amount'] ?? (lineNetAmount * vatRate / 100),
              );
      final lineGrossAmount =
          item.containsKey('line_gross_amount')
              ? _asDouble(item['line_gross_amount'])
              : _asDouble(
                item['gross_value'] ?? (lineNetAmount + lineVatAmount),
              );

      final name = _firstNonEmpty([
        item['name'],
        item['product_name'],
        item['productName'],
      ]);

      final unit = _firstNonEmpty([item['unit'], item['iu']], fallback: 'szt');

      final itemCurrency = _firstNonEmpty([
        item['currency'],
        currency,
      ], fallback: 'PLN');

      normalized.add({
        'name': name,
        'product_name': name,
        'quantity': quantity == 0 ? 1.0 : quantity,
        'unit': unit,
        'iu': unit,
        'vat_rate': vatRate,
        'unit_net_price': unitNetPrice,
        'line_net_amount': lineNetAmount,
        'line_vat_amount': lineVatAmount,
        'line_gross_amount': lineGrossAmount,
        'currency': itemCurrency,
        'description': _asString(item['description']),
        'advance': item['advance'] == true,
        'gtu': _firstNonEmpty([item['gtu']], fallback: 'OTHER'),
        'unit_price': unitNetPrice,
        'vat_amount': lineVatAmount,
        'gross_value': lineGrossAmount,
        'net_value': lineNetAmount,
        'order_index': _asInt(item['order_index']) ?? i,
      });
    }

    return normalized;
  }

  List<Map<String, dynamic>> _ensureDisplayItems(
    Map<String, dynamic> json,
    String currency,
  ) {
    final backendItems = _asMapList(json['invoice_items_display']);
    if (backendItems.isNotEmpty) {
      return backendItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        final quantity = _asDouble(item['quantity']);
        final unitNetPrice = _asDouble(item['unit_net_price']);
        final vatRate = _asDouble(item['vat_rate']);
        final lineNetAmount =
            item.containsKey('line_net_amount')
                ? _asDouble(item['line_net_amount'])
                : quantity * unitNetPrice;
        final lineVatAmount =
            item.containsKey('line_vat_amount')
                ? _asDouble(item['line_vat_amount'])
                : _asDouble(
                  item['vat_amount'] ?? (lineNetAmount * vatRate / 100),
                );
        final lineGrossAmount =
            item.containsKey('line_gross_amount')
                ? _asDouble(item['line_gross_amount'])
                : _asDouble(
                  item['gross_value'] ?? (lineNetAmount + lineVatAmount),
                );

        final name = _firstNonEmpty([
          item['name'],
          item['product_name'],
          item['productName'],
        ]);

        final unit = _firstNonEmpty([
          item['unit'],
          item['iu'],
        ], fallback: 'szt');

        return {
          'name': name,
          'product_name': name,
          'quantity': quantity == 0 ? 1.0 : quantity,
          'unit': unit,
          'iu': unit,
          'vat_rate': vatRate,
          'unit_net_price': unitNetPrice,
          'line_net_amount': lineNetAmount,
          'line_vat_amount': lineVatAmount,
          'line_gross_amount': lineGrossAmount,
          'currency': _firstNonEmpty([
            item['currency'],
            currency,
          ], fallback: 'PLN'),
          'description': _asString(item['description']),
          'advance': item['advance'] == true,
          'gtu': _firstNonEmpty([item['gtu']], fallback: 'OTHER'),
          'unit_price': unitNetPrice,
          'vat_amount': lineVatAmount,
          'gross_value': lineGrossAmount,
          'net_value': lineNetAmount,
          'order_index': _asInt(item['order_index']) ?? index,
        };
      }).toList();
    }

    final legacyItems = _normalizeLegacyItems(json, currency);
    if (legacyItems.isNotEmpty) {
      return legacyItems;
    }

    final totalGross = _asDouble(json['total_amount'] ?? json['amount']);
    final taxAmount = _asDouble(json['tax_amount']);
    final totalNet = totalGross - taxAmount;

    final fallbackName = _firstNonEmpty([
      json['name'],
      json['title'],
      json['project_name'],
      json['transaction_type'],
    ], fallback: 'Service');

    return [
      {
        'name': fallbackName,
        'product_name': fallbackName,
        'quantity': 1.0,
        'unit': 'szt',
        'iu': 'szt',
        'vat_rate':
            totalGross > 0 && taxAmount > 0 && totalNet > 0
                ? ((taxAmount / totalNet) * 100)
                : 0.0,
        'unit_net_price': totalNet > 0 ? totalNet : totalGross,
        'line_net_amount': totalNet > 0 ? totalNet : totalGross,
        'line_vat_amount': taxAmount,
        'line_gross_amount': totalGross,
        'currency': currency,
        'description': '',
        'advance': false,
        'gtu': 'OTHER',
        'unit_price': totalNet > 0 ? totalNet : totalGross,
        'vat_amount': taxAmount,
        'gross_value': totalGross,
        'net_value': totalNet > 0 ? totalNet : totalGross,
        'order_index': 0,
      },
    ];
  }

  Map<String, dynamic>? _normalizeParty(dynamic value) {
    final map = _asStringKeyMap(value);
    if (map.isEmpty) return null;

    final normalized = <String, dynamic>{
      'id': _asInt(map['id']),
      'name': _firstNonEmpty([
        map['name'],
        map['company_name'],
        '${_asString(map['first_name']).trim()} ${_asString(map['last_name']).trim()}'
            .trim(),
      ]),
      'company_name': _asString(map['company_name']),
      'first_name': _asString(map['first_name']),
      'last_name': _asString(map['last_name']),
      'email': _asString(map['email']),
      'phone': _asString(map['phone']),
      'street': _asString(map['street']),
      'house_number': _asString(map['house_number']),
      'apartment_number': _asString(map['apartment_number']),
      'postal_code': _asString(map['postal_code']),
      'city': _asString(map['city']),
      'country': _asString(map['country']),
      'tax_number': _firstNonEmpty([map['tax_number'], map['nip']]),
      'bank_name': _asString(map['bank_name']),
      'bank_account': _asString(map['bank_account']),
      'iban': _asString(map['iban']),
      'swift': _asString(map['swift']),
      'logo_url': _asString(map['logo_url']),
    };

    final hasAnyData = normalized.values.any((e) {
      if (e == null) return false;
      if (e is String) return e.trim().isNotEmpty;
      return true;
    });

    return hasAnyData ? normalized : null;
  }

  Map<String, dynamic> _buildPreviewJson(Object data) {
    final raw = _extractSourceJson(data);
    final normalized = _normalizeInvoiceJson(raw);

    final currency = _firstNonEmpty([normalized['currency']], fallback: 'PLN');

    final items = _ensureDisplayItems(normalized, currency);

    double totalGross = _asDouble(
      normalized['total_amount'] ?? normalized['amount'],
    );
    double totalTax = _asDouble(normalized['tax_amount']);

    if (totalGross <= 0 && items.isNotEmpty) {
      totalGross = items.fold<double>(
        0.0,
        (sum, item) => sum + _asDouble(item['line_gross_amount']),
      );
    }

    if (totalTax <= 0 && items.isNotEmpty) {
      totalTax = items.fold<double>(
        0.0,
        (sum, item) => sum + _asDouble(item['line_vat_amount']),
      );
    }

    final buyerData =
        _normalizeParty(normalized['buyer_data']) ??
        _normalizeParty(normalized['client_data']) ??
        (normalized['clients'] is Map
            ? _normalizeParty(normalized['clients'])
            : null);

    final clientData = _normalizeParty(normalized['client_data']) ?? buyerData;
    final sellerData =
        _normalizeParty(normalized['seller_data']) ??
        (normalized['my_invoice_data'] is Map
            ? _normalizeParty(normalized['my_invoice_data'])
            : null);

    return <String, dynamic>{
      ...normalized,
      'id': normalized['id'],
      'name': _firstNonEmpty([normalized['name'], normalized['title']]),
      'transaction_type': _asString(normalized['transaction_type']),
      'total_amount': _formatMoney(totalGross),
      'currency': currency,
      'tax_amount': _formatMoney(totalTax),
      'date': _asString(normalized['date']),
      'payment_date': _asString(normalized['payment_date']),
      'is_paid': normalized['is_paid'] == true,
      'payment_methods': _asString(normalized['payment_methods']),
      'invoice_number': _asString(normalized['invoice_number']),
      'note': _asString(normalized['note']),
      'clients': normalized['clients'],
      'client_invoice': normalized['client_invoice'],
      'my_invoice_data': normalized['my_invoice_data'],
      'invoice_template': normalized['invoice_template'],
      'buyer_data': buyerData,
      'client_data': clientData,
      'seller_data': sellerData,
      'invoice_template_data': normalized['invoice_template_data'],
      'invoice_items_display': items,
      'date_create': normalized['date_create'],
      'date_update': normalized['date_update'],
      'transaction_id': normalized['transaction_id'],
      'object_id': normalized['object_id'],
      'transaction_name': normalized['transaction_name'],
      'client_id': normalized['client_id'],
      'contractor_id': normalized['contractor_id'],
    };
  }

  String _resolveTitle(Map<String, dynamic> json) {
    final explicit = _firstNonEmpty([json['name'], json['title']]);
    if (explicit.isNotEmpty) return explicit;

    final items = _asMapList(json['invoice_items_display']);
    if (items.isNotEmpty) {
      final firstItemName = _firstNonEmpty([
        items.first['name'],
        items.first['product_name'],
      ]);
      if (firstItemName.isNotEmpty) return firstItemName;
    }

    return 'Invoice';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final activeTemplateAsync = ref.watch(invoiceActiveTemplateProvider);
    final InvoiceTemplateModel? activeTemplate = activeTemplateAsync.maybeWhen(
      data: (tpl) => tpl,
      orElse: () => null,
    );

    final sourceData = _sourceData;
    if (sourceData == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.dashboardContainer,
        ),
        child: Center(
          child: Text(
            'no_invoice_data'.tr,
            style: AppTextStyles.interMedium.copyWith(color: theme.textColor),
          ),
        ),
      );
    }

    final selectedInvoiceJson = _buildPreviewJson(sourceData);
    final title = _resolveTitle(selectedInvoiceJson);
    final previewVm = RevenueInvoicePreviewVm.fromJson(selectedInvoiceJson);

    final InvoiceRelationAction effectiveSendReminder =
        onSendReminder ??
        (vm) async {
          await _handleSendReminder(context, ref, vm);
        };

    final InvoiceRelationAction effectiveMarkAsPaid =
        onMarkAsPaid ??
        (vm) async {
          await _handleMarkAsPaid(context, ref, vm);
        };

    final InvoiceRelationAction effectiveMarkAsUnpaid =
        onMarkAsUnpaid ??
        (vm) async {
          await _handleMarkAsUnpaid(context, ref, vm);
        };

    final InvoiceRelationAction effectiveAttachClient =
        onAttachClient ??
        (vm) async {
          await _handleAttachClient(context, ref, vm);
        };

    final InvoiceRelationAction effectiveAttachTransaction =
        onAttachTransaction ??
        (vm) async {
          await _handleAttachTransaction(context, ref, vm);
        };

    // Commission integration for this invoice (revenue): shows the commission
    // summary and lets the agent link the invoice to a deal transaction. Only
    // for revenue entities (expenses/other sources have no commission).
    final Widget? commissionPanel = revenue != null
        ? InvoiceCommissionIntegrationPanel.fromInvoiceJson(
            invoiceJson: <String, dynamic>{
              'id': revenue!.id,
              ...?revenue!.invoiceData,
            },
            isMobile: isMobile,
            searchTransactions: (query) =>
                _searchCommissionTransactions(ref, query),
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.dashboardContainer,
      ),
      child: Column(
        children: [
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: theme.themeColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interBold.copyWith(
                      fontSize: 15.sp,
                      color: theme.themeTextColor,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: AppIcons.close(
                    height: 24.h,
                    width: 24.w,
                    color: theme.themeTextColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          if (!isMobile)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: _InvoiceActionBar(
                theme: theme,
                vm: previewVm,
                sourceData: sourceData,
                isMobile: isMobile,
                template: activeTemplate,
                onOpenClient: onOpenClient,
                onAttachClient: effectiveAttachClient,
                onSendReminder: effectiveSendReminder,
                onMarkAsPaid: effectiveMarkAsPaid,
                onMarkAsUnpaid: effectiveMarkAsUnpaid,
              ),
            ),
          if (!isMobile) SizedBox(height: 14.h),
          Expanded(
            child:
                isMobile
                    ? SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        10,
                        0,
                        10,
                        BottomBarSize.resolve(context) + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InvoiceActionBar(
                            theme: theme,
                            vm: previewVm,
                            sourceData: sourceData,
                            isMobile: isMobile,
                            template: activeTemplate,
                            onOpenClient: onOpenClient,
                            onAttachClient: effectiveAttachClient,
                            onSendReminder: effectiveSendReminder,
                            onMarkAsPaid: effectiveMarkAsPaid,
                            onMarkAsUnpaid: effectiveMarkAsUnpaid,
                          ),
                          SizedBox(height: 14.h),
                          _PreviewInfoBanner(
                            theme: theme,
                            title: 'interactive_preview'.tr,
                            subtitle: 'interactive_preview_subtitle'.tr,
                          ),
                          SizedBox(height: 10.h),
                          RuntimeInvoicePreview(
                            revenueJson: selectedInvoiceJson,
                            appTheme: theme,
                            layoutMode:
                                RuntimeInvoicePreviewLayoutMode.stackedEmbedded,
                            padding: EdgeInsets.zero,
                            onOpenClient: onOpenClient,
                            onAttachClient: effectiveAttachClient,
                            onOpenContractor: onOpenContractor,
                            onAttachContractor: onAttachContractor,
                            onOpenTransaction: onOpenTransaction,
                            onAttachTransaction: effectiveAttachTransaction,
                          ),
                          if (commissionPanel != null) ...[
                            SizedBox(height: 14.h),
                            commissionPanel,
                          ],
                        ],
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          if (commissionPanel != null) ...[
                            commissionPanel,
                            SizedBox(height: 14.h),
                          ],
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _PreviewSectionHeader(
                                  theme: theme,
                                  icon: Icons.tune_outlined,
                                  title: 'left_panel_interactive_preview'.tr,
                                  subtitle: 'left_panel_subtitle'.tr,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Container(
                                width: 1,
                                height: 56,
                                color: theme.textColor.withAlpha(80),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                flex: 2,
                                child: _PreviewSectionHeader(
                                  theme: theme,
                                  icon: Icons.description_outlined,
                                  title: 'right_panel_document_preview'.tr,
                                  subtitle: 'right_panel_subtitle'.tr,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: EdgeInsets.only(
                                bottom: BottomBarSize.resolve(context),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: RuntimeInvoicePreview(
                                      revenueJson: selectedInvoiceJson,
                                      appTheme: theme,
                                      layoutMode:
                                          RuntimeInvoicePreviewLayoutMode
                                              .summaryOnly,
                                      padding: EdgeInsets.zero,
                                      onOpenClient: onOpenClient,
                                      onAttachClient: effectiveAttachClient,
                                      onOpenContractor: onOpenContractor,
                                      onAttachContractor: onAttachContractor,
                                      onOpenTransaction: onOpenTransaction,
                                      onAttachTransaction:
                                          effectiveAttachTransaction,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Container(
                                    width: 1,
                                    color: theme.textColor.withAlpha(120),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    flex: 2,
                                    child: RuntimeInvoicePreview(
                                      revenueJson: selectedInvoiceJson,
                                      appTheme: theme,
                                      layoutMode:
                                          RuntimeInvoicePreviewLayoutMode
                                              .paperOnly,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceActionBar extends StatelessWidget {
  final ThemeColors theme;
  final RevenueInvoicePreviewVm vm;
  final Object sourceData;
  final bool isMobile;
  final InvoiceTemplateModel? template;

  final InvoiceRelationAction? onOpenClient;
  final InvoiceRelationAction? onAttachClient;
  final InvoiceRelationAction? onSendReminder;
  final InvoiceRelationAction? onMarkAsPaid;
  final InvoiceRelationAction? onMarkAsUnpaid;

  const _InvoiceActionBar({
    required this.theme,
    required this.vm,
    required this.sourceData,
    required this.isMobile,
    required this.template,
    required this.onOpenClient,
    required this.onAttachClient,
    required this.onSendReminder,
    required this.onMarkAsPaid,
    required this.onMarkAsUnpaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(160)),
      ),
      padding: const EdgeInsets.all(12),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionsRow(),
                  SizedBox(height: 12.h),
                  _InlineClientCard(
                    theme: theme,
                    vm: vm,
                    onOpenClient: onOpenClient,
                    onAttachClient: onAttachClient,
                  ),
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        downloadButton(
                          theme: theme,
                          data: sourceData,
                          isMobile: isMobile,
                          template: template,
                        ),
                        _ActionBarButton(
                          theme: theme,
                          icon: Icons.notifications_active_outlined,
                          label: 'send_reminder'.tr,
                          onPressed:
                              onSendReminder != null
                                  ? () async => onSendReminder!(vm)
                                  : null,
                        ),
                        _ActionBarButton(
                          theme: theme,
                          icon:
                              vm.isPaid
                                  ? Icons.undo_rounded
                                  : Icons.paid_outlined,
                          label:
                              vm.isPaid
                                  ? 'set_as_unpaid_button'.tr
                                  : 'mark_as_paid_button'.tr,
                          onPressed:
                              vm.isPaid
                                  ? (onMarkAsUnpaid != null
                                      ? () async => onMarkAsUnpaid!(vm)
                                      : null)
                                  : (onMarkAsPaid != null
                                      ? () async => onMarkAsPaid!(vm)
                                      : null),
                          highlighted: !vm.isPaid,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: _InlineClientCard(
                      theme: theme,
                      vm: vm,
                      onOpenClient: onOpenClient,
                      onAttachClient: onAttachClient,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildActionsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        downloadButton(
          theme: theme,
          data: sourceData,
          isMobile: isMobile,
          template: template,
        ),
        _ActionBarButton(
          theme: theme,
          icon: Icons.notifications_active_outlined,
          label: 'send_reminder'.tr,
          onPressed:
              onSendReminder != null ? () async => onSendReminder!(vm) : null,
        ),
        _ActionBarButton(
          theme: theme,
          icon: vm.isPaid ? Icons.undo_rounded : Icons.paid_outlined,
          label:
              vm.isPaid ? 'set_as_unpaid_button'.tr : 'mark_as_paid_button'.tr,
          onPressed:
              vm.isPaid
                  ? (onMarkAsUnpaid != null
                      ? () async => onMarkAsUnpaid!(vm)
                      : null)
                  : (onMarkAsPaid != null
                      ? () async => onMarkAsPaid!(vm)
                      : null),
          highlighted: !vm.isPaid,
        ),
      ],
    );
  }
}

class _ActionBarButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool highlighted;

  const _ActionBarButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor:
            highlighted ? theme.themeColor.withAlpha(40) : theme.textFieldColor,
        foregroundColor: theme.textColor,
        disabledBackgroundColor: theme.textFieldColor.withAlpha(130),
        disabledForegroundColor: theme.textColor.withAlpha(120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color:
                highlighted
                    ? theme.themeColor.withAlpha(180)
                    : theme.dashboardBoarder.withAlpha(160),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: AppTextStyles.interMedium.copyWith(
          fontSize: 12.sp,
          color:
              onPressed == null
                  ? theme.textColor.withAlpha(120)
                  : theme.textColor,
        ),
      ),
    );
  }
}

class _InlineClientCard extends StatelessWidget {
  final ThemeColors theme;
  final RevenueInvoicePreviewVm vm;
  final InvoiceRelationAction? onOpenClient;
  final InvoiceRelationAction? onAttachClient;

  const _InlineClientCard({
    required this.theme,
    required this.vm,
    required this.onOpenClient,
    required this.onAttachClient,
  });

  @override
  Widget build(BuildContext context) {
    final canOpen = vm.hasClientReference && onOpenClient != null;
    final canAttach = onAttachClient != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(160),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(150)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_outline, color: theme.textColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap:
                  canOpen
                      ? () async {
                        await onOpenClient!(vm);
                      }
                      : canAttach
                      ? () async {
                        await onAttachClient!(vm);
                      }
                      : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'client_label'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      fontSize: 11.sp,
                      color: theme.textColor.withAlpha(170),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    vm.clientNameOrDash,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interBold.copyWith(
                      fontSize: 13.sp,
                      color: theme.textColor,
                    ),
                  ),
                  if ((vm.clientSecondaryLine ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      vm.clientSecondaryLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.interMedium.copyWith(
                        fontSize: 11.sp,
                        color: theme.textColor.withAlpha(150),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          if (canOpen)
            TextButton(
              onPressed: () async {
                await onOpenClient!(vm);
              },
              child: Text('open_button'.tr),
            ),
          if (canAttach)
            TextButton(
              onPressed: () async {
                await onAttachClient!(vm);
              },
              child: Text(
                vm.hasClientReference ? 'change_button'.tr : 'attach_button'.tr,
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewInfoBanner extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String subtitle;

  const _PreviewInfoBanner({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.interBold.copyWith(
                    fontSize: 12.sp,
                    color: theme.textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTextStyles.interMedium.copyWith(
                    fontSize: 11.sp,
                    color: theme.textColor.withAlpha(165),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSectionHeader extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String title;
  final String subtitle;

  const _PreviewSectionHeader({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(130),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(140)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.interBold.copyWith(
                    fontSize: 12.sp,
                    color: theme.textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interMedium.copyWith(
                    fontSize: 11.sp,
                    color: theme.textColor.withAlpha(165),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- DOWNLOAD BUTTON ----------------

Widget downloadButton({
  required ThemeColors theme,
  required Object data,
  required bool isMobile,
  InvoiceTemplateModel? template,
}) {
  String resolveInvoiceNo(Object d) {
    if (d is AgentRevenueModel) return d.invoiceNumber ?? '';
    if (d is CrmExpensesDownloadModel) return d.invoiceNumber ?? '';
    if (d is TransactionExpensesModel) return d.invoiceNumber ?? '';
    return '';
  }

  String sanitizeFilename(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>| ]+'), '_');
  }

  return ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: theme.textFieldColor,
      foregroundColor: theme.textColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.dashboardBoarder.withAlpha(160)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    onPressed: () async {
      try {
        final pdfBytes = await InvoicePdf.build(
          theme: theme,
          data: data,
          isMobile: isMobile,
          template: template,
        );

        final invoiceNo = resolveInvoiceNo(data);
        final rawName =
            invoiceNo.isEmpty
                ? 'INV_${DateTime.now().millisecondsSinceEpoch}'
                : 'INV_$invoiceNo';
        final filename = '${sanitizeFilename(rawName)}.pdf';

        await savePdfBytes(pdfBytes, filename);
      } catch (_) {}
    },
    icon: Icon(Icons.download_outlined, size: 18, color: theme.textColor),
    label: Text(
      'download_pdf'.tr,
      style: AppTextStyles.interMedium.copyWith(
        color: theme.textColor,
        fontSize: 12.sp,
      ),
    ),
  );
}
