// lib/screens/association_notifications/widgets/mobile_buttons.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class MobileNewCampaignButton extends StatelessWidget {
  const MobileNewCampaignButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        style: buttonStyleRounded10ThemeRed,
        onPressed: onPressed,
        child: const Icon(Icons.campaign, color: AppColors.white, size: 22),
      ),
    );
  }
}

class MobileRefreshButton extends StatelessWidget {
  const MobileRefreshButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: onPressed,
        child: Icon(Icons.refresh, color: theme.colorScheme.onPrimary, size: 22),
      ),
    );
  }
}
