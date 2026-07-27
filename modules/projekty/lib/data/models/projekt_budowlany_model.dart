// ignore_for_file: invalid_annotation_target

class WymiarM {
  final double? a;
  final double? b;
  const WymiarM({this.a, this.b});
  factory WymiarM.fromJson(Map<String, dynamic> j) =>
      WymiarM(a: _d(j['a']), b: _d(j['b']));
}

class PomieszczenieProjektuModel {
  final int id;
  final String kondygnacjaId;
  final int kondygnacjaIdx;
  final String pomId;
  final String nazwa;
  final String typ;
  final double? powierzchniaM2;
  final double? wymiarAm;
  final double? wymiarBm;
  final bool wymiarySkoryg;
  final bool wymiarySpojne;
  final int? liczbaOkien;
  final int? liczbaDrzwi;
  final String? materialPodlogi;
  final String? materialSufitu;

  /// Wysokość w świetle (m) — z kondygnacji, chyba że pomieszczenie ma
  /// własną wartość (np. antresola). `null` gdy backend jej nie podał.
  final double? wysokoscM;

  const PomieszczenieProjektuModel({
    required this.id,
    required this.kondygnacjaId,
    required this.kondygnacjaIdx,
    required this.pomId,
    required this.nazwa,
    required this.typ,
    this.powierzchniaM2,
    this.wymiarAm,
    this.wymiarBm,
    this.wymiarySkoryg = false,
    this.wymiarySpojne = true,
    this.liczbaOkien,
    this.liczbaDrzwi,
    this.materialPodlogi,
    this.materialSufitu,
    this.wysokoscM,
  });

  /// Sufit skośny (poddasze) — wnioskowane z nazwy materiału sufitu
  /// (np. "plyta_GK_skosna"), bo backend nie podaje geometrii połaci.
  bool get sufitSkosny => (materialSufitu ?? '').toLowerCase().contains('skos');

  factory PomieszczenieProjektuModel.fromJson(Map<String, dynamic> j) =>
      PomieszczenieProjektuModel(
        id: j['id'] ?? 0,
        kondygnacjaId: j['kondygnacja_id'] ?? '',
        kondygnacjaIdx: j['kondygnacja_idx'] ?? 0,
        pomId: j['pom_id'] ?? '',
        nazwa: j['nazwa'] ?? '',
        typ: j['typ'] ?? '',
        powierzchniaM2: _d(j['powierzchnia_m2']),
        wymiarAm: _d(j['wymiar_a_m']),
        wymiarBm: _d(j['wymiar_b_m']),
        wymiarySkoryg: _b(j['wymiary_skorygowane'], false),
        wymiarySpojne: _b(j['wymiary_spojne'], true),
        liczbaOkien: j['liczba_okien'],
        liczbaDrzwi: j['liczba_drzwi'],
        materialPodlogi: j['material_podlogi'],
        materialSufitu: j['material_sufitu'],
        wysokoscM: _d(j['wysokosc_w_swietle_m']),
      );
}

class WalidacjaModel {
  final String priorytet; // blad | ostrzezenie | info
  final String kod;
  final String pole;
  final String opis;
  final String? wartoscZnaleziona;
  final String? wartoscOczekiwana;
  final bool naprawiono;

  const WalidacjaModel({
    required this.priorytet,
    required this.kod,
    required this.pole,
    required this.opis,
    this.wartoscZnaleziona,
    this.wartoscOczekiwana,
    this.naprawiono = false,
  });

  factory WalidacjaModel.fromJson(Map<String, dynamic> j) => WalidacjaModel(
        priorytet: j['priorytet'] ?? 'info',
        kod: j['kod'] ?? '',
        pole: j['pole'] ?? '',
        opis: j['opis'] ?? '',
        wartoscZnaleziona: j['wartosc_znaleziona']?.toString(),
        wartoscOczekiwana: j['wartosc_oczekiwana']?.toString(),
        naprawiono: _b(j['naprawiono'], false),
      );
}

class ProjektBudowlanyListModel {
  final String projektId;
  final String nazwa;
  final bool projektTypowy;
  final String? nrProjektu;
  final String? inwestorNazwa;
  final String? inwestorAdres;
  final String? dzialka;
  final String? gmina;
  final String? miejscowosc;
  final double? powierzchniaUzytkowa;
  final double? powierzchniaZabudowy;
  final double? kubatura;
  final int? liczbaKondygnacji;
  final String? status;
  final DateTime? dataAktualizacji;
  final int walidacjaBledy;
  final int walidacjaOstrzezenia;

  const ProjektBudowlanyListModel({
    required this.projektId,
    required this.nazwa,
    this.projektTypowy = false,
    this.nrProjektu,
    this.inwestorNazwa,
    this.inwestorAdres,
    this.dzialka,
    this.gmina,
    this.miejscowosc,
    this.powierzchniaUzytkowa,
    this.powierzchniaZabudowy,
    this.kubatura,
    this.liczbaKondygnacji,
    this.status,
    this.dataAktualizacji,
    this.walidacjaBledy = 0,
    this.walidacjaOstrzezenia = 0,
  });

  factory ProjektBudowlanyListModel.fromJson(Map<String, dynamic> j) =>
      ProjektBudowlanyListModel(
        projektId: j['projekt_id'] ?? '',
        nazwa: j['nazwa'] ?? '',
        projektTypowy: _b(j['projekt_typowy'], false),
        nrProjektu: j['nr_projektu'],
        inwestorNazwa: j['inwestor_nazwa'],
        inwestorAdres: j['inwestor_adres'],
        dzialka: j['dzialka_nr'],
        gmina: j['gmina'],
        miejscowosc: j['miejscowosc'],
        powierzchniaUzytkowa: _d(j['powierzchnia_uzytkowa_m2']),
        powierzchniaZabudowy: _d(j['powierzchnia_zabudowy_m2']),
        kubatura: _d(j['kubatura_m3']),
        liczbaKondygnacji: j['liczba_kondygnacji'],
        status: j['status'],
        dataAktualizacji: j['data_aktualizacji'] != null
            ? DateTime.tryParse(j['data_aktualizacji'])
            : null,
        walidacjaBledy: j['walidacja_bledy'] ?? 0,
        walidacjaOstrzezenia: j['walidacja_ostrzezenia'] ?? 0,
      );
}

class ProjektBudowlanyDetailModel extends ProjektBudowlanyListModel {
  final Map<String, dynamic> daneJson;
  final List<PomieszczenieProjektuModel> pomieszczenia;
  final List<WalidacjaModel> walidacje;

  const ProjektBudowlanyDetailModel({
    required super.projektId,
    required super.nazwa,
    super.projektTypowy,
    super.nrProjektu,
    super.inwestorNazwa,
    super.inwestorAdres,
    super.dzialka,
    super.gmina,
    super.miejscowosc,
    super.powierzchniaUzytkowa,
    super.powierzchniaZabudowy,
    super.kubatura,
    super.liczbaKondygnacji,
    super.status,
    super.dataAktualizacji,
    super.walidacjaBledy,
    super.walidacjaOstrzezenia,
    required this.daneJson,
    this.pomieszczenia = const [],
    this.walidacje = const [],
  });

  factory ProjektBudowlanyDetailModel.fromJson(Map<String, dynamic> j) {
    final base = ProjektBudowlanyListModel.fromJson(j);
    return ProjektBudowlanyDetailModel(
      projektId: base.projektId,
      nazwa: base.nazwa,
      projektTypowy: base.projektTypowy,
      nrProjektu: base.nrProjektu,
      inwestorNazwa: base.inwestorNazwa,
      inwestorAdres: base.inwestorAdres,
      dzialka: base.dzialka,
      gmina: base.gmina,
      miejscowosc: base.miejscowosc,
      powierzchniaUzytkowa: base.powierzchniaUzytkowa,
      powierzchniaZabudowy: base.powierzchniaZabudowy,
      kubatura: base.kubatura,
      liczbaKondygnacji: base.liczbaKondygnacji,
      status: base.status,
      dataAktualizacji: base.dataAktualizacji,
      walidacjaBledy: base.walidacjaBledy,
      walidacjaOstrzezenia: base.walidacjaOstrzezenia,
      daneJson: (j['dane_json'] as Map<String, dynamic>?) ?? {},
      pomieszczenia: (j['pomieszczenia'] as List<dynamic>? ?? [])
          .map((e) => PomieszczenieProjektuModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      walidacje: (j['walidacje'] as List<dynamic>? ?? [])
          .map((e) => WalidacjaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Kosztorys ─────────────────────────────────────────────────────────────────

class KosztorysPozycjaApiModel {
  final int lp;
  final String dzial;
  final String opis;
  final String? knr;
  final String jednostka;
  final double ilosc;
  final double cenaJednNetto;
  final double wartoscNetto;
  final String? uwagi;
  // Rozbicie składników
  final double? robocizna;
  final double? materialy;
  final double? sprzet;
  final double? kp;
  final double? z;
  final double? rbh;

  const KosztorysPozycjaApiModel({
    required this.lp,
    required this.dzial,
    required this.opis,
    this.knr,
    required this.jednostka,
    required this.ilosc,
    required this.cenaJednNetto,
    required this.wartoscNetto,
    this.uwagi,
    this.robocizna,
    this.materialy,
    this.sprzet,
    this.kp,
    this.z,
    this.rbh,
  });

  bool get hasBreakdown => robocizna != null;

  factory KosztorysPozycjaApiModel.fromJson(Map<String, dynamic> j) =>
      KosztorysPozycjaApiModel(
        lp: j['lp'] ?? 0,
        dzial: j['dzial'] ?? '',
        opis: j['opis'] ?? '',
        knr: j['knr'],
        jednostka: j['jednostka'] ?? '',
        ilosc: _d(j['ilosc']) ?? 0,
        cenaJednNetto: _d(j['cena_jedn_netto']) ?? 0,
        wartoscNetto: _d(j['wartosc_netto']) ?? 0,
        uwagi: (j['uwagi'] as String?)?.trim().isEmpty ?? true ? null : j['uwagi'] as String,
        robocizna: _d(j['robocizna_netto']),
        materialy: _d(j['materialy_netto']),
        sprzet: _d(j['sprzet_netto']),
        kp: _d(j['kp_netto']),
        z: _d(j['z_netto']),
        rbh: _d(j['rbh']),
      );

  KosztorysPozycjaApiModel copyWithCena(double newCena) =>
      KosztorysPozycjaApiModel(
        lp: lp, dzial: dzial, opis: opis, knr: knr, jednostka: jednostka,
        ilosc: ilosc,
        cenaJednNetto: newCena,
        wartoscNetto: ilosc * newCena,
        uwagi: uwagi,
        robocizna: robocizna, materialy: materialy, sprzet: sprzet,
        kp: kp, z: z, rbh: rbh,
      );
}

class KosztorysSkladnikiModel {
  final double robocizna;
  final double materialy;
  final double sprzet;
  final double kp;
  final double z;
  final double razem;
  final double razemRbh;

  const KosztorysSkladnikiModel({
    required this.robocizna,
    required this.materialy,
    required this.sprzet,
    required this.kp,
    required this.z,
    required this.razem,
    required this.razemRbh,
  });

  factory KosztorysSkladnikiModel.fromJson(Map<String, dynamic> j) =>
      KosztorysSkladnikiModel(
        robocizna: _d(j['robocizna_netto']) ?? 0,
        materialy: _d(j['materialy_netto']) ?? 0,
        sprzet: _d(j['sprzet_netto']) ?? 0,
        kp: _d(j['kp_netto']) ?? 0,
        z: _d(j['z_netto']) ?? 0,
        razem: _d(j['razem_netto']) ?? 0,
        razemRbh: _d(j['razem_rbh']) ?? 0,
      );
}

class KosztorysPodsumowanieModel {
  final double sumaNetto;
  final double vat23;
  final double brutto;
  final Map<String, double> dzialy;
  final String? uwaga;
  final KosztorysSkladnikiModel? skladniki;

  const KosztorysPodsumowanieModel({
    required this.sumaNetto,
    required this.vat23,
    required this.brutto,
    required this.dzialy,
    this.uwaga,
    this.skladniki,
  });

  factory KosztorysPodsumowanieModel.fromJson(Map<String, dynamic> j) =>
      KosztorysPodsumowanieModel(
        sumaNetto: _d(j['suma_netto']) ?? 0,
        vat23: _d(j['vat_23_procent']) ?? 0,
        brutto: _d(j['brutto']) ?? 0,
        dzialy: (j['dzialy'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, _d(v) ?? 0.0),
        ),
        uwaga: j['uwaga'],
        skladniki: j['skladniki'] != null
            ? KosztorysSkladnikiModel.fromJson(j['skladniki'] as Map<String, dynamic>)
            : null,
      );
}

class KosztorysApiModel {
  final List<KosztorysPozycjaApiModel> pozycje;
  final KosztorysPodsumowanieModel podsumowanie;

  const KosztorysApiModel({required this.pozycje, required this.podsumowanie});

  factory KosztorysApiModel.fromJson(Map<String, dynamic> j) => KosztorysApiModel(
        pozycje: (j['pozycje'] as List<dynamic>? ?? [])
            .map((e) => KosztorysPozycjaApiModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        podsumowanie: KosztorysPodsumowanieModel.fromJson(
            j['podsumowanie'] as Map<String, dynamic>? ?? {}),
      );
}

// ── helpers ───────────────────────────────────────────────────────────────────

double? _d(dynamic v) =>
    v == null ? null : double.tryParse(v.toString());

bool _b(dynamic v, bool fallback) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}
