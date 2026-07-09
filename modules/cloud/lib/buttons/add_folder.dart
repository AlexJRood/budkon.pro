import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:cloud/api/add_folder.dart";
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import "package:get/get.dart";

// Dodaj tu!
class AddFolderCard extends ConsumerWidget {
  final String? appLabel;
  final String? model;
  final String? objectId;
  final String? relationType;
  final bool isClient;

  const AddFolderCard({
    super.key,
    this.appLabel,
    this.model,
    this.objectId,
    this.relationType,
    this.isClient = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return ElevatedButton(
      style: styledButton(
        color: theme.dashboardContainer,
        foregroundAlpha: 255,
        surfaceAlpha: 255,
      ),
      onPressed:
          () => showAddFolderDialog(
            context,
            theme,
            isClient: isClient,
            appLabel: appLabel,
            model: model,
            objectId: objectId,
            relationType: relationType,
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcons.add(color: theme.textColor),
            const SizedBox(width: 8),
            Text(
              "New folder".tr,
              style: TextStyle(
                fontSize: 12,
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
