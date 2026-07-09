import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/fliper_list_view__custom_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// StateNotifier to manage hover state per widget
class HoverNotifier extends StateNotifier<bool> {
  HoverNotifier() : super(false);
  void setHover(bool value) => state = value;
}

// Unique provider for each widget instance
final hoverProvider = StateNotifierProvider.family<HoverNotifier, bool, int>(
      (ref, id) => HoverNotifier(),
);

class FlipperCustomListView extends ConsumerWidget {
  final String title;
  final int itemCount;
  final int id; // Unique ID to differentiate instances

  const FlipperCustomListView({
    super.key,
    required this.title,
    required this.itemCount,
    required this.id, // Pass a unique ID for each widget
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = ref.watch(hoverProvider(id)); // Unique state for each widget

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 330.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:  TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        return const FlipperListViewCustomCard(
                          imageUrl: 'assets/images/landingpage.webp',
                          address: 'Warszawa, Mokotów, Poland',
                          name: 'Biały Kamień Street',
                          price: '250,000',
                          profitPotential: '50,000',
                        );
                      },
                    ),
                     SizedBox(height: 10.h), // Spacing before the button

                    // Add Property Button with Unique Hover State
                    MouseRegion(
                      onEnter: (_) => ref.read(hoverProvider(id).notifier).setHover(true),
                      onExit: (_) => ref.read(hoverProvider(id).notifier).setHover(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 32.h,
                        width: 230.w,
                        decoration: BoxDecoration(
                          color: isHovered ? Colors.blueGrey.shade800 : Colors.transparent,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        padding:  EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            AppIcons.add(color: isHovered ? Colors.cyanAccent : Colors.grey),
                             SizedBox(width: 6.w),
                            Text(
                              'Add Property',
                              style: TextStyle(
                                color: isHovered ? Colors.cyanAccent : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
