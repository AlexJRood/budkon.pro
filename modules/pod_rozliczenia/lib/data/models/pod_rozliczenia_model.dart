import 'package:intl/intl.dart';

enum StatusRozliczeniaPod { oczekuje, zatwierdzone, oplacone, sporne, anulowane }

extension StatusRozliczeniaPodExt on StatusRozliczeniaPod {
  String get apiValue => name;
  String get label => switch (this) {
        StatusRozliczeniaPod.oczekuje => 'Oczekuje',
        StatusRozliczeniaPod.zatwierdzone => 'Zatwierdzone',
        StatusRozliczeniaPod.oplacone => 'Opłacone',
        StatusRozliczeniaPod.sporne => 'Sporne',
        StatusRozliczeniaPod.anulowane => 'Anulowane',
      };
  static StatusRozliczeniaPod fromApi(String v) =>
      StatusRozliczeniaPod.values.firstWhere((e) => e.name == v,
          orElse: () => StatusRozliczeniaPod.oczekuje);
}

// ---- Faktura od podwykonawcy ----

class FakturaPodwykonawcyModel {
  final int id;
  final int budowaId;
  final int podwykonawcaId;
  final String podwykonawcaNazwa;
  final String numer;
  final double kwotaBrutto;
  final double kaucjaProcentowa;
  final StatusRozliczeniaPod status;
  final DateTime dataWystawienia;
  final DateTime dataTerminu;
  final DateTime? dataOplaty;
  final String opis;

  const FakturaPodwykonawcyModel({
    required this.id,
    required this.budowaId,
    required this.podwykonawcaId,
    required this.podwykonawcaNazwa,
    required this.numer,
    required this.kwotaBrutto,
    this.kaucjaProcentowa = 5,
    this.status = StatusRozliczeniaPod.oczekuje,
    required this.dataWystawienia,
    required this.dataTerminu,
    this.dataOplaty,
    this.opis = '',
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory FakturaPodwykonawcyModel.fromJson(Map<String, dynamic> j) =>
      FakturaPodwykonawcyModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        podwykonawcaId: j['podwykonawca'] ?? 0,
        podwykonawcaNazwa: j['podwykonawca_nazwa'] ?? '',
        numer: j['numer'] ?? '',
        kwotaBrutto: double.tryParse(j['kwota_brutto']?.toString() ?? '0') ?? 0,
        kaucjaProcentowa: double.tryParse(j['kaucja_procentowa']?.toString() ?? '5') ?? 5,
        status: StatusRozliczeniaPodExt.fromApi(j['status'] ?? ''),
        dataWystawienia: DateTime.tryParse(j['data_wystawienia'] ?? '') ?? DateTime.now(),
        dataTerminu: DateTime.tryParse(j['data_terminu'] ?? '') ?? DateTime.now(),
        dataOplaty: j['data_oplaty'] != null ? DateTime.tryParse(j['data_oplaty']) : null,
        opis: j['opis'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'podwykonawca': podwykonawcaId,
        'numer': numer,
        'kwota_brutto': kwotaBrutto,
        'kaucja_procentowa': kaucjaProcentowa,
        'status': status.apiValue,
        'data_wystawienia': dataWystawienia.toIso8601String(),
        'data_terminu': dataTerminu.toIso8601String(),
        'opis': opis,
      };

  double get kaucjaKwota => kwotaBrutto * kaucjaProcentowa / 100;
  double get doZaplaty => kwotaBrutto - kaucjaKwota;
  bool get przeterminowane =>
      status == StatusRozliczeniaPod.oczekuje &&
      dataTerminu.isBefore(DateTime.now());

  String get dataTerminuFmt => _fmt.format(dataTerminu);
  String? get dataOplatyFmt => dataOplaty != null ? _fmt.format(dataOplaty!) : null;
}

// ---- Zwrot kaucji ----

class ZwrotKaucjiModel {
  final int id;
  final int fakturaId;
  final String podwykonawcaNazwa;
  final double kwota;
  final DateTime dataZwrotu;
  final String uwagi;

  const ZwrotKaucjiModel({
    required this.id,
    required this.fakturaId,
    required this.podwykonawcaNazwa,
    required this.kwota,
    required this.dataZwrotu,
    this.uwagi = '',
  });

  factory ZwrotKaucjiModel.fromJson(Map<String, dynamic> j) => ZwrotKaucjiModel(
        id: j['id'] ?? 0,
        fakturaId: j['faktura'] ?? 0,
        podwykonawcaNazwa: j['podwykonawca_nazwa'] ?? '',
        kwota: double.tryParse(j['kwota']?.toString() ?? '0') ?? 0,
        dataZwrotu: DateTime.tryParse(j['data_zwrotu'] ?? '') ?? DateTime.now(),
        uwagi: j['uwagi'] ?? '',
      );
}

// ---- Podsumowanie rozliczeń podwykonawcy ----

class PodwykonawcaRozliczeniaStats {
  final int podwykonawcaId;
  final String nazwa;
  final double fakturyLacznie;
  final double oplacenoLacznie;
  final double kaucjePobrane;
  final double kaucjeDoZwrotu;
  final int fakturyOczekujace;

  const PodwykonawcaRozliczeniaStats({
    required this.podwykonawcaId,
    required this.nazwa,
    required this.fakturyLacznie,
    required this.oplacenoLacznie,
    required this.kaucjePobrane,
    required this.kaucjeDoZwrotu,
    required this.fakturyOczekujace,
  });

  factory PodwykonawcaRozliczeniaStats.fromJson(Map<String, dynamic> j) =>
      PodwykonawcaRozliczeniaStats(
        podwykonawcaId: j['podwykonawca_id'] ?? 0,
        nazwa: j['nazwa'] ?? '',
        fakturyLacznie: double.tryParse(j['faktury_lacznie']?.toString() ?? '0') ?? 0,
        oplacenoLacznie: double.tryParse(j['oplacono_lacznie']?.toString() ?? '0') ?? 0,
        kaucjePobrane: double.tryParse(j['kaucje_pobrane']?.toString() ?? '0') ?? 0,
        kaucjeDoZwrotu: double.tryParse(j['kaucje_do_zwrotu']?.toString() ?? '0') ?? 0,
        fakturyOczekujace: j['faktury_oczekujace'] ?? 0,
      );
}
