import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/projekt_model.dart';
import '../../data/providers/projekt_provider.dart';
import '../../data/providers/kosztorysy_provider.dart';
import '../../data/services/kosztorysy_api.dart';
import '../../widgets/floor_plan/floor_plan_widget.dart';

class ProjektReviewScreen extends ConsumerStatefulWidget {
  final ParsedProjekt projekt;
  final int? kosztorysId;

  const ProjektReviewScreen({
    super.key,
    required this.projekt,
    this.kosztorysId,
  });

  @override
  ConsumerState<ProjektReviewScreen> createState() => _ProjektReviewScreenState();
}

class _ProjektReviewScreenState extends ConsumerState<ProjektReviewScreen>
    with SingleTickerProviderStateMixin {
  final _sideMenuKey = GlobalKey<SideMenuState>();
  late TabController _tabs;
  PomieszczenieProjekt? _selectedRoom;
  late List<PomieszczenieProjekt> _rooms;
  late List<SugerowanaPozyacja> _pozycje;
  final Set<int> _selectedPozycje = {};
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _rooms = List.of(widget.projekt.pomieszczenia);
    _pozycje = List.of(widget.projekt.sugerowanePozyacje);
    // Auto-select all suggested items
    _selectedPozycje.addAll(List.generate(_pozycje.length, (i) => i));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: Column(
        children: [
          _buildHeader(theme),
          _buildSummaryBar(theme),
          TabBar(
            controller: _tabs,
            labelColor: theme.themeColor,
            unselectedLabelColor: theme.textColor.withAlpha(120),
            indicatorColor: theme.themeColor,
            tabs: const [
              Tab(icon: Icon(Icons.map_outlined), text: 'Floor plan'),
              Tab(icon: Icon(Icons.list_alt_outlined), text: 'Pozycje kosztorysu'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildFloorPlanTab(theme),
                _buildPozycjeTab(theme),
              ],
            ),
          ),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.bordercolor.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.architecture, color: theme.themeColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projekt.tytul ?? 'Projekt architektoniczny',
                  style: TextStyle(
                      color: theme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'Przejrzyj wyniki analizy i zatwierdź import',
                  style: TextStyle(
                      color: theme.textColor.withAlpha(120), fontSize: 11),
                ),
              ],
            ),
          ),
          if (widget.projekt.uwagi != null)
            IconButton(
              icon: Icon(Icons.info_outline, color: theme.textColor.withAlpha(120)),
              tooltip: widget.projekt.uwagi,
              onPressed: () => _showUwagi(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ThemeColors theme) {
    final stats = [
      ('${_rooms.length}', 'pomieszczeń'),
      ('${widget.projekt.sumaPowierzchni.toStringAsFixed(0)} m²', 'powierzchnia'),
      ('${_selectedPozycje.length}/${_pozycje.length}', 'pozycji wybranych'),
      (_formatPrice(
          _pozycje.indexed
              .where((e) => _selectedPozycje.contains(e.$1))
              .fold(0.0, (s, e) => s + e.$2.wartoscSzacunkowa)),
       'wartość szacunkowa'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.userTile.withAlpha(40),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(s.$1,
                    style: TextStyle(
                        color: theme.themeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(s.$2,
                    style: TextStyle(
                        color: theme.textColor.withAlpha(130), fontSize: 10)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Floor plan tab ──────────────────────────────────────────────────────────

  Widget _buildFloorPlanTab(ThemeColors theme) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Rzut kondygnacji',
                        style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.themeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Przeciągnij pomieszczenia',
                          style: TextStyle(
                              color: theme.themeColor, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.bordercolor.withAlpha(40)),
                      ),
                      child: _rooms.isEmpty
                          ? _buildNoFloorPlan(theme)
                          : FloorPlanWidget(
                              pomieszczenia: _rooms,
                              editable: true,
                              selected: _selectedRoom,
                              onSelect: (r) =>
                                  setState(() => _selectedRoom = r),
                              onChanged: (updated) =>
                                  setState(() => _rooms = updated),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildRoomList(theme),
      ],
    );
  }

  Widget _buildNoFloorPlan(ThemeColors theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined,
              size: 48, color: theme.textColor.withAlpha(60)),
          const SizedBox(height: 12),
          Text('Brak danych rzutu',
              style: TextStyle(
                  color: theme.textColor.withAlpha(100), fontSize: 13)),
          const SizedBox(height: 4),
          Text('AI nie wykryło układu pomieszczeń',
              style: TextStyle(
                  color: theme.textColor.withAlpha(60), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRoomList(ThemeColors theme) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.bordercolor.withAlpha(40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Pomieszczenia',
                style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _rooms.length,
              itemBuilder: (_, i) {
                final room = _rooms[i];
                final isSelected = _selectedRoom?.id == room.id;
                return InkWell(
                  onTap: () => setState(() =>
                      _selectedRoom = isSelected ? null : room),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.themeColor.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: room.kolor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room.nazwa,
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '${room.powierzchnia.toStringAsFixed(1)} m²',
                                  style: TextStyle(
                                      color: theme.textColor.withAlpha(120),
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Pozycje tab ─────────────────────────────────────────────────────────────

  Widget _buildPozycjeTab(ThemeColors theme) {
    if (_pozycje.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_outlined,
                size: 48, color: theme.textColor.withAlpha(60)),
            const SizedBox(height: 12),
            Text('Brak sugerowanych pozycji',
                style: TextStyle(color: theme.textColor.withAlpha(100))),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildPozycjeToolbar(theme),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _pozycje.length,
            itemBuilder: (_, i) => _buildPozycjaTile(theme, i),
          ),
        ),
      ],
    );
  }

  Widget _buildPozycjeToolbar(ThemeColors theme) {
    final allSelected = _selectedPozycje.length == _pozycje.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            tristate: _selectedPozycje.isNotEmpty && !allSelected,
            onChanged: (_) => setState(() {
              if (allSelected) {
                _selectedPozycje.clear();
              } else {
                _selectedPozycje.addAll(
                    List.generate(_pozycje.length, (i) => i));
              }
            }),
            activeColor: theme.themeColor,
          ),
          Text(
            allSelected ? 'Odznacz wszystkie' : 'Zaznacz wszystkie',
            style:
                TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
          ),
          const Spacer(),
          Text(
            '${_selectedPozycje.length} z ${_pozycje.length} pozycji',
            style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPozycjaTile(ThemeColors theme, int index) {
    final p = _pozycje[index];
    final isSelected = _selectedPozycje.contains(index);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? theme.userTile : theme.userTile.withAlpha(60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? theme.themeColor.withAlpha(80)
              : theme.bordercolor.withAlpha(40),
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => setState(() {
          if (isSelected) {
            _selectedPozycje.remove(index);
          } else {
            _selectedPozycje.add(index);
          }
        }),
        activeColor: theme.themeColor,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          p.opis,
          style: TextStyle(
              color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            if (p.kategoria != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.themeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(p.kategoria!,
                    style:
                        TextStyle(color: theme.themeColor, fontSize: 9)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '${p.ilosc.toStringAsFixed(2)} ${p.jednostka}',
              style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11),
            ),
            if (p.zrodloPomieszczenia != null) ...[
              Text(' • ',
                  style:
                      TextStyle(color: theme.textColor.withAlpha(60))),
              Text(p.zrodloPomieszczenia!,
                  style: TextStyle(
                      color: theme.textColor.withAlpha(100), fontSize: 11)),
            ],
          ],
        ),
        secondary: Text(
          _formatPrice(p.wartoscSzacunkowa),
          style: TextStyle(
              color: theme.themeColor,
              fontWeight: FontWeight.w700,
              fontSize: 13),
        ),
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────

  Widget _buildFooter(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.bordercolor.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          const Spacer(),
          Text(
            'Zaznaczono ${_selectedPozycje.length} pozycji',
            style: TextStyle(
                color: theme.textColor.withAlpha(120), fontSize: 12),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            icon: _importing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_chart),
            label: Text(widget.kosztorysId != null
                ? 'Importuj do kosztorysu'
                : 'Utwórz kosztorys'),
            onPressed: _importing ? null : _importToKosztorys,
            style: FilledButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: theme.buttonTextColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _importToKosztorys() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final api = ref.read(kosztorysyApiProvider);
      int kosztorysId = widget.kosztorysId ?? 0;

      if (kosztorysId == 0) {
        final k = await api.create({
          'nazwa': widget.projekt.tytul ?? 'Projekt architektoniczny',
          'opis': 'Wygenerowano z projektu architektonicznego. '
              'Powierzchnia: ${widget.projekt.sumaPowierzchni.toStringAsFixed(0)} m²',
          'status': 'roboczy',
        });
        kosztorysId = k.id;
      }

      // Importuj zaznaczone pozycje
      final selectedList = _selectedPozycje.toList()..sort();
      if (selectedList.isNotEmpty) {
        // Create a default dzialu if needed – use AI generate to push items
        await api.importProjektPozycje(
          kosztorysId,
          selectedList.map((i) => _pozycje[i].toJson()).toList(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        ref.read(navigationService).pushNamedScreen('/kosztorysy/$kosztorysId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Błąd importu: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showUwagi(ThemeColors theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Uwagi AI'),
        content: Text(widget.projekt.uwagi ?? ''),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'))
        ],
      ),
    );
  }

  String _formatPrice(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} mln zł';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} tys. zł';
    return '${v.toStringAsFixed(0)} zł';
  }
}
