import 'package:intl/intl.dart';

enum StatusFaktury { szkic, wystawiona, oplacona, przeterminowana, anulowana }

extension StatusFakturyExt on StatusFaktury {
  String get apiValue => name;
  String get label => switch (this) {
        StatusFaktury.szkic => 'Szkic',
        StatusFaktury.wystawiona => 'Wystawiona',
        StatusFaktury.oplacona => 'Opłacona',
        StatusFaktury.przeterminowana => 'Przeterminowana',
        StatusFaktury.anulowana => 'Anulowana',
      };
  static StatusFaktury fromApi(String v) => StatusFaktury.values
      .firstWhere((e) => e.name == v, orElse: () => StatusFaktury.szkic);
}

enum TypFaktury { postepowa, koncowa, zaliczkowa, korygujaca }

extension TypFakturyExt on TypFaktury {
  String get apiValue => name;
  String get label => switch (this) {
        TypFaktury.postepowa => 'Postępowa',
        TypFaktury.koncowa => 'Końcowa',
        TypFaktury.zaliczkowa => 'Zaliczkowa',
        TypFaktury.korygujaca => 'Korygująca',
      };
  static TypFaktury fromApi(String v) => TypFaktury.values
      .firstWhere((e) => e.name == v, orElse: () => TypFaktury.postepowa);
}

// ---- Pozycja faktury ----

class PozycjaFakturyModel {
  final int id;
  final String opis;
  final double ilosc;
  final String jednostka;
  final double cenaNetto;
  final double vat;
  final String? etapNazwa;

  const PozycjaFakturyModel({
    this.id = 0,
    required this.opis,
    required this.ilosc,
    this.jednostka = 'ryczałt',
    required this.cenaNetto,
    this.vat = 23,
    this.etapNazwa,
  });

  factory PozycjaFakturyModel.fromJson(Map<String, dynamic> j) =>
      PozycjaFakturyModel(
        id: j['id'] ?? 0,
        opis: j['opis'] ?? '',
        ilosc: double.tryParse(j['ilosc']?.toString() ?? '1') ?? 1,
        jednostka: j['jednostka'] ?? 'ryczałt',
        cenaNetto: double.tryParse(j['cena_netto']?.toString() ?? '0') ?? 0,
        vat: double.tryParse(j['vat']?.toString() ?? '23') ?? 23,
        etapNazwa: j['etap_nazwa'],
      );

  Map<String, dynamic> toJson() => {
        'opis': opis,
        'ilosc': ilosc,
        'jednostka': jednostka,
        'cena_netto': cenaNetto,
        'vat': vat,
      };

  double get wartoscNetto => ilosc * cenaNetto;
  double get wartoscVat => wartoscNetto * vat / 100;
  double get wartoscBrutto => wartoscNetto + wartoscVat;
}

// ---- Faktura ----

class FakturaModel {
  final int id;
  final int budowaId;
  final String? budowaNazwa;
  final String numer;
  final TypFaktury typ;
  final StatusFaktury status;
  final DateTime dataWystawienia;
  final DateTime dataTerminu;
  final DateTime? dataOplaty;
  final String inwestorNazwa;
  final String wykonawcaNazwa;
  final List<PozycjaFakturyModel> pozycje;
  final double postepProcent;
  final String uwagi;

  const FakturaModel({
    required this.id,
    required this.budowaId,
    this.budowaNazwa,
    required this.numer,
    this.typ = TypFaktury.postepowa,
    this.status = StatusFaktury.szkic,
    required this.dataWystawienia,
    required this.dataTerminu,
    this.dataOplaty,
    required this.inwestorNazwa,
    required this.wykonawcaNazwa,
    this.pozycje = const [],
    this.postepProcent = 0,
    this.uwagi = '',
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory FakturaModel.fromJson(Map<String, dynamic> j) => FakturaModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        budowaNazwa: j['budowa_nazwa'],
        numer: j['numer'] ?? '',
        typ: TypFakturyExt.fromApi(j['typ'] ?? ''),
        status: StatusFakturyExt.fromApi(j['status'] ?? ''),
        dataWystawienia: DateTime.tryParse(j['data_wystawienia'] ?? '') ?? DateTime.now(),
        dataTerminu: DateTime.tryParse(j['data_terminu'] ?? '') ?? DateTime.now(),
        dataOplaty: j['data_oplaty'] != null ? DateTime.tryParse(j['data_oplaty']) : null,
        inwestorNazwa: j['inwestor_nazwa'] ?? '',
        wykonawcaNazwa: j['wykonawca_nazwa'] ?? '',
        pozycje: (j['pozycje'] as List? ?? [])
            .map((e) => PozycjaFakturyModel.fromJson(e))
            .toList(),
        postepProcent: double.tryParse(j['postep_procent']?.toString() ?? '0') ?? 0,
        uwagi: j['uwagi'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'typ': typ.apiValue,
        'status': status.apiValue,
        'data_wystawienia': dataWystawienia.toIso8601String(),
        'data_terminu': dataTerminu.toIso8601String(),
        'inwestor_nazwa': inwestorNazwa,
        'wykonawca_nazwa': wykonawcaNazwa,
        'postep_procent': postepProcent,
        'uwagi': uwagi,
        'pozycje': pozycje.map((p) => p.toJson()).toList(),
      };

  double get sumaNettoCalkowita =>
      pozycje.fold(0, (s, p) => s + p.wartoscNetto);
  double get sumaVatCalkowita => pozycje.fold(0, (s, p) => s + p.wartoscVat);
  double get sumaBruttoCalkowita => pozycje.fold(0, (s, p) => s + p.wartoscBrutto);

  bool get przeterminowana =>
      status == StatusFaktury.wystawiona &&
      dataTerminu.isBefore(DateTime.now());

  String get dataWystawieniaFmt => _fmt.format(dataWystawienia);
  String get dataTerminuFmt => _fmt.format(dataTerminu);
  String? get dataOplatyFmt => dataOplaty != null ? _fmt.format(dataOplaty!) : null;
}

// ---- Podsumowanie rozliczeń budowy ----

class BudowaRozliczeniaStats {
  final double wartoscKontraktu;
  final double fakturowanoLacznie;
  final double oplaconoLacznie;
  final double doFakturowania;
  final int fakturaOczekujace;

  const BudowaRozliczeniaStats({
    required this.wartoscKontraktu,
    required this.fakturowanoLacznie,
    required this.oplaconoLacznie,
    required this.doFakturowania,
    required this.fakturaOczekujace,
  });

  factory BudowaRozliczeniaStats.fromJson(Map<String, dynamic> j) =>
      BudowaRozliczeniaStats(
        wartoscKontraktu: double.tryParse(j['wartosc_kontraktu']?.toString() ?? '0') ?? 0,
        fakturowanoLacznie: double.tryParse(j['fakturowanoLacznie']?.toString() ?? '0') ?? 0,
        oplaconoLacznie: double.tryParse(j['oplacono_lacznie']?.toString() ?? '0') ?? 0,
        doFakturowania: double.tryParse(j['do_fakturowania']?.toString() ?? '0') ?? 0,
        fakturaOczekujace: j['faktury_oczekujace'] ?? 0,
      );

  double get postepFakturowania =>
      wartoscKontraktu > 0 ? (fakturowanoLacznie / wartoscKontraktu).clamp(0, 1) : 0;
}
