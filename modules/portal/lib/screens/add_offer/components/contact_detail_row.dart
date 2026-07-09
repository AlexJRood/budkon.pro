import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:portal/screens/add_offer/provider/location_provider_add_offer.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/user_provider.dart';

class ContactDetailRow extends ConsumerStatefulWidget {
  final bool isMobile;
  const ContactDetailRow({super.key, this.isMobile = false});

  @override
  ConsumerState<ContactDetailRow> createState() => _ContactDetailRowState();
}

class _ContactDetailRowState extends ConsumerState<ContactDetailRow> {
  bool _hasAutoFilled = false;

  /// Gets dial code from country name using the location provider
  String _getDialCodeFromCountryName(String? countryName) {
    if (countryName == null || countryName.isEmpty) {
      return '+48'; // Default to Poland
    }

    final locationState = ref.read(locationProviderAddOffer);
    
    if (locationState.countries.isEmpty) {
      return '+48'; // Default if no countries loaded
    }
    
    // Find the country in the loaded countries list
    try {
      final country = locationState.countries.firstWhere(
        (c) => c.name.toLowerCase() == countryName.toLowerCase(),
      );
      return country.phoneCode.startsWith('+') 
          ? country.phoneCode 
          : '+${country.phoneCode}';
    } catch (e) {
      // Country not found, try to find Poland as fallback
      try {
        final poland = locationState.countries.firstWhere(
          (c) => c.name == 'Poland',
        );
        return poland.phoneCode.startsWith('+') 
            ? poland.phoneCode 
            : '+${poland.phoneCode}';
      } catch (e) {
        // Poland not found either, return first country or default
        final firstCountry = locationState.countries.first;
        return firstCountry.phoneCode.startsWith('+') 
            ? firstCountry.phoneCode 
            : '+${firstCountry.phoneCode}';
      }
    }
  }

  void _autofillFromUser() {
    final userAsync = ref.read(userProvider);
    final addOfferState = ref.read(addOfferProvider);
    
    userAsync.when(
      data: (user) {
        if (user != null && !_hasAutoFilled) {
          // Autofill contact details from user data
          if (addOfferState.contactNameController.text.isEmpty) {
            final fullName = '${user.firstName} ${user.lastName}'.trim();
            if (fullName.isNotEmpty) {
              addOfferState.contactNameController.text = fullName;
            }
          }
          
          if (addOfferState.emailController.text.isEmpty && user.email.isNotEmpty) {
            addOfferState.emailController.text = user.email;
          }
          
          if (addOfferState.phoneNumberController.text.isEmpty && user.phoneNumber != null) {
            addOfferState.phoneNumberController.text = user.phoneNumber!;
          }
          
          _hasAutoFilled = true;
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Autofill from user data when component builds
    _autofillFromUser();
    
    // Get user data to determine country
    final userAsync = ref.watch(userProvider);
    String? userCountry;
    userAsync.whenData((user) {
      if (user != null) {
        userCountry = user.regCountry;
      }
    });
    
    // Create FocusNodes and TextEditingControllers once
    final focusNodePhone = FocusNode();
    final focusNodeCountry = FocusNode();
    final dialCode = _getDialCodeFromCountryName(userCountry);
    final countryCodeController = TextEditingController(text: dialCode);
    final addOfferState = ref.watch(addOfferProvider); // Watch the provider

    final theme = ref.watch(themeColorsProvider);
    if (widget.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Details'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.primaryBackgroundTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GradientTextField(
                  isPhoneField: true,
                  focusNode: focusNodePhone,
                  reqNode: FocusNode(),
                  countryCodeController: countryCodeController,

                  countryCodeHint: "",
                  hintText: "Phone".tr,
                  controller: addOfferState.phoneNumberController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GradientTextField(
                  focusNode: FocusNode(),
                  reqNode: FocusNode(),
                  controller: addOfferState.emailController,
                  hintText: "Email".tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GradientTextField(
                  focusNode: FocusNode(),
                  reqNode: FocusNode(),
                  controller: addOfferState.contactNameController,
                  hintText: "Name and Surname".tr,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Details'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.primaryBackgroundTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GradientTextField(
                  isPhoneField: true,
                  focusNode: focusNodePhone,
                  reqNode: FocusNode(),
                  countryCodeController: countryCodeController,

                  countryCodeHint: "",
                  hintText: "Phone".tr,
                  controller: addOfferState.phoneNumberController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientTextField(
                  focusNode: FocusNode(),
                  reqNode: FocusNode(),
                  controller: addOfferState.contactNameController,
                  hintText: "Name and Surname".tr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientTextField(
                  focusNode: FocusNode(),
                  reqNode: FocusNode(),
                  controller: addOfferState.emailController,
                  hintText: "Email".tr,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}
