part of 'issue_details_dialog.dart';

class _IssueDetailsDialogState extends ConsumerState<IssueDetailsDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;
  late final TextEditingController _pathController;

  bool _controllersSeeded = false;
  bool _isSaving = false;
  int? _lastSeededIssueId;

  int? _currentUserIdOrNull() {
    final u =
    ref.read(userProvider).maybeWhen(data: (u) => u, orElse: () => null);
    if (u == null) return null;
    return int.tryParse(u.userId.toString());
  }

  List<_MemberLite> _companyMembers() {
    final u =
    ref.read(userProvider).maybeWhen(data: (x) => x, orElse: () => null);
    if (u == null) return const [];

    return (u.companyMembers ?? [])
        .map<_MemberLite>(
          (m) => _MemberLite(
        m.id is int ? m.id as int : int.tryParse(m.id.toString()) ?? -1,
        '${(m.firstName ?? '').toString()} ${(m.lastName ?? '').toString()}'
            .trim(),
        (m.avatar?.toString().isNotEmpty ?? false)
            ? m.avatar.toString()
            : null,
      ),
    )
        .where((m) => m.id > 0 && m.name.isNotEmpty)
        .toList();
  }

  _MemberLite? _memberById(int? id) {
    if (id == null) return null;
    final list = _companyMembers();
    try {
      return list.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  void _showSafeSnackBar(String message) {
    final rootContext = ref.read(navigationService).navigatorKey.currentContext;
    if (rootContext == null) {
      debugPrint('SnackBar skipped: root context is null');
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(rootContext);
    if (messenger == null) {
      debugPrint('SnackBar skipped: no ScaffoldMessenger found');
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canEditIssues(WidgetRef ref) {
    return ref.watch(canAccessModuleProvider('stuff'));
  }

  String? _safeDropdownValue(
      String? value,
      List<Map<String, String>> options,
      ) {
    if (value == null || value.isEmpty) return null;
    final exists = options.any((e) => e['value'] == value);
    return exists ? value : null;
  }

  void _syncControllersFromForm(
      FeedbackModel currentIssue,
      FeedbackDetailForm? form,
      ) {
    if (form == null) return;
    if (_controllersSeeded && _lastSeededIssueId == currentIssue.id) return;

    _controllersSeeded = true;
    _lastSeededIssueId = currentIssue.id;

    final latestTitle = form.title ?? currentIssue.title ?? '';
    final latestDescription = form.description ?? currentIssue.description ?? '';
    final latestNote = form.note ?? currentIssue.note ?? '';
    final latestPath = form.path ?? currentIssue.path ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _titleController.text = latestTitle;
      _descriptionController.text = latestDescription;
      _noteController.text = latestNote;
      _pathController.text = latestPath;

      debugPrint(
        '=== CONTROLLERS SYNCED ===\n'
            'issueId: ${currentIssue.id}\n'
            'title: $latestTitle\n'
            'description: $latestDescription\n'
            'note: $latestNote\n'
            'path: $latestPath',
      );
    });
  }

  Future<void> _toggleMeAsResponsible() async {
    final uid = _currentUserIdOrNull();
    if (uid == null) {
      _showSafeSnackBar('User not loaded');
      return;
    }

    final currentForm = ref.read(feedbackDetailFormProvider(widget.issue.id));
    final model = ref.read(feedbackDetailProvider(widget.issue.id)).data;
    final currentResp =
        currentForm?.responsiblePerson ?? model?.responsiblePerson;

    final newResp = (currentResp == uid) ? null : uid;

    final formNotifier =
    ref.read(feedbackDetailFormProvider(widget.issue.id).notifier);

    if (newResp == null) {
      formNotifier.clearResponsible();
    } else {
      formNotifier.setResponsible(newResp);
    }

    final ok = await ref
        .read(feedbackDetailProvider(widget.issue.id).notifier)
        .update(responsiblePerson: newResp);

    if (!mounted) return;

    _showSafeSnackBar(
      ok
          ? (newResp == null
          ? 'Cleared responsible person'
          : 'Set you as responsible')
          : 'Error while updating responsible',
    );
  }

  Future<void> _showResponsiblePicker() async {
    final feedbackTheme = FeedbackTheme.of(context);
    final colorScheme = feedbackTheme.colorScheme;
    final members = _companyMembers();
    final systemTheme = ref.watch(themeColorsProvider);

    if (members.isEmpty) {
      _showSafeSnackBar('No company members available');
      return;
    }

    final currentForm = ref.read(feedbackDetailFormProvider(widget.issue.id));
    final model = ref.read(feedbackDetailProvider(widget.issue.id)).data;
    final currentId =
        currentForm?.responsiblePerson ?? model?.responsiblePerson;

    String query = '';
    int? selectedId = currentId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: feedbackTheme.feedbackSheetColor,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = members.where((m) {
              if (query.isEmpty) return true;
              return m.name.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scroll) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.24),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Text(
                        'Select responsible person',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface,
                          ),
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface,
                          ),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: feedbackTheme.feedbackSheetColor,
                        ),
                        onChanged: (v) => setModalState(() => query = v),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scroll,
                          itemCount: filtered.length + 1,
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return RadioListTile<int?>(
                                value: null,
                                groupValue: selectedId,
                                title: Text(
                                  '— None (clear) —',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                onChanged: (v) =>
                                    setModalState(() => selectedId = v),
                              );
                            }

                            final m = filtered[i - 1];

                            return RadioListTile<int?>(
                              value: m.id,
                              activeColor:
                              colorScheme.onSurface.withOpacity(0.95),
                              groupValue: selectedId,
                              onChanged: (v) =>
                                  setModalState(() => selectedId = v),
                              title: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: (m.avatar != null)
                                        ? NetworkImage(m.avatar!)
                                        : null,
                                    child: (m.avatar == null)
                                        ? Text(
                                      m.name.isNotEmpty
                                          ? m.name[0].toUpperCase()
                                          : '?',
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: systemTheme.themeColor,
                                disabledBackgroundColor:
                                systemTheme.themeColor.withOpacity(0.5),
                              ),
                              onPressed: () async {
                                final formNotifier = ref.read(
                                  feedbackDetailFormProvider(widget.issue.id)
                                      .notifier,
                                );

                                if (selectedId == null) {
                                  formNotifier.clearResponsible();
                                } else {
                                  formNotifier.setResponsible(selectedId);
                                }

                                final ok = await ref
                                    .read(
                                  feedbackDetailProvider(widget.issue.id)
                                      .notifier,
                                )
                                    .update(responsiblePerson: selectedId);

                                if (!mounted) return;

                                Navigator.pop(ctx);

                                _showSafeSnackBar(
                                  ok
                                      ? 'Responsible updated'
                                      : 'Error saving responsible',
                                );
                              },
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: systemTheme.themeTextColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _refreshIssue() async {
    debugPrint(
      '=== REFRESH ISSUE CLICKED ===\n'
          'issueId: ${widget.issue.id}',
    );

    _controllersSeeded = false;
    _lastSeededIssueId = null;

    await ref.read(feedbackDetailProvider(widget.issue.id).notifier).load();
    ref.invalidate(feedbackIssuesByPathProvider(Uri.base.path));
  }

  Future<void> _saveIssue() async {
    final canEdit = _canEditIssues(ref);
    if (!canEdit) {
      _showSafeSnackBar(
        'Only logged in Hously team members can edit issues',
      );
      return;
    }

    final formNotifier =
    ref.read(feedbackDetailFormProvider(widget.issue.id).notifier);
    final currentForm = ref.read(feedbackDetailFormProvider(widget.issue.id));

    debugPrint(
      '=== SAVE ISSUE CLICKED ===\n'
          'issueId: ${widget.issue.id}\n'
          'form is null: ${currentForm == null}',
    );

    if (currentForm == null) {
      debugPrint('SAVE ABORTED: form is null');
      if (!mounted) return;
      _showSafeSnackBar('Issue form is not ready');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String? cleanString(String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return null;
      return v;
    }

    try {
      final rawTitle = _titleController.text.trim();
      final rawDescription = _descriptionController.text.trim();
      final rawNote = _noteController.text.trim();
      final rawPath = _pathController.text.trim();

      formNotifier.setTitle(rawTitle);
      formNotifier.setDescription(rawDescription);
      formNotifier.setNote(rawNote);
      formNotifier.setPath(rawPath);

      final latestForm = ref.read(feedbackDetailFormProvider(widget.issue.id));

      debugPrint(
        '=== SAVE ISSUE PAYLOAD BEFORE CLEAN ===\n'
            'id: ${widget.issue.id}\n'
            'title: ${latestForm?.title}\n'
            'description: ${latestForm?.description}\n'
            'note: ${latestForm?.note}\n'
            'path: ${latestForm?.path}\n'
            'feature: ${latestForm?.feature}\n'
            'team: ${latestForm?.team}\n'
            'app: ${latestForm?.app}\n'
            'priority: ${latestForm?.priority}\n'
            'problemId: ${latestForm?.problemId}\n'
            'responsiblePerson: ${latestForm?.responsiblePerson}\n'
            'isSolved: ${latestForm?.isSolved}',
      );

      final ok = await ref
          .read(feedbackDetailProvider(widget.issue.id).notifier)
          .update(
        isSolved: latestForm?.isSolved,
        note: cleanString(latestForm?.note),
        responsiblePerson: latestForm?.responsiblePerson,
        path: cleanString(latestForm?.path),
        feature: cleanString(latestForm?.feature),
        team: cleanString(latestForm?.team),
        app: cleanString(latestForm?.app),
        priority: cleanString(latestForm?.priority),
        problemId: latestForm?.problemId,
        title: cleanString(latestForm?.title),
        description: cleanString(latestForm?.description),
      );

      debugPrint(
        '=== SAVE ISSUE RESULT ===\n'
            'issueId: ${widget.issue.id}\n'
            'success: $ok',
      );

      if (!mounted) return;

      if (ok) {
        _controllersSeeded = false;
        _lastSeededIssueId = null;

        ref.invalidate(feedbackDetailProvider(widget.issue.id));
        ref.invalidate(feedbackIssuesByPathProvider(Uri.base.path));
        ref.invalidate(feedbackListProvider);

        _showSafeSnackBar('Saved changes');
      } else {
        final detailState =
        ref.read(feedbackDetailProvider(widget.issue.id));

        debugPrint(
          '=== SAVE ISSUE FAILED ===\n'
              'issueId: ${widget.issue.id}\n'
              'providerError: ${detailState.error}',
        );

        _showSafeSnackBar(
          detailState.error?.isNotEmpty == true
              ? detailState.error!
              : 'Failed to save issue',
        );
      }
    } catch (e, stack) {
      debugPrint(
        '=== SAVE ISSUE EXCEPTION ===\n'
            'issueId: ${widget.issue.id}\n'
            'error: $e\n'
            'stack: $stack',
      );

      if (mounted) {
        _showSafeSnackBar('Save crashed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _noteController = TextEditingController();
    _pathController = TextEditingController();

    debugPrint(
      '=== ISSUE DETAILS INIT ===\n'
          'id: ${widget.issue.id}\n'
          'title: ${widget.issue.title}\n'
          'description: ${widget.issue.description}\n'
          'note: ${widget.issue.note}\n'
          'path: ${widget.issue.path}\n'
          'feature: ${widget.issue.feature}\n'
          'team: ${widget.issue.team}\n'
          'app: ${widget.issue.app}\n'
          'priority: ${widget.issue.priority}\n'
          'problemId: ${widget.issue.problem}\n'
          'responsiblePerson: ${widget.issue.responsiblePerson}\n'
          'isSolved: ${widget.issue.isSolved}\n'
          'image: ${widget.issue.image}',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Widget _buildFormContent({
    required BuildContext context,
    required ColorScheme colorScheme,
    required bool canEdit,
    required FeedbackDetailFormNotifier formNotifier,
    required bool solvedValue,
    required int? uid,
    required bool amResponsible,
    required AsyncValue<List<FeedbackProblemModel>> problemsAsync,
    required FeedbackDetailState detailState,
    required FeedbackThemeData feedbackTheme,
    required ThemeColors theme,
    required String? selectedFeature,
    required String? selectedTeam,
    required String? selectedApp,
    required String? selectedPriority,
    required int? selectedProblemId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, 'Title'),
        TextField(
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          controller: _titleController,
          enabled: canEdit && !_isSaving,
          onChanged: (value) {
            formNotifier.setTitle(value);
            debugPrint('TITLE CHANGED: $value');
          },
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 14),
        _buildSectionLabel(
          context,
          'Description (optional)',
        ),
        TextField(
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          controller: _descriptionController,
          enabled: canEdit && !_isSaving,
          minLines: 3,
          maxLines: 6,
          onChanged: (value) {
            formNotifier.setDescription(value);
            debugPrint('DESCRIPTION CHANGED: $value');
          },
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _softSurface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _responsibleTile(),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: amResponsible ? 'Remove me' : 'Assign me',
                      child: IconButton(
                        icon: Icon(
                          amResponsible
                              ? Icons.person_remove_alt_1
                              : Icons.person_add_alt_1,
                        ),
                        onPressed:
                        uid == null || _isSaving ? null : _toggleMeAsResponsible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(
                        Icons.clear,
                        color: colorScheme.onSurface.withOpacity(0.95),
                      ),
                      label: Text(
                        'Clear',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.95),
                        ),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                        ref
                            .read(
                          feedbackDetailFormProvider(
                            widget.issue.id,
                          ).notifier,
                        )
                            .clearResponsible();

                        final ok = await ref
                            .read(
                          feedbackDetailProvider(
                            widget.issue.id,
                          ).notifier,
                        )
                            .update(
                          responsiblePerson: null,
                        );

                        if (!mounted) return;

                        _showSafeSnackBar(
                          ok ? 'Cleared' : 'Error',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Is solved?',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: solvedValue,
              activeColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withOpacity(0.4),
              inactiveThumbColor: colorScheme.onSurface.withOpacity(0.8),
              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.25),
              onChanged: canEdit && !_isSaving
                  ? (value) {
                debugPrint(
                  'SOLVED CHANGED: $value for issueId ${widget.issue.id}',
                );
                formNotifier.setIsSolved(value);
              }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSectionLabel(context, 'Admin Note'),
        TextField(
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          controller: _noteController,
          enabled: canEdit && !_isSaving,
          minLines: 3,
          maxLines: 6,
          onChanged: (value) {
            formNotifier.setNote(value);
            debugPrint('NOTE CHANGED: $value');
          },
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 18),
        _buildSectionLabel(
          context,
          'Path / context (optional)',
        ),
        TextField(
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          controller: _pathController,
          enabled: canEdit && !_isSaving,
          onChanged: (value) {
            formNotifier.setPath(value);
            debugPrint('PATH CHANGED: $value');
          },
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 14),
        _buildSectionLabel(
          context,
          'Feature (optional)',
        ),
        DropdownButtonFormField<String>(
          value: selectedFeature,
          dropdownColor: feedbackTheme.feedbackSheetColor,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          onChanged: canEdit && !_isSaving
              ? (value) {
            debugPrint('FEATURE CHANGED: $value');
            formNotifier.setFeature(value);
          }
              : null,
          items: _featureOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 8),
        _buildSectionLabel(context, 'Team (optional)'),
        DropdownButtonFormField<String>(
          value: selectedTeam,
          dropdownColor: feedbackTheme.feedbackSheetColor,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          onChanged: canEdit && !_isSaving
              ? (value) {
            debugPrint('TEAM CHANGED: $value');
            formNotifier.setTeam(value);
          }
              : null,
          items: _teamOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 8),
        _buildSectionLabel(context, 'App (optional)'),
        DropdownButtonFormField<String>(
          value: selectedApp,
          dropdownColor: feedbackTheme.feedbackSheetColor,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          onChanged: canEdit && !_isSaving
              ? (value) {
            debugPrint('APP CHANGED: $value');
            formNotifier.setApp(value);
          }
              : null,
          items: _appOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 8),
        _buildSectionLabel(
          context,
          'Priority (optional)',
        ),
        DropdownButtonFormField<String>(
          value: selectedPriority,
          dropdownColor: feedbackTheme.feedbackSheetColor,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          onChanged: canEdit && !_isSaving
              ? (value) {
            debugPrint('PRIORITY CHANGED: $value');
            formNotifier.setPriority(value);
          }
              : null,
          items: _priorityOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          decoration: _fieldDecoration(context),
        ),
        const SizedBox(height: 8),
        _buildSectionLabel(
          context,
          'Issue type (optional)',
        ),
        problemsAsync.when(
          loading: () => Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: _softSurface(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.10),
              ),
            ),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          error: (error, stack) {
            debugPrint(
              '=== LOAD PROBLEMS ERROR ===\n'
                  'error: $error\n'
                  'stack: $stack',
            );
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.onSurface,
                ),
              ),
              child: Text(
                'Failed to load issue types',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
            );
          },
          data: (problems) {
            return DropdownButtonFormField<int>(
              value: problems.any((p) => p.id == selectedProblemId)
                  ? selectedProblemId
                  : null,
              dropdownColor: feedbackTheme.feedbackSheetColor,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
              onChanged: canEdit && !_isSaving
                  ? (value) {
                debugPrint('PROBLEM CHANGED: $value');
                formNotifier.setProblem(value);
              }
                  : null,
              items: problems
                  .map(
                    (problem) => DropdownMenuItem<int>(
                  value: problem.id,
                  child: Text(problem.title),
                ),
              )
                  .toList(),
              decoration: _fieldDecoration(context),
            );
          },
        ),
        const SizedBox(height: 16),
        if (detailState.error != null && detailState.error!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.20),
              ),
            ),
            child: Text(
              detailState.error!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          ),
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                disabledBackgroundColor: theme.themeColor.withOpacity(0.5),
              ),
              onPressed: canEdit && !_isSaving ? _saveIssue : null,
              icon: _isSaving
                  ? SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.themeTextColor,
                ),
              )
                  : Icon(
                Icons.save_alt,
                size: 16,
                color: theme.themeTextColor,
              ),
              label: Text(
                _isSaving ? 'Saving...' : 'Save changes',
                style: TextStyle(
                  color: theme.themeTextColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: !_isSaving ? _refreshIssue : null,
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: colorScheme.onSurface,
              ),
              label: Text(
                'Refresh',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: null,
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: colorScheme.onSurface,
              ),
              label: Text(
                'Delete',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackTheme = FeedbackTheme.of(context);
    final colorScheme = feedbackTheme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 900;

    final theme = ref.watch(themeColorsProvider);
    final canEdit = _canEditIssues(ref);

    final detailState = ref.watch(feedbackDetailProvider(widget.issue.id));
    final form = ref.watch(feedbackDetailFormProvider(widget.issue.id));
    final formNotifier =
    ref.read(feedbackDetailFormProvider(widget.issue.id).notifier);

    final problemsAsync = ref.watch(feedbackProblemsProvider);

    final currentIssue = detailState.data ?? widget.issue;


    _syncControllersFromForm(currentIssue, form);

    final selectedFeature =
    _safeDropdownValue(form?.feature ?? currentIssue.feature, _featureOptions);
    final selectedTeam =
    _safeDropdownValue(form?.team ?? currentIssue.team, _teamOptions);
    final selectedApp =
    _safeDropdownValue(form?.app ?? currentIssue.app, _appOptions);
    final selectedPriority = _safeDropdownValue(
      form?.priority ?? currentIssue.priority,
      _priorityOptions,
    );

    final solvedValue = form?.isSolved ?? currentIssue.isSolved;
    final selectedProblemId = form?.problemId ?? currentIssue.problem;
    final uid = _currentUserIdOrNull();
    final currentResponsibleId =
        form?.responsiblePerson ?? currentIssue.responsiblePerson;
    final amResponsible = uid != null && currentResponsibleId == uid;

    final formContent = _buildFormContent(
      context: context,
      colorScheme: colorScheme,
      canEdit: canEdit,
      formNotifier: formNotifier,
      solvedValue: solvedValue,
      uid: uid,
      amResponsible: amResponsible,
      problemsAsync: problemsAsync,
      detailState: detailState,
      feedbackTheme: feedbackTheme,
      theme: theme,
      selectedFeature: selectedFeature,
      selectedTeam: selectedTeam,
      selectedApp: selectedApp,
      selectedPriority: selectedPriority,
      selectedProblemId: selectedProblemId,
    );

    return Dialog(
      backgroundColor: feedbackTheme.feedbackSheetColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: screenSize.width * 0.94,
        height: screenSize.height * 0.90,
        child: detailState.loading && detailState.data == null
            ? Center(
          child: CircularProgressIndicator(
            color: colorScheme.onSurface,
          ),
        )
            : Column(
          children: [
            _buildHeader(context, currentIssue, solvedValue),
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: isMobile
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 280,
                      child: _buildImagePanel(context, currentIssue),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: formContent,
                      ),
                    ),
                  ],
                )
                    : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: formContent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _buildImagePanel(context, currentIssue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}