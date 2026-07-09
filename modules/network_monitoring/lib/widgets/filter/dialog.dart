import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/common/custom_error_handler.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

import 'package:core/platform/url.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:core/platform/api_services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:get/get_utils/get_utils.dart';

// 🔹 Riverpod loading state for the Save action
final saveSearchLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class SaveSearchDialog extends ConsumerStatefulWidget {
  const SaveSearchDialog({super.key});

  @override
  _SaveSearchDialogState createState() => _SaveSearchDialogState();
}

class _SaveSearchDialogState extends ConsumerState<SaveSearchDialog> {
  final TextEditingController savedSearchTitleController =
      TextEditingController();
  final TextEditingController savedSearchDescriptionController =
      TextEditingController();
  final TextEditingController tagsController = TextEditingController();

  String? selectedAvatar;
  Uint8List? customAvatarData;

  final ImagePicker _picker = ImagePicker();

  final List<String> defaultAvatars = const [
    'assets/images/landingpage.webp',
    'assets/images/landingpage.webp',
    'assets/images/landingpage2.webp',
    'assets/images/landingpage.webp',
    'assets/images/landingpage.webp',
    'assets/images/landingpage2.webp',
  ];

  Future<void> pickCustomAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      setState(() {
        customAvatarData = imageData;
        selectedAvatar = null;
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    savedSearchTitleController.dispose();
    savedSearchDescriptionController.dispose();
    tagsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final isSaving = ref.watch(saveSearchLoadingProvider);
    final flatBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.light),
    );

    return AlertDialog(
      backgroundColor: theme.adPopBackground,
      title: Text(
        'Save Search'.tr,
        style: AppTextStyles.interBold.copyWith(color: theme.textColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            TextField(
              style: TextStyle(color: theme.textColor),
              controller: savedSearchTitleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.textFieldColor,
                labelText: 'Title'.tr,
                labelStyle: TextStyle(color: theme.textColor),
                floatingLabelStyle: TextStyle(color: theme.textColor),
                enabledBorder: flatBorder,
                disabledBorder: flatBorder,
                focusedBorder: flatBorder,
                border: flatBorder,
              ),
            ),
            TextField(
              style: TextStyle(color: theme.textColor),
              controller: savedSearchDescriptionController,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.textFieldColor,
                labelText: 'Description'.tr,
                labelStyle: TextStyle(color: theme.textColor),
                floatingLabelStyle: TextStyle(color: theme.textColor),
                enabledBorder: flatBorder,
                disabledBorder: flatBorder,
                focusedBorder: flatBorder,
                border: flatBorder,
              ),
            ),
            TextField(
              style: TextStyle(color: theme.textColor),
              controller: tagsController,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.textFieldColor,
                labelText: 'Tags'.tr,
                labelStyle: TextStyle(color: theme.textColor),
                floatingLabelStyle: TextStyle(color: theme.textColor),
                enabledBorder: flatBorder,
                disabledBorder: flatBorder,
                focusedBorder: flatBorder,
                border: flatBorder,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Select Default Avatar:'.tr,
              style: AppTextStyles.interBold.copyWith(color: theme.textColor),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: AppIcons.iosArrowLeft(),
                  onPressed: _scrollLeft,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollController,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: pickCustomAvatar,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[300],
                            child: AppIcons.add(color: Colors.white),
                          ),
                        ),
                        ...defaultAvatars.map((avatarPath) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAvatar = avatarPath;
                                customAvatarData = null;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: CircleAvatar(
                                backgroundImage: AssetImage(avatarPath),
                                radius: 30,
                                child:
                                    selectedAvatar == avatarPath
                                        ? AppIcons.check(color: Colors.white)
                                        : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: AppIcons.iosArrowRight(),
                  onPressed: _scrollRight,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (selectedAvatar != null)
                    CircleAvatar(
                      backgroundImage: AssetImage(selectedAvatar!),
                      radius: 80,
                    ),
                  if (customAvatarData != null)
                    CircleAvatar(
                      backgroundImage: MemoryImage(customAvatarData!),
                      radius: 80,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        InkWell(
          onTap: () {
            Navigator.of(context).pop();
            // ref.read(navigationService).beamPop();
          },
          child: Container(
            height: 32,
            width: 120,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'Cancel'.tr,
                style: AppTextStyles.interMedium.copyWith(
                  color: theme.textColor,
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            if (ref.read(saveSearchLoadingProvider)) return; // guard double tap
            saveSearches();
          },
          child: Container(
            height: 32,
            width: 120,
            decoration: BoxDecoration(
              color: theme.themeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child:
                  isSaving
                      ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.themeTextColor,
                        ),
                      )
                      : Text(
                        'Save'.tr,
                        style: AppTextStyles.interMedium.copyWith(
                          color: theme.themeTextColor,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> saveSearches() async {
    // turn loading on
    ref.read(saveSearchLoadingProvider.notifier).state = true;

    try {
      final filterNotifier = ref.read(
        networkMonitoringFilterCacheProvider.notifier,
      );

      if (ApiServices.token == null) {
        if (kDebugMode) debugPrint('Authorization token not found'.tr);
        final warningSnackBar = Customsnackbar().showSnackBar(
          "Warning".tr,
          'Authorization token not found'.tr,
          "warning".tr,
          () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
        ScaffoldMessenger.of(context).showSnackBar(warningSnackBar);
        return;
      }

      final Map<String, dynamic> data = {
        'user_id': 1, // Replace with actual user ID
        'client_id': 1, // Replace with actual client ID
        'title': savedSearchTitleController.text,
        'description': savedSearchDescriptionController.text,
        'tags': tagsController.text,
        'filters': jsonEncode(filterNotifier.filters),
      };

      if (kDebugMode) debugPrint('Data to send: $data');

      final formData = FormData.fromMap(data);

      if (customAvatarData != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(
              customAvatarData!,
              filename: 'custom_avatar.png',
            ),
          ),
        );
      }

      final response = await ApiServices.post(
        URLs.savedSearch,
        hasToken: true,
        formData: formData,
      );

      if (response != null && response.statusCode == 201) {
        if (kDebugMode) debugPrint('Search saved successfully'.tr);
        if (mounted) {
          Navigator.pop(context);
          final successSnackBar = Customsnackbar().showSnackBar(
            "success".tr,
            'Search saved successfully'.tr,
            "success",
            () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(successSnackBar);
        }
      } else {
        debugPrint(
          'failed to save search ${response?.statusCode} / ${response?.statusMessage}',
        );
      }
    } catch (e) {
      debugPrint('failed to save search $e');
    } finally {
      // turn loading off (even on early returns, thanks to finally)
      ref.read(saveSearchLoadingProvider.notifier).state = false;
    }
  }
}

Future<void> saveSearch(BuildContext context, WidgetRef ref) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) => const SaveSearchDialog(),
  );
}
