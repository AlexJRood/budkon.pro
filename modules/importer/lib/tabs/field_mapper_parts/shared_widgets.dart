part of importer_field_mapper;

class _PanelHeader extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String subtitle;

  const _PanelHeader({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: theme.textColor.withAlpha(170),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
