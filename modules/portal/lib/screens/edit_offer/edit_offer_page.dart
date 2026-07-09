import 'package:flutter/material.dart';
// Import Flutter Riverpod

import 'edit_offer_mobile_page.dart';

import 'package:portal/screens/edit_offer/edit_offer_pc.dart';

class EditOfferPage extends StatelessWidget {
  // Zmiana na ConsumerWidget
  final int offerId;

  const EditOfferPage({super.key, required this.offerId});

  @override
  Widget build(BuildContext context) {
        return PrivateEditOfferUnifiedPc(
          offerId: offerId,
        );
  }
}
