import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:intl/intl.dart';
import '../../data/models/dziennik_model.dart';
import '../../data/providers/dziennik_provider.dart';
import '../../widgets/pogoda_badge.dart';

class DziennikDetailScreen extends ConsumerWidget {
  final int wpisId;
  final int budowaId;
  final String budowaNazwa;

  const DziennikDetailScreen({
    super.key,
    required this.wpisId,
    required this.budowaId,
    required this.budowaNazwa,
  });

  static final _fmt = DateFormat('dd MMMM yyyy (EEEE)', 'pl_PL');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(wpisDetailProvider(wpisId));

    final editButton = async.whenOrNull(
      data: (wpis) => IconButton(
        icon: Icon(Icons.edit_outlined, color: theme.textColor),
        onPressed: () => ref.read(navigationService).pushNamedScreen(
              '/dziennik/form',
              data: {
                'budowaId': budowaId,
                'budowaNazwa': budowaNazwa,
                'wpisId': wpisId,
              },
            ),
      ),
    );

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: editButton,
      childPc: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) =>
            Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (wpis) => _WpisBody(
            wpis: wpis,
            budowaId: budowaId,
            budowaNazwa: budowaNazwa,
            theme: theme),
      ),
    );
  }
}

class _WpisBody extends StatelessWidget {
  final WpisDetail wpis;
  final int budowaId;
  final String budowaNazwa;
  final ThemeColors theme;

  const _WpisBody({
    required this.wpis,
    required this.budowaId,
    required this.budowaNazwa,
    required this.theme,
  });

  static final _fmt = DateFormat('dd MMMM yyyy (EEEE)', 'pl_PL');

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _fmt.format(wpis.data),
                style: TextStyle(
                    color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            PogodaBadge(
                pogoda: wpis.pogoda,
                temperatura: wpis.temperatura,
                showLabel: true),
          ],
        ),

        if (wpis.pogodaAuto) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 12, color: theme.textColor.withAlpha(120)),
              const SizedBox(width: 4),
              Text(
                'Pogoda uzupełniona automatycznie',
                style:
                    TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120)),
              ),
            ],
          ),
        ],

        if (wpis.predkoscWiatru != null || wpis.opady != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (wpis.predkoscWiatru != null)
                _InfoBadge('💨 ${wpis.predkoscWiatru!.round()} km/h', theme),
              if (wpis.opady != null && wpis.opady! > 0)
                _InfoBadge('🌧 ${wpis.opady!.toStringAsFixed(1)} mm', theme),
            ],
          ),
        ],

        Divider(height: 32, color: theme.bordercolor.withAlpha(60)),

        if (wpis.etapNazwa != null) ...[
          _RowInfo(
              icon: Icons.construction,
              label: 'Etap',
              value: wpis.etapNazwa!,
              theme: theme),
          const SizedBox(height: 12),
        ],

        _SectionLabel('Opis dnia', theme: theme),
        Text(wpis.opis, style: TextStyle(color: theme.textColor)),

        if (wpis.uwagi.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel('Uwagi', theme: theme),
          Text(wpis.uwagi, style: TextStyle(color: theme.textColor)),
        ],

        Divider(height: 32, color: theme.bordercolor.withAlpha(60)),

        _SectionLabel('Zespół', theme: theme),
        Row(
          children: [
            _InfoBadge('👷 ${wpis.liczbaPracownikow} os.', theme),
            const SizedBox(width: 8),
            _InfoBadge(
                '⏱ ${wpis.godzinyPracy.toStringAsFixed(0)} h', theme),
          ],
        ),

        if (wpis.obecnosci.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...wpis.obecnosci.map(
            (o) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: theme.themeColor.withAlpha(40),
                child: Text(o.imieNazwisko[0],
                    style: TextStyle(
                        color: theme.themeColor, fontWeight: FontWeight.w700)),
              ),
              title: Text(o.imieNazwisko, style: TextStyle(color: theme.textColor)),
              subtitle: Text(o.rola,
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
              trailing: Text('${o.godziny.round()} h',
                  style:
                      TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
            ),
          ),
        ],

        if (wpis.zdjecia.isNotEmpty) ...[
          Divider(height: 32, color: theme.bordercolor.withAlpha(60)),
          _SectionLabel('Zdjęcia (${wpis.zdjecia.length})', theme: theme),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wpis.zdjecia.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final z = wpis.zdjecia[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: z.url.isNotEmpty
                        ? Image.network(z.url, fit: BoxFit.cover)
                        : Container(
                            color: theme.secondaryWidgetColor,
                            child: Icon(Icons.photo,
                                color: theme.textColor.withAlpha(120)),
                          ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeColors theme;
  const _SectionLabel(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
              color: theme.themeColor, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
}

class _InfoBadge extends StatelessWidget {
  final String text;
  final ThemeColors theme;
  const _InfoBadge(this.text, this.theme);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.secondaryWidgetColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.bordercolor.withAlpha(40)),
        ),
        child: Text(text, style: TextStyle(color: theme.textColor, fontSize: 13)),
      );
}

class _RowInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeColors theme;
  const _RowInfo(
      {required this.icon,
      required this.label,
      required this.value,
      required this.theme});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: theme.textColor.withAlpha(120)),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(color: theme.textColor))),
        ],
      );
}
