//lib/components/appbar.dart

import 'dart:async';
import 'package:portal/bars/onHoverPortal/manage.dart';
import 'package:core/shell/components/add_an_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:portal/screens/pop_pages/pages/view_settings_page.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/common/chrome/logo_hously.dart';
import 'dart:ui' as ui;

final isViewSettingPageProvider = StateProvider<bool>((ref) => false);

class TopAppBarPortal extends ConsumerStatefulWidget {
  final Padding? sidebarPadding;
  final bool? isBackButton;
  final bool? onlyBackButton;
  final bool isThatOnHover;

  const TopAppBarPortal({
    super.key,
    this.sidebarPadding,
    this.isBackButton = false,
    this.onlyBackButton = false,
    this.isThatOnHover = false,
  });

  @override
  ConsumerState<TopAppBarPortal> createState() => _TopAppBarPortalState();
}

class _TopAppBarPortalState extends ConsumerState<TopAppBarPortal> {
  // tutaj już masz dostęp do WidgetRef ref
  String?
  openPopup; // null albo 'sort', 'buy', 'rent', 'sell', 'manage', 'help'
  Timer? _hoverTimer;

  final GlobalKey sortButtonTopAppBar = GlobalKey();
  final GlobalKey buyButtonKey = GlobalKey();
  final GlobalKey rentButtonKey = GlobalKey();
  final GlobalKey sellButtonKey = GlobalKey();
  final GlobalKey manageButtonKey = GlobalKey();
  final GlobalKey helpButtonKey = GlobalKey();

  void _setOpenPopup(String? popup) {
    _hoverTimer?.cancel();
    setState(() {
      openPopup = popup;
    });
  }

  void _startCloseTimer() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(
      ref.watch(isViewSettingPageProvider)
          ? Duration(seconds: 2)
          : Duration(milliseconds: 150),
          () {
        if (ref.read(isViewSettingPageProvider)) return;
        if (!mounted) return;

        setState(() {
          openPopup = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 1920;
    const double minWidth = 480;
    const double maxLogoSize = 30;
    const double minLogoSize = 16;
    double logoSize =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxLogoSize - minLogoSize) +
        minLogoSize;
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);
    double widthRatio = screenWidth / 1920.0;
    double dynamicSizedBoxWidth = 150.0 * widthRatio - 30;
    final theme = ref.watch(themeColorsProvider);
    final isViewSetting = ref.watch(isViewSettingPageProvider);

    return Column(
      children: [
        // AppBar
        SizedBox(
          height: 60,
          width: screenWidth - 60,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildHoverButton(
                        ref: ref, // <--- dodajemy
                        label: 'Preferences'.tr,
                        icon: AppIcons.global(
                          height: 25.0,
                          width: 25,
                          color: theme.textColor,
                        ),
                        popupKey: sortButtonTopAppBar,
                        popupName: 'preferences',
                        onPressed: () {
                          setState(() {
                            openPopup = null;
                          });
                          Navigator.pushNamed(context, '/buy');
                        },
                      ),


                      // TODO: finish flow 
                      
                      // _buildHoverButton(
                      //   ref: ref, // <--- dodajemy
                      //   label: 'Buy'.tr,
                      //   popupKey: buyButtonKey,
                      //   popupName: 'buy',
                      //   onPressed: () {
                      //     setState(() {
                      //       openPopup = null;
                      //     });
                      //     Navigator.pushNamed(context, '/buy');
                      //   },
                      // ),
                      // _buildHoverButton(
                      //   ref: ref, // <--- dodajemy
                      //   label: 'Rent'.tr,
                      //   popupKey: rentButtonKey,
                      //   popupName: 'rent',
                      //   onPressed: () {
                      //     setState(() {
                      //       openPopup = null;
                      //     });
                      //     Navigator.pushNamed(context, '/buy');
                      //   },
                      // ),

                      // _buildHoverButton(
                      //   ref: ref, // <--- dodajemy
                      //   label: 'Manage',
                      //   popupKey: manageButtonKey,
                      //   popupName: 'manage',
                      //   onPressed: () {
                      //   setState(() {
                      //     openPopup = null;
                      //   });
                      //   Navigator.pushNamed(context, '/buy');
                      // },
                      // ),
                      // _buildHoverButton(
                      //   ref: ref, // <--- dodajemy
                      //   label: 'Help',
                      //   popupKey: helpButtonKey,
                      //   popupName: 'help',
                      //   onPressed: () {
                      //   setState(() {
                      //     openPopup = null;
                      //   });
                      //   Navigator.pushNamed(context, '/buy');
                      // },
                      // ),
                    ],
                  ),
                  SizedBox(width: dynamicSizedBoxWidth),

                  if (!widget.isThatOnHover)
                    Row(children: [AddAnAddWidget(), const LogoHouslyWidget()]),
                ],
              ),
            ),
          ),
        ),

        if (openPopup != null)
          MouseRegion(
            onEnter: (_) => _hoverTimer?.cancel(),
            onExit: (_) => _startCloseTimer(),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                child: AnimatedContainer(
                  color: theme.textFieldColor.withAlpha(75),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 350,
                  child: _buildPopup(theme.textColor),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHoverButton({
    required String label,
    Widget? icon,
    required GlobalKey popupKey,
    required String popupName,
    VoidCallback? onPressed,
    required WidgetRef ref,
  }) {
    final theme = ref.watch(themeColorsProvider);
    final isActive = openPopup == popupName;

    return MouseRegion(
      opaque: true,
      onEnter: (_) => _setOpenPopup(popupName),
      onExit: (_) => _startCloseTimer(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isActive
                  ? theme.textFieldColor.withAlpha(75)
                  : Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
        child: Hero(
          tag: 'SortBarButton-$label',
          child: Container(
            key: popupKey,
            height: 60,
            color: Colors.transparent,
            child: Row(
              children: [
                if (icon != null) icon,
                if (icon != null) const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTextStyles.interMedium14.copyWith(
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopup(color) {
    switch (openPopup) {
      case 'preferences':
        return ViewSettingsPage(buttonPosition: Offset.zero, isTopAppbar: true);
      case 'buy':
        return ManagePopupContentWidget(color: color, type: ColumnSetType.buy);
      case 'rent':
        return ManagePopupContentWidget(color: color, type: ColumnSetType.rent);
      case 'manage':
        return ManagePopupContentWidget(
          color: color,
          type: ColumnSetType.manage,
        );
      case 'help':
        return ViewPopChangerPage(buttonPosition: Offset.zero);
      default:
        return const SizedBox.shrink();
    }
  }
}
