// ---- Dziennik głosowy ----

enum StatusWpisu { oczekuje, transkrybowany, blad }

class WpisDziennikModel {
  final int id;
  final int budowaId;
  final DateTime data;
  final String? transkrypcja;
  final String? streszczenie;
  final StatusWpisu status;
  final String? audioUrl;
  final List<String> tagi;

  const WpisDziennikModel({
    required this.id,
    required this.budowaId,
    required this.data,
    this.transkrypcja,
    this.streszczenie,
    required this.status,
    this.audioUrl,
    this.tagi = const [],
  });

  factory WpisDziennikModel.fromJson(Map<String, dynamic> j) =>
      WpisDziennikModel(
        id: j['id'],
        budowaId: j['budowa_id'],
        data: DateTime.parse(j['data']),
        transkrypcja: j['transkrypcja'],
        streszczenie: j['streszczenie'],
        status: StatusWpisu.values.firstWhere(
          (e) => e.name == (j['status'] ?? 'oczekuje'),
          orElse: () => StatusWpisu.oczekuje,
        ),
        audioUrl: j['audio_url'],
        tagi: List<String>.from(j['tagi'] ?? []),
      );
}

// ---- Analiza zdjęć ----

enum TypAnalizy { postep, wada, material, bezpieczenstwo, inne }

extension TypAnalizyExt on TypAnalizy {
  String get label => switch (this) {
        TypAnalizy.postep => 'Postęp robót',
        TypAnalizy.wada => 'Wada/usterka',
        TypAnalizy.material => 'Materiał',
        TypAnalizy.bezpieczenstwo => 'BHP',
        TypAnalizy.inne => 'Inne',
      };

  String get emoji => switch (this) {
        TypAnalizy.postep => '📊',
        TypAnalizy.wada => '⚠️',
        TypAnalizy.material => '🧱',
        TypAnalizy.bezpieczenstwo => '🦺',
        TypAnalizy.inne => '📷',
      };
}

class AnalizaZdjeciaModel {
  final int id;
  final int budowaId;
  final DateTime data;
  final String zdjecieUrl;
  final TypAnalizy typ;
  final String opis;
  final List<String> problemy;
  final List<String> rekomendacje;
  final double? postepProcent;

  const AnalizaZdjeciaModel({
    required this.id,
    required this.budowaId,
    required this.data,
    required this.zdjecieUrl,
    required this.typ,
    required this.opis,
    this.problemy = const [],
    this.rekomendacje = const [],
    this.postepProcent,
  });

  bool get maProblemy => problemy.isNotEmpty;

  factory AnalizaZdjeciaModel.fromJson(Map<String, dynamic> j) =>
      AnalizaZdjeciaModel(
        id: j['id'],
        budowaId: j['budowa_id'],
        data: DateTime.parse(j['data']),
        zdjecieUrl: j['zdjecie_url'] ?? '',
        typ: TypAnalizy.values.firstWhere(
          (e) => e.name == (j['typ'] ?? 'inne'),
          orElse: () => TypAnalizy.inne,
        ),
        opis: j['opis'] ?? '',
        problemy: List<String>.from(j['problemy'] ?? []),
        rekomendacje: List<String>.from(j['rekomendacje'] ?? []),
        postepProcent: j['postep_procent'] != null
            ? double.tryParse(j['postep_procent'].toString())
            : null,
      );
}

// ---- Predykcja kosztów ----

class PredykcjaKosztowModel {
  final int budowaId;
  final double kosztAktualny;
  final double kosztPrzewidywany;
  final double kosztBudzet;
  final double odchylenieOdBudzetu;
  final String uzasadnienie;
  final List<String> glowneCzynniki;
  final DateTime dataGeneracji;

  const PredykcjaKosztowModel({
    required this.budowaId,
    required this.kosztAktualny,
    required this.kosztPrzewidywany,
    required this.kosztBudzet,
    required this.odchylenieOdBudzetu,
    required this.uzasadnienie,
    this.glowneCzynniki = const [],
    required this.dataGeneracji,
  });

  bool get przekroczonyBudzet => kosztPrzewidywany > kosztBudzet;

  double get procentWykonania =>
      kosztBudzet > 0 ? (kosztAktualny / kosztBudzet) * 100 : 0;

  factory PredykcjaKosztowModel.fromJson(Map<String, dynamic> j) =>
      PredykcjaKosztowModel(
        budowaId: j['budowa_id'],
        kosztAktualny: double.tryParse(j['koszt_aktualny'].toString()) ?? 0,
        kosztPrzewidywany:
            double.tryParse(j['koszt_przewidywany'].toString()) ?? 0,
        kosztBudzet: double.tryParse(j['koszt_budzet'].toString()) ?? 0,
        odchylenieOdBudzetu:
            double.tryParse(j['odchylenie_od_budzetu'].toString()) ?? 0,
        uzasadnienie: j['uzasadnienie'] ?? '',
        glowneCzynniki: List<String>.from(j['glowne_czynniki'] ?? []),
        dataGeneracji: DateTime.parse(
            j['data_generacji'] ?? DateTime.now().toIso8601String()),
      );
}

// ---- Chat z asystentem ----

enum RolaCzat { user, assistant }

class WiadomoscCzatModel {
  final String tresc;
  final RolaCzat rola;
  final DateTime czas;

  const WiadomoscCzatModel({
    required this.tresc,
    required this.rola,
    required this.czas,
  });
}
