import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:core/theme/apptheme.dart';

class MonitoringCustomMap extends ConsumerWidget {
  final bool isMobile;
  const MonitoringCustomMap({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Stack(
      children: [
        Image.asset(
          isMobile
              ? 'assets/images/monitoring-map-mobile.webp'
              : 'assets/images/map-1212.webp',
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          height: 180,
        ),
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            height: 32,
            width: 103,
            decoration:  BoxDecoration(
              color: theme.textFieldColor.withAlpha((255 * 0.7).toInt()),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Center(
              child: Text(
                'Show on Map'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
