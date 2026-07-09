enum BranzaTyp {
  elektryczna,
  hydrauliczna,
  budowlana,
  fundamenty,
  dach,
  stolarska,
  wykanczanie,
  podlogi,
  elewacja,
  instalacje_co,
  wentylacja,
  geodezja,
  projekt,
  kierownik,
  inspektor,
  transport,
  inna;

  static BranzaTyp? fromApi(String? v) {
    if (v == null || v.isEmpty) return null;
    try {
      return BranzaTyp.values.firstWhere((e) => e.name == v);
    } catch (_) {
      return inna;
    }
  }

  String get label => switch (this) {
        elektryczna => 'Elektryczna',
        hydrauliczna => 'Hydrauliczna / wod-kan',
        budowlana => 'Budowlana / murarstwo',
        fundamenty => 'Fundamenty / ziemna',
        dach => 'Dach / pokrycia',
        stolarska => 'Stolarka / okna-drzwi',
        wykanczanie => 'Wykańczanie / tynki',
        podlogi => 'Podłogi',
        elewacja => 'Elewacja / ocieplenie',
        instalacje_co => 'Instalacje CO / gaz',
        wentylacja => 'Wentylacja / klimat.',
        geodezja => 'Geodezja',
        projekt => 'Projektant / architekt',
        kierownik => 'Kierownik budowy',
        inspektor => 'Inspektor nadzoru',
        transport => 'Transport / logistyka',
        inna => 'Inna',
      };

  String get emoji => switch (this) {
        elektryczna => '⚡',
        hydrauliczna => '🔧',
        budowlana => '🧱',
        fundamenty => '⛏️',
        dach => '🏠',
        stolarska => '🚪',
        wykanczanie => '🪣',
        podlogi => '🪵',
        elewacja => '🏗️',
        instalacje_co => '🔥',
        wentylacja => '💨',
        geodezja => '📐',
        projekt => '📐',
        kierownik => '👷',
        inspektor => '🔍',
        transport => '🚛',
        inna => '🔩',
      };
}

enum StatusPowiazania {
  zaproszony,
  aktywny,
  zakonczony,
  odrzucony;

  static StatusPowiazania fromApi(String v) =>
      StatusPowiazania.values.firstWhere((e) => e.name == v,
          orElse: () => aktywny);

  String get label => switch (this) {
        zaproszony => 'Zaproszony',
        aktywny => 'Aktywny',
        zakonczony => 'Zakończony',
        odrzucony => 'Odrzucony',
      };
}

class KontrahentModel {
  final int id;
  final String displayName;
  final String firma;
  final String imie;
  final String nazwisko;
  final String email;
  final String telefon;
  final String nip;
  final String adres;
  final BranzaTyp? branza;
  final String uwagi;
  final String? avatarUrl;

  const KontrahentModel({
    required this.id,
    required this.displayName,
    required this.firma,
    required this.imie,
    required this.nazwisko,
    required this.email,
    required this.telefon,
    required this.nip,
    required this.adres,
    this.branza,
    required this.uwagi,
    this.avatarUrl,
  });

  factory KontrahentModel.fromJson(Map<String, dynamic> j) => KontrahentModel(
        id: j['id'] as int,
        displayName: j['display_name'] as String? ?? '',
        firma: j['firma'] as String? ?? '',
        imie: j['imie'] as String? ?? '',
        nazwisko: j['nazwisko'] as String? ?? '',
        email: j['email'] as String? ?? '',
        telefon: j['telefon'] as String? ?? '',
        nip: j['nip'] as String? ?? '',
        adres: j['adres'] as String? ?? '',
        branza: BranzaTyp.fromApi(j['branza'] as String?),
        uwagi: j['uwagi'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
      );
}

class PowiazanieModel {
  final int id;
  final KontrahentModel kontrahent;
  final int? etapId;
  final String? etapNazwa;
  final String rola;
  final StatusPowiazania status;
  final double? wartoscUmowy;
  final DateTime? dataOd;
  final DateTime? dataDo;
  final String uwagi;

  const PowiazanieModel({
    required this.id,
    required this.kontrahent,
    this.etapId,
    this.etapNazwa,
    required this.rola,
    required this.status,
    this.wartoscUmowy,
    this.dataOd,
    this.dataDo,
    required this.uwagi,
  });

  factory PowiazanieModel.fromJson(Map<String, dynamic> j) => PowiazanieModel(
        id: j['id'] as int,
        kontrahent: KontrahentModel.fromJson(
            j['kontrahent'] as Map<String, dynamic>),
        etapId: j['etap'] as int?,
        etapNazwa: j['etap_nazwa'] as String?,
        rola: j['rola'] as String? ?? '',
        status: StatusPowiazania.fromApi(j['status'] as String? ?? 'aktywny'),
        wartoscUmowy: (j['wartosc_umowy'] as num?)?.toDouble(),
        dataOd: j['data_od'] != null
            ? DateTime.tryParse(j['data_od'] as String)
            : null,
        dataDo: j['data_do'] != null
            ? DateTime.tryParse(j['data_do'] as String)
            : null,
        uwagi: j['uwagi'] as String? ?? '',
      );
}
