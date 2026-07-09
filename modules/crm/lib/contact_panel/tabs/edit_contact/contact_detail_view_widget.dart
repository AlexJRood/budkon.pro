import 'package:crm/shared/models/clients_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/gus.dart';
import 'package:core/platform/values.dart';
import 'package:core/common/shared_widgets/gradient_dropdown.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:crm/contact_panel/data/invoice_data_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class ContactDetailViewWidget extends ConsumerStatefulWidget {
  const ContactDetailViewWidget({super.key});

  @override
  ConsumerState<ContactDetailViewWidget> createState() =>
      _ContactDetailViewWidgetState();
}

class _ContactDetailViewWidgetState
    extends ConsumerState<ContactDetailViewWidget> {
  int? _loadedContactId;
  String? _loadedInvoiceSignature;

  final CoreContractorVerificationService _verificationService =
      const CoreContractorVerificationService();

  bool _isCheckingContractor = false;
  bool _invoiceDetailsExpanded = false;

  /// Prevents _syncFormWithContact from resetting controllers while we are
  /// applying a GUS suggestion and rebuilding the expanded form.
  bool _isApplyingGusSuggestion = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(invoiceFormProvider.notifier).clear();
    });
  }

  String _clean(String? value) => (value ?? '').trim();

  bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasAnyInvoiceFormValue(InvoiceFormState form) {
    return [
      form.legalNameController.text,
      form.nipController.text,
      form.regonController.text,
      form.notesController.text,
      form.contactPersonController.text,
      form.bankAccountController.text,
      form.websiteController.text,
      form.registeredCountryController.text,
      form.registeredCityController.text,
      form.registeredStreetController.text,
      form.registeredPostalCodeController.text,
    ].any((value) => value.trim().isNotEmpty);
  }

  bool _hasAnyInvoiceDetailsValue(InvoiceFormState form) {
    return [
      form.legalNameController.text,
      form.notesController.text,
      form.contactPersonController.text,
      form.bankAccountController.text,
      form.websiteController.text,
      form.registeredCountryController.text,
      form.registeredCityController.text,
      form.registeredStreetController.text,
      form.registeredPostalCodeController.text,
    ].any((value) => value.trim().isNotEmpty);
  }

  bool _shouldShowInvoiceDetails({
    required InvoiceFormState form,
    required UserContactModel? contact,
  }) {
    return _invoiceDetailsExpanded ||
        contact?.invoiceData?.id != null ||
        _hasAnyInvoiceDetailsValue(form);
  }

  void _syncFormWithContact({
    required InvoiceFormState form,
    required UserContactModel? userContact,
  }) {
    if (userContact == null) return;
    if (_isApplyingGusSuggestion) return;

    final contactId = userContact.id;
    final invoiceSignature =
        '${userContact.id}:${userContact.invoiceData?.id ?? 'empty'}';

    final shouldResetContact = _loadedContactId != contactId;
    final shouldResetInvoice = _loadedInvoiceSignature != invoiceSignature;

    if (!shouldResetContact && !shouldResetInvoice) return;

    _loadedContactId = contactId;
    _loadedInvoiceSignature = invoiceSignature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isApplyingGusSuggestion) return;

      final latestForm = ref.read(invoiceFormProvider);
      final latestContact = ref.read(activeContactProvider);

      if (latestContact == null || latestContact.id != contactId) return;

      if (shouldResetContact) {
        resetContactForm(latestForm, latestContact, ref);
      }

      if (shouldResetInvoice) {
        resetInvoiceForm(latestForm, latestContact.invoiceData, ref);
      }

      final shouldExpandInvoice = latestContact.invoiceData?.id != null ||
          _hasAnyInvoiceDetailsValue(latestForm);

      if (mounted) {
        setState(() {
          _invoiceDetailsExpanded = shouldExpandInvoice;
        });
      }
    });
  }

  void detectContactChanges(
    WidgetRef ref,
    InvoiceFormState form,
    UserContactModel userContact,
  ) {
    final hasChanges =
        _clean(form.firstNameController.text) != _clean(userContact.name) ||
            _clean(form.lastNameController.text) !=
                _clean(userContact.lastName) ||
            _clean(form.emailController.text) != _clean(userContact.email) ||
            _clean(form.phoneController.text) !=
                _clean(userContact.phoneNumber) ||
            _clean(form.gender) != _clean(userContact.gender) ||
            _clean(form.country) != _clean(userContact.nationality) ||
            !_sameDate(form.birthDate, userContact.birthDate);

    ref.read(contactEditStateProvider.notifier).state = hasChanges;
  }

  void resetContactForm(
    InvoiceFormState form,
    UserContactModel userContact,
    WidgetRef ref,
  ) {
    form.firstNameController.text = userContact.name;
    form.lastNameController.text = userContact.lastName ?? '';
    form.emailController.text = userContact.email ?? '';
    form.phoneController.text = userContact.phoneNumber ?? '';
    form.gender = userContact.gender ?? '';
    form.country = userContact.nationality ?? '';
    form.birthDate = userContact.birthDate;

    ref.read(contactEditStateProvider.notifier).state = false;
  }

  void resetInvoiceForm(
    InvoiceFormState form,
    InvoiceDataModel? data,
    WidgetRef ref,
  ) {
    form.legalNameController.text = data?.legalName ?? '';
    form.nipController.text = data?.nip ?? '';
    form.regonController.text = data?.regon ?? '';
    form.notesController.text = data?.notes ?? '';
    form.contactPersonController.text = data?.contactPerson ?? '';
    form.bankAccountController.text = data?.bankAccount ?? '';
    form.websiteController.text = data?.website ?? '';
    form.registeredCountryController.text = data?.registeredCountry ?? '';
    form.registeredCityController.text = data?.registeredCity ?? '';
    form.registeredStreetController.text = data?.registeredStreet ?? '';
    form.registeredPostalCodeController.text = data?.registeredPostalCode ?? '';

    ref.read(invoiceEditStateProvider.notifier).state = false;
  }

  void detectInvoiceChanges(
    WidgetRef ref,
    InvoiceFormState form,
    UserContactModel? userContact,
  ) {
    final data = userContact?.invoiceData;

    final bool hasChanges;

    if (data == null) {
      hasChanges = _hasAnyInvoiceFormValue(form);
    } else {
      hasChanges =
          _clean(form.legalNameController.text) != _clean(data.legalName) ||
              _clean(form.nipController.text) != _clean(data.nip) ||
              _clean(form.regonController.text) != _clean(data.regon) ||
              _clean(form.notesController.text) != _clean(data.notes) ||
              _clean(form.contactPersonController.text) !=
                  _clean(data.contactPerson) ||
              _clean(form.bankAccountController.text) !=
                  _clean(data.bankAccount) ||
              _clean(form.websiteController.text) != _clean(data.website) ||
              _clean(form.registeredCountryController.text) !=
                  _clean(data.registeredCountry) ||
              _clean(form.registeredCityController.text) !=
                  _clean(data.registeredCity) ||
              _clean(form.registeredStreetController.text) !=
                  _clean(data.registeredStreet) ||
              _clean(form.registeredPostalCodeController.text) !=
                  _clean(data.registeredPostalCode);
    }

    ref.read(invoiceEditStateProvider.notifier).state = hasChanges;
  }

  void _saveContactData({
    required InvoiceFormState form,
    required UserContactModel userContact,
  }) {
    ref.read(activeContactProvider.notifier).updateUserContactData(
          clientId: userContact.id.toString(),
          form: form,
          ref: ref,
        );
  }

  void _saveInvoiceData({
    required BuildContext context,
    required InvoiceFormState form,
    required UserContactModel userContact,
  }) {
    final invoiceDataId = userContact.invoiceData?.id;
    final notifier = ref.read(activeContactProvider.notifier);

    if (invoiceDataId != null) {
      notifier.updateInvoiceData(
        invoiceDataId: invoiceDataId.toString(),
        clientId: userContact.id.toString(),
        form: form,
        ref: ref,
      );
      return;
    }

    notifier.createInvoiceData(
      clientId: userContact.id.toString(),
      form: form,
      ref: ref,
    );
  }

  Future<void> _checkContractor({
    required InvoiceFormState form,
    required UserContactModel userContact,
  }) async {
    if (_isCheckingContractor) return;

    setState(() => _isCheckingContractor = true);

    try {
      final result = await _verificationService.checkContractor(
        ref: ref,
        contactId: userContact.id,
        nip: form.nipController.text,
        regon: form.regonController.text,
        bankAccount: form.bankAccountController.text,
        saveHistory: true,
      );

      if (!mounted) return;

      await CoreContractorVerificationDialog.show(
        context,
        result: result,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'Nie udało się zweryfikować kontrahenta'.tr}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingContractor = false);
      }
    }
  }

  Widget _verificationButton({
    required ThemeColors theme,
    required InvoiceFormState form,
    required UserContactModel? contact,
  }) {
    final hasIdentifier = form.nipController.text.trim().isNotEmpty ||
        form.regonController.text.trim().isNotEmpty ||
        (contact?.invoiceData?.nip?.trim().isNotEmpty ?? false) ||
        (contact?.invoiceData?.regon?.trim().isNotEmpty ?? false);

    return OutlinedButton.icon(
      onPressed: !hasIdentifier || contact == null || _isCheckingContractor
          ? null
          : () {
              _checkContractor(
                form: form,
                userContact: contact,
              );
            },
      icon: _isCheckingContractor
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.themeColor,
              ),
            )
          : const Icon(Icons.verified_user_outlined, size: 18),
      label: Text(
        _isCheckingContractor
            ? 'Sprawdzanie...'.tr
            : 'Sprawdź kontrahenta'.tr,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.themeColor,
        side: BorderSide(color: theme.themeColor.withOpacity(0.35)),
        minimumSize: const Size(170, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _invoiceExpandButton({
    required ThemeColors theme,
    required bool expanded,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _invoiceDetailsExpanded = !_invoiceDetailsExpanded;
        });
      },
      icon: Icon(
        expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
        size: 18,
      ),
      label: Text(
        expanded ? 'Zwiń'.tr : 'Rozwiń formularz'.tr,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor.withOpacity(0.82),
        side: BorderSide(color: theme.textColor.withOpacity(0.18)),
        minimumSize: const Size(142, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _invoiceHeaderActions({
    required ThemeColors theme,
    required InvoiceFormState form,
    required UserContactModel? contact,
    required bool expanded,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _invoiceExpandButton(
          theme: theme,
          expanded: expanded,
        ),
        _verificationButton(
          theme: theme,
          form: form,
          contact: contact,
        ),
      ],
    );
  }

  String _gusValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  String _firstGusValue(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      for (final key in keys) {
        final value = _gusValue(map, key);
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
    }

    return '';
  }

  String _joinGusParts(List<String> parts) {
    return parts
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .join(' ')
        .trim();
  }

  String _normalizeRegisteredCountryName(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    final exactMatch = countries.where((country) {
      final name = country['name']?.toString() ?? '';
      return name.toLowerCase() == raw.toLowerCase();
    });

    if (exactMatch.isNotEmpty) {
      return exactMatch.first['name']?.toString() ?? raw;
    }

    final normalized = raw.toUpperCase();

    if (normalized == 'PL' || normalized == 'POLSKA' || normalized == 'POLAND') {
      final plMatch = countries.where((country) {
        final name = country['name']?.toString().toLowerCase() ?? '';
        final isoCode = country['isoCode']?.toString().toUpperCase() ??
            country['code']?.toString().toUpperCase() ??
            country['flag']?.toString().toUpperCase() ??
            '';

        return isoCode == 'PL' || name == 'polska' || name == 'poland';
      });

      if (plMatch.isNotEmpty) {
        return plMatch.first['name']?.toString() ?? raw;
      }
    }

    return raw;
  }

  void _setControllerIfNotEmpty(
    TextEditingController controller,
    String value, {
    bool overwrite = true,
  }) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return;
    }

    if (!overwrite && controller.text.trim().isNotEmpty) {
      return;
    }

    controller.text = normalized;
  }

  void _applyGusInvoiceSuggestion({
    required CoreGusSuggestion suggestion,
    required InvoiceFormState form,
    required UserContactModel? userContact,
  }) {
    _isApplyingGusSuggestion = true;

    setState(() {
      _invoiceDetailsExpanded = true;
    });

    try {
      final invoice = suggestion.invoiceDataPrefill;
      final company = suggestion.companyPrefill;
      final contractor = suggestion.contractorPrefill;

      final maps = <Map<String, dynamic>>[
        invoice,
        contractor,
        company,
      ];

      final legalName = _firstGusValue(
        maps,
        [
          'legal_name',
          'company_name',
          'name',
          'nazwa',
          'Nazwa',
        ],
      );

      final nip = _firstGusValue(
        maps,
        [
          'nip',
          'Nip',
          'tax_id',
        ],
      ).isNotEmpty
          ? _firstGusValue(
              maps,
              [
                'nip',
                'Nip',
                'tax_id',
              ],
            )
          : (suggestion.nip ?? '');

      final regon = _firstGusValue(
        maps,
        [
          'regon',
          'Regon',
        ],
      ).isNotEmpty
          ? _firstGusValue(
              maps,
              [
                'regon',
                'Regon',
              ],
            )
          : (suggestion.regon ?? '');

      final registeredCountry = _normalizeRegisteredCountryName(
        _firstGusValue(
          maps,
          [
            'registered_country',
            'reg_country',
            'country',
            'kraj',
            'Kraj',
          ],
        ),
      );

      final registeredCity = _firstGusValue(
        maps,
        [
          'registered_city',
          'reg_city',
          'city',
          'miejscowosc',
          'Miejscowosc',
        ],
      );

      final registeredStreetDirect = _firstGusValue(
        maps,
        [
          'registered_street',
          'street',
          'address',
          'reg_address',
          'Ulica',
          'ulica',
        ],
      );

      final registeredStreet = registeredStreetDirect.isNotEmpty
          ? registeredStreetDirect
          : _joinGusParts(
              [
                _firstGusValue(
                  maps,
                  [
                    'reg_street',
                    'street_name',
                    'Ulica',
                    'ulica',
                  ],
                ),
                _firstGusValue(
                  maps,
                  [
                    'reg_street_number',
                    'street_number',
                    'building_number',
                    'NrNieruchomosci',
                    'nr_nieruchomosci',
                  ],
                ),
                _firstGusValue(
                  maps,
                  [
                    'apartment_number',
                    'NrLokalu',
                    'nr_lokalu',
                  ],
                ).isNotEmpty
                    ? '/${_firstGusValue(
                        maps,
                        [
                          'apartment_number',
                          'NrLokalu',
                          'nr_lokalu',
                        ],
                      )}'
                    : '',
              ],
            );

      final registeredPostalCode = _firstGusValue(
        maps,
        [
          'registered_postal_code',
          'reg_postal_code',
          'postal_code',
          'KodPocztowy',
          'kod_pocztowy',
        ],
      );

      final notes = _firstGusValue(
        maps,
        [
          'notes',
          'note',
        ],
      ).isNotEmpty
          ? _firstGusValue(
              maps,
              [
                'notes',
                'note',
              ],
            )
          : 'Dane pobrane automatycznie z GUS BIR po numerze NIP.';

      _setControllerIfNotEmpty(form.legalNameController, legalName);
      _setControllerIfNotEmpty(form.nipController, nip);
      _setControllerIfNotEmpty(form.regonController, regon);

      if (registeredCountry.isNotEmpty) {
        form.registeredCountryController.text = registeredCountry;
        ref
            .read(invoiceFormProvider.notifier)
            .setRegisteredCountry(registeredCountry);
      }

      _setControllerIfNotEmpty(form.registeredCityController, registeredCity);
      _setControllerIfNotEmpty(form.registeredStreetController, registeredStreet);
      _setControllerIfNotEmpty(
        form.registeredPostalCodeController,
        registeredPostalCode,
      );

      _setControllerIfNotEmpty(
        form.notesController,
        notes,
        overwrite: form.notesController.text.trim().isEmpty,
      );

      detectInvoiceChanges(ref, form, userContact);
      ref.read(invoiceEditStateProvider.notifier).state = true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invoice_data_loaded_from_gus'.tr),
          backgroundColor: Colors.green,
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        detectInvoiceChanges(ref, form, userContact);
        ref.read(invoiceEditStateProvider.notifier).state = true;

        setState(() {
          _invoiceDetailsExpanded = true;
        });
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isApplyingGusSuggestion = false;
      });
    }
  }

  Widget _buildInvoiceNipRegonFields({
    required InvoiceFormState invoiceForm,
    required UserContactModel? userContact,
    required ThemeColors theme,
  }) {
    void maybeDetect() {
      detectInvoiceChanges(ref, invoiceForm, userContact);
    }

    return _responsiveFields(
      children: [
        CoreGusAutocomplete(
          controller: invoiceForm.nipController,
          mode: CoreGusAutocompleteMode.contractor,
          showExistingWarnings: false,
          labelText: 'NIP'.tr,
          hintText: 'NIP'.tr,
          onSuggestionSelected: (suggestion) {
            _applyGusInvoiceSuggestion(
              suggestion: suggestion,
              form: invoiceForm,
              userContact: userContact,
            );
          },
          fieldBuilder: (context, controller, focusNode, state) {
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[5],
                  focusNode: focusNode,
                  controller: controller,
                  hintText: 'NIP'.tr,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => maybeDetect(),
                ),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (!state.isLoading && state.hasSuggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.business_rounded,
                      color: theme.themeColor,
                      size: 20,
                    ),
                  ),
              ],
            );
          },
        ),
        GradientTextField(
          reqNode: invoiceForm.reqNodes[6],
          focusNode: invoiceForm.focusNodes[6],
          controller: invoiceForm.regonController,
          hintText: 'REGON'.tr,
          keyboardType: TextInputType.number,
          onChanged: (_) => maybeDetect(),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required ThemeColors theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    bool hasChanges = false,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.textColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            theme: theme,
            icon: icon,
            title: title,
            subtitle: subtitle,
            hasChanges: hasChanges,
            trailing: trailing,
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required ThemeColors theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool hasChanges,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.themeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: theme.themeColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.interMedium.copyWith(
                      color: theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasChanges) _unsavedChip(theme),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.interRegular.copyWith(
                  color: theme.textColor.withOpacity(0.64),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  Widget _unsavedChip(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.themeColor.withOpacity(0.22),
        ),
      ),
      child: Text(
        'Unsaved changes'.tr,
        style: AppTextStyles.interMedium.copyWith(
          color: theme.themeColor,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _responsiveFields({
    required List<Widget> children,
    int desktopColumns = 2,
    double spacing = 12,
    double minWidthForColumns = 560,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < minWidthForColumns;
        final columns = useSingleColumn ? 1 : desktopColumns;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _formDivider(ThemeColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(
        height: 24,
        color: theme.textColor.withOpacity(0.08),
      ),
    );
  }

  Widget _actionBar({
    required ThemeColors theme,
    required bool hasChanges,
    required VoidCallback? onSave,
    required VoidCallback? onCancel,
    String saveLabel = 'Save',
    String cancelLabel = 'Cancel',
  }) {
    if (!hasChanges) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textColor.withOpacity(0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.textColor.withOpacity(0.08),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'You have unsaved changes.'.tr,
            style: AppTextStyles.interRegular.copyWith(
              color: theme.textColor.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 17),
            label: Text(cancelLabel.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textColor,
              side: BorderSide(
                color: theme.textColor.withOpacity(0.18),
              ),
              minimumSize: const Size(116, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(saveLabel.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: theme.themeTextColor,
              elevation: 0,
              minimumSize: const Size(116, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required ThemeColors theme,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.themeColor.withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.themeColor,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: AppTextStyles.interMedium.copyWith(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message.tr,
                  style: AppTextStyles.interRegular.copyWith(
                    color: theme.textColor.withOpacity(0.68),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget clientDataSection({
    required WidgetRef ref,
    required InvoiceFormState invoiceForm,
    required UserContactModel? userContact,
    required String currentGender,
    required List<String> genderItems,
    required bool hasChanges,
    required ThemeColors theme,
  }) {
    final contact = userContact;

    void maybeDetect() {
      if (contact != null) {
        detectContactChanges(ref, invoiceForm, contact);
      }
    }

    return _sectionCard(
      theme: theme,
      icon: Icons.person_outline_rounded,
      title: 'Client data'.tr,
      subtitle: 'Basic contact information used across CRM.'.tr,
      hasChanges: hasChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _responsiveFields(
            children: [
              GradientTextField(
                reqNode: invoiceForm.reqNodes[0],
                focusNode: invoiceForm.focusNodes[0],
                controller: invoiceForm.firstNameController,
                hintText: 'First Name'.tr,
                onChanged: (_) => maybeDetect(),
              ),
              GradientTextField(
                reqNode: invoiceForm.reqNodes[1],
                focusNode: invoiceForm.focusNodes[1],
                controller: invoiceForm.lastNameController,
                hintText: 'Last Name'.tr,
                onChanged: (_) => maybeDetect(),
              ),
            ],
          ),
          _formDivider(theme),
          _responsiveFields(
            children: [
              GradientTextField(
                reqNode: invoiceForm.reqNodes[2],
                focusNode: invoiceForm.focusNodes[2],
                controller: invoiceForm.emailController,
                hintText: 'Email'.tr,
                onChanged: (_) => maybeDetect(),
              ),
              GradientTextField(
                reqNode: invoiceForm.reqNodes[3],
                focusNode: invoiceForm.focusNodes[3],
                controller: invoiceForm.phoneController,
                isPhoneField: true,
                hintText: 'Phone'.tr,
                onChanged: (_) => maybeDetect(),
              ),
            ],
          ),
          _formDivider(theme),
          _responsiveFields(
            children: [
              GradientDateDropdown(
                selectedDate: invoiceForm.birthDate,
                value: invoiceForm.birthDate?.toIso8601String() ?? '',
                isPc: true,
                hintText: 'Date Of Birth'.tr,
                onDateSelected: (date) {
                  invoiceForm.birthDate = date;
                  maybeDetect();
                },
              ),
              GradientDropdown(
                selectedItem: currentGender,
                isPc: true,
                value: currentGender,
                items: genderItems,
                onChanged: (value) {
                  invoiceForm.gender = value ?? '';
                  maybeDetect();
                },
                hintText: 'Gender'.tr,
              ),
            ],
          ),
          _actionBar(
            theme: theme,
            hasChanges: hasChanges,
            onSave: contact == null
                ? null
                : () {
                    _saveContactData(
                      form: invoiceForm,
                      userContact: contact,
                    );
                  },
            onCancel: contact == null
                ? null
                : () {
                    resetContactForm(invoiceForm, contact, ref);
                  },
          ),
        ],
      ),
    );
  }

  Widget invoiceSection({
    required BuildContext context,
    required WidgetRef ref,
    required InvoiceFormState invoiceForm,
    required UserContactModel? userContact,
    required String? registeredSelectedCountry,
    required bool hasChanges,
    required ThemeColors theme,
  }) {
    final contact = userContact;
    final hasExistingInvoiceData = contact?.invoiceData?.id != null;

    final showDetails = _shouldShowInvoiceDetails(
      form: invoiceForm,
      contact: contact,
    );

    void maybeDetect() {
      detectInvoiceChanges(ref, invoiceForm, contact);
    }

    return _sectionCard(
      theme: theme,
      icon: Icons.receipt_long_outlined,
      title: 'Invoice data'.tr,
      subtitle: hasExistingInvoiceData
          ? 'Company and billing details for documents and invoices.'.tr
          : showDetails
              ? 'Fill billing data manually or use GUS autocomplete by NIP.'.tr
              : 'Enter NIP or REGON to fetch contractor data from GUS, or expand the form to fill it manually.'
                  .tr,
      hasChanges: hasChanges,
      trailing: _invoiceHeaderActions(
        theme: theme,
        form: invoiceForm,
        contact: contact,
        expanded: showDetails,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasExistingInvoiceData && !showDetails) ...[
            _infoBox(
              theme: theme,
              icon: Icons.auto_awesome_rounded,
              title: 'Quick invoice data setup',
              message:
                  'Type NIP, choose a GUS suggestion, and the full billing form will open automatically.',
            ),
            const SizedBox(height: 14),
          ],
          _buildInvoiceNipRegonFields(
            invoiceForm: invoiceForm,
            userContact: contact,
            theme: theme,
          ),
          if (!showDetails) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.textColor.withOpacity(0.035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.textColor.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: theme.themeColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can also expand the form and enter invoice data manually.'
                          .tr,
                      style: AppTextStyles.interRegular.copyWith(
                        color: theme.textColor.withOpacity(0.7),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _invoiceDetailsExpanded = true;
                      });
                    },
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    label: Text('Enter manually'.tr),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showDetails) ...[
            const SizedBox(height: 12),
            _formDivider(theme),
            _responsiveFields(
              desktopColumns: 1,
              children: [
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[4],
                  focusNode: invoiceForm.focusNodes[4],
                  controller: invoiceForm.legalNameController,
                  hintText: 'Legal Name'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _responsiveFields(
              desktopColumns: 1,
              children: [
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[7],
                  focusNode: invoiceForm.focusNodes[7],
                  controller: invoiceForm.contactPersonController,
                  hintText: 'Contact Person'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[8],
                  focusNode: invoiceForm.focusNodes[8],
                  controller: invoiceForm.bankAccountController,
                  hintText: 'Bank Account'.tr,
                  label: 'Bank Account'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[9],
                  focusNode: invoiceForm.focusNodes[9],
                  controller: invoiceForm.websiteController,
                  hintText: 'Website'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
              ],
            ),
            _formDivider(theme),
            GradientDropdownCountry(
              selectedCountry: registeredSelectedCountry,
              value: registeredSelectedCountry ?? '',
              countries: countries,
              isPc: true,
              hintText: 'Registered Country'.tr,
              onChanged: (value) {
                final country = value ?? '';

                invoiceForm.registeredCountryController.text = country;

                ref
                    .read(invoiceFormProvider.notifier)
                    .setRegisteredCountry(country);

                maybeDetect();
              },
            ),
            const SizedBox(height: 12),
            _responsiveFields(
              desktopColumns: 3,
              minWidthForColumns: 720,
              children: [
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[12],
                  focusNode: invoiceForm.focusNodes[12],
                  controller: invoiceForm.registeredCityController,
                  hintText: 'Registered City'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[13],
                  focusNode: invoiceForm.focusNodes[13],
                  controller: invoiceForm.registeredStreetController,
                  hintText: 'Registered Street'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[14],
                  focusNode: invoiceForm.focusNodes[14],
                  controller: invoiceForm.registeredPostalCodeController,
                  hintText: 'Registered Postal Code'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
              ],
            ),
            _formDivider(theme),
            _responsiveFields(
              desktopColumns: 1,
              children: [
                GradientTextField(
                  reqNode: invoiceForm.reqNodes[10],
                  focusNode: invoiceForm.focusNodes[10],
                  controller: invoiceForm.notesController,
                  hintText: 'Notes'.tr,
                  onChanged: (_) => maybeDetect(),
                ),
              ],
            ),
            _actionBar(
              theme: theme,
              hasChanges: hasChanges,
              saveLabel: hasExistingInvoiceData ? 'Save' : 'Add invoice data',
              onSave: contact == null
                  ? null
                  : () {
                      _saveInvoiceData(
                        context: context,
                        form: invoiceForm,
                        userContact: contact,
                      );
                    },
              onCancel: () {
                resetInvoiceForm(invoiceForm, contact?.invoiceData, ref);

                setState(() {
                  _invoiceDetailsExpanded = hasExistingInvoiceData;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(ThemeColors theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _sectionCard(
          theme: theme,
          icon: Icons.person_search_rounded,
          title: 'No contact selected'.tr,
          subtitle: 'Select a client to view and edit contact details.'.tr,
          child: Text(
            'Client details will appear here after selecting a contact from the list.'
                .tr,
            style: AppTextStyles.interRegular.copyWith(
              color: theme.textColor.withOpacity(0.68),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final invoiceForm = ref.watch(invoiceFormProvider);
    final userContact = ref.watch(activeContactProvider);
    final contactHasChanges = ref.watch(contactEditStateProvider);
    final invoiceHasChanges = ref.watch(invoiceEditStateProvider);

    _syncFormWithContact(
      form: invoiceForm,
      userContact: userContact,
    );

    if (userContact == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _emptyState(theme),
      );
    }

    final genderItems = ['Male', 'Female', 'Other'];
    final currentGender = genderItems.contains(invoiceForm.gender)
        ? invoiceForm.gender
        : genderItems.first;

    final countryNames =
        countries.map((e) => e['name']).whereType<String>().toList();

    final registeredCountryName =
        invoiceForm.registeredCountryController.text.isNotEmpty
            ? invoiceForm.registeredCountryController.text
            : (userContact.invoiceData?.registeredCountry ?? '');

    final registeredSelectedCountry =
        countryNames.contains(registeredCountryName)
            ? registeredCountryName
            : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 980;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isStacked ? 10 : 16),
          child: isStacked
              ? Column(
                  children: [
                    clientDataSection(
                      ref: ref,
                      invoiceForm: invoiceForm,
                      userContact: userContact,
                      currentGender: currentGender,
                      genderItems: genderItems,
                      hasChanges: contactHasChanges,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    invoiceSection(
                      context: context,
                      ref: ref,
                      invoiceForm: invoiceForm,
                      userContact: userContact,
                      hasChanges: invoiceHasChanges,
                      theme: theme,
                      registeredSelectedCountry: registeredSelectedCountry,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: clientDataSection(
                        ref: ref,
                        invoiceForm: invoiceForm,
                        userContact: userContact,
                        currentGender: currentGender,
                        genderItems: genderItems,
                        hasChanges: contactHasChanges,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 2,
                      child: invoiceSection(
                        context: context,
                        ref: ref,
                        invoiceForm: invoiceForm,
                        userContact: userContact,
                        hasChanges: invoiceHasChanges,
                        theme: theme,
                        registeredSelectedCountry: registeredSelectedCountry,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}