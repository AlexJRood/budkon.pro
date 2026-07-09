// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';

// Updated ButtonOption class with imageUrl
class ButtonOptionType {
  final String label;
  final String value;
  final String imageUrl;

  ButtonOptionType(this.label, this.value, this.imageUrl);
}

class TypeSelectorWidget extends ConsumerStatefulWidget {
  final String labelText;
  final bool isMobile;

  TypeSelectorWidget({Key? key, required this.labelText, this.isMobile = false})
    : super(key: key);

  @override
  ConsumerState<TypeSelectorWidget> createState() => _TypeSelectorWidgetState();
}

class _TypeSelectorWidgetState extends ConsumerState<TypeSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 1920;
    final addOfferStateNotifier = ref.watch(addOfferProvider.notifier);
    final addOfferState = ref.watch(addOfferProvider);
    final controller = addOfferState.offerTypeController;
    final theme = ref.read(themeColorsProvider);
    final selectedTextColor = Colors.blue;
    final unselectedTextColor = CustomColors.secondaryWidgetTextColor(
      context,
      ref,
    ).withAlpha(204);

    final boxHeight = widget.isMobile ? 150.0 : (isWideScreen ? 240.0 : 200.0);
    final imageWidth = isWideScreen ? 200.0 : 180.0;
    final imageHeight = isWideScreen ? 130.0 : 100.0;

    final option1 = ButtonOptionType(
      "I will sale".tr,
      "sale",
      "assets/images/salesign.png",
    );
    final option2 = ButtonOptionType(
      "I will rent".tr,
      "rent",
      "assets/images/report_house.png",
    );

    Widget buildOption(ButtonOptionType option) {
      final isSelected = controller.text == option.value;
      if (widget.isMobile) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0, right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  controller.text = option.value;
                });
                addOfferStateNotifier.updateField('offerType', option.value);
                log(option.value);
              },
              child: Container(
                height: boxHeight,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? selectedTextColor.withAlpha(76)
                          : CustomColors.secondaryWidgetColor(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : unselectedTextColor,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          isSelected ? Colors.blueAccent : unselectedTextColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isSelected
                                  ? selectedTextColor
                                  : unselectedTextColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      option.imageUrl,
                      height: imageHeight,
                      width: imageWidth,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 60,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0, right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  controller.text = option.value;
                });
                addOfferStateNotifier.updateField('offerType'.tr, option.value);
                log(option.value);
              },
              child: Container(
                height: boxHeight,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? selectedTextColor.withAlpha(76)
                          : CustomColors.secondaryWidgetColor(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : unselectedTextColor,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          option.imageUrl,
                          height: imageHeight,
                          width: imageWidth,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          option.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isSelected
                                    ? selectedTextColor
                                    : unselectedTextColor,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            isSelected
                                ? Colors.blueAccent
                                : unselectedTextColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isMobile
            ? Column(
              children: [
                Row(children: [buildOption(option1)]),
                Row(children: [buildOption(option2)]),
              ],
            )
            : Row(
              children: [
                buildOption(option1),
                buildOption(option2),
                if (MediaQuery.of(context).size.width >= 2000) ...[
                  const Expanded(child: SizedBox(width: 10)),
                ],
              ],
            ),
      ],
    );
  }
}
