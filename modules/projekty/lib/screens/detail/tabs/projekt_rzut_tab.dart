import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:floor_plan/canvas/floor_plan_canvas.dart';
import 'package:floor_plan/models/floor_plan_document.dart';
import '../../../data/models/projekt_budowlany_model.dart';
import '../../../utils/projekt_floor_plan_converter.dart';

class ProjektRzutTab extends ConsumerStatefulWidget {
  const ProjektRzutTab({super.key, required this.projekt});
  final ProjektBudowlanyDetailModel projekt;

  @override
  ConsumerState<ProjektRzutTab> createState() => _ProjektRzutTabState();
}

class _ProjektRzutTabState extends ConsumerState<ProjektRzutTab> {
  int _kondygnacjaIdx = 0;
  late FloorPlanDocument _doc;
  bool _docInitialized = false;

  @override
  void initState() {
    super.initState();
    _rebuildDoc();
  }

  void _rebuildDoc() {
    final pom = widget.projekt.pomieszczenia;
    final kondygnacje = pom.map((p) => p.kondygnacjaId).toSet().toList()..sort();
    if (kondygnacje.isEmpty) {
      _doc = FloorPlanDocument.empty();
      _docInitialized = true;
      return;
    }
    if (_kondygnacjaIdx >= kondygnacje.length) _kondygnacjaIdx = 0;
    final current = kondygnacje[_kondygnacjaIdx];
    final pomCurrent = pom.where((p) => p.kondygnacjaId == current).toList();
    _doc = ProjektFloorPlanConverter.convert(pomCurrent);
    _docInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final pom = widget.projekt.pomieszczenia;

    if (pom.isEmpty) {
      return Center(
        child: Text('Brak danych pomieszczeń do wyświetlenia rzutu',
            style: TextStyle(color: theme.textColor.withOpacity(0.5))),
      );
    }

    final kondygnacje = pom.map((p) => p.kondygnacjaId).toSet().toList()..sort();

    return Column(
      children: [
        // Wybór kondygnacji
        if (kondygnacje.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kondygnacje.asMap().entries.map((e) {
                  final sel = e.key == _kondygnacjaIdx;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _kondygnacjaIdx = e.key;
                      _rebuildDoc();
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? theme.themeColor : theme.themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                              fontSize: 13,
                              color: sel ? Colors.white : theme.themeColor,
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        // Rzut — FloorPlanCanvas z pełnym edytorem
        Expanded(
          child: _docInitialized
              ? FloorPlanCanvas(
                  document: _doc,
                  onChanged: (updated) => setState(() => _doc = updated),
                )
              : Center(child: CircularProgressIndicator(color: theme.themeColor)),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Rzut wygenerowany z danych PDF — wymiary rzeczywiste, układ automatyczny.\n'
            'Przeciągnij ściany i otwory, by dopasować do projektu.',
            style: TextStyle(fontSize: 11, color: theme.textColor.withOpacity(0.45)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
