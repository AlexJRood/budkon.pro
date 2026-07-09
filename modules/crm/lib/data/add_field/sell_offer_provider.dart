//Riverpod/add_provider.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final crmAddSellOfferProvider =
    StateNotifierProvider<CrmAddSellOfferNotifier, CrmAddSellOfferState>((ref) {
  return CrmAddSellOfferNotifier();
});

// Dodajemy funkcję obliczającą cenę za metr kwadratowy
double calculatePricePerMeter(String price, String squareFootage) {
  if (price.isNotEmpty && squareFootage.isNotEmpty) {
    double priceValue = double.tryParse(price) ?? 0;
    double squareFootageValue = double.tryParse(squareFootage) ?? 0;
    if (squareFootageValue > 0) {
      return priceValue / squareFootageValue;
    }
  }
  return 0;
}

class CrmAddSellOfferNotifier extends StateNotifier<CrmAddSellOfferState> {
  CrmAddSellOfferNotifier() : super(CrmAddSellOfferState());

  final SecureStorage secureStorage =
      SecureStorage(); // Create an instance of SecureStorage

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      final List<Uint8List> newImagesData =
          await Future.wait(images.map((image) => image.readAsBytes()));
      state = state.copyWith(
          imagesData: List.from(state.imagesData)..addAll(newImagesData));
    }
  }

  //   Future<void> pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final List<XFile>? images = await picker.pickMultiImage();
  //   if (images != null && images.isNotEmpty) {
  //     final List<Uint8List> newImagesData = await Future.wait(images.map((image) => image.readAsBytes()));
  //     state = state.copyWith(imagesData: List.from(state.imagesData)..addAll(newImagesData));
  //   }
  // }

  void removeImage(int index) {
    if (index >= 0 && index < state.imagesData.length) {
      List<Uint8List> updatedImages = List.from(state.imagesData)
        ..removeAt(index);
      state = state.copyWith(imagesData: updatedImages);
    }
  }

  void setMainImageIndex(int index) {
    state = state.copyWith(mainImageIndex: index);
  }
}

class CrmAddSellOfferState {
  final TextEditingController titleController;
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
  final bool isLoading;
  final List<String> statusMessages;

  CrmAddSellOfferState({
    this.imagesData = const [],
    this.mainImageIndex,
    TextEditingController? titleController,
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
    TextEditingController? buildYearController,
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
    this.isLoading = false,
    this.statusMessages = const [],
  })  : titleController = titleController ?? TextEditingController(),
        descriptionController =
            descriptionController ?? TextEditingController(),
        priceController = priceController ?? TextEditingController(),
        floorController = floorController ?? TextEditingController(),
        totalFloorsController =
            totalFloorsController ?? TextEditingController(),
        streetController = streetController ?? TextEditingController(),
        cityController = cityController ?? TextEditingController(),
        countryController = countryController ?? TextEditingController(),
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
        phoneNumberController =
            phoneNumberController ?? TextEditingController(),
        buildYearController = buildYearController ?? TextEditingController(),
        heatingTypeController =
            heatingTypeController ?? TextEditingController(),
        buildingMaterialController =
            buildingMaterialController ?? TextEditingController(),
        offerTypeController = offerTypeController ?? TextEditingController(),
        balconyController = balconyController ?? ValueNotifier<bool>(false),
        terraceController = terraceController ?? ValueNotifier<bool>(false),
        saunaController = saunaController ?? ValueNotifier<bool>(false),
        jacuzziController = jacuzziController ?? ValueNotifier<bool>(false),
        basementController = basementController ?? ValueNotifier<bool>(false),
        elevatorController = elevatorController ?? ValueNotifier<bool>(false),
        gardenController = gardenController ?? ValueNotifier<bool>(false),
        airConditioningController =
            airConditioningController ?? ValueNotifier<bool>(false),
        garageController = garageController ?? ValueNotifier<bool>(false),
        parkingSpaceController =
            parkingSpaceController ?? ValueNotifier<bool>(false);

  // Dodaj metodę toJson
  Map<String, dynamic> toJson() {
    return {
      'title': titleController.text,
      'description': descriptionController.text,
      'price': priceController.text,
      'floor': floorController.text,
      'total_floors': totalFloorsController.text,
      'street': streetController.text,
      'city': cityController.text,
      'state': stateController.text,
      'zipcode': zipcodeController.text,
      'rooms': roomsController.text,
      'bathrooms': bathroomsController.text,
      'square_footage': squareFootageController.text,
      'lot_size': lotSizeController.text,
      'estate_type': estateTypeController.text,
      'building_type': buildingTypeController.text,
      'currency': currencyController.text,
      'property_form': propertyFormController.text,
      'market_type': marketTypeController.text,
      'offer_type': offerTypeController.text,
      'country': countryController.text,
      'phone_number': phoneNumberController.text,
      'build_year': buildYearController.text,
      'heating_type': heatingTypeController.text,
      'building_material': buildingMaterialController.text,
      'balcony': balconyController.value,
      'terrace': terraceController.value,
      'sauna': saunaController.value,
      'jacuzzi': jacuzziController.value,
      'basement': basementController.value,
      'elevator': elevatorController.value,
      'garden': gardenController.value,
      'air_conditioning': airConditioningController.value,
      'garage': garageController.value,
      'parking_space': parkingSpaceController.value,
    };
  }

  CrmAddSellOfferState copyWith({
    List<Uint8List>? imagesData,
    TextEditingController? titleController,
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
    TextEditingController? buildYearController,
    TextEditingController? heatingTypeController,
    TextEditingController? buildingMaterialController,
    int? mainImageIndex,
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
    bool? isLoading,
    List<String>? statusMessages,
  }) {
    return CrmAddSellOfferState(
      imagesData: imagesData ?? this.imagesData,
      mainImageIndex: mainImageIndex ?? this.mainImageIndex,
      titleController: titleController ?? this.titleController,
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
      buildYearController: buildYearController ?? this.buildYearController,
      heatingTypeController:
          heatingTypeController ?? this.heatingTypeController,
      buildingMaterialController:
          buildingMaterialController ?? this.buildingMaterialController,
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
      isLoading: isLoading ?? this.isLoading,
      statusMessages: statusMessages ?? this.statusMessages,
    );
  }
}

Widget buildDropdownButtonFormField({
  required TextEditingController controller, // Używanie kontrolera
  required List<String> items,
  required String labelText,
  required WidgetRef ref,
}) {
  return SizedBox(
    child: DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : null,
      decoration: InputDecoration(
        labelText: labelText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        labelStyle: AppTextStyles.interRegular
            .copyWith(fontSize: 14, color: AppColors.dark50),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: AppColors.dark)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: AppColors.mapMarker)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: AppColors.superbee)),
        filled: true, // Dodane
        fillColor: Colors.white, // Ustawienie białego tła
      ),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: AppTextStyles.interRegular
                .copyWith(fontSize: 14, color: AppColors.dark),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        controller.text = newValue ?? '';
      },
      // Stylowanie wybranego elementu
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String value) {
          return Text(value,
              style: AppTextStyles.interSemiBold.copyWith(
                  fontSize: 14,
                  color: AppColors.dark)); // Styl dla wybranego elementu
        }).toList();
      },
    ),
  );
}

Widget buildSelectableButtonsFormField({
  required TextEditingController controller,
  required List<String> options,
  required String labelText,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          labelText,
          style: AppTextStyles.interRegular
              .copyWith(fontSize: 14, color: AppColors.light),
        ),
      ),
      const SizedBox(
        width: 10,
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: ElevatedButton(
                onPressed: () {
                  controller.text =
                      option; // Aktualizacja kontrolera wybraną wartością
                  // Odświeżenie stanu, aby zaktualizować UI
                  (context as Element).markNeedsBuild();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.text == option
                      ? Colors.blue
                      : Colors.white, // Zmiana koloru dla wybranej opcji
                  foregroundColor: controller.text == option
                      ? AppColors.light
                      : AppColors.dark, // Zmiana koloru tekstu
                  textStyle: AppTextStyles.interRegular.copyWith(
                      fontSize: 14), // Stosowanie wybranego stylu tekstu
                ),
                child: Text(option),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class AdditionalInfoFilterButton extends StatelessWidget {
  final String text;
  final ValueNotifier<bool> controller;

  const AdditionalInfoFilterButton({
    super.key,
    required this.text,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (_, isSelected, __) {
        return ElevatedButton(
          onPressed: () => controller.value = !isSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            side: isSelected ? null : const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
          ),
          child: Text(text,
              style:
                  TextStyle(color: isSelected ? Colors.white : Colors.black)),
        );
      },
    );
  }
}

class EstateTypeAddButton extends ConsumerWidget {
  final String text;
  final String filterValue;
  final TextEditingController controller;

  const EstateTypeAddButton({
    super.key,
    required this.text,
    required this.filterValue,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sprawdzanie, czy wartość przycisku jest aktualnie wybrana
    bool isSelected = controller.text == filterValue;

    return ElevatedButton(
      onPressed: () {
        // Jeśli przycisk jest już zaznaczony, to kliknięcie go ponownie powinno usunąć selekcję
        if (isSelected) {
          controller.text =
              ''; // Czyszczenie kontrolera, jeśli wartość jest już zaznaczona
        } else {
          // Ustawienie kontrolera na wartość przycisku, niezależnie od poprzedniego stanu
          controller.text = filterValue;
        }
        // Zmuszenie interfejsu do odświeżenia i pokazania aktualnego stanu
        (context as Element).markNeedsBuild();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.blue
            : Colors.white, // Podświetlenie przycisku, gdy jest wybrany
        foregroundColor: isSelected
            ? Colors.white
            : Colors.black, // Zmiana koloru tekstu w zależności od stanu
        side: isSelected
            ? null
            : const BorderSide(
                color: Colors
                    .grey), // Dodanie obramowania dla niezaznaczonych przycisków
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18.0)), // Zaokrąglenie rogów przycisku
      ),
      child: Text(text,
          style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors
                      .black)), // Zmiana koloru tekstu w zależności od stanu
    );
  }
}

class ButtonOption {
  final String label;
  final String value;

  ButtonOption(this.label, this.value);
}

Widget selectButtonsOptions({
  required TextEditingController controller,
  required List<ButtonOption> options,
  required String labelText,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          labelText,
          style: AppTextStyles.interRegular
              .copyWith(fontSize: 14, color: AppColors.light),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: ElevatedButton(
                onPressed: () {
                  controller.text =
                      option.value; // Aktualizacja kontrolera wybraną wartością
                  (context as Element)
                      .markNeedsBuild(); // Odświeżenie stanu, aby zaktualizować UI
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.text == option.value
                      ? Colors.blue
                      : Colors.white, // Zmiana koloru dla wybranej opcji
                  foregroundColor: controller.text == option.value
                      ? Colors.white
                      : Colors.black, // Zmiana koloru tekstu
                ),
                child: Text(option.label),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

Widget buildTextField({
  required TextEditingController controller,
  required String labelText,
  required BuildContext context,
  int? maxLines,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    style: AppTextStyles.interRegular
        .copyWith(fontSize: 14, color: AppColors.light),
    controller: controller,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      labelText: labelText,
      labelStyle: AppTextStyles.interRegular
          .copyWith(fontSize: 14, color: AppColors.light),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: AppColors.light)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: AppColors.light)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: AppColors.superbee)),
    ),
    maxLines:
        maxLines ?? 1, // Domyślnie jedna linia, chyba że określono inaczej
    validator: validator,
  );
}

Widget buildTextFieldDes({
  required TextEditingController controller,
  required String labelText,
  required BuildContext context,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    style: AppTextStyles.interRegular
        .copyWith(fontSize: 14, color: AppColors.light),
    controller: controller,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      labelText: labelText,
      labelStyle: AppTextStyles.interRegular
          .copyWith(fontSize: 14, color: AppColors.light),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: AppColors.light)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: AppColors.light)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: AppColors.superbee)),
      counterText: '', // Ukrywa licznik znaków
    ),
    maxLines:
        null, // Pozwala na dowolną liczbę linii, pole rozszerza się wertykalnie
    maxLength: 2500, // Ogranicza liczbę znaków do 2500
    validator: validator,
  );
}

Widget buildNumberTextField({
  required TextEditingController controller,
  required String labelText,
  required BuildContext context,
  String? Function(String?)? validator,
  required String unit, // Parametr dla jednostki
}) {
  // Ustawienie NumberFormat z separatorem w postaci spacji
  final formatter = NumberFormat('#,###.##', 'pl_PL');

  // Określenie koloru wypełnienia na podstawie wartości kontrolera
  Color fillColor = controller.text.isEmpty ? Colors.white : Colors.white;

  return TextFormField(
    style: AppTextStyles.interSemiBold
        .copyWith(fontSize: 14, color: AppColors.dark),
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      labelText: labelText,
      labelStyle: AppTextStyles.interRegular
          .copyWith(fontSize: 14, color: AppColors.dark50),
      filled: true, // Włączenie wypełnienia kolorem
      fillColor: fillColor, // Ustawienie koloru wypełnienia
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: AppColors.dark)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: AppColors.light)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: AppColors.superbee)),
    ),
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly, // Dopuszcza tylko cyfry
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) {
          return newValue.copyWith(text: '');
        }
        final int value =
            int.parse(newValue.text.replaceAll(' ', '').replaceAll(',', ''));
        final String newText = formatter.format(value).replaceAll(',', ' ');
        return newValue.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }),
    ],
    validator: validator,
  );
}

class UnitInputFormatter extends TextInputFormatter {
  final String unit;

  UnitInputFormatter({required this.unit});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText =
        newValue.text.replaceAll(',', '.'); // Zamiana przecinka na kropkę

    if (newText.isNotEmpty && !newText.endsWith(unit)) {
      // Jeśli nowy tekst nie kończy się jednostką, dodaj ją
      newText += ' $unit';
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
          offset:
              newText.length - unit.length - 1), // Aktualizacja pozycji kursora
    );
  }
}
