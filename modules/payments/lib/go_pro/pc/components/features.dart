import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/apptheme.dart';

import 'package:get/get_utils/get_utils.dart';

class FeaturesWidget extends ConsumerWidget {
  final void Function()? onstandardpressed;
  final void Function()? onpremiumpressed;
  final void Function()? ongoldpressed;
  const FeaturesWidget(
      {super.key,
      required this.ongoldpressed,
      required this.onpremiumpressed,
      required this.onstandardpressed});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    return Center(
      child: Container(
        width: 950,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              color: Colors.transparent,
              child: Row(
                children: [
                  const SizedBox(
                    width: 30,
                  ),
                  Expanded(
                    child: Text(
                      'Features'.tr,
                      style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontSize: 30),
                    ),
                  ),
                  Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            gradient:
                                CustomBackgroundGradients.textFieldGradient(
                                    context, ref),
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'standard_plan_label'.tr,
                              style: TextStyle(
                                  color: Theme.of(context).iconTheme.color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.fillColor,
                                      foregroundColor: theme.textFieldColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: onstandardpressed,
                                    child: Text(
                                      'Get Started'.tr,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textFieldColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )),
                  ),
                  Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: CustomBackgroundGradients.textFieldGradient(
                              context, ref),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'premium_plan_label'.tr,
                              style: TextStyle(
                                  color: Theme.of(context).iconTheme.color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.fillColor,
                                      foregroundColor: theme.textFieldColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: onpremiumpressed,
                                    child: Text(
                                      'Get Started'.tr,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textFieldColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )),
                  ),
                  Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            gradient:
                                CustomBackgroundGradients.textFieldGradient(
                                    context, ref),
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Gold'.tr,
                              style: TextStyle(
                                  color: Theme.of(context).iconTheme.color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.fillColor,
                                      foregroundColor: theme.textFieldColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: ongoldpressed,
                                    child: Text(
                                      'Get Started'.tr,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textFieldColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FeatureRow extends ConsumerWidget {
  final String featureLabel;
  final bool isStandardFeatureEnabled;
  final bool isPremiumFeatureEnabled;
  final bool isGoldFeatureEnabled;

  const FeatureRow({
    required this.featureLabel,
    required this.isStandardFeatureEnabled,
    required this.isPremiumFeatureEnabled,
    required this.isGoldFeatureEnabled,
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Text(
              featureLabel,
              style: TextStyle(
                  color: Theme.of(context).iconTheme.color, fontSize: 14),
            ),
          ),
          // Standard feature column
          Expanded(
            flex: 20,
            child: isStandardFeatureEnabled
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).iconTheme.color,
                  )
                : Text(
                    '_',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          // Premium feature column
          Expanded(
            flex: 20,
            child: isPremiumFeatureEnabled
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).iconTheme.color,
                  )
                : Text(
                    '_',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          // Gold feature column
          Expanded(
            flex: 20,
            child: isGoldFeatureEnabled
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).iconTheme.color,
                  )
                : Text(
                    '_',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class Featuredatarow extends StatelessWidget {
  final String featureLabel;
  final String standardFeatureQuota;
  final String premiumFeatureQuota;
  final String goldFeatureQuota;
  const Featuredatarow({
    required this.featureLabel,
    required this.standardFeatureQuota,
    required this.premiumFeatureQuota,
    required this.goldFeatureQuota,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Text(
              featureLabel,
              style: TextStyle(
                  color: Theme.of(context).iconTheme.color, fontSize: 14),
            ),
          ),
          // Standard feature column
          Expanded(
            flex: 20,
            child: Text(
              standardFeatureQuota,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Premium feature column
          Expanded(
            flex: 20,
            child: Text(
              premiumFeatureQuota,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Gold feature column
          Expanded(
            flex: 20,
            child: Text(
              goldFeatureQuota,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityBanner extends ConsumerWidget {
  final String message;

  final void Function()? onTap;
  const SecurityBanner({super.key, required this.message, required this.onTap});

  @override
  Widget build(BuildContext context, ref) {
    final themeMode = ref.watch(isDefaultDarkSystemProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: themeMode
              ? const Color.fromARGB(255, 63, 87, 90)
              : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
             Icon(
              Icons.lock_outline_rounded,
              color: themeMode
              ?  Colors.lightBlueAccent
              : Theme.of(context).iconTheme.color,
              size: 24.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                message,
                style:  TextStyle(
                  color:Theme.of(context).iconTheme.color,
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
