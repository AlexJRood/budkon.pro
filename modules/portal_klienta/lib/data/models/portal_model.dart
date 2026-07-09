class PortalKlientaModel {
  const PortalKlientaModel({
    required this.id,
    required this.budowaId,
    required this.token,
    required this.nazwaKlienta,
    this.emailKlienta = '',
    this.telefonKlienta = '',
    this.pokazujKosztorys = false,
    this.pokazujFaktury = true,
    this.pokazujZdjecia = true,
    this.pokazujHarmonogram = true,
    this.aktywny = true,
    this.wygasa,
    this.jestWazny = true,
    this.ostatniOdczyt,
    this.liczbaOdczytow = 0,
    this.urlKlienta = '',
    this.createdAt,
  });

  final int id;
  final int budowaId;
  final String token;
  final String nazwaKlienta;
  final String emailKlienta;
  final String telefonKlienta;
  final bool pokazujKosztorys;
  final bool pokazujFaktury;
  final bool pokazujZdjecia;
  final bool pokazujHarmonogram;
  final bool aktywny;
  final String? wygasa;
  final bool jestWazny;
  final String? ostatniOdczyt;
  final int liczbaOdczytow;
  final String urlKlienta;
  final String? createdAt;

  factory PortalKlientaModel.fromJson(Map<String, dynamic> j) =>
      PortalKlientaModel(
        id: j['id'] as int,
        budowaId: j['budowa_id'] as int,
        token: j['token'] as String,
        nazwaKlienta: j['nazwa_klienta'] as String,
        emailKlienta: j['email_klienta'] as String? ?? '',
        telefonKlienta: j['telefon_klienta'] as String? ?? '',
        pokazujKosztorys: j['pokazuj_kosztorys'] as bool? ?? false,
        pokazujFaktury: j['pokazuj_faktury'] as bool? ?? true,
        pokazujZdjecia: j['pokazuj_zdjecia'] as bool? ?? true,
        pokazujHarmonogram: j['pokazuj_harmonogram'] as bool? ?? true,
        aktywny: j['aktywny'] as bool? ?? true,
        wygasa: j['wygasa'] as String?,
        jestWazny: j['jest_wazny'] as bool? ?? true,
        ostatniOdczyt: j['ostatni_odczyt'] as String?,
        liczbaOdczytow: j['liczba_odczytow'] as int? ?? 0,
        urlKlienta: j['url_klienta'] as String? ?? '',
        createdAt: j['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'budowa_id': budowaId,
        'nazwa_klienta': nazwaKlienta,
        'email_klienta': emailKlienta,
        'telefon_klienta': telefonKlienta,
        'pokazuj_kosztorys': pokazujKosztorys,
        'pokazuj_faktury': pokazujFaktury,
        'pokazuj_zdjecia': pokazujZdjecia,
        'pokazuj_harmonogram': pokazujHarmonogram,
        'aktywny': aktywny,
        if (wygasa != null) 'wygasa': wygasa,
      };

  PortalKlientaModel copyWith({
    bool? aktywny,
    String? token,
    String? urlKlienta,
  }) =>
      PortalKlientaModel(
        id: id,
        budowaId: budowaId,
        token: token ?? this.token,
        nazwaKlienta: nazwaKlienta,
        emailKlienta: emailKlienta,
        telefonKlienta: telefonKlienta,
        pokazujKosztorys: pokazujKosztorys,
        pokazujFaktury: pokazujFaktury,
        pokazujZdjecia: pokazujZdjecia,
        pokazujHarmonogram: pokazujHarmonogram,
        aktywny: aktywny ?? this.aktywny,
        wygasa: wygasa,
        jestWazny: aktywny ?? this.aktywny,
        ostatniOdczyt: ostatniOdczyt,
        liczbaOdczytow: liczbaOdczytow,
        urlKlienta: urlKlienta ?? this.urlKlienta,
        createdAt: createdAt,
      );
}
