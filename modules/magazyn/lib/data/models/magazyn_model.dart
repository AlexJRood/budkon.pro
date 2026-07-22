import 'package:intl/intl.dart';

enum KategoriaMaterialu {
  beton, stal, drewno, izolacja, elektryka, hydraulika, wykonczenie, inne
}

extension KategoriaMaterialuExt on KategoriaMaterialu {
  String get apiValue => name;
  String get label => switch (this) {
        KategoriaMaterialu.beton => 'Beton i kruszywa',
        KategoriaMaterialu.stal => 'Stal i zbrojenie',
        KategoriaMaterialu.drewno => 'Drewno',
        KategoriaMaterialu.izolacja => 'Izolacja',
        KategoriaMaterialu.elektryka => 'Elektryka',
        KategoriaMaterialu.hydraulika => 'Hydraulika',
        KategoriaMaterialu.wykonczenie => 'Wykończenie',
        KategoriaMaterialu.inne => 'Inne',
      };
  String get emoji => switch (this) {
        KategoriaMaterialu.beton => '🪨',
        KategoriaMaterialu.stal => '⚙️',
        KategoriaMaterialu.drewno => '🪵',
        KategoriaMaterialu.izolacja => '🧱',
        KategoriaMaterialu.elektryka => '⚡',
        KategoriaMaterialu.hydraulika => '💧',
        KategoriaMaterialu.wykonczenie => '🎨',
        KategoriaMaterialu.inne => '📦',
      };
  static KategoriaMaterialu fromApi(String v) =>
      KategoriaMaterialu.values.firstWhere((e) => e.name == v,
          orElse: () => KategoriaMaterialu.inne);
}

enum TypRuchu { dostawa, zuzycie, zwrot, korekta }

extension TypRuchuExt on TypRuchu {
  String get apiValue => name;
  String get label => switch (this) {
        TypRuchu.dostawa => 'Dostawa',
        TypRuchu.zuzycie => 'Zużycie',
        TypRuchu.zwrot => 'Zwrot',
        TypRuchu.korekta => 'Korekta',
      };
  bool get isIn => this == TypRuchu.dostawa || this == TypRuchu.zwrot;
  static TypRuchu fromApi(String v) =>
      TypRuchu.values.firstWhere((e) => e.name == v, orElse: () => TypRuchu.dostawa);
}

// ---- Pozycja magazynowa ----

class MagazynPozycjaModel {
  final int id;
  final int budowaId;
  final String nazwa;
  final String jednostka;
  final KategoriaMaterialu kategoria;
  final double stanAktualny;
  final double stanMinimalny;
  final double zamowione;
  final double cenaJednostkowa;
  final String? dostawca;
  final String? kodKatalogowy;

  const MagazynPozycjaModel({
    required this.id,
    required this.budowaId,
    required this.nazwa,
    required this.jednostka,
    this.kategoria = KategoriaMaterialu.inne,
    this.stanAktualny = 0,
    this.stanMinimalny = 0,
    this.zamowione = 0,
    this.cenaJednostkowa = 0,
    this.dostawca,
    this.kodKatalogowy,
  });

  factory MagazynPozycjaModel.fromJson(Map<String, dynamic> j) =>
      MagazynPozycjaModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        nazwa: j['nazwa'] ?? '',
        jednostka: j['jednostka'] ?? 'szt',
        kategoria: KategoriaMaterialuExt.fromApi(j['kategoria'] ?? ''),
        stanAktualny: double.tryParse(j['stan_aktualny']?.toString() ?? '0') ?? 0,
        stanMinimalny: double.tryParse(j['stan_minimalny']?.toString() ?? '0') ?? 0,
        zamowione: double.tryParse(j['zamowione']?.toString() ?? '0') ?? 0,
        cenaJednostkowa: double.tryParse(j['cena_jednostkowa']?.toString() ?? '0') ?? 0,
        dostawca: j['dostawca'],
        kodKatalogowy: j['kod_katalogowy'],
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'nazwa': nazwa,
        'jednostka': jednostka,
        'kategoria': kategoria.apiValue,
        'stan_minimalny': stanMinimalny,
        'cena_jednostkowa': cenaJednostkowa,
        if (dostawca != null) 'dostawca': dostawca,
        if (kodKatalogowy != null) 'kod_katalogowy': kodKatalogowy,
      };

  bool get niski => stanAktualny <= stanMinimalny && stanMinimalny > 0;
  bool get pusty => stanAktualny <= 0;
  double get wartoscCalkowita => stanAktualny * cenaJednostkowa;
}

// ---- Ruch magazynowy ----

class MagazynRuchModel {
  final int id;
  final int pozycjaId;
  final String pozycjaNazwa;
  final TypRuchu typ;
  final double ilosc;
  final DateTime data;
  final String? uwaga;
  final String wykonalKto;

  const MagazynRuchModel({
    required this.id,
    required this.pozycjaId,
    required this.pozycjaNazwa,
    required this.typ,
    required this.ilosc,
    required this.data,
    this.uwaga,
    this.wykonalKto = '',
  });

  static final _fmt = DateFormat('dd.MM.yy HH:mm');

  factory MagazynRuchModel.fromJson(Map<String, dynamic> j) => MagazynRuchModel(
        id: j['id'] ?? 0,
        pozycjaId: j['pozycja'] ?? 0,
        pozycjaNazwa: j['pozycja_nazwa'] ?? '',
        typ: TypRuchuExt.fromApi(j['typ'] ?? ''),
        ilosc: double.tryParse(j['ilosc']?.toString() ?? '0') ?? 0,
        data: j['data'] != null
            ? DateTime.tryParse(j['data']) ?? DateTime.now()
            : DateTime.now(),
        uwaga: j['uwaga'],
        wykonalKto: j['wykonal_kto'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'pozycja': pozycjaId,
        'typ': typ.apiValue,
        'ilosc': ilosc,
        'data': data.toIso8601String(),
        if (uwaga != null) 'uwaga': uwaga,
      };

  String get dataFmt => _fmt.format(data);
  double get iloscZnakowana => typ.isIn ? ilosc : -ilosc;
}
