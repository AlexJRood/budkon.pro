part of 'issue_details_dialog.dart';

extension _IssueDetailsDialogWidgets on _IssueDetailsDialogState {
  Color _softSurface(
      BuildContext context, {
        double darkOpacity = 0.10,
        double lightOpacity = 0.04,
      }) {
    final feedbackTheme = FeedbackTheme.of(context);
    final colorScheme = feedbackTheme.colorScheme;
    final isDark = feedbackTheme.brightness == Brightness.dark;

    return isDark
        ? colorScheme.surfaceContainerHighest.withOpacity(darkOpacity)
        : colorScheme.onSurface.withOpacity(lightOpacity);
  }

  Widget _buildInfoChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    Color? borderColor,
    Color? textColor,
  }) {
    final colorScheme = FeedbackTheme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? colorScheme.onSurface.withOpacity(0.18),
        ),
        color: _softSurface(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor ?? colorScheme.onSurface.withOpacity(0.9),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor ?? colorScheme.onSurface.withOpacity(0.92),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final colorScheme = FeedbackTheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.95),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
      BuildContext context, {
        String? hintText,
      }) {
    final feedbackTheme = FeedbackTheme.of(context);
    final colorScheme = feedbackTheme.colorScheme;
    final isDark = feedbackTheme.brightness == Brightness.dark;
    final theme = ref.watch(themeColorsProvider);

    final fieldBackground = isDark
        ? colorScheme.surface.withOpacity(0.45)
        : colorScheme.surface;

    final borderColor = theme.themeColor;
    final hintColor = colorScheme.onSurface.withOpacity(0.55);

    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: fieldBackground,
      hintStyle: TextStyle(color: hintColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: borderColor.withOpacity(0.45),
        ),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _responsibleTile({bool dense = false}) {
    final detail = ref.read(feedbackDetailProvider(widget.issue.id)).data;
    final form = ref.read(feedbackDetailFormProvider(widget.issue.id));
    final colorScheme = FeedbackTheme.of(context).colorScheme;

    final currentId = form?.responsiblePerson ?? detail?.responsiblePerson;
    final member = _memberById(currentId);

    return InkWell(
      onTap: _showResponsiblePicker,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: FeedbackTheme.of(context).feedbackSheetColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: FeedbackTheme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(.2),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: dense ? 14 : 18,
              backgroundImage:
              (member?.avatar != null) ? NetworkImage(member!.avatar!) : null,
              child: (member?.avatar == null)
                  ? Text(
                (member?.name.isNotEmpty == true
                    ? member!.name[0].toUpperCase()
                    : '—'),
              )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                member?.name ??
                    (currentId == null ? 'Select person...' : 'ID #$currentId'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.95),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: colorScheme.onSurface.withOpacity(0.95),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      FeedbackModel currentIssue,
      bool solvedValue,
      ) {
    final colorScheme = FeedbackTheme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  currentIssue.title ?? 'Untitled issue',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                context: context,
                icon: Icons.radio_button_checked,
                label: solvedValue ? 'Solved' : 'Open',
                borderColor: solvedValue
                    ? Colors.green.withOpacity(0.45)
                    : Colors.orange.withOpacity(0.45),
                textColor: solvedValue ? Colors.green : Colors.orange,
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.tag,
                label: '# ID: ${currentIssue.id}',
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.calendar_today_outlined,
                label:
                'Date: ${currentIssue.createdAt.toString().replaceFirst('.000', '')}',
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.person_outline,
                label: 'Reporter: ${currentIssue.user ?? '—'}',
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.assignment_ind_outlined,
                label: 'Responsible: ${currentIssue.responsiblePerson ?? '—'}',
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.error_outline,
                label: 'ProblemID: ${currentIssue.problem ?? '—'}',
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.apps,
                label: 'App: ${currentIssue.app ?? '—'}',
              ),
              _buildInfoChip(
                context: context,
                icon: Icons.route_outlined,
                label: 'Path: ${currentIssue.path ?? '—'}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveDetailsPanels({
    required BuildContext context,
    required FeedbackModel currentIssue,
    required Widget formPanel,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 320,
            child: _buildImagePanel(context, currentIssue),
          ),
          const SizedBox(height: 12),
          formPanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: SizedBox(
            height: 520,
            child: _buildImagePanel(context, currentIssue),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 13,
          child: formPanel,
        ),
      ],
    );
  }

  Widget _buildImagePanel(
      BuildContext context,
      FeedbackModel currentIssue,
      ) {
    final feedbackTheme = FeedbackTheme.of(context);
    final colorScheme = feedbackTheme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: feedbackTheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surface,
        border: Border.all(
          color: feedbackTheme.brightness == Brightness.dark
              ? colorScheme.onSurface.withOpacity(0.10)
              : colorScheme.onSurface.withOpacity(0.14),
        ),
        borderRadius: isMobile ? BorderRadius.circular(12) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task image',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _softSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: (currentIssue.image != null &&
                  currentIssue.image!.isNotEmpty)
                  ? InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  currentIssue.image!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      '=== ISSUE IMAGE ERROR ===\n'
                          'issueId: ${currentIssue.id}\n'
                          'url: ${currentIssue.image}\n'
                          'error: $error',
                    );

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 42,
                            color:
                            colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: colorScheme.onSurface
                                  .withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.onSurface,
                      ),
                    );
                  },
                ),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 42,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No image attached to this issue',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if ((currentIssue.path ?? '').isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _softSurface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.10),
                ),
              ),
              child: SelectableText(
                currentIssue.path ?? '',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.82),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}