import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/widgets/event.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class ViewWidget extends ConsumerWidget {
  final bool isMobile;
  const ViewWidget(
      {super.key,
      this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            if (!ref.watch(showScheduleEventProvider))
              InkWell(
                onTap: () {
                  ref.read(showScheduleEventProvider.notifier).state = true;
                },
                child: Container(
                  height: 32,
                  width: 152,
                  decoration:  BoxDecoration(
                      color: theme.themeColor,
                      borderRadius: BorderRadius.all(Radius.circular(6))),
                  child:  Row(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 16,
                      ),
                      Text(
                        'Schedule an Event'.tr,
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      )
                    ],
                  ),
                ),
              ),
            if (ref.watch(showScheduleEventProvider))
              AddEventCardWidget(
                isMobile: isMobile,
              )
          ],
        ));
  }
}
