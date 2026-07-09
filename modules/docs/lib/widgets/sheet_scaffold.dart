import 'package:flutter/material.dart';

class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.child,
    required this.scrollController,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final ScrollController scrollController;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(  
        controller: scrollController,
        padding: EdgeInsets.only(
          left: padding.left,
          right: padding.right,
          top: padding.top,
          bottom: padding.bottom + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(60),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
