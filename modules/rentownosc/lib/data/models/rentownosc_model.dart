enum KategoriaCosztu { robocizna, material, sprzet, podwykonawcy, kosztyOgolne, inne }

extension KategoriaCosztuExt on KategoriaCosztu {
  String get apiValue => name;
  String get label => switch (this) {
        KategoriaCosztu.robocizna => 'Robocizna',
        KategoriaCosztu.material => 'Materiały',
        KategoriaCosztu.sprzet => 'Sprzęt',
        KategoriaCosztu.podwykonawcy => 'Podwykonawcy',
        KategoriaCosztu.kosztyOgolne => 'Koszty ogólne',
        KategoriaCosztu.inne => 'Inne',
      };
  String get emoji => switch (this) {
        KategoriaCosztu.robocizna => '👷',
        KategoriaCosztu.material => '🧱',
        KategoriaCosztu.sprzet => '🔧',
        KategoriaCosztu.podwykonawcy => '🤝',
        KategoriaCosztu.kosztyOgolne => '🏢',
        KategoriaCosztu.inne => '💼',
      };
  static KategoriaCosztu fromApi(String v) => KategoriaCosztu.values
      .firstWhere((e) => e.name == v, orElse: () => KategoriaCosztu.inne);
}

// ---- Wpis kosztu ----

class KosztModel {
  final int id;
  final int budowaId;
  final KategoriaCosztu kategoria;
  final String opis;
  final double kwota;
  final DateTime data;
  final String? dokument;

  const KosztModel({
    required this.id,
    required this.budowaId,
    required this.kategoria,
    required this.opis,
    required this.kwota,
    required this.data,
    this.dokument,
  });

  factory KosztModel.fromJson(Map<String, dynamic> j) => KosztModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        kategoria: KategoriaCosztuExt.fromApi(j['kategoria'] ?? ''),
        opis: j['opis'] ?? '',
        kwota: double.tryParse(j['kwota']?.toString() ?? '0') ?? 0,
        data: DateTime.tryParse(j['data'] ?? '') ?? DateTime.now(),
        dokument: j['dokument'],
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'kategoria': kategoria.apiValue,
        'opis': opis,
        'kwota': kwota,
        'data': data.toIso8601String(),
        if (dokument != null) 'dokument': dokument,
      };
}

// ---- Analiza rentowności budowy ----

class RentownoscBudowyModel {
  final int budowaId;
  final String budowaNazwa;
  final double wartoscKontraktu;
  final double przychodyFaktury;
  final double kosztyLacznie;
  final Map<KategoriaCosztu, double> kosztyPerKategoria;
  final double przychodyOczekiwane;

  const RentownoscBudowyModel({
    required this.budowaId,
    required this.budowaNazwa,
    required this.wartoscKontraktu,
    required this.przychodFaktury,
    required this.kosztyLacznie,
    required this.kosztyPerKategoria,
    required this.przychodyOczekiwane,
  }) : przychodBrutto = przychodFaktury;

  // ignore: unused_field
  final double przychodBrutto;

  factory RentownoscBudowyModel.fromJson(Map<String, dynamic> j) {
    final katMap = <KategoriaCosztu, double>{};
    final perKat = j['koszty_per_kategoria'] as Map<String, dynamic>? ?? {};
    for (final e in perKat.entries) {
      final kat = KategoriaCosztuExt.fromApi(e.key);
      katMap[kat] = double.tryParse(e.value?.toString() ?? '0') ?? 0;
    }
    return RentownoscBudowyModel(
      budowaId: j['budowa_id'] ?? 0,
      budowaNazwa: j['budowa_nazwa'] ?? '',
      wartoscKontraktu: double.tryParse(j['wartosc_kontraktu']?.toString() ?? '0') ?? 0,
      przychodFaktury: double.tryParse(j['przychody_faktury']?.toString() ?? '0') ?? 0,
      kosztyLacznie: double.tryParse(j['koszty_lacznie']?.toString() ?? '0') ?? 0,
      kosztyPerKategoria: katMap,
      przychodyOczekiwane:
          double.tryParse(j['przychody_oczekiwane']?.toString() ?? '0') ?? 0,
    );
  }

  double get zyskBrutto => przychodBrutto - kosztyLacznie;
  double get marza => przychodBrutto > 0 ? zyskBrutto / przychodBrutto : 0;
  double get marzaOczekiwana =>
      wartoscKontraktu > 0 ? (wartoscKontraktu - kosztyLacznie) / wartoscKontraktu : 0;
  bool get naMinusie => zyskBrutto < 0;
}
