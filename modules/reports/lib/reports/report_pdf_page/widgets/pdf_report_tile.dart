import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/theme/backgroundgradient.dart';

class PdfReportTile extends ConsumerWidget {
  final ReportsListModel model;
  final VoidCallback? onTap;
  final bool isSelected;

  const PdfReportTile({
    super.key,
    required this.model,
    this.onTap,
    this.isSelected = false,
  });

  String _formatMoney(num? amount, String? currency) {
    if (amount == null) return '-';

    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: '',
      decimalDigits: 2,
    );

    final cur = (currency ?? '').trim().toLowerCase();
    final money = fmt.format(amount).trim();
    return cur.isEmpty ? money : '$money $cur';
  }

  String get _locationText {
    final parts = [
      model.city,
      model.state,
      model.country,
    ].where((e) => e != null && e!.trim().isNotEmpty).cast<String>().toList();

    return parts.isEmpty ? 'unknown_location'.tr : parts.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = CustomColors.secondaryWidgetColor(context, ref);
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? bgColor.withOpacity(0.92) : bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? textColor.withOpacity(0.26)
                  : textColor.withOpacity(0.06),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                blurRadius: isSelected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: textColor.withOpacity(0.05),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/report_house.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.propertyType?.isNotEmpty == true
                          ? model.propertyType!
                          : 'Property Report'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _locationText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: textColor.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'estimated_value'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withOpacity(0.62),
                            ),
                          ),
                        ),
                        Text(
                          _formatMoney(model.valueEstimate, model.currency),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}