import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';
import 'package:core/ui/forms/form_fields.dart';


// Simple DTO for dialog result
class CreateMemberResult {
  final String name;
  final String? lastName;
  final String? email;
  final String? phonePrefix;
  final String? phone;
  final String? gender; // 'man' | 'woman' | 'other'
  final String? description;
  final String? note;

  final String? companyName;
  final String? address;
  final String? location;
  final String status; // pending/active/suspended/former
  final String? history;
  final String? notes;

  CreateMemberResult({
    required this.name,
    this.lastName,
    this.email,
    this.phonePrefix,
    this.phone,
    this.gender,
    this.description,
    this.note,
    this.companyName,
    this.address,
    this.location,
    this.status = 'pending',
    this.history,
    this.notes,
  });
}

class CreateMemberDialog extends ConsumerStatefulWidget {
  const CreateMemberDialog({super.key, this.isSheet = false});

  /// When true, renders as a draggable bottom sheet (mobile) instead of a
  /// centered dialog (desktop/tablet).
  final bool isSheet;

  /// Opens the dialog adapting its presentation to the available width:
  /// a draggable bottom sheet on narrow (mobile) screens, a centered
  /// dialog otherwise.
  static Future<CreateMemberResult?> show(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return showModalBottomSheet<CreateMemberResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CreateMemberDialog(isSheet: true),
      );
    }

    return showDialog<CreateMemberResult>(
      context: context,
      builder: (_) => const CreateMemberDialog(),
    );
  }

  @override
  ConsumerState<CreateMemberDialog> createState() => _CreateMemberDialogState();
}

class _CreateMemberDialogState extends ConsumerState<CreateMemberDialog> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phonePrefixCtrl = TextEditingController(text: '+48');
  final phoneCtrl = TextEditingController();

  final companyCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final historyCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final noteContactCtrl = TextEditingController();
  late final FocusNode _nameFocus;
  late final FocusNode _lastNameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _phoneFocus;
  late final FocusNode _genderFocus;
  late final FocusNode _descFocus;
  late final FocusNode _noteFocus;
  late final FocusNode _companyFocus;
  late final FocusNode _addressFocus;
  late final FocusNode _locationFocus;
  late final FocusNode _statusFocus;
  late final FocusNode _historyFocus;
  late final FocusNode _notesFocus;

  String status = 'pending';
  String? gender; // 'man' | 'woman' | 'other'

  static const List<String> _genderOptions = ['man', 'woman', 'other'];
  static const List<String> _statusOptions = [
    'pending',
    'active',
    'suspended',
    'former',
  ];

  String _genderLabel(String v) {
    switch (v) {
      case 'man':
        return 'man'.tr;
      case 'woman':
        return 'woman'.tr;
      case 'other':
        return 'other'.tr;
    }
    return v;
  }

  String _statusLabel(String v) {
    switch (v) {
      case 'pending':
        return 'pending_status'.tr;
      case 'active':
        return 'active_status'.tr;
      case 'suspended':
        return 'suspended_status'.tr;
      case 'former':
        return 'former_status'.tr;
    }
    return v;
  }
  @override
  void initState() {
    super.initState();

    _nameFocus = FocusNode();
    _lastNameFocus = FocusNode();
    _emailFocus = FocusNode();
    _phoneFocus = FocusNode();
    _genderFocus = FocusNode();
    _descFocus = FocusNode();
    _noteFocus = FocusNode();
    _companyFocus = FocusNode();
    _addressFocus = FocusNode();
    _locationFocus = FocusNode();
    _statusFocus = FocusNode();
    _historyFocus = FocusNode();
    _notesFocus = FocusNode();
  }
  @override
  void dispose() {
    nameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phonePrefixCtrl.dispose();
    phoneCtrl.dispose();
    companyCtrl.dispose();
    addressCtrl.dispose();
    locationCtrl.dispose();
    historyCtrl.dispose();
    notesCtrl.dispose();
    descCtrl.dispose();
    noteContactCtrl.dispose();
    _nameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _genderFocus.dispose();
    _descFocus.dispose();
    _noteFocus.dispose();
    _companyFocus.dispose();
    _addressFocus.dispose();
    _locationFocus.dispose();
    _statusFocus.dispose();
    _historyFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      CreateMemberResult(
        name: nameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim().isEmpty ? null : lastNameCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
        phonePrefix: phonePrefixCtrl.text.trim().isEmpty ? null : phonePrefixCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        gender: gender,
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        note: noteContactCtrl.text.trim().isEmpty ? null : noteContactCtrl.text.trim(),
        companyName: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
        address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
        location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
        status: status,
        history: historyCtrl.text.trim().isEmpty ? null : historyCtrl.text.trim(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      ),
    );
  }

  Widget _sectionTitle(ThemeColors theme, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.textColor.withAlpha(160)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(160),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider(ThemeColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: theme.textColor.withAlpha(28)),
    );
  }

  List<Widget> _buildFormFields(ThemeColors theme) {
    return [
      _sectionTitle(theme, Icons.badge_outlined, 'basic_info_section'.tr),
      CoreTextFormField(
        label: 'first_name_required'.tr,
        controller: nameCtrl,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'required_field'.tr : null,
        focusNode: _nameFocus,
        nextFocusNode: _lastNameFocus,
      ),
      const SizedBox(height: 8),
      CoreTextFormField(
        label: 'last_name'.tr,
        controller: lastNameCtrl,
        focusNode: _lastNameFocus,
        nextFocusNode: _emailFocus,
      ),
      const SizedBox(height: 8),
      CoreTextFormField(
        label: 'Email'.tr,
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        focusNode: _emailFocus,
        nextFocusNode: _phoneFocus,
      ),

      _sectionDivider(theme),
      _sectionTitle(theme, Icons.phone_outlined, 'contact_section'.tr),
      GradientTextField(
        focusNode: _phoneFocus,
        reqNode: _genderFocus,
        isPhoneField: true,
        countryCodeController: phonePrefixCtrl,
        controller: phoneCtrl,
        hintText: 'phone'.tr,
        label: 'phone'.tr,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 8),
      CoreDropdown<String>(
        label: 'gender'.tr,
        hintText: 'select'.tr,
        value: gender,
        options: _genderOptions,
        display: _genderLabel,
        onChanged: (v) => setState(() => gender = v),
        focusNode: _genderFocus,
        nextFocusNode: _descFocus,
      ),

      _sectionDivider(theme),
      _sectionTitle(theme, Icons.notes_outlined, 'contact_notes_section'.tr),
      CoreTextFormField(
        label: 'contact_description'.tr,
        controller: descCtrl,
        minLines: 2,
        maxLines: 4,
        focusNode: _descFocus,
        nextFocusNode: _noteFocus,
      ),
      const SizedBox(height: 8),
      CoreTextFormField(
        label: 'contact_note'.tr,
        controller: noteContactCtrl,
        minLines: 2,
        maxLines: 4,
        focusNode: _noteFocus,
        nextFocusNode: _companyFocus,
      ),

      _sectionDivider(theme),
      _sectionTitle(theme, Icons.business_outlined, 'company_address_section'.tr),
      CoreTextFormField(
        label: 'company_name'.tr,
        controller: companyCtrl,
        focusNode: _companyFocus,
        nextFocusNode: _addressFocus,
      ),
      const SizedBox(height: 8),
      CoreTextFormField(
        label: 'address'.tr,
        controller: addressCtrl,
        focusNode: _addressFocus,
        nextFocusNode: _locationFocus,
      ),
      const SizedBox(height: 8),
      CoreTextFormField(
        label: 'location'.tr,
        controller: locationCtrl,
        focusNode: _locationFocus,
        nextFocusNode: _statusFocus,
      ),

      _sectionDivider(theme),
      _sectionTitle(theme, Icons.flag_outlined, 'status_history_section'.tr),
      CoreDropdown<String>(
        label: 'Status'.tr,
        value: status,
        options: _statusOptions,
        display: _statusLabel,
        onChanged: (v) => setState(() => status = v ?? 'pending'),
        focusNode: _statusFocus,
        nextFocusNode: _historyFocus,
      ),
      const SizedBox(height: 8),
      CoreTextFormField(
        label: 'history'.tr,
        controller: historyCtrl,
        minLines: 2,
        maxLines: 4,
        focusNode: _historyFocus,
        nextFocusNode: _notesFocus,
      ),
      const SizedBox(height: 8),
      CoreTextFormField(
        label: 'notes'.tr,
        controller: notesCtrl,
        minLines: 2,
        maxLines: 4,
        focusNode: _notesFocus,
        textInputAction: TextInputAction.done,
      ),
    ];
  }

  Widget _buildHeader(ThemeColors theme, {bool showDragHandle = false}) {
    return Column(
      children: [
        if (showDragHandle)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textColor.withAlpha(60),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: theme.textColor),
            const SizedBox(width: 8),
            Text(
              'create_member'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: theme.textColor,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close, color: theme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(ThemeColors theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: buttonStyleRounded10ThemeRedWithPadding15,
            icon: Icon(Icons.check, color: theme.textColor),
            label: Text(
              'create'.tr,
              style: TextStyle(color: theme.textColor),
            ),
            onPressed: _submit,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    if (widget.isSheet) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                children: [
                  _buildHeader(theme, showDragHandle: true),
                  const SizedBox(height: 8),
                  ..._buildFormFields(theme),
                  const SizedBox(height: 16),
                  _buildActions(theme),
                ],
              ),
            ),
          );
        },
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: theme.adPopBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 160,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 8),
                  ..._buildFormFields(theme),
                  const SizedBox(height: 16),
                  _buildActions(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
