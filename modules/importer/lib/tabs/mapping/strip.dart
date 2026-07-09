import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class SelectionStripOptions extends StatelessWidget {
  final ThemeColors theme;
  final String? selectionKey;

  final bool stripSourceValue;
  final bool stripSourceKey;
  final bool stripLeadingSeparator;
  final bool stripTrailingSeparator;

  final ValueChanged<bool> onStripSourceValueChanged;
  final ValueChanged<bool> onStripSourceKeyChanged;
  final ValueChanged<bool> onStripLeadingSeparatorChanged;
  final ValueChanged<bool> onStripTrailingSeparatorChanged;

  const SelectionStripOptions({
    super.key,
    required this.theme,
    required this.selectionKey,
    required this.stripSourceValue,
    required this.stripSourceKey,
    required this.stripLeadingSeparator,
    required this.stripTrailingSeparator,
    required this.onStripSourceValueChanged,
    required this.onStripSourceKeyChanged,
    required this.onStripLeadingSeparatorChanged,
    required this.onStripTrailingSeparatorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final keyLabel = selectionKey?.trim().isNotEmpty == true
        ? selectionKey!
        : 'KLUCZ';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Co usunąć z kolumny źródłowej?'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(230),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Zaznacz tylko to, co naprawdę chcesz zostawić poza kolumną źródłową.'
                .tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Usuń samą wartość'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
              ),
            ),
            subtitle: Text(
              'Np. po wyciągnięciu numeru: "123-456-78-90"'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 11,
              ),
            ),
            value: stripSourceValue,
            onChanged: (v) {
              onStripSourceValueChanged(v ?? false);
            },
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Usuń słowo-klucz'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
              ),
            ),
            subtitle: Text(
              'Np. "$keyLabel"'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 11,
              ),
            ),
            value: stripSourceKey,
            onChanged: (v) {
              onStripSourceKeyChanged(v ?? false);
            },
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Usuń separator przed dopasowaniem'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
              ),
            ),
            subtitle: Text(
              'Np. ":" , "-" albo ";" przed kluczem / wartością.'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 11,
              ),
            ),
            value: stripLeadingSeparator,
            onChanged: (v) {
              onStripLeadingSeparatorChanged(v ?? false);
            },
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Usuń separator po wartości'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
              ),
            ),
            subtitle: Text(
              'Np. przecinek, średnik lub myślnik po wyciągniętej wartości.'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 11,
              ),
            ),
            value: stripTrailingSeparator,
            onChanged: (v) {
              onStripTrailingSeparatorChanged(v ?? false);
            },
          ),
        ],
      ),
    );
  }
}