
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/common/shared_widgets/country_model.dart';

import 'package:reports/reports/create_report_page/providers/location_data_provider.dart';
import 'package:reports/reports/create_report_page/providers/providers_report.dart';
import 'package:core/common/shared_widgets/location_components.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/apptheme.dart';

class HeaderLocationWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  const HeaderLocationWidget({super.key, this.isMobile = false});

  @override
  ConsumerState<HeaderLocationWidget> createState() =>
      _HeaderLocationWidgetState();
}

class _HeaderLocationWidgetState extends ConsumerState<HeaderLocationWidget> {
  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(propertyValuationFormProvider);
    final theme = ref.watch(themeColorsProvider);
    final locationState = ref.watch(locationProviderReport);
    final locationNotifier = ref.read(locationProviderReport.notifier);
    if (widget.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            "Location".tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          SizedBox(height: 16),
          Column(
            children: [
              locationState.isLoading
                  ? Row(
                    children: [
                      Expanded(
                        child: GradientDropdownAddOffer(
                          isPc: true,
                          hintText: 'Country'.tr,
                          value: 'loading...',
                          items: ['Loading...'],
                          selectedItem: 'loading...',
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: GradientDropdownCountryAddoffer(
                          isPc: true,
                          hintText: 'Country'.tr,
                          value: formState.country,
                          items:
                              locationState.countries.isEmpty
                                  ? [
                                    DropDownCountry(
                                      name: 'Loading...',
                                      isoCode: '',
                                      phoneCode: '',
                                    ),
                                  ]
                                  : locationState.countries,
                          selectedItem: formState.country,
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(propertyValuationFormProvider.notifier)
                                  .updateField('country', value);
                              ref
                                  .read(propertyValuationFormProvider.notifier)
                                  .updateField('state', '');
                              ref
                                  .read(propertyValuationFormProvider.notifier)
                                  .updateField('city', '');
                              locationNotifier.clearStates();
                              locationNotifier.clearCities();
                              locationNotifier.loadStates(value.name);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GradientDropdownAddOffer(
                      isPc: true,
                      hintText: 'State'.tr,
                      value: formState.state ?? '',
                      items: locationState.states,
                      selectedItem: formState.state ?? '',
                      onChanged: (value) {
                        ref
                            .read(propertyValuationFormProvider.notifier)
                            .updateField('state', value);
                        ref
                            .read(propertyValuationFormProvider.notifier)
                            .updateField('city', '');
                        locationNotifier.clearCities();
                        if (formState.country != null && value != null) {
                          locationNotifier.loadCities(
                            formState.country!.name,
                            value,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GradientDropdownAddOffer(
                      isPc: true,
                      hintText: 'City'.tr,
                      value: formState.city ?? '',
                      items: locationState.cities,
                      selectedItem: formState.city ?? '',
                      onChanged: (value) {
                        ref
                            .read(propertyValuationFormProvider.notifier)
                            .updateField('city', value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GradientTextField(
                  controller: formState.streetAddressController,
                  hintText: 'Street Address'.tr,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GradientTextField(
                  controller: formState.zipcodeController,
                  hintText: 'Zipcode'.tr,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GradientDropdownAddOffer(
                  isPc: true,
                  value: "${formState.distanceFilter} km",
                  selectedItem: "${formState.distanceFilter} km",
                  items: ['0 km', '1 km', '5 km', '10 km', '20 km'],
                  onChanged: (value) {
                    // Remove non-numeric characters (e.g., " km") and try to parse the number
                    final numericValue = double.tryParse(
                      value!.replaceAll(RegExp(r'[^0-9.]'), ''),
                    );

                    if (numericValue != null) {
                      ref
                          .read(propertyValuationFormProvider.notifier)
                          .updateField('distanceFilter', numericValue);
                    } else {}
                  },

                  hintText: 'Distance Filter'.tr,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            "Location".tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              locationState.isLoading
                  ? Expanded(
                    child: GradientDropdownAddOffer(
                      isPc: true,
                      hintText: 'Country'.tr,
                      value: 'loading...',
                      items: ['Loading...'],
                      selectedItem: 'loading...',
                      onChanged: (value) {},
                    ),
                  )
                  : Expanded(
                    child: GradientDropdownCountryAddoffer(
                      isPc: true,
                      hintText: 'Country'.tr,
                      value: formState.country,
                      items:
                          locationState.countries.isEmpty
                              ? [
                                DropDownCountry(
                                  name: 'Loading...',
                                  isoCode: '',
                                  phoneCode: '',
                                ),
                              ]
                              : locationState.countries,
                      selectedItem: formState.country,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .updateField('country', value);
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .updateField('state', '');
                          ref
                              .read(propertyValuationFormProvider.notifier)
                              .updateField('city', '');
                          locationNotifier.clearStates();
                          locationNotifier.clearCities();
                          locationNotifier.loadStates(value.name);
                        }
                      },
                    ),
                  ),
              SizedBox(width: 10),
              Expanded(
                child: GradientDropdownAddOffer(
                  isPc: true,
                  hintText: 'State'.tr,
                  value: formState.state ?? '',
                  items: locationState.states,
                  selectedItem: formState.state ?? '',
                  onChanged: (value) {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('state', value);
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('city', '');
                    locationNotifier.clearCities();
                    if (formState.country != null && value != null) {
                      locationNotifier.loadCities(
                        formState.country!.name,
                        value,
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: GradientDropdownAddOffer(
                  isPc: true,
                  hintText: 'City'.tr,
                  value: formState.city ?? '',
                  items: locationState.cities,
                  selectedItem: formState.city ?? '',
                  onChanged: (value) {
                    ref
                        .read(propertyValuationFormProvider.notifier)
                        .updateField('city', value);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientTextField(
                  controller: formState.streetAddressController,
                  hintText: 'Street Address'.tr,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: GradientTextField(
                  controller: formState.zipcodeController,
                  hintText: 'Zipcode'.tr,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: GradientDropdownAddOffer(
                  isPc: true,
                  value: "${formState.distanceFilter} km",
                  selectedItem: "${formState.distanceFilter} km",
                  items: ['0 km', '1 km', '5 km', '10 km', '20 km'],
                  onChanged: (value) {
                    // Remove non-numeric characters (e.g., " km") and try to parse the number
                    final numericValue = double.tryParse(
                      value!.replaceAll(RegExp(r'[^0-9.]'), ''),
                    );

                    if (numericValue != null) {
                      ref
                          .read(propertyValuationFormProvider.notifier)
                          .updateField('distanceFilter', numericValue);
                    } else {}
                  },

                  hintText: 'Distance Filter'.tr,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      );
    }
  }
}
