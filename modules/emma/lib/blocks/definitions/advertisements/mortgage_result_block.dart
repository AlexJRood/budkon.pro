import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class MortgageResultBlockDefinition extends EmmaBlockDefinition {
  const MortgageResultBlockDefinition();

  @override
  String get key => 'mortgage_result';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.mortgageResult;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _MortgageResultBlock(block: block, maxWidth: maxWidth);
  }
}

class _MortgagePayload {
  final double monthlyPayment;
  final double loanAmount;
  final double totalCost;
  final double totalInterest;
  final double price;
  final double downPaymentPct;
  final double interestRatePct;
  final int years;
  final String currency;

  const _MortgagePayload({
    required this.monthlyPayment,
    required this.loanAmount,
    required this.totalCost,
    required this.totalInterest,
    required this.price,
    required this.downPaymentPct,
    required this.interestRatePct,
    required this.years,
    required this.currency,
  });

  factory _MortgagePayload.fromBlock(EmmaBlockDescriptor block) {
    final raw = block.raw;
    final m = raw['mortgage'] is Map
        ? Map<String, dynamic>.from(raw['mortgage'] as Map)
        : <String, dynamic>{};

    double _d(String key) =>
        double.tryParse((m[key] ?? '0').toString()) ?? 0.0;
    int _i(String key) => int.tryParse((m[key] ?? '0').toString()) ?? 0;

    return _MortgagePayload(
      monthlyPayment: _d('monthly_payment'),
      loanAmount: _d('loan_amount'),
      totalCost: _d('total_cost'),
      totalInterest: _d('total_interest'),
      price: _d('price'),
      downPaymentPct: _d('down_payment_pct'),
      interestRatePct: _d('interest_rate_pct'),
      years: _i('years'),
      currency: (m['currency'] ?? 'PLN').toString(),
    );
  }
}

class _MortgageResultBlock extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _MortgageResultBlock({required this.block, required this.maxWidth});

  String _fmt(double value, String currency) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} mln $currency';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} tys. $currency';
    }
    return '${value.toStringAsFixed(2)} $currency';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = _MortgagePayload.fromBlock(block);
    const accent = Color(0xFF6EC6A0);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalkulator kredytu',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Monthly payment highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Miesięczna rata',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(p.monthlyPayment, p.currency),
                  style: const TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Parameters
          _detailRow(
            'Cena nieruchomości',
            _fmt(p.price, p.currency),
          ),
          _detailRow(
            'Kwota kredytu',
            _fmt(p.loanAmount, p.currency),
          ),
          _detailRow(
            'Wkład własny',
            '${p.downPaymentPct.toStringAsFixed(0)}%',
          ),
          _detailRow(
            'Oprocentowanie',
            '${p.interestRatePct.toStringAsFixed(2)}%',
          ),
          _detailRow(
            'Okres kredytowania',
            '${p.years} ${'years'.tr}',
          ),
          const Divider(color: Colors.white12, height: 18),
          _detailRow(
            'Łączny koszt odsetek',
            _fmt(p.totalInterest, p.currency),
            valueColor: Colors.orangeAccent,
          ),
          _detailRow(
            'Całkowity koszt kredytu',
            _fmt(p.totalCost, p.currency),
            valueColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
