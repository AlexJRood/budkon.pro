import 'package:feedback/src/feedback_widget.dart';
import 'package:feedback/src/provider/open_issues_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

class FiltersButtonWidget extends ConsumerStatefulWidget {
  final ScrollController scroll;
  final List<FeedbackProblemModel> problems;

  const FiltersButtonWidget({
    super.key,
    required this.scroll,
    required this.problems,
  });

  @override
  ConsumerState<FiltersButtonWidget> createState() =>
      _FiltersButtonWidgetState();
}

class _FiltersButtonWidgetState extends ConsumerState<FiltersButtonWidget> {
  static const List<List<String>> teamOptions = [
    ['team alex', 'Team Alex'],
    ['team younis', 'Team Younis'],
    ['team ansaf', 'Team Ansaf'],
    ['null', 'Null'],
  ];

  static const List<List<String>> priorityOptions = [
    ['lod', 'Live or Dead'],
    ['critical', 'Critical'],
    ['high', 'High'],
    ['mid', 'Medium'],
    ['low', 'Low'],
    ['null', 'Null'],
  ];

  static const List<List<String>> orderingOptions = [
    ['-created_at', 'Newest'],
    ['created_at', 'Oldest'],
    ['-id', 'ID ↓'],
    ['id', 'ID ↑'],
    ['feature', 'Feature A→Z'],
    ['-feature', 'Feature Z→A'],
    ['team', 'Team A→Z'],
    ['-team', 'Team Z→A'],
    ['app', 'App A→Z'],
  ];

  bool? isSolved;
  int? problemId;
  List<String> features = [];
  List<String> teams = [];
  List<String> apps = [];
  List<String> priority = [];
  bool? hasImage;
  bool? hasNote;
  bool? unassigned;
  DateTime? createdAfter;
  DateTime? createdBefore;
  String ordering = '-created_at';
  bool responsibleNull = false;

  late final TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();

    final current = ref.read(feedbackFiltersProvider);

    isSolved = current.isSolved;
    problemId = current.problemId;
    features = List<String>.from(current.features);
    teams = List<String>.from(current.teams);
    apps = List<String>.from(current.apps);
    priority = List<String>.from(current.priority);
    _pathController.text = current.pathIcontains ?? '';
    hasImage = current.hasImage;
    hasNote = current.hasNote;
    unassigned = current.unassigned;
    createdAfter = current.createdAfter;
    createdBefore = current.createdBefore;
    ordering = current.ordering ?? '-created_at';
    responsibleNull = current.responsibleIsNull == true;

    final selectedResponsibleIds = current.responsibleIds ?? <int>[];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedMemberIdsProvider.notifier).state =
          selectedResponsibleIds.toSet();
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  List<String> _toggle(List<String> list, String value) {
    final next = List<String>.from(list);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return next;
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initial,
    required void Function(DateTime?) onPicked,
    bool endOfDay = false,
  }) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: initial ?? now,
    );

    if (!mounted) return;

    if (picked == null) {
      onPicked(null);
      return;
    }

    onPicked(
      endOfDay
          ? DateTime(picked.year, picked.month, picked.day, 23, 59, 59)
          : DateTime(picked.year, picked.month, picked.day),
    );
  }

  String _currentPath() {
    try {
      return ref.read(navigationService).currentPath;
    } catch (_) {
      return Uri.base.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final notifier = ref.read(feedbackFiltersProvider.notifier);
    final currentPath = _currentPath();

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: widget.scroll,
              children: [
                sectionTitle('Responsible'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      checkmarkColor: theme.themeTextColor,
                      selectedColor: theme.themeColor,
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'Any',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: !responsibleNull &&
                          (ref.watch(selectedMemberIdsProvider) ?? <int>{})
                              .isEmpty,
                      onSelected: (_) {
                        setState(() {
                          responsibleNull = false;
                          ref.read(selectedMemberIdsProvider.notifier).state =
                          <int>{};
                        });
                      },
                    ),
                    ChoiceChip(
                      checkmarkColor: theme.themeTextColor,
                      selectedColor: theme.themeColor,
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'Unassigned only',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: responsibleNull,
                      onSelected: (_) {
                        setState(() {
                          responsibleNull = true;
                          ref.read(selectedMemberIdsProvider.notifier).state =
                          <int>{};
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!responsibleNull)
                  const SizedBox(
                    height: 42,
                    child: MembersDropdown(),
                  ),
                sectionTitle('Status'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      checkmarkColor: theme.themeTextColor,
                      selectedColor: theme.themeColor,
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'All',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: isSolved == null,
                      onSelected: (_) => setState(() => isSolved = null),
                    ),
                    ChoiceChip(
                      checkmarkColor: theme.themeTextColor,
                      selectedColor: theme.themeColor,
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'Open',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: isSolved == false,
                      onSelected: (_) => setState(() => isSolved = false),
                    ),
                    ChoiceChip(
                      checkmarkColor: theme.themeTextColor,
                      selectedColor: theme.themeColor,
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'Solved',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: isSolved == true,
                      onSelected: (_) => setState(() => isSolved = true),
                    ),
                  ],
                ),
                sectionTitle('Issue type'),
                DropdownButtonFormField<int?>(
                  initialValue: problemId,
                  decoration: InputDecoration(
                    hintText: 'Issue type',
                    hintStyle: TextStyle(color: theme.textColor),
                    filled: true,
                    fillColor: theme.dashboardContainer,
                    border: const OutlineInputBorder(),
                  ),
                  dropdownColor: theme.dashboardContainer,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'All',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    ...widget.problems.map(
                          (p) => DropdownMenuItem<int?>(
                        value: p.id,
                        child: Text(
                          p.title,
                          style: TextStyle(color: theme.textColor),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => problemId = value),
                ),
                sectionTitle('Team'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: teamOptions.map((option) {
                    final value = option[0];
                    final label = option[1];
                    final selected = teams.contains(value);

                    return FilterChip(
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        label,
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          teams = _toggle(teams, value);
                        });
                      },
                    );
                  }).toList(),
                ),
                sectionTitle('Priority'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: priorityOptions.map((option) {
                    final value = option[0];
                    final label = option[1];
                    final selected = priority.contains(value);

                    return FilterChip(
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        label,
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          priority = _toggle(priority, value);
                        });
                      },
                    );
                  }).toList(),
                ),
                sectionTitle('Path contains'),
                TextFormField(
                  controller: _pathController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'np. /admin/feedback',
                    hintStyle: TextStyle(color: theme.textColor),
                    filled: true,
                    fillColor: theme.dashboardContainer,
                    border: const OutlineInputBorder(),
                  ),
                ),
                sectionTitle('Additional'),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'Has image',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: hasImage == true,
                      onSelected: (_) {
                        setState(() {
                          hasImage = hasImage == true ? null : true;
                        });
                      },
                    ),
                    FilterChip(
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'No image',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: hasImage == false,
                      onSelected: (_) {
                        setState(() {
                          hasImage = hasImage == false ? null : false;
                        });
                      },
                    ),
                    FilterChip(
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'Has note',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: hasNote == true,
                      onSelected: (_) {
                        setState(() {
                          hasNote = hasNote == true ? null : true;
                        });
                      },
                    ),
                    FilterChip(
                      backgroundColor: theme.dashboardContainer,
                      label: Text(
                        'Unassigned',
                        style: TextStyle(color: theme.textColor),
                      ),
                      selected: unassigned == true,
                      onSelected: (_) {
                        setState(() {
                          unassigned = unassigned == true ? null : true;
                        });
                      },
                    ),
                  ],
                ),
                sectionTitle('Dates'),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.date_range,
                          color: theme.textColor,
                        ),
                        label: Text(
                          createdAfter == null
                              ? 'From'
                              : DateFormat('yyyy-MM-dd').format(createdAfter!),
                          style: TextStyle(color: theme.textColor),
                        ),
                        onPressed: () => _pickDate(
                          context: context,
                          initial: createdAfter,
                          onPicked: (date) {
                            setState(() {
                              createdAfter = date;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.event,
                          color: theme.textColor,
                        ),
                        label: Text(
                          createdBefore == null
                              ? 'To'
                              : DateFormat('yyyy-MM-dd').format(createdBefore!),
                          style: TextStyle(color: theme.textColor),
                        ),
                        onPressed: () => _pickDate(
                          context: context,
                          initial: createdBefore,
                          endOfDay: true,
                          onPicked: (date) {
                            setState(() {
                              createdBefore = date;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                sectionTitle('Sort'),
                DropdownButtonFormField<String>(
                  initialValue: ordering,
                  decoration: InputDecoration(
                    hintText: 'Sort',
                    hintStyle: TextStyle(color: theme.textColor),
                    filled: true,
                    fillColor: theme.dashboardContainer,
                    border: const OutlineInputBorder(),
                  ),
                  dropdownColor: theme.dashboardContainer,
                  items: orderingOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                      value: option[0],
                      child: Text(
                        option[1],
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      ordering = value ?? '-created_at';
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  notifier.state = const FeedbackFilters();
                  ref.read(selectedMemberIdsProvider.notifier).state = <int>{};
                  ref.invalidate(feedbackListProvider);
                  ref.invalidate(feedbackIssuesByPathProvider(currentPath));
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Clear',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: buttonStyleRounded10ThemeRedWithPadding15,
                  onPressed: () {
                    final nextState = FeedbackFilters(
                      isSolved: isSolved,
                      problemId: problemId,
                      features: features,
                      teams: teams,
                      apps: apps,
                      priority: priority,
                      pathIcontains: _pathController.text.trim().isEmpty
                          ? null
                          : _pathController.text.trim(),
                      hasImage: hasImage,
                      hasNote: hasNote,
                      unassigned: unassigned,
                      createdAfter: createdAfter,
                      createdBefore: createdBefore,
                      ordering: ordering,
                      responsibleIsNull: responsibleNull,
                      responsibleIds:
                      (ref.read(selectedMemberIdsProvider) ?? <int>{})
                          .toList(),
                    );

                    notifier.state = nextState;
                    ref.invalidate(feedbackListProvider);
                    ref.invalidate(feedbackIssuesByPathProvider(currentPath));
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Confirm',
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}