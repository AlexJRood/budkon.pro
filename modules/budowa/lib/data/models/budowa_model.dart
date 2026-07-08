enum StatusBudowy { oferta, umowa, wToku, zakonczona, anulowana }

extension StatusBudowyExt on StatusBudowy {
  String get apiValue => switch (this) {
        StatusBudowy.oferta => 'oferta',
        StatusBudowy.umowa => 'umowa',
        StatusBudowy.wToku => 'w_toku',
        StatusBudowy.zakonczona => 'zakonczona',
        StatusBudowy.anulowana => 'anulowana',
      };

  String get label => switch (this) {
        StatusBudowy.oferta => 'Oferta',
        StatusBudowy.umowa => 'Umowa podpisana',
        StatusBudowy.wToku => 'W toku',
        StatusBudowy.zakonczona => 'Zakończona',
        StatusBudowy.anulowana => 'Anulowana',
      };

  static StatusBudowy fromApi(String v) => switch (v) {
        'umowa' => StatusBudowy.umowa,
        'w_toku' => StatusBudowy.wToku,
        'zakonczona' => StatusBudowy.zakonczona,
        'anulowana' => StatusBudowy.anulowana,
        _ => StatusBudowy.oferta,
      };
}

enum StatusEtapu { planowany, wToku, zakończony }

extension StatusEtapuExt on StatusEtapu {
  String get apiValue => switch (this) {
        StatusEtapu.planowany => 'planowany',
        StatusEtapu.wToku => 'w_toku',
        StatusEtapu.zakończony => 'zakończony',
      };

  String get label => switch (this) {
        StatusEtapu.planowany => 'Planowany',
        StatusEtapu.wToku => 'W toku',
        StatusEtapu.zakończony => 'Zakończony',
      };

  static StatusEtapu fromApi(String v) => switch (v) {
        'w_toku' => StatusEtapu.wToku,
        'zakończony' => StatusEtapu.zakończony,
        _ => StatusEtapu.planowany,
      };
}

class EtapBudowyModel {
  final int id;
  final int budowaId;
  final String nazwa;
  final String typ;
  final int kolejnosc;
  final StatusEtapu status;
  final DateTime? dataStart;
  final DateTime? dataKoniec;
  final double budzetEtapu;
  final int? kosztorysId;

  const EtapBudowyModel({
    required this.id,
    required this.budowaId,
    required this.nazwa,
    this.typ = '',
    this.kolejnosc = 0,
    this.status = StatusEtapu.planowany,
    this.dataStart,
    this.dataKoniec,
    this.budzetEtapu = 0,
    this.kosztorysId,
  });

  factory EtapBudowyModel.fromJson(Map<String, dynamic> j) => EtapBudowyModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        nazwa: j['nazwa'] ?? '',
        typ: j['typ'] ?? '',
        kolejnosc: j['kolejnosc'] ?? 0,
        status: StatusEtapuExt.fromApi(j['status'] ?? ''),
        dataStart: j['data_start'] != null ? DateTime.tryParse(j['data_start']) : null,
        dataKoniec: j['data_koniec'] != null ? DateTime.tryParse(j['data_koniec']) : null,
        budzetEtapu: double.tryParse(j['budzet_etapu']?.toString() ?? '0') ?? 0,
        kosztorysId: j['kosztorys_id'],
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'nazwa': nazwa,
        'typ': typ,
        'kolejnosc': kolejnosc,
        'status': status.apiValue,
        if (dataStart != null) 'data_start': dataStart!.toIso8601String().split('T').first,
        if (dataKoniec != null) 'data_koniec': dataKoniec!.toIso8601String().split('T').first,
        'budzet_etapu': budzetEtapu,
      };

  EtapBudowyModel copyWith({StatusEtapu? status, DateTime? dataKoniec}) =>
      EtapBudowyModel(
        id: id, budowaId: budowaId, nazwa: nazwa, typ: typ, kolejnosc: kolejnosc,
        status: status ?? this.status,
        dataStart: dataStart,
        dataKoniec: dataKoniec ?? this.dataKoniec,
        budzetEtapu: budzetEtapu,
        kosztorysId: kosztorysId,
      );
}

class BudowaModel {
  final int id;
  final String nazwa;
  final String adres;
  final StatusBudowy status;
  final DateTime? dataRozpoczecia;
  final DateTime? dataPlanowanegZakonczenia;
  final double budzet;
  final List<EtapBudowyModel> etapy;
  final int etapyCount;
  final int postep; // 0–100

  const BudowaModel({
    required this.id,
    required this.nazwa,
    this.adres = '',
    this.status = StatusBudowy.oferta,
    this.dataRozpoczecia,
    this.dataPlanowanegZakonczenia,
    this.budzet = 0,
    this.etapy = const [],
    this.etapyCount = 0,
    this.postep = 0,
  });

  factory BudowaModel.fromJson(Map<String, dynamic> j) => BudowaModel(
        id: j['id'] ?? 0,
        nazwa: j['nazwa'] ?? '',
        adres: j['adres'] ?? '',
        status: StatusBudowyExt.fromApi(j['status'] ?? ''),
        dataRozpoczecia:
            j['data_rozpoczecia'] != null ? DateTime.tryParse(j['data_rozpoczecia']) : null,
        dataPlanowanegZakonczenia: j['data_planowanego_zakonczenia'] != null
            ? DateTime.tryParse(j['data_planowanego_zakonczenia'])
            : null,
        budzet: double.tryParse(j['budzet']?.toString() ?? '0') ?? 0,
        etapy: (j['etapy'] as List<dynamic>? ?? [])
            .map((e) => EtapBudowyModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        etapyCount: j['etapy_count'] ?? 0,
        postep: j['postep'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'nazwa': nazwa,
        'adres': adres,
        'status': status.apiValue,
        'budzet': budzet,
        if (dataRozpoczecia != null)
          'data_rozpoczecia': dataRozpoczecia!.toIso8601String().split('T').first,
        if (dataPlanowanegZakonczenia != null)
          'data_planowanego_zakonczenia':
              dataPlanowanegZakonczenia!.toIso8601String().split('T').first,
      };
}
