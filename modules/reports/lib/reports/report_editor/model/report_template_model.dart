import 'package:flutter/material.dart';

class ReportTemplateModel {
  final int? id;
  final String name;
  final String? logoUrl;
  final String agentName;
  final String companyName;
  final String phone;
  final String email;
  final String customFooter;
  final String colorPrimary;
  final String colorAccent;
  final String colorBackground;
  final String colorText;
  final bool showPriceAlert;
  final bool showValueHistory;
  final bool showInvestmentScore;
  final bool showMarketVelocity;
  final bool showDailyMarketOverview;
  final bool showGovernmentData;
  final bool showDemographics;
  final bool showPriceTrend;
  final bool showFloodRisk;
  final bool showAirQuality;
  final bool showPoi;
  final bool showMaintenanceCost;
  final bool showComparables;
  final bool showAccuracyIndex;
  final bool showRentalData;
  final bool showPriceDistribution;
  final bool showAgentNotes;
  final bool showReportVersions;
  final bool showMortgageCalculator;
  final bool isDefault;

  const ReportTemplateModel({
    this.id,
    this.name = 'Mój szablon',
    this.logoUrl,
    this.agentName = '',
    this.companyName = '',
    this.phone = '',
    this.email = '',
    this.customFooter = '',
    this.colorPrimary = '#5FCDD9',
    this.colorAccent = '#2FB8C6',
    this.colorBackground = '#F6F7F9',
    this.colorText = '#171A1F',
    this.showPriceAlert = true,
    this.showValueHistory = true,
    this.showInvestmentScore = true,
    this.showMarketVelocity = true,
    this.showDailyMarketOverview = true,
    this.showGovernmentData = true,
    this.showDemographics = true,
    this.showPriceTrend = true,
    this.showFloodRisk = true,
    this.showAirQuality = true,
    this.showPoi = true,
    this.showMaintenanceCost = true,
    this.showComparables = true,
    this.showAccuracyIndex = true,
    this.showRentalData = true,
    this.showPriceDistribution = true,
    this.showAgentNotes = true,
    this.showReportVersions = true,
    this.showMortgageCalculator = true,
    this.isDefault = false,
  });

  factory ReportTemplateModel.fromJson(Map<String, dynamic> json) {
    return ReportTemplateModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Mój szablon',
      logoUrl: json['logo_url'] as String?,
      agentName: json['agent_name'] as String? ?? '',
      companyName: json['company_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      customFooter: json['custom_footer'] as String? ?? '',
      colorPrimary: json['color_primary'] as String? ?? '#5FCDD9',
      colorAccent: json['color_accent'] as String? ?? '#2FB8C6',
      colorBackground: json['color_background'] as String? ?? '#F6F7F9',
      colorText: json['color_text'] as String? ?? '#171A1F',
      showPriceAlert: json['show_price_alert'] as bool? ?? true,
      showValueHistory: json['show_value_history'] as bool? ?? true,
      showInvestmentScore: json['show_investment_score'] as bool? ?? true,
      showMarketVelocity: json['show_market_velocity'] as bool? ?? true,
      showDailyMarketOverview: json['show_daily_market_overview'] as bool? ?? true,
      showGovernmentData: json['show_government_data'] as bool? ?? true,
      showDemographics: json['show_demographics'] as bool? ?? true,
      showPriceTrend: json['show_price_trend'] as bool? ?? true,
      showFloodRisk: json['show_flood_risk'] as bool? ?? true,
      showAirQuality: json['show_air_quality'] as bool? ?? true,
      showPoi: json['show_poi'] as bool? ?? true,
      showMaintenanceCost: json['show_maintenance_cost'] as bool? ?? true,
      showComparables: json['show_comparables'] as bool? ?? true,
      showAccuracyIndex: json['show_accuracy_index'] as bool? ?? true,
      showRentalData: json['show_rental_data'] as bool? ?? true,
      showPriceDistribution: json['show_price_distribution'] as bool? ?? true,
      showAgentNotes: json['show_agent_notes'] as bool? ?? true,
      showReportVersions: json['show_report_versions'] as bool? ?? true,
      showMortgageCalculator: json['show_mortgage_calculator'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'agent_name': agentName,
      'company_name': companyName,
      'phone': phone,
      'email': email,
      'custom_footer': customFooter,
      'color_primary': colorPrimary,
      'color_accent': colorAccent,
      'color_background': colorBackground,
      'color_text': colorText,
      'show_price_alert': showPriceAlert,
      'show_value_history': showValueHistory,
      'show_investment_score': showInvestmentScore,
      'show_market_velocity': showMarketVelocity,
      'show_daily_market_overview': showDailyMarketOverview,
      'show_government_data': showGovernmentData,
      'show_demographics': showDemographics,
      'show_price_trend': showPriceTrend,
      'show_flood_risk': showFloodRisk,
      'show_air_quality': showAirQuality,
      'show_poi': showPoi,
      'show_maintenance_cost': showMaintenanceCost,
      'show_comparables': showComparables,
      'show_accuracy_index': showAccuracyIndex,
      'show_rental_data': showRentalData,
      'show_price_distribution': showPriceDistribution,
      'show_agent_notes': showAgentNotes,
      'show_report_versions': showReportVersions,
      'show_mortgage_calculator': showMortgageCalculator,
      'is_default': isDefault,
    };
  }

  ReportTemplateModel copyWith({
    int? id,
    String? name,
    String? logoUrl,
    bool clearLogo = false,
    String? agentName,
    String? companyName,
    String? phone,
    String? email,
    String? customFooter,
    String? colorPrimary,
    String? colorAccent,
    String? colorBackground,
    String? colorText,
    bool? showPriceAlert,
    bool? showValueHistory,
    bool? showInvestmentScore,
    bool? showMarketVelocity,
    bool? showDailyMarketOverview,
    bool? showGovernmentData,
    bool? showDemographics,
    bool? showPriceTrend,
    bool? showFloodRisk,
    bool? showAirQuality,
    bool? showPoi,
    bool? showMaintenanceCost,
    bool? showComparables,
    bool? showAccuracyIndex,
    bool? showRentalData,
    bool? showPriceDistribution,
    bool? showAgentNotes,
    bool? showReportVersions,
    bool? showMortgageCalculator,
    bool? isDefault,
  }) {
    return ReportTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
      agentName: agentName ?? this.agentName,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      customFooter: customFooter ?? this.customFooter,
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorAccent: colorAccent ?? this.colorAccent,
      colorBackground: colorBackground ?? this.colorBackground,
      colorText: colorText ?? this.colorText,
      showPriceAlert: showPriceAlert ?? this.showPriceAlert,
      showValueHistory: showValueHistory ?? this.showValueHistory,
      showInvestmentScore: showInvestmentScore ?? this.showInvestmentScore,
      showMarketVelocity: showMarketVelocity ?? this.showMarketVelocity,
      showDailyMarketOverview: showDailyMarketOverview ?? this.showDailyMarketOverview,
      showGovernmentData: showGovernmentData ?? this.showGovernmentData,
      showDemographics: showDemographics ?? this.showDemographics,
      showPriceTrend: showPriceTrend ?? this.showPriceTrend,
      showFloodRisk: showFloodRisk ?? this.showFloodRisk,
      showAirQuality: showAirQuality ?? this.showAirQuality,
      showPoi: showPoi ?? this.showPoi,
      showMaintenanceCost: showMaintenanceCost ?? this.showMaintenanceCost,
      showComparables: showComparables ?? this.showComparables,
      showAccuracyIndex: showAccuracyIndex ?? this.showAccuracyIndex,
      showRentalData: showRentalData ?? this.showRentalData,
      showPriceDistribution: showPriceDistribution ?? this.showPriceDistribution,
      showAgentNotes: showAgentNotes ?? this.showAgentNotes,
      showReportVersions: showReportVersions ?? this.showReportVersions,
      showMortgageCalculator: showMortgageCalculator ?? this.showMortgageCalculator,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Color get primaryColor => hexToColor(colorPrimary);
  Color get accentColor => hexToColor(colorAccent);
  Color get backgroundColor => hexToColor(colorBackground);
  Color get textColor => hexToColor(colorText);

  static Color hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 3) {
      final r = clean[0] * 2;
      final g = clean[1] * 2;
      final b = clean[2] * 2;
      return Color(int.parse('FF$r$g$b', radix: 16));
    }
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return const Color(0xFF5FCDD9);
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
