import 'dart:ui' as ui;

import 'package:core/common/chrome/logo_hously.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crm/bars/client_tile.dart';

class TopAppBarCRM extends ConsumerWidget {
  final bool isThatOnHover;

  const TopAppBarCRM({super.key, this.isThatOnHover = false});

  static const double _baseBarHeight = 60;
  static const double _extraHitAreaHeight = 320;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final openedClientId = ref.watch(clientTransactionsOpenForClientIdProvider);
    final bool hasExpandedTransactions = openedClientId != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: _baseBarHeight +
          (hasExpandedTransactions ? _extraHitAreaHeight : 0),
      width: screenWidth - 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _baseBarHeight,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: isThatOnHover ? 12 : 0,
            left: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: ClientListAppBar(),
                ),
                if (!isThatOnHover) ...[
                  const SizedBox(width: 8),
                  LogoHouslyWidget(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}