import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

class NetworkMonitoringHeaderWidget extends StatelessWidget {
  const NetworkMonitoringHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/top-content.webp',
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          height: 130,
        ),
         Positioned(
          bottom: 10,
          top: 10,
          left: 20,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'title_network_monitoring'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color.fromRGBO(255, 255, 255, 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
