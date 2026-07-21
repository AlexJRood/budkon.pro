import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:intl/intl.dart';
import '../../data/models/harmonogram_model.dart';
import '../../data/providers/harmonogram_provider.dart';
import '../../data/services/harmonogram_api.dart';

class ZadanieDetailScreen extends ConsumerStatefulWidget {
  final int zadanieId;
  final int budowaId;

  const ZadanieDetailScreen({super.key, required this.zadanieId, required this.budowaId});

  @override
  ConsumerState<ZadanieDetailScreen> createState() => _ZadanieDetailScreenState();
}

class _ZadanieDetailScreenState extends ConsumerState<ZadanieDetailScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  ZadanieModel? _zadanie;
  bool _loading = true;
  int _sliderValue = 0;

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final z = await harmonogramApi.zadanie(widget.zadanieId);
      setState(() { _zadanie = z; _sliderValue = z.postepProcent; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _zapiszPostep() async {
    if (_zadanie == null) return;
    final updated = await ref.read(postepProvider.notifier).aktualizuj(widget.zadanieId, postepProcent: _sliderValue);
    if (updated != null) {
      setState(() => _zadanie = updated);
      ref.invalidate(timelineProvider(widget.budowaId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    if (_loading) {
      return BarManager(
        sideMenuKey: _sideMenuKey,
        appModule: AppModule.budkon,
        childPc: Center(child: CircularProgressIndicator(color: theme.themeColor)),
      );
    }

    if (_zadanie == null) {
      return BarManager(
        sideMenuKey: _sideMenuKey,
        appModule: AppModule.budkon,
        childPc: Center(child: Text('Błąd ładowania', style: TextStyle(color: theme.textColor))),
      );
    }

    final z = _zadanie!;

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: IconButton(
        icon: Icon(Icons.edit_outlined, color: theme.textColor),
        onPressed: () => ref.read(navigationService).pushNamedScreen(
          '/harmonogram/zadanie/form',
          data: {'budowaId': widget.budowaId, 'zadanieId': widget.zadanieId},
        ),
      ),
      childPc: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(z.nazwa,
                style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            _StatusBadge(status: z.status, isOpoznione: z.isOpoznione, theme: theme),
          ]),

          if (z.etapNazwa != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.construction, size: 16, color: theme.textColor.withAlpha(120)),
              const SizedBox(width: 6),
              Text(z.etapNazwa!, style: TextStyle(color: theme.textColor, fontSize: 13)),
            ]),
          ],

          if (z.opis.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(z.opis, style: TextStyle(color: theme.textColor.withAlpha(170))),
          ],

          Divider(height: 32, color: theme.bordercolor.withAlpha(60)),

          Row(children: [
            Expanded(child: _InfoTile(icon: Icons.play_arrow, label: 'Start',
                value: z.dataStart != null ? _fmt.format(z.dataStart!) : '—', theme: theme)),
            Expanded(child: _InfoTile(icon: Icons.flag, label: 'Koniec',
                value: z.dataKoniec != null ? _fmt.format(z.dataKoniec!) : '—',
                isWarning: z.isOpoznione, theme: theme)),
            Expanded(child: _InfoTile(icon: Icons.timer_outlined, label: 'Czas trwania',
                value: '${z.durationDni} dni', theme: theme)),
          ]),

          if (z.isOpoznione) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(80)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Opóźnienie: ${z.opoznienieDni} dni',
                    style: const TextStyle(color: Colors.orange)),
              ]),
            ),
          ],

          Divider(height: 32, color: theme.bordercolor.withAlpha(60)),

          Text('Postęp: $_sliderValue%',
              style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Slider(
                value: _sliderValue.toDouble(),
                min: 0, max: 100, divisions: 20,
                activeColor: theme.themeColor,
                inactiveColor: theme.bordercolor.withAlpha(80),
                label: '$_sliderValue%',
                onChanged: (v) => setState(() => _sliderValue = v.round()),
              ),
            ),
            FilledButton(
              onPressed: _sliderValue != z.postepProcent ? _zapiszPostep : null,
              style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
              child: Text('Zapisz', style: TextStyle(color: theme.buttonTextColor)),
            ),
          ]),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: z.postepProcent / 100, minHeight: 8,
              color: theme.themeColor, backgroundColor: theme.bordercolor.withAlpha(60),
            ),
          ),

          Divider(height: 32, color: theme.bordercolor.withAlpha(60)),

          if (z.poprzednicyIds.isNotEmpty) ...[
            Text('Poprzednicy (${z.poprzednicyIds.length})',
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: z.poprzednicyIds
                .map((id) => Chip(
                  label: Text('#$id', style: TextStyle(color: theme.textColor)),
                  backgroundColor: theme.userTile,
                  side: BorderSide(color: theme.bordercolor.withAlpha(60)),
                )).toList()),
            Divider(height: 32, color: theme.bordercolor.withAlpha(60)),
          ],

          if (z.budzet > 0)
            _InfoTile(icon: Icons.account_balance_wallet_outlined, label: 'Budżet zadania',
                value: '${z.budzet.toStringAsFixed(0)} PLN', theme: theme),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final StatusZadania status;
  final bool isOpoznione;
  final ThemeColors theme;

  const _StatusBadge({required this.status, required this.isOpoznione, required this.theme});

  Color _color() {
    if (isOpoznione) return Colors.orange.withAlpha(80);
    return switch (status) {
      StatusZadania.zakonczone => const Color(0xFF4CAF50),
      StatusZadania.w_toku => theme.themeColor.withAlpha(80),
      _ => theme.textColor.withAlpha(40),
    };
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: _color(), borderRadius: BorderRadius.circular(12)),
    child: Text(isOpoznione ? 'opóźnione' : status.label,
        style: TextStyle(color: theme.textColor, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeColors theme;
  final bool isWarning;

  const _InfoTile({required this.icon, required this.label, required this.value, required this.theme, this.isWarning = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 14, color: isWarning ? Colors.orange : theme.textColor.withAlpha(120)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11)),
      ]),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(
          color: isWarning ? Colors.orange : theme.textColor,
          fontSize: 13, fontWeight: FontWeight.w500)),
    ],
  );
}
