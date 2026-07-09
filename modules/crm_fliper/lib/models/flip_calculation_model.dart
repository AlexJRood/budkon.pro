class FlipCalculation {
  final int id;
  final String? transactionPrice;
  final String? area;
  final String? pcc;
  final String? notaryCosts;
  final String? purchaseCommission;
  final String? buyingCosts;
  final String? agentFeeSele;
  final String? salePrice;
  final String? renovationTotalCost;
  final String? fixedCosts;
  final String? capitalCost;
  final String? capitalCostPerMonth;
  final String? capitalCostUnit;
  final String? capitalCostPercent;
  final String? capitalCostPercentPer;
  final String? insuranceCost;
  final String? communityFee;
  final String? communityFeeUnit;
  final String? otherExpenses;
  final String? grossProfit;
  final String? desiredGrossProfit;
  final String? desiredNetProfit;
  final String? incomeTaxRate;
  final String? netProfit;
  final String? investorRoi;
  final int? investmentReturnTime;
  final String? rentalIncomeOptimistic;
  final String? rentalIncomePessimistic;
  final String? rentalIncomeAverage;
  final String? salePriceOptimistic;
  final String? salePricePessimistic;
  final String? salePriceAverage;
  final String? annualProfitOptimistic;
  final String? annualProfitPessimistic;
  final String? annualProfitAverage;
  final String? administrativeFee;
  final String? managementProfit;
  final String? dateCreate;
  final String? dateUpdate;
  final int? transaction;
  final int user;

  FlipCalculation({
    required this.id,
    this.transactionPrice,
    this.area,
    this.pcc,
    this.notaryCosts,
    this.purchaseCommission,
    this.buyingCosts,
    this.agentFeeSele,
    this.salePrice,
    this.renovationTotalCost,
    this.fixedCosts,
    this.capitalCost,
    this.capitalCostPerMonth,
    this.capitalCostUnit,
    this.capitalCostPercent,
    this.capitalCostPercentPer,
    this.insuranceCost,
    this.communityFee,
    this.communityFeeUnit,
    this.otherExpenses,
    this.grossProfit,
    this.desiredGrossProfit,
    this.desiredNetProfit,
    this.incomeTaxRate,
    this.netProfit,
    this.investorRoi,
    this.investmentReturnTime,
    this.rentalIncomeOptimistic,
    this.rentalIncomePessimistic,
    this.rentalIncomeAverage,
    this.salePriceOptimistic,
    this.salePricePessimistic,
    this.salePriceAverage,
    this.annualProfitOptimistic,
    this.annualProfitPessimistic,
    this.annualProfitAverage,
    this.administrativeFee,
    this.managementProfit,
    this.dateCreate,
    this.dateUpdate,
    this.transaction,
    required this.user,
  });

  factory FlipCalculation.fromJson(Map<String, dynamic> json) {
    return FlipCalculation(
      id: json['id'],
      transactionPrice: json['transaction_price'],
      area: json['area'],
      pcc: json['pcc'],
      notaryCosts: json['notary_costs'],
      purchaseCommission: json['purchase_commission'],
      buyingCosts: json['buying_costs'],
      agentFeeSele: json['agent_fee_sele'],
      salePrice: json['sale_price'],
      renovationTotalCost: json['renovation_total_cost'],
      fixedCosts: json['fixed_costs'],
      capitalCost: json['capital_cost'],
      capitalCostPerMonth: json['capital_cost_per_month'],
      capitalCostUnit: json['capital_cost_unit'],
      capitalCostPercent: json['capital_cost_percent'],
      capitalCostPercentPer: json['capital_cost_percent_per'],
      insuranceCost: json['insurance_cost'],
      communityFee: json['community_fee'],
      communityFeeUnit: json['community_fee_unit'],
      otherExpenses: json['other_expenses'],
      grossProfit: json['gross_profit'],
      desiredGrossProfit: json['desired_gross_profit'],
      desiredNetProfit: json['desired_net_profit'],
      incomeTaxRate: json['income_tax_rate'],
      netProfit: json['net_profit'],
      investorRoi: json['investor_roi'],
      investmentReturnTime: json['investment_return_time'],
      rentalIncomeOptimistic: json['rental_income_optimistic'],
      rentalIncomePessimistic: json['rental_income_pessimistic'],
      rentalIncomeAverage: json['rental_income_average'],
      salePriceOptimistic: json['sale_price_optimistic'],
      salePricePessimistic: json['sale_price_pessimistic'],
      salePriceAverage: json['sale_price_average'],
      annualProfitOptimistic: json['annual_profit_optimistic'],
      annualProfitPessimistic: json['annual_profit_pessimistic'],
      annualProfitAverage: json['annual_profit_average'],
      administrativeFee: json['administrative_fee'],
      managementProfit: json['management_profit'],
      dateCreate: json['date_create'],
      dateUpdate: json['date_update'],
      transaction: json['transaction'],
      user: json['user'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_price': transactionPrice,
      'area': area,
      'pcc': pcc,
      'notary_costs': notaryCosts,
      'purchase_commission': purchaseCommission,
      'buying_costs': buyingCosts,
      'agent_fee_sele': agentFeeSele,
      'sale_price': salePrice,
      'renovation_total_cost': renovationTotalCost,
      'fixed_costs': fixedCosts,
      'capital_cost': capitalCost,
      'capital_cost_per_month': capitalCostPerMonth,
      'capital_cost_unit': capitalCostUnit,
      'capital_cost_percent': capitalCostPercent,
      'capital_cost_percent_per': capitalCostPercentPer,
      'insurance_cost': insuranceCost,
      'community_fee': communityFee,
      'community_fee_unit': communityFeeUnit,
      'other_expenses': otherExpenses,
      'gross_profit': grossProfit,
      'desired_gross_profit': desiredGrossProfit,
      'desired_net_profit': desiredNetProfit,
      'income_tax_rate': incomeTaxRate,
      'net_profit': netProfit,
      'investor_roi': investorRoi,
      'investment_return_time': investmentReturnTime,
      'rental_income_optimistic': rentalIncomeOptimistic,
      'rental_income_pessimistic': rentalIncomePessimistic,
      'rental_income_average': rentalIncomeAverage,
      'sale_price_optimistic': salePriceOptimistic,
      'sale_price_pessimistic': salePricePessimistic,
      'sale_price_average': salePriceAverage,
      'annual_profit_optimistic': annualProfitOptimistic,
      'annual_profit_pessimistic': annualProfitPessimistic,
      'annual_profit_average': annualProfitAverage,
      'administrative_fee': administrativeFee,
      'management_profit': managementProfit,
      'date_create': dateCreate,
      'date_update': dateUpdate,
      'transaction': transaction,
      'user': user,
    };
  }

}

class FlipCalculationResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FlipCalculation> results;

  FlipCalculationResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FlipCalculationResponse.fromJson(Map<String, dynamic> json) {
    return FlipCalculationResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List)
          .map((e) => FlipCalculation.fromJson(e))
          .toList(),
    );
  }
}
