import 'dart:convert';

import 'package:crm_fliper/models/fliper_transaction_checklist_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class DocumentItem {
  final String id;
  final String label;
  final bool completed;
  final bool required;

  const DocumentItem({
    required this.id,
    required this.label,
    required this.completed,
    required this.required,
  });

  DocumentItem copyWith({bool? completed, String? label}) => DocumentItem(
        id: id,
        label: label ?? this.label,
        completed: completed ?? this.completed,
        required: required,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'completed': completed,
        'required': required,
      };

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        completed: json['completed'] == true,
        required: json['required'] == true,
      );
}

// ---------------------------------------------------------------------------
// Property + Transaction type keys
// ---------------------------------------------------------------------------

enum PropType {
  apartment,
  house,
  plot,
  commercial,
  garage,
}

enum TxKind {
  sell,
  buy,
  rent,
}

TxKind _parseTxKind(String raw) {
  final t = raw.trim().toLowerCase();
  if (t.contains('sell') || t.contains('sprzedaż') || t.contains('sprzedaz')) return TxKind.sell;
  if (t.contains('buy') || t.contains('kupno') || t.contains('zakup')) return TxKind.buy;
  if (t.contains('rent') || t.contains('wynajem') || t.contains('najem')) return TxKind.rent;
  return TxKind.sell;
}

String _txKindKey(TxKind k) => k.name;
String _propTypeKey(PropType p) => p.name;

TxKind _txKindFromKey(String? k) =>
    TxKind.values.firstWhere((e) => e.name == k, orElse: () => TxKind.sell);

PropType _propTypeFromKey(String? k) =>
    PropType.values.firstWhere((e) => e.name == k, orElse: () => PropType.apartment);

// ---------------------------------------------------------------------------
// Document templates — full matrix
// ---------------------------------------------------------------------------

class _T {
  // Shared docs used in many templates
  static const _idDoc = DocumentItem(id: 'dowod_tozsamosci', label: 'Dokument tożsamości', completed: false, required: true);
  static const _kw = DocumentItem(id: 'kw_odpis', label: 'Odpis z Księgi Wieczystej', completed: false, required: true);
  static const _energyCert = DocumentItem(id: 'swiadectwo_energetyczne', label: 'Świadectwo charakterystyki energetycznej', completed: false, required: true);
  static const _taxClearance = DocumentItem(id: 'zaswiadczenie_podatki', label: 'Zaświadczenie o niezaleganiu z podatkami', completed: false, required: true);
  static const _preContract = DocumentItem(id: 'umowa_przedwstepna', label: 'Umowa przedwstępna', completed: false, required: true);
  static const _finalDeed = DocumentItem(id: 'akt_notarialny_finalny', label: 'Akt notarialny (finalny)', completed: false, required: true);
  static const _acquisitionDeed = DocumentItem(id: 'akt_nabycia', label: 'Akt notarialny nabycia nieruchomości', completed: false, required: true);
  static const _landRegister = DocumentItem(id: 'wypis_rejestr', label: 'Wypis z rejestru gruntów i wyrys z mapy', completed: false, required: true);
  static const _hoaClearance = DocumentItem(id: 'zaswiadczenie_spoldzielni', label: 'Zaświadczenie ze spółdzielni / wspólnoty', completed: false, required: false);
  static const _noResidencyCert = DocumentItem(id: 'zaswiadczenie_meldunek', label: 'Zaświadczenie o braku meldunku', completed: false, required: false);
  static const _occupancyPermit = DocumentItem(id: 'pozwolenie_uzytkowanie', label: 'Pozwolenie na użytkowanie', completed: false, required: false);
  static const _buildingPermit = DocumentItem(id: 'pozwolenie_budowlane', label: 'Pozwolenie na budowę', completed: false, required: true);
  static const _buildingLog = DocumentItem(id: 'dziennik_budowy', label: 'Dziennik budowy', completed: false, required: false);
  static const _techCertificate = DocumentItem(id: 'inwentaryzacja', label: 'Inwentaryzacja budynku / mapa geodezyjna', completed: false, required: false);
  static const _constructionConditions = DocumentItem(id: 'warunki_zabudowy', label: 'Decyzja o warunkach zabudowy (WZ)', completed: false, required: false);
  static const _zoningPlan = DocumentItem(id: 'wypis_mpzp', label: 'Wypis i wyrys z MPZP', completed: false, required: true);
  static const _soilConditions = DocumentItem(id: 'badania_gruntu', label: 'Badania geotechniczne gruntu', completed: false, required: false);
  static const _flatIndependence = DocumentItem(id: 'samodzielnosc_lokalu', label: 'Zaświadczenie o samodzielności lokalu', completed: false, required: true);
  static const _mortgage = DocumentItem(id: 'zaswiadczenie_hipoteka', label: 'Zaświadczenie banku o hipotece / spłacie', completed: false, required: false);
  static const _loan = DocumentItem(id: 'decyzja_kredytowa', label: 'Decyzja kredytowa', completed: false, required: false);
  static const _leaseContract = DocumentItem(id: 'umowa_najmu', label: 'Umowa najmu', completed: false, required: true);
  static const _handoverProtocol = DocumentItem(id: 'protokol_odbioru', label: 'Protokół zdawczo-odbiorczy', completed: false, required: true);
  static const _utilitiesClearance = DocumentItem(id: 'zaswiadczenie_media', label: 'Zaświadczenie o braku zaległości w mediach', completed: false, required: false);
  static const _tenantId = DocumentItem(id: 'dowod_najemca', label: 'Dowód tożsamości najemcy', completed: false, required: true);
  static const _landlordId = DocumentItem(id: 'dowod_wynajmujacy', label: 'Dowód tożsamości wynajmującego', completed: false, required: true);
  static const _usageFee = DocumentItem(id: 'oplaty_eksploatacyjne', label: 'Zaświadczenie o opłatach eksploatacyjnych', completed: false, required: false);

  // ── SELL ─────────────────────────────────────────────────────────────────

  static const sellApartment = [
    _kw,
    _acquisitionDeed,
    _landRegister,
    _flatIndependence,
    _energyCert,
    _taxClearance,
    _hoaClearance,
    _noResidencyCert,
    _mortgage,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const sellHouse = [
    _kw,
    _acquisitionDeed,
    _landRegister,
    _buildingPermit,
    _occupancyPermit,
    _buildingLog,
    _techCertificate,
    _energyCert,
    _taxClearance,
    _noResidencyCert,
    _mortgage,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const sellPlot = [
    _kw,
    _landRegister,
    _zoningPlan,
    _constructionConditions,
    _soilConditions,
    _taxClearance,
    _mortgage,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const sellCommercial = [
    _kw,
    _acquisitionDeed,
    _landRegister,
    _flatIndependence,
    _occupancyPermit,
    _energyCert,
    _taxClearance,
    _hoaClearance,
    _usageFee,
    _mortgage,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const sellGarage = [
    _kw,
    _acquisitionDeed,
    _flatIndependence,
    _taxClearance,
    _hoaClearance,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  // ── BUY ──────────────────────────────────────────────────────────────────

  static const buyApartment = [
    _kw,
    DocumentItem(id: 'akt_nabycia_sprzedajacego', label: 'Akt nabycia nieruchomości przez sprzedającego', completed: false, required: true),
    _landRegister,
    _flatIndependence,
    _energyCert,
    _taxClearance,
    _hoaClearance,
    _usageFee,
    _loan,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const buyHouse = [
    _kw,
    DocumentItem(id: 'akt_nabycia_sprzedajacego', label: 'Akt nabycia nieruchomości przez sprzedającego', completed: false, required: true),
    _landRegister,
    _buildingPermit,
    _occupancyPermit,
    _buildingLog,
    _energyCert,
    _taxClearance,
    _loan,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const buyPlot = [
    _kw,
    _landRegister,
    _zoningPlan,
    _constructionConditions,
    _taxClearance,
    _loan,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const buyCommercial = [
    _kw,
    DocumentItem(id: 'akt_nabycia_sprzedajacego', label: 'Akt nabycia nieruchomości przez sprzedającego', completed: false, required: true),
    _flatIndependence,
    _occupancyPermit,
    _energyCert,
    _taxClearance,
    _usageFee,
    _loan,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  static const buyGarage = [
    _kw,
    DocumentItem(id: 'akt_nabycia_sprzedajacego', label: 'Akt nabycia nieruchomości przez sprzedającego', completed: false, required: true),
    _flatIndependence,
    _taxClearance,
    _loan,
    _preContract,
    _finalDeed,
    _idDoc,
  ];

  // ── RENT ─────────────────────────────────────────────────────────────────

  static const rentApartment = [
    _kw,
    _landlordId,
    _tenantId,
    _leaseContract,
    _handoverProtocol,
    _hoaClearance,
    _utilitiesClearance,
  ];

  static const rentHouse = [
    _kw,
    _landlordId,
    _tenantId,
    _leaseContract,
    _handoverProtocol,
    _occupancyPermit,
    _utilitiesClearance,
  ];

  static const rentCommercial = [
    _kw,
    _landlordId,
    _tenantId,
    _flatIndependence,
    _occupancyPermit,
    _leaseContract,
    _handoverProtocol,
    _utilitiesClearance,
    _usageFee,
  ];

  static const rentGarage = [
    _kw,
    _landlordId,
    _tenantId,
    _leaseContract,
    _handoverProtocol,
  ];

  // ── LOOKUP ────────────────────────────────────────────────────────────────

  static List<DocumentItem> forCombo(TxKind tx, PropType prop) {
    switch (tx) {
      case TxKind.sell:
        switch (prop) {
          case PropType.apartment:  return sellApartment;
          case PropType.house:      return sellHouse;
          case PropType.plot:       return sellPlot;
          case PropType.commercial: return sellCommercial;
          case PropType.garage:     return sellGarage;
        }
      case TxKind.buy:
        switch (prop) {
          case PropType.apartment:  return buyApartment;
          case PropType.house:      return buyHouse;
          case PropType.plot:       return buyPlot;
          case PropType.commercial: return buyCommercial;
          case PropType.garage:     return buyGarage;
        }
      case TxKind.rent:
        switch (prop) {
          case PropType.apartment:  return rentApartment;
          case PropType.house:      return rentHouse;
          case PropType.plot:       return rentApartment; // fallback
          case PropType.commercial: return rentCommercial;
          case PropType.garage:     return rentGarage;
        }
    }
  }
}

// ---------------------------------------------------------------------------
// Provider state
// ---------------------------------------------------------------------------

class DocumentPipelineState {
  final int? checklistId;
  final List<DocumentItem> items;
  final bool loading;
  final bool saving;
  final TxKind? activeTxKind;
  final PropType? activePropType;

  const DocumentPipelineState({
    this.checklistId,
    this.items = const [],
    this.loading = true,
    this.saving = false,
    this.activeTxKind,
    this.activePropType,
  });

  DocumentPipelineState copyWith({
    int? checklistId,
    List<DocumentItem>? items,
    bool? loading,
    bool? saving,
    TxKind? activeTxKind,
    PropType? activePropType,
  }) =>
      DocumentPipelineState(
        checklistId: checklistId ?? this.checklistId,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        activeTxKind: activeTxKind ?? this.activeTxKind,
        activePropType: activePropType ?? this.activePropType,
      );

  int get done => items.where((i) => i.completed).length;
  int get total => items.length;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DocumentPipelineNotifier extends StateNotifier<DocumentPipelineState> {
  final Ref ref;
  final int transactionId;

  DocumentPipelineNotifier(this.ref, this.transactionId)
      : super(const DocumentPipelineState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await ApiServices.get(
        '${URLs.fetchTransactionChecklist}?transaction=$transactionId',
        ref: ref,
        hasToken: true,
      );

      if (resp == null || resp.statusCode != 200) {
        state = state.copyWith(loading: false);
        return;
      }

      final parsed = TransactionChecklistResponse.fromJson(resp.data);
      final existing = parsed.results
          .where((c) => c.transaction == transactionId)
          .firstOrNull;

      if (existing == null) {
        state = state.copyWith(loading: false);
        return;
      }

      final payload = _parsePayload(existing.checklist);
      state = state.copyWith(
        checklistId: existing.id,
        items: payload.items,
        activeTxKind: payload.txKind,
        activePropType: payload.propType,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  _Payload _parsePayload(dynamic raw) {
    if (raw == null) return const _Payload();
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;

      // New format: {meta: {...}, items: [...]}
      if (decoded is Map) {
        final meta = decoded['meta'];
        final itemsRaw = decoded['items'];
        return _Payload(
          items: itemsRaw is List
              ? itemsRaw
                  .map((e) => DocumentItem.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : [],
          txKind: meta is Map ? _txKindFromKey(meta['txKind']?.toString()) : null,
          propType: meta is Map ? _propTypeFromKey(meta['propType']?.toString()) : null,
        );
      }

      // Legacy format: plain list
      if (decoded is List) {
        return _Payload(
          items: decoded
              .map((e) => DocumentItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
    } catch (_) {}
    return const _Payload();
  }

  dynamic _encodePayload() {
    return {
      'meta': {
        'txKind': state.activeTxKind != null ? _txKindKey(state.activeTxKind!) : null,
        'propType': state.activePropType != null ? _propTypeKey(state.activePropType!) : null,
      },
      'items': state.items.map((i) => i.toJson()).toList(),
    };
  }

  Future<void> applyTemplate(TxKind txKind, PropType propType, int userId) async {
    final template = _T.forCombo(txKind, propType);
    final merged = template.map((t) {
      final existing = state.items.where((i) => i.id == t.id).firstOrNull;
      return existing ?? t;
    }).toList();
    // Keep custom items
    for (final item in state.items) {
      if (!merged.any((m) => m.id == item.id)) merged.add(item);
    }
    final next = state.copyWith(
      items: merged,
      activeTxKind: txKind,
      activePropType: propType,
    );
    state = next;
    await _persist(userId);
  }

  Future<void> toggleItem(String itemId, int userId) async {
    final updated = state.items.map((item) {
      if (item.id == itemId) return item.copyWith(completed: !item.completed);
      return item;
    }).toList();
    state = state.copyWith(items: updated);
    await _persist(userId);
  }

  Future<void> addCustomItem(String label, int userId) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final updated = [
      ...state.items,
      DocumentItem(id: id, label: label, completed: false, required: false),
    ];
    state = state.copyWith(items: updated);
    await _persist(userId);
  }

  Future<void> removeItem(String itemId, int userId) async {
    final updated = state.items.where((i) => i.id != itemId).toList();
    state = state.copyWith(items: updated);
    await _persist(userId);
  }

  Future<void> renameItem(String itemId, String newLabel, int userId) async {
    final updated = state.items
        .map((i) => i.id == itemId ? i.copyWith(label: newLabel) : i)
        .toList();
    state = state.copyWith(items: updated);
    await _persist(userId);
  }

  /// Auto-odhaczenie "Odpis z Księgi Wieczystej" po pobraniu KW.
  Future<void> markKwDone(int userId) async {
    const kwId = 'kw_odpis';
    final hasKw = state.items.any((i) => i.id == kwId);
    final updated = hasKw
        ? state.items.map((i) => i.id == kwId ? i.copyWith(completed: true) : i).toList()
        : [
            ...state.items,
            const DocumentItem(id: kwId, label: 'Odpis z Księgi Wieczystej', completed: true, required: true),
          ];
    state = state.copyWith(items: updated);
    await _persist(userId);
  }

  Future<void> applyEmmasuggestions(List<DocumentItem> suggestions, int userId) async {
    final merged = List<DocumentItem>.from(state.items);
    for (final s in suggestions) {
      if (!merged.any((m) => m.id == s.id)) merged.add(s);
    }
    state = state.copyWith(items: merged);
    await _persist(userId);
  }

  Future<void> _persist(int userId) async {
    state = state.copyWith(saving: true);
    final data = {
      'title': 'Dokumenty transakcji',
      'description': 'Pipeline dokumentów',
      'checklist': jsonEncode(_encodePayload()),
      'transaction': transactionId,
      'user': userId,
    };

    try {
      if (state.checklistId == null) {
        final resp = await ApiServices.post(
          URLs.fetchTransactionChecklist,
          data: data,
          hasToken: true,
        );
        if (resp != null && resp.statusCode == 201) {
          final created = FliperTransactionCheckList.fromJson(resp.data);
          state = state.copyWith(checklistId: created.id, saving: false);
        } else {
          state = state.copyWith(saving: false);
        }
      } else {
        await ApiServices.put(
          URLs.fetchSingleTransactionChecklist(state.checklistId!.toString()),
          data: data,
          hasToken: true,
        );
        state = state.copyWith(saving: false);
      }
    } catch (_) {
      state = state.copyWith(saving: false);
    }
  }
}

final documentPipelineProvider = StateNotifierProvider.family<
    DocumentPipelineNotifier, DocumentPipelineState, int>(
  (ref, transactionId) => DocumentPipelineNotifier(ref, transactionId),
);

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _Payload {
  final List<DocumentItem> items;
  final TxKind? txKind;
  final PropType? propType;
  const _Payload({this.items = const [], this.txKind, this.propType});
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

class TransactionDocumentPipelineWidget extends ConsumerStatefulWidget {
  final int transactionId;
  final String transactionType;

  const TransactionDocumentPipelineWidget({
    super.key,
    required this.transactionId,
    required this.transactionType,
  });

  @override
  ConsumerState<TransactionDocumentPipelineWidget> createState() =>
      _TransactionDocumentPipelineWidgetState();
}

class _TransactionDocumentPipelineWidgetState
    extends ConsumerState<TransactionDocumentPipelineWidget> {
  bool _addingItem = false;
  final _addController = TextEditingController();
  String? _editingItemId;
  final _editController = TextEditingController();

  int get _userId => ref.read(userProvider).value?.idInt ?? 0;

  @override
  void dispose() {
    _addController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final pipeline = ref.watch(documentPipelineProvider(widget.transactionId));

    if (pipeline.loading) return _buildShimmer(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme, pipeline),
        const SizedBox(height: 12),
        if (pipeline.items.isEmpty)
          _buildEmptyState(theme)
        else
          _buildList(theme, pipeline),
        const SizedBox(height: 8),
        _buildAddItemSection(theme),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeColors theme, DocumentPipelineState pipeline) {
    return Row(
      children: [
        Icon(Icons.checklist_rounded, size: 18, color: theme.themeColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'document_pipeline'.tr,
                style: AppTextStyles.interRegular14.copyWith(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (pipeline.activeTxKind != null && pipeline.activePropType != null)
                Text(
                  '${_txKindLabel(pipeline.activeTxKind!)} · ${_propTypeLabel(pipeline.activePropType!)}',
                  style: AppTextStyles.interRegular12.copyWith(
                    color: theme.textColor.withAlpha(130),
                  ),
                ),
            ],
          ),
        ),
        if (pipeline.items.isNotEmpty) ...[
          _buildProgress(theme, pipeline),
          const SizedBox(width: 8),
        ],
        if (pipeline.saving)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.themeColor),
          )
        else
          _buildTemplateButton(theme),
      ],
    );
  }

  Widget _buildProgress(ThemeColors theme, DocumentPipelineState pipeline) {
    final done = pipeline.done;
    final total = pipeline.total;
    final frac = total == 0 ? 0.0 : done / total;
    final allDone = done == total && total > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (allDone ? Colors.green : theme.themeColor).withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allDone)
            const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green)
          else
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                value: frac,
                strokeWidth: 2,
                backgroundColor: theme.bordercolor.withAlpha(60),
                valueColor: AlwaysStoppedAnimation(theme.themeColor),
              ),
            ),
          const SizedBox(width: 5),
          Text(
            '$done/$total',
            style: AppTextStyles.interRegular12.copyWith(
              color: allDone ? Colors.green : theme.themeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateButton(ThemeColors theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showTemplateSheet(theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.textFieldColor.withAlpha(120),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.bordercolor.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high_rounded, size: 13, color: theme.textColor.withAlpha(180)),
            const SizedBox(width: 4),
            Text(
              'apply_template'.tr,
              style: AppTextStyles.interRegular12.copyWith(
                color: theme.textColor.withAlpha(180),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSheet(ThemeColors theme) {
    final pipeline = ref.read(documentPipelineProvider(widget.transactionId));
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dashboardContainer,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TemplatePickerSheet(
        initialTxKind: pipeline.activeTxKind ?? _parseTxKind(widget.transactionType),
        initialPropType: pipeline.activePropType ?? PropType.apartment,
        onApply: (txKind, propType) {
          ref
              .read(documentPipelineProvider(widget.transactionId).notifier)
              .applyTemplate(txKind, propType, _userId);
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────

  Widget _buildEmptyState(ThemeColors theme) {
    return GestureDetector(
      onTap: () => _showTemplateSheet(theme),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.textFieldColor.withAlpha(70),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.themeColor.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.playlist_add_rounded, size: 32, color: theme.themeColor.withAlpha(160)),
            const SizedBox(height: 8),
            Text(
              'create_document_checklist'.tr,
              style: AppTextStyles.interRegular14.copyWith(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'create_document_checklist_desc'.tr,
              style: AppTextStyles.interRegular12.copyWith(
                color: theme.textColor.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────

  Widget _buildList(ThemeColors theme, DocumentPipelineState pipeline) {
    final required = pipeline.items.where((i) => i.required).toList();
    final optional = pipeline.items.where((i) => !i.required).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (required.isNotEmpty) ...[
          _sectionLabel(theme, 'required_documents'.tr),
          const SizedBox(height: 6),
          ...required.map((item) => _buildItemRow(theme, item)),
        ],
        if (optional.isNotEmpty) ...[
          if (required.isNotEmpty) const SizedBox(height: 10),
          _sectionLabel(theme, 'optional_documents'.tr),
          const SizedBox(height: 6),
          ...optional.map((item) => _buildItemRow(theme, item)),
        ],
      ],
    );
  }

  Widget _sectionLabel(ThemeColors theme, String label) {
    return Text(
      label,
      style: AppTextStyles.interRegular10.copyWith(
        color: theme.textColor.withAlpha(120),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildItemRow(ThemeColors theme, DocumentItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _editingItemId == item.id
          ? _buildEditRow(theme, item)
          : _buildCheckRow(theme, item),
    );
  }

  Widget _buildCheckRow(ThemeColors theme, DocumentItem item) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => ref
              .read(documentPipelineProvider(widget.transactionId).notifier)
              .toggleItem(item.id, _userId),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: item.completed ? theme.themeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: item.completed ? theme.themeColor : theme.bordercolor.withAlpha(120),
                width: 1.5,
              ),
            ),
            child: item.completed
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onLongPress: () => setState(() {
              _editingItemId = item.id;
              _editController.text = item.label;
            }),
            child: Text(
              item.label,
              style: AppTextStyles.interRegular12.copyWith(
                color: item.completed
                    ? theme.textColor.withAlpha(100)
                    : theme.textColor,
                decoration: item.completed ? TextDecoration.lineThrough : null,
                decorationColor: theme.textColor.withAlpha(100),
              ),
            ),
          ),
        ),
        if (!item.required)
          GestureDetector(
            onTap: () => ref
                .read(documentPipelineProvider(widget.transactionId).notifier)
                .removeItem(item.id, _userId),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.close_rounded, size: 14, color: theme.textColor.withAlpha(70)),
            ),
          ),
      ],
    );
  }

  Widget _buildEditRow(ThemeColors theme, DocumentItem item) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _editController,
            autofocus: true,
            style: AppTextStyles.interRegular12.copyWith(color: theme.textColor),
            decoration: _inlineDecoration(theme, 'document_name'.tr),
            onSubmitted: (_) => _submitEdit(item),
          ),
        ),
        const SizedBox(width: 4),
        _iconBtn(theme, Icons.check_rounded, theme.themeColor, () => _submitEdit(item)),
        _iconBtn(theme, Icons.close_rounded, theme.textColor.withAlpha(100),
            () => setState(() => _editingItemId = null)),
      ],
    );
  }

  void _submitEdit(DocumentItem item) {
    final label = _editController.text.trim();
    if (label.isNotEmpty) {
      ref
          .read(documentPipelineProvider(widget.transactionId).notifier)
          .renameItem(item.id, label, _userId);
    }
    setState(() => _editingItemId = null);
  }

  // ── Add item ──────────────────────────────────────────────────────────

  Widget _buildAddItemSection(ThemeColors theme) {
    if (_addingItem) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addController,
              autofocus: true,
              style: AppTextStyles.interRegular12.copyWith(color: theme.textColor),
              decoration: _inlineDecoration(theme, 'document_name'.tr),
              onSubmitted: (_) => _submitAdd(),
            ),
          ),
          const SizedBox(width: 4),
          _iconBtn(theme, Icons.check_rounded, theme.themeColor, _submitAdd),
          _iconBtn(theme, Icons.close_rounded, theme.textColor.withAlpha(100), () {
            setState(() => _addingItem = false);
            _addController.clear();
          }),
        ],
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _addingItem = true),
      child: Row(
        children: [
          Icon(Icons.add_rounded, size: 16, color: theme.themeColor.withAlpha(180)),
          const SizedBox(width: 6),
          Text(
            'add_document'.tr,
            style: AppTextStyles.interRegular12.copyWith(
              color: theme.themeColor.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _submitAdd() {
    final label = _addController.text.trim();
    if (label.isNotEmpty) {
      ref
          .read(documentPipelineProvider(widget.transactionId).notifier)
          .addCustomItem(label, _userId);
    }
    _addController.clear();
    setState(() => _addingItem = false);
  }

  // ── Shimmer ──────────────────────────────────────────────────────────

  Widget _buildShimmer(ThemeColors theme) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: theme.textFieldColor.withAlpha(70),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  InputDecoration _inlineDecoration(ThemeColors theme, String hint) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(8));
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.interRegular12.copyWith(color: theme.textColor.withAlpha(100)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: theme.textFieldColor.withAlpha(120),
      border: border,
      enabledBorder: border.copyWith(
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(70))),
      focusedBorder: border.copyWith(
          borderSide: BorderSide(color: theme.themeColor)),
    );
  }

  Widget _iconBtn(ThemeColors theme, IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}

// ---------------------------------------------------------------------------
// Label helpers
// ---------------------------------------------------------------------------

String _txKindLabel(TxKind k) {
  switch (k) {
    case TxKind.sell: return 'doc_template_sell'.tr;
    case TxKind.buy:  return 'doc_template_buy'.tr;
    case TxKind.rent: return 'doc_template_rent'.tr;
  }
}

String _propTypeLabel(PropType p) {
  switch (p) {
    case PropType.apartment:  return 'prop_apartment'.tr;
    case PropType.house:      return 'prop_house'.tr;
    case PropType.plot:       return 'prop_plot'.tr;
    case PropType.commercial: return 'prop_commercial'.tr;
    case PropType.garage:     return 'prop_garage'.tr;
  }
}

// ---------------------------------------------------------------------------
// Template picker — 2-step: TxKind × PropType
// ---------------------------------------------------------------------------

class _TemplatePickerSheet extends StatefulWidget {
  final TxKind initialTxKind;
  final PropType initialPropType;
  final void Function(TxKind, PropType) onApply;

  const _TemplatePickerSheet({
    required this.initialTxKind,
    required this.initialPropType,
    required this.onApply,
  });

  @override
  State<_TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends State<_TemplatePickerSheet> {
  late TxKind _txKind;
  late PropType _propType;

  @override
  void initState() {
    super.initState();
    _txKind = widget.initialTxKind;
    _propType = widget.initialPropType;
  }

  @override
  Widget build(BuildContext context) {
    final docs = _T.forCombo(_txKind, _propType);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'choose_template'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'choose_template_desc'.tr,
              style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13),
            ),

            const SizedBox(height: 20),

            // ── Transaction type ──────────────────────────────────────
            _sectionTitle('transaction_type_label'.tr),
            const SizedBox(height: 8),
            _segmentRow(
              items: [
                (TxKind.sell, 'doc_template_sell'.tr, Icons.home_work_rounded),
                (TxKind.buy,  'doc_template_buy'.tr,  Icons.shopping_bag_rounded),
                (TxKind.rent, 'doc_template_rent'.tr, Icons.key_rounded),
              ],
              selected: _txKind,
              onTap: (v) => setState(() => _txKind = v),
            ),

            const SizedBox(height: 20),

            // ── Property type ─────────────────────────────────────────
            _sectionTitle('property_type_label'.tr),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _propChip(PropType.apartment, Icons.apartment_rounded),
                _propChip(PropType.house,     Icons.house_rounded),
                _propChip(PropType.plot,      Icons.landscape_rounded),
                _propChip(PropType.commercial,Icons.storefront_rounded),
                _propChip(PropType.garage,    Icons.garage_rounded),
              ],
            ),

            const SizedBox(height: 24),

            // ── Preview of document count ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.white.withAlpha(120)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${docs.length} ${'documents_count'.tr} · '
                      '${docs.where((d) => d.required).length} ${'required_lower'.tr}',
                      style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Apply button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_txKind, _propType);
                },
                icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                label: Text('apply_template'.tr),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withAlpha(160),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _segmentRow<T>({
    required List<(T, String, IconData)> items,
    required T selected,
    required void Function(T) onTap,
  }) {
    return Row(
      children: items.map((item) {
        final (value, label, icon) = item;
        final isSelected = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(value),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF).withAlpha(200)
                    : Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withAlpha(25),
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 20, color: Colors.white.withAlpha(isSelected ? 255 : 150)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withAlpha(isSelected ? 255 : 160),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _propChip(PropType prop, IconData icon) {
    final isSelected = _propType == prop;
    return GestureDetector(
      onTap: () => setState(() => _propType = prop),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withAlpha(200)
              : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : Colors.white.withAlpha(25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white.withAlpha(isSelected ? 255 : 160)),
            const SizedBox(width: 6),
            Text(
              _propTypeLabel(prop),
              style: TextStyle(
                color: Colors.white.withAlpha(isSelected ? 255 : 160),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
