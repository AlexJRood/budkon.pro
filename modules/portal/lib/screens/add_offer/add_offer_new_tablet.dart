import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
// Import your existing pages
import 'package:portal/screens/add_offer/pages/pc/add_offer_plan_screen.dart';
import 'package:portal/screens/add_offer/pages/pc/general_information_form.dart';
import 'package:portal/screens/add_offer/pages/pc/image_upload_screen.dart';
import 'package:portal/screens/add_offer/pages/pc/offer_summary_screen.dart';
import 'package:portal/screens/add_offer/pages/pc/offer_type_selector.dart';
import 'package:portal/screens/add_offer/pages/widgets/add_offer_banner_selector_screen.dart';

class AddOfferNewTablet extends ConsumerWidget {
  const AddOfferNewTablet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);

    final List<Widget> pages = [
      const OfferTypeSelector(isTablet: true),
      const ImageUploadWidget(),
      const GeneralInformationForm(),
      const AddofferPlanScreen(isTablet: true),
      const OfferSummaryScreen(),
      const BannerSelectorScreen(),
    ];

    final currentPageIndex = (progress - 0.5).floor().clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          // Tablet Padding (Landing Page Style)
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const ProgressIndicatorWidget(),
              const SizedBox(height: 20),
              // Center the content to prevent it stretching too wide on 1300px
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: pages[currentPageIndex],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}