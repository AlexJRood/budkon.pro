import 'package:portal/bars/onHoverPortal/onhover_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';

import 'package:core/platform/route_constant.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import '../../providers/news_letter_provider.dart';


class FooterWidget extends ConsumerWidget {
  final double paddingDynamic;
  final bool isProfile;
  final bool isTablet;

  const FooterWidget({
    super.key,
    required this.paddingDynamic,
    this.isProfile = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void navigateToAboutUs(BuildContext context) {
      ref.read(navigationService).pushNamedScreen(Routes.aboutusview);
    }
    final newsletterState = ref.watch(newsletterProvider);
    final newsletterNotifier = ref.read(newsletterProvider.notifier);
    final theme = ref.watch(themeColorsProvider);
    final emailController = newsletterNotifier.emailController;
    bool isChecked = false;
    const double footerSpacer = 10;

    Widget buildNewsletterSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOUSLY.PRO ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'subscribe_newsletter'.tr,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: isTablet ? double.infinity : 345,
            child: TextFormField(
              controller: emailController,
              style: TextStyle(color: Colors.white),
              cursorColor:  Colors.white,
              decoration: InputDecoration(
                suffixIcon: InkWell(
                  onTap: () async {
                    final email = emailController.text.trim();
                    final customSnackBar = Customsnackbar();

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          customSnackBar.showSnackBar(
                              'invalid_email_title'.tr,
                              'enter_email_message'.tr,
                              'warning',
                              null
                          )
                      );
                      return;
                    }
                    if (!isChecked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          customSnackBar.showSnackBar(
                              'terms_required_title'.tr,
                              'terms_required_message'.tr,
                              'warning',
                                  () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              }
                          )
                      );
                      return;
                    }
                    try {
                      await newsletterNotifier.subscribeToNewsletter(
                        email: email,
                        source: 'landing_page',
                        language: Localizations.localeOf(context).languageCode,
                      );

                      final currentState = ref.read(newsletterProvider);

                      if (!currentState.isLoading && currentState.hasValue) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            customSnackBar.showSnackBar(
                                'success_title'.tr,
                                'newsletter_success'.tr,
                                'success',
                                    () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                }
                            )
                        );
                        emailController.clear();

                      } else if (currentState.hasError) {
                        // Error case
                        ScaffoldMessenger.of(context).showSnackBar(
                            customSnackBar.showSnackBar(
                                'subscription_failed_title'.tr,
                                'subscription_failed_message'.tr,
                                'error',
                                    () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  // Optionally retry subscription
                                }
                            )
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          customSnackBar.showSnackBar(
                              'generic_error_title'.tr,
                              'generic_error_message'.tr,
                              'error',
                                  () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                              }
                          )
                      );
                    }
                  },
                  child: newsletterState.isLoading?
                      Transform.scale(
                             scale: 0.5,
                             child: CircularProgressIndicator(color: theme.textColor, strokeWidth: 2,))
                      : Icon(
                    Icons.arrow_forward,
                    color: Color.fromRGBO(145, 145, 145, 1),
                  ),
                ),
                filled: true,
                hint: Text('Email'.tr,style: TextStyle(color:Colors.white),),
                fillColor: Colors.transparent,
                hintStyle: TextStyle(color: theme.textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: theme.textColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: theme.textColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: theme.textColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'email_required'.tr;
                if (!GetUtils.isEmail(value)) return 'invalid_email'.tr;
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatefulBuilder(
                builder: (context, setState) => Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        isChecked = value;
                      });
                    }
                  },
                  checkColor: Colors.black,
                  activeColor: Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  'agree_terms'.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget buildNavigationLinks() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: footerSpacer,
        children: [
          Text(
            'navigation_links'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          PopupHoverButton(
            route: '/feed',
            label: 'buy'.tr,
            color: Colors.white,
            filters: {'offer_type': 'buy'},
          ),
          PopupHoverButton(
            route: '/feed',
            label: 'rent'.tr,
            color: Colors.white,
            filters: {'offer_type': 'rent'},
          ),
          PopupHoverButton(
            route: '/feed',
            label: 'sell'.tr,
            color: Colors.white,
            filters: {'offer_type': 'sell'},
          ),
          PopupHoverButton(
            route: '/feed',
            label: 'invest'.tr,
            color: Colors.white,
            filters: const {'offer_type': 'invest'},
          ),
        ],
      );
    }

    Widget buildCategories() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: footerSpacer,
        children: [
          Text(
            'categories'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          PopupHoverButton(
            route: '/feed',
            label: 'flat'.tr,
            color: Colors.white,
            filters: {'estate_type': ['Flat']},
          ),
          PopupHoverButton(
            route: '/feed',
            label: 'studio_apartment'.tr,
            color: Colors.white,
            filters: {'estate_type': ['Studio']},
          ),
          PopupHoverButton(
            route: '/feed',
            label: 'apartment'.tr,
            color: Colors.white,
            filters: {'estate_type': ['Apartment']},
          ),
          // PopupHoverButton(
          //   route: '/feed',
          //   label: 'luxury_apartments'.tr,
          //   color: Colors.white,
          //   filters: {'estate_type': ['Apartment']},
          // ),
          PopupHoverButton(
            route: '/feed',
            label: 'commercial_spaces'.tr,
            color: Colors.white,
            filters: {'estate_type': ['Commercial']},
          ),
          PopupHoverButton(
            route: '/feed',
            label: 'garages'.tr,
            color: Colors.white,
            filters: {'estate_type': ['Garage']},
          ),
        ],
      );
    }

    Widget buildTermsAndSettings() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: footerSpacer,
        children: [
          Text(
            'terms_settings'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          PopupHoverButton(
            route: '/terms-and-policy',
            label: 'privacy_policy'.tr,
            color: Colors.white,
          ),
          PopupHoverButton(
            route: '/terms-and-policy',
            label: 'terms_conditions'.tr,
            color: Colors.white,
          ),
          PopupHoverButton(
            route: '/cookies',
            label: 'cookie_policy'.tr,
            color: Colors.white,
          ),
          PopupHoverButton(
            route: '/agreements',
            label: 'user_agreements'.tr,
            color: Colors.white,
          ),
        ],
      );
    }

    Widget buildAboutUs() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: footerSpacer,
        children: [
          Text(
            'about'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          MouseRegion(
            onEnter: (_) {},
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () => navigateToAboutUs(context),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'about_hously'.tr,
                      style: AppTextStyles.interMedium14.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          MouseRegion(
            onEnter: (_) {},
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () => navigateToAboutUs(context),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'how_we_work'.tr,
                      style: AppTextStyles.interMedium14.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget content;
    if (isTablet) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildNewsletterSection(),
          const SizedBox(height: 60),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: buildNavigationLinks()),
              Expanded(child: buildCategories()),
              Expanded(child: buildTermsAndSettings()),
            ],
          ),
          const SizedBox(height: 60),
          buildAboutUs(),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: buildNewsletterSection()),
          Expanded(child: buildNavigationLinks()),
          Expanded(child: buildCategories()),
          Expanded(child: buildTermsAndSettings()),
          Expanded(child: buildAboutUs()),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color.fromRGBO(19, 19, 19, 1)),
      child: Stack(
        children: [
          Positioned(
            bottom: -10,
            right: 0,
            left: 0,
            height: 200,
            child: Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: Image.asset('assets/images/hously_pro.png'),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isProfile ? 20 : paddingDynamic,
              right: isProfile ? 20 : paddingDynamic,
              top: 50.0,
              bottom: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                SizedBox(height: isTablet ? 80 : 100),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'copyright'.tr,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}