import 'package:intl/intl.dart';

// ------------------------------------------------------------------ //
// Enums                                                               //
// ------------------------------------------------------------------ //

enum TypOdbioru { etapowy, czesciowy, koncowy, pogwarancyjny }

extension TypOdbioruExt on TypOdbioru {
  String get apiValue => switch (this) {
        TypOdbioru.etapowy => 'etapowy',
        TypOdbioru.czesciowy => 'czesciowy',
        TypOdbioru.koncowy => 'koncowy',
        TypOdbioru.pogwarancyjny => 'pogwarancyjny',
      };

  String get label => switch (this) {
        TypOdbioru.etapowy => 'Odbiór etapu',
        TypOdbioru.czesciowy => 'Odbiór częściowy',
        TypOdbioru.koncowy => 'Odbiór końcowy',
        TypOdbioru.pogwarancyjny => 'Odbiór pogwarancyjny',
      };

  String get emoji => switch (this) {
        TypOdbioru.etapowy => '📋',
        TypOdbioru.czesciowy => '🔍',
        TypOdbioru.koncowy => '🏁',
        TypOdbioru.pogwarancyjny => '🛡',
      };

  static TypOdbioru fromApi(String v) => switch (v) {
        'czesciowy' => TypOdbioru.czesciowy,
        'koncowy' => TypOdbioru.koncowy,
        'pogwarancyjny' => TypOdbioru.pogwarancyjny,
        _ => TypOdbioru.etapowy,
      };
}

enum StatusProtokolu { roboczy, do_podpisu, podpisany, odrzucony }

extension StatusProtokolaExt on StatusProtokolu {
  String get apiValue => switch (this) {
        StatusProtokolu.roboczy => 'roboczy',
        StatusProtokolu.do_podpisu => 'do_podpisu',
        StatusProtokolu.podpisany => 'podpisany',
        StatusProtokolu.odrzucony => 'odrzucony',
      };

  String get label => switch (this) {
        StatusProtokolu.roboczy => 'Roboczy',
        StatusProtokolu.do_podpisu => 'Do podpisu',
        StatusProtokolu.podpisany => 'Podpisany',
        StatusProtokolu.odrzucony => 'Odrzucony',
      };

  static StatusProtokolu fromApi(String v) => switch (v) {
        'do_podpisu' => StatusProtokolu.do_podpisu,
        'podpisany' => StatusProtokolu.podpisany,
        'odrzucony' => StatusProtokolu.odrzucony,
        _ => StatusProtokolu.roboczy,
      };
}

enum WynikPunktu { ok, nok, na }

extension WynikPunktuExt on WynikPunktu {
  String get apiValue => switch (this) {
        WynikPunktu.ok => 'ok',
        WynikPunktu.nok => 'nok',
        WynikPunktu.na => 'na',
      };

  String get label => switch (this) {
        WynikPunktu.ok => 'OK',
        WynikPunktu.nok => 'Niezgodność',
        WynikPunktu.na => 'Nie dotyczy',
      };

  static WynikPunktu fromApi(String v) => switch (v) {
        'ok' => WynikPunktu.ok,
        'nok' => WynikPunktu.nok,
        _ => WynikPunktu.na,
      };
}

enum StatusUsterki { otwarta, naprawiana, naprawiona, odrzucona }

extension StatusUsterkiExt on StatusUsterki {
  String get apiValue => switch (this) {
        StatusUsterki.otwarta => 'otwarta',
        StatusUsterki.naprawiana => 'naprawiana',
        StatusUsterki.naprawiona => 'naprawiona',
        StatusUsterki.odrzucona => 'odrzucona',
      };

  String get label => switch (this) {
        StatusUsterki.otwarta => 'Otwarta',
        StatusUsterki.naprawiana => 'W naprawie',
        StatusUsterki.naprawiona => 'Naprawiona',
        StatusUsterki.odrzucona => 'Odrzucona',
      };

  static StatusUsterki fromApi(String v) => switch (v) {
        'naprawiana' => StatusUsterki.naprawiana,
        'naprawiona' => StatusUsterki.naprawiona,
        'odrzucona' => StatusUsterki.odrzucona,
        _ => StatusUsterki.otwarta,
      };
}

// ------------------------------------------------------------------ //
// Models                                                              //
// ------------------------------------------------------------------ //

class PunktKontrolnyModel {
  final int id;
  final int protokolId;
  final String pytanie;
  final String kategoria;
  final bool wymagane;
  final WynikPunktu wynik;
  final String uwaga;
  final String? fotoUrl;
  final int kolejnosc;

  const PunktKontrolnyModel({
    required this.id,
    required this.protokolId,
    required this.pytanie,
    this.kategoria = '',
    this.wymagane = true,
    this.wynik = WynikPunktu.na,
    this.uwaga = '',
    this.fotoUrl,
    this.kolejnosc = 0,
  });

  factory PunktKontrolnyModel.fromJson(Map<String, dynamic> j) =>
      PunktKontrolnyModel(
        id: j['id'] ?? 0,
        protokolId: j['protokol'] ?? 0,
        pytanie: j['pytanie'] ?? '',
        kategoria: j['kategoria'] ?? '',
        wymagane: j['wymagane'] ?? true,
        wynik: WynikPunktuExt.fromApi(j['wynik'] ?? 'na'),
        uwaga: j['uwaga'] ?? '',
        fotoUrl: j['foto_url'],
        kolejnosc: j['kolejnosc'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'protokol': protokolId,
        'pytanie': pytanie,
        'kategoria': kategoria,
        'wymagane': wymagane,
        'wynik': wynik.apiValue,
        'uwaga': uwaga,
        'kolejnosc': kolejnosc,
      };

  PunktKontrolnyModel copyWith({WynikPunktu? wynik, String? uwaga, String? fotoUrl}) =>
      PunktKontrolnyModel(
        id: id, protokolId: protokolId, pytanie: pytanie, kategoria: kategoria,
        wymagane: wymagane, kolejnosc: kolejnosc,
        wynik: wynik ?? this.wynik,
        uwaga: uwaga ?? this.uwaga,
        fotoUrl: fotoUrl ?? this.fotoUrl,
      );

  bool get isOk => wynik == WynikPunktu.ok;
  bool get isNok => wynik == WynikPunktu.nok;
}

class UsterkaModel {
  final int id;
  final int budowaId;
  final int? protokolId;
  final int? etapId;
  final String opis;
  final String lokalizacja;
  final List<String> fotoUrls;
  final StatusUsterki status;
  final DateTime dataOdkrycia;
  final DateTime? dataTerminu;
  final String? wykonawcaOpis;
  final String zgloszonyPrzez;

  const UsterkaModel({
    required this.id,
    required this.budowaId,
    this.protokolId,
    this.etapId,
    required this.opis,
    this.lokalizacja = '',
    this.fotoUrls = const [],
    this.status = StatusUsterki.otwarta,
    required this.dataOdkrycia,
    this.dataTerminu,
    this.wykonawcaOpis,
    this.zgloszonyPrzez = '',
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory UsterkaModel.fromJson(Map<String, dynamic> j) => UsterkaModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        protokolId: j['protokol'],
        etapId: j['etap'],
        opis: j['opis'] ?? '',
        lokalizacja: j['lokalizacja'] ?? '',
        fotoUrls: (j['foto_urls'] as List? ?? []).cast<String>(),
        status: StatusUsterkiExt.fromApi(j['status'] ?? ''),
        dataOdkrycia: j['data_odkrycia'] != null
            ? DateTime.tryParse(j['data_odkrycia']) ?? DateTime.now()
            : DateTime.now(),
        dataTerminu: j['data_terminu'] != null ? DateTime.tryParse(j['data_terminu']) : null,
        wykonawcaOpis: j['wykonawca_opis'],
        zgloszonyPrzez: j['zgloszony_przez'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        if (protokolId != null) 'protokol': protokolId,
        if (etapId != null) 'etap': etapId,
        'opis': opis,
        'lokalizacja': lokalizacja,
        'status': status.apiValue,
        'data_odkrycia': dataOdkrycia.toIso8601String().split('T').first,
        if (dataTerminu != null) 'data_terminu': dataTerminu!.toIso8601String().split('T').first,
        if (wykonawcaOpis != null) 'wykonawca_opis': wykonawcaOpis,
      };

  String get dataOdkryciaFmt => _fmt.format(dataOdkrycia);
  String? get dataTerminuFmt => dataTerminu != null ? _fmt.format(dataTerminu!) : null;

  bool get isOtwarta => status == StatusUsterki.otwarta;
  bool get isPoTerminie =>
      dataTerminu != null &&
      dataTerminu!.isBefore(DateTime.now()) &&
      status != StatusUsterki.naprawiona;

  UsterkaModel copyWith({StatusUsterki? status}) =>
      UsterkaModel(
        id: id, budowaId: budowaId, protokolId: protokolId, etapId: etapId,
        opis: opis, lokalizacja: lokalizacja, fotoUrls: fotoUrls,
        dataOdkrycia: dataOdkrycia, dataTerminu: dataTerminu,
        wykonawcaOpis: wykonawcaOpis, zgloszonyPrzez: zgloszonyPrzez,
        status: status ?? this.status,
      );
}

class ProtokołOdbioruModel {
  final int id;
  final int budowaId;
  final int? etapId;
  final String tytul;
  final TypOdbioru typ;
  final StatusProtokolu status;
  final DateTime data;
  final String kierownikImie;
  final String inwestorImie;
  final String uwagi;
  final List<PunktKontrolnyModel> punkty;
  final List<UsterkaModel> usterki;
  final int usterkiOtwarte;
  final bool podpisanyPrzezKierownika;
  final bool podpisanyPrzezInwestora;

  const ProtokołOdbioruModel({
    required this.id,
    required this.budowaId,
    this.etapId,
    required this.tytul,
    this.typ = TypOdbioru.etapowy,
    this.status = StatusProtokolu.roboczy,
    required this.data,
    this.kierownikImie = '',
    this.inwestorImie = '',
    this.uwagi = '',
    this.punkty = const [],
    this.usterki = const [],
    this.usterkiOtwarte = 0,
    this.podpisanyPrzezKierownika = false,
    this.podpisanyPrzezInwestora = false,
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory ProtokołOdbioruModel.fromJson(Map<String, dynamic> j) =>
      ProtokołOdbioruModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        etapId: j['etap'],
        tytul: j['tytul'] ?? '',
        typ: TypOdbioruExt.fromApi(j['typ'] ?? ''),
        status: StatusProtokolaExt.fromApi(j['status'] ?? ''),
        data: j['data'] != null
            ? DateTime.tryParse(j['data']) ?? DateTime.now()
            : DateTime.now(),
        kierownikImie: j['kierownik_imie'] ?? '',
        inwestorImie: j['inwestor_imie'] ?? '',
        uwagi: j['uwagi'] ?? '',
        punkty: (j['punkty'] as List? ?? [])
            .map((e) => PunktKontrolnyModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        usterki: (j['usterki'] as List? ?? [])
            .map((e) => UsterkaModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        usterkiOtwarte: j['usterki_otwarte'] ?? 0,
        podpisanyPrzezKierownika: j['podpisany_kierownik'] ?? false,
        podpisanyPrzezInwestora: j['podpisany_inwestor'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        if (etapId != null) 'etap': etapId,
        'tytul': tytul,
        'typ': typ.apiValue,
        'status': status.apiValue,
        'data': data.toIso8601String().split('T').first,
        'uwagi': uwagi,
      };

  String get dataFmt => _fmt.format(data);

  int get punktyOk => punkty.where((p) => p.isOk).length;
  int get punktyNok => punkty.where((p) => p.isNok).length;
  int get punktyTotal => punkty.where((p) => p.wynik != WynikPunktu.na).length;
  double get postepProcent =>
      punkty.isEmpty ? 0 : punkty.where((p) => p.wynik != WynikPunktu.na).length / punkty.length;
}
