import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portal/screens/landing_page/providers/landing_stats_provider.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/ask_user_widget.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/footer_widget.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    notesController = TextEditingController();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllers = AboutFormControllers(
      formKey: formKey,
      firstNameController: firstNameController,
      lastNameController: lastNameController,
      phoneController: phoneController,
      emailController: emailController,
      notesController: notesController,
    );

    return AboutPagePcView(controllers: controllers);
  }
}

/// Small container for passing controllers around.
/// Keeps AboutPageState clean.
class AboutFormControllers {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController notesController;

  const AboutFormControllers({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
    required this.notesController,
  });
}

/// ---------------------------
/// PC VIEW
/// ---------------------------
class AboutPagePcView extends ConsumerWidget {
  final AboutFormControllers controllers;

  const AboutPagePcView({super.key, required this.controllers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: CustomBackgroundGradients.backgroundGradientRight1(context, ref),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/aboutustop.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha((255 * 0.55).toInt()),
            ),
          ),

          // Main scroll
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const AboutHeroCardPc(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  const AboutStatsSection(),
                  const SizedBox(height: 24),

                  const AboutMissionSectionPc(),
                  const SizedBox(height: 24),

                  const AboutValuesSectionPc(),
                  const SizedBox(height: 24),

                  AboutContactSectionPc(controllers: controllers),
                  const SizedBox(height: 24),

                  // Footer
                  FooterWidget(paddingDynamic: _footerPadding(context)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: IconButton(
              color: theme.buttonBackground,
              onPressed: () {
                ref.read(navigationService).beamPop(context);
              },
              icon:  AppIcons.iosArrowLeft(color: theme.textColor,),
            ),
          )
        ],
      ),
    );
  }
}


class AboutHeroCardPc extends StatelessWidget {
  const AboutHeroCardPc({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "About".tr,
                            style: GoogleFonts.libreCaslonText(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Hously.PRO",
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We provide a revolutionary real estate experience by combining advanced technology with a personalized touch.\n"
                            "Our mission is clear: to make buying, selling, and managing real estate seamless, intelligent, and empowering for everyone involved."
                        .tr,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xffE9E9E9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 2,
                    ),
                    child: Text(
                      "Contact an Agent".tr,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// MOBILE VIEW
/// ---------------------------
class AboutPageMobileView extends ConsumerWidget {
  final AboutFormControllers controllers;

  const AboutPageMobileView({super.key, required this.controllers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BarManager mobile draws topAppBar and bottomBar over content.
    // We pad content to avoid being hidden.
    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 12;
    final bottomPad = MediaQuery.of(context).padding.bottom + 90;

    return Container(
      decoration: BoxDecoration(
        gradient: CustomBackgroundGradients.backgroundGradientRight1(context, ref),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/aboutustop.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha((255 * 0.6).toInt()),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const AboutHeroCardMobile(),
                    const SizedBox(height: 16),
                    const AboutStatsSection(isMobile: true),
                    const SizedBox(height: 16),
                    const AboutMissionSectionMobile(),
                    const SizedBox(height: 16),
                    const AboutValuesSectionMobile(),
                    const SizedBox(height: 16),
                    AboutContactSectionMobile(controllers: controllers),
                    const SizedBox(height: 16),
                    FooterWidget(paddingDynamic: _footerPadding(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutHeroCardMobile extends StatelessWidget {
  const AboutHeroCardMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "About Hously.PRO".tr,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We provide a revolutionary real estate experience by combining advanced technology with a personalized touch.\n"
                        "Our mission is clear: to make buying, selling, and managing real estate seamless, intelligent, and empowering for everyone involved."
                    .tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xffE9E9E9),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 2,
                  ),
                  child: Text(
                    "Contact an Agent".tr,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// SECTIONS (shared/PC/Mobile variants)
/// ---------------------------
class AboutStatsSection extends ConsumerWidget {
  final bool isMobile;

  const AboutStatsSection({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(landingStatsProvider);

    return Container(
      width: double.infinity,
      color: const Color(0xff131313),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 32),
      child: statsAsync.when(
        data: (stats) => isMobile
            ? Column(
                children: [
                  StatItem(number: _fmt(stats.usersCount), text: 'active_users'.tr),
                  const SizedBox(height: 16),
                  StatItem(number: _fmt(stats.advertisementsCount), text: 'advertisements_count'.tr),
                  const SizedBox(height: 16),
                  StatItem(number: _fmt(stats.investmentsCount), text: 'investments'.tr),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatItem(number: _fmt(stats.usersCount), text: 'active_users'.tr),
                  const VerticalDividerLine(),
                  StatItem(number: _fmt(stats.advertisementsCount), text: 'advertisements_count'.tr),
                  const VerticalDividerLine(),
                  StatItem(number: _fmt(stats.investmentsCount), text: 'investments'.tr),
                ],
              ),
        loading: () => isMobile
            ? Column(
                children: [
                  _skeleton('active_users'.tr),
                  const SizedBox(height: 16),
                  _skeleton('advertisements_count'.tr),
                  const SizedBox(height: 16),
                  _skeleton('investments'.tr),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _skeleton('active_users'.tr),
                  const VerticalDividerLine(),
                  _skeleton('advertisements_count'.tr),
                  const VerticalDividerLine(),
                  _skeleton('investments'.tr),
                ],
              ),
        error: (_, __) => isMobile
            ? Column(
                children: [
                  StatItem(number: '-', text: 'active_users'.tr),
                  const SizedBox(height: 16),
                  StatItem(number: '-', text: 'advertisements_count'.tr),
                  const SizedBox(height: 16),
                  StatItem(number: '-', text: 'investments'.tr),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatItem(number: '-', text: 'active_users'.tr),
                  const VerticalDividerLine(),
                  StatItem(number: '-', text: 'advertisements_count'.tr),
                  const VerticalDividerLine(),
                  StatItem(number: '-', text: 'investments'.tr),
                ],
              ),
      ),
    );
  }

  static String _fmt(int value) {
    if (value <= 0) return '0';
    if (value >= 1000000) {
      final f = value / 1000000;
      final s = f.toStringAsFixed(1);
      return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}M+';
    }
    if (value >= 1000) {
      final f = value / 1000;
      final s = f.toStringAsFixed(1);
      return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}K+';
    }
    return '$value+';
  }

  Widget _skeleton(String label) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xffC8C8C8)),
        ),
      ],
    );
  }
}

class AboutMissionSectionPc extends StatelessWidget {
  const AboutMissionSectionPc({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double dynamicPadding = width / 7;

    return Container(
      width: double.infinity,
      color: const Color(0xff131313),
      padding:  EdgeInsets.symmetric(horizontal: dynamicPadding, vertical: 40),
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/aboutusimage.webp',
                  fit: BoxFit.cover,
                  height: 320,
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Our Mission".tr,
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'about_us_description'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xffC8C8C8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 2,
                    ),
                    child: Text(
                      "Contact us".tr,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutMissionSectionMobile extends StatelessWidget {
  const AboutMissionSectionMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xff131313),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/aboutusimage.webp',
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Our Mission".tr,
            style: GoogleFonts.libreCaslonText(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'about_us_description'.tr,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xffC8C8C8),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 2,
              ),
              child: Text(
                "Contact us".tr,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutValuesSectionPc extends StatelessWidget {
  const AboutValuesSectionPc({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xff5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What’s important to us".tr,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'about_us_description'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xffC8C8C8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    BuildValueItem(
                      icon: Icons.people,
                      title: "People".tr,
                      description: "Our goal is to build lasting relationships with clients and agents.".tr,
                    ),
                    BuildValueItem(
                      icon: Icons.handshake,
                      title: "Service".tr,
                      description: "We adopt a mindset of abundance, prioritizing ethics over profits.".tr,
                    ),
                    BuildValueItem(
                      icon: Icons.star,
                      title: "Integrity".tr,
                      description: "The core of every relationship lies in trust, professionalism, and excellence.".tr,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/aboutusimage2.webp',
                    fit: BoxFit.cover,
                    height: 340,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutValuesSectionMobile extends StatelessWidget {
  const AboutValuesSectionMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xff5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What’s important to us".tr,
            style: GoogleFonts.libreCaslonText(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'about_us_description'.tr,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xffC8C8C8),
            ),
          ),
          const SizedBox(height: 14),
          BuildValueItem(
            icon: Icons.people,
            title: "People".tr,
            description: "Our goal is to build lasting relationships with clients and agents.".tr,
          ),
          BuildValueItem(
            icon: Icons.handshake,
            title: "Service".tr,
            description: "We adopt a mindset of abundance, prioritizing ethics over profits.".tr,
          ),
          BuildValueItem(
            icon: Icons.star,
            title: "Integrity".tr,
            description: "The core of every relationship lies in trust, professionalism, and excellence.".tr,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/aboutusimage2.webp',
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// CONTACT SECTIONS
/// ---------------------------
class AboutContactSectionPc extends StatelessWidget {
  final AboutFormControllers controllers;

  const AboutContactSectionPc({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double dynamicPadding = width / 7;
    return Container(
      width: double.infinity,
      color: const Color(0xff131313),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: IntrinsicHeight(
          child: AskUserWidget(paddingDynamic: dynamicPadding)
        ),
      ),
    );
  }
}

class AboutContactSectionMobile extends StatelessWidget {
  final AboutFormControllers controllers;

  const AboutContactSectionMobile({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xff131313),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/aboutusimage3.webp',
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 16),
          AboutContactForm(controllers: controllers),
        ],
      ),
    );
  }
}

class AboutContactForm extends StatelessWidget {
  final AboutFormControllers controllers;

  const AboutContactForm({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controllers.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Let's get in touch.".tr,
            style: GoogleFonts.libreCaslonText(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers.firstNameController,
                  decoration: _inputDecoration('First Name'.tr),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your first name".tr;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controllers.lastNameController,
                  decoration: _inputDecoration('Last Name'.tr),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your last name".tr;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: controllers.phoneController,
            decoration: _inputDecoration('Phone Number'.tr),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your phone number".tr;
              }
              // Keep your original rule, but loosen a bit to avoid false negatives.
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits.length < 9) {
                return "Enter a valid phone number".tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: controllers.emailController,
            decoration: _inputDecoration('Email'.tr),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your email".tr;
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return "Enter a valid email address".tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: controllers.notesController,
            decoration: _notesDecoration("Notes".tr),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your notes".tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final valid = controllers.formKey.currentState?.validate() ?? false;
                if (!valid) return;

                final phone = controllers.phoneController.text.trim();
                final notes = controllers.notesController.text.trim();
                final description = [
                  if (phone.isNotEmpty) 'Phone: $phone',
                  if (notes.isNotEmpty) notes,
                ].join('\n');

                try {
                  final resp = await ApiServices.post(
                    URLs.appendBaseUrl('/feedback/contact/'),
                    data: {
                      'first_name': controllers.firstNameController.text.trim(),
                      'last_name': controllers.lastNameController.text.trim(),
                      'email': controllers.emailController.text.trim(),
                      'title': 'Contact form from About Us page',
                      'description': description.isNotEmpty ? description : 'No message.',
                    },
                  );
                  if (!context.mounted) return;
                  if (resp != null && resp.statusCode != null && resp.statusCode! < 300) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('message_sent_successfully'.tr)),
                    );
                    controllers.formKey.currentState?.reset();
                    controllers.firstNameController.clear();
                    controllers.lastNameController.clear();
                    controllers.phoneController.clear();
                    controllers.emailController.clear();
                    controllers.notesController.clear();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('something_went_wrong'.tr)),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 2,
              ),
              child: Text(
                "Submit".tr,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// SMALL WIDGETS / HELPERS
/// ---------------------------
InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 11, color: Color(0xFFC8C8C8)),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}

InputDecoration _notesDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 11, color: Color(0xFFC8C8C8)),
    filled: true,
    fillColor: Colors.white,
    alignLabelWithHint: true,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}

double _footerPadding(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w < 600) return 16;
  if (w < 1100) return 24;
  return 40;
}

class StatItem extends StatelessWidget {
  final String number;
  final String text;

  const StatItem({
    super.key,
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text.tr,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xffC8C8C8),
          ),
        ),
      ],
    );
  }
}

/// Renamed to avoid collision with Flutter's Divider widget.
class VerticalDividerLine extends StatelessWidget {
  const VerticalDividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 2,
      color: Colors.white24,
    );
  }
}

class BuildValueItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const BuildValueItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xffC8C8C8),
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
