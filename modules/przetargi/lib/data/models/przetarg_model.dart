import 'package:intl/intl.dart';

enum StatusPrzetargu {
  nowy,
  analizowany,
  kosztorysGotowy,
  zlozony,
  wygrany,
  przegrany,
  pominiety;

  static StatusPrzetargu fromApi(String v) => switch (v) {
        'kosztorys_gotowy' => kosztorysGotowy,
        'zlozony' => zlozony,
        'wygrany' => wygrany,
        'przegrany' => przegrany,
        'pominiety' => pominiety,
        'analizowany' => analizowany,
        _ => nowy,
      };

  String get apiValue => switch (this) {
        kosztorysGotowy => 'kosztorys_gotowy',
        zlozony => 'zlozony',
        wygrany => 'wygrany',
        przegrany => 'przegrany',
        pominiety => 'pominiety',
        analizowany => 'analizowany',
        nowy => 'nowy',
      };

  String get label => switch (this) {
        nowy => 'Nowy',
        analizowany => 'Analizowany',
        kosztorysGotowy => 'Kosztorys gotowy',
        zlozony => 'Złożony',
        wygrany => 'Wygrany',
        przegrany => 'Przegrany',
        pominiety => 'Pominięty',
      };
}

class PrzetargListItem {
  final int id;
  final String tytul;
  final String zamawiajacy;
  final double? wartoscSzacunkowa;
  final String waluta;
  final DateTime? terminSkladania;
  final String lokalizacja;
  final List<String> cpvKody;
  final StatusPrzetargu status;
  final int? aiScore;
  final bool? aiCzyWarto;
  final List<String> aiUwagi;
  final String zrodlo;
  final String zrodloUrl;
  final int? kosztorysId;
  final int? dniDoTerminu;
  final DateTime createdAt;

  const PrzetargListItem({
    required this.id,
    required this.tytul,
    required this.zamawiajacy,
    this.wartoscSzacunkowa,
    required this.waluta,
    this.terminSkladania,
    required this.lokalizacja,
    required this.cpvKody,
    required this.status,
    this.aiScore,
    this.aiCzyWarto,
    required this.aiUwagi,
    required this.zrodlo,
    required this.zrodloUrl,
    this.kosztorysId,
    this.dniDoTerminu,
    required this.createdAt,
  });

  factory PrzetargListItem.fromJson(Map<String, dynamic> j) => PrzetargListItem(
        id: j['id'] as int,
        tytul: j['tytul'] as String? ?? '',
        zamawiajacy: j['zamawiajacy'] as String? ?? '',
        wartoscSzacunkowa: j['wartosc_szacunkowa'] != null
            ? double.tryParse(j['wartosc_szacunkowa'].toString())
            : null,
        waluta: j['waluta'] as String? ?? 'PLN',
        terminSkladania: j['termin_skladania'] != null
            ? DateTime.tryParse(j['termin_skladania'] as String)
            : null,
        lokalizacja: j['lokalizacja'] as String? ?? '',
        cpvKody: List<String>.from(j['cpv_kody'] as List? ?? []),
        status: StatusPrzetargu.fromApi(j['status'] as String? ?? 'nowy'),
        aiScore: j['ai_score'] as int?,
        aiCzyWarto: j['ai_czy_warto'] as bool?,
        aiUwagi: List<String>.from(j['ai_uwagi'] as List? ?? []),
        zrodlo: j['zrodlo'] as String? ?? '',
        zrodloUrl: j['zrodlo_url'] as String? ?? '',
        kosztorysId: j['kosztorys_id'] as int?,
        dniDoTerminu: j['dni_do_terminu'] as int?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  String get wartoscFormatted {
    if (wartoscSzacunkowa == null) return '—';
    final f = NumberFormat('#,##0', 'pl_PL');
    return '${f.format(wartoscSzacunkowa)} $waluta';
  }

  String get terminLabel {
    if (terminSkladania == null) return '—';
    return DateFormat('d MMM yyyy', 'pl_PL').format(terminSkladania!.toLocal());
  }
}

class PrzetargDetail extends PrzetargListItem {
  final String opis;
  final String? terminRealizacji;
  final String aiUzasadnienie;
  final DateTime? aiAnalizowanyAt;
  final Map<String, dynamic> rawData;

  const PrzetargDetail({
    required super.id,
    required super.tytul,
    required super.zamawiajacy,
    super.wartoscSzacunkowa,
    required super.waluta,
    super.terminSkladania,
    required super.lokalizacja,
    required super.cpvKody,
    required super.status,
    super.aiScore,
    super.aiCzyWarto,
    required super.aiUwagi,
    required super.zrodlo,
    required super.zrodloUrl,
    super.kosztorysId,
    super.dniDoTerminu,
    required super.createdAt,
    required this.opis,
    this.terminRealizacji,
    required this.aiUzasadnienie,
    this.aiAnalizowanyAt,
    required this.rawData,
  });

  factory PrzetargDetail.fromJson(Map<String, dynamic> j) {
    final base = PrzetargListItem.fromJson(j);
    return PrzetargDetail(
      id: base.id,
      tytul: base.tytul,
      zamawiajacy: base.zamawiajacy,
      wartoscSzacunkowa: base.wartoscSzacunkowa,
      waluta: base.waluta,
      terminSkladania: base.terminSkladania,
      lokalizacja: base.lokalizacja,
      cpvKody: base.cpvKody,
      status: base.status,
      aiScore: base.aiScore,
      aiCzyWarto: base.aiCzyWarto,
      aiUwagi: base.aiUwagi,
      zrodlo: base.zrodlo,
      zrodloUrl: base.zrodloUrl,
      kosztorysId: base.kosztorysId,
      dniDoTerminu: base.dniDoTerminu,
      createdAt: base.createdAt,
      opis: j['opis'] as String? ?? '',
      terminRealizacji: j['termin_realizacji'] as String?,
      aiUzasadnienie: j['ai_uzasadnienie'] as String? ?? '',
      aiAnalizowanyAt: j['ai_analizowany_at'] != null
          ? DateTime.tryParse(j['ai_analizowany_at'] as String)
          : null,
      rawData: j['raw_data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class SubskrypcjaPrzetargow {
  final int id;
  final String nazwa;
  final List<String> cpvKody;
  final List<String> regiony;
  final double? wartoscMin;
  final double? wartoscMax;
  final List<String> slowaKluczowe;
  final bool aktywna;
  final DateTime? ostatniePobranie;

  const SubskrypcjaPrzetargow({
    required this.id,
    required this.nazwa,
    required this.cpvKody,
    required this.regiony,
    this.wartoscMin,
    this.wartoscMax,
    required this.slowaKluczowe,
    required this.aktywna,
    this.ostatniePobranie,
  });

  factory SubskrypcjaPrzetargow.fromJson(Map<String, dynamic> j) =>
      SubskrypcjaPrzetargow(
        id: j['id'] as int,
        nazwa: j['nazwa'] as String? ?? '',
        cpvKody: List<String>.from(j['cpv_kody'] as List? ?? []),
        regiony: List<String>.from(j['regiony'] as List? ?? []),
        wartoscMin: j['wartosc_min'] != null
            ? double.tryParse(j['wartosc_min'].toString())
            : null,
        wartoscMax: j['wartosc_max'] != null
            ? double.tryParse(j['wartosc_max'].toString())
            : null,
        slowaKluczowe: List<String>.from(j['slowa_kluczowe'] as List? ?? []),
        aktywna: j['aktywna'] as bool? ?? true,
        ostatniePobranie: j['ostatnie_pobranie'] != null
            ? DateTime.tryParse(j['ostatnie_pobranie'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'nazwa': nazwa,
        'cpv_kody': cpvKody,
        'regiony': regiony,
        if (wartoscMin != null) 'wartosc_min': wartoscMin,
        if (wartoscMax != null) 'wartosc_max': wartoscMax,
        'slowa_kluczowe': slowaKluczowe,
        'aktywna': aktywna,
      };
}
