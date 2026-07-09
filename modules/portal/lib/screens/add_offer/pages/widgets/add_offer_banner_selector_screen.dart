import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/common/drad_scroll_widget.dart';

class BannerSelectorScreen extends ConsumerStatefulWidget {
  final bool isMobile;
  const BannerSelectorScreen({super.key, this.isMobile = false});

  @override
  ConsumerState<BannerSelectorScreen> createState() =>
      _BannerSelectorScreenState();
}

class _BannerSelectorScreenState extends ConsumerState<BannerSelectorScreen> {

  int selectedBannerIndex = 0;
  String selectedSize = '1000×2000';
  Color selectedColor = Colors.white;
  bool addDescription = true;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final addOfferState = ref.watch(addOfferProvider);
    double mobilepadding =
        MediaQuery.of(context).size.width <= 500
            ? 15
            : MediaQuery.of(context).size.width / 8;
    double dynamicPadding =
        widget.isMobile ? mobilepadding : MediaQuery.of(context).size.width / 7;

   

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(widget.isMobile)...[SizedBox(height: 110,)],
                const SizedBox(height: 10),
                Text(
                  'Select a banner'.tr,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 20 : 23,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryBackgroundTextColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Select banner to reach more buyers faster and sell your property with ease!'.tr,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 14 : 16,
                    color: theme.primaryBackgroundTextColor,
                  ),
                ),
                const SizedBox(height: 50),

                // Banner Options
                DragScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: 160,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder:
                          (_, index) => GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedBannerIndex = index;
                              });
                            },
                            child: Container(
                              width: 270,
                              height: 130,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      selectedBannerIndex == index
                                          ? Colors.blue
                                          : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                gradient:
                                    CustomBackgroundGradients.textFieldGradient(
                                      context,
                                      ref,
                                    ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'HOUSLY',
                                                  style: TextStyle(
                                                    color:
                                                        theme
                                                            .primaryBackgroundTextColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'text,text,text,text,text,\ntext,text,text,text,text,\ntext,text,text,text,text,\ntext,text,text,text,text',
                                                  style: TextStyle(
                                                    color:
                                                        theme
                                                            .primaryBackgroundTextColor,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.qr_code, size: 50),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
                                        child: Text(
                                          '+48 xxx xxx xxx',
                                          style: TextStyle(
                                            color:
                                                theme
                                                    .primaryBackgroundTextColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: -18,
                                    right: 10,
                                    child: Text(
                                      '𝗛𝗢𝗨𝗦𝗟𝗬',
                                      style: TextStyle(
                                        color: theme.primaryBackgroundTextColor
                                            .withAlpha(51),
                                        fontSize: 35,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Select Size
                Text("Select Size".tr, style: labelStyle(theme)),
                const SizedBox(height: 10),
                sizeOption("1000×2000", theme),
                sizeOption("2000×4000", theme),
                sizeOption("4000×6000", theme),

                const SizedBox(height: 20),

                // Select Color
                Text("Select Color".tr, style: labelStyle(theme)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    colorOption(Colors.white),
                    colorOption(Colors.red),
                    colorOption(Colors.black),
                    colorOption(const Color(0xFF0A1A22)),
                  ],
                ),

                const SizedBox(height: 30),

                // Complete Form
                Text("Complete Form".tr, style: labelStyle(theme)),
                const SizedBox(height: 10),
                GradientTextField(
                  isPhoneField: true,
                  focusNode: FocusNode(),
                  reqNode: FocusNode(),
                  countryCodeController: TextEditingController(text: '+91'),
                  countryCodeHint: "",
                  hintText: "Phone".tr,
                  controller: TextEditingController(),
                ),

                const SizedBox(height: 10),

                // Description
                GradientTextField(
                  maxLines: 5,
                  focusNode: FocusNode(),
                  reqNode: FocusNode(),
                  hintText: "Description".tr,
                  controller: TextEditingController(),
                ),

                const SizedBox(height: 10),

                // Add Description Toggle
                Row(
                  children: [
                    Text("Add Description".tr, style: labelStyle(theme)),
                    if (widget.isMobile == false) const SizedBox(width: 10),
                    if (widget.isMobile) Spacer(),
                    Switch(
                      value: addDescription,
                      onChanged: (value) {
                        setState(() => addDescription = value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ref
                            .read(addOfferProvider.notifier)
                            .sendData(context, ref);
                      },
                      child: Text(
                        'Skip Banner'.tr,
                        style: TextStyle(
                          color: theme.primaryBackgroundTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 250,
                      child: SettingsButton(
                        isPc: true,
                        buttonheight: 50,
                        onTap: () {
                        
                          // You can use the state variables here
                          ref
                              .read(addOfferProvider.notifier)
                              .sendData(context, ref);
                        },
                        text: 'Continue'.tr,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
  }



  TextStyle labelStyle(ThemeColors theme) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: theme.primaryBackgroundTextColor,
  );

  Widget sizeOption(String label, ThemeColors theme) {
    final selected = selectedSize == label;
    return InkWell(
      onTap: () => setState(() => selectedSize = label),
      child: Row(
        children: [
          Radio<String>(
            fillColor: WidgetStatePropertyAll(theme.primaryBackgroundTextColor),
            value: label,
            groupValue: selectedSize,
            onChanged: (val) => setState(() => selectedSize = val!),
          ),
          Text(label, style: labelStyle(theme)),
        ],
      ),
    );
  }

  Widget colorOption(Color color) {
    final isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
