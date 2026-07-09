import 'dart:ui' as ui;

import 'package:core/ui/components/buttons.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

Future<void> _openNoteSheet(
  BuildContext context,
  WidgetRef ref, {
  required void Function(String) onTabSelected,
  required ContactType contactType,
  required String currentRoute,
}) async {
  final theme = ref.read(themeColorsProvider);

  final moreItems = buildBottomBarMoreMenuItemsForContactType(
    type: contactType,
    theme: theme,
    currentRoute: currentRoute,
    maxVisible: 4,
  );

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.dashboardContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.more_vert, color: theme.textColor),
                    const SizedBox(width: 8),
                    Text(
                      'More'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickActionsBar(
                  context: context,
                  theme: theme,
                  currentRoute: currentRoute,
                  items: moreItems,
                  onTabSelected: onTabSelected,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildQuickActionsBar({
  required BuildContext context,
  required ThemeColors theme,
  required String currentRoute,
  required List<ContactMenuItem> items,
  required void Function(String) onTabSelected,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ).copyWith(color: theme.sidebar),
    child: Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final item in items)
          _QuickActionButton(
            item: item,
            currentRoute: currentRoute,
            onTabSelected: onTabSelected,
          ),
      ],
    ),
  );
}

class _QuickActionButton extends StatelessWidget {
  final ContactMenuItem item;
  final String currentRoute;
  final void Function(String) onTabSelected;

  const _QuickActionButton({
    required this.item,
    required this.currentRoute,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (item.route == '__chat__') {
      return SizedBox(
        width: 60,
        height: 60,
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10,
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => const ChatPage(),
                transitionsBuilder: (_, anim, __, child) {
                  return FadeTransition(opacity: anim, child: child);
                },
              ),
            );
          },
          child: item.icon,
        ),
      );
    }

    return BuildIconButton(
      icon: item.icon,
      label: item.label,
      onPressed: () {
        Navigator.of(context).maybePop();
        onTabSelected(item.route);
      },
      route: item.route,
      currentRoute: currentRoute,
    );
  }
}

class BottombarClientPanel extends ConsumerWidget {
  final void Function(String) onTabSelected;
  final String activeSection;
  final ContactType contactType;

  const BottombarClientPanel({
    super.key,
    required this.onTabSelected,
    required this.activeSection,
    this.contactType = ContactType.client,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = activeSection;
    final theme = ref.read(themeColorsProvider);

    final visibleItems = buildBottomBarMainMenuItemsForContactType(
      type: contactType,
      theme: theme,
      currentRoute: currentRoute,
      maxVisible: 4,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          height: BottomBarSize.resolve(context),
          color: theme.sidebar,
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in visibleItems)
                BuildIconButton(
                  icon: item.icon,
                  label: item.label,
                  onPressed: () => onTabSelected(item.route),
                  route: item.route,
                  currentRoute: currentRoute,
                ),

              BuildIconButton(
                icon: AppIcons.moreVertical(
                  color: currentRoute == 'more'
                      ? AppColors.white
                      : theme.textColor,
                ),
                label: 'More'.tr,
                onPressed: () {
                  _openNoteSheet(
                    context,
                    ref,
                    onTabSelected: onTabSelected,
                    contactType: contactType,
                    currentRoute: currentRoute,
                  );
                },
                route: 'more',
                currentRoute: currentRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}