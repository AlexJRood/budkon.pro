import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/add_offer/components/offer_images_upload_status_bar.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';

class ImageUploadWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  const ImageUploadWidget({super.key, this.isMobile = false});

  @override
  ConsumerState<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends ConsumerState<ImageUploadWidget> {
  late final FocusNode _titleFocusNode;
  late final FocusNode _descriptionFocusNode;

  final GlobalKey _titleFieldKey = GlobalKey();
  final GlobalKey _descriptionFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();

    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        _scrollToField(_titleFieldKey);
      }
    });

    _descriptionFocusNode.addListener(() {
      if (_descriptionFocusNode.hasFocus) {
        _scrollToField(_descriptionFieldKey);
      }
    });
  }

  void _scrollToField(GlobalKey key) {
    final fieldContext = key.currentContext;
    if (fieldContext != null) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      });
    }
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _handleContinue(BuildContext context) {
    final addOfferState = ref.read(addOfferProvider);

    if (addOfferState.imageItems.length < 4) {
      final snackBar = Customsnackbar().showSnackBar(
        "Warning".tr,
        'must_add_at_least_4_photos'.tr,
        'warning'.tr,
            () {},
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (addOfferState.titleController.text.isEmpty) {
      final snackBar = Customsnackbar().showSnackBar(
        "Warning".tr,
        'Title Cant be Empty'.tr,
        'warning'.tr,
            () {},
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (addOfferState.descriptionController.text.isEmpty) {
      final snackBar = Customsnackbar().showSnackBar(
        "Warning".tr,
        'Description Cant be Empty'.tr,
        'warning'.tr,
            () {},
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      final notifier = ref.read(addOfferProvider.notifier);
      FocusScope.of(context).unfocus();
      ref.read(progressProvider.notifier).state += 1;
      notifier.markUploadStatusAfterContinue(addOfferState.hasPendingUploads);
    }
  }

  Widget _buildUploadTile(
      BuildContext context,
      WidgetRef ref,
      ThemeColors theme,
      ) {
    return InkWell(
      onTap: () {
        ref.read(addOfferProvider.notifier).pickImage();
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: CustomColors.secondaryWidgetColor(context, ref),
          border: Border.all(
            color: CustomColors.secondaryWidgetColor(context, ref),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AppIcons.camera(
            width: 30,
            height: 30,
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(
      BuildContext context,
      WidgetRef ref,
      AddOfferImageItem item,
      int index,
      ) {
    final addOfferState = ref.watch(addOfferProvider);
    final notifier = ref.read(addOfferProvider.notifier);
    final isMain = index == 0;

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: MemoryImage(item.previewBytes),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (item.isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(110),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: item.progress > 0 ? item.progress : null,
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(item.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (item.hasError)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(140),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: IconButton(
                  tooltip: 'Retry upload'.tr,
                  onPressed: () {
                    notifier.retryImageUpload(item.localId);
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ),
            ),
          ),
        Positioned(
          top: 5,
          left: 5,
          child: InkWell(
            onTap: () => notifier.setMainImageIndex(index),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isMain
                    ? Colors.amber.withAlpha(220)
                    : Colors.black.withAlpha(130),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMain ? Icons.star : Icons.star_border,
                size: 14,
                color: isMain ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(190),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.black,
                size: 12,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              onPressed: () {
                if (addOfferState.imageItems.length > 1) {
                  notifier.removeImage(index);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('must_add_at_least_1_photo'.tr),
                    ),
                  );
                }
              },
            ),
          ),
        ),
        if (isMain)
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(130),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Main photo'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final addOfferState = ref.watch(addOfferProvider);

    final mobilepadding = MediaQuery.of(context).size.width <= 500
        ? 15.0
        : MediaQuery.of(context).size.width / 8;

    final dynamicPadding = widget.isMobile
        ? mobilepadding
        : MediaQuery.of(context).size.width / 7;

    final mediaWrap = Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        ...List.generate(
          addOfferState.imageItems.length,
              (index) => _buildImageTile(
            context,
            ref,
            addOfferState.imageItems[index],
            index,
          ),
        ),
        _buildUploadTile(context, ref, theme),
        if (addOfferState.imageItems.length == 10)
          SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Do you want to add more than 10 photos".tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryBackgroundTextColor,
                  ),
                ),
                const SizedBox(height: 5),
                SettingsButton(
                  isPc: true,
                  buttonheight: 40,
                  onTap: () {},
                  text: "Go Pro".tr,
                ),
              ],
            ),
          ),
      ],
    );
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final bottomBar = BottomBarSize.resolve(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          dynamicPadding,
          0,
          dynamicPadding,
          keyboard + bottomBar + 40,),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryBackgroundTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow the steps to complete the form'.tr,
              style: TextStyle(
                fontSize: 14,
                color: theme.primaryBackgroundTextColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Media'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.primaryBackgroundTextColor,
              ),
            ),
            const SizedBox(height: 8),
            mediaWrap,
            if (addOfferState.hasAnyImages) ...[
              const SizedBox(height: 10),
              const OfferImagesUploadStatusBar(
                compact: false,
                showWhenComplete: true,
              ),
            ],
            if (widget.isMobile) ...[
              const SizedBox(height: 20),
              Text(
                '${"Optimal dimensions".tr} 320 * 410px',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.primaryBackgroundTextColor,
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                '${"Optimal dimensions".tr} 1920 * 1080px',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.primaryBackgroundTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CustomElevatedButton(
                    backgroundColor: Colors.transparent,
                    borderColor: theme.primaryBackgroundTextColor,
                    textColor: theme.primaryBackgroundTextColor,
                    icon: Icons.add,
                    borderRadius: 5,
                    onTap: () {
                      ref.read(addOfferProvider.notifier).pickImage();
                    },
                    isicon: true,
                    text: 'Upload photos'.tr,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withAlpha(16),
                      borderRadius: BorderRadius.circular(8),
                      border:
                      Border.all(color: Colors.greenAccent.withAlpha(70)),
                    ),
                    child: Text(
                      'You can drag and drop images anywhere in this form.'.tr,
                      style: TextStyle(
                        color: theme.primaryBackgroundTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'General Information'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.primaryBackgroundTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    key: _titleFieldKey,
                    child: GradientTextField(
                      focusNode: _titleFocusNode,
                      reqNode: _descriptionFocusNode,
                      controller: addOfferState.titleController,
                      hintText: "Title Of The Ad".tr,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_descriptionFocusNode);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    key: _descriptionFieldKey,
                    child: GradientTextField(
                      maxLines: 5,
                      focusNode: _descriptionFocusNode,
                      controller: addOfferState.descriptionController,
                      hintText: "Description".tr,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        _handleContinue(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(progressProvider.notifier).state -= 1;
                  },
                  child: Text(
                    'Back'.tr,
                    style: TextStyle(color: theme.primaryBackgroundTextColor),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 250,
                  child: SettingsButton(
                    isPc: true,
                    buttonheight: 50,
                    onTap: () {
                      _handleContinue(context);
                    },
                    text: "Continue".tr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}