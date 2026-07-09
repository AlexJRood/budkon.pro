import 'package:flutter/foundation.dart';

enum StatusKosztorysu { roboczy, oferta, zatwierdzony }

extension StatusKosztorysyExt on StatusKosztorysu {
  String get apiValue => switch (this) {
        StatusKosztorysu.roboczy => 'roboczy',
        StatusKosztorysu.oferta => 'oferta',
        StatusKosztorysu.zatwierdzony => 'zatwierdzony',
      };

  String get label => switch (this) {
        StatusKosztorysu.roboczy => 'Roboczy',
        StatusKosztorysu.oferta => 'Oferta',
        StatusKosztorysu.zatwierdzony => 'Zatwierdzony',
      };

  static StatusKosztorysu fromApi(String v) => switch (v) {
        'oferta' => StatusKosztorysu.oferta,
        'zatwierdzony' => StatusKosztorysu.zatwierdzony,
        _ => StatusKosztorysu.roboczy,
      };
}

// ── KNR ───────────────────────────────────────────────────────────────────────

class KnrKatalogModel {
  final int id;
  final String kod;
  final String nazwa;

  const KnrKatalogModel({required this.id, required this.kod, required this.nazwa});

  factory KnrKatalogModel.fromJson(Map<String, dynamic> j) => KnrKatalogModel(
        id: j['id'] ?? 0,
        kod: j['kod'] ?? '',
        nazwa: j['nazwa'] ?? '',
      );
}

class KnrPozycjaModel {
  final int id;
  final int katalogId;
  final String katalogKod;
  final String numer;
  final String opis;
  final String jednostka;
  final double nakladR;
  final double nakladM;
  final double nakladS;

  const KnrPozycjaModel({
    required this.id,
    required this.katalogId,
    required this.katalogKod,
    required this.numer,
    required this.opis,
    required this.jednostka,
    this.nakladR = 0,
    this.nakladM = 0,
    this.nakladS = 0,
  });

  factory KnrPozycjaModel.fromJson(Map<String, dynamic> j) => KnrPozycjaModel(
        id: j['id'] ?? 0,
        katalogId: j['katalog'] ?? 0,
        katalogKod: j['katalog_kod'] ?? '',
        numer: j['numer'] ?? '',
        opis: j['opis'] ?? '',
        jednostka: j['jednostka'] ?? '',
        nakladR: double.tryParse(j['naklad_r']?.toString() ?? '0') ?? 0,
        nakladM: double.tryParse(j['naklad_m']?.toString() ?? '0') ?? 0,
        nakladS: double.tryParse(j['naklad_s']?.toString() ?? '0') ?? 0,
      );
}

// ── Pozycja kosztorysowa ───────────────────────────────────────────────────────

class KosztorysPozycjaModel {
  final int id;
  final int dzialId;
  final int? knrPozycjaId;
  final String? knrNumer;
  final String opis;
  final String jednostka;
  final double ilosc;
  final double cenaJednostkowa;
  final double wartosc;
  final int kolejnosc;
  final double? aiSuggestedPrice;
  final double? aiSuggestedQty;

  const KosztorysPozycjaModel({
    required this.id,
    required this.dzialId,
    this.knrPozycjaId,
    this.knrNumer,
    required this.opis,
    required this.jednostka,
    required this.ilosc,
    required this.cenaJednostkowa,
    required this.wartosc,
    this.kolejnosc = 0,
    this.aiSuggestedPrice,
    this.aiSuggestedQty,
  });

  factory KosztorysPozycjaModel.fromJson(Map<String, dynamic> j) =>
      KosztorysPozycjaModel(
        id: j['id'] ?? 0,
        dzialId: j['dzial'] ?? 0,
        knrPozycjaId: j['knr_pozycja'],
        knrNumer: j['knr_numer'],
        opis: j['opis'] ?? '',
        jednostka: j['jednostka'] ?? '',
        ilosc: double.tryParse(j['ilosc']?.toString() ?? '0') ?? 0,
        cenaJednostkowa:
            double.tryParse(j['cena_jednostkowa']?.toString() ?? '0') ?? 0,
        wartosc: double.tryParse(j['wartosc']?.toString() ?? '0') ?? 0,
        kolejnosc: j['kolejnosc'] ?? 0,
        aiSuggestedPrice:
            j['ai_suggested_price'] != null
                ? double.tryParse(j['ai_suggested_price'].toString())
                : null,
        aiSuggestedQty:
            j['ai_suggested_qty'] != null
                ? double.tryParse(j['ai_suggested_qty'].toString())
                : null,
      );

  Map<String, dynamic> toJson() => {
        'dzial': dzialId,
        if (knrPozycjaId != null) 'knr_pozycja': knrPozycjaId,
        'opis': opis,
        'jednostka': jednostka,
        'ilosc': ilosc,
        'cena_jednostkowa': cenaJednostkowa,
        'kolejnosc': kolejnosc,
      };

  KosztorysPozycjaModel copyWith({double? ilosc, double? cenaJednostkowa}) =>
      KosztorysPozycjaModel(
        id: id,
        dzialId: dzialId,
        knrPozycjaId: knrPozycjaId,
        knrNumer: knrNumer,
        opis: opis,
        jednostka: jednostka,
        ilosc: ilosc ?? this.ilosc,
        cenaJednostkowa: cenaJednostkowa ?? this.cenaJednostkowa,
        wartosc: (ilosc ?? this.ilosc) * (cenaJednostkowa ?? this.cenaJednostkowa),
        kolejnosc: kolejnosc,
        aiSuggestedPrice: aiSuggestedPrice,
        aiSuggestedQty: aiSuggestedQty,
      );
}

// ── Dział ─────────────────────────────────────────────────────────────────────

class KosztorysdzDzialModel {
  final int id;
  final int kosztorysId;
  final String nazwa;
  final int kolejnosc;
  final List<KosztorysPozycjaModel> pozycje;

  const KosztorysdzDzialModel({
    required this.id,
    required this.kosztorysId,
    required this.nazwa,
    this.kolejnosc = 0,
    this.pozycje = const [],
  });

  double get wartoscDzialu =>
      pozycje.fold(0.0, (s, p) => s + p.wartosc);

  factory KosztorysdzDzialModel.fromJson(Map<String, dynamic> j) =>
      KosztorysdzDzialModel(
        id: j['id'] ?? 0,
        kosztorysId: j['kosztorys'] ?? 0,
        nazwa: j['nazwa'] ?? '',
        kolejnosc: j['kolejnosc'] ?? 0,
        pozycje: (j['pozycje'] as List<dynamic>? ?? [])
            .map((p) =>
                KosztorysPozycjaModel.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

// ── Kosztorys ─────────────────────────────────────────────────────────────────

class KosztorysListItemModel {
  final int id;
  final int? budowaId;
  final String nazwa;
  final String opis;
  final StatusKosztorysu status;
  final double wartoscTotal;
  final int pozycjeCount;
  final DateTime updatedAt;

  const KosztorysListItemModel({
    required this.id,
    this.budowaId,
    required this.nazwa,
    this.opis = '',
    required this.status,
    required this.wartoscTotal,
    required this.pozycjeCount,
    required this.updatedAt,
  });

  factory KosztorysListItemModel.fromJson(Map<String, dynamic> j) =>
      KosztorysListItemModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa_id'],
        nazwa: j['nazwa'] ?? '',
        opis: j['opis'] ?? '',
        status: StatusKosztorysyExt.fromApi(j['status'] ?? ''),
        wartoscTotal:
            double.tryParse(j['wartosc_total']?.toString() ?? '0') ?? 0,
        pozycjeCount: j['pozycje_count'] ?? 0,
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class KosztorysModel {
  final int id;
  final int? budowaId;
  final String nazwa;
  final String opis;
  final StatusKosztorysu status;
  final String aiPrompt;
  final double wartoscTotal;
  final List<KosztorysdzDzialModel> dzialy;
  final DateTime updatedAt;

  const KosztorysModel({
    required this.id,
    this.budowaId,
    required this.nazwa,
    this.opis = '',
    required this.status,
    this.aiPrompt = '',
    this.wartoscTotal = 0,
    this.dzialy = const [],
    required this.updatedAt,
  });

  factory KosztorysModel.fromJson(Map<String, dynamic> j) => KosztorysModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa_id'],
        nazwa: j['nazwa'] ?? '',
        opis: j['opis'] ?? '',
        status: StatusKosztorysyExt.fromApi(j['status'] ?? ''),
        aiPrompt: j['ai_prompt'] ?? '',
        wartoscTotal:
            double.tryParse(j['wartosc_total']?.toString() ?? '0') ?? 0,
        dzialy: (j['dzialy'] as List<dynamic>? ?? [])
            .map((d) =>
                KosztorysdzDzialModel.fromJson(d as Map<String, dynamic>))
            .toList(),
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at']) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        if (budowaId != null) 'budowa_id': budowaId,
        'nazwa': nazwa,
        'opis': opis,
        'status': status.apiValue,
      };
}
