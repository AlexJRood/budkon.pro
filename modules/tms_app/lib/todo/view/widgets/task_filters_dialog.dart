import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';
import 'package:tms_app/todo/view/widgets/task_filters/filters_body_widget.dart';
import 'package:tms_app/todo/view/widgets/task_filters/pc_mobile_scaffold_widget.dart';
import 'package:tms_app/todo/view/widgets/task_filters/selection_widgets.dart';

class TaskFiltersDialog extends ConsumerStatefulWidget {
  final VoidCallback? onApply;
  final ScrollController? scrollController;
  final bool isMobile;

  const TaskFiltersDialog({
    super.key,
    this.onApply,
    this.scrollController,
    this.isMobile = false,
  });

  @override
  ConsumerState<TaskFiltersDialog> createState() => _TaskFiltersDialogState();
}

class _TaskFiltersDialogState extends ConsumerState<TaskFiltersDialog> {
  late final TextEditingController nameCtrl;

  late final ScrollController _scrollController;

  final GlobalKey _clientSearchKey = GlobalKey();
  final GlobalKey _labelSearchKey = GlobalKey();
  final GlobalKey _memberSearchKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final s = ref.read(taskFiltersProvider);
    nameCtrl = TextEditingController(text: s.name);
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    nameCtrl.dispose();

    // only dispose if we created it here
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }

    super.dispose();
  }

  void _scrollToField(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.15, // keeps field a little above keyboard
      );
    });
  }

  Future<DateTime?> _pickDate(
      BuildContext context,
      DateTime? initial,
      ThemeColors theme,
      ) async {
    final now = DateTime.now();
    final init = initial ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(init.year, init.month, init.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final base = Theme.of(context);

        return Theme(
          data: base.copyWith(
            dialogBackgroundColor: theme.adPopBackground,
            colorScheme: base.colorScheme.copyWith(
              primary: theme.themeColor,
              onPrimary: theme.themeTextColor,
              surface: theme.adPopBackground,
              onSurface: theme.textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.themeTextColor,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: theme.adPopBackground,
              headerBackgroundColor: theme.themeColor,
              headerForegroundColor: theme.themeTextColor,
              weekdayStyle: TextStyle(color: theme.textColor),
              dayStyle: TextStyle(color: theme.textColor),
              yearStyle: TextStyle(color: theme.textColor),
              todayForegroundColor: WidgetStatePropertyAll(theme.themeTextColor),
              todayBorder: BorderSide(color: theme.themeTextColor, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final filters = ref.watch(taskFiltersProvider);

    final body = SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      child: FiltersBody(
        isMobile: widget.isMobile,
        theme: theme,
        filters: filters,
        nameCtrl: nameCtrl,
        pickDateTime: (ctx, initial) => _pickDate(ctx, initial, theme),
        fmt: _fmt,

        // NEW
        clientSearchKey: _clientSearchKey,
        labelSearchKey: _labelSearchKey,
        memberSearchKey: _memberSearchKey,
        onSearchFieldFocused: _scrollToField,
      ),
    );

    if (widget.isMobile) {
      return MobileSheetScaffold(
        theme: theme,
        title: 'Task Filters'.tr,
        body: body,
        actions: FilterActionsRow(theme: theme, onApply: widget.onApply),
      );
    }

    return PcDialogScaffold(
      theme: theme,
      title: 'Task Filters'.tr,
      body: SizedBox(width: 760, child: body),
      actions: FilterActionsRow(theme: theme, onApply: widget.onApply),
    );
  }
}
