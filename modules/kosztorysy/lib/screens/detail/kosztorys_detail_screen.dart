import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/kosztorys_model.dart';
import '../../data/providers/kosztorysy_provider.dart';
import '../../widgets/kosztorys_status_badge.dart';
import '../../widgets/pozycja_tile.dart';
import '../../widgets/wartosc_chip.dart';

class KosztorysDetailScreen extends ConsumerWidget {
  const KosztorysDetailScreen({super.key, required this.kosztorysId});
  final int kosztorysId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(kosztorysDetailProvider(kosztorysId));

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: state.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) =>
            Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (k) => _KosztorysDetail(kosztorys: k),
      ),
    );
  }
}

class _KosztorysDetail extends ConsumerWidget {
  const _KosztorysDetail({required this.kosztorys});
  final KosztorysModel kosztorys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final generating = ref.watch(aiGenerateProvider).isLoading;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(kosztorys.nazwa, style: TextStyle(color: theme.textColor)),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: theme.textColor),
              onPressed: () => _openEdit(context, ref),
            ),
          ],
        ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      KosztorysStatusBadge(status: kosztorys.status),
                      const Spacer(),
                      WartoscChip(wartosc: kosztorys.wartoscTotal, large: true),
                    ],
                  ),
                  if (kosztorys.opis.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(kosztorys.opis,
                        style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13)),
                  ],
                  SizedBox(height: 16.h),
                  _AiGenerateButton(
                    kosztorys: kosztorys,
                    generating: generating,
                    theme: theme,
                    onGenerate: (opis, obmiar) async {
                      final result = await ref
                          .read(aiGenerateProvider.notifier)
                          .generate(kosztorys.id, opis: opis, obmiar: obmiar);
                      if (result == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Błąd generowania — sprawdź połączenie z Superbee'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          if (kosztorys.dzialy.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  children: [
                    Icon(Icons.playlist_add, size: 48, color: theme.textColor.withAlpha(80)),
                    SizedBox(height: 12.h),
                    Text('Brak pozycji kosztorysowych',
                        style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4.h),
                    Text('Użyj AI Generate lub dodaj ręcznie',
                        style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            for (final dzial in kosztorys.dzialy) ...[
              SliverToBoxAdapter(child: _DzialHeader(dzial: dzial, theme: theme)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverList.builder(
                  itemCount: dzial.pozycje.length,
                  itemBuilder: (context, i) {
                    final poz = dzial.pozycje[i];
                    return PozycjaTile(
                      pozycja: poz,
                      onChanged: (ilosc, cena) async {
                        await ref.read(kosztorysFormProvider.notifier).updatePozycja(poz.id, {
                          'ilosc': ilosc,
                          'cena_jednostkowa': cena,
                        });
                        ref.read(kosztorysDetailProvider(kosztorys.id).notifier).fetch();
                      },
                      onDelete: () async {
                        await ref.read(kosztorysFormProvider.notifier).deletePozycja(poz.id);
                        ref.read(kosztorysDetailProvider(kosztorys.id).notifier).fetch();
                      },
                    );
                  },
                ),
              ),
            ],

          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      );
  }

  void _openEdit(BuildContext context, WidgetRef ref) {
    final listItem = KosztorysListItemModel(
      id: kosztorys.id,
      budowaId: kosztorys.budowaId,
      nazwa: kosztorys.nazwa,
      opis: kosztorys.opis,
      status: kosztorys.status,
      wartoscTotal: kosztorys.wartoscTotal,
      pozycjeCount: kosztorys.dzialy.fold(0, (s, d) => s + d.pozycje.length),
      updatedAt: kosztorys.updatedAt,
    );
    ref.read(navigationService).pushNamedScreen(
          '/kosztorysy/${kosztorys.id}/edit',
          data: {'existing': listItem},
        );
  }
}

class _DzialHeader extends StatelessWidget {
  const _DzialHeader({required this.dzial, required this.theme});
  final KosztorysdzDzialModel dzial;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(dzial.nazwa,
                style: TextStyle(color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _fmt(dzial.wartoscDzialu),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.themeColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} tys. zł';
    return '${v.toStringAsFixed(2)} zł';
  }
}

class _AiGenerateButton extends StatelessWidget {
  const _AiGenerateButton({required this.kosztorys, required this.generating, required this.onGenerate, required this.theme});

  final KosztorysModel kosztorys;
  final bool generating;
  final ThemeColors theme;
  final void Function(String opis, Map<String, dynamic> obmiar) onGenerate;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: generating ? null : () => _showDialog(context),
      style: FilledButton.styleFrom(
        backgroundColor: theme.themeAccent,
        foregroundColor: theme.buttonTextColor,
        minimumSize: Size(double.infinity, 44.h),
      ),
      icon: generating
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.buttonTextColor))
          : const Icon(Icons.auto_awesome),
      label: Text(generating ? 'Generuję przez AI...' : 'Generuj przez AI'),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AiDialog(
        initialOpis: kosztorys.aiPrompt.isNotEmpty ? kosztorys.aiPrompt : kosztorys.opis,
        onConfirm: (opis, obmiar) {
          Navigator.pop(ctx);
          onGenerate(opis, obmiar);
        },
      ),
    );
  }
}

class _AiDialog extends StatefulWidget {
  const _AiDialog({required this.initialOpis, required this.onConfirm});
  final String initialOpis;
  final void Function(String opis, Map<String, dynamic> obmiar) onConfirm;

  @override
  State<_AiDialog> createState() => _AiDialogState();
}

class _AiDialogState extends State<_AiDialog> {
  late final TextEditingController _opisCtrl;
  final _powCtrl = TextEditingController();
  final _kubCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _opisCtrl = TextEditingController(text: widget.initialOpis);
  }

  @override
  void dispose() {
    _opisCtrl.dispose();
    _powCtrl.dispose();
    _kubCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 8),
          const Text('AI Generate'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opisz zakres robót', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _opisCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'np. remont łazienki 8m², wymiana płytek ceramicznych, nowa instalacja wod-kan, malowanie',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Text('Obmiar (opcjonalnie)', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _powCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Powierzchnia m²', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _kubCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kubatura m³', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('⚠ Generowanie zastąpi istniejące pozycje.',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
        FilledButton(
          onPressed: () {
            if (_opisCtrl.text.trim().isEmpty) return;
            final obmiar = <String, dynamic>{};
            final pow = double.tryParse(_powCtrl.text);
            final kub = double.tryParse(_kubCtrl.text);
            if (pow != null) obmiar['powierzchnia_m2'] = pow;
            if (kub != null) obmiar['kubatura_m3'] = kub;
            widget.onConfirm(_opisCtrl.text.trim(), obmiar);
          },
          child: const Text('Generuj'),
        ),
      ],
    );
  }
}
