import 'package:intl/intl.dart';

enum StatusGwarancji { aktywna, wygasajaca, wygasla, zarchiwizowana }

extension StatusGwarancjiExt on StatusGwarancji {
  String get apiValue => name;
  String get label => switch (this) {
        StatusGwarancji.aktywna => 'Aktywna',
        StatusGwarancji.wygasajaca => 'Wygasająca',
        StatusGwarancji.wygasla => 'Wygasła',
        StatusGwarancji.zarchiwizowana => 'Zarchiwizowana',
      };
  static StatusGwarancji fromApi(String v) => StatusGwarancji.values
      .firstWhere((e) => e.name == v, orElse: () => StatusGwarancji.aktywna);
}

enum StatusZgloszenia { nowe, wTrakcie, zrealizowane, odrzucone }

extension StatusZgloszeniaExt on StatusZgloszenia {
  String get apiValue => name;
  String get label => switch (this) {
        StatusZgloszenia.nowe => 'Nowe',
        StatusZgloszenia.wTrakcie => 'W trakcie',
        StatusZgloszenia.zrealizowane => 'Zrealizowane',
        StatusZgloszenia.odrzucone => 'Odrzucone',
      };
  static StatusZgloszenia fromApi(String v) => StatusZgloszenia.values
      .firstWhere((e) => e.name == v, orElse: () => StatusZgloszenia.nowe);
}

// ---- Gwarancja ----

class GwarancjaModel {
  final int id;
  final int budowaId;
  final String tytul;
  final String? zakres;
  final String wykonawca;
  final DateTime dataOdbioru;
  final DateTime dataKoncaGwarancji;
  final int? miesiaceSerwisu;
  final String kontaktSerwisowy;

  const GwarancjaModel({
    required this.id,
    required this.budowaId,
    required this.tytul,
    this.zakres,
    required this.wykonawca,
    required this.dataOdbioru,
    required this.dataKoncaGwarancji,
    this.miesiaceSerwisu,
    this.kontaktSerwisowy = '',
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory GwarancjaModel.fromJson(Map<String, dynamic> j) => GwarancjaModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        tytul: j['tytul'] ?? '',
        zakres: j['zakres'],
        wykonawca: j['wykonawca'] ?? '',
        dataOdbioru: DateTime.tryParse(j['data_odbioru'] ?? '') ?? DateTime.now(),
        dataKoncaGwarancji:
            DateTime.tryParse(j['data_konca_gwarancji'] ?? '') ?? DateTime.now(),
        miesiaceSerwisu: j['miesiace_serwisu'],
        kontaktSerwisowy: j['kontakt_serwisowy'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'tytul': tytul,
        if (zakres != null) 'zakres': zakres,
        'wykonawca': wykonawca,
        'data_odbioru': dataOdbioru.toIso8601String(),
        'data_konca_gwarancji': dataKoncaGwarancji.toIso8601String(),
        if (miesiaceSerwisu != null) 'miesiace_serwisu': miesiaceSerwisu,
        'kontakt_serwisowy': kontaktSerwisowy,
      };

  int get dniDoKonca => dataKoncaGwarancji.difference(DateTime.now()).inDays;
  bool get wygasajaca => dniDoKonca > 0 && dniDoKonca <= 60;
  bool get wygasla => dataKoncaGwarancji.isBefore(DateTime.now());

  StatusGwarancji get status {
    if (wygasla) return StatusGwarancji.wygasla;
    if (wygasajaca) return StatusGwarancji.wygasajaca;
    return StatusGwarancji.aktywna;
  }

  String get dataOdbioruFmt => _fmt.format(dataOdbioru);
  String get dataKoncaFmt => _fmt.format(dataKoncaGwarancji);
}

// ---- Zgłoszenie serwisowe ----

class ZgloszenieSerwisowModel {
  final int id;
  final int gwarancjaId;
  final String gwarancjaTytul;
  final String opis;
  final String zglaszajacy;
  final DateTime dataZgloszenia;
  final DateTime? dataRealizacji;
  final StatusZgloszenia status;
  final String? odpowiedz;

  const ZgloszenieSerwisowModel({
    required this.id,
    required this.gwarancjaId,
    required this.gwarancjaTytul,
    required this.opis,
    required this.zglaszajacy,
    required this.dataZgloszenia,
    this.dataRealizacji,
    this.status = StatusZgloszenia.nowe,
    this.odpowiedz,
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory ZgloszenieSerwisowModel.fromJson(Map<String, dynamic> j) =>
      ZgloszenieSerwisowModel(
        id: j['id'] ?? 0,
        gwarancjaId: j['gwarancja'] ?? 0,
        gwarancjaTytul: j['gwarancja_tytul'] ?? '',
        opis: j['opis'] ?? '',
        zglaszajacy: j['zglaszajacy'] ?? '',
        dataZgloszenia: DateTime.tryParse(j['data_zgloszenia'] ?? '') ?? DateTime.now(),
        dataRealizacji: j['data_realizacji'] != null
            ? DateTime.tryParse(j['data_realizacji'])
            : null,
        status: StatusZgloszeniaExt.fromApi(j['status'] ?? ''),
        odpowiedz: j['odpowiedz'],
      );

  Map<String, dynamic> toJson() => {
        'gwarancja': gwarancjaId,
        'opis': opis,
        'zglaszajacy': zglaszajacy,
        'data_zgloszenia': dataZgloszenia.toIso8601String(),
      };

  String get dataZgloszenia2Fmt => _fmt.format(dataZgloszenia);
}
