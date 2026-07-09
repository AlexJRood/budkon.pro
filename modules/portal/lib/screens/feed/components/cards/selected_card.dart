import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/feed/components/cards/va_list.dart';

import 'a.dart';
import 'v.dart';
import 'va.dart';


enum CardType {
  alex,
  victoria,
  vanda,
  landing,
  list,
  full,
}





extension CardTypeExtension on CardType {
  
  int gridCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    switch (this) {
      case CardType.alex:
        return screenWidth >= 1250
            ? math.max(1, (screenWidth / baseWidth).ceil())
            : 1;
      case CardType.victoria:
        return screenWidth >= 1250
            ? math.max(1, (screenWidth / baseWidth).ceil())
            : 1;
      case CardType.vanda:
        return screenWidth >= 1250
            ? math.max(1, (screenWidth / baseWidth).ceil())
            : 1;
      case CardType.landing:
        return 1;
      case CardType.list:
        return 1;
      case CardType.full:
        return 1;
    }
  }

  /// Różne aspectRatio w zależności od typu karty.
  double get aspectRatio {
    switch (this) {
      case CardType.alex:
        return 1.0;
      case CardType.victoria:
        // Karty Victoria szersze np. o 50%
        return 1;
      case CardType.vanda:
        // Karty Victoria szersze np. o 50%
        return 1;
      case CardType.landing:
        return 4/3;
      case CardType.list:
        return 6;
      case CardType.full:
        return 5/3;
    }
  }

  /// Bazowa szerokość używana w obliczeniach liczby kolumn.
  /// Dla Victorii może być większa (np. +50%).
  double get baseWidth {
    switch (this) {
      case CardType.alex:
        return 500;
      case CardType.victoria:
        return 750; // 500 x 1.5
      case CardType.vanda:
        return 750; // 500 x 1.5
      case CardType.landing:
        return 750; // 500 x 1.5
      case CardType.list:
        return 750; // 500 x 1.5
      case CardType.full:
        return 950; // 500 x 1.5
    }
  }

  double get basePadding {
    switch (this) {
      case CardType.alex:
        return 8;
      case CardType.victoria:
        return 25; 
      case CardType.vanda:
        return 15; 
      case CardType.landing:
        return 15; 
      case CardType.list:
        return 15; 
      case CardType.full:
        return 15; 
    }
  }

    double get mapAspectRatio {
    switch (this) {
      case CardType.alex:
        return 16/9;
      case CardType.victoria:
        return 16/10; 
      case CardType.vanda:
        return 16/9; 
      case CardType.landing:
        return 16/11; 
      case CardType.list:
        return 4; 
      case CardType.full:
        return 4/3; 
    }
  }
    double get gridRowCount {
    switch (this) {
      case CardType.alex:
        return 1;
      case CardType.victoria:
        return 2; 
      case CardType.vanda:
        return 2; 
      case CardType.landing:
        return 1; 
      case CardType.list:
        return 1; 
      case CardType.full:
        return 1; 
    }
  }
}


final selectedCardProvider = StateProvider<CardType>((ref) {
  return CardType.vanda; // domyślnie Victoria
});




class SelectedCardWidget extends ConsumerWidget {
  final dynamic ad;
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
  final bool isFeed;
  final CardType? cardTypeOverwrite;

  const SelectedCardWidget({
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
    this.isFeed = false,
    this.cardTypeOverwrite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardType = cardTypeOverwrite != null
    ? cardTypeOverwrite!
    : ref.watch(selectedCardProvider);
    switch (cardType) {
      case CardType.alex:
        return AlexCardWidget(
          isMobile: isMobile,
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
        );
      case CardType.victoria:
        return VictoriaCardWidget(
          isMobile: isMobile,
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
        );
      case CardType.vanda:
        return VictoriaNAlexCardWidget(
          
          isMobile: isMobile,
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
          isFeed: isFeed,
          // isOwnUser: true,
          // isArchive: true,
        );
        case CardType.landing:
          return VictoriaNAlexCardWidget(
            isMobile: isMobile,
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
        );
        case CardType.list:
          return VictoriaNAlexCardWidgetList(
            isMobile: isMobile,
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
        );
        
        case CardType.full:
          return VictoriaNAlexCardWidget(
            isMobile: isMobile,
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
        );
    }
  }
}
