import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';

import '../todo_mobile.dart';
import 'board_pc.dart';

class BoardPage extends StatelessWidget {
  final AppModule appModule;

  const BoardPage({
    super.key,
    this.appModule = AppModule.agentCrm,
  });

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsBoardPageRoot
      anchorKey: 'tms.board.page.root',
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 1080) {
            return BoardPc(appModule: appModule);
          }

          return ToDoMobile(appModule: appModule);
        },
      ),
    );
  }
}