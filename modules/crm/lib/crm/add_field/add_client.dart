import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/user_contact_status_model.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm/data/clients/contact_type_provider.dart';
import 'package:get/get_utils/get_utils.dart';

class AddClientForm extends ConsumerStatefulWidget {
  const AddClientForm({super.key});

  @override
  AddClientFormState createState() => AddClientFormState();
}

class AddClientFormState extends ConsumerState<AddClientForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;

  int? _selectedStatus;
  int? _selectedContactType;
  int? _selectedServiceType;

  bool _isOpen = false;
  bool _isSaving = false;
  DateTime? _lastSubmitAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _openForm() {
    setState(() => _isOpen = true);
    // Trigger data load for dropdowns
    final ctProvider = ref.read(contactTypeProvider);
    if (ctProvider.contactType.isEmpty) ctProvider.getContactType(ref);
    if (ctProvider.contactServiceType.isEmpty) ctProvider.getContactServiceType(ref);
  }

  void _clearForm() {
    _nameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneNumberController.clear();
    setState(() {
      _selectedStatus = null;
      _selectedContactType = null;
      _selectedServiceType = null;
    });
  }

  Future<void> _submit() async {
    // Guard: debounce double-taps within 2 seconds
    final now = DateTime.now();
    if (_lastSubmitAt != null &&
        now.difference(_lastSubmitAt!) < const Duration(seconds: 2)) return;
    _lastSubmitAt = now;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final clientNotifier = ref.read(clientProvider.notifier);
      final client = UserContactModel(
        id: 0,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        phoneNumber: _phoneNumberController.text.trim().isNotEmpty
            ? _phoneNumberController.text.trim()
            : null,
        contactStatus: _selectedStatus?.toString(),
        contactType: _selectedContactType,
        serviceType: _selectedServiceType?.toString(),
      );

      await clientNotifier.addClient(client);

      if (!mounted) return;
      _clearForm();
      setState(() => _isOpen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client added successfully'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Failed to add client'.tr}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: double.infinity,
        child: _isOpen ? _buildForm() : _buildCollapsed(),
      ),
    );
  }

  Widget _buildCollapsed() {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<List<UserContactModel>>(
            future: ref.read(clientProvider.notifier).fetchClientsList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}'.tr);
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No clients available'.tr);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _openForm,
          child: AppIcons.add(),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final ctProvider = ref.watch(contactTypeProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: ClientTextFormField(
                    labelText: 'Name'.tr,
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a name'.tr
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: ClientTextFormField(
                    labelText: 'Last name'.tr,
                    controller: _lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClientTextFormField(
              labelText: 'Email'.tr,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              isEmail: true,
            ),
            const SizedBox(height: 10),
            ClientTextFormField(
              labelText: 'Phone Number'.tr,
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),

            // Status
            FutureBuilder<List<UserContactStatusModel>>(
              future: ref.read(clientProvider.notifier).fetchStatuses(ref),
              builder: (context, snapshot) {
                final statuses = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    statuses.isEmpty) {
                  return const LinearProgressIndicator();
                }
                return DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: AppTextStyles.interRegular14,
                  ),
                  value: _selectedStatus,
                  items: statuses
                      .map((s) => DropdownMenuItem<int>(
                            value: s.statusId,
                            child: Text(s.statusName,
                                style: AppTextStyles.interRegular14),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v),
                );
              },
            ),
            const SizedBox(height: 10),

            // Contact Type
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Client Type'.tr,
                labelStyle: AppTextStyles.interRegular14,
              ),
              value: _selectedContactType,
              items: ctProvider.contactType
                  .map((t) => DropdownMenuItem<int>(
                        value: t.id,
                        child: Text(t.displayLabel,
                            style: AppTextStyles.interRegular14),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedContactType = v),
            ),
            const SizedBox(height: 10),

            // Service Type
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Service Type'.tr,
                labelStyle: AppTextStyles.interRegular14,
              ),
              value: _selectedServiceType,
              items: ctProvider.contactServiceType
                  .map((s) => DropdownMenuItem<int>(
                        value: s.id,
                        child: Text(s.displayLabel,
                            style: AppTextStyles.interRegular14),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedServiceType = v),
            ),
            const SizedBox(height: 20),

            // Save / Cancel
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Save'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() => _isOpen = false),
                  child: Text('Cancel'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class ClientTextFormField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isEmail;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  const ClientTextFormField({
    super.key,
    required this.labelText,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.isEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppTextStyles.interRegular14,
      ),
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ??
          (isEmail
              ? (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  if (!_emailRegex.hasMatch(v.trim())) {
                    return 'Invalid email address'.tr;
                  }
                  return null;
                }
              : null),
    );
  }
}
