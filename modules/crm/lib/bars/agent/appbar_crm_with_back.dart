import 'package:core/common/chrome/back_button.dart';
import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../client_tile.dart';

class TopAppBarCRMWithBack extends ConsumerWidget {
  final String routeName;

  const TopAppBarCRMWithBack({super.key, required this.routeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;

    const double maxWidth = 1920;
    const double minWidth = 480;
    const double maxLogoSize = 30;
    const double minLogoSize = 16;

    double logoSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxLogoSize - minLogoSize) +
        minLogoSize;
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            BackButtonHously(),
            Expanded(child: ClientListAppBar()),
            LogoHouslyWidget(),
          ],
        ),
      ],
    );
  }
}
