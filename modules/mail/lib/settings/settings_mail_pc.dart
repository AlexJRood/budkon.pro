import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

// Your project imports (as in your code)
import 'package:mail/settings/mail_services.dart';
import 'package:mail/settings/mail_form.dart';
import 'package:core/ui/forms/form_fields.dart';


class EmailAccount {
  final int id;
  final String email;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;

  EmailAccount({
    this.id = 0,
    required this.email,
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
  });

  factory EmailAccount.fromJson(Map<String, dynamic> json) {
    return EmailAccount(
      id: json['id'],
      email: json['email_address'],
      imapHost: json['imap_host'],
      imapPort: json['imap_port'],
      smtpHost: json['smtp_host'],
      smtpPort: json['smtp_port'],
    );
  }
}

// Provider to fetch list
final emailAccountListProvider = FutureProvider<List<EmailAccount>>((ref) async {
  final response = await ApiServices.get(
    '${URLs.baseUrl}/mail/email-accounts',
    hasToken: true,
    ref: ref,
  );

  if (response != null && response.statusCode == 200) {
    final decoded = utf8.decode(response.data);
    final data = json.decode(decoded) as Map<String, dynamic>;
    final List<dynamic> accountsJson = data['results'] ?? [];
    return accountsJson
        .map((j) => EmailAccount.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  throw Exception('Failed to load email accounts');
});

final searchQueryProvider = StateProvider<String>((ref) => '');

/// ----------------------
/// REUSABLE EMAIL FORM WIDGET
/// ----------------------
class EmailAccountFormWidget extends StatelessWidget {
  final EmailAccountFormController mailForm;
  const EmailAccountFormWidget({super.key, required this.mailForm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: mailForm.imapHostController,
                hintText: 'imap_host'.tr,
                focusNode: mailForm.focusNodes[2],
                reqNode: mailForm.focusNodes[3],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: mailForm.imapPortController,
                 hintText: 'imap_port'.tr,
                keyboardType: TextInputType.number,
                focusNode: mailForm.focusNodes[0],
                reqNode: mailForm.focusNodes[1],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: mailForm.smtpHostController,
                 hintText: 'smtp_host'.tr,
                focusNode: mailForm.focusNodes[4],
                reqNode: mailForm.focusNodes[5],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: mailForm.smtpPortController,
                hintText: 'smtp_port'.tr,
                keyboardType: TextInputType.number,
                focusNode: mailForm.focusNodes[6],
                reqNode: mailForm.focusNodes[7],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: mailForm.emailController,
                hintText: 'email_address'.tr,
                focusNode: mailForm.focusNodes[8],
                reqNode: mailForm.focusNodes[9],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GradientTextField(
                controller: mailForm.emailPasswordController,
                hintText: 'email_password'.tr,
                focusNode: mailForm.focusNodes[10],
                reqNode: mailForm.focusNodes[11],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class EmailScreenPc extends ConsumerStatefulWidget {
  final bool removeHorizontalPadding;

  const EmailScreenPc({super.key, this.removeHorizontalPadding = false});

  @override
  ConsumerState<EmailScreenPc> createState() => _EmailScreenPcState();
}

class _EmailScreenPcState extends ConsumerState<EmailScreenPc> {
  Future<bool> updateVariable() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: updateVariable(),
      builder: (context, snapshot) {
        final isLoaded = snapshot.data ?? false;
        if (!isLoaded) {
          return const Center(child: SizedBox.shrink());
        }

        final searchQuery = ref.watch(searchQueryProvider);
        final accountsAsync = ref.watch(emailAccountListProvider);
        final theme = ref.read(themeColorsProvider);

        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.removeHorizontalPadding ? 0 : 30,
            ),
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Accounts'.tr,
                          style: AppTextStyles.interBold.copyWith(
                            color: theme.textColor,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Manage your team members and their account permission here.'.tr,
                          style: AppTextStyles.interRegular.copyWith(
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width:50),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 250,
                                maxHeight: 45,
                              ),
                              child: TextField(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textColor,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.popupcontainercolor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 15,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.search,
                                    color: theme.textColor,
                                    size: 18,
                                  ),
                                  hintText: 'Search...'.tr,
                                  hintStyle: TextStyle(color: theme.textColor),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      width: 1,
                                      color: theme.textColor,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onChanged: (value) => ref
                                    .read(searchQueryProvider.notifier)
                                    .state = value,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: elevatedButtonStyleRounded10.copyWith(
                                side: WidgetStateProperty.all(
                                  BorderSide(color: theme.textColor),
                                ),
                                padding: WidgetStateProperty.all(EdgeInsets.zero),
                              ),
                              onPressed: () {
                                _showAccountFormDialog(context, action: 'add');
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 10, height: 45),
                                  AppIcons.add(color: theme.textColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Add account'.tr,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                accountsAsync.when(
                  data: (accounts) {
                    final query = searchQuery.toLowerCase();

                    final filteredAccounts = accounts.where((account) {
                      return account.email.toLowerCase().contains(query) ||
                          account.imapHost.toLowerCase().contains(query) ||
                          account.smtpHost.toLowerCase().contains(query);
                    }).toList();

                    if (filteredAccounts.isEmpty) {
                      return AppLottie.noResults();
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: DataTableThemeData(
                            headingRowColor: WidgetStatePropertyAll(
                              theme.dashboardContainer,
                            ),
                          ),
                        ),
                        child: DataTable(
                          columns: [
                            DataColumn(
                              label: Text(
                                'Email'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'imap'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'smtp'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            const DataColumn(label: Text('')),
                          ],
                          rows: filteredAccounts.map((account) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    account.email,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${account.imapHost}:${account.imapPort}',
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${account.smtpHost}:${account.smtpPort}',
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: PopupMenuButton<Map<String, dynamic>>(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: {
                                            'action': 'edit',
                                            'account': account,
                                          },
                                          child: const Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: {
                                            'action': 'delete',
                                            'account': account,
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        _showAccountFormDialog(
                                          context,
                                          action: value['action'] as String,
                                          data: value['account'] as EmailAccount,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => Center(child: AppLottie.loading(size: 450)),
                  error: (e, _) => Text('${'Error'.tr}: $e'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeletePreview(EmailAccount data) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Email:',
              style: AppTextStyles.interBold.copyWith(color: theme.textColor),
            ),
            const SizedBox(width: 5),
            Text(
              data.email,
              style: AppTextStyles.interRegular.copyWith(color: theme.textColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'imap'.tr,
              style: AppTextStyles.interBold.copyWith(color: theme.textColor),
            ),
            const SizedBox(width: 5),
            Text(
              '${data.imapHost}:${data.imapPort}',
              style: AppTextStyles.interRegular.copyWith(color: theme.textColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'smtp'.tr,
              style: AppTextStyles.interBold.copyWith(color: theme.textColor),
            ),
            const SizedBox(width: 5),
            Text(
              '${data.smtpHost}:${data.smtpPort}',
              style: AppTextStyles.interRegular.copyWith(color: theme.textColor),
            ),
          ],
        ),
      ],
    );
  }

  void _showAccountFormDialog(
    BuildContext context, {
    required String action,
    EmailAccount? data,
  }) {
    showAddEmailAccountDialog(
      context,
      action: action,
      data: data,
      onSuccess: () => ref.invalidate(emailAccountListProvider),
    );
  }
}

void showAddEmailAccountDialog(
  BuildContext context, {
  String action = 'add',
  EmailAccount? data,
  VoidCallback? onSuccess,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      bool initialized = false;

      return Consumer(
        builder: (context, ref, _) {
          final mailForm = ref.watch(emailAccountFormProvider);
          final theme = ref.read(themeColorsProvider);

          String alertTitle = 'Add email account'.tr;
          String alertDescription = 'add_email_account_description'.tr;

          if (action == 'delete') {
            alertTitle = 'Confirm delete';
            alertDescription = 'email_account_will_be_deleted_permanently'.tr;
          } else if (action == 'edit') {
            alertTitle = 'edit_email_account'.tr;
            alertDescription = 'edit_email_account_description'.tr;
          }

          if (!initialized) {
            initialized = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (action == 'edit' && data != null) {
                mailForm.imapHostController.text = data.imapHost;
                mailForm.imapPortController.text = data.imapPort.toString();
                mailForm.smtpHostController.text = data.smtpHost;
                mailForm.smtpPortController.text = data.smtpPort.toString();
                mailForm.emailController.text = data.email;
                mailForm.emailPasswordController.clear();
              } else if (action != 'delete') {
                mailForm.clearAll();
              }
            });
          }

          Widget deletePreview(EmailAccount d) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Email:',
                      style:
                          AppTextStyles.interBold.copyWith(color: theme.textColor),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      d.email,
                      style: AppTextStyles.interRegular
                          .copyWith(color: theme.textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'imap'.tr,
                      style:
                          AppTextStyles.interBold.copyWith(color: theme.textColor),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${d.imapHost}:${d.imapPort}',
                      style: AppTextStyles.interRegular
                          .copyWith(color: theme.textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'smtp'.tr,
                      style:
                          AppTextStyles.interBold.copyWith(color: theme.textColor),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${d.smtpHost}:${d.smtpPort}',
                      style: AppTextStyles.interRegular
                          .copyWith(color: theme.textColor),
                    ),
                  ],
                ),
              ],
            );
          }

          return AlertDialog(
            backgroundColor: theme.adPopBackground,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertTitle,
                  style: AppTextStyles.interBold.copyWith(
                    fontSize: 18,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  alertDescription,
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            content: (action == 'delete')
                ? deletePreview(data!)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EmailProviderHint(theme: theme),
                      const SizedBox(height: 16),
                      EmailAccountFormWidget(mailForm: mailForm),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel'.tr,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool success = false;
                  String message = '';

                  if (action == 'delete') {
                    success = await ref
                        .read(emailAccountProvider.notifier)
                        .deleteEmailAccount(data!.id);
                    message = success
                        ? 'account_deleted_successfully'.tr
                        : 'failed_to_delete_account'.tr;
                  } else {
                    final payload = {
                      "imap_host": mailForm.imapHostController.text,
                      "imap_port":
                          int.tryParse(mailForm.imapPortController.text),
                      "smtp_host": mailForm.smtpHostController.text,
                      "smtp_port":
                          int.tryParse(mailForm.smtpPortController.text),
                      "email_address": mailForm.emailController.text,
                      "email_password": mailForm.emailPasswordController.text,
                      "use_tls": true,
                    };

                    if (action == 'edit') {
                      success = await ref
                          .read(emailAccountProvider.notifier)
                          .updateEmailAccount(data!.id, payload);
                      message = success
                          ? 'account_updated_successfully'.tr
                          : 'failed_to_update_account'.tr;
                    } else {
                      success = await ref
                          .read(emailAccountProvider.notifier)
                          .saveEmailAccount(payload);
                      message = success
                          ? 'account_saved_successfully'.tr
                          : 'failed_to_save_account'.tr;
                    }
                  }

                  if (!context.mounted) return;

                  if (success) {
                    onSuccess?.call();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );

                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white70,
                  minimumSize: const Size(90, 40),
                ),
                child: Text(
                  'Submit'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _EmailProviderHint extends StatefulWidget {
  final ThemeColors theme;

  const _EmailProviderHint({required this.theme});

  @override
  State<_EmailProviderHint> createState() => _EmailProviderHintState();
}

class _EmailProviderHintState extends State<_EmailProviderHint> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.themeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'email_account_setup_hint_title'.tr,
                        style: AppTextStyles.interRegular.copyWith(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: theme.textColor,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: theme.dashboardBoarder),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProviderRow(
                      theme: theme,
                      provider: 'Gmail',
                      imap: 'imap.gmail.com : 993',
                      smtp: 'smtp.gmail.com : 587',
                      note: 'gmail_app_password_note'.tr,
                    ),
                    const SizedBox(height: 10),
                    _ProviderRow(
                      theme: theme,
                      provider: 'Outlook / Hotmail',
                      imap: 'outlook.office365.com : 993',
                      smtp: 'smtp.office365.com : 587',
                    ),
                    const SizedBox(height: 10),
                    _ProviderRow(
                      theme: theme,
                      provider: 'email_provider_other'.tr,
                      imap: null,
                      smtp: null,
                      note: 'email_provider_other_note'.tr,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final ThemeColors theme;
  final String provider;
  final String? imap;
  final String? smtp;
  final String? note;

  const _ProviderRow({
    required this.theme,
    required this.provider,
    required this.imap,
    required this.smtp,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider,
          style: AppTextStyles.interBold.copyWith(
            fontSize: 12,
            color: theme.textColor,
          ),
        ),
        if (imap != null) ...[
          const SizedBox(height: 3),
          _LabelValue(theme: theme, label: 'IMAP', value: imap!),
          const SizedBox(height: 2),
          _LabelValue(theme: theme, label: 'SMTP', value: smtp!),
        ],
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note!,
            style: AppTextStyles.interRegular.copyWith(
              fontSize: 11,
              color: theme.textColor.withAlpha(160),
            ),
          ),
        ],
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final String value;

  const _LabelValue({
    required this.theme,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: AppTextStyles.interBold.copyWith(
              fontSize: 11,
              color: theme.textColor.withAlpha(180),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTextStyles.interRegular.copyWith(
            fontSize: 11,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }
}
