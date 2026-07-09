import 'dart:async';
import 'package:portal/portal_urls.dart';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/common/shared_widgets/country_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';

final addOfferProvider = StateNotifierProvider<AddOfferNotifier, AddOfferState>(
  (ref) => AddOfferNotifier(),
);
enum AddOfferSubmitResult {
  success,
  notLoggedIn,
  emptyTitle,
  emptyDescription,
  notEnoughImages,
  pendingUploads,
  failedUploads,
  notEnoughUploadedImages,
  failed,
}
double calculatePricePerMeter(String price, String squareFootage) {
  if (price.isNotEmpty && squareFootage.isNotEmpty) {
    final priceValue = double.tryParse(price.replaceAll(',', '.')) ?? 0;
    final squareFootageValue =
        double.tryParse(squareFootage.replaceAll(',', '.')) ?? 0;
    if (squareFootageValue > 0) {
      return priceValue / squareFootageValue;
    }
  }
  return 0;
}

class AddOfferImageItem {
  static const Object _sentinel = Object();

  final String localId;
  final Uint8List previewBytes;
  final String originalName;
  final bool isUploading;
  final double progress;
  final String? uploadedUrl;
  final int? tempImageId;
  final String? error;

  const AddOfferImageItem({
    required this.localId,
    required this.previewBytes,
    required this.originalName,
    this.isUploading = false,
    this.progress = 0,
    this.uploadedUrl,
    this.tempImageId,
    this.error,
  });

  bool get isUploaded => uploadedUrl != null && uploadedUrl!.isNotEmpty;
  bool get hasError => error != null && error!.trim().isNotEmpty;

  AddOfferImageItem copyWith({
    String? localId,
    Uint8List? previewBytes,
    String? originalName,
    bool? isUploading,
    double? progress,
    Object? uploadedUrl = _sentinel,
    Object? tempImageId = _sentinel,
    Object? error = _sentinel,
  }) {
    return AddOfferImageItem(
      localId: localId ?? this.localId,
      previewBytes: previewBytes ?? this.previewBytes,
      originalName: originalName ?? this.originalName,
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      uploadedUrl:
          uploadedUrl == _sentinel ? this.uploadedUrl : uploadedUrl as String?,
      tempImageId:
          tempImageId == _sentinel ? this.tempImageId : tempImageId as int?,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

class AddOfferFilterCacheNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  AddOfferFilterCacheNotifier(this.ref) : super({});

  void addFilter(String key, dynamic value) {
    state = {...state, key: value};

    final notifier = ref.read(addOfferProvider.notifier);
    final currentState = notifier.state;
    final controller = TextEditingController(text: value.toString());

    switch (key) {
      case 'city':
        notifier.state = currentState.copyWith(cityController: controller);
        break;
      case 'district':
        notifier.state = currentState.copyWith(stateController: controller);
        break;
      case 'country':
        notifier.state = currentState.copyWith(countryController: controller);
        break;
      case 'zipcode':
        notifier.state = currentState.copyWith(zipcodeController: controller);
        break;
      case 'street':
        notifier.state = currentState.copyWith(streetController: controller);
        break;
      default:
        debugPrint("Unknown filter key: $key");
    }
  }
}

final addOfferFilterProvider =
    StateNotifierProvider<AddOfferFilterCacheNotifier, Map<String, dynamic>>(
      (ref) => AddOfferFilterCacheNotifier(ref),
    );

class AddOfferNotifier extends StateNotifier<AddOfferState> {
  AddOfferNotifier() : super(AddOfferState());

  final SecureStorage secureStorage = SecureStorage();

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  void updateCountry(DropDownCountry country) {
    state = state.copyWith(country: country);
  }


  void markUploadStatusAfterContinue (bool value) {
    state = state.copyWith(showUploadStatusAfterContinue: value);
  }
  void resetForm() {
    state.dispose();
    state = AddOfferState();
  }
  void _updateImageItem(
  String localId,
  AddOfferImageItem Function(AddOfferImageItem current) updater,
) {
  final updated = state.imageItems.map((item) {
    if (item.localId == localId) {
      return updater(item);
    }
    return item;
  }).toList();

  state = state.copyWith(imageItems: updated);

  if (!state.hasPendingUploads && state.showUploadStatusAfterContinue) {
    state = state.copyWith(showUploadStatusAfterContinue: false);
  }
}

  TextEditingController _controller(dynamic value) {
    return TextEditingController(text: value?.toString() ?? '');
  }

  String _generateLocalId() => DateTime.now().microsecondsSinceEpoch.toString();

  int _maxAllowedImages(bool isProUser) => isProUser ? 9999 : 10;

  bool _isAllowedImageName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, String> _authHeaders() {
    final headers = <String, String>{};
    if (ApiServices.token != null && ApiServices.token!.isNotEmpty) {
      headers['Authorization'] = 'Token ${ApiServices.token}';
    }
    return headers;
  }

  void updateField(String field, dynamic value) {
    switch (field) {
      case 'country':
        state = state.copyWith(country: value as DropDownCountry?);
        break;
      case 'distanceFilter':
        state = state.copyWith(
          distanceFilterController: _controller(value),
        );
        break;
      case 'title':
        state = state.copyWith(titleController: _controller(value));
        break;
      case 'access':
        state = state.copyWith(accessController: _controller(value));
        break;
      case 'area':
        state = state.copyWith(areaController: _controller(value));
        break;
      case 'description':
        state = state.copyWith(descriptionController: _controller(value));
        break;
      case 'price':
        state = state.copyWith(priceController: _controller(value));
        break;
      case 'floor':
        state = state.copyWith(floorController: _controller(value));
        break;
      case 'totalFloors':
        state = state.copyWith(totalFloorsController: _controller(value));
        break;
      case 'street':
        state = state.copyWith(streetController: _controller(value));
        break;
      case 'city':
        state = state.copyWith(cityController: _controller(value));
        break;
      case 'state':
        state = state.copyWith(stateController: _controller(value));
        break;
      case 'zipcode':
        state = state.copyWith(
          zipcodeController: _controller(_limitZipcode(value?.toString() ?? '')),
        );
        break;
      case 'rooms':
        state = state.copyWith(roomsController: _controller(value));
        break;
      case 'bathrooms':
        state = state.copyWith(bathroomsController: _controller(value));
        break;
      case 'squareFootage':
        state = state.copyWith(squareFootageController: _controller(value));
        break;
      case 'lotSize':
        state = state.copyWith(lotSizeController: _controller(value));
        break;
      case 'estateType':
        state = state.copyWith(estateTypeController: _controller(value));
        break;
      case 'buildingType':
        state = state.copyWith(buildingTypeController: _controller(value));
        break;
      case 'currency':
        state = state.copyWith(currencyController: _controller(value));
        break;
      case 'propertyForm':
        state = state.copyWith(propertyFormController: _controller(value));
        break;
      case 'marketType':
        state = state.copyWith(marketTypeController: _controller(value));
        break;
      case 'offerType':
        state = state.copyWith(offerTypeController: _controller(value));
        break;
      case 'countryName':
        state = state.copyWith(countryController: _controller(value));
        break;
      case 'phoneNumber':
        state = state.copyWith(phoneNumberController: _controller(value));
        break;
      case 'heatingType':
        state = state.copyWith(heatingTypeController: _controller(value));
        break;
      case 'buildYear':
        state = state.copyWith(buildYearController: _controller(value));
        break;
      case 'buildingMaterial':
        state = state.copyWith(buildingMaterialController: _controller(value));
        break;
      case 'latitude':
        state = state.copyWith(latitudeController: _controller(value));
        break;
      case 'longitude':
        state = state.copyWith(longitudeController: _controller(value));
        break;
      case 'design':
        state = state.copyWith(designController: _controller(value));
        break;
      case 'imagesData':
        final bytes = (value as List<Uint8List>? ?? []);
        state = state.copyWith(
          imageItems: bytes
              .asMap()
              .entries
              .map(
                (entry) => AddOfferImageItem(
                  localId: '${_generateLocalId()}_${entry.key}',
                  previewBytes: entry.value,
                  originalName: 'image_${entry.key}.jpg',
                ),
              )
              .toList(),
        );
        break;
      case 'mainImageIndex':
        state = state.copyWith(mainImageIndex: value as int?);
        break;
      case 'isLoading':
        state = state.copyWith(isLoading: value as bool?);
        break;
      case 'statusMessages':
        state = state.copyWith(statusMessages: value as List<String>?);
        break;
      case 'balcony':
        state = state.copyWith(balconyController: _controller(value));
        break;
      case 'terrace':
        state = state.copyWith(terraceController: _controller(value));
        break;
      case 'sauna':
        state = state.copyWith(saunaController: _controller(value));
        break;
      case 'jacuzzi':
        state = state.copyWith(jacuzziController: _controller(value));
        break;
      case 'basement':
        state = state.copyWith(basementController: _controller(value));
        break;
      case 'elevator':
        state = state.copyWith(elevatorController: _controller(value));
        break;
      case 'garden':
        state = state.copyWith(gardenController: _controller(value));
        break;
      case 'airConditioning':
        state = state.copyWith(airConditioningController: _controller(value));
        break;
      case 'garage':
        state = state.copyWith(garageController: _controller(value));
        break;
      case 'parkingSpace':
        state = state.copyWith(parkingSpaceController: _controller(value));
        break;
      case 'current':
        state = state.copyWith(currentController: _controller(value));
        break;
      case 'gas':
        state = state.copyWith(gasController: _controller(value));
        break;
      case 'position':
        state = state.copyWith(positionController: _controller(value));
        break;
      case 'lightning':
        state = state.copyWith(lightningController: _controller(value));
        break;
      case 'energyCertificate':
        state = state.copyWith(
          energyCertificateController: _controller(value),
        );
        break;
      case 'advertiser':
        state = state.copyWith(advertiserTypeController: _controller(value));
        break;
      case 'sewers':
        state = state.copyWith(sewersController: _controller(value));
        break;
      case 'water':
        state = state.copyWith(waterController: _controller(value));
        break;
      case 'phone':
        state = state.copyWith(phoneController: _controller(value));
        break;
      case 'cesspool':
        state = state.copyWith(cesspoolController: _controller(value));
        break;
    }

    log("Updated field: $field with value: $value");
  }

  void toggleFeature(String field) {
    switch (field) {
      case 'sauna':
        updateField(
          'sauna',
          state.saunaController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'elevator':
        updateField(
          'elevator',
          state.elevatorController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'gym':
        updateField(
          'garage',
          state.garageController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'airConditioning':
        updateField(
          'airConditioning',
          state.airConditioningController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'garden':
        updateField(
          'garden',
          state.gardenController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'basement':
        updateField(
          'basement',
          state.basementController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'current':
        updateField(
          'current',
          state.currentController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'gas':
        updateField(
          'gas',
          state.gasController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'sewers':
        updateField(
          'sewers',
          state.sewersController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'water':
        updateField(
          'water',
          state.waterController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'phone':
        updateField(
          'phone',
          state.phoneController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
      case 'cesspool':
        updateField(
          'cesspool',
          state.cesspoolController.text == 'Yes' ? 'No' : 'Yes',
        );
        break;
    }
  }

  void clearState() {
    state.stateController.clear();
  }

  void cleaCity() {
    state.cityController.clear();
  }

  bool _convertTextToBoolean(String text) {
    final lowerText = text.toLowerCase().trim();
    return lowerText == 'yes' ||
        lowerText == 'true' ||
        lowerText == '1' ||
        lowerText == 'on' ||
        lowerText == 'enabled';
  }

  String _limitZipcode(String zipcode) {
    final cleanZipcode = zipcode.replaceAll(RegExp(r'\D'), '');
    return cleanZipcode.length > 5
        ? cleanZipcode.substring(0, 5)
        : cleanZipcode;
  }

  Future<void> pickImage({bool isProUser = false}) async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isEmpty) return;

      final validImages = images
          .where((image) => _isAllowedImageName(image.name))
          .toList();

      if (validImages.isEmpty) {
        debugPrint('No supported image files selected.');
        return;
      }

      final bytesList = await Future.wait(
        validImages.map((image) => image.readAsBytes()),
      );

      await _appendImagesAndStartUpload(
        bytesList: bytesList,
        originalNames: validImages.map((e) => e.name).toList(),
        isProUser: isProUser,
      );
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> addDroppedXFiles(
    List<XFile> files, {
    bool isProUser = false,
  }) async {
    try {
      if (files.isEmpty) return;

      final validFiles = files
          .where((file) => _isAllowedImageName(file.name))
          .toList();

      if (validFiles.isEmpty) {
        debugPrint('No supported dropped files.');
        return;
      }

      final bytesList = await Future.wait(
        validFiles.map((file) => file.readAsBytes()),
      );

      await _appendImagesAndStartUpload(
        bytesList: bytesList,
        originalNames: validFiles.map((e) => e.name).toList(),
        isProUser: isProUser,
      );
    } catch (e) {
      debugPrint("Error handling dropped XFiles: $e");
    }
  }

  Future<void> _appendImagesAndStartUpload({
    required List<Uint8List> bytesList,
    required List<String> originalNames,
    bool isProUser = false,
  }) async {
    if (bytesList.isEmpty) return;

    final maxAllowed = _maxAllowedImages(isProUser);
    final remainingSlots = maxAllowed - state.imageItems.length;

    if (remainingSlots <= 0) {
      debugPrint('Image limit reached.');
      return;
    }

    final acceptedBytes = bytesList.take(remainingSlots).toList();
    final acceptedNames = originalNames.take(remainingSlots).toList();

    final newItems = <AddOfferImageItem>[];
    for (var i = 0; i < acceptedBytes.length; i++) {
      newItems.add(
        AddOfferImageItem(
          localId: '${_generateLocalId()}_$i',
          previewBytes: acceptedBytes[i],
          originalName: acceptedNames[i],
          isUploading: true,
          progress: 0,
        ),
      );
    }

    state = state.copyWith(
      imageItems: [...state.imageItems, ...newItems],
    );

    for (final item in newItems) {
      unawaited(_uploadSingleImage(item.localId));
    }
  }

  AddOfferImageItem? _findItemByLocalId(String localId) {
    for (final item in state.imageItems) {
      if (item.localId == localId) return item;
    }
    return null;
  }


  Future<void> _uploadSingleImage(String localId) async {
    final item = _findItemByLocalId(localId);
    if (item == null) return;

    try {
      final dio = Dio();

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          item.previewBytes,
          filename:
              item.originalName.isNotEmpty ? item.originalName : '$localId.jpg',
        ),
        'session_id': state.uploadSessionId,
      });

      final response = await dio.post(
        PortalUrls.advertisementsTempImageUpload,
        data: formData,
        options: Options(headers: _authHeaders()),
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          final progress = sent / total;
          _updateImageItem(
            localId,
            (current) => current.copyWith(progress: progress),
          );
        },
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      _updateImageItem(
        localId,
        (current) => current.copyWith(
          isUploading: false,
          progress: 1,
          uploadedUrl: data['file_url']?.toString(),
          tempImageId: _toInt(data['id']),
          error: null,
        ),
      );
    } catch (e) {
      _updateImageItem(
        localId,
        (current) => current.copyWith(
          isUploading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> retryImageUpload(String localId) async {
    final item = _findItemByLocalId(localId);
    if (item == null) return;

    _updateImageItem(
      localId,
      (current) => current.copyWith(
        isUploading: true,
        progress: 0,
        uploadedUrl: null,
        tempImageId: null,
        error: null,
      ),
    );

    await _uploadSingleImage(localId);
  }

  Future<void> removeImage(int index) async {
    if (index < 0 || index >= state.imageItems.length) return;

    final item = state.imageItems[index];
    final updatedItems = [...state.imageItems]..removeAt(index);

    state = state.copyWith(
      imageItems: updatedItems,
      mainImageIndex: updatedItems.isEmpty ? null : 0,
    );

    if (item.tempImageId != null) {
      try {
        final dio = Dio();
        await dio.delete(
          PortalUrls.advertisementsTempImageDelete(item.tempImageId!),
          options: Options(headers: _authHeaders()),
        );
      } catch (e) {
        debugPrint('Error deleting temporary image: $e');
      }
    }
    
  if (!state.hasPendingUploads && state.showUploadStatusAfterContinue) {
    state = state.copyWith(showUploadStatusAfterContinue: false);
  }
  }

  void setMainImageIndex(int index) {
    if (index < 0 || index >= state.imageItems.length) return;
    if (index == 0) {
      state = state.copyWith(mainImageIndex: 0);
      return;
    }

    final updated = [...state.imageItems];
    final selected = updated.removeAt(index);
    updated.insert(0, selected);

    state = state.copyWith(
      imageItems: updated,
      mainImageIndex: 0,
    );
  }



  Future<AddOfferSubmitResult> sendData(BuildContext context, WidgetRef ref) async {
  debugPrint('📤 Starting sendData process...');

  final navigator = Navigator.of(context, rootNavigator: true);

  if (state.titleController.text.trim().isEmpty) {
  return AddOfferSubmitResult.emptyTitle;
  }

  if (state.descriptionController.text.trim().isEmpty) {
  return AddOfferSubmitResult.emptyDescription;
  }

  if (state.imageItems.length < 4) {
  return AddOfferSubmitResult.notEnoughImages;
  }

  if (state.hasPendingUploads) {
  return AddOfferSubmitResult.pendingUploads;
  }

  if (state.hasFailedUploads) {
  return AddOfferSubmitResult.failedUploads;
  }

  if (state.uploadedImageUrls.length < 4) {
  return AddOfferSubmitResult.notEnoughUploadedImages;
  }

  if (ApiServices.token == null) {
  return AddOfferSubmitResult.notLoggedIn;
  }

  if (!context.mounted) {
  return AddOfferSubmitResult.failed;
  }

  _showLoadingDialog(context, ref, 'publishing_advertisement'.tr);

  state = state.copyWith(
  isLoading: true,
  statusMessages: ['Validating data'],
  );

  try {
  state = state.copyWith(statusMessages: ['Checking data']);
  debugPrint('🔍 Status: Checking data');

  final rawPricePerMeter = calculatePricePerMeter(
  state.priceController.text,
  state.squareFootageController.text,
  );

  final pricePerMeter = rawPricePerMeter.toStringAsFixed(2);

  final squareFootageText = state.squareFootageController.text
      .replaceAll(' ', '')
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9.]'), '');

  final formData = FormData.fromMap({
  'title': state.titleController.text.trim(),
  'description': state.descriptionController.text.trim(),
  'price': state.priceController.text.replaceAll(RegExp(r'\D'), ''),
  'estate_type': state.estateTypeController.text,
  'building_type': state.buildingTypeController.text,
  'price_per_meter': pricePerMeter,
  'floor': state.floorController.text.replaceAll(RegExp(r'\D'), ''),
  'total_floors':
  state.totalFloorsController.text.replaceAll(RegExp(r'\D'), ''),
  'currency': state.currencyController.text,
  'street': state.streetController.text,
  'phone_number':
  state.phoneNumberController.text.replaceAll(RegExp(r'\D'), ''),
  'city': state.cityController.text,
  'country': state.countryController.text,
  'state': state.stateController.text,
  'zipcode': _limitZipcode(state.zipcodeController.text),
  'rooms': state.roomsController.text.replaceAll(RegExp(r'\D'), ''),
  'heating_type': state.heatingTypeController.text,
  'build_year':
  state.buildYearController.text.replaceAll(RegExp(r'\D'), ''),
  'bathrooms':
  state.bathroomsController.text.replaceAll(RegExp(r'\D'), ''),
  'square_footage': squareFootageText,
  'lot_size': state.lotSizeController.text.replaceAll(RegExp(r'\D'), ''),
  'property_form': state.propertyFormController.text,
  'market_type': state.marketTypeController.text,
  'offer_type': state.offerTypeController.text,
  'building_material': state.buildingMaterialController.text,
  'balcony': _convertTextToBoolean(state.balconyController.text),
  'terrace': _convertTextToBoolean(state.terraceController.text),
  'sauna': _convertTextToBoolean(state.saunaController.text),
  'jacuzzi': _convertTextToBoolean(state.jacuzziController.text),
  'basement': _convertTextToBoolean(state.basementController.text),
  'elevator': _convertTextToBoolean(state.elevatorController.text),
  'garden': _convertTextToBoolean(state.gardenController.text),
  'air_conditioning':
  _convertTextToBoolean(state.airConditioningController.text),
  'garage': _convertTextToBoolean(state.garageController.text),
  'parking_space':
  _convertTextToBoolean(state.parkingSpaceController.text),
  });

  for (final url in state.uploadedImageUrls) {
  formData.fields.add(MapEntry('images', url));
  }

  debugPrint('📦 ==== FORM DATA FIELDS ====');
  for (final field in formData.fields) {
  debugPrint('➡️ ${field.key}: ${field.value}');
  }

  state = state.copyWith(statusMessages: [
  'Checking data',
  'Sending data to server',
  ]);

  final response = await ApiServices.post(
  PortalUrls.addAdvertisement,
  hasToken: true,
  formData: formData,
  );

  if (navigator.canPop()) {
  navigator.pop();
  }

  debugPrint('📥 RESPONSE STATUS: ${response?.statusCode}');
  debugPrint('📥 RESPONSE DATA: ${response?.data}');

  if (response != null && response.statusCode == 201) {
  return AddOfferSubmitResult.success;
  }

  return AddOfferSubmitResult.failed;
  } catch (e, stackTrace) {
  debugPrint('🔥 Error while sending data: $e');
  debugPrint('📄 Stacktrace:\n$stackTrace');

  if (navigator.canPop()) {
  navigator.pop();
  }

  return AddOfferSubmitResult.failed;
  } finally {
  state = state.copyWith(isLoading: false);
  }
  }

  void _showLoadingDialog(BuildContext context, WidgetRef ref, String message) {
    final theme = ref.read(themeColorsProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: theme.dashboardContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.themeColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddOfferState {
  static const Object _sentinel = Object();

  final DropDownCountry? country;
  final TextEditingController distanceFilterController;
  final TextEditingController titleController;
  final TextEditingController designController;
  final TextEditingController positionController;
  final TextEditingController lightningController;
  final TextEditingController energyCertificateController;
  final TextEditingController appartmentNumberController;
  final TextEditingController contactNameController;
  final TextEditingController emailController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController floorController;
  final TextEditingController totalFloorsController;
  final TextEditingController streetController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipcodeController;
  final TextEditingController roomsController;
  final TextEditingController bathroomsController;
  final TextEditingController squareFootageController;
  final TextEditingController lotSizeController;
  final TextEditingController estateTypeController;
  final TextEditingController buildingTypeController;
  final TextEditingController currencyController;
  final TextEditingController propertyFormController;
  final TextEditingController marketTypeController;
  final TextEditingController offerTypeController;
  final TextEditingController countryController;
  final TextEditingController phoneNumberController;
  final TextEditingController heatingTypeController;
  final TextEditingController buildYearController;
  final TextEditingController buildingMaterialController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController balconyController;
  final TextEditingController terraceController;
  final TextEditingController saunaController;
  final TextEditingController jacuzziController;
  final TextEditingController basementController;
  final TextEditingController elevatorController;
  final TextEditingController gardenController;
  final TextEditingController airConditioningController;
  final TextEditingController garageController;
  final TextEditingController parkingSpaceController;
  final TextEditingController surfaceController;
  final TextEditingController pricePerM2Controller;
  final TextEditingController dimensionsController;
  final TextEditingController plotTypeController;
  final TextEditingController fenceController;
  final TextEditingController advertiserTypeController;
  final TextEditingController accessController;
  final TextEditingController areaController;
  final TextEditingController currentController;
  final TextEditingController gasController;
  final TextEditingController sewersController;
  final TextEditingController waterController;
  final TextEditingController phoneController;
  final TextEditingController cesspoolController;
  final bool showUploadStatusAfterContinue;
  final List<AddOfferImageItem> imageItems;
  final String uploadSessionId;
  final int? mainImageIndex;
  final bool isLoading;
  final List<String> statusMessages;

  List<Uint8List> get imagesData =>
      imageItems.map((item) => item.previewBytes).toList();

  List<String> get uploadedImageUrls => imageItems
      .where((item) => item.uploadedUrl != null && item.uploadedUrl!.isNotEmpty)
      .map((item) => item.uploadedUrl!)
      .toList();

  bool get hasAnyImages => imageItems.isNotEmpty;

  bool get shouldShowDeferredUploadStatusbar => showUploadStatusAfterContinue && hasPendingUploads;

  bool get hasPendingUploads => imageItems.any((item) => item.isUploading);

  bool get hasFailedUploads => imageItems.any((item) => item.hasError);

  int get totalImagesCount => imageItems.length;

  int get uploadedImagesCount =>
      imageItems.where((item) => item.isUploaded).length;

  int get pendingUploadsCount =>
      imageItems.where((item) => item.isUploading).length;

  int get failedUploadsCount =>
      imageItems.where((item) => item.hasError).length;

  double get uploadProgressValue {
    if (imageItems.isEmpty) return 0;

    double completed = 0;
    for (final item in imageItems) {
      if (item.isUploaded) {
        completed += 1;
      } else if (item.isUploading) {
        completed += item.progress.clamp(0.0, 1.0);
      }
    }

    return (completed / imageItems.length).clamp(0.0, 1.0);
  }

  AddOfferState({
    DropDownCountry? country,
    TextEditingController? distanceFilterController,
    TextEditingController? titleController,
    TextEditingController? designController,
    TextEditingController? positionController,
    TextEditingController? lightningController,
    TextEditingController? energyCertificateController,
    TextEditingController? appartmentNumberController,
    TextEditingController? contactNameController,
    TextEditingController? emailController,
    TextEditingController? descriptionController,
    TextEditingController? priceController,
    TextEditingController? floorController,
    TextEditingController? totalFloorsController,
    TextEditingController? streetController,
    TextEditingController? cityController,
    TextEditingController? stateController,
    TextEditingController? zipcodeController,
    TextEditingController? roomsController,
    TextEditingController? bathroomsController,
    TextEditingController? squareFootageController,
    TextEditingController? lotSizeController,
    TextEditingController? estateTypeController,
    TextEditingController? buildingTypeController,
    TextEditingController? currencyController,
    TextEditingController? propertyFormController,
    TextEditingController? marketTypeController,
    TextEditingController? offerTypeController,
    TextEditingController? countryController,
    TextEditingController? phoneNumberController,
    TextEditingController? heatingTypeController,
    TextEditingController? buildYearController,
    TextEditingController? buildingMaterialController,
    TextEditingController? latitudeController,
    TextEditingController? longitudeController,
    TextEditingController? balconyController,
    TextEditingController? terraceController,
    TextEditingController? saunaController,
    TextEditingController? jacuzziController,
    TextEditingController? basementController,
    TextEditingController? elevatorController,
    TextEditingController? gardenController,
    TextEditingController? airConditioningController,
    TextEditingController? garageController,
    TextEditingController? parkingSpaceController,
    TextEditingController? surfaceController,
    TextEditingController? pricePerM2Controller,
    TextEditingController? dimensionsController,
    TextEditingController? plotTypeController,
    TextEditingController? fenceController,
    TextEditingController? advertiserTypeController,
    TextEditingController? accessController,
    TextEditingController? areaController,
    TextEditingController? currentController,
    TextEditingController? gasController,
    TextEditingController? sewersController,
    TextEditingController? waterController,
    TextEditingController? phoneController,
    TextEditingController? cesspoolController,
    this.showUploadStatusAfterContinue = false,

    this.imageItems = const [],
    String? uploadSessionId,
    this.mainImageIndex,
    this.isLoading = false,
    this.statusMessages = const [],
  }) : country =
            country ??
                DropDownCountry(
                  name: 'Poland',
                  isoCode: 'PL',
                  phoneCode: '+48',
                ),
       distanceFilterController =
            distanceFilterController ?? TextEditingController(text: '0 km'),
       titleController = titleController ?? TextEditingController(),
       designController = designController ?? TextEditingController(),
       positionController =
            positionController ?? TextEditingController(text: 'Corner'),
       lightningController = lightningController ?? TextEditingController(),
       energyCertificateController =
            energyCertificateController ?? TextEditingController(),
       appartmentNumberController =
            appartmentNumberController ?? TextEditingController(),
       contactNameController = contactNameController ?? TextEditingController(),
       emailController = emailController ?? TextEditingController(),
       descriptionController = descriptionController ?? TextEditingController(),
       priceController = priceController ?? TextEditingController(),
       floorController = floorController ?? TextEditingController(),
       totalFloorsController =
            totalFloorsController ?? TextEditingController(),
       streetController = streetController ?? TextEditingController(),
       cityController = cityController ?? TextEditingController(),
       stateController = stateController ?? TextEditingController(),
       zipcodeController = zipcodeController ?? TextEditingController(),
       roomsController = roomsController ?? TextEditingController(),
       bathroomsController = bathroomsController ?? TextEditingController(),
       squareFootageController =
            squareFootageController ?? TextEditingController(),
       lotSizeController = lotSizeController ?? TextEditingController(),
       estateTypeController = estateTypeController ?? TextEditingController(),
       buildingTypeController =
            buildingTypeController ?? TextEditingController(),
       currencyController = currencyController ?? TextEditingController(),
       propertyFormController =
            propertyFormController ?? TextEditingController(),
       marketTypeController = marketTypeController ?? TextEditingController(),
       offerTypeController = offerTypeController ?? TextEditingController(),
       countryController =
            countryController ?? TextEditingController(text: 'Poland'),
       phoneNumberController = phoneNumberController ?? TextEditingController(),
       heatingTypeController = heatingTypeController ?? TextEditingController(),
       buildYearController = buildYearController ?? TextEditingController(),
       buildingMaterialController =
            buildingMaterialController ?? TextEditingController(),
       latitudeController = latitudeController ?? TextEditingController(),
       longitudeController = longitudeController ?? TextEditingController(),
       balconyController =
            balconyController ?? TextEditingController(text: 'Balcony'),
       terraceController =
            terraceController ?? TextEditingController(text: 'Terrace'),
       saunaController = saunaController ?? TextEditingController(text: 'No'),
       jacuzziController =
            jacuzziController ?? TextEditingController(text: 'No'),
       basementController =
            basementController ?? TextEditingController(text: 'No'),
       elevatorController =
            elevatorController ?? TextEditingController(text: 'No'),
       gardenController = gardenController ?? TextEditingController(text: 'No'),
       airConditioningController =
            airConditioningController ?? TextEditingController(text: 'No'),
       garageController = garageController ?? TextEditingController(text: 'No'),
       parkingSpaceController =
            parkingSpaceController ?? TextEditingController(text: 'Parking'),
       surfaceController = surfaceController ?? TextEditingController(),
       pricePerM2Controller = pricePerM2Controller ?? TextEditingController(),
       dimensionsController = dimensionsController ?? TextEditingController(),
       plotTypeController =
            plotTypeController ??
                TextEditingController(text: 'Agricultural'),
       fenceController = fenceController ?? TextEditingController(text: 'No'),
       advertiserTypeController =
            advertiserTypeController ?? TextEditingController(),
       accessController = accessController ?? TextEditingController(text: 'No'),
       areaController = areaController ?? TextEditingController(text: 'Urban'),
       currentController = currentController ?? TextEditingController(text: 'No'),
       gasController = gasController ?? TextEditingController(text: 'No'),
       sewersController = sewersController ?? TextEditingController(text: 'No'),
       waterController = waterController ?? TextEditingController(text: 'No'),
       phoneController = phoneController ?? TextEditingController(text: 'No'),
       cesspoolController =
            cesspoolController ?? TextEditingController(text: 'No'),
       uploadSessionId =
            uploadSessionId ??
                DateTime.now().microsecondsSinceEpoch.toString();



  AddOfferState copyWith({
    DropDownCountry? country,
    TextEditingController? distanceFilterController,
    TextEditingController? titleController,
    TextEditingController? designController,
    TextEditingController? positionController,
    TextEditingController? lightningController,
    TextEditingController? energyCertificateController,
    TextEditingController? appartmentNumberController,
    TextEditingController? contactNameController,
    TextEditingController? emailController,
    TextEditingController? descriptionController,
    TextEditingController? priceController,
    TextEditingController? floorController,
    TextEditingController? totalFloorsController,
    TextEditingController? streetController,
    TextEditingController? cityController,
    TextEditingController? stateController,
    TextEditingController? zipcodeController,
    TextEditingController? roomsController,
    TextEditingController? bathroomsController,
    TextEditingController? squareFootageController,
    TextEditingController? lotSizeController,
    TextEditingController? estateTypeController,
    TextEditingController? buildingTypeController,
    TextEditingController? currencyController,
    TextEditingController? propertyFormController,
    TextEditingController? marketTypeController,
    TextEditingController? offerTypeController,
    TextEditingController? countryController,
    TextEditingController? phoneNumberController,
    TextEditingController? heatingTypeController,
    TextEditingController? buildYearController,
    TextEditingController? buildingMaterialController,
    TextEditingController? latitudeController,
    TextEditingController? longitudeController,
    TextEditingController? balconyController,
    TextEditingController? terraceController,
    TextEditingController? saunaController,
    TextEditingController? jacuzziController,
    TextEditingController? basementController,
    TextEditingController? elevatorController,
    TextEditingController? gardenController,
    TextEditingController? airConditioningController,
    TextEditingController? garageController,
    TextEditingController? parkingSpaceController,
    TextEditingController? surfaceController,
    TextEditingController? pricePerM2Controller,
    TextEditingController? dimensionsController,
    TextEditingController? plotTypeController,
    TextEditingController? fenceController,
    TextEditingController? advertiserTypeController,
    TextEditingController? accessController,
    TextEditingController? areaController,
    TextEditingController? currentController,
    TextEditingController? gasController,
    TextEditingController? sewersController,
    TextEditingController? waterController,
    TextEditingController? phoneController,
    TextEditingController? cesspoolController,
    List<AddOfferImageItem>? imageItems,
    String? uploadSessionId,
    Object? mainImageIndex = _sentinel,
    bool? isLoading,
    List<String>? statusMessages,
    bool? showUploadStatusAfterContinue,
  }) {
    return AddOfferState(
      country: country ?? this.country,
      distanceFilterController:
          distanceFilterController ?? this.distanceFilterController,
      titleController: titleController ?? this.titleController,
      designController: designController ?? this.designController,
      positionController: positionController ?? this.positionController,
      lightningController: lightningController ?? this.lightningController,
      energyCertificateController:
          energyCertificateController ?? this.energyCertificateController,
      appartmentNumberController:
          appartmentNumberController ?? this.appartmentNumberController,
      contactNameController:
          contactNameController ?? this.contactNameController,
      emailController: emailController ?? this.emailController,
      descriptionController:
          descriptionController ?? this.descriptionController,
      priceController: priceController ?? this.priceController,
      floorController: floorController ?? this.floorController,
      totalFloorsController:
          totalFloorsController ?? this.totalFloorsController,
      streetController: streetController ?? this.streetController,
      cityController: cityController ?? this.cityController,
      stateController: stateController ?? this.stateController,
      zipcodeController: zipcodeController ?? this.zipcodeController,
      roomsController: roomsController ?? this.roomsController,
      bathroomsController: bathroomsController ?? this.bathroomsController,
      squareFootageController:
          squareFootageController ?? this.squareFootageController,
      lotSizeController: lotSizeController ?? this.lotSizeController,
      estateTypeController: estateTypeController ?? this.estateTypeController,
      buildingTypeController:
          buildingTypeController ?? this.buildingTypeController,
      currencyController: currencyController ?? this.currencyController,
      propertyFormController:
          propertyFormController ?? this.propertyFormController,
      marketTypeController: marketTypeController ?? this.marketTypeController,
      offerTypeController: offerTypeController ?? this.offerTypeController,
      countryController: countryController ?? this.countryController,
      phoneNumberController:
          phoneNumberController ?? this.phoneNumberController,
      heatingTypeController:
          heatingTypeController ?? this.heatingTypeController,
      buildYearController: buildYearController ?? this.buildYearController,
      buildingMaterialController:
          buildingMaterialController ?? this.buildingMaterialController,
      latitudeController: latitudeController ?? this.latitudeController,
      longitudeController: longitudeController ?? this.longitudeController,
      balconyController: balconyController ?? this.balconyController,
      terraceController: terraceController ?? this.terraceController,
      saunaController: saunaController ?? this.saunaController,
      jacuzziController: jacuzziController ?? this.jacuzziController,
      basementController: basementController ?? this.basementController,
      elevatorController: elevatorController ?? this.elevatorController,
      gardenController: gardenController ?? this.gardenController,
      airConditioningController:
          airConditioningController ?? this.airConditioningController,
      garageController: garageController ?? this.garageController,
      parkingSpaceController:
          parkingSpaceController ?? this.parkingSpaceController,
      surfaceController: surfaceController ?? this.surfaceController,
      pricePerM2Controller: pricePerM2Controller ?? this.pricePerM2Controller,
      dimensionsController: dimensionsController ?? this.dimensionsController,
      plotTypeController: plotTypeController ?? this.plotTypeController,
      fenceController: fenceController ?? this.fenceController,
      advertiserTypeController:
          advertiserTypeController ?? this.advertiserTypeController,
      accessController: accessController ?? this.accessController,
      areaController: areaController ?? this.areaController,
      currentController: currentController ?? this.currentController,
      gasController: gasController ?? this.gasController,
      sewersController: sewersController ?? this.sewersController,
      waterController: waterController ?? this.waterController,
      phoneController: phoneController ?? this.phoneController,
      cesspoolController: cesspoolController ?? this.cesspoolController,
      imageItems: imageItems ?? this.imageItems,
      uploadSessionId: uploadSessionId ?? this.uploadSessionId,
      mainImageIndex: identical(mainImageIndex, _sentinel)
          ? this.mainImageIndex
          : mainImageIndex as int?,
      isLoading: isLoading ?? this.isLoading,
      statusMessages: statusMessages ?? this.statusMessages,
      showUploadStatusAfterContinue: showUploadStatusAfterContinue ?? this.showUploadStatusAfterContinue,
    );
  }

  void dispose() {
    for (final c in <TextEditingController>[
      distanceFilterController,
      titleController,
      designController,
      positionController,
      lightningController,
      energyCertificateController,
      appartmentNumberController,
      contactNameController,
      emailController,
      descriptionController,
      priceController,
      floorController,
      totalFloorsController,
      streetController,
      cityController,
      stateController,
      zipcodeController,
      roomsController,
      bathroomsController,
      squareFootageController,
      lotSizeController,
      estateTypeController,
      buildingTypeController,
      currencyController,
      propertyFormController,
      marketTypeController,
      offerTypeController,
      countryController,
      phoneNumberController,
      heatingTypeController,
      buildYearController,
      buildingMaterialController,
      latitudeController,
      longitudeController,
      balconyController,
      terraceController,
      saunaController,
      jacuzziController,
      basementController,
      elevatorController,
      gardenController,
      airConditioningController,
      garageController,
      parkingSpaceController,
      surfaceController,
      pricePerM2Controller,
      dimensionsController,
      plotTypeController,
      fenceController,
      advertiserTypeController,
      accessController,
      areaController,
      currentController,
      gasController,
      sewersController,
      waterController,
      phoneController,
      cesspoolController,
    ]) {
      c.dispose();
    }
  }
}

class HoverStateNotifier extends StateNotifier<bool> {
  HoverStateNotifier() : super(false);
  void setHovered(bool hovered) => state = hovered;
}

final hoverStateProvider = StateNotifierProvider<HoverStateNotifier, bool>(
  (ref) => HoverStateNotifier(),
);

final addOfferErrorsProvider = StateProvider<Map<String, String>>((ref) => {});