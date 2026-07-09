import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';

class DocWidget extends StatelessWidget {
  final Widget child;

  const DocWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.docWidget.anchorKey,

      spec: DocsEmmaAnchors.docWidget,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: RepaintBoundary(
        child: child,
      ),
    );
  }
}