import 'package:flutter/material.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class BudkonShell extends StatefulWidget {
  final Widget child;

  const BudkonShell({super.key, required this.child});

  @override
  State<BudkonShell> createState() => _BudkonShellState();
}

class _BudkonShellState extends State<BudkonShell> {
  final _sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    return BarManager(
      appModule: AppModule.budkon,
      sideMenuKey: _sideMenuKey,
      childPc: widget.child,
      childTablet: widget.child,
      childMobile: widget.child,
    );
  }
}
