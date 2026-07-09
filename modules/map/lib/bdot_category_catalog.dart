import 'package:flutter/material.dart';

enum BdotCategory {
  sw,
  sk,
  su,
  pt,
  bu,
  ku,
  tc,
  ad,
  oi,
  rt,

  kibdotImplementations,
  kibdotBase,
  buildingsStatsVoivodeship,
  buildingsStatsCounty,
}

class BdotClassDefinition {
  final String code;
  final String label;

  const BdotClassDefinition({
    required this.code,
    required this.label,
  });
}

class BdotCategoryDefinition {
  final BdotCategory category;
  final String id;
  final String label;
  final String shortCode;
  final IconData icon;
  final Color defaultColor;

  final List<BdotClassDefinition> classes;

  final String? serviceUrl;
  final List<String> layers;

  final double defaultMinZoom;
  final bool defaultEnabled;
  final String? note;

  const BdotCategoryDefinition({
    required this.category,
    required this.id,
    required this.label,
    required this.shortCode,
    required this.icon,
    required this.defaultColor,
    required this.classes,
    required this.serviceUrl,
    required this.layers,
    required this.defaultMinZoom,
    required this.defaultEnabled,
    this.note,
  });

  bool get hasService => serviceUrl != null && serviceUrl!.trim().isNotEmpty;
  bool get isRenderable => hasService && layers.isNotEmpty;

  bool get isSchemaCategory => const {
        BdotCategory.sw,
        BdotCategory.sk,
        BdotCategory.su,
        BdotCategory.pt,
        BdotCategory.bu,
        BdotCategory.ku,
        BdotCategory.tc,
        BdotCategory.ad,
        BdotCategory.oi,
        BdotCategory.rt,
      }.contains(category);
}

class BdotCategoryCatalog {
  static const String integratedBdotUrl =
      'https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaBazDanychObiektowTopograficznych?language=pol';

  static const String buildingsStatsUrl =
      'https://mapy.geoportal.gov.pl/wss/service/PZGIK/BDOT10k/WMS/StatystykiBudynkow?';

  static const List<BdotCategoryDefinition> definitions = [
    BdotCategoryDefinition(
      category: BdotCategory.sw,
      id: 'bdot_sw',
      label: 'Sieć wodna',
      shortCode: 'SW',
      icon: Icons.water_rounded,
      defaultColor: Colors.blue,
      classes: [
        BdotClassDefinition(code: 'SWRS', label: 'Rzeka i strumień'),
        BdotClassDefinition(code: 'SWKN', label: 'Kanał'),
        BdotClassDefinition(code: 'SWRM', label: 'Rów melioracyjny'),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 13.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.sk,
      id: 'bdot_sk',
      label: 'Sieć komunikacyjna',
      shortCode: 'SK',
      icon: Icons.route_rounded,
      defaultColor: Colors.orange,
      classes: [
        BdotClassDefinition(code: 'SKJZ', label: 'Jezdnia'),
        BdotClassDefinition(code: 'SKDR', label: 'Droga'),
        BdotClassDefinition(code: 'SKRW', label: 'Rondo i węzeł drogowy'),
        BdotClassDefinition(
          code: 'SKRP',
          label: 'Ciąg ruchu pieszego i rowerowego',
        ),
        BdotClassDefinition(code: 'SKTR', label: 'Tor lub zespół torów'),
        BdotClassDefinition(code: 'SKPP', label: 'Przeprawa'),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 13.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.su,
      id: 'bdot_su',
      label: 'Sieć uzbrojenia terenu',
      shortCode: 'SU',
      icon: Icons.hub_outlined,
      defaultColor: Colors.purple,
      classes: [
        BdotClassDefinition(code: 'SULN', label: 'Linia napowietrzna'),
        BdotClassDefinition(code: 'SUPR', label: 'Przewód rurowy'),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 14.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.pt,
      id: 'bdot_pt',
      label: 'Pokrycie terenu',
      shortCode: 'PT',
      icon: Icons.landscape_rounded,
      defaultColor: Colors.green,
      classes: [
        BdotClassDefinition(code: 'PTWP', label: 'Woda powierzchniowa'),
        BdotClassDefinition(code: 'PTZB', label: 'Zabudowa'),
        BdotClassDefinition(code: 'PTLZ', label: 'Teren leśny i zadrzewiony'),
        BdotClassDefinition(code: 'PTRK', label: 'Roślinność krzewiasta'),
        BdotClassDefinition(code: 'PTUT', label: 'Uprawa trwała'),
        BdotClassDefinition(
          code: 'PTTR',
          label: 'Roślinność trawiasta i uprawa rolna',
        ),
        BdotClassDefinition(code: 'PTKM', label: 'Teren komunikacyjny'),
        BdotClassDefinition(code: 'PTGN', label: 'Grunt nieużytkowany'),
        BdotClassDefinition(code: 'PTPL', label: 'Plac'),
        BdotClassDefinition(code: 'PTSO', label: 'Składowisko odpadów'),
        BdotClassDefinition(code: 'PTWZ', label: 'Wyrobisko i zwałowisko'),
        BdotClassDefinition(
          code: 'PTNZ',
          label: 'Pozostały teren niezabudowany',
        ),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 13.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.bu,
      id: 'bdot_bu',
      label: 'Budynki, budowle i urządzenia',
      shortCode: 'BU',
      icon: Icons.apartment_rounded,
      defaultColor: Colors.brown,
      classes: [
        BdotClassDefinition(code: 'BUBD', label: 'Budynek'),
        BdotClassDefinition(code: 'BUIN', label: 'Budowla inżynierska'),
        BdotClassDefinition(code: 'BUHD', label: 'Budowla hydrotechniczna'),
        BdotClassDefinition(code: 'BUSP', label: 'Budowla sportowa'),
        BdotClassDefinition(code: 'BUWT', label: 'Wysoka budowla techniczna'),
        BdotClassDefinition(code: 'BUZT', label: 'Zbiornik techniczny'),
        BdotClassDefinition(code: 'BUUO', label: 'Umocnienie'),
        BdotClassDefinition(code: 'BUZM', label: 'Budowla ziemna'),
        BdotClassDefinition(code: 'BUTR', label: 'Urządzenie transportowe'),
        BdotClassDefinition(code: 'BUIT', label: 'Inne urządzenie techniczne'),
        BdotClassDefinition(code: 'BUCM', label: 'Budowla cmentarna'),
        BdotClassDefinition(code: 'BUIB', label: 'Inna budowla'),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 14.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.ku,
      id: 'bdot_ku',
      label: 'Kompleksy użytkowania terenu',
      shortCode: 'KU',
      icon: Icons.terrain_rounded,
      defaultColor: Colors.teal,
      classes: [
        BdotClassDefinition(code: 'KUMN', label: 'Kompleks mieszkaniowy'),
        BdotClassDefinition(
          code: 'KUPG',
          label: 'Kompleks przemysłowo-gospodarczy',
        ),
        BdotClassDefinition(code: 'KUHU', label: 'Kompleks handlowo-usługowy'),
        BdotClassDefinition(code: 'KUKO', label: 'Kompleks komunikacyjny'),
        BdotClassDefinition(
          code: 'KUSK',
          label: 'Kompleks sportowy i rekreacyjny',
        ),
        BdotClassDefinition(
          code: 'KUHO',
          label: 'Kompleks usług hotelarskich',
        ),
        BdotClassDefinition(code: 'KUOS', label: 'Kompleks oświatowy'),
        BdotClassDefinition(code: 'KUOZ', label: 'Kompleks ochrony zdrowia'),
        BdotClassDefinition(
          code: 'KUZA',
          label: 'Kompleks zabytkowo-historyczny',
        ),
        BdotClassDefinition(
          code: 'KUSC',
          label: 'Kompleks sakralny i cmentarz',
        ),
        BdotClassDefinition(
          code: 'KUIK',
          label: 'Inny kompleks użytkowania terenu',
        ),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 13.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.tc,
      id: 'bdot_tc',
      label: 'Tereny chronione',
      shortCode: 'TC',
      icon: Icons.shield_outlined,
      defaultColor: Colors.lightGreen,
      classes: [
        BdotClassDefinition(code: 'TCON', label: 'Obszar Natura 2000'),
        BdotClassDefinition(code: 'TCPK', label: 'Park krajobrazowy'),
        BdotClassDefinition(code: 'TCPN', label: 'Park narodowy'),
        BdotClassDefinition(code: 'TCRZ', label: 'Rezerwat'),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 11.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.ad,
      id: 'bdot_ad',
      label: 'Jednostki podziału terytorialnego',
      shortCode: 'AD',
      icon: Icons.account_tree_outlined,
      defaultColor: Colors.indigo,
      classes: [
        BdotClassDefinition(
          code: 'ADJA',
          label: 'Jednostka podziału administracyjnego',
        ),
        BdotClassDefinition(code: 'ADMS', label: 'Miejscowość'),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 8.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.oi,
      id: 'bdot_oi',
      label: 'Obiekty inne',
      shortCode: 'OI',
      icon: Icons.category_rounded,
      defaultColor: Colors.pink,
      classes: [
        BdotClassDefinition(code: 'OIPR', label: 'Obiekt przyrodniczy'),
        BdotClassDefinition(
          code: 'OIKM',
          label: 'Obiekt związany z komunikacją',
        ),
        BdotClassDefinition(code: 'OIOR', label: 'Obiekt orientacyjny'),
        BdotClassDefinition(code: 'OIMK', label: 'Mokradła'),
        BdotClassDefinition(code: 'OISZ', label: 'Szuwary'),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 13.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.rt,
      id: 'bdot_rt',
      label: 'Rzeźba terenu',
      shortCode: 'RT',
      icon: Icons.show_chart_rounded,
      defaultColor: Colors.deepOrange,
      classes: [
        BdotClassDefinition(
          code: 'BUZM',
          label: 'Budowla ziemna / element relewantny',
        ),
      ],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 11.0,
      defaultEnabled: false,
      note:
          'Osobna warstwa logiczna. Źródło renderu: wspólna kompozycja BDOT.',
    ),

    BdotCategoryDefinition(
      category: BdotCategory.kibdotImplementations,
      id: 'kibdot_implementations',
      label: 'BDOT wdrożenia',
      shortCode: 'KIBDOT',
      icon: Icons.map_outlined,
      defaultColor: Colors.blueGrey,
      classes: [],
      serviceUrl: integratedBdotUrl,
      layers: ['wdrozenia'],
      defaultMinZoom: 8.5,
      defaultEnabled: false,
      note: 'Dokładna publiczna warstwa WMS.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.kibdotBase,
      id: 'kibdot_base',
      label: 'BDOT ogólny overlay',
      shortCode: 'KIBDOT',
      icon: Icons.domain_rounded,
      defaultColor: Colors.grey,
      classes: [],
      serviceUrl: integratedBdotUrl,
      layers: ['bdot'],
      defaultMinZoom: 14.0,
      defaultEnabled: false,
      note: 'Dokładna publiczna warstwa WMS.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.buildingsStatsVoivodeship,
      id: 'bdot_buildings_voivodeship',
      label: 'Budynki i budowle — województwa',
      shortCode: 'BU stat',
      icon: Icons.location_city_rounded,
      defaultColor: Colors.red,
      classes: [],
      serviceUrl: buildingsStatsUrl,
      layers: ['budynki_woj'],
      defaultMinZoom: 7.5,
      defaultEnabled: false,
      note: 'Dokładna publiczna warstwa WMS.',
    ),
    BdotCategoryDefinition(
      category: BdotCategory.buildingsStatsCounty,
      id: 'bdot_buildings_county',
      label: 'Budynki i budowle — powiaty',
      shortCode: 'BU stat',
      icon: Icons.location_city_rounded,
      defaultColor: Colors.redAccent,
      classes: [],
      serviceUrl: buildingsStatsUrl,
      layers: ['budynki_pow'],
      defaultMinZoom: 10.5,
      defaultEnabled: false,
      note: 'Dokładna publiczna warstwa WMS.',
    ),
  ];

  static List<BdotCategoryDefinition> get definitionsInUiOrder => definitions;

  static List<BdotCategoryDefinition> get renderableDefinitions =>
      definitions.where((e) => e.isRenderable).toList();

  static List<BdotCategoryDefinition> get schemaDefinitions =>
      definitions.where((e) => e.isSchemaCategory).toList();

  static List<BdotCategoryDefinition> get overlayDefinitions =>
      definitions.where((e) => !e.isSchemaCategory).toList();

  static BdotCategoryDefinition byCategory(BdotCategory category) {
    return definitions.firstWhere((e) => e.category == category);
  }
}