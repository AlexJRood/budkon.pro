// ==============================
// HELPERS
// ==============================
import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

class CenteredLoader extends StatelessWidget {
  const CenteredLoader();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(),
    ),
  );
}

class CenteredMsg extends StatelessWidget {
  const CenteredMsg(this.text, this.theme);
  final String text;
  final ThemeColors theme;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, style: TextStyle(color: theme.textColor, fontSize: 18)),
    ),
  );
}

class MobileCreateEventButton extends StatelessWidget {
  const MobileCreateEventButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 45,
        height: 45,
        child: ElevatedButton(
          style: buttonStyleRounded10ThemeRed,
          onPressed: onPressed,
          child: AppIcons.add(color: AppColors.white),
        ),
      ),
    );
  }
}

class MobileFilterButton extends StatelessWidget {
  const MobileFilterButton({
    super.key,
    required this.onPressed,
    required this.theme,
  });

  final ThemeColors theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10,
          onPressed: onPressed,
          child: Icon(
            Icons.filter_list_rounded,
            color: theme.textColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}
