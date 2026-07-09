enum KategoriaMaterialu {
  beton('beton', 'Beton i kruszywa', '🪨'),
  stal('stal', 'Stal i metale', '🔩'),
  drewno('drewno', 'Drewno i stolarka', '🪵'),
  ceramika('ceramika', 'Ceramika i bloki', '🧱'),
  izolacja('izolacja', 'Izolacja i hydroizolacja', '🛡️'),
  instalacje('instalacje', 'Instalacje wod-kan', '🔧'),
  elektryka('elektryka', 'Elektryka', '⚡'),
  elewacja('elewacja', 'Elewacja i tynki', '🏠'),
  pokrycie('pokrycie', 'Pokrycie dachowe', '🏗️'),
  wykonczenie('wykonczenie', 'Wykończenie', '🎨'),
  chemia('chemia', 'Chemia budowlana', '🧪'),
  narzedzia('narzedzia', 'Narzędzia i sprzęt', '🔨'),
  inne('inne', 'Inne', '📦');

  final String value;
  final String label;
  final String emoji;
  const KategoriaMaterialu(this.value, this.label, this.emoji);

  static KategoriaMaterialu fromValue(String v) =>
      KategoriaMaterialu.values.firstWhere(
        (e) => e.value == v,
        orElse: () => KategoriaMaterialu.inne,
      );
}

enum TrendCeny {
  rosnacy('rosnacy', '↑', 'Cena rośnie — kup teraz!'),
  spadajacy('spadajacy', '↓', 'Cena spada — możesz poczekać'),
  stabilny('stabilny', '→', 'Cena stabilna');

  final String value;
  final String symbol;
  final String porada;
  const TrendCeny(this.value, this.symbol, this.porada);

  static TrendCeny? fromValue(String? v) {
    if (v == null) return null;
    return TrendCeny.values.firstWhere(
      (e) => e.value == v,
      orElse: () => TrendCeny.stabilny,
    );
  }
}

class HistoriaCenyModel {
  final int id;
  final double cenaNetto;
  final String data;
  final String zrodlo;
  final String uwagi;

  const HistoriaCenyModel({
    required this.id,
    required this.cenaNetto,
    required this.data,
    required this.zrodlo,
    this.uwagi = '',
  });

  factory HistoriaCenyModel.fromJson(Map<String, dynamic> j) =>
      HistoriaCenyModel(
        id: j['id'] as int,
        cenaNetto: (j['cena_netto'] as num).toDouble(),
        data: j['data'].toString(),
        zrodlo: (j['zrodlo'] ?? '').toString(),
        uwagi: (j['uwagi'] ?? '').toString(),
      );
}

class MaterialModel {
  final int id;
  final String nazwa;
  final String jednostka;
  final KategoriaMaterialu kategoria;
  final String producent;
  final String symbol;
  final int vat;
  final double? cenaNetto;
  final double? cenaBrutto;
  final String? cenaUpdatedAt;
  final TrendCeny? trend;
  final List<HistoriaCenyModel> historiaCen;

  const MaterialModel({
    required this.id,
    required this.nazwa,
    required this.jednostka,
    required this.kategoria,
    this.producent = '',
    this.symbol = '',
    this.vat = 23,
    this.cenaNetto,
    this.cenaBrutto,
    this.cenaUpdatedAt,
    this.trend,
    this.historiaCen = const [],
  });

  factory MaterialModel.fromJson(Map<String, dynamic> j) => MaterialModel(
        id: j['id'] as int,
        nazwa: j['nazwa'].toString(),
        jednostka: (j['jednostka'] ?? 'szt').toString(),
        kategoria: KategoriaMaterialu.fromValue(
            (j['kategoria'] ?? 'inne').toString()),
        producent: (j['producent'] ?? '').toString(),
        symbol: (j['symbol'] ?? '').toString(),
        vat: (j['vat'] as num?)?.toInt() ?? 23,
        cenaNetto: (j['cena_netto'] as num?)?.toDouble(),
        cenaBrutto: (j['cena_brutto'] as num?)?.toDouble(),
        cenaUpdatedAt: j['cena_updated_at']?.toString(),
        trend: TrendCeny.fromValue(j['trend']?.toString()),
        historiaCen: (j['historia_cen'] as List? ?? [])
            .map((e) => HistoriaCenyModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get cenaFormatted {
    if (cenaNetto == null) return '—';
    return '${cenaNetto!.toStringAsFixed(2)} PLN';
  }
}

enum StatusPozycji {
  doZamowienia('do_zamowienia', 'Do zamówienia'),
  zamowione('zamowione', 'Zamówione'),
  wDostawie('w_dostawie', 'W dostawie'),
  dostarczone('dostarczone', 'Dostarczone'),
  zwrocone('zwrocone', 'Zwrócone');

  final String value;
  final String label;
  const StatusPozycji(this.value, this.label);

  static StatusPozycji fromValue(String v) =>
      StatusPozycji.values.firstWhere(
        (e) => e.value == v,
        orElse: () => StatusPozycji.doZamowienia,
      );
}

class PozycjaZamowieniaModel {
  final int id;
  final MaterialModel material;
  final int budowaId;
  final int? kosztorysId;
  final int? etapId;
  final double ilosc;
  final double iloscDostarczona;
  final double? cenaNettoPodana;
  final StatusPozycji status;
  final String uwagi;
  final String? dataPotrzeby;
  final String? dataZamowienia;
  final String? dataDostawy;
  final double? wartoscNetto;
  final double brakuje;

  const PozycjaZamowieniaModel({
    required this.id,
    required this.material,
    required this.budowaId,
    this.kosztorysId,
    this.etapId,
    required this.ilosc,
    this.iloscDostarczona = 0,
    this.cenaNettoPodana,
    required this.status,
    this.uwagi = '',
    this.dataPotrzeby,
    this.dataZamowienia,
    this.dataDostawy,
    this.wartoscNetto,
    this.brakuje = 0,
  });

  factory PozycjaZamowieniaModel.fromJson(Map<String, dynamic> j) =>
      PozycjaZamowieniaModel(
        id: j['id'] as int,
        material: MaterialModel.fromJson(j['material'] as Map<String, dynamic>),
        budowaId: j['budowa_id'] as int,
        kosztorysId: j['kosztorys_id'] as int?,
        etapId: j['etap_id'] as int?,
        ilosc: (j['ilosc'] as num).toDouble(),
        iloscDostarczona:
            (j['ilosc_dostarczona'] as num? ?? 0).toDouble(),
        cenaNettoPodana:
            (j['cena_netto_zakupu'] as num?)?.toDouble(),
        status: StatusPozycji.fromValue(
            (j['status'] ?? 'do_zamowienia').toString()),
        uwagi: (j['uwagi'] ?? '').toString(),
        dataPotrzeby: j['data_potrzeby']?.toString(),
        dataZamowienia: j['data_zamowienia']?.toString(),
        dataDostawy: j['data_dostawy']?.toString(),
        wartoscNetto: (j['wartosc_netto'] as num?)?.toDouble(),
        brakuje: (j['brakuje'] as num? ?? 0).toDouble(),
      );

  double get efektywnaCtena =>
      cenaNettoPodana ?? material.cenaNetto ?? 0;

  String get iloscStr {
    final i = ilosc % 1 == 0 ? ilosc.toInt().toString() : ilosc.toStringAsFixed(2);
    return '$i ${material.jednostka}';
  }
}
