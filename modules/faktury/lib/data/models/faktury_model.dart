import 'package:flutter/material.dart';

enum TypFaktury {
  sprzedaz, zaliczkowa, koncowa, korygujaca, proforma;

  static TypFaktury fromApi(String v) =>
      TypFaktury.values.firstWhere((e) => e.name == v, orElse: () => sprzedaz);

  String get label => switch (this) {
        sprzedaz => 'Faktura sprzedaży',
        zaliczkowa => 'Zaliczkowa',
        koncowa => 'Końcowa',
        korygujaca => 'Korygująca',
        proforma => 'Proforma',
      };
}

enum StatusFaktury {
  szkic, wystawiona, wyslana, oplacona, przeterminowana, anulowana;

  static StatusFaktury fromApi(String v) =>
      StatusFaktury.values.firstWhere((e) => e.name == v, orElse: () => szkic);

  String get label => switch (this) {
        szkic => 'Szkic',
        wystawiona => 'Wystawiona',
        wyslana => 'Wysłana',
        oplacona => 'Opłacona',
        przeterminowana => 'Przeterminowana',
        anulowana => 'Anulowana',
      };

  Color get color => switch (this) {
        szkic => const Color(0xFF9E9E9E),
        wystawiona => const Color(0xFF42A5F5),
        wyslana => const Color(0xFFFF9800),
        oplacona => const Color(0xFF66BB6A),
        przeterminowana => const Color(0xFFEF5350),
        anulowana => const Color(0xFF9E9E9E),
      };
}

class FakturaListItem {
  final int id;
  final String numer;
  final TypFaktury typ;
  final StatusFaktury status;
  final String nabywcaNazwa;
  final int? budowaId;
  final String? budowaNazwa;
  final DateTime dataWystawienia;
  final DateTime terminPlatnosci;
  final double wartoscNetto;
  final double wartoscVat;
  final double wartoscBrutto;
  final int stawkaVat;
  final bool jestPrzeterminowana;

  const FakturaListItem({
    required this.id,
    required this.numer,
    required this.typ,
    required this.status,
    required this.nabywcaNazwa,
    this.budowaId,
    this.budowaNazwa,
    required this.dataWystawienia,
    required this.terminPlatnosci,
    required this.wartoscNetto,
    required this.wartoscVat,
    required this.wartoscBrutto,
    required this.stawkaVat,
    required this.jestPrzeterminowana,
  });

  factory FakturaListItem.fromJson(Map<String, dynamic> j) => FakturaListItem(
        id: j['id'] as int,
        numer: j['numer'] as String? ?? '',
        typ: TypFaktury.fromApi(j['typ'] as String? ?? 'sprzedaz'),
        status: StatusFaktury.fromApi(j['status'] as String? ?? 'szkic'),
        nabywcaNazwa: j['nabywca_nazwa'] as String? ?? '',
        budowaId: j['budowa_id'] as int?,
        budowaNazwa: j['budowa_nazwa'] as String?,
        dataWystawienia: DateTime.parse(j['data_wystawienia'] as String),
        terminPlatnosci: DateTime.parse(j['termin_platnosci'] as String),
        wartoscNetto: double.tryParse(j['wartosc_netto']?.toString() ?? '0') ?? 0,
        wartoscVat: double.tryParse(j['wartosc_vat']?.toString() ?? '0') ?? 0,
        wartoscBrutto:
            double.tryParse(j['wartosc_brutto']?.toString() ?? '0') ?? 0,
        stawkaVat: j['stawka_vat'] as int? ?? 23,
        jestPrzeterminowana: j['jest_przeterminowana'] as bool? ?? false,
      );

  String get numerDisplay => numer.isNotEmpty ? numer : 'Szkic';
}

class FakturaDetail extends FakturaListItem {
  final int? ofertaId;
  final String wystawcaNazwa;
  final String wystawcaNip;
  final String wystawcaAdres;
  final String wystawcaKonto;
  final String nabywcaNip;
  final String nabywcaAdres;
  final String metodaPlatnosci;
  final List<Map<String, dynamic>> pozycje;
  final String uwagi;

  const FakturaDetail({
    required super.id,
    required super.numer,
    required super.typ,
    required super.status,
    required super.nabywcaNazwa,
    super.budowaId,
    super.budowaNazwa,
    required super.dataWystawienia,
    required super.terminPlatnosci,
    required super.wartoscNetto,
    required super.wartoscVat,
    required super.wartoscBrutto,
    required super.stawkaVat,
    required super.jestPrzeterminowana,
    this.ofertaId,
    required this.wystawcaNazwa,
    required this.wystawcaNip,
    required this.wystawcaAdres,
    required this.wystawcaKonto,
    required this.nabywcaNip,
    required this.nabywcaAdres,
    required this.metodaPlatnosci,
    required this.pozycje,
    required this.uwagi,
  });

  factory FakturaDetail.fromJson(Map<String, dynamic> j) {
    final base = FakturaListItem.fromJson(j);
    return FakturaDetail(
      id: base.id,
      numer: base.numer,
      typ: base.typ,
      status: base.status,
      nabywcaNazwa: base.nabywcaNazwa,
      budowaId: base.budowaId,
      budowaNazwa: base.budowaNazwa,
      dataWystawienia: base.dataWystawienia,
      terminPlatnosci: base.terminPlatnosci,
      wartoscNetto: base.wartoscNetto,
      wartoscVat: base.wartoscVat,
      wartoscBrutto: base.wartoscBrutto,
      stawkaVat: base.stawkaVat,
      jestPrzeterminowana: base.jestPrzeterminowana,
      ofertaId: j['oferta_id'] as int?,
      wystawcaNazwa: j['wystawca_nazwa'] as String? ?? '',
      wystawcaNip: j['wystawca_nip'] as String? ?? '',
      wystawcaAdres: j['wystawca_adres'] as String? ?? '',
      wystawcaKonto: j['wystawca_konto'] as String? ?? '',
      nabywcaNip: j['nabywca_nip'] as String? ?? '',
      nabywcaAdres: j['nabywca_adres'] as String? ?? '',
      metodaPlatnosci: j['metoda_platnosci'] as String? ?? 'przelew',
      pozycje: (j['pozycje'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
      uwagi: j['uwagi'] as String? ?? '',
    );
  }
}
