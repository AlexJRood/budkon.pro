import 'package:flutter/material.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/custom_vertical_divider.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_button.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_list_view.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NegotiationWidget extends StatelessWidget {
  final bool isMobile;
  const NegotiationWidget({super.key,this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding:  EdgeInsets.symmetric(horizontal: isMobile?10:160.0),
          child: Row(
            spacing: isMobile?20.w:40.w,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlipperCustomListView(
                        title: 'Saved Properties (3)',
                        itemCount: 10,
                        id: 1,
                      ),
                      CustomVerticalDivider(),
                      FlipperCustomListView(
                        title: 'Offers Reached Out (1)',
                        itemCount: 1,
                        id: 2,
                      ),
                      CustomVerticalDivider(),
                      FlipperCustomListView(
                        title: 'Scheduled Viewings (1)',
                        itemCount: 1,
                        id: 3,
                      ),
                      CustomVerticalDivider(),
                      FlipperCustomListView(
                        title: 'Offers Sent (3)',
                        itemCount: 10,
                        id: 4,
                      ),
                      CustomVerticalDivider(),
                      FlipperCustomListView(
                        title: 'Counter-Offers (1)',
                        itemCount: 3,
                        id: 5,
                      ),
                        ],
                      ),
                ),
              ),
                if(!isMobile)
                DottedBorder(
                  color:
                      Colors.cyanAccent.withAlpha((255 * 0.5).toInt()),
                  strokeWidth: 1.5,
                  dashPattern: const [4, 2],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(10),
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 80,
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900, // Dark background color
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              
            ],
          ),
        ),
        if(!isMobile)
         Positioned(
          right: 20,
          bottom: 20,
          child: Column(
            spacing: 12.h,
            children: [
              FlipperCustomButton(
                icon: Icons.add_box_outlined,
                label: 'Publish',
              ),
              FlipperCustomButton(
                icon: Icons.add_box_outlined,
                label: 'Edit',
              ),
              FlipperCustomButton(
                icon: Icons.add_box_outlined,
                label: 'Transaction',
              ),
            ],
          ),
        )
      ],
    );
  }
}
