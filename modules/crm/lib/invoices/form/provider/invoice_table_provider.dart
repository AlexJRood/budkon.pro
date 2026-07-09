import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/invoices/models/invoice_item.dart'; // InvoiceItemPresetModel

// ===============================
// InvoiceRow (IMMUTABLE, production-ready)
// ===============================
class InvoiceRow {
  // Stable identity for UI (controllers/keys).
  final String rowId;

  final String productName;
  final bool advance;
  final double quantity;

  /// Unit (IU)
  final String iu;

  /// GTU (optional)
  final String gtu;

  /// NET per unit
  final double unitPrice;

  /// Discount applied on line net (not per unit)
  final double unitDiscount;

  /// VAT rate in percent (e.g. 23 means 23%)
  final double vatRate;

  /// Currency per row
  final String currency;

  /// Optional link to preset
  final String? presetUuid;

  static int _seq = 0;

  static String _newRowId() {
    _seq++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  const InvoiceRow._({
    required this.rowId,
    required this.productName,
    required this.advance,
    required this.quantity,
    required this.iu,
    required this.gtu,
    required this.unitPrice,
    required this.unitDiscount,
    required this.vatRate,
    required this.currency,
    required this.presetUuid,
  });

  factory InvoiceRow({
    String? rowId,
    String productName = '',
    bool advance = false,
    double quantity = 1.0,
    String iu = 'szt',
    String gtu = 'OTHER',
    double unitPrice = 0.0,
    double unitDiscount = 0.0,
    double vatRate = 23.0,
    String currency = 'PLN',
    String? presetUuid,
  }) {
    return InvoiceRow._(
      rowId: rowId ?? _newRowId(),
      productName: productName,
      advance: advance,
      quantity: quantity,
      iu: iu,
      gtu: gtu,
      unitPrice: unitPrice,
      unitDiscount: unitDiscount,
      vatRate: vatRate,
      currency: currency,
      presetUuid: presetUuid,
    );
  }

  // Comments in English.
  // Always safe getters (no negatives unless user explicitly sets them).
  double get netAmount {
    final net = (unitPrice * quantity) - unitDiscount;
    return net.isFinite ? net : 0.0;
  }

  double get vatAmount {
    final v = netAmount * (vatRate / 100);
    return v.isFinite ? v : 0.0;
  }

  double get grossValue {
    final g = netAmount + vatAmount;
    return g.isFinite ? g : 0.0;
  }

  InvoiceRow copyWith({
    String? rowId,
    String? productName,
    bool? advance,
    double? quantity,
    String? iu,
    String? gtu,
    double? unitPrice,
    double? unitDiscount,
    double? vatRate,
    String? currency,
    String? presetUuid,
    bool clearPresetUuid = false,
  }) {
    return InvoiceRow._(
      rowId: rowId ?? this.rowId,
      productName: productName ?? this.productName,
      advance: advance ?? this.advance,
      quantity: quantity ?? this.quantity,
      iu: iu ?? this.iu,
      gtu: gtu ?? this.gtu,
      unitPrice: unitPrice ?? this.unitPrice,
      unitDiscount: unitDiscount ?? this.unitDiscount,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      presetUuid: clearPresetUuid ? null : (presetUuid ?? this.presetUuid),
    );
  }

  Map<String, dynamic> toJson() => {
        'preset_uuid': presetUuid,
        'product_name': productName,
        'advance': advance,
        'quantity': quantity,
        'unit': iu,
        'gtu': gtu,
        'unit_net_price': unitPrice,
        'unit_discount': unitDiscount,
        'vat_rate': vatRate,
        'currency': currency,
        'line_net_amount': netAmount,
        'line_vat_amount': vatAmount,
        'line_gross_amount': grossValue,
      };
}

extension InvoiceRowListX on List<InvoiceRow> {
  List<Map<String, dynamic>> toInvoiceItemMap() => map((row) => row.toJson()).toList();

  Map<String, dynamic> toInvoiceItemsPayload({String key = 'items'}) {
    return {key: toInvoiceItemMap()};
  }
}

final buyerTypeProvider = StateProvider<String>((ref) => 'existing');

// ===============================
// InvoiceTableNotifier (IMMUTABLE updates, production-ready)
// ===============================
class InvoiceTableNotifier extends StateNotifier<List<InvoiceRow>> {
  InvoiceTableNotifier() : super([InvoiceRow()]);

  // -------------------------
  // Helpers
  // -------------------------

  String normalizeUnit(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'szt.' || v == 'szt') return 'szt';
    return value.trim();
  }

  String normalizeGTU(String value) {
    final v = value.trim().toUpperCase();
    if (v.isEmpty) return '';
    return v;
  }

  double _parseNum(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(' ', '').replaceAll(',', '.').trim();
    return double.tryParse(s) ?? fallback;
  }

  double _clampFinite(double v, {double fallback = 0}) {
    if (!v.isFinite || v.isNaN) return fallback;
    return v;
  }

  bool _isPlaceholderRow(InvoiceRow r) {
    return r.presetUuid == null &&
        r.productName.trim().isEmpty &&
        r.unitPrice == 0.0 &&
        r.unitDiscount == 0.0;
  }

  bool _indexOk(int index) => index >= 0 && index < state.length;

  List<InvoiceRow> _replaceAt(int index, InvoiceRow row) {
    final next = [...state];
    next[index] = row;
    return next;
  }

  // -------------------------
  // CRUD rows
  // -------------------------

  void addRow() {
    state = [...state, InvoiceRow(currency: _safeCurrencyFallback())];
  }

  void removeRow(int index) {
    if (state.length <= 1) return;
    if (!_indexOk(index)) return;

    final next = [...state]..removeAt(index);
    state = next.isEmpty ? [InvoiceRow(currency: _safeCurrencyFallback())] : next;
  }

  // Production-safe update: never mutate existing row object.
  void updateRow(int index, InvoiceRow row) {
    if (!_indexOk(index)) return;

    final normalized = row.copyWith(
      iu: normalizeUnit(row.iu),
      gtu: normalizeGTU(row.gtu),
      quantity: _clampFinite(row.quantity, fallback: 1.0),
      unitPrice: _clampFinite(row.unitPrice),
      unitDiscount: _clampFinite(row.unitDiscount),
      vatRate: _clampFinite(row.vatRate, fallback: 23.0),
      currency: row.currency.trim().isEmpty ? _safeCurrencyFallback() : row.currency.trim(),
    );

    state = _replaceAt(index, normalized);
  }

  // Convenient field updates (UI can call these instead of building rows).
  void updateName(int index, String name) {
    if (!_indexOk(index)) return;
    state = _replaceAt(index, state[index].copyWith(productName: name));
  }

  void updateAdvance(int index, bool value) {
    if (!_indexOk(index)) return;
    state = _replaceAt(index, state[index].copyWith(advance: value));
  }

  void updateQuantity(int index, double qty) {
    if (!_indexOk(index)) return;
    final safeQty = _clampFinite(qty, fallback: 1.0);
    state = _replaceAt(index, state[index].copyWith(quantity: safeQty <= 0 ? 1.0 : safeQty));
  }

  void updateUnit(int index, String unit) {
    if (!_indexOk(index)) return;
    state = _replaceAt(index, state[index].copyWith(iu: normalizeUnit(unit)));
  }

  void updateGTU(int index, String gtu) {
    if (!_indexOk(index)) return;
    state = _replaceAt(index, state[index].copyWith(gtu: normalizeGTU(gtu)));
  }

  void updateUnitPrice(int index, double unitNet) {
    if (!_indexOk(index)) return;
    state = _replaceAt(index, state[index].copyWith(unitPrice: _clampFinite(unitNet)));
  }

  void updateDiscount(int index, double discount) {
    if (!_indexOk(index)) return;
    state = _replaceAt(index, state[index].copyWith(unitDiscount: _clampFinite(discount)));
  }

  void updateVatRate(int index, double vat) {
    if (!_indexOk(index)) return;
    final safeVat = _clampFinite(vat, fallback: 23.0);
    state = _replaceAt(index, state[index].copyWith(vatRate: safeVat < 0 ? 0.0 : safeVat));
  }

  void setCurrencyForAll(String currency) {
    final cur = currency.trim().isEmpty ? _safeCurrencyFallback() : currency.trim();
    state = [for (final r in state) r.copyWith(currency: cur)];
  }

  String _safeCurrencyFallback() {
    // Keep PLN default but don't crash.
    return state.isNotEmpty ? state.first.currency : 'PLN';
  }

  // -------------------------
  // Reset / clear
  // -------------------------

  void clearAll() {
    state = [InvoiceRow(currency: _safeCurrencyFallback())];
  }

  // -------------------------
  // Presets integration
  // -------------------------

  void addRowFromPreset(InvoiceItemPresetModel preset) {
    final qty = _parseNum(preset.defaultQuantity, fallback: 1);
    final price = _parseNum(preset.unitNetPrice, fallback: 0);
    final vat = _parseNum(preset.vatRate, fallback: 23);

    final row = InvoiceRow(
      presetUuid: preset.uuid,
      productName: preset.name,
      quantity: qty <= 0 ? 1.0 : qty,
      iu: normalizeUnit(preset.unit),
      gtu: 'OTHER',
      unitPrice: _clampFinite(price),
      unitDiscount: 0,
      vatRate: vat < 0 ? 0 : vat,
      currency: preset.currency.trim().isEmpty ? _safeCurrencyFallback() : preset.currency.trim(),
      advance: false,
    );

    // Replace placeholder if it's the only row.
    if (state.length == 1 && _isPlaceholderRow(state.first)) {
      state = [row];
      return;
    }

    state = [...state, row];
  }

  // -------------------------
  // Net/Gross input -> recalc unit NET
  // -------------------------

  // Comments in English.
  // User edits line NET value => compute unit NET price so that computed netAmount matches.
  void applyNetValue(int index, double netLine) {
    if (!_indexOk(index)) return;

    final row = state[index];
    final qty = row.quantity <= 0 ? 1.0 : row.quantity;

    final safeNetLine = _clampFinite(netLine);
    final unitNetPrice = (safeNetLine + row.unitDiscount) / qty;

    final nextRow = row.copyWith(
      unitPrice: _clampFinite(unitNetPrice),
    );

    state = _replaceAt(index, nextRow);
  }

  // Comments in English.
  // User edits line GROSS value => compute unit NET price so that computed gross matches.
  void applyGrossValue(int index, double gross) {
    if (!_indexOk(index)) return;

    final row = state[index];

    final qty = row.quantity <= 0 ? 1.0 : row.quantity;
    final vatRate = row.vatRate < 0 ? 0.0 : row.vatRate;

    final divisor = 1.0 + (vatRate / 100.0);
    if (divisor <= 0) return;

    final safeGross = _clampFinite(gross);
    final netLine = safeGross / divisor;

    final unitNetPrice = (netLine + row.unitDiscount) / qty;

    final nextRow = row.copyWith(
      unitPrice: _clampFinite(unitNetPrice),
    );

    state = _replaceAt(index, nextRow);
  }

  // Used by TransactionFormWidget: replace table with a single computed item.
  void setSingleServiceItem({
    required String name,
    required double unitNetPrice,
    double quantity = 1.0,
    double vatRate = 23.0,
    String unit = 'szt',
    String currency = 'PLN',
    String? presetUuid,
  }) {
    final cur = currency.trim().isEmpty ? _safeCurrencyFallback() : currency.trim();

    state = [
      InvoiceRow(
        presetUuid: presetUuid,
        productName: name,
        quantity: quantity <= 0 ? 1.0 : _clampFinite(quantity, fallback: 1.0),
        iu: normalizeUnit(unit),
        unitPrice: _clampFinite(unitNetPrice),
        vatRate: _clampFinite(vatRate, fallback: 23.0),
        unitDiscount: 0.0,
        advance: false,
        gtu: 'OTHER',
        currency: cur,
      ),
    ];
  }

  // -------------------------
  // Totals (pure, always correct)
  // -------------------------

  double get totalVatAmount => state.fold<double>(0.0, (sum, row) => sum + row.vatAmount);
  double get totalGrossValue => state.fold<double>(0.0, (sum, row) => sum + row.grossValue);
  double get totalNetValue => state.fold<double>(0.0, (sum, row) => sum + row.netAmount);
}

final invoiceTableProvider =
    StateNotifierProvider<InvoiceTableNotifier, List<InvoiceRow>>(
  (ref) => InvoiceTableNotifier(),
);
