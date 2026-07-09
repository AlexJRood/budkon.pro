import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_buyer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/gus.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class InvoiceBuyerGusSection extends ConsumerStatefulWidget {
  final bool isMobile;

  const InvoiceBuyerGusSection({
    super.key,
    required this.isMobile,
  });

  @override
  ConsumerState<InvoiceBuyerGusSection> createState() =>
      _InvoiceBuyerGusSectionState();
}

class _InvoiceBuyerGusSectionState
    extends ConsumerState<InvoiceBuyerGusSection> {
  final _nipController = TextEditingController();
  final _regonController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _countryController = TextEditingController(text: 'Poland');
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _contactPersonController = TextEditingController();

  bool _expanded = false;
  bool _syncingControllers = false;

  List<TextEditingController> get _controllers => [
        _nipController,
        _regonController,
        _legalNameController,
        _countryController,
        _cityController,
        _streetController,
        _postalCodeController,
        _websiteController,
        _bankAccountController,
        _contactPersonController,
      ];

  @override
  void initState() {
    super.initState();

    _syncControllersFromBuyer(ref.read(invoiceBuyerProvider));

    for (final controller in _controllers) {
      controller.addListener(_syncDraftFromControllers);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_syncDraftFromControllers);
      controller.dispose();
    }

    super.dispose();
  }

  void _syncControllersFromBuyer(InvoiceBuyerDraft buyer) {
    _syncingControllers = true;

    try {
      _write(_nipController, buyer.nip);
      _write(_regonController, buyer.regon);
      _write(_legalNameController, buyer.legalName);
      _write(_countryController, buyer.country.isNotEmpty ? buyer.country : 'Poland');
      _write(_cityController, buyer.city);
      _write(_streetController, buyer.street);
      _write(_postalCodeController, buyer.postalCode);
      _write(_websiteController, buyer.website);
      _write(_bankAccountController, buyer.bankAccount);
      _write(_contactPersonController, buyer.contactPerson);
    } finally {
      _syncingControllers = false;
    }
  }

  void _write(TextEditingController controller, String value) {
    if (controller.text == value) return;

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncDraftFromControllers() {
    if (_syncingControllers) return;

    final buyer = ref.read(invoiceBuyerProvider);

    if (buyer.mode == InvoiceBuyerMode.existingContact) {
      return;
    }

    ref.read(invoiceBuyerProvider.notifier).setManual(
          legalName: _legalNameController.text,
          nip: _nipController.text,
          regon: _regonController.text,
          country: _countryController.text,
          city: _cityController.text,
          street: _streetController.text,
          postalCode: _postalCodeController.text,
          website: _websiteController.text,
          bankAccount: _bankAccountController.text,
          contactPerson: _contactPersonController.text,
        );
  }

  String _value(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';

      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return '';
  }

  String _first(List<Map<String, dynamic>> maps, List<String> keys) {
    for (final map in maps) {
      final value = _value(map, keys);

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String _joinParts(List<String> parts) {
    return parts
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .join(' ')
        .trim();
  }

  void _setIfNotEmpty(TextEditingController controller, String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return;
    }

    controller.text = normalized;
  }

  void _applySuggestion(CoreGusSuggestion suggestion) {
    final invoice = suggestion.invoiceDataPrefill;
    final company = suggestion.companyPrefill;
    final contractor = suggestion.contractorPrefill;

    final maps = <Map<String, dynamic>>[
      invoice,
      contractor,
      company,
    ];

    final legalName = _first(
      maps,
      [
        'legal_name',
        'company_name',
        'name',
        'Nazwa',
        'nazwa',
      ],
    );

    final nipFromMaps = _first(
      maps,
      [
        'nip',
        'Nip',
        'tax_id',
        'tax_number',
      ],
    );

    final regonFromMaps = _first(
      maps,
      [
        'regon',
        'Regon',
      ],
    );

    final country = _first(
      maps,
      [
        'registered_country',
        'reg_country',
        'country',
        'Kraj',
        'kraj',
      ],
    );

    final city = _first(
      maps,
      [
        'registered_city',
        'reg_city',
        'city',
        'Miejscowosc',
        'miejscowosc',
      ],
    );

    final postalCode = _first(
      maps,
      [
        'registered_postal_code',
        'reg_postal_code',
        'postal_code',
        'KodPocztowy',
        'kod_pocztowy',
      ],
    );

    final directStreet = _first(
      maps,
      [
        'registered_street',
        'reg_address',
        'address',
        'street',
      ],
    );

    final street = directStreet.isNotEmpty
        ? directStreet
        : _joinParts(
            [
              _first(
                maps,
                [
                  'reg_street',
                  'street_name',
                  'Ulica',
                  'ulica',
                ],
              ),
              _first(
                maps,
                [
                  'reg_street_number',
                  'street_number',
                  'building_number',
                  'NrNieruchomosci',
                  'nr_nieruchomosci',
                ],
              ),
              _first(
                maps,
                [
                  'apartment_number',
                  'NrLokalu',
                  'nr_lokalu',
                ],
              ).isNotEmpty
                  ? '/${_first(
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

    final website = _first(
      maps,
      [
        'website',
        'www',
        'strona_www',
        'adres_strony_internetowej',
      ],
    );

    _syncingControllers = true;

    try {
      _setIfNotEmpty(_legalNameController, legalName);
      _setIfNotEmpty(_nipController, nipFromMaps.isNotEmpty ? nipFromMaps : suggestion.nip ?? '');
      _setIfNotEmpty(
        _regonController,
        regonFromMaps.isNotEmpty ? regonFromMaps : suggestion.regon ?? '',
      );
      _setIfNotEmpty(_countryController, country.isNotEmpty ? country : 'Poland');
      _setIfNotEmpty(_cityController, city);
      _setIfNotEmpty(_streetController, street);
      _setIfNotEmpty(_postalCodeController, postalCode);
      _setIfNotEmpty(_websiteController, website);
    } finally {
      _syncingControllers = false;
    }

    ref.read(invoiceBuyerProvider.notifier).applyGusSuggestion(suggestion);

    setState(() {
      _expanded = true;
    });
  }

  void _changeMode(InvoiceBuyerMode mode) {
    final notifier = ref.read(invoiceBuyerProvider.notifier);

    if (mode == InvoiceBuyerMode.existingContact) {
      notifier.clearBuyerData(keepMode: false);
      notifier.setMode(InvoiceBuyerMode.existingContact);

      setState(() {
        _expanded = false;
      });

      return;
    }

    ref.read(revenueFormProvider.notifier).clearInvoiceBuyer();
    notifier.setMode(mode);

    setState(() {
      _expanded = ref.read(invoiceBuyerProvider).hasBuyerData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final buyer = ref.watch(invoiceBuyerProvider);

    Widget modeChip({
      required InvoiceBuyerMode mode,
      required String label,
      required IconData icon,
    }) {
      final selected = buyer.mode == mode;

      return ChoiceChip(
        selected: selected,
        onSelected: (_) => _changeMode(mode),
        avatar: Icon(
          icon,
          size: 17,
          color: selected ? theme.themeTextColor : theme.textColor,
        ),
        label: Text(label.tr),
        labelStyle: TextStyle(
          color: selected ? theme.themeTextColor : theme.textColor,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: theme.themeColor,
        backgroundColor: theme.adPopBackground,
        side: BorderSide(color: theme.dashboardBoarder),
      );
    }

    return _card(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(theme),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              modeChip(
                mode: InvoiceBuyerMode.existingContact,
                label: 'contact_from_crm',
                icon: Icons.people_alt_outlined,
              ),
              modeChip(
                mode: InvoiceBuyerMode.newContactFromGus,
                label: 'new_contact_from_gus',
                icon: Icons.person_add_alt_1_outlined,
              ),
              modeChip(
                mode: InvoiceBuyerMode.oneTime,
                label: 'one_time_invoice',
                icon: Icons.receipt_long_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _info(theme, buyer),
          if (buyer.mode == InvoiceBuyerMode.existingContact) ...[
            const SizedBox(height: 10),
            Text(
              'Wybierz kontakt z CRM poniżej. Przy tworzeniu faktury backend utworzy zamrożony snapshot InvoiceData dla dokumentu.'
                  .tr,
              style: AppTextStyles.interRegular12.copyWith(
                color: theme.textColor.withOpacity(0.68),
                height: 1.35,
              ),
            ),
          ],
          if (buyer.mode != InvoiceBuyerMode.existingContact) ...[
            const SizedBox(height: 14),
            _responsive(
              isMobile: widget.isMobile,
              children: [
                CoreGusAutocomplete(
                  controller: _nipController,
                  mode: CoreGusAutocompleteMode.contractor,
                  showExistingWarnings: false,
                  labelText: 'NIP'.tr,
                  hintText: 'NIP'.tr,
                  onSuggestionSelected: _applySuggestion,
                  fieldBuilder: (context, controller, focusNode, state) {
                    return _textField(
                      theme: theme,
                      controller: controller,
                      focusNode: focusNode,
                      label: 'NIP'.tr,
                      keyboardType: TextInputType.number,
                      suffix: state.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.business,
                              color: theme.themeColor,
                            ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    );
                  },
                ),
                _textField(
                  theme: theme,
                  controller: _regonController,
                  label: 'REGON'.tr,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buyerPreview(theme, buyer),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(
                  _expanded ? 'Zwiń dane nabywcy'.tr : 'Wpisz dane ręcznie'.tr,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.themeColor,
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              _responsive(
                isMobile: widget.isMobile,
                singleColumn: true,
                children: [
                  _textField(
                    theme: theme,
                    controller: _legalNameController,
                    label: 'Legal Name'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _responsive(
                isMobile: widget.isMobile,
                children: [
                  _textField(
                    theme: theme,
                    controller: _countryController,
                    label: 'Country'.tr,
                  ),
                  _textField(
                    theme: theme,
                    controller: _cityController,
                    label: 'City'.tr,
                  ),
                  _textField(
                    theme: theme,
                    controller: _streetController,
                    label: 'Street'.tr,
                  ),
                  _textField(
                    theme: theme,
                    controller: _postalCodeController,
                    label: 'Postal code'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _responsive(
                isMobile: widget.isMobile,
                children: [
                  _textField(
                    theme: theme,
                    controller: _bankAccountController,
                    label: 'Bank Account'.tr,
                  ),
                  _textField(
                    theme: theme,
                    controller: _websiteController,
                    label: 'Website'.tr,
                    keyboardType: TextInputType.url,
                  ),
                  _textField(
                    theme: theme,
                    controller: _contactPersonController,
                    label: 'Contact Person'.tr,
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _header(ThemeColors theme) {
    return Row(
      children: [
        Icon(
          Icons.badge_outlined,
          color: theme.themeColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Nabywca faktury'.tr,
            style: AppTextStyles.interBold.copyWith(
              color: theme.textColor,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _info(ThemeColors theme, InvoiceBuyerDraft buyer) {
    String text;

    switch (buyer.mode) {
      case InvoiceBuyerMode.existingContact:
        text =
            'Faktura zostanie wystawiona dla wybranego kontaktu CRM. Backend utworzy zamrożony InvoiceData snapshot dla tej faktury.';
        break;
      case InvoiceBuyerMode.newContactFromGus:
        text =
            'Po zapisaniu faktury backend utworzy nowy kontakt CRM, profil InvoiceData oraz zamrożony snapshot InvoiceData przypięty do faktury.';
        break;
      case InvoiceBuyerMode.oneTime:
        text =
            'Faktura jednorazowa nie utworzy kontaktu CRM. Backend zapisze dane nabywcy jako zamrożony InvoiceData przypięty tylko do tej faktury.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.themeColor.withOpacity(0.18),
        ),
      ),
      child: Text(
        text.tr,
        style: AppTextStyles.interRegular12.copyWith(
          color: theme.textColor.withOpacity(0.72),
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buyerPreview(ThemeColors theme, InvoiceBuyerDraft buyer) {
    if (!buyer.hasBuyerData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.themeColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wpisz NIP i wybierz dane z GUS albo rozwiń formularz i uzupełnij dane ręcznie.'
                    .tr,
                style: AppTextStyles.interRegular12.copyWith(
                  color: theme.textColor.withOpacity(0.68),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final address = [
      buyer.postalCode,
      buyer.city,
      buyer.street,
    ].where((value) => value.trim().isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: buyer.fromGus
              ? theme.themeAccent.withOpacity(0.45)
              : theme.dashboardBoarder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            buyer.fromGus ? Icons.verified_rounded : Icons.edit_note_rounded,
            color: buyer.fromGus ? theme.themeAccent : theme.themeColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle(
              style: AppTextStyles.interRegular12.copyWith(
                color: theme.textColor.withOpacity(0.72),
                height: 1.35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buyer.legalName.isNotEmpty
                        ? buyer.legalName
                        : 'Dane nabywcy'.tr,
                    style: AppTextStyles.interBold.copyWith(
                      color: theme.textColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (buyer.nip.isNotEmpty) Text('NIP: ${buyer.nip}'),
                  if (buyer.regon.isNotEmpty) Text('REGON: ${buyer.regon}'),
                  if (address.isNotEmpty) Text(address),
                  if (buyer.website.isNotEmpty) Text('WWW: ${buyer.website}'),
                  if (buyer.bankAccount.isNotEmpty)
                    Text('Rachunek: ${buyer.bankAccount}'),
                ],
              ),
            ),
          ),
          if (buyer.fromGus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: theme.themeAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'GUS',
                style: AppTextStyles.interBold.copyWith(
                  color: theme.themeAccent,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({
    required ThemeColors theme,
    required Widget child,
  }) {
    return Padding(
      padding: widget.isMobile
          ? const EdgeInsets.symmetric(horizontal: 10)
          : const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  Widget _responsive({
    required bool isMobile,
    required List<Widget> children,
    bool singleColumn = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            singleColumn || isMobile || constraints.maxWidth < 720 ? 1 : 2;

        const spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: width,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _textField({
    required ThemeColors theme,
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: theme.textColor,
      ),
      cursorColor: theme.themeColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.textColor.withOpacity(0.65),
        ),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(12),
                child: suffix,
              ),
        filled: true,
        fillColor: theme.adPopBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.dashboardBoarder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.themeColor,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.dashboardBoarder,
          ),
        ),
      ),
    );
  }
}