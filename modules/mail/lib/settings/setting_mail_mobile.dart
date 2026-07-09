import 'package:flutter/foundation.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:mail/settings/mail_form.dart' hide EmailAccountForm;
import 'package:mail/settings/mail_services.dart';
import 'package:mail/settings/settings_mail_pc.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';

class SettingMailMobile extends ConsumerStatefulWidget {
  const SettingMailMobile({super.key});

  @override
  ConsumerState<SettingMailMobile> createState() => _SettingMailMobileState();
}

class _SettingMailMobileState extends ConsumerState<SettingMailMobile> {
  Future<bool> updateVariable() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: CustomBackgroundGradients.getMainMenuBackground(
            context,
            ref,
          ),
        ),
        child: Column(
          children: [
            MobileSettingsAppbar(
              title: "label_mail".tr,
              onPressed: () => ref.read(navigationService).beamPop(),
            ),
            Expanded(
              child: FutureBuilder<bool>(
                future: updateVariable(),
                builder: (context, snapshot) {
                  final isLoaded = snapshot.data ?? false;
                  if (!isLoaded) {
                    return Center(child: AppLottie.loading(size: 200));
                  }

                  final theme = ref.watch(themeColorsProvider);
                  final searchQuery = ref.watch(searchQueryProvider);
                  final accountsAsync = ref.watch(emailAccountListProvider);

                  return SafeArea(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Text(
                              'Email Accounts'.tr,
                              style: AppTextStyles.interBold.copyWith(
                                color: theme.textColor,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Manage your team members and their account permission here.'.tr,
                              style: AppTextStyles.interRegular.copyWith(
                                fontSize: 14,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Search + Add button (stacked on mobile)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textColor,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: theme.dashboardContainer,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 14,
                                          ),
                                      suffixIcon: Icon(
                                        Icons.search,
                                        color: theme.textColor,
                                        size: 18,
                                      ),
                                      hintText: 'Search...'.tr,
                                      hintStyle: TextStyle(
                                        color: theme.textColor,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          width: 1,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          width: 1,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                    onChanged:
                                        (value) =>
                                            ref
                                                .read(
                                                  searchQueryProvider.notifier,
                                                )
                                                .state = value,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        () => _showAccountForm(
                                          context,
                                          'add',
                                          null,
                                          theme,
                                        ),

                                    icon: Icon(
                                      Icons.add,
                                      color: theme.textColor,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Add account'.tr,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.dashboardContainer,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Accounts list (cards on mobile)
                            accountsAsync.when(
                              data: (accounts) {
                                final query = searchQuery.toLowerCase();
                                final filtered =
                                    accounts.where((a) {
                                      return a.email.toLowerCase().contains(
                                            query,
                                          ) ||
                                          a.imapHost.toLowerCase().contains(
                                            query,
                                          ) ||
                                          a.smtpHost.toLowerCase().contains(
                                            query,
                                          );
                                    }).toList();

                                if (filtered.isEmpty) {
                                    return Center(
                                         child: Column(
                                           children: [
                                             AppLottie.noResults(size: 260),
                                           ],
                                         ),
                                    );
                                }
                                return Column(
                                  children:
                                      filtered.map((account) {
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: theme.dashboardContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: theme.textColor.withAlpha(
                                                64,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Leading email & details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      account.email,
                                                      style: AppTextStyles
                                                          .interSemiBold
                                                          .copyWith(
                                                            color:
                                                                theme.textColor,
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'imap'.tr,
                                                          style: AppTextStyles
                                                              .interBold
                                                              .copyWith(
                                                                color:
                                                                    theme
                                                                        .textColor,
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${account.imapHost}:${account.imapPort}',
                                                            style: AppTextStyles
                                                                .interRegular
                                                                .copyWith(
                                                                  color:
                                                                      theme
                                                                          .textColor,
                                                                  fontSize: 13,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'smtp'.tr,
                                                          style: AppTextStyles
                                                              .interBold
                                                              .copyWith(
                                                                color:
                                                                    theme
                                                                        .textColor,
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${account.smtpHost}:${account.smtpPort}',
                                                            style: AppTextStyles
                                                                .interRegular
                                                                .copyWith(
                                                                  color:
                                                                      theme
                                                                          .textColor,
                                                                  fontSize: 13,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Trailing menu
                                              PopupMenuButton<
                                                Map<String, dynamic>
                                              >(
                                                color: theme.adPopBackground,
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: theme.textColor,
                                                ),
                                                itemBuilder:
                                                    (context) => [
                                                      PopupMenuItem(
                                                        value: {
                                                          'action': 'edit',
                                                          'account': account,
                                                        },
                                                        child: Text(
                                                          'Edit'.tr,
                                                          style: TextStyle(
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: {
                                                          'action': 'delete',
                                                          'account': account,
                                                        },
                                                        child: Text(
                                                          'Delete'.tr,
                                                          style: TextStyle(
                                                            color:
                                                                theme.textColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                onSelected:
                                                    (newValue) =>
                                                        _showAccountFormDialog(
                                                          context,
                                                          newValue['action']
                                                              as String,
                                                          newValue['account']
                                                              as EmailAccount,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                );
                              },
                              loading:
                                  () => Center(
                                    child: AppLottie.loading(size: 200),
                                  ),
                              error:
                                  (e, _) => Text(
                                    '${'Error'.tr}: $e',
                                    style: TextStyle(color: theme.textColor),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- dialogs & helpers (reused logic) ----------

  Widget _buildDeletePreview(EmailAccount data) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '${'Email'.tr}:',
              style: AppTextStyles.interBold.copyWith(color: theme.textColor),
            ),
            const SizedBox(width: 5),
            Text(
              data.email,
              style: AppTextStyles.interRegular.copyWith(
                color: theme.textColor,
              ),
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
              style: AppTextStyles.interRegular.copyWith(
                color: theme.textColor,
              ),
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
              style: AppTextStyles.interRegular.copyWith(
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAccountFormDialog(
    BuildContext context,
    String action,
    EmailAccount? data,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final mailForm = ref.watch(emailAccountFormProvider);
        final theme = ref.read(themeColorsProvider);

        String alertTitle = 'add_email_account'.tr;
        String alertDescription = 'enter_passcode_to_verify_access'.tr;

        if (action == 'delete') {
          alertTitle = 'confirm_delete'.tr;
          alertDescription = 'email_account_will_be_deleted_permanently'.tr;
        } else if (action == 'edit') {
          alertTitle = 'edit_email_account'.tr;
          mailForm.imapHostController.text = data!.imapHost;
          mailForm.imapPortController.text = data.imapPort.toString();
          mailForm.smtpHostController.text = data.smtpHost;
          mailForm.smtpPortController.text = data.smtpPort.toString();
          mailForm.emailController.text = data.email;
          mailForm.emailPasswordController.clear();
        } else {
          mailForm.imapHostController.clear();
          mailForm.imapPortController.clear();
          mailForm.smtpHostController.clear();
          mailForm.smtpPortController.clear();
          mailForm.emailController.clear();
          mailForm.emailPasswordController.clear();
        }

        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
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
          content:
              (action == 'delete')
                  ? _buildDeletePreview(data!)
                  : EmailAccountFormWidget(mailForm: mailForm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                bool success = false;
                String message = '';

                if (action == 'delete') {
                  success = await ref
                      .read(emailAccountProvider.notifier)
                      .deleteEmailAccount(data!.id);
                  message = success ? 'account_deleted_successfully'.tr : 'failed_to_delete_account'.tr;
                } else {
                  final payload = {
                    "imap_host": mailForm.imapHostController.text,
                    "imap_port": int.tryParse(mailForm.imapPortController.text),
                    "smtp_host": mailForm.smtpHostController.text,
                    "smtp_port": int.tryParse(mailForm.smtpPortController.text),
                    "email_address": mailForm.emailController.text,
                    "email_password": mailForm.emailPasswordController.text,
                    "use_tls": true,
                  };

                  if (action == 'edit') {
                    success = await ref
                        .read(emailAccountProvider.notifier)
                        .updateEmailAccount(data!.id, payload);
                    message = success ? 'account_updated_successfully'.tr : 'failed_to_update_account'.tr;
                  } else {
                    success = await ref
                        .read(emailAccountProvider.notifier)
                        .saveEmailAccount(payload);
                    message = success ? 'account_saved_successfully'.tr : 'failed_to_save_account'.tr;
                  }
                }

                if (success) {
                  ref.invalidate(emailAccountListProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                  if (action == 'delete') {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (context.mounted) Navigator.of(context).pop();
                    });
                  } else {
                    if (context.mounted) Navigator.of(context).pop();
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
              ),
              child: Text(
                'Submit'.tr,
                style: TextStyle(
                  color: theme.themeColorText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAccountForm(
    BuildContext context,
    String action,
    EmailAccount? data,
    ThemeColors theme
  ) {
    if (_useBottomSheet(context)) {
      _showAccountFormBottomSheet(context, action, data, theme);
    } else {
      _showAccountFormDialog(context, action, data);
    }
  }

  void _showAccountFormBottomSheet(
    BuildContext context,
    String action,
    EmailAccount? data,
    ThemeColors theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
       backgroundColor: theme.dashboardContainer,
       shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final mailForm = ref.watch(emailAccountFormProvider);
        final theme = ref.read(themeColorsProvider);

        String alertTitle = 'add_email_account'.tr;
        String alertDescription = 'enter_passcode_to_verify_access'.tr;

        if (action == 'delete') {
          alertTitle = 'confirm_delete'.tr;
          alertDescription = 'email_account_will_be_deleted_permanently'.tr;
        } else if (action == 'edit') {
          alertTitle = 'edit_email_account'.tr;
          mailForm.imapHostController.text = data!.imapHost;
          mailForm.imapPortController.text = data.imapPort.toString();
          mailForm.smtpHostController.text = data.smtpHost;
          mailForm.smtpPortController.text = data.smtpPort.toString();
          mailForm.emailController.text = data.email;
          mailForm.emailPasswordController.clear();
        } else {
          mailForm.imapHostController.clear();
          mailForm.imapPortController.clear();
          mailForm.smtpHostController.clear();
          mailForm.smtpPortController.clear();
          mailForm.emailController.clear();
          mailForm.emailPasswordController.clear();
        }

        Future<void> onSubmit() async {
          bool success = false;
          String message = '';

          if (action == 'delete') {
            success = await ref
                .read(emailAccountProvider.notifier)
                .deleteEmailAccount(data!.id);
            message = success ? 'account_deleted_successfully'.tr : 'failed_to_delete_account'.tr;
          } else {
            final payload = {
              "imap_host": mailForm.imapHostController.text,
              "imap_port": int.tryParse(mailForm.imapPortController.text),
              "smtp_host": mailForm.smtpHostController.text,
              "smtp_port": int.tryParse(mailForm.smtpPortController.text),
              "email_address": mailForm.emailController.text,
              "email_password": mailForm.emailPasswordController.text,
              "use_tls": true,
            };

            if (action == 'edit') {
              success = await ref
                  .read(emailAccountProvider.notifier)
                  .updateEmailAccount(data!.id, payload);
              message = success ? 'account_updated_successfully'.tr : 'failed_to_update_account'.tr;
            } else {
              success = await ref
                  .read(emailAccountProvider.notifier)
                  .saveEmailAccount(payload);
              message = success ? 'account_saved_successfully'.tr : 'failed_to_save_account'.tr;
            }
          }

          if (success) {
            ref.invalidate(emailAccountListProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
        
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
        
                  action == 'delete'
                      ? _buildDeletePreview(data!)
                      : EmailAccountFormWidget(mailForm: mailForm),
        
                  const SizedBox(height: 16),
        
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                           style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(6)
                            )
                          ),
                          child: Text(
                            'Cancel'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.themeColor,
                          ),
                          child: Text(
                            'Submit'.tr,
                            style: TextStyle(
                              color: theme.themeColorText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

bool _useBottomSheet(BuildContext context) {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
