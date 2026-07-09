import 'package:core/ui/device_type_util.dart';
import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_layout_provider.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:core/theme/lottie.dart';

class DynamicDashboardPage extends ConsumerStatefulWidget {
  const DynamicDashboardPage({
    super.key,
    required this.dashboardKey,
    this.useShellSpacing = true,
  });

  final String dashboardKey;
  final bool useShellSpacing;

  @override
  ConsumerState<DynamicDashboardPage> createState() =>
      _DynamicDashboardPageState();
}

class _DynamicDashboardPageState extends ConsumerState<DynamicDashboardPage> 
    with AutomaticKeepAliveClientMixin {
  
  late ScrollController _scrollController;
  
  static final Map<String, double> _savedScrollPositions = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_saveScrollPosition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dashboardLayoutProvider(widget.dashboardKey).notifier).load();
      final savedPosition = _savedScrollPositions[widget.dashboardKey];
      if (savedPosition != null && savedPosition > 0 && _scrollController.hasClients) {
        _scrollController.jumpTo(savedPosition);
      }
    });
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollPositions[widget.dashboardKey] = _scrollController.position.pixels;
    }
  }

  @override
  void dispose() {
    _saveScrollPosition();
    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    final state = ref.watch(dashboardLayoutProvider(widget.dashboardKey));
    final notifier = ref.read(dashboardLayoutProvider(widget.dashboardKey).notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = _resolveBreakpoint(constraints.maxWidth);
        final isMobileShell = constraints.maxWidth < 800;

        final topSpacing = widget.useShellSpacing
            ? TopAppBarSize.resolve(context) + 12
            : 8.0;

        final bottomSpacing = widget.useShellSpacing
            ? (isMobileShell ? BottomBarSize.resolve(context) + 16 : 20.0)
            : 8.0;

        return EmmaUiAnchorTarget(
          anchorKey: 'dynamic_dashboard.${widget.dashboardKey}.page',
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await notifier.load(forceRefresh: true);
                  },
                  child: NotificationListener<OverscrollNotification>(
                    onNotification: (notification) {
                      if (notification.depth > 0 && _scrollController.hasClients) {
                        final pos = _scrollController.position;
                        final target = (pos.pixels + notification.overscroll).clamp(
                          pos.minScrollExtent,
                          pos.maxScrollExtent,
                        );
                        if (target != pos.pixels) _scrollController.jumpTo(target);
                      }
                      return false;
                    },
                    child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: topSpacing,
                      bottom: bottomSpacing,
                    ),
                    children: [
                      if (state.isLoading && state.config == null)
                         Center(
                          child: Padding(
                            padding: EdgeInsets.all(36),
                            child: AppLottie.loading(),
                          ),
                        )
                      else
                        DashboardCanvas(
                          dashboardKey: widget.dashboardKey,
                          breakpoint: breakpoint,
                        ),
                    ],
                  ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DashboardBreakpoint _resolveBreakpoint(double width) {
    if (width < 800) return DashboardBreakpoint.mobile;
    if (width < 1200) return DashboardBreakpoint.tablet;
    return DashboardBreakpoint.desktop;
  }
}