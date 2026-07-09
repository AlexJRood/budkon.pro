import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:core/theme/icons.dart';
import 'todo_mobile.dart';
import 'todo_pc.dart';

import 'package:tms_app/todo/provider/filtered_tasks_provider.dart';
import 'package:tms_app/todo/view/widgets/task_filters_dialog.dart';
import 'package:crm/widget/add_task_modal_sheet_widget.dart';
import 'board/provider/board_provider.dart';
import 'dart:ui' as ui;

class ToDoPage extends ConsumerWidget {
  final AppModule appModule;

  const ToDoPage({
    super.key,
    this.appModule = AppModule.agentCrm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShowCaseWidget(
      builder:(context) =>  PieCanvas(
        theme: const PieTheme(
          rightClickShowsMenu: true,
          leftClickShowsMenu: false,
          buttonTheme: PieButtonTheme(
            backgroundColor: AppColors.buttonGradient1,
            iconColor: Colors.white,
          ),
          buttonThemeHovered: PieButtonTheme(
            backgroundColor: Color.fromARGB(96, 58, 58, 58),
            iconColor: Colors.white,
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 1080) {
              // Jeśli jest to aplikacja webowa lub aplikacja desktopowa z szerokością większą niż 1420
              return ToDoPc(appModule: appModule);
            } else {
              // W przeciwnym razie (aplikacja mobilna lub aplikacja desktopowa z mniejszą szerokością)
              return ToDoMobile(appModule: appModule);
            }
          },
        ),
      ),
    );
  }
}