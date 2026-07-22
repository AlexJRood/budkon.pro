import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/bzp_wynik_model.dart';
import '../../data/providers/bzp_szukaj_provider.dart';

class BzpSzukajScreen extends ConsumerStatefulWidget {
  const BzpSzukajScreen({super.key});

  @override
  ConsumerState<BzpSzukajScreen> createState() => _BzpSzukajScreenState();
}

class _BzpSzukajScreenState extends ConsumerState<BzpSzukajScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  final _frazaCtrl = TextEditingController();
  final _cpvCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  int _dniWstecz = 30;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // ZaĹ‚aduj wyniki przy otwarciu (ostatnie 30 dni)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bzpSzukajProvider.notifier).szukaj();
    });
  }

  @override
  void dispose() {
    _frazaCtrl.dispose();
    _cpvCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      final s = ref.read(bzpSzukajProvider);
      if (!s.isLoading && s.hasMore) {
        ref.read(bzpSzukajProvider.notifier).szukaj(nextPage: true);
      }
    }
  }

  void _search() {
    ref.read(bzpSzukajProvider.notifier).szukaj(
          fraza: _frazaCtrl.text.trim(),
          cpv: _cpvCtrl.text.trim(),
          dniWstecz: _dniWstecz,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(bzpSzukajProvider);

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Column(
        children: [
          _SearchPanel(
            frazaCtrl: _frazaCtrl,
            cpvCtrl: _cpvCtrl,
            dniWstecz: _dniWstecz,
            theme: theme,
            onDniChanged: (d) => setState(() => _dniWstecz = d),
            onSearch: _search,
          ),
          if (state.total > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Znaleziono ${state.total} ogĹ‚oszeĹ„',
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _Body(
              state: state,
              theme: theme,
              scrollCtrl: _scrollCtrl,
              onRetry: _search,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ //
// Panel filtrĂłw                                                       //
// ------------------------------------------------------------------ //

class _SearchPanel extends StatelessWidget {
  final TextEditingController frazaCtrl;
  final TextEditingController cpvCtrl;
  final int dniWstecz;
  final ThemeColors theme;
  final ValueChanged<int> onDniChanged;
  final VoidCallback onSearch;

  const _SearchPanel({
    required this.frazaCtrl,
    required this.cpvCtrl,
    required this.dniWstecz,
    required this.theme,
    required this.onDniChanged,
    required this.onSearch,
  });

  static const _dni = [7, 14, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: theme.userTile,
        border: Border(bottom: BorderSide(color: theme.bordercolor.withAlpha(40))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: frazaCtrl,
                  style: TextStyle(color: theme.textColor, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'Szukaj w BZP (np. roboty budowlane)...',
                    hintStyle: TextStyle(color: theme.textColor.withAlpha(80), fontSize: 13.sp),
                    prefixIcon: Icon(Icons.search, color: theme.textColor.withAlpha(120), size: 20),
                    filled: true,
                    fillColor: theme.textFieldColor,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    suffixIcon: frazaCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: theme.textColor.withAlpha(120)),
                            onPressed: () => frazaCtrl.clear(),
                          )
                        : null,
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              SizedBox(width: 8.w),
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Szukaj'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.buttonTextColor,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              SizedBox(
                width: 180.w,
                child: TextField(
                  controller: cpvCtrl,
                  style: TextStyle(color: theme.textColor, fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: 'Kod CPV (np. 45000000-7)',
                    hintStyle: TextStyle(color: theme.textColor.withAlpha(80), fontSize: 12.sp),
                    filled: true,
                    fillColor: theme.textFieldColor,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: theme.bordercolor.withAlpha(60)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text('Zakres:', style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12.sp)),
              SizedBox(width: 6.w),
              ..._dni.map(
                (d) => Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: ChoiceChip(
                    label: Text('${d}d'),
                    selected: dniWstecz == d,
                    onSelected: (_) => onDniChanged(d),
                    visualDensity: VisualDensity.compact,
                    selectedColor: theme.themeColor.withAlpha(60),
                    checkmarkColor: theme.themeColor,
                    backgroundColor: theme.textFieldColor,
                    labelStyle: TextStyle(
                      fontSize: 11.sp,
                      color: dniWstecz == d ? theme.themeColor : theme.textColor,
                    ),
                    side: BorderSide(
                      color: dniWstecz == d ? theme.themeColor : theme.bordercolor.withAlpha(60),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ //
// CiaĹ‚o â€” lista wynikĂłw                                               //
// ------------------------------------------------------------------ //

class _Body extends StatelessWidget {
  final BzpSzukajState state;
  final ThemeColors theme;
  final ScrollController scrollCtrl;
  final VoidCallback onRetry;

  const _Body({
    required this.state,
    required this.theme,
    required this.scrollCtrl,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.wyniki.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.themeColor));
    }

    if (state.error != null && state.wyniki.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'BĹ‚Ä…d pobierania danych z BZP',
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                state.error!,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('SprĂłbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.wyniki.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: theme.textColor.withAlpha(80)),
            const SizedBox(height: 12),
            Text(
              'Brak wynikĂłw',
              style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'SprĂłbuj zmieniÄ‡ frazÄ™ lub rozszerzyÄ‡ zakres dat.',
              style: TextStyle(color: theme.textColor.withAlpha(150)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      itemCount: state.wyniki.length + (state.isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= state.wyniki.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: theme.themeColor, strokeWidth: 2)),
          );
        }
        return _BzpCard(wynik: state.wyniki[i], theme: theme);
      },
    );
  }
}

// ------------------------------------------------------------------ //
// Karta ogĹ‚oszenia                                                    //
// ------------------------------------------------------------------ //

class _BzpCard extends StatelessWidget {
  final BzpWynikModel wynik;
  final ThemeColors theme;

  const _BzpCard({required this.wynik, required this.theme});

  @override
  Widget build(BuildContext context) {
    final dni = wynik.dniDoTerminu;
    final expired = dni != null && dni < 0;
    final urgent = dni != null && dni >= 0 && dni <= 7;
    final muted = theme.textColor.withAlpha(120);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GĂłrna belka: numer + termin
            Row(
              children: [
                if (wynik.noticeNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      wynik.noticeNumber!,
                      style: TextStyle(
                        color: theme.themeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Spacer(),
                if (dni != null)
                  _TerminChip(dni: dni, expired: expired, urgent: urgent, theme: theme),
                if (wynik.url != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => launchUrl(Uri.parse(wynik.url!),
                        mode: LaunchMode.externalApplication),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.open_in_new,
                          size: 16, color: theme.themeColor),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),

            // TytuĹ‚
            Text(
              wynik.tytul.isEmpty ? '(brak tytuĹ‚u)' : wynik.tytul,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),

            // ZamawiajÄ…cy
            Row(
              children: [
                Icon(Icons.business_outlined, size: 13, color: muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    wynik.zamawiajacy,
                    style: TextStyle(color: muted, fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (wynik.lokalizacja != null && wynik.lokalizacja!.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    wynik.lokalizacja!,
                    style: TextStyle(color: muted, fontSize: 12.sp),
                  ),
                ],
              ),
            ],

            if (wynik.cpvKody.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: wynik.cpvKody.take(4).map((cpv) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.themeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      cpv,
                      style: TextStyle(
                        color: theme.themeColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TerminChip extends StatelessWidget {
  final int dni;
  final bool expired;
  final bool urgent;
  final ThemeColors theme;

  const _TerminChip({
    required this.dni,
    required this.expired,
    required this.urgent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = expired
        ? theme.textColor.withAlpha(100)
        : urgent
            ? Colors.red.shade400
            : theme.themeColor;
    final bg = expired
        ? theme.bordercolor.withAlpha(40)
        : urgent
            ? Colors.red.withAlpha(40)
            : theme.themeColor.withAlpha(30);
    final label = expired
        ? 'Termin minÄ…Ĺ‚'
        : dni == 0
            ? 'DziĹ›'
            : '$dni dni';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: (urgent && !expired) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

