part of importer_field_mapper;

// ── Column type detection ──────────────────────────────────────────────────

enum _ColType { email, phone, date, number, url, zip, text }

class _ColTypeHint {
  final _ColType type;
  final IconData icon;
  final String label;
  final Color color;

  const _ColTypeHint(this.type, this.icon, this.label, this.color);
}

_ColTypeHint _detectColumnType(String colName, List<String> samples) {
  final name = colName.toLowerCase();

  // Name-based fast path
  if (_matchesAny(name, ['email', 'e-mail', 'mail'])) {
    return _ColTypeHint(_ColType.email, Icons.alternate_email_rounded, 'email', Colors.blue.shade300);
  }
  if (_matchesAny(name, ['phone', 'tel', 'mobile', 'fax', 'telefon', 'komórka'])) {
    return _ColTypeHint(_ColType.phone, Icons.phone_rounded, 'telefon', Colors.green.shade300);
  }
  if (_matchesAny(name, ['date', 'data', 'created', 'updated', 'birth', 'urodzin', 'czas', 'time', 'timestamp'])) {
    return _ColTypeHint(_ColType.date, Icons.calendar_today_rounded, 'data', Colors.orange.shade300);
  }
  if (_matchesAny(name, ['url', 'www', 'website', 'link', 'href', 'strona'])) {
    return _ColTypeHint(_ColType.url, Icons.link_rounded, 'URL', Colors.purple.shade300);
  }
  if (_matchesAny(name, ['zip', 'postal', 'postcode', 'kod', 'pocztowy'])) {
    return _ColTypeHint(_ColType.zip, Icons.local_post_office_rounded, 'kod poczt.', Colors.teal.shade300);
  }

  // Sample-based detection (majority vote over non-empty samples)
  final nonEmpty = samples.where((s) => s.trim().isNotEmpty).toList();
  if (nonEmpty.isEmpty) {
    return _ColTypeHint(_ColType.text, Icons.text_fields_rounded, 'tekst', Colors.grey.shade400);
  }

  int emailHits = 0, phoneHits = 0, dateHits = 0, numberHits = 0, urlHits = 0, zipHits = 0;

  for (final s in nonEmpty) {
    if (_kEmailRe.hasMatch(s)) emailHits++;
    if (_kPhoneRe.hasMatch(s)) phoneHits++;
    if (_kDateRe.hasMatch(s)) dateHits++;
    if (_kNumberRe.hasMatch(s)) numberHits++;
    if (_kUrlRe.hasMatch(s)) urlHits++;
    if (_kZipRe.hasMatch(s)) zipHits++;
  }

  final threshold = (nonEmpty.length * 0.6).ceil();
  if (emailHits >= threshold) return _ColTypeHint(_ColType.email, Icons.alternate_email_rounded, 'email', Colors.blue.shade300);
  if (urlHits >= threshold) return _ColTypeHint(_ColType.url, Icons.link_rounded, 'URL', Colors.purple.shade300);
  if (phoneHits >= threshold) return _ColTypeHint(_ColType.phone, Icons.phone_rounded, 'telefon', Colors.green.shade300);
  if (zipHits >= threshold) return _ColTypeHint(_ColType.zip, Icons.local_post_office_rounded, 'kod poczt.', Colors.teal.shade300);
  if (dateHits >= threshold) return _ColTypeHint(_ColType.date, Icons.calendar_today_rounded, 'data', Colors.orange.shade300);
  if (numberHits >= threshold) return _ColTypeHint(_ColType.number, Icons.tag_rounded, 'liczba', Colors.cyan.shade300);

  return _ColTypeHint(_ColType.text, Icons.text_fields_rounded, 'tekst', Colors.grey.shade400);
}

bool _matchesAny(String name, List<String> keywords) =>
    keywords.any((k) => name.contains(k));

final _kEmailRe = RegExp(r'^[\w.+-]+@[\w-]+\.\w{2,}$');
final _kPhoneRe = RegExp(r'^[+\d\s\-().]{6,20}$');
final _kDateRe = RegExp(r'(\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})');
final _kNumberRe = RegExp(r'^-?\d+([.,]\d+)?$');
final _kUrlRe = RegExp(r'^https?://', caseSensitive: false);
final _kZipRe = RegExp(r'^\d{2}-\d{3}$|^\d{5}$');

// ── Panel ──────────────────────────────────────────────────────────────────

class _SourceColumnsPanel extends StatelessWidget {
  final ThemeColors theme;
  final List<String> columns;
  final List<String> previewColumns;
  final List<List<String>> previewData;
  final ImportFormState formState;
  final String? selectedColumn;
  final String sourceSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSelectColumn;

  const _SourceColumnsPanel({
    required this.theme,
    required this.columns,
    required this.previewColumns,
    required this.previewData,
    required this.formState,
    required this.selectedColumn,
    required this.sourceSearch,
    required this.onSearchChanged,
    required this.onSelectColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(100)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _PanelHeader(
            theme: theme,
            title: 'Kolumny źródłowe'.tr,
            subtitle: 'Kliknij kolumnę, żeby ustawić ją jako aktywną.'.tr,
          ),
          const SizedBox(height: 10),
          EmmaUiAnchorTarget(
            // @emma-backend: ImporterEmmaAnchors.importMapperSourceSearch
            anchorKey: 'importer.mapper.source_search',
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.dashboardContainer,
                labelText: 'Szukaj kolumny'.tr,
                labelStyle: TextStyle(
                  color: theme.textColor.withAlpha(160),
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: columns.isEmpty
                ? Center(
                    child: Text(
                      'Brak kolumn pasujących do wyszukiwania.'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(170),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: columns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final col = columns[index];
                      final mappings = formState.fieldMappings
                          .where((m) => m.columnName == col)
                          .toList(growable: false);

                      final samples = _samplesForColumn(
                        previewColumns: previewColumns,
                        previewData: previewData,
                        columnName: col,
                        maxItems: 3,
                      );

                      return _SourceColumnCard(
                        theme: theme,
                        columnName: col,
                        isSelected: selectedColumn == col,
                        mappings: mappings,
                        samples: samples,
                        onTap: () => onSelectColumn(col),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SourceColumnCard extends StatelessWidget {
  final ThemeColors theme;
  final String columnName;
  final bool isSelected;
  final List<FieldMappingRule> mappings;
  final List<String> samples;
  final VoidCallback onTap;

  const _SourceColumnCard({
    required this.theme,
    required this.columnName,
    required this.isSelected,
    required this.mappings,
    required this.samples,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = mappings.isNotEmpty;
    final typeHint = _detectColumnType(columnName, samples);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.themeColor.withAlpha(26)
              : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.themeColor
                : theme.dashboardBoarder.withAlpha(120),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMapped
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isMapped
                      ? Colors.greenAccent.shade400
                      : theme.textColor.withAlpha(130),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    columnName,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: typeHint.label,
                    child: Icon(
                      typeHint.icon,
                      size: 14,
                      color: typeHint.color.withAlpha(200),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.themeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (mappings.isEmpty)
              Text(
                'Jeszcze nieprzypisana'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(160),
                  fontSize: 11,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: mappings.map((m) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.adPopBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.dashboardBoarder.withAlpha(100),
                      ),
                    ),
                    child: Text(
                      '${m.targetModel}.${m.targetField}',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (samples.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: samples.map((s) {
                  return Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.adPopBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(210),
                        fontSize: 10,
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
