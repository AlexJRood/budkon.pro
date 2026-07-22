import 'package:intl/intl.dart';

enum TypSzkolenia { wstepne, stanowiskowe, okresowe, specjalistyczne, pierwszaPomoc }

extension TypSzkoleniaExt on TypSzkolenia {
  String get apiValue => name;
  String get label => switch (this) {
        TypSzkolenia.wstepne => 'Wstępne',
        TypSzkolenia.stanowiskowe => 'Stanowiskowe',
        TypSzkolenia.okresowe => 'Okresowe',
        TypSzkolenia.specjalistyczne => 'Specjalistyczne',
        TypSzkolenia.pierwszaPomoc => 'Pierwsza pomoc',
      };
  static TypSzkolenia fromApi(String v) => TypSzkolenia.values
      .firstWhere((e) => e.name == v, orElse: () => TypSzkolenia.wstepne);
}

enum StatusWypadku { zgloszony, wTrakcie, zamkniety, skierowany }

extension StatusWypadkuExt on StatusWypadku {
  String get apiValue => name;
  String get label => switch (this) {
        StatusWypadku.zgloszony => 'Zgłoszony',
        StatusWypadku.wTrakcie => 'W trakcie',
        StatusWypadku.zamkniety => 'Zamknięty',
        StatusWypadku.skierowany => 'Skierowany do PIP',
      };
  static StatusWypadku fromApi(String v) => StatusWypadku.values
      .firstWhere((e) => e.name == v, orElse: () => StatusWypadku.zgloszony);
}

// ---- Szkolenie BHP pracownika ----

class SzkolenieBhpModel {
  final int id;
  final int pracownikId;
  final String pracownikImie;
  final TypSzkolenia typ;
  final DateTime dataSzkolenia;
  final DateTime dataWaznosci;
  final String? certyfikatUrl;

  const SzkolenieBhpModel({
    required this.id,
    required this.pracownikId,
    required this.pracownikImie,
    required this.typ,
    required this.dataSzkolenia,
    required this.dataWaznosci,
    this.certyfikatUrl,
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory SzkolenieBhpModel.fromJson(Map<String, dynamic> j) => SzkolenieBhpModel(
        id: j['id'] ?? 0,
        pracownikId: j['pracownik'] ?? 0,
        pracownikImie: j['pracownik_imie'] ?? '',
        typ: TypSzkoleniaExt.fromApi(j['typ'] ?? ''),
        dataSzkolenia: DateTime.tryParse(j['data_szkolenia'] ?? '') ?? DateTime.now(),
        dataWaznosci: DateTime.tryParse(j['data_waznosci'] ?? '') ?? DateTime.now(),
        certyfikatUrl: j['certyfikat_url'],
      );

  Map<String, dynamic> toJson() => {
        'pracownik': pracownikId,
        'typ': typ.apiValue,
        'data_szkolenia': dataSzkolenia.toIso8601String(),
        'data_waznosci': dataWaznosci.toIso8601String(),
      };

  bool get wygasa => dataWaznosci.difference(DateTime.now()).inDays <= 30;
  bool get wygaslo => dataWaznosci.isBefore(DateTime.now());

  String get dataSzkoleniaFmt => _fmt.format(dataSzkolenia);
  String get dataWaznosciFmt => _fmt.format(dataWaznosci);
}

// ---- Wypadek na budowie ----

class WypadekModel {
  final int id;
  final int budowaId;
  final String opis;
  final DateTime dataZdarzenia;
  final String? poszkodowany;
  final String? miejsceZdarzenia;
  final StatusWypadku status;
  final bool wezwanoSluzby;
  final String uwagi;

  const WypadekModel({
    required this.id,
    required this.budowaId,
    required this.opis,
    required this.dataZdarzenia,
    this.poszkodowany,
    this.miejsceZdarzenia,
    this.status = StatusWypadku.zgloszony,
    this.wezwanoSluzby = false,
    this.uwagi = '',
  });

  static final _fmt = DateFormat('dd.MM.yyyy HH:mm');

  factory WypadekModel.fromJson(Map<String, dynamic> j) => WypadekModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        opis: j['opis'] ?? '',
        dataZdarzenia: DateTime.tryParse(j['data_zdarzenia'] ?? '') ?? DateTime.now(),
        poszkodowany: j['poszkodowany'],
        miejsceZdarzenia: j['miejsce_zdarzenia'],
        status: StatusWypadkuExt.fromApi(j['status'] ?? ''),
        wezwanoSluzby: j['wezwano_sluzby'] ?? false,
        uwagi: j['uwagi'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'opis': opis,
        'data_zdarzenia': dataZdarzenia.toIso8601String(),
        if (poszkodowany != null) 'poszkodowany': poszkodowany,
        if (miejsceZdarzenia != null) 'miejsce_zdarzenia': miejsceZdarzenia,
        'status': status.apiValue,
        'wezwano_sluzby': wezwanoSluzby,
        'uwagi': uwagi,
      };

  String get dataFmt => _fmt.format(dataZdarzenia);
}

// ---- Instrukcja BHP ----

class InstrukcjaBhpModel {
  final int id;
  final int budowaId;
  final String tytul;
  final String tresc;
  final DateTime dataAktualizacji;

  const InstrukcjaBhpModel({
    required this.id,
    required this.budowaId,
    required this.tytul,
    required this.tresc,
    required this.dataAktualizacji,
  });

  factory InstrukcjaBhpModel.fromJson(Map<String, dynamic> j) => InstrukcjaBhpModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        tytul: j['tytul'] ?? '',
        tresc: j['tresc'] ?? '',
        dataAktualizacji:
            DateTime.tryParse(j['data_aktualizacji'] ?? '') ?? DateTime.now(),
      );
}
