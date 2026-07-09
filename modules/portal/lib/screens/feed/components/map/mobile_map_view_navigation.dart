import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/navigation_service.dart';

class NavigationBarMapMobile extends ConsumerWidget {
  const NavigationBarMapMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BuildNavigationOption(
          tag: 'FilterMobile-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag 
          icon: Icons.search,
          label: 'filter'.tr,
          onTap: () =>
              ref.read(navigationService).pushNamedScreen(Routes.filters),
        ),
        const SizedBox(height: 15),
        BuildNavigationOption(
          tag: 'SortMobile-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag 
          icon: Icons.sort,
          label: 'Sort'.tr,
          onTap: () =>
              ref.read(navigationService).pushNamedScreen(Routes.sortPopMobile),
        ),
      ],
    );
  }
}

class BuildNavigationOption extends StatelessWidget {
  const BuildNavigationOption({
    super.key,
    required this.tag,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final String tag;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: elevatedButtonStyleRounded10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: tag,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.dark, size: 30),
                const SizedBox(height: 2),
                Text(label,
                    style: AppTextStyles.interMedium
                        .copyWith(fontSize: 10, color: AppColors.dark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
