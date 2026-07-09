import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

class ReportsFAQPage extends StatelessWidget {
  final bool isMobile;
  const ReportsFAQPage({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              SizedBox(width: constraints.maxWidth * 0.1),

              // Main content in center
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isMobile) ...[
                        SizedBox(height: 30),
                        Text(
                         "frequently_asked_questions".tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).iconTheme.color,
                            fontSize: 27,
                          ),
                        ),
                        SizedBox(height: 30),
                      ],     
                  FAQItem(
                     question: 'how_accurate_is_the_data'.tr,
                     answer: 'how_accurate_is_the_data_answer'.tr,
                          ),
                   FAQItem(
                     question: 'can_i_preview_sample_report'.tr,
                     answer: 'can_i_preview_sample_report_answer'.tr,
                         ),
                   FAQItem(
                     question: 'what_payment_methods_accepted'.tr,
                     answer: 'what_payment_methods_accepted_answer'.tr,
                          ),
                   FAQItem(
                       question: 'is_there_refund_policy'.tr,
                       answer: 'is_there_refund_policy_answer'.tr,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: constraints.maxWidth * 0.1),
            ],
          );
        },
      ),
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});

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
              color: Theme.of(context).iconTheme.color,
              fontSize: 17,
            ),
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
                    color: Theme.of(context).iconTheme.color!.withAlpha(178),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
