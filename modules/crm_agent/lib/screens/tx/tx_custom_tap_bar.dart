import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_tap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';

final txTabIndexProvider = StateProvider<int>((ref) => 1);

class TxCustomTapBar extends ConsumerStatefulWidget {
  const TxCustomTapBar({super.key});

  @override
  ConsumerState<TxCustomTapBar> createState() => _TxCustomTapBarState();
}

class _TxCustomTapBarState extends ConsumerState<TxCustomTapBar> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      updateUrl(Routes.proTx);
    },);
  }
  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final color = theme.themeColor;
    final textColor = theme.textColor;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 380.w,
        height: 45.h,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing:4,
          children: [
            // SelectionNegotiationTapBar(
            //   color: color,
            //   textColor: textColor,
            //   ref: ref,
            //   index: 0,
            //   title: "Dashboard".tr,
            //   selectIndex:
            //       ()
            //       {ref.read(txTabIndexProvider.notifier).state = 0;
            //       updateUrl(Routes.proTxDashboard);
            //       ref
            //           .read(navigationHistoryProvider.notifier)
            //           .addPage(Routes.proTxDashboard);
            //         },
            //   tabIndex: ref.watch(txTabIndexProvider),
            // ),
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 1,
              title: "Transactions".tr,
              selectIndex: () {
                ref.read(txTabIndexProvider.notifier).state = 1;
                updateUrl(Routes.proTx);
                ref
                    .read(navigationHistoryProvider.notifier)
                    .addPage(Routes.proTx);
              },
              tabIndex: ref.watch(txTabIndexProvider),
            ),
            SelectionNegotiationTapBar(
              color: color,
              textColor: textColor,
              ref: ref,
              index: 2,
              title: "Drafts".tr,
              selectIndex: () {
                ref.read(txTabIndexProvider.notifier).state = 2;
                updateUrl(Routes.proTxDraft);
                ref
                    .read(navigationHistoryProvider.notifier)
                    .addPage(Routes.proTxDraft);
              },
              tabIndex: ref.watch(txTabIndexProvider),
            ),
          ],
        ),
      ),
    );
  }
}
