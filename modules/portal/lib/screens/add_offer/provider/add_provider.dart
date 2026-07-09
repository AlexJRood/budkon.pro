import 'package:portal/portal_urls.dart';
// //Riverpod/add_provider.dart

// // ignore_for_file: use_build_context_synchronously

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_dropzone/flutter_dropzone.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:core/platform/route_constant.dart';
// import 'package:core/platform/url.dart';
// import 'package:core/theme/design.dart';
// import 'package:core/common/custom_error_handler.dart';
// import 'package:core/platform/navigation_service.dart';
// import 'package:core/theme/apptheme.dart';
// import 'package:core/platform/api_services.dart';
// import 'package:core/platform/secure_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';

// final addOfferProvider =
//     StateNotifierProvider<AddOfferNotifier, AddOfferState>((ref) {
//   return AddOfferNotifier();
// });

// // Dodajemy funkcję obliczającą cenę za metr kwadratowy
// double calculatePricePerMeter(String price, String squareFootage) {
//   if (price.isNotEmpty && squareFootage.isNotEmpty) {
//     double priceValue = double.tryParse(price) ?? 0;
//     double squareFootageValue = double.tryParse(squareFootage) ?? 0;
//     if (squareFootageValue > 0) {
//       return priceValue / squareFootageValue;
//     }
//   }
//   return 0;
// }

// class AddOfferNotifier extends StateNotifier<AddOfferState> {
//   AddOfferNotifier() : super(AddOfferState());

//   final SecureStorage secureStorage =
//       SecureStorage(); // Create an instance of SecureStorage
//   late DropzoneViewController dropzoneController;

//   Future<void> pickImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final List<XFile> images = await picker.pickMultiImage();
//       if (images.isNotEmpty) {
//         final List<Uint8List> newImagesData =
//         await Future.wait(images.map((image) => image.readAsBytes()));
//         state = state.copyWith(
//           imagesData: List.from(state.imagesData)..addAll(newImagesData),
//         );
//       }
//     } catch (e) {
//       print("Error picking images: $e");
//     }
//   }

//   Future<void> handleFileDrop(dynamic file, DropzoneViewController controller) async {
//     try {
//       if (file != null) {
//         final bytes = await controller.getFileData(file);

//         state = state.copyWith(
//           imagesData: List.from(state.imagesData)..add(bytes),
//         );
//       } else {
//         print("No file dropped.");
//       }
//     } catch (e) {
//       print("Error handling dropped file: $e");
//     }
//   }


//   //   Future<void> pickImage() async {
//   //   final ImagePicker picker = ImagePicker();
//   //   final List<XFile>? images = await picker.pickMultiImage();
//   //   if (images != null && images.isNotEmpty) {
//   //     final List<Uint8List> newImagesData = await Future.wait(images.map((image) => image.readAsBytes()));
//   //     state = state.copyWith(imagesData: List.from(state.imagesData)..addAll(newImagesData));
//   //   }
//   // }

//   void removeImage(int index) {
//     if (index >= 0 && index < state.imagesData.length) {
//       List<Uint8List> updatedImages = List.from(state.imagesData)
//         ..removeAt(index);
//       state = state.copyWith(imagesData: updatedImages);
//     }
//   }

//   void setMainImageIndex(int index) {
//     state = state.copyWith(mainImageIndex: index);
//     print('mainimageindex:${state.mainImageIndex}');
//     print('imagelength:${state.imagesData.length}');
//     Uint8List temp = state.imagesData[0];
//     state.imagesData[0] = state.imagesData[state.mainImageIndex!];
//     state.imagesData[state.mainImageIndex!] = temp;
//   }

//   void updateField(String fieldName, String? value) {
//     switch (fieldName) {
//       case 'currency':
//         state.currencyController.text = value ?? '';
//         break;
//       case 'title':
//         state.titleController.text = value ?? '';
//         break;
//       case 'description':
//         state.descriptionController.text = value ?? '';
//         break;
//       case 'price':
//         state.priceController.text = value ?? '';
//         break;
//       case 'estate_type':
//         state.estateTypeController.text = value ?? '';
//         break;
//       case 'building_type':
//         state.buildingTypeController.text = value ?? '';
//         break;
//       case 'floor':
//         state.floorController.text = value ?? '';
//         break;
//       case 'total_floors':
//         state.totalFloorsController.text = value ?? '';
//         break;
//       case 'street':
//         state.streetController.text = value ?? '';
//         break;
//       case 'phone_number':
//         state.phoneNumberController.text = value ?? '';
//         break;
//       case 'city':
//         state.cityController.text = value ?? '';
//         break;
//       case 'country':
//         state.countryController.text = value ?? '';
//         break;
//       case 'state':
//         state.stateController.text = value ?? '';
//         break;
//       case 'zipcode':
//         // Limit zipcode to 5 characters
//         String zipcode = (value ?? '').replaceAll(RegExp(r'\D'), '');
//         if (zipcode.length > 5) {
//           zipcode = zipcode.substring(0, 5);
//         }
//         state.zipcodeController.text = zipcode;
//         break;
//       case 'rooms':
//         state.roomsController.text = value ?? '';
//         break;
//       case 'heating_type':
//         state.heatingTypeController.text = value ?? '';
//         break;
//       case 'build_year':
//         state.buildYearController.text = value ?? '';
//         break;
//       case 'bathrooms':
//         state.bathroomsController.text = value ?? '';
//         break;
//       case 'square_footage':
//         state.squareFootageController.text = value ?? '';
//         break;
//       case 'lot_size':
//         state.lotSizeController.text = value ?? '';
//         break;
//       case 'property_form':
//         state.propertyFormController.text = value ?? '';
//         break;
//       case 'market_type':
//         state.marketTypeController.text = value ?? '';
//         break;
//       case 'offer_type':
//         state.offerTypeController.text = value ?? '';
//         break;
//       case 'building_material':
//         state.buildingMaterialController.text = value ?? '';
//         break;
//     }
//   }

//   Future<void> sendData(BuildContext context, WidgetRef ref) async {
//     if (state.titleController.text.isEmpty) {
//       final snackBar = Customsnackbar().showSnackBar(
//           "Warning", "description, currency and price are required.", "warning",
//           () {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       });
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);

//       return;
//     }

//     if (ApiServices.token == null) {
//       final snackBar = Customsnackbar().showSnackBar(
//           "Not logged in", "you need to login to post an ad", "warning", () {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       });
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);

//       ref.read(navigationService).pushNamedScreen(Routes.loginPop);

//       return;
//     }

//     state = state.copyWith(isLoading: true, statusMessages: ['Checking data']);

//     try {
//       state = state
//           .copyWith(statusMessages: ['Checking data', 'Compressing images']);

//       double pricePerMeter = calculatePricePerMeter(
//         state.priceController.text,
//         state.squareFootageController.text,
//       );
      

//       final formData = FormData.fromMap({
//         'title': state.titleController.text,
//         'description': state.descriptionController.text,
//         'price': state.priceController.text.replaceAll(RegExp(r'\D'), ''),
//         'estate_type': state.estateTypeController.text,
//         'building_type': state.buildingTypeController.text,
//         'price_per_meter': pricePerMeter.toString(),
//         'floor': state.floorController.text.replaceAll(RegExp(r'\D'), ''),
//         'total_floors':
//             state.totalFloorsController.text.replaceAll(RegExp(r'\D'), ''),
//         'currency': state.currencyController.text,
//         'street': state.streetController.text,
//         'phone_number':
//             state.phoneNumberController.text.replaceAll(RegExp(r'\D'), ''),
//         'city': state.cityController.text,
//         'country': state.countryController.text,
//         'state': state.stateController.text,
//         'zipcode': state.zipcodeController.text.length > 5 
//             ? state.zipcodeController.text.substring(0, 5)
//             : state.zipcodeController.text,
//         'rooms': state.roomsController.text.replaceAll(RegExp(r'\D'), ''),
//         'heating_type': state.heatingTypeController.text,
//         'build_year':
//             state.buildYearController.text.replaceAll(RegExp(r'\D'), ''),
//         'bathrooms':
//             state.bathroomsController.text.replaceAll(RegExp(r'\D'), ''),
//         'square_footage':
//             state.squareFootageController.text.replaceAll(RegExp(r'\D'), ''),
//         'lot_size': state.lotSizeController.text.replaceAll(RegExp(r'\D'), ''),
//         'property_form': state.propertyFormController.text,
//         'market_type': state.marketTypeController.text,
//         'offer_type': state.offerTypeController.text,
//         'building_material': state.buildingMaterialController.text,
//         'balcony': state.balconyController.value,
//         'terrace': state.terraceController.value,
//         'sauna': state.saunaController.value,
//         'jacuzzi': state.jacuzziController.value,
//         'basement': state.basementController.value,
//         'elevator': state.elevatorController.value,
//         'garden': state.gardenController.value,
//         'air_conditioning': state.airConditioningController.value,
//         'garage': state.garageController.value,
//         'parking_space': state.parkingSpaceController.value,
//       });

//       formData.files.addAll(
//         state.imagesData.map((imageData) {
//           return MapEntry(
//             'images',
//             MultipartFile.fromBytes(
//               imageData,
//               filename: 'image${state.imagesData.indexOf(imageData)}.jpg',
//             ),
//           );
//         }),
//       );
//       state = state.copyWith(statusMessages: [
//         'Checking data',
//         'Compressing images',
//         'Sending data to server'
//       ]);

//       final response = await ApiServices.post(
//         PortalUrls.addAdvertisement,
//         hasToken: true,
//         formData: formData,
//       );

//       if (response != null && response.statusCode == 201) {
//         final snackBar = Customsnackbar().showSnackBar(
//             "success", "Advertisement added successfully", "success", () {
//           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         });
//         ScaffoldMessenger.of(context).showSnackBar(snackBar);

//         ref.read(navigationService).pushNamedScreen(Routes.profile);
//       } else {
//         throw Exception('Failed to add advertisement');
//       }
//     } catch (e) {
//       final snackBar = Customsnackbar().showSnackBar(
//           "Error",
//           " an Error has occured while sending data please retry ",
//           "error", () {
//         sendData(context, ref);
//       });
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     } finally {
//       state = state.copyWith(isLoading: false);
//     }
//   }
// }

// class AddOfferState {
//   final TextEditingController titleController;
//   final TextEditingController descriptionController;
//   final TextEditingController priceController;
//   final TextEditingController floorController;
//   final TextEditingController totalFloorsController;
//   final TextEditingController streetController;
//   final TextEditingController cityController;
//   final TextEditingController stateController;
//   final TextEditingController zipcodeController;
//   final TextEditingController roomsController;
//   final TextEditingController bathroomsController;
//   final TextEditingController squareFootageController;
//   final TextEditingController lotSizeController;
//   final TextEditingController estateTypeController;
//   final TextEditingController buildingTypeController;
//   final TextEditingController currencyController;
//   final TextEditingController propertyFormController;
//   final TextEditingController marketTypeController;
//   final TextEditingController offerTypeController;
//   final TextEditingController countryController;
//   final TextEditingController phoneNumberController;
//   final TextEditingController heatingTypeController;
//   final TextEditingController buildYearController;
//   final TextEditingController buildingMaterialController;
//   final List<Uint8List> imagesData;
//   final int? mainImageIndex;
//   final ValueNotifier<bool> balconyController;
//   final ValueNotifier<bool> terraceController;
//   final ValueNotifier<bool> saunaController;
//   final ValueNotifier<bool> jacuzziController;
//   final ValueNotifier<bool> basementController;
//   final ValueNotifier<bool> elevatorController;
//   final ValueNotifier<bool> gardenController;
//   final ValueNotifier<bool> airConditioningController;
//   final ValueNotifier<bool> garageController;
//   final ValueNotifier<bool> parkingSpaceController;
//   final bool isLoading; // Dodaj to pole
//   final List<String> statusMessages; // Dodaj to pole

//   AddOfferState({
//     this.imagesData = const [],
//     this.mainImageIndex,
//     TextEditingController? titleController,
//     TextEditingController? descriptionController,
//     TextEditingController? priceController,
//     TextEditingController? floorController,
//     TextEditingController? totalFloorsController,
//     TextEditingController? streetController,
//     TextEditingController? cityController,
//     TextEditingController? stateController,
//     TextEditingController? zipcodeController,
//     TextEditingController? roomsController,
//     TextEditingController? bathroomsController,
//     TextEditingController? squareFootageController,
//     TextEditingController? phoneNumberController,
//     TextEditingController? lotSizeController,
//     TextEditingController? estateTypeController,
//     TextEditingController? buildingTypeController,
//     TextEditingController? buildingMaterialController,
//     TextEditingController? currencyController,
//     TextEditingController? propertyFormController,
//     TextEditingController? marketTypeController,
//     TextEditingController? offerTypeController,
//     TextEditingController? countryController,
//     TextEditingController? buildYearController,
//     TextEditingController? heatingTypeController,
//     ValueNotifier<bool>? balconyController,
//     ValueNotifier<bool>? terraceController,
//     ValueNotifier<bool>? saunaController,
//     ValueNotifier<bool>? jacuzziController,
//     ValueNotifier<bool>? basementController,
//     ValueNotifier<bool>? elevatorController,
//     ValueNotifier<bool>? gardenController,
//     ValueNotifier<bool>? airConditioningController,
//     ValueNotifier<bool>? garageController,
//     ValueNotifier<bool>? parkingSpaceController,
//     this.isLoading = false, // Domyślnie ustaw na false
//     this.statusMessages = const [], // Dodaj to pole
//   })  : titleController = titleController ?? TextEditingController(),
//         descriptionController =
//             descriptionController ?? TextEditingController(),
//         priceController = priceController ?? TextEditingController(),
//         floorController = floorController ?? TextEditingController(),
//         totalFloorsController =
//             totalFloorsController ?? TextEditingController(),
//         streetController = streetController ?? TextEditingController(),
//         cityController = cityController ?? TextEditingController(),
//         countryController = countryController ?? TextEditingController(),
//         stateController = stateController ?? TextEditingController(),
//         zipcodeController = zipcodeController ?? TextEditingController(),
//         roomsController = roomsController ?? TextEditingController(),
//         bathroomsController = bathroomsController ?? TextEditingController(),
//         squareFootageController =
//             squareFootageController ?? TextEditingController(),
//         lotSizeController = lotSizeController ?? TextEditingController(),
//         estateTypeController = estateTypeController ?? TextEditingController(),
//         buildingTypeController =
//             buildingTypeController ?? TextEditingController(),
//         currencyController = currencyController ?? TextEditingController(),
//         propertyFormController =
//             propertyFormController ?? TextEditingController(),
//         marketTypeController = marketTypeController ?? TextEditingController(),
//         phoneNumberController =
//             phoneNumberController ?? TextEditingController(),
//         buildYearController = buildYearController ?? TextEditingController(),
//         heatingTypeController =
//             heatingTypeController ?? TextEditingController(),
//         buildingMaterialController =
//             buildingMaterialController ?? TextEditingController(),
//         offerTypeController = offerTypeController ?? TextEditingController(),
//         balconyController = balconyController ?? ValueNotifier<bool>(false),
//         terraceController = terraceController ?? ValueNotifier<bool>(false),
//         saunaController = saunaController ?? ValueNotifier<bool>(false),
//         jacuzziController = jacuzziController ?? ValueNotifier<bool>(false),
//         basementController = basementController ?? ValueNotifier<bool>(false),
//         elevatorController = elevatorController ?? ValueNotifier<bool>(false),
//         gardenController = gardenController ?? ValueNotifier<bool>(false),
//         airConditioningController =
//             airConditioningController ?? ValueNotifier<bool>(false),
//         garageController = garageController ?? ValueNotifier<bool>(false),
//         parkingSpaceController =
//             parkingSpaceController ?? ValueNotifier<bool>(false);

//   AddOfferState copyWith({
//     List<Uint8List>? imagesData,
//     TextEditingController? titleController,
//     TextEditingController? descriptionController,
//     TextEditingController? priceController,
//     TextEditingController? floorController,
//     TextEditingController? totalFloorsController,
//     TextEditingController? streetController,
//     TextEditingController? cityController,
//     TextEditingController? stateController,
//     TextEditingController? zipcodeController,
//     TextEditingController? roomsController,
//     TextEditingController? bathroomsController,
//     TextEditingController? squareFootageController,
//     TextEditingController? lotSizeController,
//     TextEditingController? estateTypeController,
//     TextEditingController? buildingTypeController,
//     TextEditingController? currencyController,
//     TextEditingController? propertyFormController,
//     TextEditingController? marketTypeController,
//     TextEditingController? offerTypeController,
//     TextEditingController? countryController,
//     TextEditingController? phoneNumberController,
//     TextEditingController? buildYearController,
//     TextEditingController? heatingTypeController,
//     TextEditingController? buildingMaterialController,
//     int? mainImageIndex,
//     ValueNotifier<bool>? balconyController,
//     ValueNotifier<bool>? terraceController,
//     ValueNotifier<bool>? saunaController,
//     ValueNotifier<bool>? jacuzziController,
//     ValueNotifier<bool>? basementController,
//     ValueNotifier<bool>? elevatorController,
//     ValueNotifier<bool>? gardenController,
//     ValueNotifier<bool>? airConditioningController,
//     ValueNotifier<bool>? garageController,
//     ValueNotifier<bool>? parkingSpaceController,
//     bool? isLoading, // Dodaj to pole
//     List<String>? statusMessages, // Dodaj to pole
//   }) {
//     return AddOfferState(
//       imagesData: imagesData ?? this.imagesData,
//       mainImageIndex: mainImageIndex ?? mainImageIndex,
//       titleController: titleController ?? this.titleController,
//       descriptionController:
//           descriptionController ?? this.descriptionController,
//       priceController: priceController ?? this.priceController,
//       floorController: floorController ?? this.floorController,
//       totalFloorsController:
//           totalFloorsController ?? this.totalFloorsController,
//       streetController: streetController ?? this.streetController,
//       cityController: cityController ?? this.cityController,
//       stateController: stateController ?? this.stateController,
//       zipcodeController: zipcodeController ?? this.zipcodeController,
//       roomsController: roomsController ?? this.roomsController,
//       bathroomsController: bathroomsController ?? this.bathroomsController,
//       squareFootageController:
//           squareFootageController ?? this.squareFootageController,
//       lotSizeController: lotSizeController ?? this.lotSizeController,
//       estateTypeController: estateTypeController ?? this.estateTypeController,
//       buildingTypeController:
//           buildingTypeController ?? this.buildingTypeController,
//       currencyController: currencyController ?? this.currencyController,
//       propertyFormController:
//           propertyFormController ?? this.propertyFormController,
//       marketTypeController: marketTypeController ?? this.marketTypeController,
//       offerTypeController: offerTypeController ?? this.offerTypeController,
//       countryController: countryController ?? this.countryController,
//       phoneNumberController:
//           phoneNumberController ?? this.phoneNumberController,
//       buildYearController: buildYearController ?? this.buildYearController,
//       heatingTypeController:
//           heatingTypeController ?? this.heatingTypeController,
//       buildingMaterialController:
//           buildingMaterialController ?? this.buildingMaterialController,
//       balconyController: balconyController ?? this.balconyController,
//       terraceController: terraceController ?? this.terraceController,
//       saunaController: saunaController ?? this.saunaController,
//       jacuzziController: jacuzziController ?? this.jacuzziController,
//       basementController: basementController ?? this.basementController,
//       elevatorController: elevatorController ?? this.elevatorController,
//       gardenController: gardenController ?? this.gardenController,
//       airConditioningController:
//           airConditioningController ?? this.airConditioningController,
//       garageController: garageController ?? this.garageController,
//       parkingSpaceController:
//           parkingSpaceController ?? this.parkingSpaceController,
//       isLoading: isLoading ?? this.isLoading, // Dodaj to pole
//       statusMessages: statusMessages ?? this.statusMessages, // Dodaj to pole
//     );
//   }
// }


