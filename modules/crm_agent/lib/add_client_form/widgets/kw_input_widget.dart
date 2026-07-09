import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Kody wydziałów KW z systemu EKW MS
const _kwCourts = [
  'BI1B', 'BI1L', 'BI1M', 'BI1P', 'BI2B',
  'BY1B', 'BY1I', 'BY1S', 'BY1T', 'BY1W', 'BY2B',
  'EL1E', 'EL1L', 'EL1P', 'EL1R', 'EL1S', 'EL1W', 'EL2E',
  'GD1A', 'GD1C', 'GD1G', 'GD1K', 'GD1M', 'GD1P', 'GD1T', 'GD1W', 'GD2G', 'GD4G',
  'GL1B', 'GL1G', 'GL1J', 'GL1K', 'GL1L', 'GL1M', 'GL1R', 'GL1S', 'GL1T', 'GL1Z', 'GL2G', 'GL4G',
  'GR1G', 'GR1J',
  'JG1J', 'JG1L', 'JG1Z',
  'KA1B', 'KA1C', 'KA1D', 'KA1G', 'KA1I', 'KA1K', 'KA1M', 'KA1R', 'KA1S', 'KA1T', 'KA1W', 'KA1Z', 'KA2G',
  'KB1K', 'KB1O', 'KB1S',
  'KI1I', 'KI1J', 'KI1K', 'KI1L', 'KI1O', 'KI1P', 'KI1S', 'KI2K',
  'KN1K', 'KN1N', 'KN1S',
  'KO1G', 'KO1K', 'KO1N', 'KO1O', 'KO1S',
  'KR1A', 'KR1B', 'KR1C', 'KR1I', 'KR1K', 'KR1L', 'KR1M', 'KR1N', 'KR1P', 'KR1S', 'KR1T', 'KR1W', 'KR2K',
  'KS1B', 'KS1J', 'KS1K',
  'LD1G', 'LD1L', 'LD1M', 'LD1O', 'LD1P', 'LD1R', 'LD1S', 'LD1W', 'LD1Z', 'LD2G',
  'LE1L',
  'LM1L',
  'LO1G', 'LO1L', 'LO1O', 'LO1P',
  'LU1B', 'LU1L', 'LU1P', 'LU1R', 'LU2L',
  'NS1N', 'NS1S', 'NS1T',
  'OL1E', 'OL1G', 'OL1L', 'OL1N', 'OL1O', 'OL2O',
  'OP1K', 'OP1N', 'OP1O', 'OP1P', 'OP1S', 'OP2O',
  'OS1C', 'OS1I', 'OS1O',
  'PI1S', 'PI1T',
  'PL1P',
  'PO1B', 'PO1C', 'PO1F', 'PO1G', 'PO1K', 'PO1L', 'PO1M', 'PO1N', 'PO1O', 'PO1P', 'PO1S', 'PO1T', 'PO1W', 'PO2P',
  'PT1O', 'PT1P', 'PT1R', 'PT1T',
  'RA1G', 'RA1R', 'RA1S',
  'RZ1G', 'RZ1J', 'RZ1L', 'RZ1R', 'RZ1S', 'RZ1T', 'RZ2R',
  'SD1G', 'SD1K', 'SD1L', 'SD1S',
  'SG1G',
  'SI1G', 'SI1S',
  'SK1G', 'SK1K', 'SK1S', 'SK1T',
  'SL1B', 'SL1C', 'SL1S',
  'SN1N', 'SN1S',
  'SR1S',
  'ST1B', 'ST1K', 'ST1S',
  'SU1G', 'SU1S',
  'SW1G',
  'SZ1G', 'SZ1N', 'SZ1P', 'SZ1S', 'SZ1W', 'SZ2G',
  'TA1B', 'TA1D', 'TA1M', 'TA1T',
  'TO1B', 'TO1G', 'TO1I', 'TO1T', 'TO1W', 'TO2T',
  'WA1A', 'WA1K', 'WA1L', 'WA1M', 'WA1N', 'WA1O', 'WA1P', 'WA1R', 'WA1W', 'WA2M',
  'WL1G', 'WL1L', 'WL1W',
  'WR1A', 'WR1K', 'WR1L', 'WR1O', 'WR1S', 'WR1T', 'WR1W', 'WR2W',
  'ZA1B', 'ZA1Z',
  'ZG1G', 'ZG1K', 'ZG1M', 'ZG1N', 'ZG1S', 'ZG1Z', 'ZG2G',
];

class KwInputWidget extends ConsumerStatefulWidget {
  final TextEditingController kwController;
  final void Function(String value) onChanged;

  const KwInputWidget({
    super.key,
    required this.kwController,
    required this.onChanged,
  });

  @override
  ConsumerState<KwInputWidget> createState() => _KwInputWidgetState();
}

class _KwInputWidgetState extends ConsumerState<KwInputWidget> {
  String? _selectedCourt;
  final _numberCtrl = TextEditingController();
  final _digitCtrl = TextEditingController();
  final _courtSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _parseExisting();
  }

  void _parseExisting() {
    final existing = widget.kwController.text.trim();
    if (existing.isEmpty) return;
    final parts = existing.split('/');
    if (parts.length == 3) {
      _selectedCourt = _kwCourts.contains(parts[0]) ? parts[0] : null;
      _numberCtrl.text = parts[1];
      _digitCtrl.text = parts[2];
    }
  }

  void _notify() {
    if (_selectedCourt == null || _numberCtrl.text.isEmpty || _digitCtrl.text.isEmpty) return;
    final full = '${_selectedCourt!}/${_numberCtrl.text}/${_digitCtrl.text}';
    widget.kwController.text = full;
    widget.onChanged(full);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _digitCtrl.dispose();
    _courtSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCourtPicker(BuildContext context, ThemeColors theme) async {
    String search = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.dashboardContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final filtered = _kwCourts.where((c) => c.contains(search.toUpperCase())).toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: true,
                    controller: _courtSearchCtrl,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Szukaj kodu (np. WA1M)',
                      hintStyle: TextStyle(color: theme.textColor.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.search, color: theme.textColor.withOpacity(0.5)),
                      filled: true,
                      fillColor: theme.dashboardBoarder,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(filtered[i], style: TextStyle(color: theme.textColor, fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                      selected: filtered[i] == _selectedCourt,
                      selectedTileColor: theme.themeColor.withOpacity(0.15),
                      onTap: () {
                        setState(() {});
                        this.setState(() => _selectedCourt = filtered[i]);
                        _courtSearchCtrl.clear();
                        Navigator.pop(ctx);
                        _notify();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final borderColor = theme.textColor.withOpacity(0.2);
    final labelStyle = TextStyle(color: theme.textColor.withOpacity(0.5), fontSize: 11);
    final inputStyle = TextStyle(color: theme.textColor, fontSize: 15, fontFamily: 'monospace', letterSpacing: 1.2);
    final hintColor = theme.textColor.withOpacity(0.25);
    final divColor = theme.textColor.withOpacity(0.2);

    InputDecoration _fieldDeco({required String hint}) => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontFamily: 'monospace'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Numer Księgi Wieczystej', style: labelStyle),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Kod wydziału
                GestureDetector(
                  onTap: () => _showCourtPicker(context, theme),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: divColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCourt ?? 'Wydział',
                          style: _selectedCourt != null
                              ? inputStyle
                              : TextStyle(color: hintColor, fontSize: 13),
                        ),
                        Icon(Icons.arrow_drop_down, color: theme.textColor.withOpacity(0.4), size: 18),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: divColor),
                // Numer 8-cyfrowy
                Expanded(
                  child: TextField(
                    controller: _numberCtrl,
                    style: inputStyle,
                    decoration: _fieldDeco(hint: '00000000'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                    onChanged: (_) => _notify(),
                  ),
                ),
                Container(width: 1, color: divColor),
                // Cyfra kontrolna
                SizedBox(
                  width: 52,
                  child: TextField(
                    controller: _digitCtrl,
                    style: inputStyle,
                    textAlign: TextAlign.center,
                    decoration: _fieldDeco(hint: '0'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
