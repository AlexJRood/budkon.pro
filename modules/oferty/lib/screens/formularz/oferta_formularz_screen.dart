import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/services/oferty_api.dart';

class OfertyFormularzScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final String budowaNazwa;
  final int? kosztorysId;

  const OfertyFormularzScreen({
    super.key,
    this.budowaId,
    this.budowaNazwa = 'Budowa',
    this.kosztorysId,
  });

  @override
  ConsumerState<OfertyFormularzScreen> createState() => _OfertyFormularzScreenState();
}

class _OfertyFormularzScreenState extends ConsumerState<OfertyFormularzScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  final _pageCtrl = PageController();
  int _step = 0;
  bool _saving = false;

  int? _kosztorysId;
  String _kosztorysNazwa = '';

  final _klientNazwaCtrl = TextEditingController();
  final _klientAdresCtrl = TextEditingController();
  final _klientNipCtrl = TextEditingController();
  final _klientEmailCtrl = TextEditingController();
  final _klientTelCtrl = TextEditingController();

  final _tytulCtrl = TextEditingController();
  final _wstepCtrl = TextEditingController();
  final _warunkiCtrl = TextEditingController(
    text: 'Oferta ważna 30 dni od daty wystawienia.\n'
        'Ceny podane w PLN, nie zawierają podatku VAT.\n'
        'Termin realizacji do uzgodnienia.',
  );
  int _vatProcent = 23;
  double _rabatProcent = 0;
  String? _waznaDo;

  final _wystawcaNazwaCtrl = TextEditingController();
  final _wystawcaNipCtrl = TextEditingController();
  final _wystawcaEmailCtrl = TextEditingController();
  final _wystawcaTelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.kosztorysId != null) _kosztorysId = widget.kosztorysId;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _klientNazwaCtrl.dispose();
    _klientAdresCtrl.dispose();
    _klientNipCtrl.dispose();
    _klientEmailCtrl.dispose();
    _klientTelCtrl.dispose();
    _tytulCtrl.dispose();
    _wstepCtrl.dispose();
    _warunkiCtrl.dispose();
    _wystawcaNazwaCtrl.dispose();
    _wystawcaNipCtrl.dispose();
    _wystawcaEmailCtrl.dispose();
    _wystawcaTelCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _generuj();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      ref.read(navigationService).beamPop();
    }
  }

  bool get _canProceed => switch (_step) {
    0 => _kosztorysId != null,
    1 => _klientNazwaCtrl.text.trim().isNotEmpty,
    _ => true,
  };

  Future<void> _generuj() async {
    setState(() => _saving = true);
    try {
      final oferta = await ofertyApi.zKosztorysu({
        'kosztorys_id': _kosztorysId,
        if (widget.budowaId != null) 'budowa_id': widget.budowaId,
        'tytul': _tytulCtrl.text.trim().isNotEmpty ? _tytulCtrl.text.trim() : null,
        'klient_nazwa': _klientNazwaCtrl.text.trim(),
        'klient_adres': _klientAdresCtrl.text.trim(),
        'klient_nip': _klientNipCtrl.text.trim(),
        'klient_email': _klientEmailCtrl.text.trim(),
        'klient_telefon': _klientTelCtrl.text.trim(),
        'wystawca_nazwa': _wystawcaNazwaCtrl.text.trim(),
        'wystawca_nip': _wystawcaNipCtrl.text.trim(),
        'wystawca_email': _wystawcaEmailCtrl.text.trim(),
        'wystawca_telefon': _wystawcaTelCtrl.text.trim(),
        'wstep': _wstepCtrl.text.trim(),
        'warunki': _warunkiCtrl.text.trim(),
        'vat_procent': _vatProcent,
        'rabat_procent': _rabatProcent,
        if (_waznaDo != null) 'wazna_do': _waznaDo,
      });

      if (!mounted) return;
      ref.read(navigationService).beamPop();
      ref.read(navigationService).pushNamedScreen(
        '/oferty/detail',
        data: {'ofertaId': oferta.id, 'autoPdf': true},
      );
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    final content = Column(
      children: [
        LinearProgressIndicator(
          value: (_step + 1) / 3,
          backgroundColor: theme.textColor.withAlpha(40),
          valueColor: AlwaysStoppedAnimation(theme.themeColor),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: _prevStep,
              ),
              const SizedBox(width: 8),
              Text(
                ['Kosztorys', 'Dane klienta', 'Ustawienia'][_step],
                style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _KrokKosztorys(
                budowaId: widget.budowaId,
                selected: _kosztorysId,
                theme: theme,
                onSelect: (id, nazwa) => setState(() { _kosztorysId = id; _kosztorysNazwa = nazwa; }),
              ),
              _KrokKlient(
                theme: theme,
                nazwaCtrl: _klientNazwaCtrl,
                adresCtrl: _klientAdresCtrl,
                nipCtrl: _klientNipCtrl,
                emailCtrl: _klientEmailCtrl,
                telCtrl: _klientTelCtrl,
              ),
              _KrokUstawienia(
                theme: theme,
                tytulCtrl: _tytulCtrl,
                tytulHint: _kosztorysNazwa,
                wstepCtrl: _wstepCtrl,
                warunkiCtrl: _warunkiCtrl,
                wystawcaNazwaCtrl: _wystawcaNazwaCtrl,
                wystawcaNipCtrl: _wystawcaNipCtrl,
                wystawcaEmailCtrl: _wystawcaEmailCtrl,
                wystawcaTelCtrl: _wystawcaTelCtrl,
                vatProcent: _vatProcent,
                rabatProcent: _rabatProcent,
                onVatChanged: (v) => setState(() => _vatProcent = v),
                onRabatChanged: (v) => setState(() => _rabatProcent = v),
                onWaznaDoChanged: (v) => setState(() => _waznaDo = v),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: (_canProceed && !_saving) ? _nextStep : null,
              style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
              child: _saving
                  ? SizedBox.square(dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.buttonTextColor))
                  : Text(_step < 2 ? 'Dalej' : 'Generuj ofertę',
                      style: TextStyle(color: theme.buttonTextColor)),
            ),
          ),
        ),
      ],
    );

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: content,
    );
  }
}

class _KrokKosztorys extends ConsumerStatefulWidget {
  final int? budowaId;
  final int? selected;
  final ThemeColors theme;
  final void Function(int id, String nazwa) onSelect;

  const _KrokKosztorys({required this.budowaId, required this.selected, required this.theme, required this.onSelect});

  @override
  ConsumerState<_KrokKosztorys> createState() => _KrokKosztorysState();
}

class _KrokKosztorysState extends ConsumerState<_KrokKosztorys> {
  List<Map<String, dynamic>> _kosztorysy = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _zaladuj();
  }

  Future<void> _zaladuj() async {
    try {
      final dio = _getDio();
      final r = await dio.get('/kosztorysy/', queryParameters: {
        if (widget.budowaId != null) 'budowa': widget.budowaId,
      });
      setState(() {
        _kosztorysy = (r.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: theme.themeColor));
    }
    if (_kosztorysy.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: theme.textColor.withAlpha(80)),
          const SizedBox(height: 16),
          Text('Brak kosztorysów dla tej budowy', style: TextStyle(color: theme.textColor)),
          const SizedBox(height: 8),
          Text('Utwórz kosztorys w module Kosztorysy',
              style: TextStyle(color: theme.textColor.withAlpha(140))),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Wybierz kosztorys jako podstawę oferty',
            style: TextStyle(color: theme.textColor.withAlpha(150))),
        const SizedBox(height: 16),
        ..._kosztorysy.map((k) {
          final id = k['id'] as int;
          final nazwa = (k['nazwa'] ?? '').toString();
          final status = (k['status'] ?? '').toString();
          final selected = widget.selected == id;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: selected ? theme.themeColor.withAlpha(20) : theme.userTile,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? theme.themeColor : theme.bordercolor.withAlpha(60),
                width: selected ? 2 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(nazwa,
                  style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
              subtitle: Text(status, style: TextStyle(color: theme.textColor.withAlpha(140))),
              trailing: selected ? Icon(Icons.check_circle, color: theme.themeColor) : null,
              onTap: () => widget.onSelect(id, nazwa),
            ),
          );
        }),
      ],
    );
  }
}

Dio _getDio() => Dio(BaseOptions(
  baseUrl: 'http://127.0.0.1:8001/api/v1',
  headers: {'X-Company-Id': '1'},
));

class _KrokKlient extends StatelessWidget {
  final ThemeColors theme;
  final TextEditingController nazwaCtrl;
  final TextEditingController adresCtrl;
  final TextEditingController nipCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController telCtrl;

  const _KrokKlient({
    required this.theme,
    required this.nazwaCtrl,
    required this.adresCtrl,
    required this.nipCtrl,
    required this.emailCtrl,
    required this.telCtrl,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Dane nabywcy oferty',
          style: TextStyle(color: theme.textColor.withAlpha(150))),
      const SizedBox(height: 16),
      _Field(theme: theme, ctrl: nazwaCtrl, label: 'Nazwa klienta / firma *'),
      _Field(theme: theme, ctrl: adresCtrl, label: 'Adres', maxLines: 2),
      _Field(theme: theme, ctrl: nipCtrl, label: 'NIP (opcjonalnie)'),
      _Field(theme: theme, ctrl: emailCtrl, label: 'E-mail', keyboardType: TextInputType.emailAddress),
      _Field(theme: theme, ctrl: telCtrl, label: 'Telefon', keyboardType: TextInputType.phone),
    ],
  );
}

class _KrokUstawienia extends StatefulWidget {
  final ThemeColors theme;
  final TextEditingController tytulCtrl;
  final String tytulHint;
  final TextEditingController wstepCtrl;
  final TextEditingController warunkiCtrl;
  final TextEditingController wystawcaNazwaCtrl;
  final TextEditingController wystawcaNipCtrl;
  final TextEditingController wystawcaEmailCtrl;
  final TextEditingController wystawcaTelCtrl;
  final int vatProcent;
  final double rabatProcent;
  final ValueChanged<int> onVatChanged;
  final ValueChanged<double> onRabatChanged;
  final ValueChanged<String?> onWaznaDoChanged;

  const _KrokUstawienia({
    required this.theme,
    required this.tytulCtrl,
    required this.tytulHint,
    required this.wstepCtrl,
    required this.warunkiCtrl,
    required this.wystawcaNazwaCtrl,
    required this.wystawcaNipCtrl,
    required this.wystawcaEmailCtrl,
    required this.wystawcaTelCtrl,
    required this.vatProcent,
    required this.rabatProcent,
    required this.onVatChanged,
    required this.onRabatChanged,
    required this.onWaznaDoChanged,
  });

  @override
  State<_KrokUstawienia> createState() => _KrokUstawieniaState();
}

class _KrokUstawieniaState extends State<_KrokUstawienia> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(title: 'Oferta', theme: theme),
        _Field(theme: theme, ctrl: widget.tytulCtrl, label: 'Tytuł oferty',
            hint: widget.tytulHint.isNotEmpty ? 'np. Oferta — ${widget.tytulHint}' : null),
        _Field(theme: theme, ctrl: widget.wstepCtrl, label: 'Wstęp (opcjonalnie)',
            maxLines: 3, hint: 'np. Dziękujemy za zapytanie...'),
        _Field(theme: theme, ctrl: widget.warunkiCtrl, label: 'Warunki', maxLines: 4),

        const SizedBox(height: 16),
        _Section(title: 'Finansowe', theme: theme),

        DropdownButtonFormField<int>(
          value: widget.vatProcent,
          dropdownColor: theme.popupcontainercolor,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            labelText: 'Stawka VAT',
            labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
            border: OutlineInputBorder(borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
            filled: true,
            fillColor: theme.textFieldColor,
            isDense: true,
          ),
          items: [0, 5, 8, 23].map((v) =>
            DropdownMenuItem(value: v, child: Text('$v%', style: TextStyle(color: theme.textColor)))).toList(),
          onChanged: (v) => widget.onVatChanged(v!),
        ),
        const SizedBox(height: 12),

        Row(children: [
          Text('Rabat: ', style: TextStyle(color: theme.textColor)),
          Expanded(
            child: Slider(
              value: widget.rabatProcent,
              min: 0, max: 30, divisions: 30,
              activeColor: theme.themeColor,
              inactiveColor: theme.bordercolor.withAlpha(80),
              label: '${widget.rabatProcent.toStringAsFixed(0)}%',
              onChanged: widget.onRabatChanged,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text('${widget.rabatProcent.toStringAsFixed(0)}%',
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),

        OutlinedButton.icon(
          icon: Icon(Icons.event_outlined, color: theme.themeColor),
          label: Text('Ustaw datę ważności', style: TextStyle(color: theme.textColor)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: theme.bordercolor.withAlpha(80))),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) widget.onWaznaDoChanged(date.toIso8601String().substring(0, 10));
          },
        ),

        const SizedBox(height: 20),
        _Section(title: 'Wystawca (Twoja firma)', theme: theme),
        _Field(theme: theme, ctrl: widget.wystawcaNazwaCtrl, label: 'Nazwa firmy'),
        _Field(theme: theme, ctrl: widget.wystawcaNipCtrl, label: 'NIP firmy'),
        _Field(theme: theme, ctrl: widget.wystawcaEmailCtrl, label: 'E-mail firmy',
            keyboardType: TextInputType.emailAddress),
        _Field(theme: theme, ctrl: widget.wystawcaTelCtrl, label: 'Telefon firmy',
            keyboardType: TextInputType.phone),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final ThemeColors theme;
  const _Section({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title,
        style: TextStyle(color: theme.themeColor, fontSize: 13, fontWeight: FontWeight.w700)),
  );
}

class _Field extends StatelessWidget {
  final ThemeColors theme;
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.theme,
    required this.ctrl,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
        hintText: hint,
        hintStyle: TextStyle(color: theme.textColor.withAlpha(80)),
        filled: true,
        fillColor: theme.textFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
        ),
        isDense: true,
      ),
    ),
  );
}
