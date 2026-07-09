import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class OfferSummaryScreen extends ConsumerWidget {
  final bool isMobile;
  const OfferSummaryScreen({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobilepadding = MediaQuery.of(context).size.width <= 500
        ? 15.0
        : MediaQuery.of(context).size.width / 8;

    final dynamicPadding = isMobile
        ? mobilepadding
        : MediaQuery.of(context).size.width / 7;

    final theme = ref.watch(themeColorsProvider);
    final offerState = ref.watch(addOfferProvider);

    final estateType = offerState.estateTypeController.text.trim();

    final commonFields = [
      infoRow(
        'property_type'.tr,
        offerState.estateTypeController.text.isNotEmpty
            ? offerState.estateTypeController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Street Address'.tr,
        offerState.streetController.text.isNotEmpty
            ? offerState.streetController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'City'.tr,
        offerState.cityController.text.isNotEmpty
            ? offerState.cityController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'State'.tr,
        offerState.stateController.text.isNotEmpty
            ? offerState.stateController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Zip Code'.tr,
        offerState.zipcodeController.text.isNotEmpty
            ? offerState.zipcodeController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Country'.tr,
        offerState.countryController.text.isNotEmpty
            ? offerState.countryController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Market Type'.tr,
        offerState.marketTypeController.text.isNotEmpty
            ? offerState.marketTypeController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'advertiser_type'.tr,
        offerState.advertiserTypeController.text.isNotEmpty
            ? offerState.advertiserTypeController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Build Year'.tr,
        offerState.buildYearController.text.isNotEmpty
            ? offerState.buildYearController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Heating type'.tr,
        offerState.heatingTypeController.text.isNotEmpty
            ? offerState.heatingTypeController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
    ];

    final studioFlatHouseFields = isStudioFlatHouse(estateType)
        ? [
            infoRow(
              'Square Footage'.tr,
              offerState.squareFootageController.text.isNotEmpty
                  ? '${offerState.squareFootageController.text}m²'
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Number of Rooms'.tr,
              offerState.roomsController.text.isNotEmpty
                  ? offerState.roomsController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Number of Bathrooms'.tr,
              offerState.bathroomsController.text.isNotEmpty
                  ? offerState.bathroomsController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Floor/Level'.tr,
              offerState.floorController.text.isNotEmpty
                  ? offerState.floorController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Total Floors'.tr,
              offerState.totalFloorsController.text.isNotEmpty
                  ? offerState.totalFloorsController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Building Type'.tr,
              offerState.buildingTypeController.text.isNotEmpty
                  ? offerState.buildingTypeController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Building Material'.tr,
              offerState.buildingMaterialController.text.isNotEmpty
                  ? offerState.buildingMaterialController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Apartment Number'.tr,
              offerState.appartmentNumberController.text.isNotEmpty
                  ? offerState.appartmentNumberController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
          ]
        : [];

    final garageWarehouseFields = isGarageWarehouse(estateType)
        ? [
            infoRow(
              'Design'.tr,
              offerState.designController.text.isNotEmpty
                  ? offerState.designController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Position'.tr,
              offerState.positionController.text.isNotEmpty
                  ? offerState.positionController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Lightning'.tr,
              offerState.lightningController.text.isNotEmpty
                  ? offerState.lightningController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Surface'.tr,
              offerState.surfaceController.text.isNotEmpty
                  ? '${offerState.surfaceController.text}m²'
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Energy Certificate'.tr,
              offerState.energyCertificateController.text.isNotEmpty
                  ? offerState.energyCertificateController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
          ]
        : [];

    final lotFields = isLot(estateType)
        ? [
            infoRow(
              'Surface'.tr,
              offerState.surfaceController.text.isNotEmpty
                  ? '${offerState.surfaceController.text}m²'
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Price Per m²'.tr,
              offerState.pricePerM2Controller.text.isNotEmpty
                  ? '${offerState.currencyController.text}${offerState.pricePerM2Controller.text}'
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Dimensions'.tr,
              offerState.dimensionsController.text.isNotEmpty
                  ? offerState.dimensionsController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Plot Type'.tr,
              offerState.plotTypeController.text.isNotEmpty
                  ? offerState.plotTypeController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Fence'.tr,
              offerState.fenceController.text.isNotEmpty
                  ? offerState.fenceController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
            infoRow(
              'Position'.tr,
              offerState.positionController.text.isNotEmpty
                  ? offerState.positionController.text
                  : 'N/A',
              theme.primaryBackgroundTextColor,
            ),
          ]
        : [];

    final additionalFeatures = [
      infoRow(
        'Balcony'.tr,
        offerState.balconyController.text.isNotEmpty
            ? offerState.balconyController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Elevator'.tr,
        offerState.elevatorController.text.isNotEmpty
            ? offerState.elevatorController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Sauna'.tr,
        offerState.saunaController.text.isNotEmpty
            ? offerState.saunaController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Garage'.tr,
        offerState.garageController.text.isNotEmpty
            ? offerState.garageController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Parking'.tr,
        offerState.parkingSpaceController.text.isNotEmpty
            ? offerState.parkingSpaceController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Air Conditioning'.tr,
        offerState.airConditioningController.text.isNotEmpty
            ? offerState.airConditioningController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Basement'.tr,
        offerState.basementController.text.isNotEmpty
            ? offerState.basementController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
    ];

    final additionalFeaturesPlot = [
      infoRow(
        'Access'.tr,
        offerState.accessController.text.isNotEmpty
            ? offerState.accessController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Area'.tr,
        offerState.areaController.text.isNotEmpty
            ? offerState.areaController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Current'.tr,
        offerState.currentController.text.isNotEmpty
            ? offerState.currentController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Gas'.tr,
        offerState.gasController.text.isNotEmpty
            ? offerState.gasController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Sewers'.tr,
        offerState.sewersController.text.isNotEmpty
            ? offerState.sewersController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Water'.tr,
        offerState.waterController.text.isNotEmpty
            ? offerState.waterController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Phone'.tr,
        offerState.phoneController.text.isNotEmpty
            ? offerState.phoneController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      infoRow(
        'Cesspool'.tr,
        offerState.cesspoolController.text.isNotEmpty
            ? offerState.cesspoolController.text
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
    ];

    final priceFields = [
      infoRow(
        'Total Price'.tr,
        offerState.priceController.text.isNotEmpty
            ? '${offerState.currencyController.text}${offerState.priceController.text}'
            : 'N/A',
        theme.primaryBackgroundTextColor,
      ),
      if (isLot(estateType))
        infoRow(
          'Price per m²'.tr,
          offerState.pricePerM2Controller.text.isNotEmpty
              ? '${offerState.currencyController.text}${offerState.pricePerM2Controller.text}'
              : 'N/A',
          theme.primaryBackgroundTextColor,
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryBackgroundTextColor.withAlpha(26),
                    theme.primaryBackgroundTextColor.withAlpha(13),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryBackgroundTextColor.withAlpha(76),
                  width: 2,
                ),
              ),
              child: Text(
                'Summary'.tr,
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  color: theme.primaryBackgroundTextColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.primaryBackgroundTextColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Check the information before posting.'.tr,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: theme.primaryBackgroundTextColor.withAlpha(230),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            if (offerState.hasPendingUploads) ...[
              const SizedBox(height: 18),
              _statusBanner(
                context,
                theme.primaryBackgroundTextColor,
                Colors.orange,
                'photos_uploading_background'.tr,
              ),
            ],

            if (offerState.hasFailedUploads) ...[
              const SizedBox(height: 12),
              _statusBanner(
                context,
                theme.primaryBackgroundTextColor,
                Colors.red,
                'photos_upload_failed'.tr,
              ),
            ],

            const SizedBox(height: 40),

            if (!isMobile) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPropertyDetailsTable(
                      'Property Details'.tr,
                      [
                        ...commonFields,
                        ...studioFlatHouseFields,
                        ...garageWarehouseFields,
                        ...lotFields,
                      ],
                      theme.primaryBackgroundTextColor,
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isStudioFlatHouse(estateType) || isLot(estateType)) ...[
                          _buildPropertyDetailsTable(
                            'Additional Features'.tr,
                            isStudioFlatHouse(estateType)
                                ? additionalFeatures
                                : additionalFeaturesPlot,
                            theme.primaryBackgroundTextColor,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildPropertyDetailsTable(
                          'Price'.tr,
                          priceFields,
                          theme.primaryBackgroundTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              sectionTitle('Description'.tr, theme.primaryBackgroundTextColor),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryBackgroundTextColor.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.primaryBackgroundTextColor.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: Text(
                  offerState.descriptionController.text.isNotEmpty
                      ? offerState.descriptionController.text
                      : 'No description provided.'.tr,
                  style: TextStyle(
                    color: theme.primaryBackgroundTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              sectionTitle('Media'.tr, theme.primaryBackgroundTextColor),
              const SizedBox(height: 16),
              _buildMediaGrid(offerState),
            ],

            if (isMobile) ...[
              _buildPropertyDetailsTable(
                'Property Details'.tr,
                [
                  ...commonFields,
                  ...studioFlatHouseFields,
                  ...garageWarehouseFields,
                  ...lotFields,
                ],
                theme.primaryBackgroundTextColor,
              ),
              const SizedBox(height: 30),
              sectionTitle('Description'.tr, theme.primaryBackgroundTextColor),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryBackgroundTextColor.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.primaryBackgroundTextColor.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: Text(
                  offerState.descriptionController.text.isNotEmpty
                      ? offerState.descriptionController.text
                      : 'No description provided.'.tr,
                  style: TextStyle(
                    color: theme.primaryBackgroundTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (isStudioFlatHouse(estateType) || isLot(estateType)) ...[
                const SizedBox(height: 30),
                _buildPropertyDetailsTable(
                  'Additional Features'.tr,
                  isStudioFlatHouse(estateType)
                      ? additionalFeatures
                      : additionalFeaturesPlot,
                  theme.primaryBackgroundTextColor,
                ),
                const SizedBox(height: 30),
              ],
              _buildPropertyDetailsTable(
                'Price'.tr,
                priceFields,
                theme.primaryBackgroundTextColor,
              ),
              const SizedBox(height: 30),
              sectionTitle('Media'.tr, theme.primaryBackgroundTextColor),
              const SizedBox(height: 16),
              _buildMediaGrid(offerState),
            ],

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(progressProvider.notifier).state -= 1;
                  },
                  child: Text(
                    'Back'.tr,
                    style: TextStyle(
                      color: theme.primaryBackgroundTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 250,
                  child: SettingsButton(
                    isPc: true,
                    buttonheight: 50,
                    onTap: () async {
                      final result = await ref.read(addOfferProvider.notifier).sendData(context, ref);

                      if (!context.mounted) return;

                      switch (result) {
                        case AddOfferSubmitResult.success:
                          ref.read(addOfferProvider.notifier).resetForm();
                          ref.read(progressProvider.notifier).state = 0.5;
                          ref.read(maxVisitedStepProvider.notifier).state = 0;
                          ref.read(addOfferFilterProvider.notifier).state = {};

                          ref.read(navigationService).pushNamedScreen(Routes.profile);
                          break;

                        case AddOfferSubmitResult.notLoggedIn:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "not_logged_in".tr,
                              "you_need_to_login_to_post_ad".tr,
                              "warning".tr,
                              null,
                            ),
                          );
                          ref.read(navigationService).pushNamedScreen(Routes.loginPop);
                          break;

                        case AddOfferSubmitResult.emptyTitle:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "warning".tr,
                              'title_cant_be_empty'.tr,
                              'warning'.tr,
                              null,
                            ),
                          );
                          break;

                        case AddOfferSubmitResult.emptyDescription:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "warning".tr,
                              'description_cant_be_empty'.tr,
                              'warning'.tr,
                              null,
                            ),
                          );
                          break;

                        case AddOfferSubmitResult.notEnoughImages:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "warning".tr,
                              'must_add_at_least_4_photos_snackbar'.tr,
                              'warning'.tr,
                              null,
                            ),
                          );
                          break;

                        case AddOfferSubmitResult.pendingUploads:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "warning".tr,
                              'wait_for_photos_upload'.tr,
                              'warning'.tr,
                              null,
                            ),
                          );
                          break;

                        case AddOfferSubmitResult.failedUploads:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "warning".tr,
                              'photos_upload_error_retry'.tr,
                              'warning'.tr,
                              null,
                            ),
                          );
                          break;

                        case AddOfferSubmitResult.notEnoughUploadedImages:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "warning".tr,
                              'at_least_4_photos_must_be_uploaded'.tr,
                              'warning'.tr,
                              null,
                            ),
                          );
                          break;

                        case AddOfferSubmitResult.failed:
                          ref.read(navigationService).showSnackbar(
                            Customsnackbar().showSnackBar(
                              "error".tr,
                              "error_occurred_sending_data".tr,
                              "error".tr,
                              null,
                            ),
                          );
                          break;
                      }
                    },
                    text: offerState.hasPendingUploads
                        ? 'Waiting for uploads...'.tr
                        : 'Submit'.tr,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(
    BuildContext context,
    Color textColor,
    Color accent,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMediaGrid(AddOfferState offerState) {
    if (offerState.imageItems.isEmpty) {
      return Container(
        width: 160,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white70),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(offerState.imageItems.length, (index) {
        final item = offerState.imageItems[index];
        final isMain = index == 0;

        return Stack(
          children: [
            Container(
              width: 160,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: MemoryImage(item.previewBytes),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (item.isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            if (item.hasError)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.white),
                  ),
                ),
              ),
            if (isMain)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(130),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Main'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget sectionTitle(String title, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 24),
        child: Text(
          title,
          style: AppTextStyles.libreCaslonHeading.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );

  Widget _buildPropertyDetailsTable(
    String title,
    List<Widget> rows,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(title, color),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(51)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: color.withAlpha(13),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Property'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Details'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              ...rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: index < rows.length - 1
                          ? BorderSide(color: color.withAlpha(26))
                          : BorderSide.none,
                    ),
                  ),
                  child: row,
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget infoRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _formatValue(value),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );

  String _formatValue(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'yes') return 'Yes'.tr;
    if (normalized == 'no') return 'No'.tr;
    if (normalized == 'n/a') return 'N/A'.tr;

    final currencies = ['CZK', 'PLN', 'EUR', 'GBP', 'USD'];

    for (final currency in currencies) {
      if (value.startsWith(currency)) {
        return value.replaceFirst(currency, '$currency ');
      }
    }

    return value;
  }

  bool _sameType(String current, String target) {
    return current == target || current == target.tr;
  }

  bool isStudioFlatHouse(String type) {
    final types = [
      'Studio',
      'Flat',
      'House',
      'Twin house',
      'Row house',
      'Invest',
      'Commercial',
      'Room',
      'Apartment',
    ];
    return types.any((item) => _sameType(type, item));
  }

  bool isGarageWarehouse(String type) {
    return _sameType(type, 'Garage') || _sameType(type, 'Warehouse');
  }

  bool isLot(String type) {
    return _sameType(type, 'Lot');
  }
}