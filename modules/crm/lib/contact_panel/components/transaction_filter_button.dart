import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class TransactionFilterButton extends ConsumerWidget {
  final String text;
  final void Function()? onTap;
  final bool isicon;
  final bool isMobile;
  const TransactionFilterButton({
    super.key,
    this.isMobile =false,
    required this.text,
    this.isicon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    return SizedBox(
      height: 40,
      child:
          isicon
              ? ElevatedButton.icon(
                icon: Icon(Icons.tune, color: theme.textColor),
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  backgroundColor: WidgetStatePropertyAll(theme.clientbuttoncolor),
                ),
                onPressed: onTap,
                label: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 12,
                  ),
                ),
              )
              : ElevatedButton(
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  backgroundColor: WidgetStatePropertyAll(theme.clientbuttoncolor),
                ),
                onPressed: onTap,
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 11,
                  ),
                ),
              ),
    );
  }
}
