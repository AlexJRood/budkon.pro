part of importer_field_mapper;

// ── Parsed schema types ────────────────────────────────────────────────────

class _ModelSchema {
  final String name;
  final List<_TargetFieldSpec> fields;
  final Color accent;

  const _ModelSchema({
    required this.name,
    required this.fields,
    required this.accent,
  });

  List<_TargetFieldSpec> get required =>
      fields.where((f) => f.required).toList(growable: false);

  List<_TargetFieldSpec> get optional =>
      fields.where((f) => !f.required).toList(growable: false);

  List<_TargetFieldSpec> get relations =>
      fields.where((f) => f.isRelation && f.relatedModel != null).toList(growable: false);

  int get fieldCount => fields.length;
}

// ── Colour palette for models ──────────────────────────────────────────────

const _kModelAccents = [
  Color(0xFF378ADD), // blue
  Color(0xFF1D9E75), // teal
  Color(0xFFBA7517), // amber
  Color(0xFF7F77DD), // purple
  Color(0xFFD85A30), // coral
  Color(0xFF639922), // green
  Color(0xFFD4537E), // pink
  Color(0xFF888780), // gray
];

Color _accentForIndex(int i) => _kModelAccents[i % _kModelAccents.length];

// ── Entry point ────────────────────────────────────────────────────────────

void showSchemaExplorer({
  required BuildContext context,
  required ThemeColors theme,
  required ImportOptions options,
}) {
  final models = _buildModels(options.targetModels);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _SchemaExplorerSheet(theme: theme, models: models),
    ),
  );
}

List<_ModelSchema> _buildModels(Map<String, dynamic> raw) {
  final entries = raw.entries.toList();
  return List.generate(entries.length, (i) {
    final entry = entries[i];
    return _ModelSchema(
      name: entry.key,
      fields: _extractFieldSpecsFromRawSpec(entry.value),
      accent: _accentForIndex(i),
    );
  });
}

// ── Sheet ──────────────────────────────────────────────────────────────────

class _SchemaExplorerSheet extends StatefulWidget {
  final ThemeColors theme;
  final List<_ModelSchema> models;

  const _SchemaExplorerSheet({required this.theme, required this.models});

  @override
  State<_SchemaExplorerSheet> createState() => _SchemaExplorerSheetState();
}

class _SchemaExplorerSheetState extends State<_SchemaExplorerSheet> {
  String _search = '';
  bool _onlyRequired = false;
  bool _onlyRelations = false;
  String? _expandedModel;

  List<_ModelSchema> get _filtered {
    final q = _search.trim().toLowerCase();
    return widget.models.where((m) {
      if (q.isEmpty) return true;
      if (m.name.toLowerCase().contains(q)) return true;
      return m.fields.any((f) =>
          f.name.toLowerCase().contains(q) ||
          (f.relatedModel?.toLowerCase().contains(q) ?? false));
    }).toList(growable: false);
  }

  List<({String from, String to, Color fromAccent})> get _allRelations {
    final out = <({String from, String to, Color fromAccent})>[];
    for (final m in widget.models) {
      for (final f in m.relations) {
        out.add((from: m.name, to: f.relatedModel!, fromAccent: m.accent));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final filtered = _filtered;
    final allRelations = _allRelations;

    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(100)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dashboardBoarder.withAlpha(120),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.themeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: theme.themeColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schema Explorer'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${widget.models.length} ${'modeli'.tr} · ${allRelations.length} ${'relacji FK'.tr}',
                        style: TextStyle(
                          color: theme.textColor.withAlpha(160),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: theme.textColor.withAlpha(180)),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dashboardBoarder.withAlpha(80)),

          // Search + filters
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: TextStyle(color: theme.textColor, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: theme.textColor.withAlpha(150)),
                      hintText: 'Szukaj modelu lub pola...'.tr,
                      hintStyle: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12),
                      filled: true,
                      fillColor: theme.adPopBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dashboardBoarder.withAlpha(80)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dashboardBoarder.withAlpha(80)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.themeColor.withAlpha(160)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  theme: theme,
                  label: 'Wymagane',
                  icon: Icons.circle,
                  active: _onlyRequired,
                  activeColor: Colors.redAccent,
                  onTap: () => setState(() => _onlyRequired = !_onlyRequired),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  theme: theme,
                  label: 'FK',
                  icon: Icons.call_split_rounded,
                  active: _onlyRelations,
                  activeColor: Colors.purpleAccent,
                  onTap: () => setState(() => _onlyRelations = !_onlyRelations),
                ),
              ],
            ),
          ),

          // FK relation strip
          if (allRelations.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dashboardBoarder.withAlpha(70)),
                ),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Relacje:'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(150),
                      fontSize: 11,
                    ),
                  ),
                  ...allRelations.map((r) => _RelationBadge(
                        theme: theme,
                        from: r.from,
                        to: r.to,
                        accent: r.fromAccent,
                      )),
                ],
              ),
            ),

          // Model cards
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Brak modeli pasujących do wyszukiwania.'.tr,
                      style: TextStyle(color: theme.textColor.withAlpha(160)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final model = filtered[i];
                      final isExpanded = _expandedModel == model.name;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ModelCard(
                          theme: theme,
                          model: model,
                          isExpanded: isExpanded,
                          onlyRequired: _onlyRequired,
                          onlyRelations: _onlyRelations,
                          onToggle: () => setState(() {
                            _expandedModel = isExpanded ? null : model.name;
                          }),
                        ),
                      );
                    },
                  ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dashboardBoarder.withAlpha(70))),
            ),
            child: Row(
              children: [
                _LegendItem(
                  color: Colors.redAccent,
                  label: 'wymagane',
                  filled: true,
                ),
                const SizedBox(width: 14),
                _LegendItem(
                  color: theme.dashboardBoarder.withAlpha(160),
                  label: 'opcjonalne',
                  filled: true,
                ),
                const SizedBox(width: 14),
                _TypeBadge(label: 'FK', color: Colors.purple),
                const SizedBox(width: 4),
                _TypeBadge(label: 'str', color: Colors.blue),
                const SizedBox(width: 4),
                _TypeBadge(label: 'int', color: Colors.green),
                const SizedBox(width: 4),
                _TypeBadge(label: 'date', color: Colors.orange),
                const SizedBox(width: 4),
                _TypeBadge(label: 'bool', color: Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model card ─────────────────────────────────────────────────────────────

class _ModelCard extends StatelessWidget {
  final ThemeColors theme;
  final _ModelSchema model;
  final bool isExpanded;
  final bool onlyRequired;
  final bool onlyRelations;
  final VoidCallback onToggle;

  const _ModelCard({
    required this.theme,
    required this.model,
    required this.isExpanded,
    required this.onlyRequired,
    required this.onlyRelations,
    required this.onToggle,
  });

  List<_TargetFieldSpec> get _visibleFields {
    var fields = model.fields;
    if (onlyRequired) fields = fields.where((f) => f.required).toList();
    if (onlyRelations) fields = fields.where((f) => f.isRelation).toList();
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    final accent = model.accent;
    final visible = _visibleFields;
    const previewCount = 5;
    final preview = visible.take(previewCount).toList();
    final overflow = visible.length - previewCount;
    final relations = model.relations;

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(100)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          onExpansionChanged: (_) => onToggle(),
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  model.name,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Stats chips
              _StatChip(
                label: '${model.fieldCount}',
                icon: Icons.view_column_rounded,
                theme: theme,
              ),
              const SizedBox(width: 6),
              if (model.required.isNotEmpty)
                _StatChip(
                  label: '${model.required.length} req',
                  icon: Icons.circle,
                  theme: theme,
                  color: Colors.redAccent,
                ),
              if (model.required.isNotEmpty) const SizedBox(width: 6),
              if (relations.isNotEmpty)
                _StatChip(
                  label: '${relations.length} FK',
                  icon: Icons.call_split_rounded,
                  theme: theme,
                  color: Colors.purpleAccent,
                ),
            ],
          ),
          // Collapsed summary
          subtitle: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 20),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...preview.map((f) => _FieldPill(theme: theme, field: f)),
                if (overflow > 0)
                  Text(
                    '+$overflow ${'więcej'.tr}',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(140),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          // Expanded full field table
          children: [
            Divider(height: 1, color: theme.dashboardBoarder.withAlpha(60)),
            const SizedBox(height: 10),
            // Required fields
            if (model.required.isNotEmpty) ...[
              _SectionLabel(theme: theme, label: 'Wymagane'.tr, color: Colors.redAccent),
              const SizedBox(height: 6),
              ...model.required.map((f) => _FieldRow(theme: theme, field: f)),
              const SizedBox(height: 10),
            ],
            // Optional fields
            if (model.optional.isNotEmpty) ...[
              _SectionLabel(theme: theme, label: 'Opcjonalne'.tr, color: theme.textColor.withAlpha(160)),
              const SizedBox(height: 6),
              ...model.optional.map((f) => _FieldRow(theme: theme, field: f)),
            ],
            // FK summary
            if (relations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: theme.dashboardBoarder.withAlpha(50)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.call_split_rounded, size: 13, color: Colors.purpleAccent.withAlpha(200)),
                  const SizedBox(width: 6),
                  Text(
                    'FK →'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    children: relations.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple.withAlpha(18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withAlpha(60)),
                        ),
                        child: Text(
                          f.relatedModel!,
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final ThemeColors theme;
  final _TargetFieldSpec field;

  const _FieldRow({required this.theme, required this.field});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: field.required ? Colors.redAccent : theme.dashboardBoarder.withAlpha(160),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              field.name,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          _FieldTypeBadge(type: field.type, theme: theme),
          if (field.relatedModel != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.purple.withAlpha(50)),
              ),
              child: Text(
                field.relatedModel!,
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldPill extends StatelessWidget {
  final ThemeColors theme;
  final _TargetFieldSpec field;

  const _FieldPill({required this.theme, required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: field.required
            ? Colors.redAccent.withAlpha(14)
            : theme.dashboardContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: field.required
              ? Colors.redAccent.withAlpha(60)
              : theme.dashboardBoarder.withAlpha(80),
        ),
      ),
      child: Text(
        field.name,
        style: TextStyle(
          color: field.required
              ? Colors.redAccent.shade200
              : theme.textColor.withAlpha(180),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _FieldTypeBadge extends StatelessWidget {
  final String type;
  final ThemeColors theme;

  const _FieldTypeBadge({required this.type, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase();
    final (label, color) = switch (t) {
      'foreignkey' || 'onetoonefield' || 'manytomanyfield' => ('FK', Colors.purple),
      'charfield' || 'textfield' || 'emailfield' || 'urlfield' || 'slugfield' => ('str', Colors.blue),
      'integerfield' ||
      'positiveintegerfield' ||
      'positivesmallintegerfield' ||
      'smallintegerfield' ||
      'bigintegerfield' ||
      'floatfield' ||
      'decimalfield' =>
        ('num', Colors.green),
      'booleanfield' || 'nullbooleanfield' => ('bool', Colors.teal),
      'datefield' || 'datetimefield' || 'timefield' => ('date', Colors.orange),
      _ => (type.isEmpty ? '?' : type.length > 6 ? '${type.substring(0, 5)}…' : type, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withAlpha(220),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RelationBadge extends StatelessWidget {
  final ThemeColors theme;
  final String from;
  final String to;
  final Color accent;

  const _RelationBadge({
    required this.theme,
    required this.from,
    required this.to,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withAlpha(16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            from,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.arrow_forward_rounded, size: 11, color: accent.withAlpha(180)),
          ),
          Text(
            to,
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.theme,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final IconData icon;
  final Color? color;

  const _StatChip({
    required this.theme,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? theme.textColor.withAlpha(140);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: c),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.theme,
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withAlpha(20) : theme.adPopBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor.withAlpha(120) : theme.dashboardBoarder.withAlpha(100),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? activeColor : theme.textColor.withAlpha(160)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : theme.textColor.withAlpha(160),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool filled;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withAlpha(220),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
