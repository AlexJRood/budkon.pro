enum StatusZadania {
  planowane,
  w_toku,
  zakonczone,
  wstrzymane;

  static StatusZadania fromApi(String v) =>
      StatusZadania.values.firstWhere((e) => e.name == v,
          orElse: () => planowane);

  String get label => switch (this) {
        planowane => 'Planowane',
        w_toku => 'W toku',
        zakonczone => 'Zakończone',
        wstrzymane => 'Wstrzymane',
      };
}

class ZadanieModel {
  final int id;
  final int? etapId;
  final String? etapNazwa;
  final String nazwa;
  final String opis;
  final int kolejnosc;
  final StatusZadania status;
  final DateTime? dataStart;
  final DateTime? dataKoniec;
  final int? czasTrwaniaDni;
  final int postepProcent;
  final double budzet;
  final int? kosztorysId;
  final List<int> assignedIds;
  final List<int> poprzednicyIds;
  final int? opoznienieDni;

  const ZadanieModel({
    required this.id,
    this.etapId,
    this.etapNazwa,
    required this.nazwa,
    required this.opis,
    required this.kolejnosc,
    required this.status,
    this.dataStart,
    this.dataKoniec,
    this.czasTrwaniaDni,
    required this.postepProcent,
    required this.budzet,
    this.kosztorysId,
    required this.assignedIds,
    required this.poprzednicyIds,
    this.opoznienieDni,
  });

  factory ZadanieModel.fromJson(Map<String, dynamic> j) => ZadanieModel(
        id: j['id'] as int,
        etapId: j['etap'] as int?,
        etapNazwa: j['etap_nazwa'] as String?,
        nazwa: j['nazwa'] as String? ?? '',
        opis: j['opis'] as String? ?? '',
        kolejnosc: j['kolejnosc'] as int? ?? 0,
        status: StatusZadania.fromApi(j['status'] as String? ?? 'planowane'),
        dataStart: j['data_start'] != null
            ? DateTime.tryParse(j['data_start'] as String)
            : null,
        dataKoniec: j['data_koniec'] != null
            ? DateTime.tryParse(j['data_koniec'] as String)
            : null,
        czasTrwaniaDni: j['czas_trwania_dni'] as int?,
        postepProcent: j['postep_procent'] as int? ?? 0,
        budzet: (j['budzet'] as num?)?.toDouble() ?? 0,
        kosztorysId: j['kosztorys_id'] as int?,
        assignedIds:
            (j['assigned_ids'] as List? ?? []).map((e) => e as int).toList(),
        poprzednicyIds: (j['poprzednicy_ids'] as List? ?? [])
            .map((e) => e as int)
            .toList(),
        opoznienieDni: j['opoznienie_dni'] as int?,
      );

  bool get isOpóźnione => opoznienieDni != null && opoznienieDni! > 0;
  int get durationDni =>
      czasTrwaniaDni ??
      (dataStart != null && dataKoniec != null
          ? dataKoniec!.difference(dataStart!).inDays
          : 1);
}

class MilestoneModel {
  final int id;
  final int? etapId;
  final String? etapNazwa;
  final String nazwa;
  final DateTime data;
  final bool osiagniety;
  final String kolor;

  const MilestoneModel({
    required this.id,
    this.etapId,
    this.etapNazwa,
    required this.nazwa,
    required this.data,
    required this.osiagniety,
    required this.kolor,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> j) => MilestoneModel(
        id: j['id'] as int,
        etapId: j['etap'] as int?,
        etapNazwa: j['etap_nazwa'] as String?,
        nazwa: j['nazwa'] as String? ?? '',
        data: DateTime.parse(j['data'] as String),
        osiagniety: j['osiagniety'] as bool? ?? false,
        kolor: j['kolor'] as String? ?? '#FF9800',
      );
}

class EtapTimeline {
  final int id;
  final String nazwa;
  final String typ;
  final int kolejnosc;
  final String status;
  final DateTime? dataStart;
  final DateTime? dataKoniec;
  final double budzetEtapu;
  final List<ZadanieModel> zadania;
  final int postepEtapu;

  const EtapTimeline({
    required this.id,
    required this.nazwa,
    required this.typ,
    required this.kolejnosc,
    required this.status,
    this.dataStart,
    this.dataKoniec,
    required this.budzetEtapu,
    required this.zadania,
    required this.postepEtapu,
  });

  factory EtapTimeline.fromJson(Map<String, dynamic> j) => EtapTimeline(
        id: j['id'] as int,
        nazwa: j['nazwa'] as String? ?? '',
        typ: j['typ'] as String? ?? '',
        kolejnosc: j['kolejnosc'] as int? ?? 0,
        status: j['status'] as String? ?? 'planowany',
        dataStart: j['data_start'] != null
            ? DateTime.tryParse(j['data_start'] as String)
            : null,
        dataKoniec: j['data_koniec'] != null
            ? DateTime.tryParse(j['data_koniec'] as String)
            : null,
        budzetEtapu: (j['budzet_etapu'] as num?)?.toDouble() ?? 0,
        zadania: (j['zadania'] as List? ?? [])
            .map((e) => ZadanieModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        postepEtapu: j['postep_etapu'] as int? ?? 0,
      );
}

class TimelineData {
  final int budowaId;
  final String budowaNazwa;
  final DateTime? dataStart;
  final DateTime? dataKoniec;
  final List<EtapTimeline> etapy;
  final List<MilestoneModel> milestones;

  const TimelineData({
    required this.budowaId,
    required this.budowaNazwa,
    this.dataStart,
    this.dataKoniec,
    required this.etapy,
    required this.milestones,
  });

  factory TimelineData.fromJson(Map<String, dynamic> j) => TimelineData(
        budowaId: j['budowa_id'] as int,
        budowaNazwa: j['budowa_nazwa'] as String? ?? '',
        dataStart: j['data_start'] != null
            ? DateTime.tryParse(j['data_start'] as String)
            : null,
        dataKoniec: j['data_koniec'] != null
            ? DateTime.tryParse(j['data_koniec'] as String)
            : null,
        etapy: (j['etapy'] as List? ?? [])
            .map((e) => EtapTimeline.fromJson(e as Map<String, dynamic>))
            .toList(),
        milestones: (j['milestones'] as List? ?? [])
            .map((e) => MilestoneModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  DateTime get effectiveStart =>
      dataStart ??
      etapy
          .expand((e) => [e.dataStart])
          .whereType<DateTime>()
          .fold(DateTime.now(), (a, b) => a.isBefore(b) ? a : b);

  DateTime get effectiveEnd =>
      dataKoniec ??
      etapy
          .expand((e) => [e.dataKoniec])
          .whereType<DateTime>()
          .fold(
              DateTime.now().add(const Duration(days: 90)),
              (a, b) => a.isAfter(b) ? a : b);
}
