import 'package:flutter/material.dart';
import 'package:core/theme/icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddNoteWidget extends StatelessWidget {
  const AddNoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon:
          AppIcons.iosArrowLeft(
            color: Color.fromRGBO(255, 255, 255, 1),
          )
        ),
        actions:  [
          AppIcons.check(
            color: Color.fromRGBO(255, 255, 255, 1),
          )
        ],
      ),
      body:  Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 20.h),
        child: Column(
          spacing: 20.h,
          children: [
            Text(
              '31 January 2025 at 13:17',
              style: TextStyle(
                fontSize: 14.sp,
                color: Color.fromRGBO(200, 200, 200, 0.6),
              ),
            ),
            TextField(
              maxLines: null,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
              ),
              decoration: InputDecoration(
                hintText: 'Write your note here...',
                hintStyle: TextStyle(
                  color: Color.fromRGBO(200, 200, 200, 0.6),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
