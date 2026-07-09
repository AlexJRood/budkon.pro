import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';

import 'package:get/get_utils/get_utils.dart';

class AskUserWidgetMobile extends ConsumerWidget {
  const AskUserWidgetMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final formKey = GlobalKey<FormState>();
    return SizedBox(
      height: 900,
      child: Stack(
        children: [
          Image.asset(
            'assets/images/landingpage.webp',
            height: 413,
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 240,
            child: Container(
              height: 750,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: CustomBackgroundGradients.landingpagebackground(
                    context, ref),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(6),
                  topLeft: Radius.circular(6),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Still haven’t found what you’re looking for?'.tr,
                        style: TextStyle(
                          color:
                              CustomColors.landingPageTextColor(context, ref),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'First Name'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Last Name'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number'.tr;
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit phone number'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email'.tr;
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Notes'.tr,
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some notes'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(100, 48),
                          backgroundColor: AppColors.redBeige,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Form submitted successfully'.tr)),
                            );
                          }
                        },
                        child: Text(
                          'Submit'.tr,
                          style: TextStyle(
                              color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
