import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portal/screens/landing_page/providers/landing_stats_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';

class AboutPageMobile extends ConsumerStatefulWidget {
  const AboutPageMobile({super.key});

  @override
  _AboutPageMobileState createState() => _AboutPageMobileState();
}

class _AboutPageMobileState extends ConsumerState<AboutPageMobile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;
  bool _isChecked = false;


  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = ref.watch(themeColorsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: TopAppBarSize.resolve(context),),
          SizedBox(
            height: 810,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: OptimizedAssetImage(
                    path:'assets/images/aboutustop.webp',
                    width: screenWidth,
                  ),
                ),

                // 2) Dark Overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withAlpha((255 * 0.5).toInt()),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    // Constrain the width for better readability on larger screens
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Big heading
                          Row(
                            spacing: 5,
                            children: [
                              Text(
                                "About".tr,
                                style: GoogleFonts.libreCaslonText(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Hously.PRO",
                                style: GoogleFonts.inter(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Text(
                            "We provide a revolutionary real estate experience by combining advanced technology with a personalized touch.Our mission is clear: to make buying, selling, and managing real estate seamless, intelligent, and empowering for everyone involved.".tr,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xffE9E9E9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // "Contact an Agent".tr button
                          SizedBox(
                            height: 44,
                            width: MediaQuery.of(context).size.width * .5,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                "Contact an Agent".tr,
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xff131313),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1) Statistics in a Row
                    const _StatsColumn(),
                    const SizedBox(height: 20),

                    // 2) “Our Mission” Section (Image on left, Text on right)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OptimizedAssetImage(
                          path: 'assets/images/aboutusimage.webp',
                          width: screenWidth,
                          height: 260,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(width: 40),
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                // vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              "Contact us".tr,
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 720,
                color: const Color(0xff212020),
                padding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Top Image
                          OptimizedAssetImage(
                            path: 'assets/images/aboutusimage2.webp',
                            width: screenWidth,
                            height: 240,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            "What’s important to us".tr,
                            style: GoogleFonts.libreCaslonText(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Paragraph
                          Text(
                            "We are a passionate team dedicated to creating meaningful experiences through innovative design and technology. Our mission is to connect people, inspire creativity, and empower communities.".tr,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xff919191),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Value Items
                          BuildValueItem(
                            icon: Icons.people,
                            title: "People".tr,
                            description: "Our goal is to build lasting relationships with clients and agents.".tr,
                          ),
                          const Divider2(),
                          const SizedBox(height: 10),

                          BuildValueItem(
                            icon: Icons.handshake,
                            title: "Service".tr,
                            description: "We adopt a mindset of abundance, prioritizing ethics over profits.".tr,
                          ),
                          const Divider2(),
                          const SizedBox(height: 10),
                          BuildValueItem(
                            icon: Icons.star,
                            title: "Integrity".tr,
                            description: "The core of every relationship lies in trust, professionalism, and excellence.".tr,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 750,
                width: double.infinity,
                color: const Color(0xff131313),
                child: Stack(
                  children: [
                    /// 1) Background image
                    Positioned.fill(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 500,
                      child: OptimizedAssetImage(
                        path: 'assets/images/aboutusimage3.webp',
                        width: screenWidth,
                        height: 250,
                      ),
                    ),

                    /// 2) Foreground container (the form) with rounded top corners
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      top: 200,
                      child: Container(
                        // Adjust this height as needed
                        height: 530,
                        decoration: const BoxDecoration(
                          color: Color(0xff131313),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              // In case content exceeds the container height
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Let's get in touch.".tr,
                                    style: GoogleFonts.libreCaslonText(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _firstNameController,
                                    decoration:
                                    _inputDecoration('First Name'.tr,theme),
                                    style:
                                    const TextStyle(color: Colors.black),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your first name".tr;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _lastNameController,
                                    decoration: _inputDecoration('Last Name'.tr,theme),
                                    style:
                                    const TextStyle(color: Colors.black),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your last name".tr;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration:
                                    _inputDecoration('Phone Number'.tr,theme),
                                    style:
                                    const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your phone number".tr;
                                      }
                                      if (!RegExp(r'^\d{10}$')
                                          .hasMatch(value)) {
                                        return "Enter a valid 10-digit phone number".tr;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: _inputDecoration('Email'.tr,theme),
                                    style:
                                    const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your email".tr;
                                      }
                                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                          .hasMatch(value)) {
                                        return "Enter a valid email address".tr;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _notesController,
                                    decoration: InputDecoration(
                                      labelText: "Notes".tr,
                                      labelStyle: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFC8C8C8),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                            color: Colors.red, width: 2),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                            color: Colors.red, width: 2),
                                      ),
                                      floatingLabelBehavior:
                                      FloatingLabelBehavior.auto,
                                      alignLabelWithHint: true,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                            color: Colors.white, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                            color: Colors.blue, width: 2),
                                      ),
                                    ),
                                    style:
                                    const TextStyle(color: Colors.black),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your notes".tr;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .5,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!
                                            .validate()) {
                                          // All fields are valid, proceed with submission
                                          debugPrint(
                                              "Form submitted successfully!".tr);
                                          // Add your submission logic here
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(6),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        "Submit".tr,
                                        style: GoogleFonts.inter(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The main container for your footer
                    Container(
                      // Set a height if you want a fixed footer area
                      height: 1000,
                      width: double.infinity,
                      color: Colors.grey[900],
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 1) Top Row: the four columns side by side
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FooterColumn(
                                title: "Navigation Links".tr,
                                items: [
                                  "Buy".tr,
                                  "Rent".tr,
                                  "Sell".tr,
                                  "Invest".tr,
                                  "Build".tr,
                                  "Recommended deals".tr,
                                ],
                                onItemTap: (item) {
                                  // Handle tap for the item here
                                  if (kDebugMode) print("Tapped on $item");
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              FooterColumn(
                                title: "Categories".tr,
                                items: [
                                  "Flat".tr,
                                  "Studio apartment".tr,
                                  "Flat".tr,
                                  "Vacation homes".tr,
                                  "Commercial spaces".tr,
                                  "Luxury apartments".tr,
                                  "Garaże".tr,
                                ],
                                onItemTap: (item) {
                                  // Handle tap for the item here
                                  if (kDebugMode) print("Tapped on $item");
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              FooterColumn(
                                title: "Terms and settings".tr,
                                items:  [
                                  "Privacy Policy".tr,
                                  "Terms and conditions".tr,
                                  "Cookie Policy".tr,
                                  "User Agreements".tr,
                                ],
                                onItemTap: (item) {
                                  // Handle tap for the item here
                                  if (kDebugMode) print("Tapped on $item");
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              FooterColumn(
                                title: "About".tr,
                                items: [
                                  "About Hously".tr,
                                  "How we work".tr,
                                  "Careers".tr, // Example extra link
                                ],
                                onItemTap: (item) {
                                  // Handle tap for the item here
                                  if (kDebugMode) print("Tapped on $item");
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// 2) Brand & Newsletter Section
                          Text(
                            "HOUSLY.PRO",
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Subscribe to our newsletter for the latest recommendations, and news.".tr,
                            style: GoogleFonts.inter(
                                color: const Color(0xffE9E9E9),
                                fontSize: 14,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 10),

                          // Email TextField with arrow suffix
                          SizedBox(
                            height: 40,
                            width: MediaQuery.of(context)
                                .size
                                .width, // Adjust to your needs
                            child: TextField(
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: "Email".tr,
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xff919191),
                                  fontWeight: FontWeight.w300,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: Color(0xff5A5A5A),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: Color(0xff5A5A5A),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: Color(0xff5A5A5A),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    // Handle subscribe action
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(2.0),
                                    decoration: const BoxDecoration(
                                      color: Color(0xff2F2F2F),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(6),
                                        bottomRight: Radius.circular(6),
                                      ),
                                    ),
                                    child: AppIcons.simpleArrowForward(color: Colors.white,),
                                  ),
                                ),
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 48,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Checkbox
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // The checkbox on the far left
                              Checkbox(
                                value: _isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isChecked = value ?? false;
                                  });
                                },
                              ),

                              // The text on the far right, wrapped by Expanded to avoid overflow
                              Expanded(
                                child: Text(
                                  "I agree with our Terms of Service, Privacy Policy and our default Notification Settings.".tr,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          /// 3) Footer / Copyright
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: OptimizedAssetImage(
                                    path: 'assets/images/aboutusbottom.png',
                                    width: screenWidth,
                                    height: 40,
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "Copyright © 2024 Hously.",
                                        style: TextStyle(
                                          color: Color(0xffE9E9E9),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "All rights reserved. Icons by Icons8".tr,
                                        style: TextStyle(
                                          color: Color(0xffE9E9E9),
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// 4) Bottom Wave/Shape
                    Positioned(
                      // Adjust these values to match exactly how you want it to appear
                      bottom: -27,
                      left: 250,
                      right: 250,
                      child: OptimizedAssetImage(
                        path:  'assets/images/aboutusbottom.png',
                        width: screenWidth ,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: BottomBarSize.resolve(context),)
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label,ThemeColors theme) {
    return InputDecoration(
      label: Text(label,style: TextStyle(color: theme.textColor),),
      labelStyle: const TextStyle(fontSize: 11, color: Color(0xFFC8C8C8)),
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
}

class _StatsColumn extends ConsumerWidget {
  const _StatsColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(landingStatsProvider);

    return statsAsync.when(
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatItem(number: _fmt(stats.usersCount), label: 'active_users'.tr),
          const DividerWidget(),
          const SizedBox(height: 7),
          StatItem(number: _fmt(stats.advertisementsCount), label: 'advertisements_count'.tr),
          const DividerWidget(),
          const SizedBox(height: 7),
          StatItem(number: _fmt(stats.investmentsCount), label: 'investments'.tr),
        ],
      ),
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeleton('active_users'.tr),
          const DividerWidget(),
          const SizedBox(height: 7),
          _skeleton('advertisements_count'.tr),
          const DividerWidget(),
          const SizedBox(height: 7),
          _skeleton('investments'.tr),
        ],
      ),
      error: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatItem(number: '-', label: 'active_users'.tr),
          const DividerWidget(),
          const SizedBox(height: 7),
          StatItem(number: '-', label: 'advertisements_count'.tr),
          const DividerWidget(),
          const SizedBox(height: 7),
          StatItem(number: '-', label: 'investments'.tr),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xffC8C8C8))),
        const SizedBox(height: 8),
      ],
    );
  }
}

class OptimizedAssetImage extends StatelessWidget {
  final String path;
  final double width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const OptimizedAssetImage({
    super.key,
    required this.path,
    required this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (width * dpr).round();

    Widget image = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return RepaintBoundary(
      child: ClipRect(
        child: image,
      ),
    );
  }
}
class FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onItemTap;

  const FooterColumn({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        for (var item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () => onItemTap(item),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  color: const Color(0xffE9E9E9),
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ButtonTextRowAboutUs extends StatelessWidget {
  const ButtonTextRowAboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 8),
          TextButtonWidget(label: "BUY".tr, onPressed: () {}),
          TextButtonWidget(label: "RENT".tr, onPressed: () {}),
          TextButtonWidget(label: "SELL".tr, onPressed: () {}),
          TextButtonWidget(label: "INVEST".tr, onPressed: () {}),
          TextButtonWidget(label: "BUILD".tr, onPressed: () {}),
        ],
      ),
    );
  }
}

class TextButtonWidget extends StatelessWidget {
  final String label;
  final void Function()? onPressed;

  const TextButtonWidget({
    required this.label,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0.0, right: 0.0),
      child: MouseRegion(
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          child: TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.white
                        .withAlpha((255 * 0.4).toInt()); // White shade on hover
                  }
                  return Colors.transparent; // Default transparent background
                },
              ),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white, // Text remains white
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String number;
  final String label;

  const StatItem({
    required this.number,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xffC8C8C8),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
} // Divider Widget

class DividerWidget extends StatelessWidget {
  const DividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 1,
      color: const Color(0xff5A5A5A),
    );
  }
}

class Divider2 extends StatelessWidget {
  const Divider2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 1,
      color: const Color(0xffFFFFFF),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
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