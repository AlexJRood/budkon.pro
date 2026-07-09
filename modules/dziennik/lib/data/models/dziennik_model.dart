enum PogodaTyp {
  slonecznie,
  czesciowe_zachmurzenie,
  pochmurno,
  deszcz,
  burza,
  snieg,
  wiatr,
  mgla,
  mroz;

  static PogodaTyp fromApi(String v) =>
      PogodaTyp.values.firstWhere((e) => e.name == v, orElse: () => pochmurno);

  String get label => switch (this) {
        slonecznie => 'Słonecznie',
        czesciowe_zachmurzenie => 'Częściowe zachmurzenie',
        pochmurno => 'Pochmurno',
        deszcz => 'Deszcz',
        burza => 'Burza',
        snieg => 'Śnieg',
        wiatr => 'Silny wiatr',
        mgla => 'Mgła',
        mroz => 'Mróz',
      };

  String get emoji => switch (this) {
        slonecznie => '☀️',
        czesciowe_zachmurzenie => '⛅',
        pochmurno => '☁️',
        deszcz => '🌧️',
        burza => '⛈️',
        snieg => '❄️',
        wiatr => '💨',
        mgla => '🌫️',
        mroz => '🥶',
      };
}

class ObecnoscModel {
  final int? id;
  final int? contactId;
  final String imieNazwisko;
  final String rola;
  final double godziny;

  const ObecnoscModel({
    this.id,
    this.contactId,
    required this.imieNazwisko,
    required this.rola,
    required this.godziny,
  });

  factory ObecnoscModel.fromJson(Map<String, dynamic> j) => ObecnoscModel(
        id: j['id'] as int?,
        contactId: j['contact_id'] as int?,
        imieNazwisko: j['imie_nazwisko'] as String? ?? '',
        rola: j['rola'] as String? ?? '',
        godziny: (j['godziny'] as num?)?.toDouble() ?? 8,
      );

  Map<String, dynamic> toJson() => {
        if (contactId != null) 'contact_id': contactId,
        'imie_nazwisko': imieNazwisko,
        'rola': rola,
        'godziny': godziny,
      };
}

class ZdjecieModel {
  final int id;
  final String url;
  final String opis;

  const ZdjecieModel({required this.id, required this.url, required this.opis});

  factory ZdjecieModel.fromJson(Map<String, dynamic> j) => ZdjecieModel(
        id: j['id'] as int,
        url: j['url'] as String? ?? '',
        opis: j['opis'] as String? ?? '',
      );
}

class WpisListItem {
  final int id;
  final DateTime data;
  final String? etapNazwa;
  final PogodaTyp? pogoda;
  final double? temperatura;
  final double? predkoscWiatru;
  final double? opady;
  final bool pogodaAuto;
  final double godzinyPracy;
  final int liczbaPracownikow;
  final String opis;
  final int zdjeciaCount;

  const WpisListItem({
    required this.id,
    required this.data,
    this.etapNazwa,
    this.pogoda,
    this.temperatura,
    this.predkoscWiatru,
    this.opady,
    required this.pogodaAuto,
    required this.godzinyPracy,
    required this.liczbaPracownikow,
    required this.opis,
    required this.zdjeciaCount,
  });

  factory WpisListItem.fromJson(Map<String, dynamic> j) => WpisListItem(
        id: j['id'] as int,
        data: DateTime.parse(j['data'] as String),
        etapNazwa: j['etap_nazwa'] as String?,
        pogoda: j['pogoda'] != null && (j['pogoda'] as String).isNotEmpty
            ? PogodaTyp.fromApi(j['pogoda'] as String)
            : null,
        temperatura: (j['temperatura'] as num?)?.toDouble(),
        predkoscWiatru: (j['predkosc_wiatru'] as num?)?.toDouble(),
        opady: (j['opady'] as num?)?.toDouble(),
        pogodaAuto: j['pogoda_auto'] as bool? ?? false,
        godzinyPracy: (j['godziny_pracy'] as num?)?.toDouble() ?? 0,
        liczbaPracownikow: j['liczba_pracownikow'] as int? ?? 0,
        opis: j['opis'] as String? ?? '',
        zdjeciaCount: j['zdjecia_count'] as int? ?? 0,
      );
}

class WpisDetail extends WpisListItem {
  final int budowaId;
  final int? etapId;
  final String uwagi;
  final List<ObecnoscModel> obecnosci;
  final List<ZdjecieModel> zdjecia;

  const WpisDetail({
    required super.id,
    required super.data,
    super.etapNazwa,
    super.pogoda,
    super.temperatura,
    super.predkoscWiatru,
    super.opady,
    required super.pogodaAuto,
    required super.godzinyPracy,
    required super.liczbaPracownikow,
    required super.opis,
    required super.zdjeciaCount,
    required this.budowaId,
    this.etapId,
    required this.uwagi,
    required this.obecnosci,
    required this.zdjecia,
  });

  factory WpisDetail.fromJson(Map<String, dynamic> j) {
    final base = WpisListItem.fromJson(j);
    return WpisDetail(
      id: base.id,
      data: base.data,
      etapNazwa: base.etapNazwa,
      pogoda: base.pogoda,
      temperatura: base.temperatura,
      predkoscWiatru: base.predkoscWiatru,
      opady: base.opady,
      pogodaAuto: base.pogodaAuto,
      godzinyPracy: base.godzinyPracy,
      liczbaPracownikow: base.liczbaPracownikow,
      opis: base.opis,
      zdjeciaCount: base.zdjeciaCount,
      budowaId: j['budowa_id'] as int,
      etapId: j['etap_id'] as int?,
      uwagi: j['uwagi'] as String? ?? '',
      obecnosci: (j['obecnosci'] as List? ?? [])
          .map((e) => ObecnoscModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      zdjecia: (j['zdjecia'] as List? ?? [])
          .map((e) => ZdjecieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AutoUzupelnijData {
  final PogodaTyp? pogoda;
  final double? temperatura;
  final double? predkoscWiatru;
  final double? opady;
  final DateTime data;
  final int? etapId;
  final String? etapNazwa;
  final int liczbaPracownikowPoprzedni;
  final List<ObecnoscModel> obecnosciPoprzednie;

  const AutoUzupelnijData({
    this.pogoda,
    this.temperatura,
    this.predkoscWiatru,
    this.opady,
    required this.data,
    this.etapId,
    this.etapNazwa,
    required this.liczbaPracownikowPoprzedni,
    required this.obecnosciPoprzednie,
  });

  factory AutoUzupelnijData.fromJson(Map<String, dynamic> j) =>
      AutoUzupelnijData(
        pogoda: j['pogoda'] != null && (j['pogoda'] as String).isNotEmpty
            ? PogodaTyp.fromApi(j['pogoda'] as String)
            : null,
        temperatura: (j['temperatura'] as num?)?.toDouble(),
        predkoscWiatru: (j['predkosc_wiatru'] as num?)?.toDouble(),
        opady: (j['opady'] as num?)?.toDouble(),
        data: DateTime.parse(j['data'] as String),
        etapId: j['etap_id'] as int?,
        etapNazwa: j['etap_nazwa'] as String?,
        liczbaPracownikowPoprzedni:
            j['liczba_pracownikow_poprzedni'] as int? ?? 0,
        obecnosciPoprzednie: (j['obecnosci_poprzednie'] as List? ?? [])
            .map((e) => ObecnoscModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MarketBudowlany {
  final String osmId;
  final String nazwa;
  final String adres;
  final double lat;
  final double lon;
  final String? marka;

  const MarketBudowlany({
    required this.osmId,
    required this.nazwa,
    required this.adres,
    required this.lat,
    required this.lon,
    this.marka,
  });

  factory MarketBudowlany.fromJson(Map<String, dynamic> j) => MarketBudowlany(
        osmId: j['osm_id'] as String? ?? '',
        nazwa: j['nazwa'] as String? ?? '',
        adres: j['adres'] as String? ?? '',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        marka: j['marka'] as String?,
      );

  bool get isZnanaMarka => marka != null;
}
