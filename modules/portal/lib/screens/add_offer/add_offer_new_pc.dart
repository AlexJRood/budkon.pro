import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/add_offer/components/drop_zone.dart';
import 'package:portal/screens/add_offer/components/offer_images_upload_status_bar.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/pages/pc/add_offer_plan_screen.dart';
import 'package:portal/screens/add_offer/pages/pc/details_information_form.dart';
import 'package:portal/screens/add_offer/pages/pc/general_information_form.dart';
import 'package:portal/screens/add_offer/pages/pc/image_upload_screen.dart';
import 'package:portal/screens/add_offer/pages/pc/offer_summary_screen.dart';
import 'package:portal/screens/add_offer/pages/pc/offer_type_selector.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:portal/emma/anchors/anchors_portal.dart';

class AddOfferNewPc extends ConsumerWidget {
  const AddOfferNewPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = <Widget>[
      const OfferTypeSelector(),
      const ImageUploadWidget(),
      const GeneralInformationForm(),
      const DetailsInformationForm(),
      const AddofferPlanScreen(),
      const OfferSummaryScreen(),
    ];

    final progress = ref.watch(progressProvider);
    final addOfferState = ref.watch(addOfferProvider);
    final offerType = addOfferState.offerTypeController.text;

    log(offerType);
    log(MediaQuery.of(context).size.width.toString());

    final currentPageIndex = progressToPageIndex(progress, pages.length);
    final horizontalPadding = MediaQuery.of(context).size.width / 7;

    return EmmaUiAnchorTarget(
      anchorKey: PortalEmmaAnchors.addOfferRoot.anchorKey,

      spec: PortalEmmaAnchors.addOfferRoot,
      runtimeMode: PortalEmmaAnchors.addOfferRoot.runtimeMode,
      tapMode: PortalEmmaAnchors.addOfferRoot.tapMode,
      child: UniversalOfferDropZone(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (addOfferState.shouldShowDeferredUploadStatusbar) ...[
              const SizedBox(height: 14),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const OfferImagesUploadStatusBar(
                  compact: true,
                  showWhenComplete: false,
                ),
              ),
            ],
            EmmaUiAnchorTarget(
              anchorKey: PortalEmmaAnchors.addOfferProgress.anchorKey,

              spec: PortalEmmaAnchors.addOfferProgress,
              runtimeMode: PortalEmmaAnchors.addOfferProgress.runtimeMode,
              tapMode: PortalEmmaAnchors.addOfferProgress.tapMode,
              child: const ProgressIndicatorWidget(),
            ),
            const SizedBox(height: 20),
            pages[currentPageIndex],
          ],
        ),
      ),
      ),
    );
  }
}