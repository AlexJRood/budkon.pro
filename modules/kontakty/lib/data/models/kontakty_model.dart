enum Branza {
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

  static Branza fromApi(String v) =>
      Branza.values.firstWhere((e) => e.name == v, orElse: () => inna);

  String get label => switch (this) {
        elektryczna => 'Elektryczna',
        hydrauliczna => 'Hydraulika / wod-kan',
        budowlana => 'Murarstwo / budowlana',
        fundamenty => 'Fundamenty / ziemna',
        dach => 'Dach / pokrycia',
        stolarska => 'Stolarka / okna-drzwi',
        wykanczanie => 'Wykańczanie / tynki',
        podlogi => 'Podłogi',
        elewacja => 'Elewacja / ocieplenie',
        instalacje_co => 'CO / gaz',
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
        wykanczanie => '🖌️',
        podlogi => '🟫',
        elewacja => '🏗️',
        instalacje_co => '🔥',
        wentylacja => '💨',
        geodezja => '📐',
        projekt => '📋',
        kierownik => '👷',
        inspektor => '🔍',
        transport => '🚛',
        inna => '📁',
      };
}

class KontrahentListItem {
  final int id;
  final String imie;
  final String nazwisko;
  final String firma;
  final String email;
  final String telefon;
  final String nip;
  final Branza? branza;
  final String? avatarUrl;

  const KontrahentListItem({
    required this.id,
    this.imie = '',
    this.nazwisko = '',
    this.firma = '',
    this.email = '',
    this.telefon = '',
    this.nip = '',
    this.branza,
    this.avatarUrl,
  });

  String get displayName =>
      firma.isNotEmpty ? firma : pelneImie.isNotEmpty ? pelneImie : 'Kontrahent #$id';

  String get pelneImie => [imie, nazwisko].where((s) => s.isNotEmpty).join(' ');

  String get inicjaly {
    if (firma.isNotEmpty) return firma.substring(0, firma.length >= 2 ? 2 : 1).toUpperCase();
    final i = imie.isNotEmpty ? imie[0] : '';
    final n = nazwisko.isNotEmpty ? nazwisko[0] : '';
    return (i + n).toUpperCase();
  }

  factory KontrahentListItem.fromJson(Map<String, dynamic> j) => KontrahentListItem(
        id: j['id'] as int,
        imie: j['imie'] as String? ?? '',
        nazwisko: j['nazwisko'] as String? ?? '',
        firma: j['firma'] as String? ?? '',
        email: j['email'] as String? ?? '',
        telefon: j['telefon'] as String? ?? '',
        nip: j['nip'] as String? ?? '',
        branza: j['branza'] != null && (j['branza'] as String).isNotEmpty
            ? Branza.fromApi(j['branza'] as String)
            : null,
        avatarUrl: j['avatar'] as String?,
      );
}

class KontrahentDetail extends KontrahentListItem {
  final String adres;
  final String uwagi;

  const KontrahentDetail({
    required super.id,
    super.imie,
    super.nazwisko,
    super.firma,
    super.email,
    super.telefon,
    super.nip,
    super.branza,
    super.avatarUrl,
    required this.adres,
    required this.uwagi,
  });

  factory KontrahentDetail.fromJson(Map<String, dynamic> j) {
    final base = KontrahentListItem.fromJson(j);
    return KontrahentDetail(
      id: base.id,
      imie: base.imie,
      nazwisko: base.nazwisko,
      firma: base.firma,
      email: base.email,
      telefon: base.telefon,
      nip: base.nip,
      branza: base.branza,
      avatarUrl: base.avatarUrl,
      adres: j['adres'] as String? ?? '',
      uwagi: j['uwagi'] as String? ?? '',
    );
  }
}
