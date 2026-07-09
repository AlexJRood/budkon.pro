import 'dart:convert';
import 'package:crm/crm_urls.dart';
import 'dart:typed_data';

import 'package:crm/your_agent/urls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/secure_storage.dart';
import 'package:core/platform/url.dart';
import 'package:core/common/custom_error_handler.dart';

double calculatePricePerMeter(String price, String squareFootage) {
  if (price.isNotEmpty && squareFootage.isNotEmpty) {
    final p = double.tryParse(price.replaceAll(',', '.')) ?? 0;
    final s = double.tryParse(squareFootage.replaceAll(',', '.')) ?? 0;
    if (s > 0) return p / s;
  }
  return 0;
}

enum EditOfferApiMode {
  crmDraft,
  portalAdvertisement,
}

class EditOfferApiConfig {
  final EditOfferApiMode mode;
  final String Function(String id) loadUrlBuilder;
  final String Function(String id) updateUrlBuilder;
  final String Function(String id)? appendImagesUrlBuilder;
  final String Function(String id)? removeImageUrlBuilder;
  final bool uploadImagesImmediately;
  final bool updateWithMultipart;

  const EditOfferApiConfig({
    required this.mode,
    required this.loadUrlBuilder,
    required this.updateUrlBuilder,
    required this.appendImagesUrlBuilder,
    required this.removeImageUrlBuilder,
    required this.uploadImagesImmediately,
    required this.updateWithMultipart,
  });

  factory EditOfferApiConfig.crm() {
    return EditOfferApiConfig(
      mode: EditOfferApiMode.crmDraft,
      loadUrlBuilder: (id) => CrmUrls.singleEstateAgentAdvertismentDraft(id),
      updateUrlBuilder: (id) => CrmUrls.updateEstateAgentAdvertismentDraft(id),
      appendImagesUrlBuilder: (id) =>
          'https://www.superbee.cloud/portal/draft/advertisements/images/$id/append/',
      removeImageUrlBuilder: (id) =>
          'https://www.superbee.cloud/portal/draft/advertisements/images/$id/remove/',
      uploadImagesImmediately: true,
      updateWithMultipart: false,
    );
  }

  factory EditOfferApiConfig.portal() {
    return EditOfferApiConfig(
      mode: EditOfferApiMode.portalAdvertisement,
      loadUrlBuilder: (id) => CrmUrls.advertiseOffer(id),
      updateUrlBuilder: (id) => CrmUrls.updateAdvertise(id),
      appendImagesUrlBuilder: (id) =>
          'https://www.superbee.cloud/portal/advertisements/images/$id/append/',
      removeImageUrlBuilder: (id) =>
          'https://www.superbee.cloud/portal/advertisements/images/$id/remove/',
      uploadImagesImmediately: true,
      updateWithMultipart: false,
    );
  }

  bool get isCrm => mode == EditOfferApiMode.crmDraft;
  bool get isPortal => mode == EditOfferApiMode.portalAdvertisement;
}

final crmEditSellOfferProvider =
    StateNotifierProvider.family<CrmEditOfferNotifier, EditOfferState, int?>(
  (ref, offerId) => CrmEditOfferNotifier(
    offerId: offerId,
    ref: ref,
    apiConfig: EditOfferApiConfig.crm(),
  ),
);

class CrmEditOfferNotifier extends StateNotifier<EditOfferState> {
  CrmEditOfferNotifier({
    int? offerId,
    required dynamic ref,
    EditOfferApiConfig? apiConfig,
  })  : _ref = ref,
        apiConfig = apiConfig ?? EditOfferApiConfig.crm(),
        super(EditOfferState()) {
    if (offerId != null) {
      loadOfferData(offerId, ref);
    }
  }

  final SecureStorage secureStorage = SecureStorage();
  final dynamic _ref;
  final EditOfferApiConfig apiConfig;

  int _loadSeq = 0;

  bool _asBool(dynamic value) {
    if (value == true || value == 1) return true;
    final v = (value ?? '').toString().trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    return text == 'null' ? '' : text;
  }

  String _fullImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${URLs.baseUrl}$path';
  }

  void cycleLocalImages(int direction) {
    final imgs = List<Uint8List>.from(state.imagesData);
    if (imgs.length < 2) return;

    if (direction > 0) {
      final first = imgs.removeAt(0);
      imgs.add(first);
    } else {
      final last = imgs.removeLast();
      imgs.insert(0, last);
    }

    state = state.copyWith(
      imagesData: imgs,
      mainImageIndex: 0,
    );
  }

  void cycleServerImages(int direction) {
    final urls = List<String>.from(state.serverImageUrls);
    if (urls.length < 2) return;

    if (direction > 0) {
      final first = urls.removeAt(0);
      urls.add(first);
    } else {
      final last = urls.removeLast();
      urls.insert(0, last);
    }

    state = state.copyWith(
      serverImageUrls: urls,
      mainImageIndex: 0,
    );
  }

  void setMainImageIndex(int index) {
    final imgs = List<Uint8List>.from(state.imagesData);
    if (imgs.isEmpty) return;

    final i = index.clamp(0, imgs.length - 1);
    final tmp = imgs[0];
    imgs[0] = imgs[i];
    imgs[i] = tmp;

    state = state.copyWith(
      imagesData: imgs,
      mainImageIndex: 0,
    );
  }

  void setMainServerImageByUrl(String url) {
    final urls = List<String>.from(state.serverImageUrls);
    final index = urls.indexOf(url);
    if (index < 0) return;

    final selected = urls.removeAt(index);
    urls.insert(0, selected);

    state = state.copyWith(
      serverImageUrls: urls,
      mainImageIndex: 0,
    );
  }

  void removeImage(int index) {
    if (index >= 0 && index < state.imagesData.length) {
      final updated = List<Uint8List>.from(state.imagesData)..removeAt(index);
      state = state.copyWith(
        imagesData: updated,
        mainImageIndex: updated.isEmpty ? null : 0,
      );
    }
  }

  Future<bool> removeServerImageAt(int index) async {
    final id = state.editedOfferId;
    if (id == null) return false;
    if (index < 0 || index >= state.serverImageUrls.length) return false;

    final urls = List<String>.from(state.serverImageUrls)..removeAt(index);
    state = state.copyWith(
      serverImageUrls: urls,
      mainImageIndex: urls.isEmpty ? null : 0,
    );

    if (!apiConfig.uploadImagesImmediately ||
        apiConfig.removeImageUrlBuilder == null) {
      return true;
    }

    final resp = await ApiServices.post(
      apiConfig.removeImageUrlBuilder!(id.toString()),
      hasToken: true,
      data: {'index': index},
    );

    final ok = resp != null &&
        (resp.statusCode == 200 ||
            resp.statusCode == 204 ||
            resp.statusCode == 202);

    if (!ok) {
      await loadOfferData(id, _ref);
    }
    return ok;
  }

  Future<void> removeCurrentMainImage() async {
    if (state.imagesData.isNotEmpty) {
      removeImage(0);
      return;
    }

    if (state.serverImageUrls.isNotEmpty) {
      await removeServerImageAt(0);
    }
  }

  void _showSnackSafe(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.removeCurrentSnackBar();

    final snackBar = Customsnackbar().showSnackBar(
      title,
      message,
      type,
      () {
        messenger.hideCurrentSnackBar();
      },
    );

    messenger.showSnackBar(snackBar);
  }

  Map<String, dynamic> _decodeResponseToMap(dynamic raw) {
    try {
      dynamic decoded = raw;

      if (decoded is List<int>) {
        decoded = jsonDecode(utf8.decode(decoded));
      } else if (decoded is String) {
        decoded = jsonDecode(decoded);
      }

      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  List<String> _extractServerUrls(Map<String, dynamic> offerData) {
    final dynamic rawImgs = offerData['images'];
    final dynamic rawAdv = offerData['advertisement_images'];

    final List<String> urls = (rawImgs is List && rawImgs.isNotEmpty)
        ? rawImgs.whereType<String>().map(_fullImageUrl).toList()
        : (rawAdv is List
            ? rawAdv.whereType<String>().map(_fullImageUrl).toList()
            : <String>[]);

    return urls;
  }

  Future<void> loadOfferData(int offerId, dynamic ref) async {
    final int seq = ++_loadSeq;

    state = state.copyWith(
      isLoading: true,
      fieldErrors: const {},
    );

    if (ApiServices.token == null) {
      if (mounted && seq == _loadSeq) {
        state = state.copyWith(isLoading: false);
      }
      return;
    }

    try {
      final response = await ApiServices.get(
        ref: ref,
        apiConfig.loadUrlBuilder('$offerId'),
        hasToken: true,
      );

      if (!mounted || seq != _loadSeq) return;

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> offerData = _decodeResponseToMap(response.data);

        final titleController =
            TextEditingController(text: _asString(offerData['title']));
        final descriptionController =
            TextEditingController(text: _asString(offerData['description']));
        final priceController =
            TextEditingController(text: _asString(offerData['price']));
        final pricePerMeterController =
            TextEditingController(text: _asString(offerData['price_per_meter']));

        final floorController =
            TextEditingController(text: _asString(offerData['floor']));
        final totalFloorsController =
            TextEditingController(text: _asString(offerData['total_floors']));

        final streetController =
            TextEditingController(text: _asString(offerData['street']));
        final districtController =
            TextEditingController(text: _asString(offerData['district']));
        final cityController =
            TextEditingController(text: _asString(offerData['city']));
        final stateController =
            TextEditingController(text: _asString(offerData['state']));
        final zipcodeController =
            TextEditingController(text: _asString(offerData['zipcode']));
        final countryController =
            TextEditingController(text: _asString(offerData['country']));

        final latitudeController =
            TextEditingController(text: _asString(offerData['latitude']));
        final longitudeController =
            TextEditingController(text: _asString(offerData['longitude']));

        final phoneNumberController =
            TextEditingController(text: _asString(offerData['phone_number']));
        final phoneNumberPrefixController =
            TextEditingController(text: _asString(offerData['phone_number_prefix']));

        final buildYearController =
            TextEditingController(text: _asString(offerData['build_year']));
        final squareFootageController =
            TextEditingController(text: _asString(offerData['square_footage']));
        final lotSizeController =
            TextEditingController(text: _asString(offerData['lot_size']));

        final propertyFormController =
            TextEditingController(text: _asString(offerData['property_form']));
        final marketTypeController =
            TextEditingController(text: _asString(offerData['market_type']));

        final windowsController =
            TextEditingController(text: _asString(offerData['windows']));
        final atticTypeController =
            TextEditingController(text: _asString(offerData['attic_type']));
        final securityController =
            TextEditingController(text: _asString(offerData['security']));
        final premisesLocationController =
            TextEditingController(text: _asString(offerData['premises_location']));
        final purposeController =
            TextEditingController(text: _asString(offerData['purpose']));
        final roofController =
            TextEditingController(text: _asString(offerData['roof']));
        final recreationalHouseController =
            TextEditingController(text: _asString(offerData['recreational_house']));
        final roofCoveringController =
            TextEditingController(text: _asString(offerData['roof_covering']));
        final lightningController =
            TextEditingController(text: _asString(offerData['lightning']));
        final constructionController =
            TextEditingController(text: _asString(offerData['construction']));
        final heightController =
            TextEditingController(text: _asString(offerData['height']));
        final officeRoomsController =
            TextEditingController(text: _asString(offerData['office_rooms']));
        final socialFacilitiesController =
            TextEditingController(text: _asString(offerData['social_facilities']));
        final parkingController =
            TextEditingController(text: _asString(offerData['parking']));
        final rampController =
            TextEditingController(text: _asString(offerData['ramp']));
        final floorMaterialController =
            TextEditingController(text: _asString(offerData['floor_material']));
        final fencingController =
            TextEditingController(text: _asString(offerData['fencing']));
        final accessRoadController =
            TextEditingController(text: _asString(offerData['access_road']));
        final plotTypeController =
            TextEditingController(text: _asString(offerData['plot_type']));
        final dimensionsController =
            TextEditingController(text: _asString(offerData['dimensions']));

        final uuidController =
            TextEditingController(text: _asString(offerData['uuid']));
        final createdAtController =
            TextEditingController(text: _asString(offerData['created_at']));
        final activeValidityDateController =
            TextEditingController(text: _asString(offerData['active_validity_date']));
        final viewCountController =
            TextEditingController(text: _asString(offerData['view_count']));
        final userController =
            TextEditingController(text: _asString(offerData['user']));
        final clientController =
            TextEditingController(text: _asString(offerData['client']));

        final rentController =
            TextEditingController(text: _asString(offerData['rent']));
        final landAndMortgageRegisterController = TextEditingController(
          text: _asString(offerData['land_and_mortgage_register']),
        );
        final estateConditionController =
            TextEditingController(text: _asString(offerData['estate_condition']));
        final remoteServiceController =
            TextEditingController(text: _asString(offerData['remote_service']));
        final crmSignatureController =
            TextEditingController(text: _asString(offerData['crm_signature']));

        final currency = _asString(offerData['currency']);
        final currencyController = TextEditingController(
          text: (['PLN', 'EUR', 'GBP', 'USD', 'CZK'].contains(currency)
              ? currency
              : 'PLN'),
        );

        final buildingType = _asString(offerData['building_type']);
        final buildingTypeController = TextEditingController(
          text: ([
            'block_building_option'.tr,
            'apartment_building_option'.tr,
            'townhouse_option'.tr,
            'tenement_building_option'.tr,
            'highrise_building_option'.tr,
            'Loft'.tr
          ].contains(buildingType)
              ? buildingType
              : 'block_building_option'.tr),
        );

        final heatingType = _asString(offerData['heating_type']);
        final heatingTypeController = TextEditingController(
          text: ([
            'gas_heating_option'.tr,
            'electric_heating_option'.tr,
            'district_heating_option'.tr,
            'heat_pump_heating_option'.tr,
            'oil_heating_option'.tr,
            'all_heating_option'.tr,
            'not_provided_heating_option'.tr
          ].contains(heatingType)
              ? heatingType
              : 'gas_heating_option'.tr),
        );

        final buildingMaterial = _asString(offerData['building_material']);
        final buildingMaterialController = TextEditingController(
          text: ([
            'brick_material_option'.tr,
            'large_panel_material_option'.tr,
            'silicate_material_option'.tr,
            'concrete_material_option'.tr,
            'aerated_concrete_material_option'.tr,
            'hollow_block_material_option'.tr,
            'reinforced_concrete_material_option'.tr,
            'ceramsite_material_option'.tr,
            'wood_material_option'.tr,
            'other_material_option'.tr
          ].contains(buildingMaterial)
              ? buildingMaterial
              : 'brick_material_option'.tr),
        );

        final offerType = _asString(offerData['offer_type']);
        final offerTypeController = TextEditingController(
          text: offerType == 'sell' ? 'want_to_sell_option'.tr : 'want_to_rent_option'.tr,
        );

        final estateType = _asString(offerData['estate_type']);
        String estateTypeDisplayValue = '';
        if (estateType == 'Flat'.tr || estateType == 'Flat') {
          estateTypeDisplayValue = 'apartment_option'.tr;
        } else if (estateType == 'Studio'.tr || estateType == 'Studio') {
          estateTypeDisplayValue = 'studio_option'.tr;
        } else if (estateType == 'Apartment') {
          estateTypeDisplayValue = 'penthouse_option'.tr;
        } else if (estateType == 'House'.tr || estateType == 'House') {
          estateTypeDisplayValue = 'house_option'.tr;
        } else if (estateType == 'Twin house'.tr || estateType == 'Twin house') {
          estateTypeDisplayValue = 'semi_detached_option'.tr;
        } else if (estateType == 'Row house'.tr || estateType == 'Row house') {
          estateTypeDisplayValue = 'townhouse_option'.tr;
        } else if (estateType == 'Invest'.tr || estateType == 'Invest') {
          estateTypeDisplayValue ='investments_option'.tr;
        } else if (estateType == 'Lot'.tr || estateType == 'Lot') {
          estateTypeDisplayValue = 'plots_option'.tr;
        } else if (estateType == 'Commercial'.tr || estateType == 'Commercial') {
          estateTypeDisplayValue = 'commercial_option'.tr;
        } else if (estateType == 'Warehouse'.tr || estateType == 'Warehouse') {
          estateTypeDisplayValue = 'warehouse_option'.tr;
        } else if (estateType == 'Room'.tr || estateType == 'Room') {
          estateTypeDisplayValue = 'rooms_option'.tr;
        } else if (estateType == 'Garage'.tr || estateType == 'Garage') {
          estateTypeDisplayValue = 'garages_option'.tr;
        }
        final estateTypeController =
            TextEditingController(text: estateTypeDisplayValue);

        final rooms = _asString(offerData['rooms']);
        final roomsController = TextEditingController(
          text: ['1', '2', '3', '4', '5', '6', '7+'].contains(rooms) ? rooms : '',
        );

        final bathrooms = _asString(offerData['bathrooms']);
        final bathroomsController = TextEditingController(
          text: ['1', '2', '3', '4', '5', '6', '7+'].contains(bathrooms)
              ? bathrooms
              : '',
        );

        final balconyController = ValueNotifier<bool>(_asBool(offerData['balcony']));
        final terraceController = ValueNotifier<bool>(_asBool(offerData['terrace']));
        final saunaController = ValueNotifier<bool>(_asBool(offerData['sauna']));
        final jacuzziController = ValueNotifier<bool>(_asBool(offerData['jacuzzi']));
        final basementController =
            ValueNotifier<bool>(_asBool(offerData['basement']));
        final elevatorController =
            ValueNotifier<bool>(_asBool(offerData['elevator']));
        final gardenController = ValueNotifier<bool>(_asBool(offerData['garden']));
        final airConditioningController =
            ValueNotifier<bool>(_asBool(offerData['air_conditioning']));
        final garageController = ValueNotifier<bool>(_asBool(offerData['garage']));
        final parkingSpaceController =
            ValueNotifier<bool>(_asBool(offerData['parking_space']));

        final electricity =
            ValueNotifier<bool>(_asBool(offerData['electricity']));
        final energyCertificate =
            ValueNotifier<bool>(_asBool(offerData['energy_certificate']));
        final water = ValueNotifier<bool>(_asBool(offerData['water']));
        final gas = ValueNotifier<bool>(_asBool(offerData['gas']));
        final phone = ValueNotifier<bool>(_asBool(offerData['phone']));
        final internet = ValueNotifier<bool>(_asBool(offerData['internet']));
        final sewerage = ValueNotifier<bool>(_asBool(offerData['sewerage']));
        final equipment = ValueNotifier<bool>(_asBool(offerData['equipment']));

        final isPremium2 = ValueNotifier<bool>(_asBool(offerData['isPremium2']));
        final isRenewable =
            ValueNotifier<bool>(_asBool(offerData['is_renewable']));
        final isActive = ValueNotifier<bool>(_asBool(offerData['is_active']));
        final crmBlockUpdates =
            ValueNotifier<bool>(_asBool(offerData['crm_block_updates']));

        final urls = _extractServerUrls(offerData);

        if (!mounted || seq != _loadSeq) return;

        state = state.copyWith(
          titleController: titleController,
          descriptionController: descriptionController,
          priceController: priceController,
          pricePerMeterController: pricePerMeterController,
          floorController: floorController,
          totalFloorsController: totalFloorsController,
          streetController: streetController,
          districtController: districtController,
          cityController: cityController,
          stateController: stateController,
          zipcodeController: zipcodeController,
          countryController: countryController,
          latitudeController: latitudeController,
          longitudeController: longitudeController,
          phoneNumberController: phoneNumberController,
          phoneNumberPrefixController: phoneNumberPrefixController,
          buildYearController: buildYearController,
          squareFootageController: squareFootageController,
          lotSizeController: lotSizeController,
          propertyFormController: propertyFormController,
          marketTypeController: marketTypeController,
          windowsController: windowsController,
          atticTypeController: atticTypeController,
          securityController: securityController,
          premisesLocationController: premisesLocationController,
          purposeController: purposeController,
          roofController: roofController,
          recreationalHouseController: recreationalHouseController,
          roofCoveringController: roofCoveringController,
          lightningController: lightningController,
          constructionController: constructionController,
          heightController: heightController,
          officeRoomsController: officeRoomsController,
          socialFacilitiesController: socialFacilitiesController,
          parkingController: parkingController,
          rampController: rampController,
          floorMaterialController: floorMaterialController,
          fencingController: fencingController,
          accessRoadController: accessRoadController,
          plotTypeController: plotTypeController,
          dimensionsController: dimensionsController,
          uuidController: uuidController,
          createdAtController: createdAtController,
          activeValidityDateController: activeValidityDateController,
          viewCountController: viewCountController,
          userController: userController,
          clientController: clientController,
          rentController: rentController,
          landAndMortgageRegisterController: landAndMortgageRegisterController,
          estateConditionController: estateConditionController,
          remoteServiceController: remoteServiceController,
          crmSignatureController: crmSignatureController,
          offerTypeController: offerTypeController,
          estateTypeController: estateTypeController,
          roomsController: roomsController,
          bathroomsController: bathroomsController,
          currencyController: currencyController,
          buildingTypeController: buildingTypeController,
          heatingTypeController: heatingTypeController,
          buildingMaterialController: buildingMaterialController,
          balconyController: balconyController,
          terraceController: terraceController,
          saunaController: saunaController,
          jacuzziController: jacuzziController,
          basementController: basementController,
          elevatorController: elevatorController,
          gardenController: gardenController,
          airConditioningController: airConditioningController,
          garageController: garageController,
          parkingSpaceController: parkingSpaceController,
          electricity: electricity,
          energyCertificate: energyCertificate,
          water: water,
          gas: gas,
          phone: phone,
          internet: internet,
          sewerage: sewerage,
          equipment: equipment,
          isPremium2: isPremium2,
          isRenewable: isRenewable,
          isActive: isActive,
          crmBlockUpdates: crmBlockUpdates,
          serverImageUrls: urls,
          imagesData: const [],
          mainImageIndex: urls.isEmpty ? null : 0,
          editedOfferId: offerId,
          fieldErrors: const {},
          isLoading: false,
        );

        return;
      }
    } catch (_) {}

    if (mounted && seq == _loadSeq) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    final List<Uint8List> newBytes =
        await Future.wait(images.map((x) => x.readAsBytes()));

    if (!mounted) return;

    state = state.copyWith(
      imagesData: List.of(state.imagesData)..addAll(newBytes),
      mainImageIndex: 0,
    );

    if (state.editedOfferId == null) return;

    if (apiConfig.uploadImagesImmediately) {
      await _appendImagesToServer(state.editedOfferId!, newBytes);
    }
  }

  Future<void> _appendImagesToServer(int id, List<Uint8List> files) async {
    if (files.isEmpty) return;
    if (!apiConfig.uploadImagesImmediately) return;
    if (apiConfig.appendImagesUrlBuilder == null) return;

    final form = FormData();
    for (int i = 0; i < files.length; i++) {
      form.files.add(
        MapEntry(
          'images',
          MultipartFile.fromBytes(files[i], filename: 'photo_$i.jpg'),
        ),
      );
    }

    final resp = await ApiServices.post(
      apiConfig.appendImagesUrlBuilder!(id.toString()),
      hasToken: true,
      formData: form,
    );

    if (!mounted) return;

    if (resp != null && (resp.statusCode == 200 || resp.statusCode == 201)) {
      List<String> newUrls = state.serverImageUrls;

      try {
        final data = _decodeResponseToMap(resp.data);
        final dynamic rawImgs = data['images'] ?? data['advertisement_images'];
        if (rawImgs is List) {
          final mapped = rawImgs
              .whereType<String>()
              .map((p) => p.startsWith('http') ? p : '${URLs.baseUrl}$p')
              .toList();
          if (mapped.isNotEmpty) {
            newUrls = mapped;
          }
        }
      } catch (_) {}

      state = state.copyWith(
        imagesData: const [],
        serverImageUrls: newUrls,
        mainImageIndex: newUrls.isEmpty ? null : 0,
      );

      await loadOfferData(id, _ref);
    }
  }

  String? _sanitizeDecimal(String input, {int? maxIntDigits}) {
    final s = input.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;

    final d = double.tryParse(s);
    if (d == null) return null;

    if (maxIntDigits != null) {
      final before = d.abs().floor().toString();
      if (before.length > maxIntDigits) return 'OVERFLOW';
    }

    return d.toString();
  }

  Map<String, String> _extractFieldErrors(dynamic raw) {
    try {
      dynamic data = raw;
      if (data is List<int>) {
        data = jsonDecode(utf8.decode(data));
      } else if (data is String) {
        data = jsonDecode(data);
      }

      if (data is Map) {
        final map = <String, String>{};
        data.forEach((k, v) {
          if (v is List) {
            map[k.toString()] = v.join(', ');
          } else {
            map[k.toString()] = v?.toString() ?? '';
          }
        });
        return map;
      }
    } catch (_) {}

    return const {};
  }

  Future<Uint8List?> _downloadImageBytes(String url) async {
    final dio = Dio();
    final token = ApiServices.token?.toString().trim();

    final headerVariants = <Map<String, String>?>[
      null,
      if (token != null && token.isNotEmpty) {'Authorization': 'Token $token'},
      if (token != null && token.isNotEmpty) {'Authorization': 'Bearer $token'},
    ];

    for (final headers in headerVariants) {
      try {
        final response = await dio.get<List<int>>(
          url,
          options: Options(
            headers: headers,
            responseType: ResponseType.bytes,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        final data = response.data;
        if (response.statusCode == 200 && data != null && data.isNotEmpty) {
          return Uint8List.fromList(data);
        }
      } catch (_) {}
    }

    return null;
  }

  Future<List<Uint8List>> _downloadImages(List<String> urls) async {
    final List<Uint8List> result = [];

    for (final url in urls) {
      final bytes = await _downloadImageBytes(url);
      if (bytes != null) {
        result.add(bytes);
      }
    }

    return result;
  }

  Future<List<Uint8List>> _buildPortalOrderedImages() async {
    final localImages = List<Uint8List>.from(state.imagesData);

    if (state.serverImageUrls.isEmpty) {
      return localImages;
    }

    final serverImages = await _downloadImages(state.serverImageUrls);
    return [...localImages, ...serverImages];
  }

  Future<bool> sendData(
    BuildContext context,
    int? offerId, {
    bool isClientPortal = false,
    String? portalUuid,
  }) async {
    String _digits(String s) => s.replaceAll(RegExp(r'[^0-9-]'), '');

    String _offerTypeToApi(String t) {
      final x = t.trim();
      if (x == 'want_to_sell_option'.tr) return 'sell';
      if (x == 'want_to_rent_option'.tr) return 'rent';
      return x;
    }

    String _estateTypeToApi(String t) {
      final m = <String, String>{
        'apartment_option'.tr: 'Flat'.tr,
        'studio_option'.tr: 'Studio'.tr,
        'penthouse_option'.tr: 'Apartment'.tr,
        'house_option'.tr: 'House'.tr,
        'semi_detached_option'.tr: 'Twin house'.tr,
        'townhouse_option'.tr: 'Row house'.tr,
        'investments_option'.tr: 'Invest'.tr,
        'plots_option'.tr: 'Lot'.tr,
        'commercial_option'.tr: 'Commercial'.tr,
        'warehouse_option'.tr: 'Warehouse'.tr,
        'rooms_option'.tr: 'Room'.tr,
        'garages_option'.tr: 'Garage'.tr,
      };
      return m[t] ?? t;
    }

    Map<String, String> fieldErrors = {};

    if (state.titleController.text.isEmpty) {
      fieldErrors['title'] = 'title_required_error'.tr;
    }

    final latSan = _sanitizeDecimal(state.latitudeController.text);
    if (state.latitudeController.text.trim().isNotEmpty && latSan == null) {
      fieldErrors['latitude'] = 'valid_number_required_error'.tr;
    }

    final lngSan = _sanitizeDecimal(state.longitudeController.text);
    if (state.longitudeController.text.trim().isNotEmpty && lngSan == null) {
      fieldErrors['longitude'] = 'valid_number_required_error'.tr;
    }

    final lotSan =
        _sanitizeDecimal(state.lotSizeController.text, maxIntDigits: 7);
    if (state.lotSizeController.text.trim().isNotEmpty) {
      if (lotSan == null) {
        fieldErrors['lot_size'] = 'valid_number_required_error'.tr;
      } else if (lotSan == 'OVERFLOW') {
        fieldErrors['lot_size'] =
            'max_7_digits_before_decimal_error'.tr;
      }
    }

    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: fieldErrors);
      _showSnackSafe(
        context,
        title: 'error_label'.tr,
        message: fieldErrors.values.join('\n'),
        type: "error",
      );
      return false;
    }

    if (ApiServices.token == null) {
      _showSnackSafe(
        context,
        title: 'not_logged_in_title'.tr,
        message:'login_required_to_post_ad'.tr,
        type: "warning",
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      statusMessages: ['preparing_json_status'.tr],
      fieldErrors: const {},
    );

    try {
      final ppm = calculatePricePerMeter(
        state.priceController.text,
        state.squareFootageController.text,
      );

      final priceSan = _sanitizeDecimal(state.priceController.text);
      final squareSan = _sanitizeDecimal(state.squareFootageController.text);
      final lotSizeSan =
          _sanitizeDecimal(state.lotSizeController.text, maxIntDigits: 7);
      final rentSan = _sanitizeDecimal(state.rentController.text);

      final payload = <String, dynamic>{
        'title': state.titleController.text.trim(),
        'description': state.descriptionController.text.trim(),
        'price': priceSan,
        'currency': state.currencyController.text.trim(),
        'estate_type': _estateTypeToApi(state.estateTypeController.text.trim()),
        'building_type': state.buildingTypeController.text.trim(),
        'floor': _digits(state.floorController.text),
        'total_floors': _digits(state.totalFloorsController.text),
        'price_per_meter': ppm > 0 ? ppm.toStringAsFixed(2) : null,
        'street': state.streetController.text.trim(),
        'district': state.districtController.text.trim(),
        'city': state.cityController.text.trim(),
        'country': state.countryController.text.trim(),
        'state': state.stateController.text.trim(),
        'zipcode': _digits(state.zipcodeController.text),
        'rooms': _digits(state.roomsController.text),
        'bathrooms': _digits(state.bathroomsController.text),
        'heating_type': state.heatingTypeController.text.trim(),
        'build_year': _digits(state.buildYearController.text),
        'square_footage': squareSan,
        'lot_size': lotSizeSan,
        'property_form': state.propertyFormController.text.trim(),
        'market_type': state.marketTypeController.text.trim(),
        'offer_type': _offerTypeToApi(state.offerTypeController.text.trim()),
        'building_material': state.buildingMaterialController.text.trim(),
        'phone_number': _digits(state.phoneNumberController.text),
        'phone_number_prefix': state.phoneNumberPrefixController.text.trim(),
        'latitude': latSan,
        'longitude': lngSan,
        'windows': state.windowsController.text.trim(),
        'attic_type': state.atticTypeController.text.trim(),
        'security': state.securityController.text.trim(),
        'premises_location': state.premisesLocationController.text.trim(),
        'purpose': state.purposeController.text.trim(),
        'roof': state.roofController.text.trim(),
        'recreational_house': state.recreationalHouseController.text.trim(),
        'roof_covering': state.roofCoveringController.text.trim(),
        'lightning': state.lightningController.text.trim(),
        'construction': state.constructionController.text.trim(),
        'height': state.heightController.text.trim(),
        'office_rooms': state.officeRoomsController.text.trim(),
        'social_facilities': state.socialFacilitiesController.text.trim(),
        'parking': state.parkingController.text.trim(),
        'ramp': state.rampController.text.trim(),
        'floor_material': state.floorMaterialController.text.trim(),
        'fencing': state.fencingController.text.trim(),
        'access_road': state.accessRoadController.text.trim(),
        'plot_type': state.plotTypeController.text.trim(),
        'dimensions': state.dimensionsController.text.trim(),
        'land_and_mortgage_register':
            state.landAndMortgageRegisterController.text.trim(),
        'estate_condition': state.estateConditionController.text.trim(),
        'remote_service': state.remoteServiceController.text.trim(),
        'rent': rentSan,
        'crm_signature': state.crmSignatureController.text.trim(),
        'balcony': state.balconyController.value,
        'terrace': state.terraceController.value,
        'sauna': state.saunaController.value,
        'jacuzzi': state.jacuzziController.value,
        'basement': state.basementController.value,
        'elevator': state.elevatorController.value,
        'garden': state.gardenController.value,
        'air_conditioning': state.airConditioningController.value,
        'garage': state.garageController.value,
        'parking_space': state.parkingSpaceController.value,
        'electricity': state.electricity.value,
        'energy_certificate': state.energyCertificate.value,
        'water': state.water.value,
        'gas': state.gas.value,
        'phone': state.phone.value,
        'internet': state.internet.value,
        'sewerage': state.sewerage.value,
        'equipment': state.equipment.value,
        'isPremium2': state.isPremium2.value,
        'is_renewable': state.isRenewable.value,
        'is_active': state.isActive.value,
        'crm_block_updates': state.crmBlockUpdates.value,
      };

      payload.remove('images');
      payload.remove('main_image');
      payload.remove('created_at');
      payload.remove('active_validity_date');
      payload.remove('uuid');
      payload.remove('view_count');
      payload.remove('user');
      payload.remove('client');

      payload.removeWhere(
        (k, v) => v == null || (v is String && v.trim().isEmpty),
      );

      Response<dynamic>? response;

      if (apiConfig.isCrm) {
        response = isClientPortal
            ? await ApiServices.post(
                URLsClientPortal.clientPortalSuggestions(portalUuid!),
                hasToken: true,
                data: payload,
              )
            : await ApiServices.patch(
                apiConfig.updateUrlBuilder('${offerId ?? state.editedOfferId}'),
                hasToken: true,
                data: payload,
                formData: null,
              );
      } else {
        final expectedImageCount =
            state.imagesData.length + state.serverImageUrls.length;
        final orderedImages = await _buildPortalOrderedImages();

        if (expectedImageCount > 0 && orderedImages.length != expectedImageCount) {
          _showSnackSafe(
            context,
            title: "Error".tr,
            message:
                'failed_to_prepare_all_photos_error'.tr,
            type: "error",
          );
          return false;
        }

        final formData = FormData.fromMap(payload);

        if (orderedImages.isEmpty) {
          formData.fields.add(const MapEntry('images', ''));
        } else {
          for (int i = 0; i < orderedImages.length; i++) {
            formData.files.add(
              MapEntry(
                'images',
                MultipartFile.fromBytes(
                  orderedImages[i],
                  filename: 'image_$i.jpg',
                ),
              ),
            );
          }
        }

        response = await ApiServices.patch(
          apiConfig.updateUrlBuilder('${offerId ?? state.editedOfferId}'),
          hasToken: true,
          formData: formData,
        );
      }

      if (!mounted) return false;

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        state = state.copyWith(fieldErrors: const {});

        _showSnackSafe(
          context,
          title: "success".tr,
          message: 'advertisement_updated_success'.tr,
          type: "success",
        );

        return true;
      } else {
        final fe = response?.data != null
            ? _extractFieldErrors(response!.data)
            : <String, String>{};

        if (fe.isNotEmpty) {
          state = state.copyWith(fieldErrors: fe);
        }

        final msg = fe.isNotEmpty
            ? fe.entries.map((e) => '${e.key}: ${e.value}').join('\n')
            : (response == null
                ? 'no_response_from_server'.tr
                : response.data.toString());

        _showSnackSafe(
          context,
          title: "Error".tr,
          message: msg,
          type: "error",
        );

        return false;
      }
    } on DioException catch (e) {
      final fe = e.response?.data != null
          ? _extractFieldErrors(e.response!.data)
          : <String, String>{};

      if (fe.isNotEmpty) {
        state = state.copyWith(fieldErrors: fe);
      }

      final flattened = e.response != null
          ? (e.response!.data is String
              ? e.response!.data
              : e.message ??'network_error'.tr)
          : (e.message ?? 'network_error'.tr);

      _showSnackSafe(
        context,
        title: "Error".tr,
        message: flattened,
        type: "error",
      );

      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

class EditOfferState {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController pricePerMeterController;

  final TextEditingController floorController;
  final TextEditingController totalFloorsController;

  final TextEditingController streetController;
  final TextEditingController districtController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipcodeController;
  final TextEditingController countryController;

  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

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

  final TextEditingController phoneNumberController;
  final TextEditingController phoneNumberPrefixController;

  final TextEditingController heatingTypeController;
  final TextEditingController buildYearController;
  final TextEditingController buildingMaterialController;

  final TextEditingController windowsController;
  final TextEditingController atticTypeController;
  final TextEditingController securityController;
  final TextEditingController premisesLocationController;
  final TextEditingController purposeController;
  final TextEditingController roofController;
  final TextEditingController recreationalHouseController;
  final TextEditingController roofCoveringController;
  final TextEditingController lightningController;
  final TextEditingController constructionController;
  final TextEditingController heightController;
  final TextEditingController officeRoomsController;
  final TextEditingController socialFacilitiesController;
  final TextEditingController parkingController;
  final TextEditingController rampController;
  final TextEditingController floorMaterialController;
  final TextEditingController fencingController;
  final TextEditingController accessRoadController;
  final TextEditingController plotTypeController;
  final TextEditingController dimensionsController;

  final TextEditingController uuidController;
  final TextEditingController createdAtController;
  final TextEditingController activeValidityDateController;
  final TextEditingController viewCountController;
  final TextEditingController userController;
  final TextEditingController clientController;

  final TextEditingController rentController;
  final TextEditingController landAndMortgageRegisterController;
  final TextEditingController estateConditionController;
  final TextEditingController remoteServiceController;
  final TextEditingController crmSignatureController;

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

  final ValueNotifier<bool> electricity;
  final ValueNotifier<bool> energyCertificate;
  final ValueNotifier<bool> water;
  final ValueNotifier<bool> gas;
  final ValueNotifier<bool> phone;
  final ValueNotifier<bool> internet;
  final ValueNotifier<bool> sewerage;
  final ValueNotifier<bool> equipment;

  final ValueNotifier<bool> isPremium2;
  final ValueNotifier<bool> isRenewable;
  final ValueNotifier<bool> isActive;
  final ValueNotifier<bool> crmBlockUpdates;

  final Map<String, String> fieldErrors;

  final int? editedOfferId;
  final bool isLoading;
  final List<String> statusMessages;
  final List<String> serverImageUrls;

  EditOfferState({
    this.isLoading = false,
    this.statusMessages = const [],
    this.imagesData = const [],
    this.mainImageIndex,
    TextEditingController? titleController,
    TextEditingController? descriptionController,
    TextEditingController? priceController,
    TextEditingController? pricePerMeterController,
    TextEditingController? floorController,
    TextEditingController? totalFloorsController,
    TextEditingController? streetController,
    TextEditingController? districtController,
    TextEditingController? cityController,
    TextEditingController? stateController,
    TextEditingController? zipcodeController,
    TextEditingController? countryController,
    TextEditingController? latitudeController,
    TextEditingController? longitudeController,
    TextEditingController? roomsController,
    TextEditingController? bathroomsController,
    TextEditingController? squareFootageController,
    TextEditingController? lotSizeController,
    TextEditingController? estateTypeController,
    TextEditingController? buildingTypeController,
    TextEditingController? buildingMaterialController,
    TextEditingController? currencyController,
    TextEditingController? propertyFormController,
    TextEditingController? marketTypeController,
    TextEditingController? offerTypeController,
    TextEditingController? phoneNumberController,
    TextEditingController? phoneNumberPrefixController,
    TextEditingController? heatingTypeController,
    TextEditingController? buildYearController,
    TextEditingController? windowsController,
    TextEditingController? atticTypeController,
    TextEditingController? securityController,
    TextEditingController? premisesLocationController,
    TextEditingController? purposeController,
    TextEditingController? roofController,
    TextEditingController? recreationalHouseController,
    TextEditingController? roofCoveringController,
    TextEditingController? lightningController,
    TextEditingController? constructionController,
    TextEditingController? heightController,
    TextEditingController? officeRoomsController,
    TextEditingController? socialFacilitiesController,
    TextEditingController? parkingController,
    TextEditingController? rampController,
    TextEditingController? floorMaterialController,
    TextEditingController? fencingController,
    TextEditingController? accessRoadController,
    TextEditingController? plotTypeController,
    TextEditingController? dimensionsController,
    TextEditingController? uuidController,
    TextEditingController? createdAtController,
    TextEditingController? activeValidityDateController,
    TextEditingController? viewCountController,
    TextEditingController? userController,
    TextEditingController? clientController,
    TextEditingController? rentController,
    TextEditingController? landAndMortgageRegisterController,
    TextEditingController? estateConditionController,
    TextEditingController? remoteServiceController,
    TextEditingController? crmSignatureController,
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
    ValueNotifier<bool>? electricity,
    ValueNotifier<bool>? energyCertificate,
    ValueNotifier<bool>? water,
    ValueNotifier<bool>? gas,
    ValueNotifier<bool>? phone,
    ValueNotifier<bool>? internet,
    ValueNotifier<bool>? sewerage,
    ValueNotifier<bool>? equipment,
    ValueNotifier<bool>? isPremium2,
    ValueNotifier<bool>? isRenewable,
    ValueNotifier<bool>? isActive,
    ValueNotifier<bool>? crmBlockUpdates,
    this.serverImageUrls = const [],
    this.editedOfferId,
    this.fieldErrors = const {},
  })  : titleController = titleController ?? TextEditingController(),
        descriptionController = descriptionController ?? TextEditingController(),
        priceController = priceController ?? TextEditingController(),
        pricePerMeterController =
            pricePerMeterController ?? TextEditingController(),
        floorController = floorController ?? TextEditingController(),
        totalFloorsController = totalFloorsController ?? TextEditingController(),
        streetController = streetController ?? TextEditingController(),
        districtController = districtController ?? TextEditingController(),
        cityController = cityController ?? TextEditingController(),
        countryController = countryController ?? TextEditingController(),
        stateController = stateController ?? TextEditingController(),
        zipcodeController = zipcodeController ?? TextEditingController(),
        latitudeController = latitudeController ?? TextEditingController(),
        longitudeController = longitudeController ?? TextEditingController(),
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
        buildingMaterialController =
            buildingMaterialController ?? TextEditingController(),
        phoneNumberController =
            phoneNumberController ?? TextEditingController(),
        phoneNumberPrefixController =
            phoneNumberPrefixController ?? TextEditingController(),
        buildYearController = buildYearController ?? TextEditingController(),
        heatingTypeController =
            heatingTypeController ?? TextEditingController(),
        windowsController = windowsController ?? TextEditingController(),
        atticTypeController = atticTypeController ?? TextEditingController(),
        securityController = securityController ?? TextEditingController(),
        premisesLocationController =
            premisesLocationController ?? TextEditingController(),
        purposeController = purposeController ?? TextEditingController(),
        roofController = roofController ?? TextEditingController(),
        recreationalHouseController =
            recreationalHouseController ?? TextEditingController(),
        roofCoveringController =
            roofCoveringController ?? TextEditingController(),
        lightningController = lightningController ?? TextEditingController(),
        constructionController =
            constructionController ?? TextEditingController(),
        heightController = heightController ?? TextEditingController(),
        officeRoomsController = officeRoomsController ?? TextEditingController(),
        socialFacilitiesController =
            socialFacilitiesController ?? TextEditingController(),
        parkingController = parkingController ?? TextEditingController(),
        rampController = rampController ?? TextEditingController(),
        floorMaterialController =
            floorMaterialController ?? TextEditingController(),
        fencingController = fencingController ?? TextEditingController(),
        accessRoadController = accessRoadController ?? TextEditingController(),
        plotTypeController = plotTypeController ?? TextEditingController(),
        dimensionsController = dimensionsController ?? TextEditingController(),
        uuidController = uuidController ?? TextEditingController(),
        createdAtController = createdAtController ?? TextEditingController(),
        activeValidityDateController =
            activeValidityDateController ?? TextEditingController(),
        viewCountController = viewCountController ?? TextEditingController(),
        userController = userController ?? TextEditingController(),
        clientController = clientController ?? TextEditingController(),
        rentController = rentController ?? TextEditingController(),
        landAndMortgageRegisterController =
            landAndMortgageRegisterController ?? TextEditingController(),
        estateConditionController =
            estateConditionController ?? TextEditingController(),
        remoteServiceController =
            remoteServiceController ?? TextEditingController(),
        crmSignatureController =
            crmSignatureController ?? TextEditingController(),
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
            parkingSpaceController ?? ValueNotifier<bool>(false),
        electricity = electricity ?? ValueNotifier<bool>(false),
        energyCertificate = energyCertificate ?? ValueNotifier<bool>(false),
        water = water ?? ValueNotifier<bool>(false),
        gas = gas ?? ValueNotifier<bool>(false),
        phone = phone ?? ValueNotifier<bool>(false),
        internet = internet ?? ValueNotifier<bool>(false),
        sewerage = sewerage ?? ValueNotifier<bool>(false),
        equipment = equipment ?? ValueNotifier<bool>(false),
        isPremium2 = isPremium2 ?? ValueNotifier<bool>(false),
        isRenewable = isRenewable ?? ValueNotifier<bool>(false),
        isActive = isActive ?? ValueNotifier<bool>(false),
        crmBlockUpdates = crmBlockUpdates ?? ValueNotifier<bool>(false);

  EditOfferState copyWith({
    List<Uint8List>? imagesData,
    int? mainImageIndex,
    TextEditingController? titleController,
    TextEditingController? descriptionController,
    TextEditingController? priceController,
    TextEditingController? pricePerMeterController,
    TextEditingController? floorController,
    TextEditingController? totalFloorsController,
    TextEditingController? streetController,
    TextEditingController? districtController,
    TextEditingController? cityController,
    TextEditingController? stateController,
    TextEditingController? zipcodeController,
    TextEditingController? countryController,
    TextEditingController? latitudeController,
    TextEditingController? longitudeController,
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
    TextEditingController? buildingMaterialController,
    TextEditingController? phoneNumberController,
    TextEditingController? phoneNumberPrefixController,
    TextEditingController? heatingTypeController,
    TextEditingController? buildYearController,
    TextEditingController? windowsController,
    TextEditingController? atticTypeController,
    TextEditingController? securityController,
    TextEditingController? premisesLocationController,
    TextEditingController? purposeController,
    TextEditingController? roofController,
    TextEditingController? recreationalHouseController,
    TextEditingController? roofCoveringController,
    TextEditingController? lightningController,
    TextEditingController? constructionController,
    TextEditingController? heightController,
    TextEditingController? officeRoomsController,
    TextEditingController? socialFacilitiesController,
    TextEditingController? parkingController,
    TextEditingController? rampController,
    TextEditingController? floorMaterialController,
    TextEditingController? fencingController,
    TextEditingController? accessRoadController,
    TextEditingController? plotTypeController,
    TextEditingController? dimensionsController,
    TextEditingController? uuidController,
    TextEditingController? createdAtController,
    TextEditingController? activeValidityDateController,
    TextEditingController? viewCountController,
    TextEditingController? userController,
    TextEditingController? clientController,
    TextEditingController? rentController,
    TextEditingController? landAndMortgageRegisterController,
    TextEditingController? estateConditionController,
    TextEditingController? remoteServiceController,
    TextEditingController? crmSignatureController,
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
    ValueNotifier<bool>? electricity,
    ValueNotifier<bool>? energyCertificate,
    ValueNotifier<bool>? water,
    ValueNotifier<bool>? gas,
    ValueNotifier<bool>? phone,
    ValueNotifier<bool>? internet,
    ValueNotifier<bool>? sewerage,
    ValueNotifier<bool>? equipment,
    ValueNotifier<bool>? isPremium2,
    ValueNotifier<bool>? isRenewable,
    ValueNotifier<bool>? isActive,
    ValueNotifier<bool>? crmBlockUpdates,
    bool? isLoading,
    List<String>? statusMessages,
    List<String>? serverImageUrls,
    int? editedOfferId,
    Map<String, String>? fieldErrors,
  }) {
    return EditOfferState(
      imagesData: imagesData ?? this.imagesData,
      mainImageIndex: mainImageIndex ?? this.mainImageIndex,
      titleController: titleController ?? this.titleController,
      descriptionController: descriptionController ?? this.descriptionController,
      priceController: priceController ?? this.priceController,
      pricePerMeterController:
          pricePerMeterController ?? this.pricePerMeterController,
      floorController: floorController ?? this.floorController,
      totalFloorsController:
          totalFloorsController ?? this.totalFloorsController,
      streetController: streetController ?? this.streetController,
      districtController: districtController ?? this.districtController,
      cityController: cityController ?? this.cityController,
      stateController: stateController ?? this.stateController,
      zipcodeController: zipcodeController ?? this.zipcodeController,
      countryController: countryController ?? this.countryController,
      latitudeController: latitudeController ?? this.latitudeController,
      longitudeController: longitudeController ?? this.longitudeController,
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
      buildingMaterialController:
          buildingMaterialController ?? this.buildingMaterialController,
      phoneNumberController:
          phoneNumberController ?? this.phoneNumberController,
      phoneNumberPrefixController:
          phoneNumberPrefixController ?? this.phoneNumberPrefixController,
      buildYearController: buildYearController ?? this.buildYearController,
      heatingTypeController:
          heatingTypeController ?? this.heatingTypeController,
      windowsController: windowsController ?? this.windowsController,
      atticTypeController: atticTypeController ?? this.atticTypeController,
      securityController: securityController ?? this.securityController,
      premisesLocationController:
          premisesLocationController ?? this.premisesLocationController,
      purposeController: purposeController ?? this.purposeController,
      roofController: roofController ?? this.roofController,
      recreationalHouseController:
          recreationalHouseController ?? this.recreationalHouseController,
      roofCoveringController:
          roofCoveringController ?? this.roofCoveringController,
      lightningController: lightningController ?? this.lightningController,
      constructionController:
          constructionController ?? this.constructionController,
      heightController: heightController ?? this.heightController,
      officeRoomsController:
          officeRoomsController ?? this.officeRoomsController,
      socialFacilitiesController:
          socialFacilitiesController ?? this.socialFacilitiesController,
      parkingController: parkingController ?? this.parkingController,
      rampController: rampController ?? this.rampController,
      floorMaterialController:
          floorMaterialController ?? this.floorMaterialController,
      fencingController: fencingController ?? this.fencingController,
      accessRoadController: accessRoadController ?? this.accessRoadController,
      plotTypeController: plotTypeController ?? this.plotTypeController,
      dimensionsController: dimensionsController ?? this.dimensionsController,
      uuidController: uuidController ?? this.uuidController,
      createdAtController: createdAtController ?? this.createdAtController,
      activeValidityDateController:
          activeValidityDateController ?? this.activeValidityDateController,
      viewCountController: viewCountController ?? this.viewCountController,
      userController: userController ?? this.userController,
      clientController: clientController ?? this.clientController,
      rentController: rentController ?? this.rentController,
      landAndMortgageRegisterController:
          landAndMortgageRegisterController ??
              this.landAndMortgageRegisterController,
      estateConditionController:
          estateConditionController ?? this.estateConditionController,
      remoteServiceController:
          remoteServiceController ?? this.remoteServiceController,
      crmSignatureController:
          crmSignatureController ?? this.crmSignatureController,
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
      electricity: electricity ?? this.electricity,
      energyCertificate: energyCertificate ?? this.energyCertificate,
      water: water ?? this.water,
      gas: gas ?? this.gas,
      phone: phone ?? this.phone,
      internet: internet ?? this.internet,
      sewerage: sewerage ?? this.sewerage,
      equipment: equipment ?? this.equipment,
      isPremium2: isPremium2 ?? this.isPremium2,
      isRenewable: isRenewable ?? this.isRenewable,
      isActive: isActive ?? this.isActive,
      crmBlockUpdates: crmBlockUpdates ?? this.crmBlockUpdates,
      isLoading: isLoading ?? this.isLoading,
      statusMessages: statusMessages ?? this.statusMessages,
      serverImageUrls: serverImageUrls ?? this.serverImageUrls,
      editedOfferId: editedOfferId ?? this.editedOfferId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

final adEditingProvider = StateProvider.family<bool, Object>((ref, adId) {
  debugPrint(
    '🔍 adEditingProvider - Creating new state for adId: $adId with value: false',
  );
  return false;
});

final adMapActivatedProvider =
    StateProvider.family<bool, Object>((ref, adId) => false);

final adMainImageUrlProvider =
    StateProvider.family<String, Object>((ref, adId) => '');