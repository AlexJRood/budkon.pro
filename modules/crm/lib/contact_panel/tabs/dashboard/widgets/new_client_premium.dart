import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/components/dashhed_line.dart';
import 'package:crm/contact_panel/components/transaction_filter_button.dart';
import 'package:get/get_utils/get_utils.dart';
class NewClientPremium extends ConsumerWidget {
  const NewClientPremium({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dashboardContainer, width: 3),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Wersja Pro'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text('Szczegóły'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ))
            ],
          ),
          const SizedBox(height: 25),
          const MySeparator(),
          const SizedBox(height: 25),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: CustomBackgroundGradients.proContainerGradient(
                      context, ref),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  'Więcej z Premium'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Our premium subscription elevate your experience and unlock of benefits.'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'You\'ll Pay'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                '\$49.00',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '\$29.00',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/per month',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Spacer(),
          Row(
            children: [
              Expanded(
                child: TransactionFilterButton(
                  text: "Rozpocznij".tr,
                  onTap: () {},
                  isicon: false,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
