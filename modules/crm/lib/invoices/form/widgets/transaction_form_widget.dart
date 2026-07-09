// ===============================
// lib/crm_agent/add_invoice_form/widgets/transaction_form_widget.dart
//
// FIXED (production-safe):
// ✅ Root cause: prefill runs twice; second run has base=null -> overwrites correct computed values.
// ✅ Fix: compute FIRST, use per-tx cache, and NEVER overwrite UI when computed is null.
// ✅ Also: avoid clearing table unless we have a valid computed.
// Comments in English.
// ===============================

import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/data/clients/client_selection_provider.dart';
import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_flow_provider.dart';
import 'package:crm/invoices/form/provider/invoice_table_provider.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class TransactionFormWidget extends ConsumerStatefulWidget {
  final bool isExpenses;
  final bool isMobile;

  const TransactionFormWidget({
    super.key,
    required this.isExpenses,
    required this.isMobile,
  });

  @override
  ConsumerState<TransactionFormWidget> createState() => _TransactionFormWidgetState();
}

class _TransactionFormWidgetState extends ConsumerState<TransactionFormWidget> {
  String? _lastPrefillSignature;
  bool _prefillInProgress = false;

  late final ProviderSubscription<AgentTransactionModel?> _txSub;

  // ✅ Cache last good computed commission per tx id.
  final Map<int, _ComputedCommission> _computedCache = {};

  @override
  void initState() {
    super.initState();

    _txSub = ref.listenManual<AgentTransactionModel?>(
      selectedTransactionProvider,
      (prev, next) {
        if (!mounted) return;

        if (next == null) {
          _lastPrefillSignature = null;
          return;
        }

        final sig = _prefillSignature(next);
        if (_lastPrefillSignature == sig) return;
        _lastPrefillSignature = sig;

        // Do NOT prefill during build; schedule post-frame.
        _schedulePrefill(next);
      },
    );
  }

  void _schedulePrefill(AgentTransactionModel tx) {
    if (_prefillInProgress) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_prefillInProgress) return;

      _prefillInProgress = true;
      try {
        _applyPrefill(tx);
      } finally {
        _prefillInProgress = false;
      }
    });
  }

  @override
  void dispose() {
    _txSub.close();
    super.dispose();
  }

  // -------------------------
  // Helpers (parsing)
  // -------------------------

  double? _tryDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final normalized = s.replaceAll(' ', '').replaceAll(',', '.');
    final cleaned = normalized.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(cleaned);
  }

  int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  String? _tryString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool? _tryBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }

  // Merge root + nested "transaction" map if exists
  Map<String, dynamic> _txMap(AgentTransactionModel tx) {
    try {
      final dynamic d = tx;
      final raw = d.toJson?.call();
      if (raw is Map) {
        final root = Map<String, dynamic>.from(raw as Map);

        final nested = root['transaction'];
        if (nested is Map) {
          final inner = Map<String, dynamic>.from(nested as Map);
          final merged = <String, dynamic>{...root, ...inner};

          // Prefer root overrides for important keys
          for (final k in const [
            'final_amount',
            'final_currency',
            'property_final_price',
            'isCommisssionPercentage',
            'isCommissionNetValue',
            'commission',
            'vatRate',
            'vat_rate',
          ]) {
            if (root[k] != null) merged[k] = root[k];
          }
          return merged;
        }
        return root;
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  double? _doubleFromKeys(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (!m.containsKey(k)) continue;
      final d = _tryDouble(m[k]);
      if (d != null) return d;
    }
    return null;
  }

  bool? _boolFromKeys(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (!m.containsKey(k)) continue;
      final b = _tryBool(m[k]);
      if (b != null) return b;
    }
    return null;
  }

  int? _tryClientId(AgentTransactionModel tx) {
    try {
      final dynamic client = (tx as dynamic).client;
      return _tryInt(client?.id);
    } catch (_) {
      return null;
    }
  }

  String _tryCurrency(AgentTransactionModel tx) {
    final m = _txMap(tx);
    final raw = m['final_currency'] ?? m['finalCurrency'] ?? m['currency'];
    return _tryString(raw) ?? 'PLN';
  }

  // VAT rate for invoice row (percent)
  double _vatRate(AgentTransactionModel tx) {
    final m = _txMap(tx);

    final raw = m['vatRate'] ?? m['vat_rate'] ?? m['vat'] ?? m['vat_percent'];
    final parsed = _tryDouble(raw);
    if (parsed != null && parsed >= 0 && parsed <= 99) return parsed;

    // Safe dynamic fallback
    try {
      final d = tx as dynamic;
      final dynRaw = d.vatRate ?? d.vat_rate ?? d.vat;
      final dynParsed = _tryDouble(dynRaw);
      if (dynParsed != null && dynParsed >= 0 && dynParsed <= 99) return dynParsed;
    } catch (_) {}

    return 23.0;
  }

  bool _isCommissionPercent(AgentTransactionModel tx) {
    final m = _txMap(tx);

    final flag = _boolFromKeys(m, const [
      'isCommisssionPercentage', // IMPORTANT typo in your model/json
      'isCommissionPercent',
      'is_commission_percent',
      'commission_is_percent',
      'commissionIsPercent',
      'isCommissionPercentage',
      'is_commission_percentage',
      'commission_is_percentage',
      'commissionIsPercentage',
    ]);

    if (flag != null) return flag;

    final unit = (m['commissionUnit'] ?? m['commission_unit'])?.toString().toLowerCase().trim();
    final type = (m['commissionType'] ?? m['commission_type'])?.toString().toLowerCase().trim();
    if (unit == '%' || unit == 'percent' || unit == 'percentage') return true;
    if (type == '%' || type == 'percent' || type == 'percentage') return true;

    return false;
  }

  double? _tryCommissionRatePercent(AgentTransactionModel tx) {
    if (!_isCommissionPercent(tx)) return null;
    final m = _txMap(tx);

    // In percent mode, "commission" means RATE (%)
    return _doubleFromKeys(m, const [
      'commissionRate',
      'commission_rate',
      'commissionPercent',
      'commission_percent',
      'commission_percentage',
      'commissionValuePercent',
      'commission_value_percent',
      'commission', // percent in percent-mode
    ]);
  }

  double? _tryCommissionFixedAmount(AgentTransactionModel tx) {
    final m = _txMap(tx);

    if (_isCommissionPercent(tx)) {
      // In percent mode, fixed should NOT read "commission"
      return _doubleFromKeys(m, const [
        'commissionAmount',
        'commission_amount',
        'commissionValue',
        'commission_value',
      ]);
    }

    // In fixed mode, "commission" means AMOUNT
    return _doubleFromKeys(m, const [
      'commissionAmount',
      'commission_amount',
      'commissionValue',
      'commission_value',
      'commission',
    ]);
  }

  // Base for percent commission (sale price)
  double? _tryBaseForPercent(AgentTransactionModel tx) {
    final m = _txMap(tx);

    final base = _doubleFromKeys(m, const [
      'property_final_price',
      'propertyFinalPrice',
      'final_amount',
      'finalAmount',
      'total_amount',
      'totalAmount',
      'amount', // last resort
    ]);

    if (base != null && base > 0) return base;
    return null;
  }

  dynamic _tryPaymentMethod(AgentTransactionModel tx) {
    final m = _txMap(tx);

    final fromMap = m['paymentMethodId'] ??
        m['payment_method_id'] ??
        m['paymentMethod'] ??
        m['payment_method'] ??
        m['payment_methods'];

    if (fromMap != null) return fromMap;

    try {
      final d = tx as dynamic;
      return d.paymentMethodId ??
          d.payment_method_id ??
          d.paymentMethod ??
          d.payment_method ??
          d.payment_methods;
    } catch (_) {
      return null;
    }
  }

  String _prefillSignature(AgentTransactionModel tx) {
    final m = _txMap(tx);
    String s(dynamic v) => v == null ? '' : v.toString();

    return <String>[
      s(m['id'] ?? tx.id),
      s(m['name'] ?? tx.name),
      s(m['transaction_type'] ?? m['transactionType'] ?? (tx as dynamic).transactionType),
      s(m['isCommisssionPercentage']),
      s(m['isCommissionNetValue']),
      s(m['commission']),
      s(m['commissionAmount']),
      s(m['commissionRate']),
      s(m['vatRate'] ?? m['vat_rate']),
      s(m['final_amount']),
      s(m['property_final_price']),
      s(m['final_currency']),
    ].join('|');
  }

  // -------------------------
  // Commission compute (FIXED + cache-friendly)
  // -------------------------

  _ComputedCommission? _computeCommission(AgentTransactionModel tx) {
    final isPercent = _isCommissionPercent(tx);

    // isNet: prefer map, fallback to model field
    final m = _txMap(tx);
    final isNetFromMap = _boolFromKeys(m, const [
      'isCommissionNetValue',
      'is_commission_net_value',
      'isCommissionNet',
      'is_commission_net',
    ]);
    final isNet = isNetFromMap ?? tx.isCommissionNetValue;

    final vat = _vatRate(tx);
    final divisor = 1.0 + vat / 100.0;

    if (isPercent) {
      final rate = _tryCommissionRatePercent(tx);
      final baseGross = _tryBaseForPercent(tx);

      if (rate == null || baseGross == null) return null;

      final baseNet = baseGross / divisor;

      // raw is in "nature" of isNet
      final raw = isNet
          ? (baseNet * (rate / 100.0)) // commission NET
          : (baseGross * (rate / 100.0)); // commission GROSS

      final net = isNet ? raw : (raw / divisor);
      final gross = isNet ? (raw * divisor) : raw;

      return _ComputedCommission(
        raw: raw,
        net: net,
        gross: gross,
        vat: vat,
        isNet: isNet,
        isPercent: true,
        rate: rate,
        baseGross: baseGross,
      );
    }

    // fixed amount
    final fixed = _tryCommissionFixedAmount(tx);
    if (fixed == null) return null;

    final net = isNet ? fixed : (fixed / divisor);
    final gross = isNet ? (fixed * divisor) : fixed;

    return _ComputedCommission(
      raw: fixed,
      net: net,
      gross: gross,
      vat: vat,
      isNet: isNet,
      isPercent: false,
      rate: null,
      baseGross: null,
    );
  }

  // -------------------------
  // APPLY PREFILL (MAIN FIX)
  // -------------------------

  void _applyPrefill(AgentTransactionModel tx) {
    final formNotifier = ref.read(revenueFormProvider.notifier);
    final tableNotifier = ref.read(invoiceTableProvider.notifier);

    // Basic links
    formNotifier.setObjectId(tx.id);

    final clientId = _tryClientId(tx);
    if (clientId != null) {
      formNotifier.setClient(clientId);
    }

    // Text/basic
    formNotifier.setCurrency(_tryCurrency(tx));
    formNotifier.setName('${'invoice_prefix'.tr} ${tx.name}');

    final m = _txMap(tx);
    final tType = _tryString(
          m['transaction_type'] ?? m['transactionType'] ?? (tx as dynamic).transactionType,
        ) ??
        '';
    if (tType.isNotEmpty) formNotifier.setTransactionType(tType);

    // Payment method best-effort (safe)
    final payment = _tryPaymentMethod(tx);
    if (payment != null) {
      try {
        (formNotifier as dynamic).setPaymentMethodId(_tryInt(payment) ?? payment);
      } catch (_) {
        try {
          (formNotifier as dynamic).setPaymentMethod(_tryInt(payment) ?? payment);
        } catch (_) {}
      }
    }

    // ✅ Compute FIRST (do not clear table yet)
    final computed = _computeCommission(tx);

    // ✅ Use cache if current payload is missing base
    final cached = _computedCache[tx.id];
    final effective = computed ?? cached;

    // ✅ If we still have nothing - DO NOT overwrite UI (this is the main fix)
    if (effective == null) {
      debugPrint(
        '⚠️ PREFILL skipped tx=${tx.id} (computed=NULL, cached=NULL). Keeping previous invoice values.',
      );
      debugPrint(
        '   debug: isPercent=${_isCommissionPercent(tx)} '
        'rate=${_tryCommissionRatePercent(tx)} '
        'base=${_tryBaseForPercent(tx)} '
        'fixed=${_tryCommissionFixedAmount(tx)}',
      );
      return;
    }

    // ✅ Save good computed
    _computedCache[tx.id] = effective;

    // ✅ Now we can safely enforce single-row mode
    tableNotifier.clearAll();

    final itemName = tType.isNotEmpty ? tType : 'commission'.tr;

    // Form total - assume gross preview
    try {
      formNotifier.setTotalAmountFromDouble(effective.gross);
    } catch (_) {}

    // Table row uses NET (your table computes VAT/gross)
    tableNotifier.setSingleServiceItem(
      name: itemName,
      unitNetPrice: effective.net,
      quantity: 1,
      vatRate: effective.vat,
      unit: 'szt',
      currency: _tryCurrency(tx),
    );

    debugPrint(
      '✅ PREFILL tx=${tx.id} '
      'isPercent=${effective.isPercent} rate=${effective.rate} '
      'base=${effective.baseGross} isNet=${effective.isNet} vat=${effective.vat} '
      'net=${effective.net} gross=${effective.gross}',
    );
  }

  void _normalizeSelectedTxInstance({
    required List<AgentTransactionModel> transactions,
    required AgentTransactionModel? selectedTx,
  }) {
    if (selectedTx == null) return;

    final match = transactions.where((t) => t.id == selectedTx.id).toList();
    if (match.length == 1 && !identical(match.first, selectedTx)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastPrefillSignature = null; // force re-prefill
        ref.read(selectedTransactionProvider.notifier).state = match.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final mode = ref.watch(invoiceFlowModeProvider);
    final transactionStateAsync = ref.watch(transactionProvider);
    final selectedTx = ref.watch(selectedTransactionProvider);

    final formNotifier = ref.read(revenueFormProvider.notifier);
    final tableNotifier = ref.read(invoiceTableProvider.notifier);

    if (mode != InvoiceFlowMode.transaction) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.isMobile
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: transactionStateAsync.when(
        data: (state) {
          final transactions = state.transactions;
          _normalizeSelectedTxInstance(transactions: transactions, selectedTx: selectedTx);

          return Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'link_to_transaction'.tr,
                      style: AppTextStyles.interBold.copyWith(color: theme.textColor, fontSize: 14),
                    ),
                    const Spacer(),
                    if (selectedTx != null)
                      TextButton(
                        onPressed: () {
                          ref.read(selectedTransactionProvider.notifier).state = null;

                          formNotifier.clearTransaction();
                          tableNotifier.clearAll();

                          formNotifier.clearClient();
                          ref.read(selectedClientProvider.notifier).state = null;

                          _lastPrefillSignature = null;
                        },
                        child: Text('remove_link'.tr, style: TextStyle(color: theme.textColor)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<AgentTransactionModel>(
                  value: selectedTx == null
                      ? null
                      : transactions.firstWhere(
                          (t) => t.id == selectedTx.id,
                          orElse: () => selectedTx,
                        ),
                  style: TextStyle(color: theme.textColor),
                  hint: Text('select_transaction'.tr, style: TextStyle(color: theme.textColor)),
                  decoration: _decor(theme),
                  dropdownColor: theme.dashboardContainer,
                  icon: Icon(Icons.arrow_drop_down, color: theme.textColor),
                  items: transactions
                      .map(
                        (tx) => DropdownMenuItem<AgentTransactionModel>(
                          value: tx,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.name,
                                style: AppTextStyles.interBold.copyWith(fontSize: 14, color: theme.textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(tx as dynamic).transactionType ?? ''}',
                                style: AppTextStyles.interRegular12.copyWith(
                                  color: theme.textColor.withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) {
                    return transactions.map((tx) {
                      return Text(
                        tx.name,
                        style: AppTextStyles.interBold.copyWith(fontSize: 14, color: theme.textColor),
                      );
                    }).toList();
                  },
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(selectedTransactionProvider.notifier).state = value;
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${'Error'.tr}: $err')),
      ),
    );
  }

  InputDecoration _decor(ThemeColors theme) {
    return InputDecoration(
      filled: true,
      fillColor: theme.dashboardContainer,
      hintStyle: TextStyle(color: theme.textColor),
      labelStyle: TextStyle(color: theme.textColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dashboardBoarder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dashboardBoarder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.themeColor, width: 2),
      ),
    );
  }
}

// -------------------------
// Data class for computed commission
// -------------------------
class _ComputedCommission {
  final double raw; // value in nature of isNet (net if isNet=true else gross)
  final double net;
  final double gross;
  final double vat;
  final bool isNet;
  final bool isPercent;
  final double? rate;
  final double? baseGross;

  _ComputedCommission({
    required this.raw,
    required this.net,
    required this.gross,
    required this.vat,
    required this.isNet,
    required this.isPercent,
    required this.rate,
    required this.baseGross,
  });
}
