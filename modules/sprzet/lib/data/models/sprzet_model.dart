import 'package:intl/intl.dart';

enum KategoriaSprzetu { maszyny, elektronarzedzia, rusztowania, pomiarowe, pojazdy, inne }

extension KategoriaSprzetaExt on KategoriaSprzetu {
  String get apiValue => name;
  String get label => switch (this) {
        KategoriaSprzetu.maszyny => 'Maszyny budowlane',
        KategoriaSprzetu.elektronarzedzia => 'Elektronarzędzia',
        KategoriaSprzetu.rusztowania => 'Rusztowania',
        KategoriaSprzetu.pomiarowe => 'Sprzęt pomiarowy',
        KategoriaSprzetu.pojazdy => 'Pojazdy',
        KategoriaSprzetu.inne => 'Inne',
      };
  String get emoji => switch (this) {
        KategoriaSprzetu.maszyny => '🏗️',
        KategoriaSprzetu.elektronarzedzia => '🔧',
        KategoriaSprzetu.rusztowania => '🪜',
        KategoriaSprzetu.pomiarowe => '📐',
        KategoriaSprzetu.pojazdy => '🚛',
        KategoriaSprzetu.inne => '🔩',
      };
  static KategoriaSprzetu fromApi(String v) =>
      KategoriaSprzetu.values.firstWhere((e) => e.name == v,
          orElse: () => KategoriaSprzetu.inne);
}

enum StatusSprzetu { dostepny, uzyciu, serwis, nieaktywny }

extension StatusSprzetaExt on StatusSprzetu {
  String get apiValue => name;
  String get label => switch (this) {
        StatusSprzetu.dostepny => 'Dostępny',
        StatusSprzetu.uzyciu => 'W użyciu',
        StatusSprzetu.serwis => 'Serwis',
        StatusSprzetu.nieaktywny => 'Nieaktywny',
      };
  static StatusSprzetu fromApi(String v) =>
      StatusSprzetu.values.firstWhere((e) => e.name == v,
          orElse: () => StatusSprzetu.dostepny);
}

// ---- Sprzęt ----

class SprzetModel {
  final int id;
  final String nazwa;
  final KategoriaSprzetu kategoria;
  final StatusSprzetu status;
  final String? nrSeryjny;
  final String? nrRejestracyjny;
  final DateTime? dataPrzegladu;
  final DateTime? dataKoncaPrzegladu;
  final String? lokalizacja;
  final int? budowaId;
  final String uwagi;

  const SprzetModel({
    required this.id,
    required this.nazwa,
    this.kategoria = KategoriaSprzetu.inne,
    this.status = StatusSprzetu.dostepny,
    this.nrSeryjny,
    this.nrRejestracyjny,
    this.dataPrzegladu,
    this.dataKoncaPrzegladu,
    this.lokalizacja,
    this.budowaId,
    this.uwagi = '',
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory SprzetModel.fromJson(Map<String, dynamic> j) => SprzetModel(
        id: j['id'] ?? 0,
        nazwa: j['nazwa'] ?? '',
        kategoria: KategoriaSprzetaExt.fromApi(j['kategoria'] ?? ''),
        status: StatusSprzetaExt.fromApi(j['status'] ?? ''),
        nrSeryjny: j['nr_seryjny'],
        nrRejestracyjny: j['nr_rejestracyjny'],
        dataPrzegladu: j['data_przegladu'] != null
            ? DateTime.tryParse(j['data_przegladu'])
            : null,
        dataKoncaPrzegladu: j['data_konca_przegladu'] != null
            ? DateTime.tryParse(j['data_konca_przegladu'])
            : null,
        lokalizacja: j['lokalizacja'],
        budowaId: j['budowa'],
        uwagi: j['uwagi'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nazwa': nazwa,
        'kategoria': kategoria.apiValue,
        'status': status.apiValue,
        if (nrSeryjny != null) 'nr_seryjny': nrSeryjny,
        if (nrRejestracyjny != null) 'nr_rejestracyjny': nrRejestracyjny,
        if (dataPrzegladu != null) 'data_przegladu': dataPrzegladu!.toIso8601String(),
        if (dataKoncaPrzegladu != null)
          'data_konca_przegladu': dataKoncaPrzegladu!.toIso8601String(),
        if (lokalizacja != null) 'lokalizacja': lokalizacja,
        if (budowaId != null) 'budowa': budowaId,
        'uwagi': uwagi,
      };

  bool get przegladWygasa {
    if (dataKoncaPrzegladu == null) return false;
    return dataKoncaPrzegladu!.difference(DateTime.now()).inDays <= 30;
  }

  bool get przegladWygasl {
    if (dataKoncaPrzegladu == null) return false;
    return dataKoncaPrzegladu!.isBefore(DateTime.now());
  }

  String? get dataKoncaFmt =>
      dataKoncaPrzegladu != null ? _fmt.format(dataKoncaPrzegladu!) : null;
}

// ---- Wypożyczenie sprzętu ----

class WypozyczenieModel {
  final int id;
  final int sprzetId;
  final String sprzetNazwa;
  final int budowaId;
  final String budowaNazwa;
  final DateTime dataOd;
  final DateTime? dataDo;
  final String pracownik;
  final String uwagi;

  const WypozyczenieModel({
    required this.id,
    required this.sprzetId,
    required this.sprzetNazwa,
    required this.budowaId,
    required this.budowaNazwa,
    required this.dataOd,
    this.dataDo,
    required this.pracownik,
    this.uwagi = '',
  });

  static final _fmt = DateFormat('dd.MM.yy');

  factory WypozyczenieModel.fromJson(Map<String, dynamic> j) =>
      WypozyczenieModel(
        id: j['id'] ?? 0,
        sprzetId: j['sprzet'] ?? 0,
        sprzetNazwa: j['sprzet_nazwa'] ?? '',
        budowaId: j['budowa'] ?? 0,
        budowaNazwa: j['budowa_nazwa'] ?? '',
        dataOd: DateTime.tryParse(j['data_od'] ?? '') ?? DateTime.now(),
        dataDo: j['data_do'] != null ? DateTime.tryParse(j['data_do']) : null,
        pracownik: j['pracownik'] ?? '',
        uwagi: j['uwagi'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'sprzet': sprzetId,
        'budowa': budowaId,
        'data_od': dataOd.toIso8601String(),
        if (dataDo != null) 'data_do': dataDo!.toIso8601String(),
        'pracownik': pracownik,
        'uwagi': uwagi,
      };

  bool get aktywne => dataDo == null;
  String get dataOdFmt => _fmt.format(dataOd);
  String? get dataDoFmt => dataDo != null ? _fmt.format(dataDo!) : null;
}
