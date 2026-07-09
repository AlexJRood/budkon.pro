import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm/bars/contact_log.dart';
import 'package:crm/pie_menu/clients_pro.dart';
import 'package:crm_agent/add_client_form/add_client_form_mobile.dart';
import 'package:crm_agent/add_client_form/add_client_form_page.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:crm_agent/crm/providers/dashboard_service.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_earning_chart_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

class DbRecentLeadsAndChartWidget extends StatelessWidget {
  const DbRecentLeadsAndChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final height = hasBoundedHeight ? constraints.maxHeight : 420.0;
        final isNarrow = constraints.maxWidth < 900;

        return SizedBox(
          height: height,
          width: double.infinity,
          child:
              isNarrow
                  ? const Column(
                    children: [
                      Expanded(child: DbRecentLeadsWidget()),
                      SizedBox(height: 12),
                      Expanded(child: DbEarningChartWidget()),
                    ],
                  )
                  : const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: DbRecentLeadsWidget()),
                      SizedBox(width: 20),
                      Expanded(flex: 1, child: DbEarningChartWidget()),
                    ],
                  ),
        );
      },
    );
  }
}

class DbRecentLeadsWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final double? height;
  final String backgroundMode;
  final bool showHeader;
  final String itemStyle;
  final bool compact;

  const DbRecentLeadsWidget({
    super.key,
    this.isMobile = false,
    this.height,
    this.backgroundMode = 'card',
    this.showHeader = true,
    this.itemStyle = 'card',
    this.compact = false,
  });

  @override
  ConsumerState<DbRecentLeadsWidget> createState() =>
      _DbRecentLeadsWidgetState();
}

class _DbRecentLeadsWidgetState extends ConsumerState<DbRecentLeadsWidget> {
  static const double _oneTileHeightThreshold = 90.0;

  bool get _transparentBackground => widget.backgroundMode == 'transparent';
  bool get _minimalItems => widget.itemStyle == 'minimal';

  late final ScrollController _listController;

  // Raw px dragged past the edge since we last saw the list not pinned there.
  // A small threshold before we start forwarding avoids an abrupt, jarring
  // handoff the instant the list bottoms/tops out.
  double _edgeDragSlack = 0;
  static const double _edgeDragSlackThreshold = 6.0;

  @override
  void initState() {
    super.initState();
    _listController = ScrollController();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _openAddClient(BuildContext context, ThemeColors theme) {
    if (kIsWeb || !widget.isMobile) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder:
              (_, __, ___) => const AddClientFormScreen(isClientView: true),
          transitionsBuilder:
              (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
        ),
      );
      return;
    }

    showModalBottomSheet(
      backgroundColor: theme.dashboardContainer,
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return AddClientFormMobile(
              isClientView: false,
              sheetScrollController: scrollController,
            );
          },
        );
      },
    );
  }

  Color _pieOverlayColor(ThemeColors theme) {
    final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
    final base = uiIsDark ? Colors.black : Colors.white;
    return base.withValues(alpha: 0.70);
  }

  String _cleanPhone(String? value) {
    if (value == null) return '';
    return value.trim().replaceAll(RegExp(r'[^\d+]'), '');
  }

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _handleEmailTap(BuildContext context, String? email) async {
    final clean = email?.trim() ?? '';
    if (clean.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Add email in client details'.tr)),
      );
      return;
    }
    if (_isMobilePlatform) {
      final uri = Uri(scheme: 'mailto', path: clean);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        await Clipboard.setData(ClipboardData(text: clean));
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text('${'Copied email'.tr}: $clean')),
          );
        }
      }
    } else {
      await Clipboard.setData(ClipboardData(text: clean));
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('${'Copied email'.tr}: $clean'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showNoteDialog(BuildContext context, ThemeColors theme, String note) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.dashboardContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sticky_note_2_outlined, color: theme.textColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'note'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: theme.textColor, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      note,
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.8).toInt()),
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePhoneTap(BuildContext context, String? phoneNumber) async {
    final clean = _cleanPhone(phoneNumber);

    if (clean.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Add phone number in client details'.tr)),
      );
      return;
    }

    if (_isMobilePlatform) {
      final uri = Uri(scheme: 'tel', path: clean);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not open phone app'.tr)),
        );
      }
    } else {
      await Clipboard.setData(ClipboardData(text: clean));
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('${'Copied phone number'.tr}: $clean'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openClientDashboard(dynamic contact) {
    ref
        .read(contactOpenLogProvider.notifier)
        .logOpen(contact.id, source: 'dashboard');

    final routeName = ref.read(navigationService).currentPath;
    final baseRoute = removeContactSegment(routeName);

    ref
        .read(navigationService)
        .pushNamedScreen(
          '$baseRoute/contact/${contact.id}/dashboard',
          data: {'clientViewPop': contact},
        );
  }

  Widget _buildHeader({
    required BuildContext context,
    required ThemeColors theme,
    required bool isCompact,
  }) {
    if (isCompact) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'recent_contacts'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ref.read(navigationService).pushNamedScreen(Routes.proClients);
            },
            icon: Icon(
              Icons.open_in_new_rounded,
              color: theme.textColor,
              size: 18,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'recent_contacts'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PieMenu(
              theme: PieTheme.of(
                context,
              ).copyWith(overlayColor: _pieOverlayColor(theme)),
              onPressedWithDevice: (kind) {
                if (kind == PointerDeviceKind.mouse ||
                    kind == PointerDeviceKind.touch) {
                  final routeName = ref.read(navigationService).currentPath;

                  ref
                      .read(navigationService)
                      .pushNamedScreen('$routeName${Routes.addClientForm}');

                  ref.read(showUserContactsProvider.notifier).state = true;
                }
              },
              actions: buildPieMenuActionsClientsPro(ref, 1, 1, context),
              child: SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  style: elevatedButtonStyleRounded10,
                  icon: AppIcons.add(
                    height: 25,
                    width: 25,
                    color: theme.textColor,
                  ),
                  onPressed: () => _openAddClient(context, theme),
                ),
              ),
            ),
            TextButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
                ref.read(navigationService).pushNamedScreen(Routes.proClients);
              },
              child: Text(
                'View All'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, color: theme.textColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactAvatar({
    required dynamic contact,
    required ThemeColors theme,
    required bool isCompact,
  }) {
    final radius = isCompact ? 16.r : 20.r;
    final size = radius * 2;

    return CircleAvatar(
      backgroundColor: theme.textColor.withAlpha((255 * 0.8).toInt()),
      radius: radius,
      child:
          contact.avatar != null
              ? ClipOval(
                child: Image.network(
                  contact.avatar!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  cacheWidth: 250,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.person,
                        color: theme.textColor,
                        size: isCompact ? 16 : 20,
                      ),
                ),
              )
              : Icon(
                Icons.person,
                color: theme.textColor,
                size: isCompact ? 16 : 20,
              ),
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required dynamic contact,
    required ThemeColors theme,
    required bool isCompact,
  }) {
    final hasNote = (contact.note?.toString() ?? '').isNotEmpty;
    final hasEmail = (contact.email?.toString() ?? '').trim().isNotEmpty;
    final actionSize = isCompact ? 16.sp : 18.sp;
    final activeColor = theme.textColor.withAlpha((255 * 0.8).toInt());
    final dimColor = theme.textColor.withAlpha(80);
    final useCard = !_minimalItems;

    final emailOrPhone = (contact.email?.toString().trim().isNotEmpty == true)
        ? contact.email!.toString()
        : (contact.phoneNumber?.toString().trim() ?? '');
    final serviceType = contact.serviceType?.toString().trim() ?? '';

    Widget actionIcon({
      required IconData icon,
      required VoidCallback? onTap,
      required bool active,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: active ? activeColor : dimColor, size: actionSize),
          ),
        ),
      );
    }

    return PieMenu(
      theme: PieTheme.of(context).copyWith(overlayColor: _pieOverlayColor(theme)),
      onPressedWithDevice: (kind) {
        if (kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.touch) {
          _openClientDashboard(contact);
        }
      },
      actions: buildPieMenuActionsClientsPro(ref, contact.id, contact, context),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: useCard ? 3 : 0),
        padding: EdgeInsets.symmetric(
          horizontal: useCard ? 10 : 0,
          vertical: isCompact ? 7 : 9,
        ),
        decoration: useCard
            ? BoxDecoration(
                color: theme.adPopBackground.withAlpha(110),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dashboardBoarder.withAlpha(110),
                ),
              )
            : null,
        child: Row(
          children: [
            _buildContactAvatar(contact: contact, theme: theme, isCompact: isCompact),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${contact.name} ${contact.lastName ?? ''}".trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: isCompact ? 12.sp : 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (emailOrPhone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      emailOrPhone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: isCompact ? 10.sp : 11.sp,
                      ),
                    ),
                  ],
                  if (!widget.isMobile && !isCompact && serviceType.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      serviceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(140),
                        fontSize: 10.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isMobile && !isCompact) ...[
                  actionIcon(
                    icon: Icons.mail_outline_rounded,
                    onTap: () => _handleEmailTap(context, contact.email?.toString()),
                    active: hasEmail,
                    tooltip: _isMobilePlatform ? 'Open email app'.tr : 'Copy email'.tr,
                  ),
                  actionIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => _openClientDashboard(contact),
                    active: true,
                    tooltip: 'chat'.tr,
                  ),
                  actionIcon(
                    icon: Icons.sticky_note_2_outlined,
                    onTap: hasNote
                        ? () => _showNoteDialog(context, theme, contact.note.toString())
                        : null,
                    active: hasNote,
                    tooltip: 'note'.tr,
                  ),
                ],
                actionIcon(
                  icon: Icons.call_outlined,
                  onTap: () => _handlePhoneTap(context, contact.phoneNumber?.toString()),
                  active: _cleanPhone(contact.phoneNumber?.toString()).isNotEmpty,
                  tooltip: _isMobilePlatform ? 'call'.tr : 'Copy'.tr,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // The contacts list is a nested vertical Scrollable inside the dashboard's
  // page-level scroll view. The gesture arena hands the whole drag to
  // whichever Scrollable is deepest, so once it wins there is no built-in way
  // for the ancestor page to take over even after this list is fully
  // scrolled to its edge. `onPointerMove` bypasses the gesture arena (it
  // fires for every raw pointer move regardless of which recognizer "wins"),
  // so once this list is pinned at an edge we can drive the ancestor
  // Scrollable's position 1:1 with the finger for the rest of the drag.
  void _forwardEdgeDragToAncestor(BuildContext context, PointerMoveEvent event) {
    if (!_listController.hasClients) return;

    final dy = event.delta.dy;
    if (dy == 0) return;

    final inner = _listController.position;
    final atTop = inner.pixels <= inner.minScrollExtent;
    final atBottom = inner.pixels >= inner.maxScrollExtent;

    final draggingTowardsStart = dy > 0;
    final pinnedAtRelevantEdge = draggingTowardsStart ? atTop : atBottom;

    if (!pinnedAtRelevantEdge) {
      _edgeDragSlack = 0;
      return;
    }

    _edgeDragSlack += dy.abs();
    if (_edgeDragSlack < _edgeDragSlackThreshold) return;

    final edgeValue = atTop ? inner.minScrollExtent : inner.maxScrollExtent;
    if (inner.pixels != edgeValue) {
      inner.jumpTo(edgeValue);
    }

    final outer = Scrollable.maybeOf(context)?.position;
    if (outer == null) return;

    final target = (outer.pixels - dy).clamp(
      outer.minScrollExtent,
      outer.maxScrollExtent,
    );

    if (target != outer.pixels) {
      outer.jumpTo(target);
    }
  }

  Widget _buildContactsList({
    required BuildContext context,
    required ThemeColors theme,
    required bool isCompact,
  }) {
    final recentContacts = ref.watch(recentContactsProvider);

    return recentContacts.when(
      data: (contacts) {
        if (contacts.isEmpty) {
          return Center(
            child: AppLottie.noResults(size: isCompact ? 120 : 300),
          );
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          child: Listener(
            onPointerMove: (event) => _forwardEdgeDragToAncestor(context, event),
            onPointerUp: (_) => _edgeDragSlack = 0,
            onPointerCancel: (_) => _edgeDragSlack = 0,
            child: ListView.builder(
              controller: _listController,
              physics: const ClampingScrollPhysics(),
              padding: _minimalItems
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(vertical: 4),
              addAutomaticKeepAlives: false,
              cacheExtent: 300.0,
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];

                return _buildContactRow(
                  context: context,
                  contact: contact,
                  theme: theme,
                  isCompact: isCompact,
                );
              },
            ),
          ),
        );
      },
      loading:
          () => Center(child: AppLottie.loading(size: isCompact ? 120 : 300)),
      error:
          (e, _) => Center(child: AppLottie.error(size: isCompact ? 120 : 300)),
    );
  }

  Widget _buildAvatarStrip({
    required BuildContext context,
    required ThemeColors theme,
    required bool showBorder,
  }) {
    final recentContacts = ref.watch(recentContactsProvider);

    return Container(
      height: double.infinity,
      decoration: showBorder
          ? BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.dashboardBoarder),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: recentContacts.when(
          data: (contacts) {
            if (contacts.isEmpty) return const SizedBox.shrink();

            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown,
                },
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final name =
                      "${contact.name} ${contact.lastName ?? ''}".trim();
                  return Tooltip(
                    message: name,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () => _openClientDashboard(contact),
                      child: _buildContactAvatar(
                        contact: contact,
                        theme: theme,
                        isCompact: true,
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final height = hasBoundedHeight
            ? constraints.maxHeight
            : (widget.height ?? (widget.isMobile ? 500.0 : 330.0));

        final isOneTile = height < _oneTileHeightThreshold;

        if (isOneTile) {
          return _buildAvatarStrip(
            context: context,
            theme: theme,
            showBorder: !_transparentBackground,
          );
        }

        final isCompact = widget.compact || height < 260;

        final content = ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: _transparentBackground
                ? null
                : BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.dashboardBoarder),
                  ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showHeader) ...[
                  _buildHeader(
                    context: context,
                    theme: theme,
                    isCompact: isCompact,
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                ],
                Expanded(
                  child: _buildContactsList(
                    context: context,
                    theme: theme,
                    isCompact: isCompact,
                  ),
                ),
              ],
            ),
          ),
        );

        if (hasBoundedHeight) {
          return SizedBox.expand(child: content);
        }

        return SizedBox(height: height, child: content);
      },
    );
  }

  String removeContactSegment(String path) {
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }
}
