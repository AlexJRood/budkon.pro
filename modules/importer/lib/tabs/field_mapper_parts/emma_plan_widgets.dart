part of importer_field_mapper;

class _EmmaMapperPlanSection extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String emptyText;
  final List<dynamic> items;
  final Widget Function(dynamic item) itemBuilder;

  const _EmmaMapperPlanSection({
    required this.theme,
    required this.title,
    required this.emptyText,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(110),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontSize: 12,
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: itemBuilder(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmmaMapperPlanCard extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color? accentColor;

  const _EmmaMapperPlanCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? theme.themeColor;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withAlpha(70),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(185),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
