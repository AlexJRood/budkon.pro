import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/backgroundgradient.dart';


class ResponsivePropertySearchWidget extends ConsumerWidget {
  const ResponsivePropertySearchWidget({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: CustomBackgroundGradients.reportsLandingGradient(
          context,
          ref,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 768;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [_TextContent()],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: const [
                          Expanded(flex: 3, child: SizedBox(width: 10)),
                          Expanded(flex: 6, child: _SearchBar()),
                          Expanded(flex: 3, child: SizedBox(width: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _TextContent(),
                SizedBox(height: 15.0),
                _SearchBar(),
              ],
            );
          }
        },
      ),
    );
  }
}

class _TextContent extends ConsumerWidget {
  const _TextContent();

  @override
  Widget build(BuildContext context, ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20,),
        Text(
          'Buy Property Report for smarter decisions'.tr,
          style: TextStyle(
            color: CustomColors.gradientTextcolor(context, ref),
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.0),
        Text(
          'Access detailed property reports to make informed investments'.tr,
          style: TextStyle(
            color: CustomColors.gradientTextcolor(context, ref),
            fontSize: 13.0,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.0),
      ],
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      height: 50.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: CustomColors.textfieldFillColor(context, ref),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.search, color: Colors.grey),
          ),
          Expanded(
            child: TextField(
              cursorColor: CustomColors.textfieldStyle(context, ref),
              style: TextStyle(
                fontSize: 13.0,
                color: CustomColors.textfieldStyle(context, ref),
              ),
              decoration: InputDecoration(
                fillColor: CustomColors.textfieldFillColor(context, ref),
                focusedBorder: InputBorder.none,
                hintText: 'Search a street address'.tr,
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFD3D3D3),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                ),
              ),
              onPressed: () {},
              child:  Text(
                'Search'.tr,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
