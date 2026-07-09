import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class AddressText extends StatelessWidget {
  const AddressText({super.key, required this.state, required this.theme});

  final dynamic state;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '${state.streetController.text}, ${state.cityController.text}, ${state.stateController.text}',
        style: AppTextStyles.interRegular16.copyWith(color: theme.textColor),
      ),
    );
  }
}