import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/oferty_api.dart';
import '../podglad/oferta_detail_screen.dart';

/// Formularz tworzenia oferty z kosztorysu.
/// Krok 1: wybierz kosztorys
/// Krok 2: dane klienta
/// Krok 3: ustawienia (VAT, rabat, ważność, teksty)
class OfertyFormularzScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final String budowaNazwa;
  final int? kosztorysId; // jeśli przekazany z zewnątrz

  const OfertyFormularzScreen({
    super.key,
    this.budowaId,
    this.budowaNazwa = 'Budowa',
    this.kosztorysId,
  });

  @override
  ConsumerState<OfertyFormularzScreen> createState() =>
      _OfertyFormularzScreenState();
}

class _OfertyFormularzScreenState
    extends ConsumerState<OfertyFormularzScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _saving = false;

  // Krok 1
  int? _kosztorysId;
  String _kosztorysNazwa = '';

  // Krok 2 — klient
  final _klientNazwaCtrl = TextEditingController();
  final _klientAdresCtrl = TextEditingController();
  final _klientNipCtrl = TextEditingController();
  final _klientEmailCtrl = TextEditingController();
  final _klientTelCtrl = TextEditingController();

  // Krok 3 — ustawienia
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

  // Krok wystawcy (krótkie pola)
  final _wystawcaNazwaCtrl = TextEditingController();
  final _wystawcaNipCtrl = TextEditingController();
  final _wystawcaEmailCtrl = TextEditingController();
  final _wystawcaTelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.kosztorysId != null) {
      _kosztorysId = widget.kosztorysId;
    }
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
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _generuj();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
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
        'tytul': _tytulCtrl.text.trim().isNotEmpty
            ? _tytulCtrl.text.trim()
            : null,
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
      // Przejdź do podglądu nowej oferty
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OfertyDetailScreen(
            ofertaId: oferta.id,
            autoPdf: true,
          ),
        ),
      );
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _prevStep),
        title: Text(['Kosztorys', 'Dane klienta', 'Ustawienia'][_step]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _KrokKosztorys(
            budowaId: widget.budowaId,
            selected: _kosztorysId,
            onSelect: (id, nazwa) => setState(() {
              _kosztorysId = id;
              _kosztorysNazwa = nazwa;
            }),
          ),
          _KrokKlient(
            nazwaCtrl: _klientNazwaCtrl,
            adresCtrl: _klientAdresCtrl,
            nipCtrl: _klientNipCtrl,
            emailCtrl: _klientEmailCtrl,
            telCtrl: _klientTelCtrl,
          ),
          _KrokUstawienia(
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: (_canProceed && !_saving) ? _nextStep : null,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_step < 2 ? 'Dalej' : 'Generuj ofertę'),
          ),
        ),
      ),
    );
  }
}

// ---- Krok 1: Wybór kosztorysu ----------------------------------------------

class _KrokKosztorys extends ConsumerStatefulWidget {
  final int? budowaId;
  final int? selected;
  final void Function(int id, String nazwa) onSelect;

  const _KrokKosztorys({
    required this.budowaId,
    required this.selected,
    required this.onSelect,
  });

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
      final dio = await _getDio();
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_kosztorysy.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Brak kosztorysów dla tej budowy'),
            const SizedBox(height: 8),
            Text(
              'Utwórz kosztorys w module Kosztorysy',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Wybierz kosztorys jako podstawę oferty',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 16),
        ..._kosztorysy.map((k) {
          final id = k['id'] as int;
          final nazwa = (k['nazwa'] ?? '').toString();
          final status = (k['status'] ?? '').toString();
          final selected = widget.selected == id;
          final cs = Theme.of(context).colorScheme;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              title: Text(nazwa,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(status),
              trailing: selected
                  ? Icon(Icons.check_circle, color: cs.primary)
                  : null,
              onTap: () => widget.onSelect(id, nazwa),
            ),
          );
        }),
      ],
    );
  }
}

import 'package:dio/dio.dart';
Dio _getDio() => Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:8001/api/v1',
      headers: {'X-Company-Id': '1'},
    ));

// ---- Krok 2: Dane klienta --------------------------------------------------

class _KrokKlient extends StatelessWidget {
  final TextEditingController nazwaCtrl;
  final TextEditingController adresCtrl;
  final TextEditingController nipCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController telCtrl;

  const _KrokKlient({
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
          Text(
            'Dane nabywcy oferty',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 16),
          _Field(ctrl: nazwaCtrl, label: 'Nazwa klienta / firma *', required: true),
          _Field(ctrl: adresCtrl, label: 'Adres', maxLines: 2),
          _Field(ctrl: nipCtrl, label: 'NIP (opcjonalnie)'),
          _Field(
            ctrl: emailCtrl,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
          ),
          _Field(
            ctrl: telCtrl,
            label: 'Telefon',
            keyboardType: TextInputType.phone,
          ),
        ],
      );
}

// ---- Krok 3: Ustawienia ----------------------------------------------------

class _KrokUstawienia extends StatefulWidget {
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
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Oferta'),
          _Field(
            ctrl: widget.tytulCtrl,
            label: 'Tytuł oferty',
            hint: widget.tytulHint.isNotEmpty
                ? 'np. Oferta — ${widget.tytulHint}'
                : null,
          ),
          _Field(
            ctrl: widget.wstepCtrl,
            label: 'Wstęp (opcjonalnie)',
            maxLines: 3,
            hint: 'np. Dziękujemy za zapytanie...',
          ),
          _Field(ctrl: widget.warunkiCtrl, label: 'Warunki', maxLines: 4),

          const SizedBox(height: 16),
          _Section('Finansowe'),

          // VAT
          DropdownButtonFormField<int>(
            value: widget.vatProcent,
            decoration: const InputDecoration(
              labelText: 'Stawka VAT',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [0, 5, 8, 23]
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text('$v%'),
                    ))
                .toList(),
            onChanged: (v) => widget.onVatChanged(v!),
          ),
          const SizedBox(height: 12),

          // Rabat
          Row(children: [
            const Text('Rabat: '),
            Expanded(
              child: Slider(
                value: widget.rabatProcent,
                min: 0,
                max: 30,
                divisions: 30,
                label: '${widget.rabatProcent.toStringAsFixed(0)}%',
                onChanged: widget.onRabatChanged,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${widget.rabatProcent.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Ważna do
          OutlinedButton.icon(
            icon: const Icon(Icons.event_outlined),
            label: const Text('Ustaw datę ważności'),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate:
                    DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                widget.onWaznaDoChanged(date.toIso8601String().substring(0, 10));
              }
            },
          ),

          const SizedBox(height: 20),
          _Section('Wystawca (Twoja firma)'),
          _Field(ctrl: widget.wystawcaNazwaCtrl, label: 'Nazwa firmy'),
          _Field(ctrl: widget.wystawcaNipCtrl, label: 'NIP firmy'),
          _Field(
            ctrl: widget.wystawcaEmailCtrl,
            label: 'E-mail firmy',
            keyboardType: TextInputType.emailAddress,
          ),
          _Field(
            ctrl: widget.wystawcaTelCtrl,
            label: 'Telefon firmy',
            keyboardType: TextInputType.phone,
          ),
        ],
      );
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final int maxLines;
  final bool required;
  final TextInputType? keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.required = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );
}
