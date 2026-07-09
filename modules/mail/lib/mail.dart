import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mail/settings/settings_mail_pc.dart';
import 'package:core/theme/apptheme.dart';
import 'emma/anchors/anchors_mail.dart';
import 'components/mail_sidebar.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/ui/device_type_util.dart';

import 'package:mail/components/mail_list.dart';
import 'package:mail/components/mail_list_mobile.dart';
import 'package:mail/components/vertical_buttons.dart';
import 'package:mail/utils/api_services.dart';
import 'package:mail/utils/mail_filters.dart';

// Module contract (AppModule). Lets the host app register mail via the
// ModuleRegistry without importing mail's pages directly.
export 'core/module.dart';

class EmailView extends ConsumerStatefulWidget {
  final int? leadId;
  final dynamic lead;

  const EmailView({
    super.key,
    this.leadId,
    this.lead,
  });

  @override
  ConsumerState<EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends ConsumerState<EmailView> {
  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    final isSidebarVisible = ref.watch(mailSidebarVisibleProvider);
    final accountsAsync = ref.watch(emailAccountsProvider);
    final hasNoAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts.isEmpty,
      orElse: () => false,
    );

    return EmmaUiAnchorTarget(
      anchorKey: EmmaAnchors.mailViewRoot.anchorKey,

      spec: EmmaAnchors.mailViewRoot,
      runtimeMode: EmmaAnchors.mailViewRoot.runtimeMode,
      tapMode: EmmaAnchors.mailViewRoot.tapMode,
      child: BarManager(
        showClientToggle: true,
        sideMenuKey: sideMenuKey,
        appModule: AppModule.agentCrm,
        verticalButtons: MailVerticalBar(
          onPressed: () {},
          showActionList: true,
          leadId: widget.leadId,
          lead: widget.lead,
        ),
        childrenTablet: [
          if (hasNoAccounts)
            const Expanded(child: _NoMailAccountsView())
          else ...[
            if (isSidebarVisible)
              MailSidebar(
                width: 200,
                isTablet: true,
                leadId: widget.leadId,
                lead: widget.lead,
              ),
            Expanded(
              child: EmailListWithPreview(
                leadId: widget.leadId,
                lead: widget.lead,
                isTablet: true,
                enableBulkSelection: true,
                flexList: 2,
                flexPreview: 3,
              ),
            ),
          ],
        ],
        childrenMobile: [
          SizedBox(height: TopAppBarSize.resolve(context)),
          if (hasNoAccounts)
            const Expanded(child: _NoMailAccountsView())
          else
            Expanded(
              child: EmailListWithPreviewMobile(
                leadId: widget.leadId,
                lead: widget.lead,
                isMobile: true,
                enableBulkSelection: true,
              ),
            ),
          SizedBox(height: BottomBarSize.resolve(context)),
        ],
        childrenPc: [
          if (hasNoAccounts)
            const Expanded(child: _NoMailAccountsView())
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sidebarWidth =
                      constraints.maxWidth < 1120 ? 252.0 : 280.0;

                  return Row(
                    children: [
                      const SizedBox(width: 8),
                      MailSidebar(
                        width: sidebarWidth,
                        isTablet: false,
                        leadId: widget.leadId,
                        lead: widget.lead,
                      ),
                      Expanded(
                        child: EmailListWithPreview(
                          leadId: widget.leadId,
                          lead: widget.lead,
                          enableBulkSelection: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NoMailAccountsView extends ConsumerWidget {
  const _NoMailAccountsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_lock_outlined,
              size: 72,
              color: theme.textColor.withAlpha(60),
            ),
            const SizedBox(height: 24),
            Text(
              'No connected email accounts'.tr,
              style: AppTextStyles.interBold.copyWith(
                color: theme.textColor,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'no_email_account_connect_description'.tr,
              style: AppTextStyles.interRegular.copyWith(
                color: theme.textColor.withAlpha(160),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => showAddEmailAccountDialog(
                context,
                onSuccess: () => ref.invalidate(emailAccountsProvider),
              ),
              icon: AppIcons.add(color: theme.themeTextColor),
              label: Text(
                'Add account'.tr,
                style: TextStyle(color: theme.themeTextColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}