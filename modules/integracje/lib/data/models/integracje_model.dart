// ---- GUS/CEIDG — dane firmy ----

class FirmaGusModel {
  final String nip;
  final String nazwa;
  final String regon;
  final String? krs;
  final String adres;
  final String? formaPrawna;
  final bool aktywna;

  const FirmaGusModel({
    required this.nip,
    required this.nazwa,
    required this.regon,
    this.krs,
    required this.adres,
    this.formaPrawna,
    required this.aktywna,
  });

  factory FirmaGusModel.fromJson(Map<String, dynamic> j) => FirmaGusModel(
        nip: j['nip'] ?? '',
        nazwa: j['nazwa'] ?? '',
        regon: j['regon'] ?? '',
        krs: j['krs'],
        adres: j['adres'] ?? '',
        formaPrawna: j['forma_prawna'],
        aktywna: j['aktywna'] ?? true,
      );
}

// ---- KSeF — status faktury ----

enum StatusKsef { niezgloszona, oczekuje, przyjeta, odrzucona, blad }

extension StatusKsefExt on StatusKsef {
  String get label => switch (this) {
        StatusKsef.niezgloszona => 'Niezgłoszona',
        StatusKsef.oczekuje => 'Oczekuje',
        StatusKsef.przyjeta => 'Przyjęta',
        StatusKsef.odrzucona => 'Odrzucona',
        StatusKsef.blad => 'Błąd',
      };
  static StatusKsef fromApi(String v) =>
      StatusKsef.values.firstWhere((e) => e.name == v, orElse: () => StatusKsef.niezgloszona);
}

class KsefStatusModel {
  final String fakturaId;
  final StatusKsef status;
  final String? ksefNumer;
  final String? bladOpis;
  final DateTime? dataWysylki;

  const KsefStatusModel({
    required this.fakturaId,
    required this.status,
    this.ksefNumer,
    this.bladOpis,
    this.dataWysylki,
  });

  factory KsefStatusModel.fromJson(Map<String, dynamic> j) => KsefStatusModel(
        fakturaId: j['faktura_id']?.toString() ?? '',
        status: StatusKsefExt.fromApi(j['status'] ?? ''),
        ksefNumer: j['ksef_numer'],
        bladOpis: j['blad_opis'],
        dataWysylki: j['data_wysylki'] != null
            ? DateTime.tryParse(j['data_wysylki'])
            : null,
      );
}

// ---- e-Zamówienia — przetarg publiczny ----

class PrzetargPublicznyModel {
  final String id;
  final String tytul;
  final String zamawiajacy;
  final String? cpv;
  final DateTime terminSkladania;
  final double? wartoscSzacunkowa;
  final String url;

  const PrzetargPublicznyModel({
    required this.id,
    required this.tytul,
    required this.zamawiajacy,
    this.cpv,
    required this.terminSkladania,
    this.wartoscSzacunkowa,
    required this.url,
  });

  factory PrzetargPublicznyModel.fromJson(Map<String, dynamic> j) =>
      PrzetargPublicznyModel(
        id: j['id']?.toString() ?? '',
        tytul: j['tytul'] ?? '',
        zamawiajacy: j['zamawiajacy'] ?? '',
        cpv: j['cpv'],
        terminSkladania:
            DateTime.tryParse(j['termin_skladania'] ?? '') ?? DateTime.now(),
        wartoscSzacunkowa:
            j['wartosc_szacunkowa'] != null
                ? double.tryParse(j['wartosc_szacunkowa'].toString())
                : null,
        url: j['url'] ?? '',
      );

  bool get krotkoTerminowy =>
      terminSkladania.difference(DateTime.now()).inDays <= 7;
}
