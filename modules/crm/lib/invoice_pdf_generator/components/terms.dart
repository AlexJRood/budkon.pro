import 'package:flutter/material.dart';
import '../const.dart';


import 'package:get/get_utils/get_utils.dart';

// ignore: must_be_immutable
class Terms extends StatelessWidget {
  TextEditingController terms = TextEditingController();
   Terms({super.key,required this.terms});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 520,
      child: TextField(controller: terms,
        maxLines: 3, // For multiline text field
        decoration: CustomDecoration().customInputDecoration("Terms And Conditions".tr),
      ),
    );
  }
}
