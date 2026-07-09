import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/icons.dart';

class SelectionButton extends ConsumerWidget {
  final String title;
  final String value;
  final VoidCallback onPressed;
  final Key? buttonKey;
  final bool isMobile;

  const SelectionButton({
    super.key,
    required this.title,
    required this.value,
    required this.onPressed,
    required this.isMobile,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return SizedBox(
      height: 60,
      child: ElevatedButton(
        key: buttonKey,
        style: elevatedButtonStyleRounded10,
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              // ✅ this forces texts to respect available width
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? 'All $title'.tr : value,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile? 10:14,
                        fontWeight: FontWeight.w500,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ✅ icon always visible, text will ellipsize before touching it
              AppIcons.expand(color: theme.textColor),
            ],
          ),
        ),
      ),
    );
  }
}











