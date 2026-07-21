import 'package:flutter/material.dart';

// ── Pomieszczenie w rzucie ─────────────────────────────────────────────────────

class PomieszczenieProjekt {
  final String id;
  final String nazwa;
  final double powierzchnia; // m²
  final String? typPomieszczenia; // salon, sypialnia, kuchnia, etc.

  // Pozycja i rozmiar na floor planie (wartości 0.0–1.0, relative)
  final double x;
  final double y;
  final double szerokosc;
  final double wysokosc;

  final Color kolor;

  const PomieszczenieProjekt({
    required this.id,
    required this.nazwa,
    required this.powierzchnia,
    this.typPomieszczenia,
    this.x = 0,
    this.y = 0,
    this.szerokosc = 0.2,
    this.wysokosc = 0.2,
    this.kolor = const Color(0xFF607D8B),
  });

  PomieszczenieProjekt copyWith({
    double? x,
    double? y,
    double? szerokosc,
    double? wysokosc,
    String? nazwa,
    double? powierzchnia,
  }) =>
      PomieszczenieProjekt(
        id: id,
        nazwa: nazwa ?? this.nazwa,
        powierzchnia: powierzchnia ?? this.powierzchnia,
        typPomieszczenia: typPomieszczenia,
        x: x ?? this.x,
        y: y ?? this.y,
        szerokosc: szerokosc ?? this.szerokosc,
        wysokosc: wysokosc ?? this.wysokosc,
        kolor: kolor,
      );

  factory PomieszczenieProjekt.fromJson(Map<String, dynamic> j, int index) {
    final colors = _roomColors();
    return PomieszczenieProjekt(
      id: j['id']?.toString() ?? 'room_$index',
      nazwa: j['nazwa'] ?? j['name'] ?? 'Pomieszczenie ${index + 1}',
      powierzchnia: double.tryParse(j['powierzchnia']?.toString() ?? '0') ?? 0,
      typPomieszczenia: j['typ'],
      x: double.tryParse(j['x']?.toString() ?? '0') ?? 0,
      y: double.tryParse(j['y']?.toString() ?? '0') ?? 0,
      szerokosc: double.tryParse(j['szerokosc']?.toString() ?? '0.2') ?? 0.2,
      wysokosc: double.tryParse(j['wysokosc']?.toString() ?? '0.2') ?? 0.2,
      kolor: colors[index % colors.length],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nazwa': nazwa,
        'powierzchnia': powierzchnia,
        if (typPomieszczenia != null) 'typ': typPomieszczenia,
        'x': x,
        'y': y,
        'szerokosc': szerokosc,
        'wysokosc': wysokosc,
      };

  static List<Color> _roomColors() => const [
        Color(0xFF5C7A9C),
        Color(0xFF6B8E7A),
        Color(0xFF8E7A6B),
        Color(0xFF7A6B8E),
        Color(0xFF8E6B7A),
        Color(0xFF6B7A8E),
        Color(0xFF7A8E6B),
        Color(0xFF8E8E6B),
      ];
}

// ── Sugerowana pozycja kosztorysowa z AI ──────────────────────────────────────

class SugerowanaPozyacja {
  final String opis;
  final String jednostka;
  final double ilosc;
  final double szacowanaCena;
  final String? zrodloPomieszczenia;
  final String? kategoria;

  const SugerowanaPozyacja({
    required this.opis,
    required this.jednostka,
    required this.ilosc,
    required this.szacowanaCena,
    this.zrodloPomieszczenia,
    this.kategoria,
  });

  double get wartoscSzacunkowa => ilosc * szacowanaCena;

  factory SugerowanaPozyacja.fromJson(Map<String, dynamic> j) =>
      SugerowanaPozyacja(
        opis: j['opis'] ?? j['description'] ?? '',
        jednostka: j['jednostka'] ?? j['unit'] ?? 'm²',
        ilosc: double.tryParse(j['ilosc']?.toString() ?? '0') ?? 0,
        szacowanaCena:
            double.tryParse(j['cena']?.toString() ?? j['price']?.toString() ?? '0') ?? 0,
        zrodloPomieszczenia: j['pomieszczenie']?.toString(),
        kategoria: j['kategoria']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'opis': opis,
        'jednostka': jednostka,
        'ilosc': ilosc,
        'cena_jednostkowa': szacowanaCena,
      };
}

// ── Wynik parsowania projektu ─────────────────────────────────────────────────

class ParsedProjekt {
  final String? tytul;
  final double? powierzchniaCalkwita;
  final double? liczbaKondygnacji;
  final List<PomieszczenieProjekt> pomieszczenia;
  final List<SugerowanaPozyacja> sugerowanePozyacje;
  final String? uwagi;

  const ParsedProjekt({
    this.tytul,
    this.powierzchniaCalkwita,
    this.liczbaKondygnacji,
    this.pomieszczenia = const [],
    this.sugerowanePozyacje = const [],
    this.uwagi,
  });

  double get sumaPowierzchni =>
      pomieszczenia.fold(0.0, (s, p) => s + p.powierzchnia);

  double get wartoscSzacunkowaCalkwita =>
      sugerowanePozyacje.fold(0.0, (s, p) => s + p.wartoscSzacunkowa);

  factory ParsedProjekt.fromJson(Map<String, dynamic> j) {
    final roomsList = (j['pomieszczenia'] ?? j['rooms'] ?? []) as List;
    final pozycjeList = (j['pozycje'] ?? j['items'] ?? []) as List;
    return ParsedProjekt(
      tytul: j['tytul']?.toString() ?? j['title']?.toString(),
      powierzchniaCalkwita:
          double.tryParse(j['powierzchnia_calkowita']?.toString() ?? ''),
      liczbaKondygnacji:
          double.tryParse(j['liczba_kondygnacji']?.toString() ?? ''),
      pomieszczenia: roomsList
          .asMap()
          .entries
          .map((e) =>
              PomieszczenieProjekt.fromJson(e.value as Map<String, dynamic>, e.key))
          .toList(),
      sugerowanePozyacje: pozycjeList
          .map((p) => SugerowanaPozyacja.fromJson(p as Map<String, dynamic>))
          .toList(),
      uwagi: j['uwagi']?.toString() ?? j['notes']?.toString(),
    );
  }
}
