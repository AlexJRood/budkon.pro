import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/screens/feed/provider/feed_pop/user_feedback_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class AskUserWidget extends ConsumerWidget {
  final double paddingDynamic;
  final bool isTablet;

  AskUserWidget({
    super.key,
    required this.paddingDynamic,
    this.isTablet = false,
  });

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicVerticalPadding = paddingDynamic / 2;
    final theme = ref.watch(themeColorsProvider);
    final feedback = ref.read(userFeedbackProvider.notifier);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: paddingDynamic,
          vertical: dynamicVerticalPadding,
        ),
        child: isTablet
            ? Column(
                children: [
                  _askUserImage(),
                  const SizedBox(height: 30),
                  _askUserForm(context, theme, feedback),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _askUserImage(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: _askUserForm(context, theme, feedback),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _askUserImage() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/images/landingpage.webp',
            width: isTablet ? 500 : 600,
            height: isTablet ? 400 : 529,
            fit: BoxFit.cover,
            cacheWidth: 600,
          ),
        ),
      );

  Widget _askUserForm(context, theme, feedback) => Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment:
              isTablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              'Still haven’t found what\nyou’re looking for?'.tr,
              textAlign: isTablet ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: isTablet ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 20),

            // --- FIRST + LAST NAME ---
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CoreTextFormField(
                      label: 'First Name'.tr,
                      controller: feedback.firstNameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name'.tr;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: CoreTextFormField(
                      label: 'Last Name'.tr,
                      controller: feedback.lastNameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your last name'.tr;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- PHONE ---
            CoreTextFormField(
              label: 'Phone Number'.tr,
              controller: feedback.phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 20),

            // --- EMAIL ---
            CoreTextFormField(
              label: 'Email Address'.tr,
              controller: feedback.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) {
                  return 'Please enter your email address'.tr;
                }
                if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                    .hasMatch(v)) {
                  return 'Please enter a valid email address'.tr;
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // --- NOTES ---
            CoreTextFormField(
              label: 'Notes'.tr,
              controller: feedback.descriptionController,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) {
                  return 'Please enter some notes'.tr;
                }
                if (v.length < 10) {
                  return 'Notes must be at least 10 characters long'.tr;
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // --- SUBMIT ---
            SizedBox(
              height: 48,
              width: isTablet ? double.infinity : null,
              child: CoreFilledButton(
                onPressed: () {
                  final form = _formKey.currentState;
                  if (form == null) return;

                  if (form.validate()) {
                    feedback.submitUserFeedback();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Form submitted successfully'.tr),
                      ),
                    );
                  }
                },
                child: Text(
                  'Submit'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
