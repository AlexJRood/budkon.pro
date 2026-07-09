enum StatusOferty {
  roboczy('roboczy', 'Roboczy'),
  wyslana('wyslana', 'Wysłana'),
  zaakceptowana('zaakceptowana', 'Zaakceptowana'),
  odrzucona('odrzucona', 'Odrzucona'),
  wygasla('wygasla', 'Wygasła');

  final String value;
  final String label;
  const StatusOferty(this.value, this.label);

  static StatusOferty fromValue(String v) => StatusOferty.values.firstWhere(
        (e) => e.value == v,
        orElse: () => StatusOferty.roboczy,
      );
}

class PozycjaOferty {
  final String opis;
  final String jednostka;
  final double ilosc;
  final double cenaJednostkowa;
  final double wartosc;

  const PozycjaOferty({
    required this.opis,
    required this.jednostka,
    required this.ilosc,
    required this.cenaJednostkowa,
    required this.wartosc,
  });

  factory PozycjaOferty.fromJson(Map<String, dynamic> j) => PozycjaOferty(
        opis: j['opis'].toString(),
        jednostka: j['jednostka'].toString(),
        ilosc: (j['ilosc'] as num).toDouble(),
        cenaJednostkowa: (j['cena_jednostkowa'] as num).toDouble(),
        wartosc: (j['wartosc'] as num).toDouble(),
      );
}

class DzialOferty {
  final String nazwa;
  final List<PozycjaOferty> pozycje;

  const DzialOferty({required this.nazwa, required this.pozycje});

  double get wartosc =>
      pozycje.fold(0, (sum, p) => sum + p.wartosc);

  factory DzialOferty.fromJson(Map<String, dynamic> j) => DzialOferty(
        nazwa: (j['dzial'] ?? '').toString(),
        pozycje: (j['pozycje'] as List? ?? [])
            .map((e) => PozycjaOferty.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class HistoriaStatusuModel {
  final int id;
  final StatusOferty status;
  final String data;
  final String uwagi;

  const HistoriaStatusuModel({
    required this.id,
    required this.status,
    required this.data,
    this.uwagi = '',
  });

  factory HistoriaStatusuModel.fromJson(Map<String, dynamic> j) =>
      HistoriaStatusuModel(
        id: j['id'] as int,
        status: StatusOferty.fromValue(j['status'].toString()),
        data: j['data'].toString(),
        uwagi: (j['uwagi'] ?? '').toString(),
      );
}

class OfertyListItem {
  final int id;
  final String numer;
  final String tytul;
  final String klientNazwa;
  final double wartoscNetto;
  final double wartoscBrutto;
  final StatusOferty status;
  final String dataWystawienia;
  final String? waznaDo;
  final int? budowaId;
  final int? kosztorysId;

  const OfertyListItem({
    required this.id,
    required this.numer,
    required this.tytul,
    required this.klientNazwa,
    required this.wartoscNetto,
    required this.wartoscBrutto,
    required this.status,
    required this.dataWystawienia,
    this.waznaDo,
    this.budowaId,
    this.kosztorysId,
  });

  factory OfertyListItem.fromJson(Map<String, dynamic> j) => OfertyListItem(
        id: j['id'] as int,
        numer: (j['numer'] ?? '').toString(),
        tytul: (j['tytul'] ?? '').toString(),
        klientNazwa: (j['klient_nazwa'] ?? '').toString(),
        wartoscNetto: (j['wartosc_netto'] as num? ?? 0).toDouble(),
        wartoscBrutto: (j['wartosc_brutto'] as num? ?? 0).toDouble(),
        status: StatusOferty.fromValue((j['status'] ?? 'roboczy').toString()),
        dataWystawienia: (j['data_wystawienia'] ?? '').toString(),
        waznaDo: j['wazna_do']?.toString(),
        budowaId: j['budowa_id'] as int?,
        kosztorysId: j['kosztorys_id'] as int?,
      );
}

class OfertyDetail extends OfertyListItem {
  final String klientAdres;
  final String klientNip;
  final String klientEmail;
  final String klientTelefon;
  final String wystawcaNazwa;
  final String wystawcaAdres;
  final String wystawcaNip;
  final String wystawcaEmail;
  final String wystawcaTelefon;
  final String wstep;
  final String warunki;
  final String uwagi;
  final List<DzialOferty> pozycje;
  final int vatProcent;
  final double rabatProcent;
  final double wartoscVat;
  final bool hasPdf;
  final List<HistoriaStatusuModel> historiaStatusu;

  const OfertyDetail({
    required super.id,
    required super.numer,
    required super.tytul,
    required super.klientNazwa,
    required super.wartoscNetto,
    required super.wartoscBrutto,
    required super.status,
    required super.dataWystawienia,
    super.waznaDo,
    super.budowaId,
    super.kosztorysId,
    this.klientAdres = '',
    this.klientNip = '',
    this.klientEmail = '',
    this.klientTelefon = '',
    this.wystawcaNazwa = '',
    this.wystawcaAdres = '',
    this.wystawcaNip = '',
    this.wystawcaEmail = '',
    this.wystawcaTelefon = '',
    this.wstep = '',
    this.warunki = '',
    this.uwagi = '',
    this.pozycje = const [],
    this.vatProcent = 23,
    this.rabatProcent = 0,
    this.wartoscVat = 0,
    this.hasPdf = false,
    this.historiaStatusu = const [],
  });

  factory OfertyDetail.fromJson(Map<String, dynamic> j) => OfertyDetail(
        id: j['id'] as int,
        numer: (j['numer'] ?? '').toString(),
        tytul: (j['tytul'] ?? '').toString(),
        klientNazwa: (j['klient_nazwa'] ?? '').toString(),
        wartoscNetto: (j['wartosc_netto'] as num? ?? 0).toDouble(),
        wartoscBrutto: (j['wartosc_brutto'] as num? ?? 0).toDouble(),
        wartoscVat: (j['wartosc_vat'] as num? ?? 0).toDouble(),
        status: StatusOferty.fromValue((j['status'] ?? 'roboczy').toString()),
        dataWystawienia: (j['data_wystawienia'] ?? '').toString(),
        waznaDo: j['wazna_do']?.toString(),
        budowaId: j['budowa_id'] as int?,
        kosztorysId: j['kosztorys_id'] as int?,
        klientAdres: (j['klient_adres'] ?? '').toString(),
        klientNip: (j['klient_nip'] ?? '').toString(),
        klientEmail: (j['klient_email'] ?? '').toString(),
        klientTelefon: (j['klient_telefon'] ?? '').toString(),
        wystawcaNazwa: (j['wystawca_nazwa'] ?? '').toString(),
        wystawcaAdres: (j['wystawca_adres'] ?? '').toString(),
        wystawcaNip: (j['wystawca_nip'] ?? '').toString(),
        wystawcaEmail: (j['wystawca_email'] ?? '').toString(),
        wystawcaTelefon: (j['wystawca_telefon'] ?? '').toString(),
        wstep: (j['wstep'] ?? '').toString(),
        warunki: (j['warunki'] ?? '').toString(),
        uwagi: (j['uwagi'] ?? '').toString(),
        vatProcent: (j['vat_procent'] as num?)?.toInt() ?? 23,
        rabatProcent: (j['rabat_procent'] as num? ?? 0).toDouble(),
        hasPdf: j['has_pdf'] as bool? ?? false,
        pozycje: (j['pozycje'] as List? ?? [])
            .map((e) => DzialOferty.fromJson(e as Map<String, dynamic>))
            .toList(),
        historiaStatusu: (j['historia_statusu'] as List? ?? [])
            .map((e) =>
                HistoriaStatusuModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
