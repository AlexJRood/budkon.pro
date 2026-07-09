import 'package:flutter/material.dart';

import 'package:get/get_utils/get_utils.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 950,
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        FAQItem(
          question: 'WHAT ARE THE BENEFITS OF UPGRADING TO THE PREMIUM PLAN?'.tr,
          answer:
              'Upgrading to the Premium Plan gives you access to exclusive features, priority support, and advanced analytics tools.'.tr,
        ),
        FAQItem(
          question: 'WHAT\'S THE DIFFERENCE BETWEEN STANDARD, GOLD AND PREMIUM'.tr,
          answer:
              'The Standard plan offers basic features, Gold provides additional customization options, and Premium includes everything in Gold with extra priority support and analytics tools.'.tr,
        ),
        FAQItem(
          question: 'CAN I CANCEL MY SUBSCRIPTION AT ANY TIME?'.tr,
          answer:
              'Yes, you can cancel your subscription anytime through your account settings without any penalties.'.tr,
        ),
        FAQItem(
          question: 'WHAT PAYMENT METHODS ARE ACCEPTED FOR THE SUBSCRIPTION?'.tr,
          answer:
              'We accept all major credit cards, PayPal, and bank transfers for subscription payments.'.tr,
        ),
        FAQItem(
          question: 'HOW DO I UPDATE MY ACCOUNT OR BILLING INFORMATION?'.tr,
          answer:
              'To update your account or billing information, simply go to the "Account Settings".tr section and make the necessary changes.',
        ),
        FAQItem(
          question: 'HOW DO I CONTACT CUSTOMER SUPPORT IF I NEED ASSISTANCE?'.tr,
          answer:
              'You can contact customer support via email at support@company.com or reach our support hotline at 1-800-123-4567.'.tr,
        ),
      ]),
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const FAQItem({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Theme.of(context).iconTheme.color,
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
                color: Theme.of(context).iconTheme.color, fontSize: 17),
          ),
          collapsedIconColor: Theme.of(context).iconTheme.color,
          iconColor: Theme.of(context).iconTheme.color,
          children: [
            if (answer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Text(
                  answer,
                  style: TextStyle(
                      color:
                          Theme.of(context).iconTheme.color!.withAlpha((255 * 0.7).toInt())),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
