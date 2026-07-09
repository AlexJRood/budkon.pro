import 'package:flutter/material.dart';

import 'package:get/get_utils/get_utils.dart';

class Paymentstatuscontainer extends StatelessWidget {
  final String status;
  const Paymentstatuscontainer({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: status == 'Cancel'.tr
            ? const Color(0xff372b2a)
            : status == 'Pending'.tr
                ? const Color(0xff2e343b)
                : const Color(0xff2f342f),
      ),
      child: Center(
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: status == 'Cancel'.tr
                ? const Color(0xffad6a55)
                : status == 'Pending'.tr
                    ? const Color(0xffa1ece6)
                    : const Color(0xffa6e3b8),
          ),
        ),
      ),
    );
  }
}
