import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:get/get_utils/get_utils.dart';

class TariffPlan {
  final String name;
  final String duration;
  final String originalPrice;
  final String discountedPrice;

  TariffPlan(
      this.name,
      this.duration,
      this.originalPrice,
      this.discountedPrice,
      );

  bool get hasDiscount => discountedPrice.isNotEmpty;
}

class TariffTile extends StatelessWidget {
  final TariffPlan plan;

  const TariffTile({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Section (Text Info)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plan.duration,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(178),
                ),
              ),
              if (plan.name == "Plus") ...[
                const SizedBox(height: 2),
                Text(
                  "Szczecin".tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(128),
                  ),
                ),
              ],
            ],
          ),
          // Replace the right section with this:
          Spacer(),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (plan.hasDiscount) ...[
                  Flexible(
                    child: Text(
                      plan.originalPrice,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(128),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    plan.hasDiscount
                        ? plan.discountedPrice
                        : plan.originalPrice,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

class TariffPlansWidget extends ConsumerWidget {
  final bool isMobile;
  final bool isTablet;
  const TariffPlansWidget({super.key, this.isMobile = false,  this.isTablet=false});

  @override
  Widget build(BuildContext context, ref) {
    // Define the tariff plans data
    final plans = [
      TariffPlan("Basic".tr, "for one month".tr, "\$0", ""),
      TariffPlan("Plus".tr, "for 7 days".tr, "\$20.00", "\$15.00"),
      TariffPlan("Turbo".tr, "for 7 days".tr, "\$60.00", "\$45.00"),
    ];
    final addOfferState = ref.watch(addOfferProvider); // Watch the provider
    final offerType = addOfferState.offerTypeController.text; // Get offerType
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double dialogHeight =
    isMobile
        ? screenHeight * 0.8
        : isTablet? 600
        : screenWidth > 2000
        ? screenHeight * 0.4
        : (screenWidth >= 500
        ? 520
        : 400); // optional fallback if width < 500
    return Container(
      height: dialogHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(
            'assets/images/mapa.webp', // Dummy URL
          ),
          fit: BoxFit.cover,
        ),
      ),

      child: Stack(
        children: [
          // Background image

          // Semi-transparent overlay and content
          Container(
            height: dialogHeight,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(((0.8 as num).clamp(0, 1) * 255).round()), // Dark semi-transparent background
              borderRadius: BorderRadius.circular(12),
            ),

            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  "Tariff plans".tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                // Subtitle
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Boost your ad to reach more buyers faster  and sell your property with ease!".tr,
                        style: TextStyle(
                          color: Colors.white.withAlpha(230),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Tariff plans list
                TariffTile(plan: plans[0]),
                TariffTile(plan: plans[1]),
                TariffTile(plan: plans[2]),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                SizedBox(height: 16),
                // Footer note
                Text(
                  "You can change the posting pricing plan at any time.".tr,
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                  ),
                ),
                if (offerType.isNotEmpty && isMobile == false) ...[
                  SizedBox(height:isTablet?20:80),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
