import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/add_offer/components/drop_zone.dart';
import 'package:portal/screens/add_offer/components/offer_images_upload_status_bar.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/pages/mobile/addOffer_planScreen_mobile.dart';
import 'package:portal/screens/add_offer/pages/mobile/general_information_screen_mobile.dart';
import 'package:portal/screens/add_offer/pages/mobile/offer_type_selector_mobile.dart';
import 'package:portal/screens/add_offer/pages/pc/details_information_form.dart';
import 'package:portal/screens/add_offer/pages/pc/image_upload_screen.dart';
import 'package:portal/screens/add_offer/pages/pc/offer_summary_screen.dart';
import 'package:portal/screens/add_offer/pages/widgets/add_offer_banner_selector_screen.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/ui/device_type_util.dart';

class AddOfferNewMobile extends ConsumerWidget {
  const AddOfferNewMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = <Widget>[
      const OfferTypeSelectorMobile(),
      const ImageUploadWidget(isMobile: true),
      const GeneralInformationScreenMobile(isMobile: true),
      const DetailsInformationForm(isMobile: true,),
      const AddofferPlanScreenMobile(),
      const OfferSummaryScreen(isMobile: true),
      // const BannerSelectorScreen(isMobile: true),
    ];

    final progress = ref.watch(progressProvider);
    final addOfferState = ref.watch(addOfferProvider);
    final offerType = addOfferState.offerTypeController.text;

    log(offerType);
    log(MediaQuery.of(context).size.width.toString());

    final currentPageIndex =
    (progress - 0.5).floor().clamp(0, pages.length - 1);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomBarSpace = BottomBarSize.resolve(context);

    return UniversalOfferDropZone(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: TopAppBarSize.resolve(context),
          ),
          const ProgressIndicatorWidget(),
          if (addOfferState.hasAnyImages) ...[
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: OfferImagesUploadStatusBar(
                compact: true,
                showWhenComplete: true,
              ),
            ),
          ],
          const SizedBox(height: 12),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: bottomInset > 0 ? 16 : bottomBarSpace + 16,
              ),
              child: pages[currentPageIndex],
            ),
          ),
        ],
      ),
    );
  }
}