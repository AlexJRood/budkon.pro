import 'package:intl/intl.dart';

enum KategoriaDokumentu {
  projekt, pozwolenie, kosztorys, umowa, protokol, korespondencja, bhp, certyfikat, inne
}

extension KategoriaDokumentuExt on KategoriaDokumentu {
  String get apiValue => name;
  String get label => switch (this) {
        KategoriaDokumentu.projekt => 'Projekt',
        KategoriaDokumentu.pozwolenie => 'Pozwolenie',
        KategoriaDokumentu.kosztorys => 'Kosztorys',
        KategoriaDokumentu.umowa => 'Umowa',
        KategoriaDokumentu.protokol => 'Protokół',
        KategoriaDokumentu.korespondencja => 'Korespondencja',
        KategoriaDokumentu.bhp => 'BHP',
        KategoriaDokumentu.certyfikat => 'Certyfikat/atest',
        KategoriaDokumentu.inne => 'Inne',
      };
  String get emoji => switch (this) {
        KategoriaDokumentu.projekt => '📐',
        KategoriaDokumentu.pozwolenie => '📋',
        KategoriaDokumentu.kosztorys => '💰',
        KategoriaDokumentu.umowa => '📄',
        KategoriaDokumentu.protokol => '✅',
        KategoriaDokumentu.korespondencja => '✉️',
        KategoriaDokumentu.bhp => '⛑️',
        KategoriaDokumentu.certyfikat => '🏅',
        KategoriaDokumentu.inne => '📁',
      };
  static KategoriaDokumentu fromApi(String v) =>
      KategoriaDokumentu.values.firstWhere((e) => e.name == v,
          orElse: () => KategoriaDokumentu.inne);
}

enum StatusDokumentu { aktywny, archiwalny, wersjaRobocza, przedawniony }

extension StatusDokumentuExt on StatusDokumentu {
  String get apiValue => name;
  String get label => switch (this) {
        StatusDokumentu.aktywny => 'Aktywny',
        StatusDokumentu.archiwalny => 'Archiwalny',
        StatusDokumentu.wersjaRobocza => 'Wersja robocza',
        StatusDokumentu.przedawniony => 'Przedawniony',
      };
  static StatusDokumentu fromApi(String v) =>
      StatusDokumentu.values.firstWhere((e) => e.name == v,
          orElse: () => StatusDokumentu.aktywny);
}

class DokumentModel {
  final int id;
  final int budowaId;
  final String tytul;
  final KategoriaDokumentu kategoria;
  final StatusDokumentu status;
  final String? numer;
  final String? opis;
  final DateTime dataWydania;
  final DateTime? dataWaznosci;
  final String? fileUrl;
  final String? fileName;
  final String dodaKto;

  const DokumentModel({
    required this.id,
    required this.budowaId,
    required this.tytul,
    this.kategoria = KategoriaDokumentu.inne,
    this.status = StatusDokumentu.aktywny,
    this.numer,
    this.opis,
    required this.dataWydania,
    this.dataWaznosci,
    this.fileUrl,
    this.fileName,
    this.dodaKto = '',
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  factory DokumentModel.fromJson(Map<String, dynamic> j) => DokumentModel(
        id: j['id'] ?? 0,
        budowaId: j['budowa'] ?? 0,
        tytul: j['tytul'] ?? '',
        kategoria: KategoriaDokumentuExt.fromApi(j['kategoria'] ?? ''),
        status: StatusDokumentuExt.fromApi(j['status'] ?? ''),
        numer: j['numer'],
        opis: j['opis'],
        dataWydania: DateTime.tryParse(j['data_wydania'] ?? '') ?? DateTime.now(),
        dataWaznosci: j['data_waznosci'] != null
            ? DateTime.tryParse(j['data_waznosci'])
            : null,
        fileUrl: j['file_url'],
        fileName: j['file_name'],
        dodaKto: j['doda_kto'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'budowa': budowaId,
        'tytul': tytul,
        'kategoria': kategoria.apiValue,
        'status': status.apiValue,
        if (numer != null) 'numer': numer,
        if (opis != null) 'opis': opis,
        'data_wydania': dataWydania.toIso8601String(),
        if (dataWaznosci != null) 'data_waznosci': dataWaznosci!.toIso8601String(),
      };

  bool get wygasa {
    if (dataWaznosci == null) return false;
    return dataWaznosci!.difference(DateTime.now()).inDays <= 30;
  }

  bool get przeterminowany {
    if (dataWaznosci == null) return false;
    return dataWaznosci!.isBefore(DateTime.now());
  }

  String get dataWydaniaFmt => _fmt.format(dataWydania);
  String? get dataWaznosciFmt =>
      dataWaznosci != null ? _fmt.format(dataWaznosci!) : null;
}
