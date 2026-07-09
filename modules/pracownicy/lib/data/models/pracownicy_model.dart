enum Specjalizacja {
  murarz('murarz', 'Murarz', '🧱'),
  zbrojarz('zbrojarz', 'Zbrojarz / betoniar', '⚙️'),
  ciesla('ciesla', 'Cieśla', '🪵'),
  dekarz('dekarz', 'Dekarz', '🏗️'),
  tynkarz('tynkarz', 'Tynkarz / glazurnik', '🎨'),
  instalatorWodKan('instalator_wod_kan', 'Instalator wod-kan', '🔧'),
  elektryk('elektryk', 'Elektryk', '⚡'),
  spawacz('spawacz', 'Spawacz', '🔥'),
  operatorSprzetu('operator', 'Operator sprzętu', '🚜'),
  kierownik('kierownik', 'Kierownik budowy', '📋'),
  geodeta('geodeta', 'Geodeta', '📐'),
  pomocnik('pomocnik', 'Pomocnik budowlany', '👷'),
  inne('inne', 'Inne', '🔩');

  final String value;
  final String label;
  final String emoji;
  const Specjalizacja(this.value, this.label, this.emoji);

  static Specjalizacja fromValue(String v) => Specjalizacja.values.firstWhere(
        (e) => e.value == v,
        orElse: () => Specjalizacja.inne,
      );
}

enum PoziomDoswiadczenia {
  uczen('uczen', 'Uczeń / staż', 1, 0.6),
  junior('junior', 'Junior (1-3 lata)', 2, 0.8),
  mid('mid', 'Samodzielny (3-8 lat)', 3, 1.0),
  senior('senior', 'Senior (8-15 lat)', 4, 1.3),
  ekspert('ekspert', 'Ekspert (15+ lat)', 5, 1.6);

  final String value;
  final String label;
  final int rank;
  final double mnoznik;
  const PoziomDoswiadczenia(this.value, this.label, this.rank, this.mnoznik);

  static PoziomDoswiadczenia fromValue(String v) =>
      PoziomDoswiadczenia.values.firstWhere(
        (e) => e.value == v,
        orElse: () => PoziomDoswiadczenia.mid,
      );
}

class UmiejetnoscModel {
  final int id;
  final Specjalizacja specjalizacja;
  final PoziomDoswiadczenia poziom;
  final int lataDowiadczenia;
  final String certyfikat;
  final String numerCertyfikatu;
  final String? certyfikatWaznyDo;
  final bool certyfikatWazny;
  final double? stawkaSpecjalizacji;
  final double mnoznik;
  final String uwagi;

  const UmiejetnoscModel({
    required this.id,
    required this.specjalizacja,
    required this.poziom,
    required this.lataDowiadczenia,
    this.certyfikat = '',
    this.numerCertyfikatu = '',
    this.certyfikatWaznyDo,
    this.certyfikatWazny = true,
    this.stawkaSpecjalizacji,
    this.mnoznik = 1.0,
    this.uwagi = '',
  });

  factory UmiejetnoscModel.fromJson(Map<String, dynamic> j) => UmiejetnoscModel(
        id: j['id'] as int,
        specjalizacja:
            Specjalizacja.fromValue((j['specjalizacja'] ?? '').toString()),
        poziom: PoziomDoswiadczenia.fromValue((j['poziom'] ?? 'mid').toString()),
        lataDowiadczenia: (j['lata_doswiadczenia'] as num?)?.toInt() ?? 0,
        certyfikat: (j['certyfikat'] ?? '').toString(),
        numerCertyfikatu: (j['numer_certyfikatu'] ?? '').toString(),
        certyfikatWaznyDo: j['certyfikat_wazny_do']?.toString(),
        certyfikatWazny: j['certyfikat_wazny'] as bool? ?? true,
        stawkaSpecjalizacji:
            (j['stawka_specjalizacji'] as num?)?.toDouble(),
        mnoznik: (j['mnoznik'] as num?)?.toDouble() ?? 1.0,
        uwagi: (j['uwagi'] ?? '').toString(),
      );
}

class HistoriaStawkiModel {
  final int id;
  final double stawkaGodz;
  final String waluta;
  final String dataOd;

  const HistoriaStawkiModel({
    required this.id,
    required this.stawkaGodz,
    required this.waluta,
    required this.dataOd,
  });

  factory HistoriaStawkiModel.fromJson(Map<String, dynamic> j) =>
      HistoriaStawkiModel(
        id: j['id'] as int,
        stawkaGodz: (j['stawka_godz'] as num).toDouble(),
        waluta: (j['waluta'] ?? 'PLN').toString(),
        dataOd: j['data_od'].toString(),
      );
}

class PracownikListItem {
  final int id;
  final String imie;
  final String nazwisko;
  final String pelneImie;
  final String telefon;
  final String email;
  final Specjalizacja glownaSpecjalizacja;
  final bool aktywny;
  final String typUmowy;
  final double? aktualnaStawka;
  final List<Map<String, dynamic>> specjalizacje; // skrót

  const PracownikListItem({
    required this.id,
    required this.imie,
    required this.nazwisko,
    required this.pelneImie,
    required this.telefon,
    required this.email,
    required this.glownaSpecjalizacja,
    required this.aktywny,
    required this.typUmowy,
    this.aktualnaStawka,
    this.specjalizacje = const [],
  });

  factory PracownikListItem.fromJson(Map<String, dynamic> j) =>
      PracownikListItem(
        id: j['id'] as int,
        imie: (j['imie'] ?? '').toString(),
        nazwisko: (j['nazwisko'] ?? '').toString(),
        pelneImie: (j['pelne_imie'] ?? '').toString(),
        telefon: (j['telefon'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        glownaSpecjalizacja: Specjalizacja.fromValue(
            (j['glowna_specjalizacja'] ?? 'inne').toString()),
        aktywny: j['aktywny'] as bool? ?? true,
        typUmowy: (j['typ_umowy'] ?? '').toString(),
        aktualnaStawka: (j['aktualna_stawka'] as num?)?.toDouble(),
        specjalizacje:
            (j['specjalizacje'] as List? ?? []).cast<Map<String, dynamic>>(),
      );

  String get inicjaly {
    final i = imie.isNotEmpty ? imie[0] : '';
    final n = nazwisko.isNotEmpty ? nazwisko[0] : '';
    return '$i$n'.toUpperCase();
  }
}

class PracownikDetail extends PracownikListItem {
  final List<UmiejetnoscModel> umiejetnosci;
  final List<HistoriaStawkiModel> historiaStawek;
  final String? dataZatrudnienia;
  final String uwagi;

  const PracownikDetail({
    required super.id,
    required super.imie,
    required super.nazwisko,
    required super.pelneImie,
    required super.telefon,
    required super.email,
    required super.glownaSpecjalizacja,
    required super.aktywny,
    required super.typUmowy,
    super.aktualnaStawka,
    super.specjalizacje,
    this.umiejetnosci = const [],
    this.historiaStawek = const [],
    this.dataZatrudnienia,
    this.uwagi = '',
  });

  factory PracownikDetail.fromJson(Map<String, dynamic> j) => PracownikDetail(
        id: j['id'] as int,
        imie: (j['imie'] ?? '').toString(),
        nazwisko: (j['nazwisko'] ?? '').toString(),
        pelneImie: (j['pelne_imie'] ?? '').toString(),
        telefon: (j['telefon'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        glownaSpecjalizacja: Specjalizacja.fromValue(
            (j['glowna_specjalizacja'] ?? 'inne').toString()),
        aktywny: j['aktywny'] as bool? ?? true,
        typUmowy: (j['typ_umowy'] ?? '').toString(),
        aktualnaStawka: (j['aktualna_stawka'] as num?)?.toDouble(),
        specjalizacje:
            (j['specjalizacje'] as List? ?? []).cast<Map<String, dynamic>>(),
        umiejetnosci: (j['umiejetnosci'] as List? ?? [])
            .map((e) => UmiejetnoscModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        historiaStawek: (j['historia_stawek'] as List? ?? [])
            .map((e) =>
                HistoriaStawkiModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        dataZatrudnienia: j['data_zatrudnienia']?.toString(),
        uwagi: (j['uwagi'] ?? '').toString(),
      );

  /// Efektywna stawka dla konkretnej specjalizacji
  double? stawkaForSpec(Specjalizacja spec) {
    final um = umiejetnosci.firstWhere(
      (u) => u.specjalizacja == spec,
      orElse: () => UmiejetnoscModel(
        id: 0,
        specjalizacja: spec,
        poziom: PoziomDoswiadczenia.mid,
        lataDowiadczenia: 0,
      ),
    );
    if (um.stawkaSpecjalizacji != null) return um.stawkaSpecjalizacji;
    if (aktualnaStawka != null) return aktualnaStawka! * um.mnoznik;
    return null;
  }
}
