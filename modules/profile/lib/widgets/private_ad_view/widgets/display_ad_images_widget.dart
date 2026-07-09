import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/design.dart';

class DisplayAdImagesWidget extends StatelessWidget {
  final double mainImageWidth;
  final double mainImageHeight;
  final bool isExpired;
  const DisplayAdImagesWidget({super.key,
  required this.isExpired,
  required this.mainImageHeight,
  required this.mainImageWidth,});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          // onTap:
          //     () => ref
          //     .read(navigationService)
          //     .pushNamedScreen(
          //   Routes.imageView,
          //   data: {
          //     'tag': widget.tagNetworkPop,
          //     'images': widget.adNetworkPop.images,
          //     'initialPage': widget
          //         .adNetworkPop
          //         .images
          //         .indexOf(mainImageUrl),
          //   },
          // ),
          child: Stack(
            children: [
              Image.asset(
                'assets/images/landingpage2.webp',
                width: mainImageWidth,
                height: mainImageHeight,
                fit: BoxFit.cover,
              ),
              if(isExpired)
                Container(
                    height:37.h,
                    width: mainImageWidth,
                    color:Colors.red,
                    padding:EdgeInsets.all(8),
                    child: Text('The ad is expired',
                      style:AppTextStyles.interBold
                          .copyWith(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    )
                )
            ],
          ),
        ),
        const SizedBox(height: 20),
        // SizedBox(
        //   width:
        //   mainImageWidth, // Ograniczenie szerokości kontenera miniatur do szerokości głównego obrazu
        //   height: 120, // Ustaw wysokość kontenera dla miniatur
        //   child: ListView.builder(
        //     scrollDirection: Axis.horizontal,
        //     itemCount: widget.adNetworkPop.images.length,
        //     itemBuilder: (context, index) {
        //       String imageUrl =
        //       widget.adNetworkPop.images[index];
        //       return GestureDetector(
        //         onTap: () {
        //           setState(() {
        //             mainImageUrl =
        //                 imageUrl; // Aktualizacja głównego obrazu na kliknięty obraz
        //           });
        //         },
        //         child: Padding(
        //           padding: EdgeInsets.only(
        //             left:
        //             index == 0
        //                 ? 0
        //                 : 10.0, // Nie dodawaj paddingu po lewej stronie pierwszego obrazu
        //             right:
        //             index == imageUrl.length - 1
        //                 ? 0
        //                 : 10.0, // Nie dodawaj paddingu po prawej stronie ostatniego obrazu
        //           ),
        //           child: Image.network(
        //             imageUrl,
        //             width: 120,
        //             height: 120,
        //             fit: BoxFit.cover,
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }
}
