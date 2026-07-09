import 'package:flutter/material.dart';
import 'package:portal/screens/filters/filters_page_pop_mobile.dart';
import 'package:portal/screens/filters/filters_page_pop_pc.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:portal/emma/anchors/anchors_portal.dart';

class FiltersPage extends StatelessWidget {
  final String tag;
  final bool isNeedToNavigate;
  final ScrollController? scrollController;
  const FiltersPage({super.key, this.scrollController, required this.tag, this.isNeedToNavigate = false});

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      anchorKey: PortalEmmaAnchors.filtersRoot.anchorKey,

      spec: PortalEmmaAnchors.filtersRoot,
      runtimeMode: PortalEmmaAnchors.filtersRoot.runtimeMode,
      tapMode: PortalEmmaAnchors.filtersRoot.tapMode,
      child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 1080) {
          return FiltersPagePopMobile(tag: tag, isNeedToNavigate:true, scrollController:scrollController);
        } else {
          return FiltersPagePopPc(tag: tag, isNeedToNavigate:true);
        }
      },
    ),
    );
  }
}
