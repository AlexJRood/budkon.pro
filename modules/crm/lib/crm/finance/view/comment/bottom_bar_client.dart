import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/design.dart';

class BottomBarClient extends StatelessWidget {
  final double bottomBarClientWidth;

  const BottomBarClient({super.key, required this.bottomBarClientWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bottomBarClientWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: BackgroundGradients.adGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () {},
                      child: Text('Klient'.tr, style: AppTextStyles.interLight16)),
                  TextButton(
                      onPressed: () {},
                      child: Text('Wyszukiwania'.tr,
                          style: AppTextStyles.interLight16)),
                  TextButton(
                      onPressed: () {},
                      child:
                          Text('Notatki'.tr, style: AppTextStyles.interLight16)),
                  TextButton(
                      onPressed: () {},
                      child: Text('To do'.tr, style: AppTextStyles.interLight16)),
                  TextButton(
                      onPressed: () {},
                      child:
                          Text('Kalendarz'.tr, style: AppTextStyles.interLight16)),
                  TextButton(
                      onPressed: () {},
                      child: Text('Komentarze'.tr,
                          style: AppTextStyles.interLight16)),
                  TextButton(
                      onPressed: () {},
                      child: Text('Docs'.tr, style: AppTextStyles.interLight16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
