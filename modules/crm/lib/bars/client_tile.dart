import 'package:core/kernel/kernel.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:crm/bars/client_appbar_drop_service.dart';
import 'package:crm/bars/contact_log.dart';
import 'package:crm/pie_menu/clients_pro.dart';
import 'package:cloud/models/cloud_drag_payload.dart';
import 'package:cloud/providers/providers.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/services/dnd_service.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:crm/crm/clients/emma/anchors_crm_clients.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mail/utils/mail_filters.dart';
import 'package:network_monitoring/providers/saved_search/add_client.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/url.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

const configUrl = URLs.baseUrl;
const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';

const double kClientListMobileCollapsedHeight = 64;
const double kClientTransactionPanelTopGap = 8;
const double kClientTransactionPanelHeight = 260;
const double kClientListMobileExpandedWithTransactionsHeight =
    32 + kClientTransactionPanelTopGap + kClientTransactionPanelHeight + 16;

final clientListAppBarExpandedProvider = StateProvider<bool>((ref) => false);
final clientListMobileVisibilityProvider = StateProvider<bool>((ref) => false);

final clientTransactionsOpenForClientIdProvider =
    StateProvider<String?>((ref) => null);

class _EdgeHoverAutoScroller {
  Timer? _timer;
  ScrollController? _controller;
  double _direction = 0;
  double _intensity = 0;
  double _maxStep = 18;

  void update({
    required ScrollController controller,
    required Rect viewportRect,
    required Offset globalPosition,
    required Axis axis,
    double triggerExtent = 56,
    double maxStep = 18,
  }) {
    _controller = controller;
    _maxStep = maxStep;

    double direction = 0;
    double intensity = 0;

    if (axis == Axis.horizontal) {
      final leftDistance = globalPosition.dx - viewportRect.left;
      final rightDistance = viewportRect.right - globalPosition.dx;

      if (leftDistance >= 0 && leftDistance <= triggerExtent) {
        direction = -1;
        intensity = (1 - (leftDistance / triggerExtent)).clamp(0.0, 1.0);
      } else if (rightDistance >= 0 && rightDistance <= triggerExtent) {
        direction = 1;
        intensity = (1 - (rightDistance / triggerExtent)).clamp(0.0, 1.0);
      }
    } else {
      final topDistance = globalPosition.dy - viewportRect.top;
      final bottomDistance = viewportRect.bottom - globalPosition.dy;

      if (topDistance >= 0 && topDistance <= triggerExtent) {
        direction = -1;
        intensity = (1 - (topDistance / triggerExtent)).clamp(0.0, 1.0);
      } else if (bottomDistance >= 0 && bottomDistance <= triggerExtent) {
        direction = 1;
        intensity = (1 - (bottomDistance / triggerExtent)).clamp(0.0, 1.0);
      }
    }

    if (direction == 0 || intensity <= 0) {
      stop();
      return;
    }

    _direction = direction;
    _intensity = intensity;

    _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final c = _controller;
      if (c == null || !c.hasClients) {
        stop();
        return;
      }

      final position = c.position;
      final delta = _direction * (4 + ((_maxStep - 4) * _intensity));
      final next = (c.offset + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      if ((next - c.offset).abs() < 0.1) return;
      c.jumpTo(next);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}

class ClientTileMobile extends ConsumerWidget {
  const ClientTileMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final clientListAsyncValue = ref.watch(clientProvider);
    final scrollController = ScrollController();

    return clientListAsyncValue.when(
      data: (clients) {
        if (clients.isEmpty) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: CustomBackgroundGradients.adGradient1(context, ref),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'no_clients_available'.tr,
                  style: AppTextStyles.interRegular12.copyWith(
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          );
        }

        return DragScrollView(
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...clients.map((client) {
                  return PieMenu(
                    theme: PieTheme.of(context).copyWith(
                      overlayColor: (() {
                        final theme = ref.watch(themeColorsProvider);
                        final bool uiIsDark =
                            theme.textColor.computeLuminance() > 0.5;
                        final base = uiIsDark ? Colors.black : Colors.white;
                        return base.withValues(alpha: 0.70);
                      })(),
                    ),
                    onPressedWithDevice: (kind) {
                      if (kind == PointerDeviceKind.mouse ||
                          kind == PointerDeviceKind.touch) {
                        final routeName =
                            ref.read(navigationService).currentPath;
                        final baseRoute = removeContactSegment(routeName);

                        if (routeName.contains('contact') &&
                            routeName.contains('dashboard')) {
                          ref.read(navigationService).beamPop();
                          ref.read(navigationService).pushNamedScreen(
                            '$baseRoute/contact/${client.id}/dashboard',
                            data: {'clientViewPop': client},
                          );
                        } else {
                          ref.read(navigationService).pushNamedScreen(
                            '$baseRoute/contact/${client.id}/dashboard',
                            data: {'clientViewPop': client},
                          );
                        }
                      }
                    },
                    actions: buildPieMenuActionsClientsPro(
                      ref,
                      client.id,
                      client,
                      context,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(navigationService)
                            .pushNamedScreen(Routes.proAddClient);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            client.avatar ?? defaultAvatarUrl,
                          ),
                          child: client.avatar == null
                              ? AppIcons.search(
                                  color: Theme.of(context).iconTheme.color,
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => DragScrollView(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              15,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: ShimmerPlaceholder(
                  height: 65,
                  width: 65,
                  radius: 50,
                ),
              ),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading clients'.tr,
          style: AppTextStyles.interRegular12,
        ),
      ),
    );
  }

  String removeContactSegment(String path) {
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }
}

class ClientListAppBar extends ConsumerStatefulWidget {
  const ClientListAppBar({super.key});

  @override
  ConsumerState<ClientListAppBar> createState() => _ClientListAppBarState();
}

class _ClientListAppBarState extends ConsumerState<ClientListAppBar> {
  late final TextEditingController searchController;
  late final ScrollController _scrollController;
  final FocusNode _searchFocusNode = FocusNode();

  final GlobalKey _clientsViewportKey = GlobalKey();
  final _EdgeHoverAutoScroller _clientsEdgeScroller = _EdgeHoverAutoScroller();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _clientsEdgeScroller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(clientProvider.notifier).fetchClients(searchQuery: value);
    });
  }

  String buildPath(String base, List<String> segments) {
    var b = base.trim();
    if (b == '/' || b.isEmpty) b = '';
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);

    final segs = segments.map((s) => s.replaceAll(RegExp(r'^/+'), '')).toList();

    final path = '/${[if (b.isNotEmpty) b, ...segs].join('/')}';
    return path.replaceAll(RegExp(r'/{2,}'), '/');
  }

  String removeContactSegment(String path) {
    final regex = RegExp(r'/contact/\d+/dashboard$');
    final cleaned = path.replaceAll(regex, '');
    if (cleaned.length > 1 && cleaned.endsWith('/')) {
      return cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  Rect? _globalRectFromKey(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  void _handleClientsDragHover(Offset globalPosition) {
    final rect = _globalRectFromKey(_clientsViewportKey);
    if (rect == null) return;

    _clientsEdgeScroller.update(
      controller: _scrollController,
      viewportRect: rect,
      globalPosition: globalPosition,
      axis: Axis.horizontal,
      triggerExtent: 64,
      maxStep: 22,
    );
  }

  void _stopClientsDragHover() {
    _clientsEdgeScroller.stop();
  }

  Future<void> _loadMoreTransactionsForClient(UserContactModel client) async {
    // TODO: connect provider/API if needed.
  }

  String _clientFullName(UserContactModel client) {
    final lastName = (client.lastName ?? '').trim();
    if (lastName.isEmpty) return client.name;
    return '${client.name} $lastName';
  }

  Widget _buildClientChip(
    BuildContext context,
    WidgetRef ref,
    UserContactModel client,
  ) {
    final theme = ref.watch(themeColorsProvider);

    return PieMenu(
      theme: PieTheme.of(context).copyWith(
        overlayColor: (() {
          final theme = ref.watch(themeColorsProvider);
          final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
          final base = uiIsDark ? Colors.black : Colors.white;
          return base.withValues(alpha: 0.70);
        })(),
      ),
      onPressedWithDevice: (kind) {
        if (kind == PointerDeviceKind.mouse ||
            kind == PointerDeviceKind.touch) {
          ref
              .read(contactOpenLogProvider.notifier)
              .logOpen(client.id, source: 'appbar');

          final routeName = ref.read(navigationService).currentPath;
          final baseRoute = removeContactSegment(routeName);

          final target = buildPath(baseRoute, [
            'contact',
            '${client.id}',
            'dashboard',
          ]);

          if (routeName.contains('contact') &&
              routeName.contains('dashboard')) {
            ref.read(navigationService).beamPop();
            ref.read(navigationService).openPopup(
              target,
              data: {'clientViewPop': client},
            );
          } else {
            ref.read(navigationService).openPopup(
              target,
              data: {'clientViewPop': client},
            );
          }
        }
      },
      actions: buildPieMenuActionsClientsPro(
        ref,
        client.id,
        client,
        context,
      ),
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: CustomBackgroundGradients.crmClientAppbarGradient(
            context,
            ref,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 6),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: ResizeImage(
                      NetworkImage(client.avatar ?? defaultAvatarUrl),
                      width: 48,
                      height: 48,
                    ),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _clientFullName(client),
                style: AppTextStyles.interRegular14.copyWith(
                  color: theme.mobileTextcolor,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientDropTarget(
    BuildContext context,
    WidgetRef ref,
    UserContactModel client,
  ) {
    return _ClientDropExpandableTile(
      key: ValueKey('client-drop-tile-${client.id}'),
      client: client,
      clientChild: _buildClientChip(context, ref, client),
      onDropToClient: (payload) async {
        await ClientAppbarDropService.handleDrop(
          context: context,
          ref: ref,
          data: payload,
          client: client,
        );
      },
      onDragHover: _handleClientsDragHover,
      onDragHoverEnd: _stopClientsDragHover,
      onLoadMoreTransactions: () => _loadMoreTransactionsForClient(client),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientListAsyncValue = ref.watch(clientProvider);
    final theme = ref.watch(themeColorsProvider);
    final isExpanded = ref.watch(clientListAppBarExpandedProvider);

    return EmmaUiAnchorTarget(
      anchorKey: 'crm.clients.appbar.root',
      spec: CrmClientsEmmaAnchors.appbarRoot,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),

          EmmaUiAnchorTarget(
            anchorKey: 'crm.clients.appbar.add_client_button',
            spec: CrmClientsEmmaAnchors.appbarAddClientButton,
            runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
            tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
            child: PieMenu(
              theme: PieTheme.of(context).copyWith(
                overlayColor: (() {
                  final theme = ref.watch(themeColorsProvider);
                  final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
                  final base = uiIsDark ? Colors.black : Colors.white;
                  return base.withValues(alpha: 0.70);
                })(),
              ),
              onPressedWithDevice: (kind) {
                if (kind == PointerDeviceKind.mouse ||
                    kind == PointerDeviceKind.touch) {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) =>
                          (moduleRegistry.slot('crm.addClientForm')?.call(context, {'isClientView': true}) ?? const SizedBox.shrink()),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                    ),
                  );
                }
              },
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: CustomBackgroundGradients.crmClientAppbarGradient(
                    context,
                    ref,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AppIcons.add(
                    color: theme.mobileTextcolor,
                    height: 25,
                    width: 25,
                  ),
                ),
              ),
            ),
          ),

          EmmaUiAnchorTarget(
            anchorKey: 'crm.clients.appbar.search',
            spec: CrmClientsEmmaAnchors.appbarSearch,
            runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
            tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
            child: PieMenu(
              theme: PieTheme.of(context).copyWith(
                overlayColor: (() {
                  final theme = ref.watch(themeColorsProvider);
                  final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
                  final base = uiIsDark ? Colors.black : Colors.white;
                  return base.withValues(alpha: 0.70);
                })(),
              ),
              onPressedWithDevice: (kind) {
                if (kind == PointerDeviceKind.mouse ||
                    kind == PointerDeviceKind.touch) {
                  final current = ref.read(clientListAppBarExpandedProvider);
                  final next = !current;
                  ref.read(clientListAppBarExpandedProvider.notifier).state =
                      next;

                  if (next) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!mounted) return;
                      FocusScope.of(context).requestFocus(_searchFocusNode);
                    });
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isExpanded ? 200 : 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: CustomBackgroundGradients.crmClientAppbarGradient(
                    context,
                    ref,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isExpanded
                    ? Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) {
                            ref
                                .read(clientListAppBarExpandedProvider.notifier)
                                .state = false;
                          }
                        },
                        child: TextField(
                          controller: searchController,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          onChanged: _scheduleSearch,
                          onSubmitted: (value) {
                            _searchDebounce?.cancel();
                            ref
                                .read(clientProvider.notifier)
                                .fetchClients(searchQuery: value);
                            ref
                                .read(clientListAppBarExpandedProvider.notifier)
                                .state = false;
                          },
                          decoration: InputDecoration(
                            hintText: 'search_client_placeholder'.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 8.0,
                            ),
                            hintStyle: AppTextStyles.interRegular12,
                          ),
                          style: AppTextStyles.interRegular12,
                          textAlign: TextAlign.start,
                        ),
                      )
                    : AppIcons.search(
                        color: theme.mobileTextcolor,
                        height: 20,
                        width: 20,
                      ),
              ),
            ),
          ),

          Expanded(
            child: EmmaUiAnchorTarget(
              anchorKey: 'crm.clients.appbar.client_strip',
              spec: CrmClientsEmmaAnchors.appbarClientStrip,
              runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
              tapMode: EmmaUiAnchorTapMode.disabled,
              child: clientListAsyncValue.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            height: 32,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: CustomBackgroundGradients.adGradient1(
                                context,
                                ref,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  'no_clients_available'.tr,
                                  style: AppTextStyles.interRegular12.copyWith(
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return SizedBox(
                    key: _clientsViewportKey,
                    child: DragScrollView(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...clients.map(
                              (client) => _buildClientDropTarget(
                                context,
                                ref,
                                client,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      10,
                      (index) => Container(
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient:
                              CustomBackgroundGradients.crmClientAppbarGradient(
                            context,
                            ref,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            children: [
                              const SizedBox(width: 6),
                              Shimmer.fromColors(
                                baseColor: ShimmerColors.base(context),
                                highlightColor: ShimmerColors.highlight(context),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: ShimmerColors.background(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Shimmer.fromColors(
                                baseColor: ShimmerColors.base(context),
                                highlightColor: ShimmerColors.highlight(context),
                                child: Container(
                                  width: 160,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: ShimmerColors.background(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => DragScrollView(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        10,
                        (index) => Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient:
                                CustomBackgroundGradients.crmClientAppbarGradient(
                              context,
                              ref,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              children: [
                                const SizedBox(width: 6),
                                Stack(
                                  children: [
                                    Shimmer.fromColors(
                                      baseColor: ShimmerColors.base(context),
                                      highlightColor:
                                          ShimmerColors.highlight(context),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color:
                                              ShimmerColors.background(context),
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      left: 5,
                                      top: 5,
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Shimmer.fromColors(
                                  baseColor: ShimmerColors.base(context),
                                  highlightColor:
                                      ShimmerColors.highlight(context),
                                  child: Container(
                                    width: 160,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: ShimmerColors.background(context),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientDropExpandableTile extends ConsumerStatefulWidget {
  const _ClientDropExpandableTile({
    super.key,
    required this.client,
    required this.clientChild,
    required this.onDropToClient,
    this.onDragHover,
    this.onDragHoverEnd,
    this.onLoadMoreTransactions,
  });

  final UserContactModel client;
  final Widget clientChild;
  final Future<void> Function(DndPayload payload) onDropToClient;
  final void Function(Offset globalPosition)? onDragHover;
  final VoidCallback? onDragHoverEnd;
  final Future<void> Function()? onLoadMoreTransactions;

  @override
  ConsumerState<_ClientDropExpandableTile> createState() =>
      _ClientDropExpandableTileState();
}

class _ClientDropExpandableTileState
    extends ConsumerState<_ClientDropExpandableTile> {
  final DndService _dndService = DndService();

  bool _expandedForTransactions = false;
  bool _pointerInsideTile = false;
  DndPayload? _activePayload;
  Timer? _collapseTimer;

  static const double _transactionPanelWidth = 320;
  static const double _transactionPanelTopGap = kClientTransactionPanelTopGap;
  static const double _transactionPanelHeight = kClientTransactionPanelHeight;

  String get _clientKey => widget.client.id.toString();

  DndPayload _payloadWithClient(DndPayload payload) {
    return payload.copyWith(
      data: {
        ...?payload.data,
        'client': widget.client.id,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _activePayload = _dndService.activeDragPayload.value;
    _dndService.activeDragPayload.addListener(_handleDragPayloadChanged);
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _dndService.activeDragPayload.removeListener(_handleDragPayloadChanged);
    super.dispose();
  }

  void _handleDragPayloadChanged() {
    if (!mounted) return;

    _activePayload = _dndService.activeDragPayload.value;

    if (_activePayload == null) {
      widget.onDragHoverEnd?.call();
    }

    _refreshExpandedState(immediateCollapse: _activePayload == null);
  }

  bool _canExpandForTransactions(DndPayload? payload) {
    if (payload == null) return false;

    final capabilities = _dndService.getAssignmentCapabilities(payload);
    final txs = widget.client.transactionsPreview?.results ?? const [];

    return capabilities.canAssignToTransaction && txs.isNotEmpty;
  }

  bool _canDropToClient(DndPayload payload) {
    return _dndService.canDrop(payload, DndTargetType.clientAppbar).isAllowed;
  }

  void _publishExpandedState(bool expanded) {
    final notifier =
        ref.read(clientTransactionsOpenForClientIdProvider.notifier);
    final currentOpen = ref.read(clientTransactionsOpenForClientIdProvider);

    if (expanded) {
      notifier.state = _clientKey;
    } else if (currentOpen == _clientKey) {
      notifier.state = null;
    }
  }

  void _setExpanded(bool value) {
    if (_expandedForTransactions == value) {
      _publishExpandedState(value);
      return;
    }

    if (!mounted) return;

    setState(() {
      _expandedForTransactions = value;
    });

    _publishExpandedState(value);
  }

  void _setPointerInside(bool value) {
    if (_pointerInsideTile == value) return;
    _pointerInsideTile = value;
    _refreshExpandedState();
  }

  void _refreshExpandedState({bool immediateCollapse = false}) {
    _collapseTimer?.cancel();

    final shouldExpand =
        _pointerInsideTile && _canExpandForTransactions(_activePayload);

    if (shouldExpand) {
      _setExpanded(true);
      return;
    }

    if (!_expandedForTransactions) {
      _publishExpandedState(false);
      return;
    }

    if (immediateCollapse) {
      _setExpanded(false);
      return;
    }

    _collapseTimer = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;

      final stillShouldExpand =
          _pointerInsideTile && _canExpandForTransactions(_activePayload);

      if (stillShouldExpand) return;

      _setExpanded(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onEnter: (_) => _setPointerInside(true),
      onHover: (_) => _setPointerInside(true),
      onExit: (_) => _setPointerInside(false),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: _expandedForTransactions ? _transactionPanelWidth : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DndReceiver(
                showHoverFeedback: false,
                showSnackbar: false,
                acceptColor: Colors.green,
                rejectColor: Colors.red,
                targets: const [DndTargetType.clientAppbar],
                onWillAcceptWithDetails: (payload) {
                  _activePayload = payload;
                  _setPointerInside(true);
                },
                onMove: (globalPosition, payload) {
                  _activePayload = payload;
                  _setPointerInside(true);
                  widget.onDragHover?.call(globalPosition);
                },
                onLeave: (_) {
                  _setPointerInside(false);
                },
                onDragLeave: () {
                  _setPointerInside(false);
                  widget.onDragHoverEnd?.call();
                },
                onDrop: (data) async {
                  widget.onDragHoverEnd?.call();
                  _setPointerInside(false);

                  if (_canDropToClient(data)) {
                    final payloadWithClient = _payloadWithClient(data);
                    await widget.onDropToClient(payloadWithClient);
                  }
                },
                builder: (
                  context,
                  hoveringPayload,
                  isHovering,
                  canAcceptDrop,
                  child,
                ) {
                  final capabilities = hoveringPayload == null
                      ? null
                      : _dndService.getAssignmentCapabilities(hoveringPayload);

                  final canOpenTransactions =
                      hoveringPayload != null &&
                          _canExpandForTransactions(hoveringPayload);

                  final hasAnyUsableTarget =
                      (capabilities?.canAssignToClient ?? false) ||
                          canOpenTransactions;

                  final showClientAccept =
                      isHovering && (capabilities?.canAssignToClient ?? false);

                  final showTransactionHint =
                      isHovering &&
                          !(capabilities?.canAssignToClient ?? false) &&
                          canOpenTransactions;

                  final showReject = isHovering && !hasAnyUsableTarget;

                  Color borderColor = Colors.transparent;
                  Color fillColor = Colors.transparent;

                  if (showClientAccept) {
                    borderColor = Colors.green.shade400;
                    fillColor = Colors.green.withOpacity(0.06);
                  } else if (showTransactionHint) {
                    borderColor = Colors.blue.shade400;
                    fillColor = Colors.blue.withOpacity(0.06);
                  } else if (showReject) {
                    borderColor = Colors.red.shade400;
                    fillColor = Colors.red.withOpacity(0.06);
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: borderColor == Colors.transparent
                          ? null
                          : Border.all(color: borderColor, width: 2),
                      color: fillColor,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                child: widget.clientChild,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _expandedForTransactions
                    ? Padding(
                        key: ValueKey('tx-panel-${widget.client.id}'),
                        padding: const EdgeInsets.only(
                          top: _transactionPanelTopGap,
                        ),
                        child: _ClientTransactionTargetsPanel(
                          client: widget.client,
                          maxHeight: _transactionPanelHeight,
                          onLoadMore: widget.onLoadMoreTransactions,
                          onDragHover: (globalPosition) {
                            _setPointerInside(true);
                            widget.onDragHover?.call(globalPosition);
                          },
                          onDragHoverEnd: () {
                            _setPointerInside(false);
                            widget.onDragHoverEnd?.call();
                          },
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('tx-panel-empty'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientTransactionTargetsPanel extends ConsumerStatefulWidget {
  const _ClientTransactionTargetsPanel({
    required this.client,
    required this.maxHeight,
    this.onLoadMore,
    this.onDragHover,
    this.onDragHoverEnd,
  });

  final UserContactModel client;
  final double maxHeight;
  final Future<void> Function()? onLoadMore;
  final void Function(Offset globalPosition)? onDragHover;
  final VoidCallback? onDragHoverEnd;

  @override
  ConsumerState<_ClientTransactionTargetsPanel> createState() =>
      _ClientTransactionTargetsPanelState();
}

class _ClientTransactionTargetsPanelState
    extends ConsumerState<_ClientTransactionTargetsPanel> {
  final ScrollController _transactionsScrollController = ScrollController();
  final GlobalKey _transactionsViewportKey = GlobalKey();
  final _EdgeHoverAutoScroller _transactionsEdgeScroller =
      _EdgeHoverAutoScroller();

  bool _loadingMore = false;

  DndPayload _payloadWithClientAndTransaction(
    DndPayload payload,
    dynamic transactionId,
  ) {
    return payload.copyWith(
      data: {
        ...?payload.data,
        'client': widget.client.id,
        'transaction': transactionId,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _transactionsScrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _transactionsScrollController.removeListener(_maybeLoadMore);
    _transactionsScrollController.dispose();
    _transactionsEdgeScroller.dispose();
    super.dispose();
  }

  String _buildSubtitle(dynamic tx) {
    final parts = <String>[];

    final status = tx.status?.toString().trim();
    if (status != null && status.isNotEmpty) {
      parts.add(status);
    }

    if (tx.amount != null) {
      final currency = (tx.currency ?? '').toString().trim();
      parts.add(
        currency.isNotEmpty ? '${tx.amount} $currency' : '${tx.amount}',
      );
    }

    return parts.join(' • ');
  }

  Rect? _globalRectFromKey(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  void _handleVerticalDragHover(Offset globalPosition) {
    final rect = _globalRectFromKey(_transactionsViewportKey);
    if (rect == null) return;

    _transactionsEdgeScroller.update(
      controller: _transactionsScrollController,
      viewportRect: rect,
      globalPosition: globalPosition,
      axis: Axis.vertical,
      triggerExtent: 48,
      maxStep: 18,
    );
  }

  Future<void> _maybeLoadMore() async {
    final txPreview = widget.client.transactionsPreview;
    final hasMore = txPreview?.hasMore ?? false;

    if (!hasMore) return;
    if (_loadingMore) return;
    if (widget.onLoadMore == null) return;
    if (!_transactionsScrollController.hasClients) return;

    final position = _transactionsScrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;

    if (remaining > 140) return;

    if (!mounted) return;
    setState(() {
      _loadingMore = true;
    });

    try {
      await widget.onLoadMore!.call();
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txPreview = widget.client.transactionsPreview;
    final transactions = txPreview?.results ?? const [];

    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 320,
      child: Material(
        elevation: 12,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight,
            minHeight: 80,
          ),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'assign_to_transaction'.tr,
                      style: AppTextStyles.interRegular12.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${txPreview?.count ?? transactions.length}',
                    style: AppTextStyles.interRegular12.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SizedBox(
                  key: _transactionsViewportKey,
                  child: ListView.separated(
                    controller: _transactionsScrollController,
                    shrinkWrap: true,
                    itemCount: transactions.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      if (_loadingMore && index == transactions.length) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final tx = transactions[index];
                      final subtitle = _buildSubtitle(tx);

                      final String title =
                          (tx.title == null ||
                                  tx.title.toString().trim().isEmpty)
                              ? 'Transaction'
                              : tx.title.toString();

                      return DndReceiver(
                        acceptColor: Colors.green,
                        rejectColor: Colors.red,
                        showSnackbar: false,
                        showHoverFeedback: true,
                        targets: const [DndTargetType.clientTransaction],
                        onWillAcceptWithDetails: (_) {
                          widget.onDragHover?.call(
                            _globalRectFromKey(_transactionsViewportKey)
                                    ?.center ??
                                Offset.zero,
                          );
                        },
                        onMove: (globalPosition, payload) {
                          widget.onDragHover?.call(globalPosition);
                          _handleVerticalDragHover(globalPosition);
                        },
                        onLeave: (_) {
                          _transactionsEdgeScroller.stop();
                          widget.onDragHoverEnd?.call();
                        },
                        onDragLeave: () {
                          _transactionsEdgeScroller.stop();
                          widget.onDragHoverEnd?.call();
                        },
                        onDrop: (data) async {
                          _transactionsEdgeScroller.stop();
                          widget.onDragHoverEnd?.call();

                          final payloadWithAssignment =
                              _payloadWithClientAndTransaction(data, tx.id);

                          await ClientAppbarDropService.handleDrop(
                            context: context,
                            ref: ref,
                            data: payloadWithAssignment,
                            client: widget.client,
                            transactionId: tx.id,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: colorScheme.surface,
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTextStyles.interRegular12.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.interRegular12
                                            .copyWith(
                                          color: theme
                                              .textTheme.bodySmall?.color
                                              ?.withOpacity(0.70),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if ((txPreview?.hasMore ?? false) && !_loadingMore) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'scroll_load_more_transactions'.tr,
                    style: AppTextStyles.interRegular12.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}