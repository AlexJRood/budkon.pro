import 'package:feedback/src/better_feedback.dart';
import 'package:feedback/src/l18n/translation.dart';
import 'package:feedback/src/provider/feedback_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/user/user/user_provider.dart';

/// Prompt the user for feedback using `StringFeedback`.
Widget simpleFeedbackBuilder(
    BuildContext context,
    OnSubmit onSubmit,
    ScrollController? scrollController,
    ) => StringFeedback(onSubmit: onSubmit, scrollController: scrollController);

class _MemberLite {
  final int id;
  final String name;
  final String? avatar;

  const _MemberLite(this.id, this.name, this.avatar);
}

class StringFeedback extends ConsumerStatefulWidget {
  const StringFeedback({
    super.key,
    required this.onSubmit,
    required this.scrollController,
  });

  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  @override
  ConsumerState<StringFeedback> createState() => _StringFeedbackState();
}

class _StringFeedbackState extends ConsumerState<StringFeedback> {
  late TextEditingController controller;
  late TextEditingController descriptionController;
  late TextEditingController adminNoteController;

  String? selectedDropdownValue;
  List<DropdownMenuItem<String>> items = [];
  Map<String, int> problemTitleToId = {};

  bool _isDisposed = false;
  bool _isLoadingProblems = false;

  String? selectedFeature;
  String? selectedTeam;
  String? selectedApp;
  String? selectedPriority;
  int? selectedResponsiblePersonId;

  static const List<List<String>> featureOptions = [
    ['wall', 'Wall'],
    ['feedback', 'Feedback'],
    ['portal', 'Portal'],
    ['crm', 'CRM'],
    ['chat', 'Chat'],
    ['ai', 'AI'],
    ['nm', 'Network Monitoring'],
    ['docs', 'Docs'],
    ['tms', 'TMS'],
    ['calendar', 'Calendar'],
    ['cloud', 'Cloud'],
    ['mail', 'Mail'],
    ['client_panel', 'Client Panel'],
    ['finance', 'Finance'],
    ['notifications', 'Notifications'],
    ['profile', 'Profile'],
    ['assosiation', 'Association'],
    ['fav', 'Favourites'],
    ['browse_list', 'Browse List'],
  ];

  static const List<List<String>> teamOptions = [
    ['team alex', 'Team Alex'],
    ['team younis', 'Team Younis'],
    ['team ansaf', 'Team Ansaf'],
  ];

  static const List<List<String>> appOptions = [
    ['hously', 'Hously'],
    ['panel', 'Panel'],
    ['extractly', 'Extractly'],
  ];

  static const List<List<String>> priorityOptions = [
    ['lod', 'Live or Dead'],
    ['critical', 'Critical'],
    ['high', 'High'],
    ['mid', 'Medium'],
    ['low', 'Low'],
  ];

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    descriptionController = TextEditingController();
    adminNoteController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      fetchFeedbackProblems();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    controller.dispose();
    descriptionController.dispose();
    adminNoteController.dispose();
    super.dispose();
  }

  List<_MemberLite> _companyMembers() {
    final u = ref.read(userProvider).maybeWhen(data: (x) => x, orElse: () => null);
    if (u == null) return const [];

    return (u.companyMembers ?? [])
        .map<_MemberLite>(
          (m) => _MemberLite(
        m.id is int ? m.id as int : int.tryParse(m.id.toString()) ?? -1,
        '${(m.firstName ?? '').toString()} ${(m.lastName ?? '').toString()}'.trim(),
        (m.avatar?.toString().isNotEmpty ?? false) ? m.avatar.toString() : null,
      ),
    )
        .where((m) => m.id > 0 && m.name.isNotEmpty)
        .toList();
  }

  List<DropdownMenuItem<int?>> _buildResponsibleItems(Color textColor) {
    final members = _companyMembers();

    return [
      DropdownMenuItem<int?>(
        value: null,
        child: Text(
          'None',
          style: TextStyle(color: textColor),
        ),
      ),
      ...members.map(
            (m) => DropdownMenuItem<int?>(
          value: m.id,
          child: Text(
            m.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor),
          ),
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _buildOptionItems(
      List<List<String>> options,
      Color textColor,
      ) {
    return options
        .map(
          (e) => DropdownMenuItem<String>(
        value: e[0],
        child: Text(
          e[1],
          style: TextStyle(color: textColor),
        ),
      ),
    )
        .toList();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Color textColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: textColor.withAlpha(180)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: textColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: textColor),
      ),
    );
  }

  InputDecoration _dropdownDecoration({
    required String labelText,
    required Color textColor,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: textColor),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: textColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: textColor),
      ),
    );
  }

  Future<void> fetchFeedbackProblems() async {
    if (_isLoadingProblems) return;
    _isLoadingProblems = true;

    try {
      final notifier = ref.read(feedbackProvider.notifier);
      final problems = await notifier.getFeedbackProblems(ref);

      if (!mounted || _isDisposed) return;

      final Map<String, int> newProblemTitleToId = {};
      final List<DropdownMenuItem<String>> newItems = problems.map((problem) {
        newProblemTitleToId[problem.title] = problem.id;
        return DropdownMenuItem<String>(
          value: problem.title,
          child: Text(problem.title),
        );
      }).toList();

      if (!mounted || _isDisposed) return;

      setState(() {
        problemTitleToId = newProblemTitleToId;
        items = newItems;
      });

      debugPrint('=== FEEDBACK PROBLEMS LOADED ===');
      debugPrint('items count: ${items.length}');
      debugPrint('problemTitleToId: $problemTitleToId');
    } catch (e, st) {
      debugPrint('fetchFeedbackProblems error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isLoadingProblems = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final canStuff = ref.watch(canAccessModuleProvider('stuff'));
    final responsibleItems = _buildResponsibleItems(theme.textColor);
    final responsibleValue = responsibleItems.any(
          (item) => item.value == selectedResponsiblePersonId,
    )
        ? selectedResponsiblePersonId
        : null;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView(
                controller: widget.scrollController,
                padding: EdgeInsets.fromLTRB(
                  16,
                  widget.scrollController != null ? 20 : 16,
                  16,
                  0,
                ),
                children: <Widget>[
                  SizedBox(
                    height: 50,
                    child: DropdownButton<String>(
                      value: selectedDropdownValue,
                      items: items,
                      hint: Text(
                        FeedbackLocalizations.of(context).feedbackDescriptionText,
                        style: TextStyle(color: theme.textColor),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedDropdownValue = value;
                        });
                        debugPrint('=== PROBLEM CHANGED ===');
                        debugPrint('selectedDropdownValue: $value');
                        debugPrint(
                          'problem id: ${value != null ? problemTitleToId[value] : null}',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: _inputDecoration(
                      hintText: 'Title',
                      textColor: theme.textColor,
                    ),
                    style: TextStyle(color: theme.textColor),
                    cursorColor: theme.textColor,
                    key: const Key('text_input_field'),
                    maxLines: 1,
                    minLines: 1,
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) {
                      debugPrint('=== TITLE CHANGED === $v');
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: _inputDecoration(
                      hintText: 'Description',
                      textColor: theme.textColor,
                    ),
                    style: TextStyle(color: theme.textColor),
                    cursorColor: theme.textColor,
                    key: const Key('description_text_input_field'),
                    maxLines: 3,
                    minLines: 1,
                    controller: descriptionController,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) {
                      debugPrint('=== DESCRIPTION CHANGED === $v');
                    },
                  ),
                  if (canStuff) ...[
                    const SizedBox(height: 10),
                    TextField(
                      decoration: _inputDecoration(
                        hintText: 'Admin Note',
                        textColor: theme.textColor,
                      ),
                      style: TextStyle(color: theme.textColor),
                      cursorColor: theme.textColor,
                      key: const Key('admin_note_text_input_field'),
                      maxLines: 3,
                      minLines: 1,
                      controller: adminNoteController,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) {
                        debugPrint('=== ADMIN NOTE CHANGED === $v');
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      value: responsibleValue,
                      dropdownColor: theme.dashboardContainer,
                      items: responsibleItems,
                      decoration: _dropdownDecoration(
                        labelText: 'Responsible person',
                        textColor: theme.textColor,
                      ),
                      style: TextStyle(color: theme.textColor),
                      onChanged: (value) {
                        setState(() {
                          selectedResponsiblePersonId = value;
                        });
                        debugPrint('=== RESPONSIBLE PERSON CHANGED ===');
                        debugPrint(
                          'selectedResponsiblePersonId: $selectedResponsiblePersonId',
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedFeature,
                      dropdownColor: theme.dashboardContainer,
                      items: _buildOptionItems(featureOptions, theme.textColor),
                      decoration: _dropdownDecoration(
                        labelText: 'Feature',
                        textColor: theme.textColor,
                      ),
                      style: TextStyle(color: theme.textColor),
                      onChanged: (value) {
                        setState(() {
                          selectedFeature = value;
                        });
                        debugPrint('=== FEATURE CHANGED ===');
                        debugPrint('selectedFeature: $selectedFeature');
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedTeam,
                      dropdownColor: theme.dashboardContainer,
                      items: _buildOptionItems(teamOptions, theme.textColor),
                      decoration: _dropdownDecoration(
                        labelText: 'Team',
                        textColor: theme.textColor,
                      ),
                      style: TextStyle(color: theme.textColor),
                      onChanged: (value) {
                        setState(() {
                          selectedTeam = value;
                        });
                        debugPrint('=== TEAM CHANGED ===');
                        debugPrint('selectedTeam: $selectedTeam');
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedApp,
                      dropdownColor: theme.dashboardContainer,
                      items: _buildOptionItems(appOptions, theme.textColor),
                      decoration: _dropdownDecoration(
                        labelText: 'App',
                        textColor: theme.textColor,
                      ),
                      style: TextStyle(color: theme.textColor),
                      onChanged: (value) {
                        setState(() {
                          selectedApp = value;
                        });
                        debugPrint('=== APP CHANGED ===');
                        debugPrint('selectedApp: $selectedApp');
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      dropdownColor: theme.dashboardContainer,
                      items: _buildOptionItems(priorityOptions, theme.textColor),
                      decoration: _dropdownDecoration(
                        labelText: 'Priority',
                        textColor: theme.textColor,
                      ),
                      style: TextStyle(color: theme.textColor),
                      onChanged: (value) {
                        setState(() {
                          selectedPriority = value;
                        });
                        debugPrint('=== PRIORITY CHANGED ===');
                        debugPrint('selectedPriority: $selectedPriority');
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
              if (widget.scrollController != null)
                const FeedbackSheetDragHandle(),
            ],
          ),
        ),
        ElevatedButton(
          style: buttonStyleRounded10ThemeRedWithPadding15,
          key: const Key('submit_feedback_button'),
          child: Text(
            FeedbackLocalizations.of(context).submitButtonText,
            style: TextStyle(
              color: theme.themeTextColor,
            ),
          ),
          onPressed: () async {
            final extras = {
              'title': controller.text,
              'description': descriptionController.text,
              'problem_string': selectedDropdownValue,
              'problem': selectedDropdownValue != null
                  ? problemTitleToId[selectedDropdownValue]
                  : null,
              if (canStuff) 'note': adminNoteController.text,
              if (canStuff) 'responsible_person': selectedResponsiblePersonId,
              if (canStuff) 'feature': selectedFeature,
              if (canStuff) 'team': selectedTeam,
              if (canStuff) 'app': selectedApp,
              if (canStuff) 'priority': selectedPriority,
            };

            debugPrint('=== SUBMIT FEEDBACK CLICKED ===');
            debugPrint('title: ${controller.text}');
            debugPrint('description: ${descriptionController.text}');
            debugPrint('adminNote: ${adminNoteController.text}');
            debugPrint('selectedProblemTitle: $selectedDropdownValue');
            debugPrint(
              'selectedProblemId: ${selectedDropdownValue != null ? problemTitleToId[selectedDropdownValue] : null}',
            );
            debugPrint('selectedResponsiblePersonId: $selectedResponsiblePersonId');
            debugPrint('selectedFeature: $selectedFeature');
            debugPrint('selectedTeam: $selectedTeam');
            debugPrint('selectedApp: $selectedApp');
            debugPrint('selectedPriority: $selectedPriority');
            debugPrint('canStuff: $canStuff');
            debugPrint('extras: $extras');

            await widget.onSubmit(
              descriptionController.text,
              extras: extras,
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}