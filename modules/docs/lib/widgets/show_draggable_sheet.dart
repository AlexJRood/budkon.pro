import 'package:flutter/material.dart';

Future<T?> showDraggableSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext ctx, ScrollController sc) builder,
  double initialChildSize = 0.55,
  double minChildSize = 0.35,
  double maxChildSize = 0.7,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              color: Theme.of(ctx).scaffoldBackgroundColor,
            ),
            child: builder(ctx, scrollController),
          );
        },
      );
    },
  );
}
