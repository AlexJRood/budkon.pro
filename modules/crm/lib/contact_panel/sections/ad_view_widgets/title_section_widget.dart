import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class TitleSection extends StatelessWidget {
  const TitleSection({
    super.key,
    required this.isEditing,
    required this.titleController,
    required this.theme,
    required this.mainWidth,
  });

  final bool isEditing;
  final TextEditingController titleController;
  final ThemeColors theme;
  final double mainWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: isEditing
          ? SizedBox(
        width: mainWidth,
        child: BuildTextField(
          controller: titleController,
          labelText: 'listing_title_label'.tr,
          maxLines: 1,
          isEditAdView: true,
        ),
      )
          : Material(
        color: Colors.transparent,
        child: Text(
          titleController.text,
          style: AppTextStyles.interBold
              .copyWith(fontSize: 22, color: theme.textColor),
        ),
      ),
    );
  }
}

