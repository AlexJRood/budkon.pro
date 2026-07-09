import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filter_landing_page/components/filters_components.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/font_size.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';

import 'package:core/common/custom_error_handler.dart';
import '../../providers/news_letter_provider.dart';

class FooterWidgetMobile extends ConsumerStatefulWidget {
  final double paddingDynamic;
  final bool isMobile;

  const FooterWidgetMobile({
    super.key,
    required this.paddingDynamic,
    this.isMobile = false,
  });

  @override
  ConsumerState<FooterWidgetMobile> createState() => _FooterWidgetMobileState();
}

class _FooterWidgetMobileState extends ConsumerState<FooterWidgetMobile> {
  late final FocusNode _emailFocusNode;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();

    _emailFocusNode = FocusNode();

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _scrollEmailIntoView();
      }
    });
  }

  void _scrollEmailIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_emailFocusNode.hasFocus) return;

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || !_emailFocusNode.hasFocus) return;

      await Scrollable.ensureVisible(
        _emailFocusNode.context!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
    });
  }
  void _unfocusEmailField() {
    if (_emailFocusNode.hasFocus) {
      _emailFocusNode.unfocus();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    super.dispose();
  }
  Future<void> _submitNewsletter() async {
    _unfocusEmailField();

    final newsletterNotifier = ref.read(newsletterProvider.notifier);
    final emailController = newsletterNotifier.emailController;
    final email = emailController.text.trim();
    final customSnackBar = Customsnackbar();

      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          customSnackBar.showSnackBar(
            'invalid_email_title'.tr,
            'enter_email_message'.tr,
            'warning',
            null,
          ),
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
              ScaffoldMessenger.of(context)
                  .hideCurrentSnackBar();
            },
          ),
        );
        return;
      }
      try {
        await newsletterNotifier
            .subscribeToNewsletter(
          email: email,
          source: 'landing_page',
          language: Localizations.localeOf(context)
              .languageCode,
        );

        final currentState =
        ref.read(newsletterProvider);

        if (!currentState.isLoading &&
            currentState.hasValue) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            customSnackBar.showSnackBar(
              'success_title'.tr,
              'newsletter_success'.tr,
              'success',
                  () {
                ScaffoldMessenger.of(context)
                    .hideCurrentSnackBar();
              },
            ),
          );
          emailController.clear();
        } else if (currentState.hasError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            customSnackBar.showSnackBar(
              'subscription_failed_title'.tr,
              'subscription_failed_message'.tr,
              'error',
                  () {
                ScaffoldMessenger.of(context)
                    .hideCurrentSnackBar();
              },
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          customSnackBar.showSnackBar(
            'generic_error_title'.tr,
            'generic_error_message'.tr,
            'error',
                () {
              ScaffoldMessenger.of(context)
                  .hideCurrentSnackBar();
            },
          ),
        );
      }
  }
  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final fontSize = ref.watch(fontSizeProvider(context));
    final newsletterState = ref.watch(newsletterProvider);
    final newsletterNotifier = ref.read(newsletterProvider.notifier);
    final emailController = newsletterNotifier.emailController;

    return Container(
      height: widget.isMobile ? 800 : 500,
      width: double.infinity,
      decoration: BoxDecoration(color: theme.textFieldColor),
      child: Stack(
        children: [
          Positioned(
            bottom: widget.isMobile ? 50 : -10,
            right: 0,
            left: 0,
            height: fontSize.logoSize(50, 170),
            child: Center(
              child: Text(
                'HOUSLY.PRO',
                style: AppTextStyles.houslyAiLogo30.copyWith(
                  color: theme.textColor.withAlpha((255 * 0.3).toInt()),
                  fontSize: fontSize.logoSize(50, 170),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.paddingDynamic,
              vertical: widget.isMobile ? 20 : 50.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                widget.isMobile
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HOUSLY.PRO',
                      style: AppTextStyles.houslyAiLogo24.copyWith(
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'subscribe_newsletter'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textColor.withAlpha(
                          (255 * 0.7).toInt(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      width: 345,
                      child: TextFormField(
                        controller: emailController,
                        focusNode: _emailFocusNode,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        scrollPadding: EdgeInsets.only(
                          left: 20,
                          top: 20,
                          right: 20,
                          bottom:
                          MediaQuery.of(context).viewInsets.bottom +
                              BottomBarSize.resolve(context) +
                              80,
                        ),
                        onFieldSubmitted: (_) async {
                          final email = emailController.text.trim();

                          if (email.isEmpty) {
                            _emailFocusNode.unfocus();
                            FocusScope.of(context).unfocus();
                            return;
                          }

                          await _submitNewsletter();
                        },
                        onTap: () {
                          if (_emailFocusNode.hasFocus) {
                            _scrollEmailIntoView();
                          }
                        },
                        decoration: InputDecoration(
                          suffixIcon: InkWell(
                            onTap: () async {
                              _unfocusEmailField();
                              await _submitNewsletter();
                            },
                            child: newsletterState.isLoading
                                ? Transform.scale(
                              scale: 0.5,
                              child: CircularProgressIndicator(
                                color: theme.textColor,
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(
                              Icons.arrow_forward,
                              color:
                              Color.fromRGBO(145, 145, 145, 1),
                            ),
                          ),
                          filled: true,
                          hintText: 'Email'.tr,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(color: theme.textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide:
                            BorderSide(color: theme.textColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide:
                            BorderSide(color: theme.textColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide:
                            BorderSide(color: theme.textColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'email_required'.tr;
                          }
                          if (!GetUtils.isEmail(value)) {
                            return 'invalid_email'.tr;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                isChecked = value;
                              });
                            }
                          },
                          checkColor: theme.textColor,
                          activeColor: theme.themeColor,
                        ),
                        Expanded(
                          child: Text(
                            'agree_terms'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(
                                (255 * 0.7).toInt(),
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 420,
                      child: SingleChildScrollView(
                        primary: false,
                        child: Column(
                          children: [
                            _buildExpansionButtons(
                              context,
                              ref,
                              'navigation_links'.tr,
                              id: 'navigation',
                              [
                                NavItem(
                                  'buy'.tr,
                                  '/feed',
                                  filters: {'offer_type': 'buy'},
                                ),
                                NavItem(
                                  'sell'.tr,
                                  '/feed',
                                  filters: {'offer_type': 'sell'},
                                ),
                                NavItem(
                                  'rent'.tr,
                                  '/feed',
                                  filters: {'offer_type': 'rent'},
                                ),
                              ],
                            ),
                            _buildExpansionButtons(
                              context,
                              ref,
                              'categories'.tr,
                              id: 'categories',
                              [
                                NavItem(
                                  'flat'.tr,
                                  '/feed',
                                  filters: {
                                    'estate_type': ['Flat'],
                                  },
                                ),
                                NavItem(
                                  'studio_apartment'.tr,
                                  '/feed',
                                  filters: {
                                    'estate_type': ['Studio'],
                                  },
                                ),
                                NavItem(
                                  'apartment'.tr,
                                  '/feed',
                                  filters: {
                                    'estate_type': ['Apartment'],
                                  },
                                ),
                                NavItem(
                                  'Lot'.tr,
                                  '/feed',
                                  filters: {
                                    'estate_type': ['Lot'],
                                  },
                                ),
                                NavItem(
                                  'commercial_spaces'.tr,
                                  '/feed',
                                  filters: {
                                    'estate_type': ['Commercial'],
                                  },
                                ),
                                NavItem(
                                  'garages'.tr,
                                  '/feed',
                                  filters: {
                                    'estate_type': ['Garage'],
                                  },
                                ),
                              ],
                            ),
                            _buildExpansionButtons(
                              context,
                              ref,
                              'terms_settings'.tr,
                              id: 'terms',
                              [
                                NavItem(
                                  'privacy_policy'.tr,
                                  '/terms-and-policy',
                                ),
                                NavItem(
                                  'terms_conditions'.tr,
                                  '/terms-and-policy',
                                ),
                                NavItem('cookie_policy'.tr, '/cookies'),
                                NavItem(
                                  'user_agreements'.tr,
                                  '/user-agreements',
                                ),
                              ],
                            ),
                            _buildExpansionButtons(
                              context,
                              ref,
                              'About',
                              id: 'about',
                              [
                                NavItem('about_hously'.tr, '/about'),
                                NavItem(
                                  'how_we_work'.tr,
                                  '/how-we-work',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOUSLY.PRO',
                            style: AppTextStyles.houslyAiLogo24.copyWith(
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'subscribe_newsletter'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textColor.withAlpha(
                                (255 * 0.7).toInt(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            width: 345,
                            child: TextFormField(
                              controller: emailController,
                              focusNode: _emailFocusNode,
                              style:
                              const TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              scrollPadding: EdgeInsets.only(
                                left: 20,
                                top: 20,
                                right: 20,
                                bottom: MediaQuery.of(context)
                                    .viewInsets
                                    .bottom +
                                    BottomBarSize.resolve(context) +
                                    80,
                              ),
                              onFieldSubmitted: (_) async {
                                final email = emailController.text.trim();

                                if (email.isEmpty) {
                                  _emailFocusNode.unfocus();
                                  FocusScope.of(context).unfocus();
                                  return;
                                }

                                await _submitNewsletter();
                              },
                              onTap: () {
                                if (_emailFocusNode.hasFocus) {
                                  _scrollEmailIntoView();
                                }
                              },
                              decoration: InputDecoration(
                                suffixIcon: InkWell(
                                  onTap: () async {
                                    _unfocusEmailField();
                                    await _submitNewsletter();
                                  },
                                  child: newsletterState.isLoading
                                      ? Transform.scale(
                                    scale: 0.5,
                                    child:
                                    CircularProgressIndicator(
                                      color: theme.textColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Icon(
                                    Icons.arrow_forward,
                                    color: Color.fromRGBO(
                                      145,
                                      145,
                                      145,
                                      1,
                                    ),
                                  ),
                                ),
                                filled: true,
                                hintText: 'Email'.tr,
                                fillColor: Colors.transparent,
                                hintStyle:
                                TextStyle(color: theme.textColor),
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(6.0),
                                  borderSide:
                                  BorderSide(color: theme.textColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(6.0),
                                  borderSide:
                                  BorderSide(color: theme.textColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(6.0),
                                  borderSide:
                                  BorderSide(color: theme.textColor),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'email_required'.tr;
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'invalid_email'.tr;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      isChecked = value;
                                    });
                                  }
                                },
                                checkColor: theme.textColor,
                                activeColor: theme.themeColor,
                              ),
                              Expanded(
                                child: Text(
                                  'agree_terms'.tr,
                                  style: TextStyle(
                                    color: theme.textColor.withAlpha(
                                      (255 * 0.7).toInt(),
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    _buildButtons(context, ref, 'navigation_links'.tr, [
                      NavItem(
                        'buy'.tr,
                        '/feed',
                        filters: {'offer_type': 'buy'},
                      ),
                      NavItem(
                        'sell'.tr,
                        '/feed',
                        filters: {'offer_type': 'sell'},
                      ),
                      NavItem(
                        'rent'.tr,
                        '/feed',
                        filters: {'offer_type': 'rent'},
                      ),
                    ]),
                    _buildButtons(context, ref, 'categories'.tr, [
                      NavItem(
                        'flat'.tr,
                        '/feed',
                        filters: {
                          'estate_type': ['Flat'],
                        },
                      ),
                      NavItem(
                        'studio_apartment'.tr,
                        '/feed',
                        filters: {
                          'estate_type': ['Studio'],
                        },
                      ),
                      NavItem(
                        'apartment'.tr,
                        '/feed',
                        filters: {
                          'estate_type': ['Apartment'],
                        },
                      ),
                      NavItem(
                        'Lot'.tr,
                        '/fed',
                        filters: {
                          'estate_type': ['Lot'],
                        },
                      ),
                      NavItem(
                        'commercial_spaces'.tr,
                        '/feed',
                        filters: {
                          'estate_type': ['Commercial'],
                        },
                      ),
                      NavItem(
                        'garages'.tr,
                        '/feed',
                        filters: {
                          'estate_type': ['Garage'],
                        },
                      ),
                    ]),
                    _buildButtons(context, ref, 'terms_settings'.tr, [
                      NavItem(
                        'privacy_policy'.tr,
                        '/terms-and-policy',
                      ),
                      NavItem(
                        'terms_conditions'.tr,
                        '/terms-and-policy',
                      ),
                      NavItem('cookie_policy'.tr, '/cookies'),
                      NavItem('user_agreements'.tr, '/agreements'),
                    ]),
                    _buildButtons(context, ref, 'About', [
                      NavItem('about_hously'.tr, '/about'),
                      NavItem('how_we_work'.tr, '/how-we-work'),
                    ]),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'copyright'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textColor.withAlpha((255 * 0.7).toInt()),
                    ),
                  ),
                ),
                if (widget.isMobile)
                  SizedBox(height: BottomBarSize.resolve(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(
      BuildContext context,
      WidgetRef ref,
      String title,
      List<NavItem> items, {
        double spacing = 14,
      }) {
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.read(navigationService);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            SizedBox(height: spacing),
            ...items.map((item) {
              return SizedBox(
                height: 30,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (item.filters != null) {
                      ref.read(filterCacheProvider.notifier).clearFilters();
                      ref.read(filterButtonProvider.notifier).clearUiFilters();

                      item.filters!.forEach((key, value) {
                        ref
                            .read(filterButtonProvider.notifier)
                            .updateFilter(key, value);

                        ref.read(filterCacheProvider.notifier).addFilter(
                          key,
                          value is List
                              ? value.join(',')
                              : value.toString(),
                        );
                      });
                    }

                    nav.pushNamedScreen(item.route);
                  },
                  style: elevatedButtonStyleRounded10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        item.label.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(
                            (255 * 0.7).toInt(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionButtons(
      BuildContext context,
      WidgetRef ref,
      String title,
      List<NavItem> items, {
        required String id,
      }) {
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.read(navigationService);

    return ExpansionTile(
      iconColor: theme.textColor,
      collapsedIconColor: theme.textColor,
      key: PageStorageKey<String>('footer_expansion_$id'),
      title: Text(
        title.tr,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      children: items.map((item) {
        return SizedBox(
          height: 40,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (item.filters != null) {
                ref.read(filterCacheProvider.notifier).clearFilters();
                ref.read(filterButtonProvider.notifier).clearUiFilters();

                item.filters!.forEach((key, value) {
                  ref
                      .read(filterButtonProvider.notifier)
                      .updateFilter(key, value);

                  ref.read(filterCacheProvider.notifier).addFilter(
                    key,
                    value is List ? value.join(',') : value.toString(),
                  );
                });
              }

              nav.pushNamedScreen(item.route);
            },
            style: elevatedButtonStyleRounded10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                Text(
                  item.label.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha((255 * 0.7).toInt()),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class NavItem {
  final String label;
  final String route;
  final Map<String, dynamic>? filters;

  NavItem(this.label, this.route, {this.filters});
}