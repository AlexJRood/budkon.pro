import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/kosztorys_model.dart';

class PozycjaTile extends StatefulWidget {
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
  State<PozycjaTile> createState() => _PozycjaTileState();
}

class _PozycjaTileState extends State<PozycjaTile> {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasAiSuggestion = widget.pozycja.aiSuggestedPrice != null;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: hasAiSuggestion
            ? BorderSide(color: cs.tertiary.withOpacity(0.4))
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
              // Główna linia
              Row(
                children: [
                  if (widget.pozycja.knrNumer != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.pozycja.knrNumer!,
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.pozycja.opis,
                      style: theme.textTheme.bodyMedium,
                      maxLines: _expanded ? null : 2,
                      overflow:
                          _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmtWartosc(widget.pozycja.wartosc),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumField(
                        label: 'Cena jedn. (zł)',
                        controller: _cenaCtrl,
                        onSubmitted: (_) => _commit(),
                        aiValue: widget.pozycja.aiSuggestedPrice,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.check, size: 20),
                      tooltip: 'Zapisz',
                      color: cs.primary,
                      onPressed: _commit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Usuń pozycję',
                      color: cs.error,
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
    this.aiValue,
  });

  final String label;
  final TextEditingController controller;
  final void Function(String) onSubmitted;
  final double? aiValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
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
                        size: 14, color: cs.tertiary),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
