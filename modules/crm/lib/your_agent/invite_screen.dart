import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/your_agent/models.dart';
import 'package:crm/your_agent/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class ClientPortalInviteScreen extends ConsumerWidget {
  final String token;
  final String? loginRoute;
  final String? registerRoute;

  const ClientPortalInviteScreen({
    super.key,
    required this.token,
    this.loginRoute,
    this.registerRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      appModule: AppModule.portal,
      sideMenuKey: sideMenuKey,
      isTopAppBarHoveroverUI: false,
      paddingPc: 24,
      paddingMobile: 16,
      childPc: _ClientPortalInviteBody(
        token: token,
        isMobile: false,
        loginRoute: loginRoute,
        registerRoute: registerRoute,
      ),
      childMobile: _ClientPortalInviteBody(
        token: token,
        isMobile: true,
        loginRoute: loginRoute,
        registerRoute: registerRoute,
      ),
    );
  }
}

class _ClientPortalInviteBody extends ConsumerStatefulWidget {
  final String token;
  final bool isMobile;
  final String? loginRoute;
  final String? registerRoute;

  const _ClientPortalInviteBody({
    required this.token,
    required this.isMobile,
    this.loginRoute,
    this.registerRoute,
  });

  @override
  ConsumerState<_ClientPortalInviteBody> createState() =>
      _ClientPortalInviteBodyState();
}

class _ClientPortalInviteBodyState
    extends ConsumerState<_ClientPortalInviteBody> {
  bool _isBinding = false;

  Future<void> _bindInvite(ClientPortalInviteStatusResponse invite) async {
    if (_isBinding) return;

    setState(() => _isBinding = true);

    try {
      final result =
          await ref.read(clientPortalInviteActionsProvider).bindInvite(
                token: widget.token,
              );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('portal_access_activated_message'.tr),
        ),
      );

      _openPanel(result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'failed_to_activate_invitation'.tr} $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBinding = false);
      }
    }
  }

  void _openPanel(ClientPortalInviteStatusResponse invite) {
    final nav = ref.read(navigationService);
    final portalUuid = invite.portalUuid;

    if (portalUuid != null && portalUuid.isNotEmpty) {
      nav.pushNamedScreen('/your-agent/$portalUuid');
      return;
    }

    nav.pushNamedScreen('/your-agent');
  }

  void _openLogin() {
    if (widget.loginRoute == null || widget.loginRoute!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'provide_login_route_message'.tr
          ),
        ),
      );
      return;
    }

    ref.read(navigationService).pushNamedScreen(widget.loginRoute!);
  }

  void _openRegister() {
    if (widget.registerRoute == null || widget.registerRoute!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'provide_register_route_message'.tr
          ),
        ),
      );
      return;
    }

    ref.read(navigationService).pushNamedScreen(widget.registerRoute!);
  }

  EdgeInsets _pagePadding(BuildContext context) {
    final top = widget.isMobile ? TopAppBarSize.resolve(context) + 16 : 32.0;
    final bottom =
        widget.isMobile ? BottomBarSize.resolve(context) + 24 : 32.0;

    return EdgeInsets.fromLTRB(16, top, 16, bottom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final inviteAsync =
        ref.watch(clientPortalInviteStatusProvider(widget.token));
    final isLoggedIn = ApiServices.isUserLoggedIn();

    return inviteAsync.when(
      loading: () => Padding(
        padding: _pagePadding(context),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Padding(
        padding: _pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _InviteContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.expensesRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'failed_to_load_invitation'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(190),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PrimaryActionButton(
                    label: 'refresh_button'.tr,
                    onTap: () {
                      ref.invalidate(
                        clientPortalInviteStatusProvider(widget.token),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (invite) {
        return SingleChildScrollView(
          padding: _pagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InviteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InviteHeader(
                          status: invite.status,
                          reason: invite.reason,
                        ),
                        const SizedBox(height: 20),
                        _InviteStatusBanner(
                          status: invite.status,
                          reason: _fallbackReason(invite),
                        ),
                        const SizedBox(height: 20),
                        _SectionTitle(
                          title:'case_details_title'.tr,
                        ),
                        const SizedBox(height: 10),
                        _InviteInfoCard(invite: invite),
                        const SizedBox(height: 20),
                        _SectionTitle(
                          title: 'permissions_title'.tr,
                        ),
                        const SizedBox(height: 10),
                        _PermissionsWrap(invite: invite),
                        const SizedBox(height: 24),
                        _ActionSection(
                          invite: invite,
                          isLoggedIn: isLoggedIn,
                          isBinding: _isBinding,
                          onAccept: invite.isValid && isLoggedIn
                              ? () => _bindInvite(invite)
                              : null,
                          onLogin: _openLogin,
                          onRegister: _openRegister,
                          onOpenPanel: () => _openPanel(invite),
                          onRefresh: () {
                            ref.invalidate(
                              clientPortalInviteStatusProvider(widget.token),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _fallbackReason(ClientPortalInviteStatusResponse invite) {
    if (invite.reason != null && invite.reason!.trim().isNotEmpty) {
      return invite.reason!;
    }

    switch (invite.status) {
      case 'valid':
        return 'invite_valid_message'.tr;
      case 'already_bound':
        return 'invite_already_bound_message'.tr;
      case 'bound':
        return 'invite_bound_message'.tr;
      case 'disabled':
        return 'invite_disabled_message'.tr;
      case 'expired':
        return 'invite_expired_message'.tr;
      case 'invite_expired':
        return 'invite_link_expired_message'.tr;
      case 'not_found':
        return 'invite_not_found_message'.tr;
      case 'bound_to_other_user':
        return 'invite_bound_to_other_user_message'.tr;
      default:
        return 'invite_unknown_status_message'.tr;
    }
  }
}

class _InviteContainer extends ConsumerWidget {
  final Widget child;

  const _InviteContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(240),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: child,
    );
  }
}

class _InviteHeader extends ConsumerWidget {
  final String status;
  final String? reason;

  const _InviteHeader({
    required this.status,
    required this.reason,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statusColor(theme, status).withAlpha(40),
            border: Border.all(
              color: _statusColor(theme, status).withAlpha(110),
            ),
          ),
          child: Icon(
            _statusIcon(status),
            size: 34,
            color: _statusColor(theme, status),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _statusTitle(status),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'your_agent_panel_description'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textColor.withAlpha(200),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _InviteStatusBanner extends ConsumerWidget {
  final String status;
  final String reason;

  const _InviteStatusBanner({
    required this.status,
    required this.reason,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final color = _statusColor(theme, status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(100),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _statusIcon(status),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteInfoCard extends ConsumerWidget {
  final ClientPortalInviteStatusResponse invite;

  const _InviteInfoCard({
    required this.invite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(180),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'case_label'.tr,
            value: invite.transactionTitle,
          ),
          _InfoRow(
            label: 'type_label'.tr,
            value: invite.isSeller
                ? 'seller_role'.tr
                : invite.isBuyer
                    ? 'buyer_role'.tr
                    : '—',
          ),
          _InfoRow(
            label: 'status_label'.tr,
            value: invite.transactionStatus ?? '—',
          ),
          _InfoRow(
            label: 'amount_label'.tr,
            value: invite.amountLabel ?? '—',
          ),
          _InfoRow(
            label: 'invitation_email_label'.tr,
            value: invite.invitedEmail ?? '—',
          ),
          _InfoRow(
            label: 'invitation_phone_label'.tr,
            value: invite.invitedPhone ?? '—',
          ),
          if (invite.agentName != null)
            _InfoRow(
              label: 'agent_label'.tr,
              value: invite.agentName!,
            ),
          if (invite.agentEmail != null)
            _InfoRow(
              label: 'agent_email_label'.tr,
              value: invite.agentEmail!,
            ),
          if (invite.agentPhone != null)
            _InfoRow(
              label: 'agent_phone_label'.tr,
              value: invite.agentPhone!,
            ),
          if (invite.visibleUntil != null)
            _InfoRow(
              label: 'visible_until_label'.tr,
              value: invite.visibleUntil!,
            ),
        ],
      ),
    );
  }
}

class _PermissionsWrap extends ConsumerWidget {
  final ClientPortalInviteStatusResponse invite;

  const _PermissionsWrap({
    required this.invite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = <String>[
      if (invite.canEditListing) 'permission_suggest_listing_changes'.tr,
      if (invite.canViewDocuments) 'permission_view_documents'.tr,
      if (invite.canViewPresentations) 'permission_view_presentations'.tr,
      if (invite.isReadOnly) 'permission_read_only'.tr,
      if (!invite.canEditListing &&
          !invite.canViewDocuments &&
          !invite.canViewPresentations &&
          !invite.isReadOnly)
        'permission_no_additional'.tr,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: permissions.map((e) => _PermissionChip(label: e)).toList(),
    );
  }
}

class _PermissionChip extends ConsumerWidget {
  final String label;

  const _PermissionChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.themeColor.withAlpha(90),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ActionSection extends ConsumerWidget {
  final ClientPortalInviteStatusResponse invite;
  final bool isLoggedIn;
  final bool isBinding;
  final VoidCallback? onAccept;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onOpenPanel;
  final VoidCallback onRefresh;

  const _ActionSection({
    required this.invite,
    required this.isLoggedIn,
    required this.isBinding,
    required this.onAccept,
    required this.onLogin,
    required this.onRegister,
    required this.onOpenPanel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final actions = <Widget>[];

    if (invite.isValid) {
      if (isLoggedIn) {
        actions.add(
          _PrimaryActionButton(
            label: isBinding ? 'activating_status'.tr : 'accept_access_button'.tr,
            onTap: isBinding ? null : onAccept,
            icon: Icons.check_circle_outline,
          ),
        );
      } else {
        actions.add(
          _PrimaryActionButton(
            label: 'login_button'.tr,
            onTap: onLogin,
            icon: Icons.login,
          ),
        );
        actions.add(
          _SecondaryActionButton(
            label: 'register_button'.tr,
            onTap: onRegister,
            icon: Icons.person_add_alt_1,
          ),
        );
      }
    } else if (invite.isAlreadyBound || invite.isBound) {
      if (isLoggedIn) {
        actions.add(
          _PrimaryActionButton(
            label: 'go_to_panel_button'.tr,
            onTap: onOpenPanel,
            icon: Icons.arrow_forward,
          ),
        );
      } else {
        actions.add(
          _PrimaryActionButton(
            label: 'login_button'.tr,
            onTap: onLogin,
            icon: Icons.login,
          ),
        );
      }
    } else if (invite.isBoundToOtherUser) {
      if (!isLoggedIn) {
        actions.add(
          _PrimaryActionButton(
            label: 'login_to_correct_account_button'.tr,
            onTap: onLogin,
            icon: Icons.login,
          ),
        );
      }
    }

    actions.add(
      _SecondaryActionButton(
        label: 'refresh_button'.tr,
        onTap: onRefresh,
        icon: Icons.refresh,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (invite.isValid && !isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'login_or_register_to_activate_message'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(200),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions,
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon ?? Icons.arrow_forward, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const _SecondaryActionButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon ?? Icons.open_in_new,
        color: theme.textColor,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.dashboardBoarder),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _SectionTitle extends ConsumerWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Text(
      title,
      style: TextStyle(
        color: theme.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoRow extends ConsumerWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha(190),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ThemeColors theme, String status) {
  switch (status) {
    case 'valid':
    case 'bound':
    case 'already_bound':
      return theme.themeColor;
    case 'disabled':
    case 'expired':
    case 'invite_expired':
    case 'bound_to_other_user':
      return AppColors.superbee;
    case 'not_found':
      return AppColors.hardRed;
    default:
      return theme.themeColor;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'valid':
      return Icons.mark_email_read_outlined;
    case 'bound':
      return Icons.verified_outlined;
    case 'already_bound':
      return Icons.link_outlined;
    case 'disabled':
      return Icons.block_outlined;
    case 'expired':
    case 'invite_expired':
      return Icons.schedule_outlined;
    case 'bound_to_other_user':
      return Icons.person_off_outlined;
    case 'not_found':
      return Icons.search_off_outlined;
    default:
      return Icons.info_outline;
  }
}

String _statusTitle(String status) {
  switch (status) {
    case 'valid':
      return 'invite_title_valid'.tr;
    case 'bound':
      return 'invite_title_bound'.tr;
    case 'already_bound':
      return 'invite_title_already_bound'.tr;
    case 'disabled':
      return 'invite_title_disabled'.tr;
    case 'expired':
      return 'invite_title_expired'.tr;
    case 'invite_expired':
      return 'invite_title_invite_expired'.tr;
    case 'bound_to_other_user':
      return 'invite_title_bound_to_other_user'.tr;
    case 'not_found':
      return 'invite_title_not_found'.tr;
    default:
      return 'invite_title_default'.tr;
  }
}