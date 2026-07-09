import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:calendar/state_managers/popup_calendar_provider.dart';
import 'package:calendar/widgets/save_event_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class NoEventWidget extends ConsumerWidget {
  final bool isPc;
  final String? clientId;
  const NoEventWidget({super.key, this.isPc = true, this.clientId});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    double screenWidth = MediaQuery.of(context).size.width;
    final secondContainerwidthmobile = screenWidth * (1100 / 1920);
    final firstContainerwidthmobile = screenWidth * (900 / 1920);
    final secondContainerwidthPc = screenWidth * (220 / 1920);
    final firstContainerwidthmobiPC = screenWidth * (150 / 1920);
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 25),
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.textColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color.fromARGB(255, 61, 61, 61),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 2,
                    left: 2,
                    right: 2,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    height: 100,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: theme.textFieldColor,
                          spreadRadius: 0,
                          blurRadius: 0,
                          offset: Offset(1, -1),
                        ),
                      ],
                      border: Border.all(
                        color: const Color.fromARGB(255, 61, 61, 61),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: theme.textFieldColor,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                              height: 25,
                              width:
                                  isPc
                                      ? firstContainerwidthmobiPC
                                      : firstContainerwidthmobile,
                              decoration: BoxDecoration(
                                color: theme.textColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                              height: 30,
                              width:
                                  isPc
                                      ? secondContainerwidthPc
                                      : secondContainerwidthmobile,
                              decoration: BoxDecoration(
                                color: theme.textColor.withAlpha(
                                  (255 * 0.5).toInt(),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 98,
                  left: 10,
                  child: Icon(
                    Icons.more_horiz_rounded,
                    size: 25,
                    color: theme.fillColor,
                  ),
                ),
                Positioned(
                  right: 25,
                  bottom: 3,
                  child: Transform.rotate(
                    angle:
                        450 *
                        3.1415927 /
                        360, // Rotation in radians (45 degrees)

                    child: Icon(
                      Icons.send_rounded,
                      size: 30,
                      color: theme.fillColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  "Create and manage events seamlessly in one place".tr,
                  style: TextStyle(color: theme.textColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      theme.clientbuttoncolor,
                    ),
                    shape: WidgetStatePropertyAll(
                      (RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      )),
                    ),
                    minimumSize: WidgetStateProperty.all(
                      Size(double.infinity, 40),
                    ),
                  ),
                  icon: Icon(Icons.add, color: theme.textColor, size: 14),
                  label: Text(
                    "Add New Event".tr,
                    style: TextStyle(fontSize: 10, color: theme.textColor),
                  ),
                  onPressed: () {
                    ref.read(appointmentsProvider).isEdit = false;
                    ref.read(popupCalendarProvider.notifier).clearAllFields();

                    // (optional) Preselect the client on client dashboard
                    final cid = int.tryParse('$clientId');
                    if (cid != null) {
                      final ev = ref.read(popupCalendarProvider).event;
                      ref.read(popupCalendarProvider).event = ev.copyWith(
                        client: cid,
                      );
                    }
                    if (isPc) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            insetPadding: const EdgeInsets.all(24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              height: screenSize.height / 1.2,
                              width: screenSize.width / 1.2,
                              child: SaveEventWidget(isMobile: false, index: 0),
                            ),
                          );
                        },
                      );
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.dashboardContainer,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.85,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            expand: false,
                            builder:
                                (context, scrollController) => SaveEventWidget(
                                  isMobile: true,
                                  scrollController: scrollController,
                                  index: 0,
                                ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
