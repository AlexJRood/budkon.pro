import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../utils/api.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:get/get_utils/get_utils.dart';

class BrowseListActionsWidget extends ConsumerWidget {
  final bool isHidden;
  final VoidCallback toggleIsHidden;
  const BrowseListActionsWidget({
    super.key,
    required this.isHidden,
    required this.toggleIsHidden,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return SizedBox(
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.black26,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () async {
                await ref.read(browseListProvider.notifier).clearBrowseLists();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'browse_list_cleared'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                );
                // Możesz dodatkowo odświeżyć listę, np. wywołując applyFilters() lub inną metodę
                await ref.read(browseListProvider.notifier).applyFilters(ref);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 5,
                  children: [
                    const Icon(Icons.clear_outlined, size: 20),
                    if (!isHidden)
                      Flexible(
                        child: Text(
                          'Clear browse list'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.interMedium14.copyWith(
                            color: theme.textColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrowseListButtonBarWidget extends ConsumerStatefulWidget {
  final bool isHidden;
  final VoidCallback toggleIsHidden;

  const BrowseListButtonBarWidget({
    super.key,
    required this.isHidden,
    required this.toggleIsHidden,
  });

  @override
  ConsumerState<BrowseListButtonBarWidget> createState() =>
      __BrowseListPcWidgetState();
}

class __BrowseListPcWidgetState
    extends ConsumerState<BrowseListButtonBarWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return SizedBox(
      height: 50,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: widget.toggleIsHidden,
                  child: Icon(
                    widget.isHidden
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: theme.textColor,
                    size: 25,
                  ),
                ),
              ),
              if (!widget.isHidden)
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'browse_list'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.interMedium14.copyWith(
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
