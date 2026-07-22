// ---- Cross-budowa overview ----

enum StatusBudowyAnalytics { wTrakcie, zakonczona, wstrzymana, planowana }

extension StatusBudowyAnalyticsExt on StatusBudowyAnalytics {
  String get label => switch (this) {
        StatusBudowyAnalytics.wTrakcie => 'W trakcie',
        StatusBudowyAnalytics.zakonczona => 'Zakończona',
        StatusBudowyAnalytics.wstrzymana => 'Wstrzymana',
        StatusBudowyAnalytics.planowana => 'Planowana',
      };

  static StatusBudowyAnalytics fromApi(String v) =>
      StatusBudowyAnalytics.values.firstWhere(
        (e) => e.name == v,
        orElse: () => StatusBudowyAnalytics.wTrakcie,
      );
}

class BudowaKartaModel {
  final int id;
  final String nazwa;
  final StatusBudowyAnalytics status;
  final double przychodCalkowity;
  final double kosztCalkowity;
  final double budzet;
  final double postepProcent;
  final DateTime dataRozpoczecia;
  final DateTime? dataZakonczenia;

  const BudowaKartaModel({
    required this.id,
    required this.nazwa,
    required this.status,
    required this.przychodCalkowity,
    required this.kosztCalkowity,
    required this.budzet,
    required this.postepProcent,
    required this.dataRozpoczecia,
    this.dataZakonczenia,
  });

  double get zysk => przychodCalkowity - kosztCalkowity;
  double get marza =>
      przychodCalkowity > 0 ? (zysk / przychodCalkowity) * 100 : 0;
  bool get naMinusie => zysk < 0;
  bool get przekroczyBudzet => kosztCalkowity > budzet;

  factory BudowaKartaModel.fromJson(Map<String, dynamic> j) => BudowaKartaModel(
        id: j['id'],
        nazwa: j['nazwa'] ?? '',
        status: StatusBudowyAnalyticsExt.fromApi(j['status'] ?? 'wTrakcie'),
        przychodCalkowity:
            double.tryParse(j['przychod_calkowity'].toString()) ?? 0,
        kosztCalkowity: double.tryParse(j['koszt_calkowity'].toString()) ?? 0,
        budzet: double.tryParse(j['budzet'].toString()) ?? 0,
        postepProcent: double.tryParse(j['postep_procent'].toString()) ?? 0,
        dataRozpoczecia: DateTime.parse(j['data_rozpoczecia']),
        dataZakonczenia: j['data_zakonczenia'] != null
            ? DateTime.tryParse(j['data_zakonczenia'])
            : null,
      );
}

// ---- Firmowe KPI ----

class FirmoweKpiModel {
  final double przychodMiesiac;
  final double przychodRok;
  final double kosztMiesiac;
  final double kosztRok;
  final double marzaSrednia;
  final int budowyAktywne;
  final int budowyZakonczone;
  final double naleznosciOgolne;
  final double zobowiazaniaOgolne;

  const FirmoweKpiModel({
    required this.przychodMiesiac,
    required this.przychodRok,
    required this.kosztMiesiac,
    required this.kosztRok,
    required this.marzaSrednia,
    required this.budowyAktywne,
    required this.budowyZakonczone,
    required this.naleznosciOgolne,
    required this.zobowiazaniaOgolne,
  });

  double get zyskMiesiac => przychodMiesiac - kosztMiesiac;
  double get zyskRok => przychodRok - kosztRok;

  factory FirmoweKpiModel.fromJson(Map<String, dynamic> j) => FirmoweKpiModel(
        przychodMiesiac:
            double.tryParse(j['przychod_miesiac'].toString()) ?? 0,
        przychodRok: double.tryParse(j['przychod_rok'].toString()) ?? 0,
        kosztMiesiac: double.tryParse(j['koszt_miesiac'].toString()) ?? 0,
        kosztRok: double.tryParse(j['koszt_rok'].toString()) ?? 0,
        marzaSrednia: double.tryParse(j['marza_srednia'].toString()) ?? 0,
        budowyAktywne: j['budowy_aktywne'] ?? 0,
        budowyZakonczone: j['budowy_zakonczone'] ?? 0,
        naleznosciOgolne:
            double.tryParse(j['naleznosci_ogolne'].toString()) ?? 0,
        zobowiazaniaOgolne:
            double.tryParse(j['zobowiazania_ogolne'].toString()) ?? 0,
      );
}

// ---- Raport miesięczny ----

class RaportMiesiecznyModel {
  final int rok;
  final int miesiac;
  final double przychod;
  final double koszt;
  final double zysk;
  final List<BudowaKartaModel> budowyWRaporcie;
  final Map<String, double> przychodPerBudowa;
  final Map<String, double> kosztPerBudowa;

  const RaportMiesiecznyModel({
    required this.rok,
    required this.miesiac,
    required this.przychod,
    required this.koszt,
    required this.zysk,
    this.budowyWRaporcie = const [],
    this.przychodPerBudowa = const {},
    this.kosztPerBudowa = const {},
  });

  String get tytul =>
      '${_miesiacNazwa(miesiac)} $rok';

  static String _miesiacNazwa(int m) => const [
        '', 'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
        'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
      ][m];

  factory RaportMiesiecznyModel.fromJson(Map<String, dynamic> j) =>
      RaportMiesiecznyModel(
        rok: j['rok'],
        miesiac: j['miesiac'],
        przychod: double.tryParse(j['przychod'].toString()) ?? 0,
        koszt: double.tryParse(j['koszt'].toString()) ?? 0,
        zysk: double.tryParse(j['zysk'].toString()) ?? 0,
        budowyWRaporcie: ((j['budowy'] ?? []) as List)
            .map((e) => BudowaKartaModel.fromJson(e))
            .toList(),
        przychodPerBudowa: Map<String, double>.from(
            (j['przychod_per_budowa'] ?? {})
                .map((k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0))),
        kosztPerBudowa: Map<String, double>.from(
            (j['koszt_per_budowa'] ?? {})
                .map((k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0))),
      );
}

// ---- Trend miesięczny (sparkline data) ----

class TrendPunktModel {
  final int rok;
  final int miesiac;
  final double wartosc;

  const TrendPunktModel(
      {required this.rok, required this.miesiac, required this.wartosc});

  factory TrendPunktModel.fromJson(Map<String, dynamic> j) => TrendPunktModel(
        rok: j['rok'],
        miesiac: j['miesiac'],
        wartosc: double.tryParse(j['wartosc'].toString()) ?? 0,
      );
}
