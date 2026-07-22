import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/kosztorys_model.dart';

class PozycjaTile extends ConsumerStatefulWidget {
  const PozycjaTile({
    super.key,
    required this.pozycja,
    required this.onChanged,
    required this.onDelete,
  });

  final KosztorysPozycjaModel pozycja;
  final void Function(double ilosc, double cena) onChanged;
  final VoidCallback onDelete;

  @override
  ConsumerState<PozycjaTile> createState() => _PozycjaTileState();
}

class _PozycjaTileState extends ConsumerState<PozycjaTile> {
  late final TextEditingController _iloscCtrl;
  late final TextEditingController _cenaCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _iloscCtrl = TextEditingController(
        text: widget.pozycja.ilosc.toStringAsFixed(2));
    _cenaCtrl = TextEditingController(
        text: widget.pozycja.cenaJednostkowa.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _iloscCtrl.dispose();
    _cenaCtrl.dispose();
    super.dispose();
  }

  void _commit() {
    final ilosc = double.tryParse(_iloscCtrl.text) ?? widget.pozycja.ilosc;
    final cena =
        double.tryParse(_cenaCtrl.text) ?? widget.pozycja.cenaJednostkowa;
    widget.onChanged(ilosc, cena);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final hasAiSuggestion = widget.pozycja.aiSuggestedPrice != null;

    return Card(
      elevation: 0,
      color: theme.userTile,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: hasAiSuggestion
            ? BorderSide(color: const Color(0xFF6A5ACD).withAlpha(100))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.pozycja.knrNumer != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.themeColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.pozycja.knrNumer!,
                        style: TextStyle(
                            fontSize: 10,
                            color: theme.themeColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.pozycja.opis,
                      style: TextStyle(fontSize: 14, color: theme.textColor),
                      maxLines: _expanded ? null : 2,
                      overflow:
                          _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmtWartosc(widget.pozycja.wartosc),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.themeColor,
                    ),
                  ),
                ],
              ),

              if (_expanded) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: 'Ilość (${widget.pozycja.jednostka})',
                        controller: _iloscCtrl,
                        onSubmitted: (_) => _commit(),
                        aiValue: widget.pozycja.aiSuggestedQty,
                        accentColor: theme.themeColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumField(
                        label: 'Cena jedn. (zł)',
                        controller: _cenaCtrl,
                        onSubmitted: (_) => _commit(),
                        aiValue: widget.pozycja.aiSuggestedPrice,
                        accentColor: theme.themeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.check, size: 20),
                      tooltip: 'Zapisz',
                      color: theme.themeColor,
                      onPressed: _commit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Usuń pozycję',
                      color: Colors.red,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtWartosc(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k zł';
    return '${v.toStringAsFixed(2)} zł';
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.label,
    required this.controller,
    required this.onSubmitted,
    required this.accentColor,
    this.aiValue,
  });

  final String label;
  final TextEditingController controller;
  final void Function(String) onSubmitted;
  final Color accentColor;
  final double? aiValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
          ],
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            suffixIcon: aiValue != null
                ? Tooltip(
                    message: 'Sugestia AI: $aiValue',
                    child: Icon(Icons.auto_awesome,
                        size: 14, color: const Color(0xFF6A5ACD)),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
