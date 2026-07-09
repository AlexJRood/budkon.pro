// ===============================
// lib/crm_agent/add_invoice_form/widgets/invoice_data_table_widget.dart
// PRO / Production-ready
// Fixes:
// - ScrollController moved to State (not created in build)
// - Fully compatible with IMMUTABLE InvoiceRow + notifier helper methods
// - Transaction lock mode: table cooperates with TransactionForm
//   (prevents user breaking prefill + avoids weird state loops)
// Comments in English.
// ===============================

import 'package:crm/invoices/form/provider/invoice_table_provider.dart';
import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_flow_provider.dart';
import 'package:crm/invoices/models/invoice_item.dart';
import 'package:crm/invoices/providers/invoice_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

// If you keep this in another file, remove duplicate.
final invoiceTableAutoColumnsProvider = StateProvider<bool>((ref) => true);

enum InvoiceTableColumn {
  name,
  advance,
  quantity,
  unit,
  gtu,
  unitPrice,
  unitDiscount,
  vatRate,
  netValue,
  vatAmount,
  grossValue,
  currency,
  actions,
}

extension InvoiceTableColumnX on InvoiceTableColumn {
  String get label {
    switch (this) {
      case InvoiceTableColumn.name:
        return 'name_of_service'.tr;
      case InvoiceTableColumn.advance:
        return 'advance'.tr;
      case InvoiceTableColumn.quantity:
        return 'quantity'.tr;
      case InvoiceTableColumn.unit:
        return 'iu'.tr;
      case InvoiceTableColumn.gtu:
        return 'gtu'.tr;
      case InvoiceTableColumn.unitPrice:
        return 'unit_price'.tr;
      case InvoiceTableColumn.unitDiscount:
        return 'unit_discount'.tr;
      case InvoiceTableColumn.vatRate:
        return 'vat_rate_percent'.tr;
      case InvoiceTableColumn.netValue:
        return 'net_value'.tr;
      case InvoiceTableColumn.vatAmount:
        return 'vat_amount'.tr;
      case InvoiceTableColumn.grossValue:
        return 'gross_value'.tr;
      case InvoiceTableColumn.currency:
        return 'currency'.tr;
      case InvoiceTableColumn.actions:
        return '';
    }
  }

  bool get isNumeric {
    switch (this) {
      case InvoiceTableColumn.quantity:
      case InvoiceTableColumn.unitPrice:
      case InvoiceTableColumn.unitDiscount:
      case InvoiceTableColumn.vatRate:
      case InvoiceTableColumn.netValue:
      case InvoiceTableColumn.vatAmount:
      case InvoiceTableColumn.grossValue:
        return true;
      default:
        return false;
    }
  }

  double? get fixedWidth {
    switch (this) {
      case InvoiceTableColumn.name:
        return 360;
      case InvoiceTableColumn.advance:
        return 82;
      case InvoiceTableColumn.quantity:
        return 96;
      case InvoiceTableColumn.unit:
        return 92;
      case InvoiceTableColumn.gtu:
        return 108;
      case InvoiceTableColumn.unitPrice:
        return 126;
      case InvoiceTableColumn.unitDiscount:
        return 126;
      case InvoiceTableColumn.vatRate:
        return 108;
      case InvoiceTableColumn.netValue:
        return 126;
      case InvoiceTableColumn.vatAmount:
        return 126;
      case InvoiceTableColumn.grossValue:
        return 126;
      case InvoiceTableColumn.currency:
        return 96;
      case InvoiceTableColumn.actions:
        return 64;
    }
  }
}

class InvoiceTableColumnsNotifier extends StateNotifier<List<InvoiceTableColumn>> {
  InvoiceTableColumnsNotifier()
      : super(const [
          InvoiceTableColumn.name,
          InvoiceTableColumn.quantity,
          InvoiceTableColumn.unit,
          InvoiceTableColumn.unitPrice,
          InvoiceTableColumn.vatRate,
          InvoiceTableColumn.netValue,
          InvoiceTableColumn.vatAmount,
          InvoiceTableColumn.grossValue,
          InvoiceTableColumn.currency,
          InvoiceTableColumn.actions,
        ]);

  void toggle(InvoiceTableColumn col) {
    if (col == InvoiceTableColumn.actions) return;
    final next = [...state];

    if (next.contains(col)) {
      next.remove(col);
    } else {
      final actionsIndex = next.indexOf(InvoiceTableColumn.actions);
      if (actionsIndex >= 0) {
        next.insert(actionsIndex, col);
      } else {
        next.add(col);
      }
    }

    next.remove(InvoiceTableColumn.actions);
    next.add(InvoiceTableColumn.actions);

    state = next;
  }
}

final invoiceTableColumnsProvider =
    StateNotifierProvider<InvoiceTableColumnsNotifier, List<InvoiceTableColumn>>(
  (ref) => InvoiceTableColumnsNotifier(),
);

class InvoiceDataTable extends ConsumerStatefulWidget {
  final bool isMobile;
  const InvoiceDataTable({super.key, required this.isMobile});

  @override
  ConsumerState<InvoiceDataTable> createState() => _InvoiceDataTableState();
}

class _InvoiceDataTableState extends ConsumerState<InvoiceDataTable> {
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, FocusNode> _focus = {};
  bool _syncing = false;

  // Keep a stable horizontal scroll controller.
  final ScrollController _hScroll = ScrollController();

  String _k(String rowId, String field) => '$rowId|$field';

  TextEditingController _c(String rowId, String field, String initial) {
    final key = _k(rowId, field);
    return _ctrl.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  FocusNode _f(String rowId, String field) {
    final key = _k(rowId, field);
    return _focus.putIfAbsent(key, () => FocusNode());
  }

  double? _parseDouble(String v) {
    final s = v.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  String _fmt2(num v) => v.toStringAsFixed(2);

  // Sync controllers from model, but never override a focused field (no cursor jumps).
  void _syncControllers(List<InvoiceRow> rows) {
    _syncing = true;
    try {
      final existingKeys = <String>{};

      for (final r in rows) {
        void syncField(String field, String value) {
          final c = _c(r.rowId, field, value);
          final f = _f(r.rowId, field);
          existingKeys.add(_k(r.rowId, field));
          if (!f.hasFocus && c.text != value) {
            c.text = value;
          }
        }

        syncField('name', r.productName);
        syncField('qty', _fmt2(r.quantity));
        syncField('unitPrice', _fmt2(r.unitPrice));
        syncField('discount', _fmt2(r.unitDiscount));
        syncField('vatRate', _fmt2(r.vatRate));
        syncField('net', _fmt2(r.netAmount));
        syncField('gross', _fmt2(r.grossValue));
      }

      // Clean up controllers for removed rows
      final toRemove = _ctrl.keys.where((k) => !existingKeys.contains(k)).toList();
      for (final k in toRemove) {
        _ctrl[k]?.dispose();
        _ctrl.remove(k);
        _focus[k]?.dispose();
        _focus.remove(k);
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _hScroll.dispose();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _openPresetPicker(BuildContext context, ThemeColors theme) async {
    String search = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSB) {
            return Consumer(
              builder: (ctx, refBottom, _) {
                final asyncPresets = refBottom.watch(invoiceItemPresetListProvider(search));

                return Container(
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    border: Border.all(color: theme.dashboardBoarder),
                  ),
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'add_from_presets'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(Icons.close, color: theme.textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (v) => setStateSB(() => search = v),
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                            hintText: 'search_by_name_description_code'.tr,
                          hintStyle: TextStyle(color: theme.textColor.withAlpha(140)),
                          filled: true,
                          fillColor: theme.adPopBackground,
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 420,
                        child: asyncPresets.when(
                          data: (list) {
                            if (list.isEmpty) {
                              return Center(
                                child: Text(
                                 'no_presets_create_in_settings'.tr,
                                  style: TextStyle(color: theme.textColor.withAlpha(180)),
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: theme.dashboardBoarder.withAlpha(120),
                              ),
                              itemBuilder: (ctx, i) {
                                final InvoiceItemPresetModel p = list[i];

                                return ListTile(
                                  title: Text(
                                    p.name,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${p.unitNetPrice} ${p.currency} • ${p.unit} • VAT ${p.vatRate}%',
                                    style: TextStyle(color: theme.textColor.withAlpha(170)),
                                  ),
                                  trailing: Icon(Icons.add_circle_outline, color: theme.themeColor),
                                  onTap: () {
                                    refBottom.read(invoiceTableProvider.notifier).addRowFromPreset(p);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, st) => Center(
                            child: Text('${'Error'.tr}: $e', style: const TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openColumnsPicker(BuildContext context, ThemeColors theme) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, refBottom, _) {
            final selected = refBottom.watch(invoiceTableColumnsProvider);
            final notifier = refBottom.read(invoiceTableColumnsProvider.notifier);

            final all =
                InvoiceTableColumn.values.where((c) => c != InvoiceTableColumn.actions).toList();

            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border.all(color: theme.dashboardBoarder),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'table_columns'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, color: theme.textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...all.map((col) {
                    final isOn = selected.contains(col);
                    return CheckboxListTile(
                      value: isOn,
                      onChanged: (_) => notifier.toggle(col),
                      activeColor: theme.themeColor,
                      checkColor: theme.themeTextColor,
                      title: Text(col.label, style: TextStyle(color: theme.textColor)),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<InvoiceTableColumn> _computeAutoColumns(List<InvoiceRow> rows) {
    final anyAdvance = rows.any((r) => r.advance == true);
    final anyDiscount = rows.any((r) => r.unitDiscount != 0);
    final anyGTU = rows.any((r) => r.gtu.trim().isNotEmpty);

    return <InvoiceTableColumn>[
      InvoiceTableColumn.name,
      if (anyAdvance) InvoiceTableColumn.advance,
      InvoiceTableColumn.quantity,
      InvoiceTableColumn.unit,
      if (anyGTU) InvoiceTableColumn.gtu,
      InvoiceTableColumn.unitPrice,
      if (anyDiscount) InvoiceTableColumn.unitDiscount,
      InvoiceTableColumn.vatRate,
      InvoiceTableColumn.netValue,
      InvoiceTableColumn.vatAmount,
      InvoiceTableColumn.grossValue,
      InvoiceTableColumn.currency,
      InvoiceTableColumn.actions,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(invoiceTableProvider);
    final tableNotifier = ref.read(invoiceTableProvider.notifier);
    final theme = ref.watch(themeColorsProvider);
    final formState = ref.watch(revenueFormProvider);

    // Transaction cooperation:
    final mode = ref.watch(invoiceFlowModeProvider);
    final selectedTx = ref.watch(selectedTransactionProvider);
    final bool lockedToTransaction = mode == InvoiceFlowMode.transaction && selectedTx != null;

    // Keep controllers in sync safely.
    _syncControllers(rows);

    final manualCols = ref.watch(invoiceTableColumnsProvider);
    final autoEnabled = ref.watch(invoiceTableAutoColumnsProvider);
    final columns = autoEnabled ? _computeAutoColumns(rows) : manualCols;

    final baseIU = <String>['', 'szt', 'szt.', 'pes', 'kg', 'm'];
    final iuOptions = <String>{
      ...baseIU,
      ...rows.map((r) => r.iu).where((u) => u.trim().isNotEmpty),
    }.toList();

    final gtuOptions = <String>['', 'LACK', 'OTHER'];

    String normalizeIU(String v) => tableNotifier.normalizeUnit(v);

    String normalizeGTU(String v) {
      final x = (v).trim().toUpperCase();
      if (x.isEmpty) return '';
      if (gtuOptions.contains(x)) return x;
      return '';
    }

    String? safeDropdownValue(String? value, List<String> options) {
      if (value == null) return null;
      return options.contains(value) ? value : null;
    }

    List<DataColumn> buildColumns() {
      return columns.map((column) {
        if (column == InvoiceTableColumn.actions) {
          return const DataColumn(
            label: SizedBox(width: 40),
          );
        }

        final width = column.fixedWidth ?? 100;
        final alignment = column.isNumeric
            ? Alignment.centerRight
            : Alignment.centerLeft;

        return DataColumn(
          numeric: column.isNumeric,
          tooltip: column.label,
          label: SizedBox(
            width: width,
            child: Align(
              alignment: alignment,
              child: Text(
                column.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.themeTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ),
        );
      }).toList();
    }

    InputDecoration baseCellDeco({
      required bool readOnly,
      String? hint,
    }) {
      final borderColor = theme.dashboardBoarder.withAlpha(150);
      final fillColor = readOnly
          ? theme.dashboardBoarder.withAlpha(28)
          : theme.adPopBackground.withAlpha(155);

      return InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: theme.textColor.withAlpha(105)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.themeColor, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor.withAlpha(90)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
      );
    }

    Widget numCell({
      required TextEditingController controller,
      required FocusNode focusNode,
      required void Function(String) onChanged,
      bool readOnly = false,
    }) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: theme.textColor,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: readOnly ? theme.textColor.withAlpha(185) : theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: baseCellDeco(readOnly: readOnly),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
        readOnly: readOnly,
        onChanged: (value) {
          if (_syncing || readOnly) return;
          onChanged(value);
        },
      );
    }

    Widget textCell({
      required TextEditingController controller,
      required FocusNode focusNode,
      required void Function(String) onChanged,
      String? hint,
      bool readOnly = false,
    }) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: theme.textColor,
        style: TextStyle(
          color: readOnly ? theme.textColor.withAlpha(185) : theme.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        readOnly: readOnly,
        decoration: baseCellDeco(readOnly: readOnly, hint: hint),
        onChanged: (value) {
          if (_syncing || readOnly) return;
          onChanged(value);
        },
      );
    }

    Widget cellDropdown({
      required Widget child,
      bool readOnly = false,
      Alignment alignment = Alignment.centerLeft,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: readOnly
                ? theme.dashboardBoarder.withAlpha(28)
                : theme.adPopBackground.withAlpha(155),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dashboardBoarder.withAlpha(150),
            ),
          ),
          child: Align(
            alignment: alignment,
            child: DropdownButtonHideUnderline(child: child),
          ),
        ),
      );
    }

    Widget calculatedValue(String value, {bool strong = false}) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    List<DataCell> buildRowCells(int i, InvoiceRow row) {
      final cells = <DataCell>[];

      // Controllers
      final nameC = _c(row.rowId, 'name', row.productName);
      final qtyC = _c(row.rowId, 'qty', _fmt2(row.quantity));
      final priceC = _c(row.rowId, 'unitPrice', _fmt2(row.unitPrice));
      final discC = _c(row.rowId, 'discount', _fmt2(row.unitDiscount));
      final vatC = _c(row.rowId, 'vatRate', _fmt2(row.vatRate));
      final netC = _c(row.rowId, 'net', _fmt2(row.netAmount));
      final grossC = _c(row.rowId, 'gross', _fmt2(row.grossValue));

      final nameF = _f(row.rowId, 'name');
      final qtyF = _f(row.rowId, 'qty');
      final priceF = _f(row.rowId, 'unitPrice');
      final discF = _f(row.rowId, 'discount');
      final vatF = _f(row.rowId, 'vatRate');
      final netF = _f(row.rowId, 'net');
      final grossF = _f(row.rowId, 'gross');

      // In transaction mode: lock editing so prefill owns the row.
      final bool lockRow = lockedToTransaction;

      for (final col in columns) {
        switch (col) {
          case InvoiceTableColumn.name:
            cells.add(
              DataCell(
                Row(
                  children: [
                    Expanded(
                      child: textCell(
                        controller: nameC,
                        focusNode: nameF,
                        hint: 'name_of_service'.tr,
                        readOnly: lockRow,
                        onChanged: (v) => tableNotifier.updateName(i, v),
                      ),
                    ),
                    if (lockedToTransaction) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.themeColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.themeColor.withAlpha(120)),
                        ),
                        child: Text(
                          'tx'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (row.presetUuid != null && !lockedToTransaction) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.themeColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.themeColor.withAlpha(120)),
                        ),
                        child: Text(
                          'preset_label'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
            break;

          case InvoiceTableColumn.advance:
            cells.add(
              DataCell(
                Checkbox(
                  value: row.advance,
                  onChanged: lockRow ? null : (v) => v == null ? null : tableNotifier.updateAdvance(i, v),
                ),
              ),
            );
            break;

          case InvoiceTableColumn.quantity:
            cells.add(
              DataCell(
                numCell(
                  controller: qtyC,
                  focusNode: qtyF,
                  readOnly: lockRow,
                  onChanged: (v) {
                    final d = _parseDouble(v);
                    if (d == null) return;
                    tableNotifier.updateQuantity(i, d);
                  },
                ),
              ),
            );
            break;

          case InvoiceTableColumn.unit:
            cells.add(
              DataCell(
                cellDropdown(
                  readOnly: lockRow,
                  child: DropdownButton<String>(
                    value: safeDropdownValue(normalizeIU(row.iu), iuOptions),
                    items: iuOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.isEmpty ? '—' : e)))
                        .toList(),
                    onChanged: lockRow ? null : (val) => val == null ? null : tableNotifier.updateUnit(i, normalizeIU(val)),
                    underline: const SizedBox(),
                    dropdownColor: theme.dashboardContainer,
                    style: TextStyle(color: theme.textColor),
                    isDense: true,
                  ),
                ),
              ),
            );
            break;

          case InvoiceTableColumn.gtu:
            cells.add(
              DataCell(
                cellDropdown(
                  readOnly: lockRow,
                  child: DropdownButton<String>(
                    value: safeDropdownValue(normalizeGTU(row.gtu), gtuOptions),
                    items: gtuOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.isEmpty ? '—' : e)))
                        .toList(),
                    onChanged: lockRow ? null : (val) => val == null ? null : tableNotifier.updateGTU(i, normalizeGTU(val)),
                    underline: const SizedBox(),
                    dropdownColor: theme.dashboardContainer,
                    style: TextStyle(color: theme.textColor),
                    isDense: true,
                  ),
                ),
              ),
            );
            break;

          case InvoiceTableColumn.unitPrice:
            cells.add(
              DataCell(
                numCell(
                  controller: priceC,
                  focusNode: priceF,
                  readOnly: lockRow,
                  onChanged: (v) {
                    final d = _parseDouble(v);
                    if (d == null) return;
                    tableNotifier.updateUnitPrice(i, d);
                  },
                ),
              ),
            );
            break;

          case InvoiceTableColumn.unitDiscount:
            cells.add(
              DataCell(
                numCell(
                  controller: discC,
                  focusNode: discF,
                  readOnly: lockRow,
                  onChanged: (v) {
                    final d = _parseDouble(v);
                    if (d == null) return;
                    tableNotifier.updateDiscount(i, d);
                  },
                ),
              ),
            );
            break;

          case InvoiceTableColumn.vatRate:
            cells.add(
              DataCell(
                numCell(
                  controller: vatC,
                  focusNode: vatF,
                  readOnly: lockRow,
                  onChanged: (v) {
                    final d = _parseDouble(v);
                    if (d == null) return;
                    tableNotifier.updateVatRate(i, d);
                  },
                ),
              ),
            );
            break;

          case InvoiceTableColumn.netValue:
            cells.add(
              DataCell(
                numCell(
                  controller: netC,
                  focusNode: netF,
                  readOnly: lockRow,
                  onChanged: (v) {
                    final d = _parseDouble(v);
                    if (d == null) return;
                    tableNotifier.applyNetValue(i, d);
                  },
                ),
              ),
            );
            break;

          case InvoiceTableColumn.vatAmount:
            cells.add(
              DataCell(
                calculatedValue(row.vatAmount.toStringAsFixed(2)),
              ),
            );
            break;

          case InvoiceTableColumn.grossValue:
            cells.add(
              DataCell(
                numCell(
                  controller: grossC,
                  focusNode: grossF,
                  readOnly: lockRow,
                  onChanged: (v) {
                    final d = _parseDouble(v);
                    if (d == null) return;
                    tableNotifier.applyGrossValue(i, d);
                  },
                ),
              ),
            );
            break;

          case InvoiceTableColumn.currency:
            cells.add(
              DataCell(
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(24),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.themeColor.withAlpha(70)),
                    ),
                    child: Text(
                      row.currency,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
            break;

          case InvoiceTableColumn.actions:
            cells.add(
              DataCell(
                Center(
                  child: Tooltip(
                    message: 'delete'.tr,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 19),
                      color: Colors.redAccent,
                      disabledColor: theme.textColor.withAlpha(55),
                      onPressed: (lockedToTransaction || rows.length <= 1)
                          ? null
                          : () => tableNotifier.removeRow(i),
                    ),
                  ),
                ),
              ),
            );
            break;
        }
      }

      return cells;
    }

    List<DataCell> buildSummaryRow() {
      // Totals should be calculated from WATCHED rows to rebuild correctly.
      final totalNet = rows.fold<double>(0.0, (s, r) => s + r.netAmount);
      final totalVat = rows.fold<double>(0.0, (s, r) => s + r.vatAmount);
      final totalGross = rows.fold<double>(0.0, (s, r) => s + r.grossValue);

      final cells = <DataCell>[];

      for (final col in columns) {
        switch (col) {
          case InvoiceTableColumn.name:
            cells.add(
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Text(
                      'together'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor),
                    ),
                  ),
                ),
              ),
            );
            break;

          case InvoiceTableColumn.netValue:
            cells.add(
              DataCell(
                calculatedValue(totalNet.toStringAsFixed(2), strong: true),
              ),
            );
            break;

          case InvoiceTableColumn.vatAmount:
            cells.add(
              DataCell(
                calculatedValue(totalVat.toStringAsFixed(2), strong: true),
              ),
            );
            break;

          case InvoiceTableColumn.grossValue:
            cells.add(
              DataCell(
                calculatedValue(totalGross.toStringAsFixed(2), strong: true),
              ),
            );
            break;

          case InvoiceTableColumn.currency:
            cells.add(
              DataCell(
                cellDropdown(
                  child: DropdownButton<String>(
                    value: ref.watch(selectedCurrencyProvider),
                    items: const [
                      DropdownMenuItem(value: 'PLN', child: Text('PLN')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: lockedToTransaction
                        ? null
                        : (value) {
                            if (value == null) return;
                            ref.read(selectedCurrencyProvider.notifier).state = value;
                            formState.currencyController.text = value;
                            ref.read(invoiceTableProvider.notifier).setCurrencyForAll(value);
                          },
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: theme.dashboardContainer,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
            );
            break;

          default:
            cells.add(const DataCell(SizedBox()));
            break;
        }
      }

      return cells;
    }

    // If rows are empty in manual mode, show nice empty state.
    final bool showEmptyState = rows.isEmpty && !lockedToTransaction;

    final toolbarButtons = <Widget>[
      OutlinedButton.icon(
        style: elevatedButtonStyleRounded10,
        onPressed: () {
          ref.read(invoiceTableAutoColumnsProvider.notifier).state =
              !ref.read(invoiceTableAutoColumnsProvider);
        },
        icon: Icon(
          autoEnabled ? Icons.auto_awesome : Icons.tune,
          size: 18,
          color: theme.textColor,
        ),
        label: Text(
          autoEnabled ? 'auto'.tr : 'manual'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      ),
      OutlinedButton.icon(
        style: elevatedButtonStyleRounded10,
        onPressed: () => _openColumnsPicker(context, theme),
        icon: Icon(Icons.view_column_outlined, size: 18, color: theme.textColor),
        label: Text('columns'.tr, style: TextStyle(color: theme.textColor)),
      ),
      OutlinedButton.icon(
        style: elevatedButtonStyleRounded10,
        onPressed: lockedToTransaction
            ? null
            : () => _openPresetPicker(context, theme),
        icon: Icon(Icons.playlist_add, size: 18, color: theme.textColor),
        label: Text(
          'add_from_presets_button'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      ),
      ElevatedButton.icon(
        onPressed: lockedToTransaction ? null : tableNotifier.addRow,
        icon: const Icon(Icons.add, size: 18),
        label: Text('onetime'.tr),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.themeColor,
          foregroundColor: theme.themeTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ];

    return Padding(
      padding: widget.isMobile
          ? const EdgeInsets.symmetric(horizontal: 10)
          : const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = widget.isMobile || constraints.maxWidth < 980;

              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: theme.themeColor.withAlpha(24),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 19,
                          color: theme.themeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'invoice_items'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (lockedToTransaction)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: theme.textColor.withAlpha(150),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'locked_to_transaction_auto_prefill'.tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(160),
                                fontSize: 12,
                              ),
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
                alignment: WrapAlignment.end,
                children: toolbarButtons,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: title),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (showEmptyState)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dashboardBoarder),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: theme.themeColor),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      'no_items_add_onetime_or_from_presets'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(190),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: tableNotifier.addRow,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('add'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      foregroundColor: theme.themeTextColor,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dashboardBoarder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!_hScroll.hasClients) return;
                    final next = (_hScroll.offset - details.delta.dx).clamp(
                      0.0,
                      _hScroll.position.maxScrollExtent,
                    );
                    _hScroll.jumpTo(next);
                  },
                  child: Scrollbar(
                    controller: _hScroll,
                    thumbVisibility: !widget.isMobile,
                    trackVisibility: false,
                    child: SingleChildScrollView(
                      controller: _hScroll,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 54,
                        dataRowMinHeight: 58,
                        dataRowMaxHeight: 66,
                        horizontalMargin: 14,
                        checkboxHorizontalMargin: 12,
                        columnSpacing: 14,
                        dividerThickness: 0,
                        headingRowColor: WidgetStatePropertyAll(
                          theme.themeColor,
                        ),
                        headingTextStyle: TextStyle(
                          color: theme.themeTextColor,
                          fontWeight: FontWeight.w800,
                        ),
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: theme.dashboardBoarder.withAlpha(100),
                          ),
                        ),
                        columns: buildColumns(),
                        rows: [
                          ...List.generate(rows.length, (index) {
                            final row = rows[index];
                            return DataRow(
                              key: ValueKey(row.rowId),
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return theme.themeColor.withAlpha(18);
                                }
                                return index.isEven
                                    ? theme.dashboardContainer
                                    : theme.adPopBackground.withAlpha(75);
                              }),
                              cells: buildRowCells(index, row),
                            );
                          }),
                          DataRow(
                            key: const ValueKey('__summary__'),
                            color: WidgetStatePropertyAll(
                              theme.themeColor.withAlpha(24),
                            ),
                            cells: buildSummaryRow(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.isMobile) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(
                    Icons.swipe_outlined,
                    size: 15,
                    color: theme.textColor.withAlpha(120),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'scroll_horizontally'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(120),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
