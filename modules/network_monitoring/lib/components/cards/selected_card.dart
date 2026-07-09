import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitoring/components/cards/va_list.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'a.dart';
import 'v.dart';
import 'va.dart';


enum CardTypeNM {
  alex,
  victoria,
  vanda,
  landing,
  list,
  full,
  map,
}



extension CardTypeExtension on CardTypeNM {
  
  int gridCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    switch (this) {
      case CardTypeNM.alex:
        return screenWidth >= 1250
            ? math.max(1, (screenWidth / baseWidth).ceil())
            : 1;
      case CardTypeNM.victoria:
        return screenWidth >= 1250
            ? math.max(1, (screenWidth / baseWidth).ceil())
            : 1;
      case CardTypeNM.vanda:
        return screenWidth >= 1250
            ? math.max(1, (screenWidth / baseWidth).ceil())
            : 1;
      case CardTypeNM.landing:
        return 1;
      case CardTypeNM.list:
        return 1;
      case CardTypeNM.full:
        return 1;
      case CardTypeNM.map:
        return 1;
    }
  }

  /// Różne aspectRatio w zależności od typu karty.
  double get aspectRatio {
    switch (this) {
      case CardTypeNM.alex:
        return 1.0;
      case CardTypeNM.victoria:
        // Karty Victoria szersze np. o 50%
        return 1;
      case CardTypeNM.vanda:
        // Karty Victoria szersze np. o 50%
        return 1;
      case CardTypeNM.landing:
        return 4/3;
      case CardTypeNM.list:
        return 6;
      case CardTypeNM.full:
        return 5/3;
      case CardTypeNM.map:
        return 16/11; 
    }
  }

  /// Bazowa szerokość używana w obliczeniach liczby kolumn.
  /// Dla Victorii może być większa (np. +50%).
  double get baseWidth {
    switch (this) {
      case CardTypeNM.alex:
        return 500;
      case CardTypeNM.victoria:
        return 750; // 500 x 1.5
      case CardTypeNM.vanda:
        return 750; // 500 x 1.5
      case CardTypeNM.landing:
        return 750; // 500 x 1.5
      case CardTypeNM.list:
        return 750; // 500 x 1.5
      case CardTypeNM.full:
        return 950; // 500 x 1.5
      case CardTypeNM.map:
        return 950; // 500 x 1.5
    }
  }

  double get basePadding {
    switch (this) {
      case CardTypeNM.alex:
        return 8;
      case CardTypeNM.victoria:
        return 25; 
      case CardTypeNM.vanda:
        return 15; 
      case CardTypeNM.landing:
        return 15; 
      case CardTypeNM.list:
        return 15; 
      case CardTypeNM.full:
        return 15; 
      case CardTypeNM.map:
        return 15; 
    }
  }

    double get mapAspectRatio {
    switch (this) {
      case CardTypeNM.alex:
        return 16/9;
      case CardTypeNM.victoria:
        return 16/10; 
      case CardTypeNM.vanda:
        return 16/9; 
      case CardTypeNM.landing:
        return 16/11; 
      case CardTypeNM.list:
        return 4; 
      case CardTypeNM.full:
        return 4/3; 
      case CardTypeNM.map:
        return 4/3; 
    }
  }
    double get gridRowCount {
    switch (this) {
      case CardTypeNM.alex:
        return 1;
      case CardTypeNM.victoria:
        return 2; 
      case CardTypeNM.vanda:
        return 2; 
      case CardTypeNM.landing:
        return 1; 
      case CardTypeNM.list:
        return 1; 
      case CardTypeNM.full:
        return 1; 
      case CardTypeNM.map:
        return 1; 
    }
  }
}


final selectedCardProviderNM = StateProvider<CardTypeNM>((ref) {
  return CardTypeNM.vanda; // domyślnie Alex
});




class SelectedCardWidgetNM extends ConsumerWidget {
  final MonitoringAdsModel ad;
  final String tag;
  final String mainImageUrl;
  final bool isPro;
  final bool isDefaultDarkSystem;
  final Color color;
  final Color textColor;
  final Color textFieldColor;
  final Widget buildShimmerPlaceholder;
  final dynamic buildPieMenuActions;
  final double aspectRatio;
  final bool isMobile;
  final bool isTablet;
  final int? transactionId;
  final int? clientId;
  final CardTypeNM? cardTypeNMOverwrite;


  const SelectedCardWidgetNM({
    super.key,
    required this.ad,
    required this.tag,
    required this.mainImageUrl,
    required this.isPro,
    required this.isDefaultDarkSystem,
    required this.color,
    required this.textColor,
    required this.textFieldColor,
    required this.buildShimmerPlaceholder,
    required this.buildPieMenuActions,
    required this.aspectRatio,    
    required this.isMobile,
    this.isTablet = false,
    this.transactionId,
    this.clientId,
    this.cardTypeNMOverwrite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final cardTypeNM = cardTypeNMOverwrite != null
        ? cardTypeNMOverwrite!
        : ref.watch(selectedCardProviderNM);
    switch (cardTypeNM) {
      case CardTypeNM.alex:
        return NetworkMonitoringAlexCardWidget(
          isMobile: isMobile,
          isTablet: isTablet,
          aspectRatio: aspectRatio,
          ad: ad,
          tag: tag,
          mainImageUrl: mainImageUrl,
          isPro: isPro,
          isDefaultDarkSystem: isDefaultDarkSystem,
          color: color,
          textColor: textColor,
          textFieldColor: textFieldColor,
          buildShimmerPlaceholder: buildShimmerPlaceholder,
          buildPieMenuActions: buildPieMenuActions,
          transactionId: transactionId,
          clientId: clientId,
        );
      case CardTypeNM.victoria:
        return NetworkMonitoringVictoriaCardWidget(
          isMobile: isMobile,
          isTablet: isTablet,
          aspectRatio: aspectRatio,
          ad: ad,
          tag: tag,
          mainImageUrl: mainImageUrl,
          isPro: isPro,
          isDefaultDarkSystem: isDefaultDarkSystem,
          color: color,
          textColor: textColor,
          textFieldColor: textFieldColor,
          buildShimmerPlaceholder: buildShimmerPlaceholder,
          buildPieMenuActions: buildPieMenuActions,
          transactionId: transactionId,
          clientId: clientId,
        );
      case CardTypeNM.vanda:
        return NetworMonitoringCardVandA(
          isMobile: isMobile,
          isTablet: isTablet,
          aspectRatio: aspectRatio,
          ad: ad,
          tag: tag,
          mainImageUrl: mainImageUrl,
          isPro: isPro,
          isDefaultDarkSystem: isDefaultDarkSystem,
          color: color,
          textColor: textColor,
          textFieldColor: textFieldColor,
          buildShimmerPlaceholder: buildShimmerPlaceholder,
          buildPieMenuActions: buildPieMenuActions,
          transactionId: transactionId,
          clientId: clientId,
        );
        case CardTypeNM.landing:
          return NetworMonitoringCardVandA(
            isMobile: isMobile,
            isTablet: isTablet,
            aspectRatio: aspectRatio,
            ad: ad,
            tag: tag,
            mainImageUrl: mainImageUrl,
            isPro: isPro,
            isDefaultDarkSystem: isDefaultDarkSystem,
            color: color,
            textColor: textColor,
            textFieldColor: textFieldColor,
            buildShimmerPlaceholder: buildShimmerPlaceholder,
            buildPieMenuActions: buildPieMenuActions,
          transactionId: transactionId,
          clientId: clientId,
        );
        case CardTypeNM.list:
          return NetworkMonitoringVictoriaNAlexCardWidgetList(
            isMobile: isMobile,
            isTablet: isTablet,
            aspectRatio: aspectRatio,
            ad: ad,
            tag: tag,
            mainImageUrl: mainImageUrl,
            isPro: isPro,
            isDefaultDarkSystem: isDefaultDarkSystem,
            color: color,
            textColor: textColor,
            textFieldColor: textFieldColor,
            buildShimmerPlaceholder: buildShimmerPlaceholder,
            buildPieMenuActions: buildPieMenuActions,
          transactionId: transactionId,
          clientId: clientId,
        );
        
        case CardTypeNM.full:
          return NetworMonitoringCardVandA(
            isMobile: isMobile,
            isTablet: isTablet,
            aspectRatio: aspectRatio,
            ad: ad,
            tag: tag,
            mainImageUrl: mainImageUrl,
            isPro: isPro,
            isDefaultDarkSystem: isDefaultDarkSystem,
            color: color,
            textColor: textColor,
            textFieldColor: textFieldColor,
            buildShimmerPlaceholder: buildShimmerPlaceholder,
            buildPieMenuActions: buildPieMenuActions,
            transactionId: transactionId,
            clientId: clientId,
        );
        case CardTypeNM.map:
          return NetworMonitoringCardVandA(
            isMobile: isMobile,
            isTablet: isTablet,
            aspectRatio: aspectRatio,
            ad: ad,
            tag: tag,
            mainImageUrl: mainImageUrl,
            isPro: isPro,
            isDefaultDarkSystem: isDefaultDarkSystem,
            color: color,
            textColor: textColor,
            textFieldColor: textFieldColor,
            buildShimmerPlaceholder: buildShimmerPlaceholder,
            buildPieMenuActions: buildPieMenuActions,
            transactionId: transactionId,
            clientId: clientId,
        );
    }
  }
}
