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
  final int? transactionId;
  final int? clientId;
  final bool isTablet;
  const BrowseListActionsWidget({
    super.key,
    required this.isHidden,
    required this.toggleIsHidden,
    this.transactionId,
    this.clientId,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
          final scope = BrowseScope(
      transactionId: transactionId,
      clientId: clientId,
    );

    return SizedBox(
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child:  Container(
            color: Colors.black26,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10.copyWith(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
              ),
              onPressed: () async {
                await ref.read(networkMonitoringBrowseListProvider(scope).notifier).clearBrowseListsNM(transactionId, clientId);           
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Browse list cleared'.tr),
                  ),
                );
                await ref.read(networkMonitoringBrowseListProvider(scope).notifier).applyFilters(ref);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTablet ? Icons.delete_outline : Icons.clear_outlined,
                    size: isTablet ? 18 : 20,
                    color: theme.textColor,
                  ),
                  if (!isHidden) ...[
                    SizedBox(width: isTablet ? 4 : 8),
                    Flexible(
                      child: Text(
                        (isTablet ? 'Clear' : 'Clear browsing list').tr,
                        style: isTablet
                            ? AppTextStyles.interMedium10.copyWith(color: theme.textColor)
                            : AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
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
  BrowseListPcWidgetState createState() => BrowseListPcWidgetState();
}

class BrowseListPcWidgetState extends ConsumerState<BrowseListButtonBarWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
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
                    size: 25,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (!widget.isHidden)
                Flexible(
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Browse list".tr,
                            style: AppTextStyles.interMedium14.copyWith(
                              color: theme.textColor
                            ),
                        ),
                      const SizedBox(width:10 ),
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
