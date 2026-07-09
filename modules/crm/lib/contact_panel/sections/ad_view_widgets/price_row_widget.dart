import 'package:crm/data/add_field/edit_sell_offer_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:portal/screens/edit_offer/components/edit_fileds.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.isEditing,
    required this.state,
    required this.formattedPrice,
    required this.pricePerSquareMeter,
    required this.viewCurrency,
    required this.theme,
  });

  final bool isEditing;
  final EditOfferState state;
  final String formattedPrice;
  final double pricePerSquareMeter;
  final String viewCurrency;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isEditing) ...[
          SizedBox(
            width: 110,
            child: BuildDropdownButtonFormField(
              controller: state.currencyController,
              items: const ['PLN', 'EUR', 'GBP', 'USD', 'CZK'],
              labelText: 'Currency'.tr,
              isEditAdView: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BuildNumberTextField(
              controller: state.priceController,
              labelText: 'Price'.tr,
              unit: '',
              isEditAdView: true,
            ),
          ),
        ] else ...[
          Text(
            '$formattedPrice $viewCurrency',
            style: AppTextStyles.interBold
                .copyWith(fontSize: 26, color: theme.textColor),
          ),
          const Spacer(),
        ],
        const SizedBox(width: 10),
        Text(
          '${NumberFormat.decimalPattern().format(pricePerSquareMeter)} $viewCurrency/m²',
          style: AppTextStyles.interRegular16.copyWith(color: theme.textColor),
        ),
      ],
    );
  }
}

