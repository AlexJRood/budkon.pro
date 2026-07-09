part of importer_field_mapper;

class _MapperHeaderAndToolbar extends StatelessWidget {
  final ThemeColors theme;
  final bool isCompact;
  final Widget toolbar;

  const _MapperHeaderAndToolbar({
    required this.theme,
    required this.isCompact,
    required this.toolbar,
  });

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mapper pól – widok wizualny'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Najpierw wybierz model docelowy, potem przypnij kolumny do pól. '
                  'Pola relacyjne są oznaczone jako FK.'
              .tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(178),
            fontSize: 11,
          ),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 10),
          toolbar,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: toolbar,
          ),
        ),
      ],
    );
  }
}
