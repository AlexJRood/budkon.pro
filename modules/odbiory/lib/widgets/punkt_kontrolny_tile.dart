import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/odbiory_model.dart';
import '../data/providers/odbiory_provider.dart';

class PunktKontrolnyTile extends ConsumerStatefulWidget {
  final PunktKontrolnyModel punkt;
  final bool readOnly;

  const PunktKontrolnyTile({
    super.key,
    required this.punkt,
    this.readOnly = false,
  });

  @override
  ConsumerState<PunktKontrolnyTile> createState() => _PunktKontrolnyTileState();
}

class _PunktKontrolnyTileState extends ConsumerState<PunktKontrolnyTile> {
  bool _expanded = false;
  late final TextEditingController _uwagiCtrl;

  @override
  void initState() {
    super.initState();
    _uwagiCtrl = TextEditingController(text: widget.punkt.uwaga);
  }

  @override
  void dispose() {
    _uwagiCtrl.dispose();
    super.dispose();
  }

  Future<void> _setWynik(WynikPunktu w) async {
    if (widget.readOnly) return;
    await ref.read(protokolProvider.notifier).updatePunkt(
          widget.punkt.id,
          w,
          uwaga: _uwagiCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final p = widget.punkt;

    final wynikColor = switch (p.wynik) {
      WynikPunktu.ok => Colors.green,
      WynikPunktu.nok => Colors.red.shade400,
      WynikPunktu.na => theme.textColor.withAlpha(60),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: p.isNok ? Colors.red.withAlpha(80) : theme.bordercolor.withAlpha(40),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.readOnly ? null : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Kategoria dot
                  if (p.kategoria.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.themeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(p.kategoria,
                          style: TextStyle(fontSize: 9, color: theme.themeColor)),
                    ),
                  Expanded(
                    child: Text(
                      p.pytanie,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                        fontWeight: p.wymagane ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Wynik buttons
                  if (!widget.readOnly) ...[
                    _WynikBtn(
                      icon: Icons.check,
                      active: p.isOk,
                      activeColor: Colors.green,
                      theme: theme,
                      onTap: () => _setWynik(WynikPunktu.ok),
                    ),
                    const SizedBox(width: 4),
                    _WynikBtn(
                      icon: Icons.close,
                      active: p.isNok,
                      activeColor: Colors.red,
                      theme: theme,
                      onTap: () => _setWynik(WynikPunktu.nok),
                    ),
                    const SizedBox(width: 4),
                    _WynikBtn(
                      icon: Icons.remove,
                      active: p.wynik == WynikPunktu.na,
                      activeColor: theme.textColor.withAlpha(120),
                      theme: theme,
                      onTap: () => _setWynik(WynikPunktu.na),
                    ),
                  ] else ...[
                    Icon(
                      switch (p.wynik) {
                        WynikPunktu.ok => Icons.check_circle,
                        WynikPunktu.nok => Icons.cancel,
                        WynikPunktu.na => Icons.remove_circle_outline,
                      },
                      size: 20,
                      color: wynikColor,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Rozwinięte uwagi
          if (_expanded && !widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _uwagiCtrl,
                      style: TextStyle(fontSize: 12, color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Uwaga / komentarz...',
                        hintStyle: TextStyle(color: theme.textColor.withAlpha(80), fontSize: 12),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.save_outlined, size: 18, color: theme.themeColor),
                    onPressed: () => _setWynik(p.wynik),
                    tooltip: 'Zapisz uwagę',
                  ),
                ],
              ),
            ),

          // Uwaga read-only lub istniejąca
          if (p.uwaga.isNotEmpty && (!_expanded || widget.readOnly))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 12, color: theme.textColor.withAlpha(100)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(p.uwaga,
                        style: TextStyle(
                            fontSize: 11, color: theme.textColor.withAlpha(150), fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WynikBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _WynikBtn({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? activeColor.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: active ? activeColor : theme.bordercolor.withAlpha(60),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: active ? activeColor : theme.textColor.withAlpha(80)),
      ),
    );
  }
}
