import 'package:crm_agent/add_client_form/components/usercontact/user_contact_custom_text_field.dart';
import 'package:core/settings/settings.dart';
import 'package:crm_agent/add_client_form/components/usercontact/usercontact_custom_drop_down.dart';
import 'package:crm_agent/add_client_form/provider/contact_type_provider.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/common/shared_widgets/gradient_dropdown.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/common/shared_widgets/global_dropdown.dart';
import 'package:core/common/shared_widgets/country_model.dart';



class AddUserContactsCrm extends ConsumerStatefulWidget {
  final GlobalKey<FormState>? viewFormKey;
  final GlobalKey<FormState>? sellFormKey;
  final GlobalKey<FormState>? buyFormKey;
  final bool isMobile;

  const AddUserContactsCrm({
    super.key,
    this.viewFormKey,
    this.sellFormKey,
    this.buyFormKey,
    this.isMobile = false,
  });

  @override
  ConsumerState<AddUserContactsCrm> createState() => _AddUserContactsCrmState();
}

class _AddUserContactsCrmState extends ConsumerState<AddUserContactsCrm> {
  // Gender options (key -> label)
  final Map<String, String> kGenderOptions = const {
    '1': 'Male',
    '2': 'Female',
    '3': 'Other',
  };

  late final TextEditingController _phonePrefixController;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _phoneReqNode;
  late final FocusNode _nameFocusNode;
  late final FocusNode _lastNameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _nationalityFocusNode;

  @override
  void initState() {
    super.initState();
    getData();

    _phoneFocusNode = FocusNode();
    _phoneReqNode = FocusNode();
    _nameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _nationalityFocusNode = FocusNode();

    final current = ref.read(addClientFormProvider);
    _phonePrefixController = TextEditingController(
      text: current.clientPhoneNumberPrefix ?? '+48',
    );

    _phonePrefixController.addListener(() {
      ref
          .read(addClientFormProvider.notifier)
          .setPhoneNumberPrefix(_phonePrefixController.text);
    });
  }

  @override
  void dispose() {
    _phonePrefixController.dispose();
    _phoneFocusNode.dispose();
    _phoneReqNode.dispose();
    _nameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _nationalityFocusNode.dispose();
    super.dispose();
  }

  void getData() async {
    final provider = ref.read(contactTypeProvider);
    await Future.wait([
      provider.getContactType(ref),
      provider.getContactStatus(ref),
      provider.getContactServiceType(ref),
      provider.getUserDetails(ref),
    ]);
    provider.resetState();
  }

  void _syncPrefixController(AddClientFormState state) {
    final desired = state.clientPhoneNumberPrefix ?? '';
    if (_phonePrefixController.text != desired) {
      _phonePrefixController.value = _phonePrefixController.value.copyWith(
        text: desired,
        selection: TextSelection.collapsed(offset: desired.length),
      );
    }
  }

  DropDownCountry? _findCountryByName(
    List<DropDownCountry> items,
    String? name,
  ) {
    if (name == null || name.trim().isEmpty) return null;
    final n = name.trim().toLowerCase();
    for (final c in items) {
      if (c.name.toLowerCase() == n) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final addClientForm = ref.watch(addClientFormProvider);
    final addClientFormNotifier = ref.read(addClientFormProvider.notifier);
    final selectedClientId = addClientForm.selectedClientId;

    final theme = ref.watch(themeColorsProvider);
    final contactTypeState = ref.watch(contactTypeProvider);
    final locationState = ref.watch(locationProviderSettingsProfile);

    final selectedNationality = _findCountryByName(locationState.countries, addClientForm.clientNationality);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPrefixController(addClientForm);
    });

    return Column(
      spacing: 20,
      children: [
        if (ref.watch(showUserContactsProvider))
          Container(
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.themeColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6),
                      topLeft: Radius.circular(6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'USER CONTACTS'.tr,
                          style: TextStyle(
                            color: theme.themeTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: ElevatedButton(
                            style: elevatedButtonStyleRounded10,
                            onPressed: () {
                              ref.read(showUserContactsProvider.notifier).state =
                                  false;
                            },
                            child: Icon(
                              Icons.expand_more,
                              color: theme.themeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Form(
                    key: widget.viewFormKey,
                    child: Column(
                      spacing: 12,
                      children: [
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: UserContactCustomTextField(
                                id: 1,
                                focusNode: _nameFocusNode,
                                nextFocusNode: _lastNameFocusNode,
                                textInputAction: TextInputAction.next,
                                hintText: 'Name'.tr,
                                valueKey: 'name',
                                formatThousands: false,
                                controller: addClientForm.clientNameController,
                                validator: (value) {
                                  if (selectedClientId != null) return null;
                                  if (value == null || value.isEmpty) {
                                    return "First Name cannot be empty".tr;
                                  }
                                  return null;
                                },
                                onChanged: (valueKey, value) {
                                  addClientFormNotifier.updateTextField(
                                    addClientForm.clientNameController,
                                    value,
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: UserContactCustomTextField(
                                id: 2,
                                focusNode: _lastNameFocusNode,
                                nextFocusNode: _phoneFocusNode,
                                textInputAction: TextInputAction.next,
                                valueKey: 'last_name',
                                hintText: 'Last Name'.tr,
                                formatThousands: false,
                                controller:
                                    addClientForm.clientLastNameController,
                                onChanged: (valueKey, value) {
                                  addClientFormNotifier.updateTextField(
                                    addClientForm.clientLastNameController,
                                    value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        Divider(color: theme.textColor.withAlpha(120)),

                        Row(
                          children: [
                            Expanded(
                              child: GradientTextField(
                                reqNode: _emailFocusNode,
                                textInputAction: TextInputAction.next,
                                isPhoneField: true,
                                countryCodeController: _phonePrefixController,
                                countryCodeHint: '',
                                hintText: 'Phone'.tr,
                                label: 'Phone'.tr,
                                controller:
                                    addClientForm.clientPhoneNumberController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                            
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: UserContactCustomTextField(
                                id: 3,
                                focusNode: _emailFocusNode,
                                nextFocusNode: _nationalityFocusNode,
                                textInputAction: TextInputAction.next,
                                valueKey: 'email',
                                hintText: 'Email'.tr,
                                formatThousands: false,
                                controller: addClientForm.clientEmailController,
                                onChanged: (valueKey, value) {
                                  addClientFormNotifier.updateTextField(
                                    addClientForm.clientEmailController,
                                    value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // ✅ Nationality (TypeAhead with flags)
                        
                        // ✅ Phone + DOB + Gender
                        if(!widget.isMobile)...[
                          
                        Row(
                          spacing: 12,
                          children: [
                            
                            Expanded(
                              child: GradientDropdownReportCountry(
                                focusNode: _nationalityFocusNode,
                                isPc: !widget.isMobile,
                                value: selectedNationality,
                                hintText: 'nationality'.tr,
                                items: locationState.countries,
                                selectedItem: selectedNationality,
                                onChanged: (country) {
                                  ref.read(addClientFormProvider.notifier)
                                      .setNationality(country?.name);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GradientDropdownKV(
                                isPc: !widget.isMobile,
                                hintText: 'Gender'.tr,
                                items: kGenderOptions,
                                selectedKey: addClientForm.clientGender,
                                onChangedKey: (key) {
                                  ref
                                      .read(addClientFormProvider.notifier)
                                      .setGender(key);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GradientDateDropdown(
                                value: "",
                                isPc: !widget.isMobile,
                                selectedDate: addClientForm.clientBirthDate,
                                hintText: 'Date Of Birth'.tr,
                                onDateSelected: (date) {
                                  ref
                                      .read(addClientFormProvider.notifier)
                                      .setBirthDate(date);
                                },
                              ),
                            ),
                          ],
                        ),

                        ],


                        
                        // ✅ Phone + DOB + Gender
                        if(widget.isMobile)...[
                          
                        Column(
                          spacing: 12,
                          children: [
                            
                            Row(
                              children: [
                                Expanded(
                                  child: GradientDropdownReportCountry(
                                    isPc: !widget.isMobile,
                                    value: selectedNationality,
                                    hintText: 'nationality'.tr,
                                    items: locationState.countries,
                                    selectedItem: selectedNationality,
                                    onChanged: (country) {
                                      ref.read(addClientFormProvider.notifier)
                                          .setNationality(country?.name);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GradientDropdownKV(
                                    isPc: !widget.isMobile,
                                    hintText: 'Gender'.tr,
                                    items: kGenderOptions,
                                    selectedKey: addClientForm.clientGender,
                                    onChangedKey: (key) {
                                      ref
                                          .read(addClientFormProvider.notifier)
                                          .setGender(key);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GradientDateDropdown(
                                    value: "",
                                    isPc: !widget.isMobile,
                                    selectedDate: addClientForm.clientBirthDate,
                                    hintText: 'Date Of Birth'.tr,
                                    onDateSelected: (date) {
                                      ref
                                          .read(addClientFormProvider.notifier)
                                          .setBirthDate(date);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        ],
                        


                        Divider(color: theme.textColor.withAlpha(120)),

                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: AddClientFormCustomDropDown(
                                id: 109,
                                hintText: 'Contact Status'.tr,
                                valueKey: 'contact_status',
                                options: contactTypeState.contactStatus
                                    .map((e) => e.statusName)
                                    .toList(),
                                values: contactTypeState.contactStatus
                                    .map((e) => e.statusId.toString())
                                    .toList(),
                                // Fix: reroute do addClientFormProvider (było trafiało do sell draft cache)
                                onChangedExtra: (value, _, __) {
                                  addClientFormNotifier.setContactStatus(
                                    value.trim().isEmpty ? null : value,
                                  );
                                  ref.read(sellOfferFilterCacheProvider.notifier)
                                      .removeData('contact_status');
                                },
                              ),
                            ),
                          ],
                        ),

                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: AddClientFormCustomDropDown(
                                id: 101,
                                hintText: 'Contact type'.tr,
                                valueKey: 'contact_type',
                                options: contactTypeState.contactType
                                    .map((e) => e.displayLabel)
                                    .toList(),
                                values: contactTypeState.contactType
                                    .map((e) => e.idAsString)
                                    .toList(),
                                // Fix: reroute do addClientFormProvider
                                onChangedExtra: (value, _, __) {
                                  addClientFormNotifier.setContactType(
                                    value.trim().isEmpty ? null : value,
                                  );
                                  ref.read(sellOfferFilterCacheProvider.notifier)
                                      .removeData('contact_type');
                                },
                              ),
                            ),
                          ],
                        ),

                        Divider(color: theme.textColor.withAlpha(120)),

                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: AddClientFormCustomDropDown(
                                id: 103,
                                hintText: 'Responsible Person'.tr,
                                valueKey: 'responsible_person',
                                options: contactTypeState.userModel?.companyMembers
                                        .map((m) =>
                                            '${m.firstName} ${m.lastName}')
                                        .toList() ??
                                    const [],
                                values: contactTypeState.userModel?.companyMembers
                                        .map((m) => m.id.toString())
                                        .toList() ??
                                    const [],
                                // Fix: reroute do addClientFormProvider
                                onChangedExtra: (value, _, __) {
                                  addClientFormNotifier.setResponsiblePerson(
                                    value.trim().isEmpty ? null : value,
                                  );
                                  ref.read(sellOfferFilterCacheProvider.notifier)
                                      .removeData('responsible_person');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
