import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';

/// Klasa przechowująca kontrolery tekstowe oraz stan oferty
class AgentSellOfferControllers {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingControllerWithDecimal priceController;
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
  final TextEditingControllerWithDecimal buildYearController;
  final TextEditingController buildingMaterialController;
  final List<Uint8List> imagesData;
  final int? mainImageIndex;

  final ValueNotifier<bool> balconyController;
  final ValueNotifier<bool> terraceController;
  final ValueNotifier<bool> saunaController;
  final ValueNotifier<bool> jacuzziController;
  final ValueNotifier<bool> basementController;
  final ValueNotifier<bool> elevatorController;
  final ValueNotifier<bool> gardenController;
  final ValueNotifier<bool> airConditioningController;
  final ValueNotifier<bool> garageController;
  final ValueNotifier<bool> parkingSpaceController;
  final TextEditingController landAndMortgageRegisterController;

  final bool isLoading;
  final List<String> statusMessages;

  /// Konstruktor domyślny
  AgentSellOfferControllers({
    this.imagesData = const [],
    this.mainImageIndex,
    TextEditingController? titleController,
    TextEditingController? descriptionController,
    TextEditingControllerWithDecimal? priceController,
    TextEditingController? floorController,
    TextEditingController? totalFloorsController,
    TextEditingController? streetController,
    TextEditingController? cityController,
    TextEditingController? stateController,
    TextEditingController? zipcodeController,
    TextEditingController? roomsController,
    TextEditingController? bathroomsController,
    TextEditingController? squareFootageController,
    TextEditingController? phoneNumberController,
    TextEditingController? lotSizeController,
    TextEditingController? estateTypeController,
    TextEditingController? buildingTypeController,
    TextEditingController? buildingMaterialController,
    TextEditingController? currencyController,
    TextEditingController? propertyFormController,
    TextEditingController? marketTypeController,
    TextEditingController? offerTypeController,
    TextEditingController? countryController,
    TextEditingControllerWithDecimal? buildYearController,
    TextEditingController? heatingTypeController,
    ValueNotifier<bool>? balconyController,
    ValueNotifier<bool>? terraceController,
    ValueNotifier<bool>? saunaController,
    ValueNotifier<bool>? jacuzziController,
    ValueNotifier<bool>? basementController,
    ValueNotifier<bool>? elevatorController,
    ValueNotifier<bool>? gardenController,
    ValueNotifier<bool>? airConditioningController,
    ValueNotifier<bool>? garageController,
    ValueNotifier<bool>? parkingSpaceController,
    TextEditingController? landAndMortgageRegisterController,
    this.isLoading = false,
    this.statusMessages = const [],
  })  : titleController = titleController ?? TextEditingController(),
        descriptionController = descriptionController ?? TextEditingController(),
        priceController = priceController ?? TextEditingControllerWithDecimal(),
        floorController = floorController ?? TextEditingController(),
        totalFloorsController = totalFloorsController ?? TextEditingController(),
        streetController = streetController ?? TextEditingController(),
        cityController = cityController ?? TextEditingController(),
        countryController = countryController ?? TextEditingController(),
        stateController = stateController ?? TextEditingController(),
        zipcodeController = zipcodeController ?? TextEditingController(),
        roomsController = roomsController ?? TextEditingController(),
        bathroomsController = bathroomsController ?? TextEditingController(),
        squareFootageController = squareFootageController ?? TextEditingController(),
        lotSizeController = lotSizeController ?? TextEditingController(),
        estateTypeController = estateTypeController ?? TextEditingController(),
        buildingTypeController = buildingTypeController ?? TextEditingController(),
        currencyController = currencyController ?? TextEditingController(),
        propertyFormController = propertyFormController ?? TextEditingController(),
        marketTypeController = marketTypeController ?? TextEditingController(),
        phoneNumberController = phoneNumberController ?? TextEditingController(),
        buildYearController = buildYearController ?? TextEditingControllerWithDecimal(),
        heatingTypeController = heatingTypeController ?? TextEditingController(),
        buildingMaterialController = buildingMaterialController ?? TextEditingController(),
        offerTypeController = offerTypeController ?? TextEditingController(),
        balconyController = balconyController ?? ValueNotifier<bool>(false),
        terraceController = terraceController ?? ValueNotifier<bool>(false),
        saunaController = saunaController ?? ValueNotifier<bool>(false),
        jacuzziController = jacuzziController ?? ValueNotifier<bool>(false),
        basementController = basementController ?? ValueNotifier<bool>(false),
        elevatorController = elevatorController ?? ValueNotifier<bool>(false),
        gardenController = gardenController ?? ValueNotifier<bool>(false),
        airConditioningController = airConditioningController ?? ValueNotifier<bool>(false),
        garageController = garageController ?? ValueNotifier<bool>(false),
        parkingSpaceController = parkingSpaceController ?? ValueNotifier<bool>(false),
        landAndMortgageRegisterController = landAndMortgageRegisterController ?? TextEditingController();

  /// Metoda `dispose()` zwalniająca zasoby
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    floorController.dispose();
    totalFloorsController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipcodeController.dispose();
    roomsController.dispose();
    bathroomsController.dispose();
    squareFootageController.dispose();
    lotSizeController.dispose();
    estateTypeController.dispose();
    buildingTypeController.dispose();
    currencyController.dispose();
    propertyFormController.dispose();
    marketTypeController.dispose();
    phoneNumberController.dispose();
    buildYearController.dispose();
    heatingTypeController.dispose();
    buildingMaterialController.dispose();
    offerTypeController.dispose();
    landAndMortgageRegisterController.dispose();
  }
  void clear() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    floorController.clear();
    totalFloorsController.clear();
    streetController.clear();
    cityController.clear();
    stateController.clear();
    zipcodeController.clear();
    roomsController.clear();
    bathroomsController.clear();
    squareFootageController.clear();
    lotSizeController.clear();
    estateTypeController.clear();
    buildingTypeController.clear();
    currencyController.clear();
    propertyFormController.clear();
    marketTypeController.clear();
    offerTypeController.clear();
    countryController.clear();
    phoneNumberController.clear();
    heatingTypeController.clear();
    buildYearController.clear();
    buildingMaterialController.clear();
    landAndMortgageRegisterController.clear();

    // Reset all boolean toggles
    balconyController.value = false;
    terraceController.value = false;
    saunaController.value = false;
    jacuzziController.value = false;
    basementController.value = false;
    elevatorController.value = false;
    gardenController.value = false;
    airConditioningController.value = false;
    garageController.value = false;
    parkingSpaceController.value = false;
  }

}

/// Provider dla AddOfferState
final sellControllersProvider = StateProvider<AgentSellOfferControllers>((ref) {
  final state = AgentSellOfferControllers();
  ref.onDispose(state.dispose);
  return state;
});




//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
/////////////////////// How to use that //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// class AddOfferScreen extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final offerState = ref.watch(addOfferProvider);

//     return Scaffold(
//       appBar: AppBar(title: Text("Add Offer".tr)),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: offerState.titleController,
//               decoration: InputDecoration(labelText: "Tytuł".tr),
//             ),
//             TextField(
//               controller: offerState.descriptionController,
//               decoration: InputDecoration(labelText: "Opis".tr),
//             ),
//             TextField(
//               controller: offerState.priceController,
//               decoration: InputDecoration(labelText: "Price".tr),
//             ),
//             SwitchListTile(
//               title: Text("Czy jest balkon?".tr),
//               value: offerState.balconyController.value,
//               onChanged: (value) {
//                 offerState.balconyController.value = value;
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
