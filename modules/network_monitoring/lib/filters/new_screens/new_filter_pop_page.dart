import 'package:flutter/material.dart';
import 'package:network_monitoring/filters/new_screens/new_filter_pop_mobile.dart';
import 'package:network_monitoring/filters/new_screens/new_filters_pop_pc.dart';

class NewFilterPopPage extends StatelessWidget {
  final bool needNavigate;
  final ScrollController? scrollController;

  const NewFilterPopPage({
    super.key,
    this.needNavigate = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 750) {
          return NewFilterPopMobile(
            needNavigate: needNavigate,
            scrollController: scrollController,
          );
        } else {
          return NewFiltersPopPc(needNavigate: needNavigate);
        }
      },
    );
  }
}
