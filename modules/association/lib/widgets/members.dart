import 'package:association/models/members_model.dart';
import 'package:association/providers/members_provider.dart';
import 'package:association/widgets/add_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/text_field.dart';
import 'package:crm/contact_panel/navigation/enum.dart';

/// ============================================================
/// Association routes builders (NO templates, always real paths)
/// ============================================================

String _associationAdminBase(int associationId) =>
    '${Routes.associationAdminPath}/$associationId';

String _associationMembersBase(int associationId) =>
    '${_associationAdminBase(associationId)}/members';

String _associationNotificationsPath(int associationId) =>
    '${_associationMembersBase(associationId)}/notifications';

String _associationApplicationsPath(int associationId) =>
    '${_associationMembersBase(associationId)}/aplications';

String _associationLoyaltyPath(int associationId) =>
    '${_associationMembersBase(associationId)}/loyalty';

String _associationContactDashboardPath({
  required int associationId,
  required int contactId,
}) =>
    '${_associationAdminBase(associationId)}/contact/$contactId/dashboard';

int? _extractAssociationAdminIdFromPath(String path) {
  // Expected: /association/admin/<id>/...
  try {
    final seg = Uri.parse(path).pathSegments;
    final a = seg.indexOf('association');
    if (a == -1) return null;
    if (a + 1 >= seg.length) return null;
    if (seg[a + 1] != 'admin') return null;
    if (a + 2 >= seg.length) return null;
    return int.tryParse(seg[a + 2]);
  } catch (_) {
    return null;
  }
}

void _push(WidgetRef ref, String route, {Object? data}) {
  ref.read(navigationHistoryProvider.notifier).addPage(route);
  ref.read(navigationService).pushNamedScreen(route, data: data);
}

/// --- Banner with "Manage payments" ---
class _PaymentsBanner extends StatelessWidget {
  final ThemeColors theme;
  const _PaymentsBanner({this.onManage, required this.theme});

  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.info_outline_rounded, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'manage_subscriptions_message'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: onManage,
              child: Text(
                'manage_payments'.tr,
                style: TextStyle(color: theme.textColor, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --- Table header ---
class _TableHeader extends StatelessWidget {
  final ThemeColors theme;
  const _TableHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'member_name'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              'membership_status'.tr,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

/// --- List with rows ---
class _MembersList extends StatelessWidget {
  const _MembersList({
    required this.items,
    required this.theme,
    this.onViewDetails,
    this.onEdit,
    this.onSendInvoice,
    this.onSendReminder,
  });

  final ThemeColors theme;
  final List<AssociationMemberModel> items;
  final void Function(AssociationMemberModel member)? onViewDetails;
  final void Function(AssociationMemberModel member)? onEdit;
  final void Function(AssociationMemberModel member)? onSendInvoice;
  final void Function(AssociationMemberModel member)? onSendReminder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (ctx, i) => _MemberRow(
          theme: theme,
          m: items[i],
          onViewDetails: onViewDetails,
          onEdit: onEdit,
          onSendInvoice: onSendInvoice,
          onSendReminder: onSendReminder,
        ),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.7,
          color: Theme.of(context).dividerColor.withAlpha(153),
        ),
        itemCount: items.length,
      ),
    );
  }
}

/// --- Single row ---
class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.m,
    this.onViewDetails,
    this.onEdit,
    this.onSendInvoice,
    this.onSendReminder,
    required this.theme,
  });

  final ThemeColors theme;
  final AssociationMemberModel m;
  final void Function(AssociationMemberModel member)? onViewDetails;
  final void Function(AssociationMemberModel member)? onEdit;
  final void Function(AssociationMemberModel member)? onSendInvoice;
  final void Function(AssociationMemberModel member)? onSendReminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = m.user?.name ?? 'member_placeholder'.tr;
    final email = m.user?.email;
    final avatarUrl = m.user?.avatar;

    return ElevatedButton(
      style: elevatedButtonStyleRounded10,
      onPressed: () {
        final nav = ref.read(navigationService);
        final currentPath = nav.currentPath;

        final contactId = m.user?.id;
        if (contactId == null) return;

        final assocId = _extractAssociationAdminIdFromPath(currentPath);
        if (assocId == null) {
          // Fallback: do nothing or route to something safe
          return;
        }

        final route = _associationContactDashboardPath(
          associationId: assocId,
          contactId: contactId,
        );

        _push(
          ref,
          route,
          data: {
            'clientViewPop': m.user,
            'contactType': ContactType.associationMember,
          },
        );
      },
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(_initials(displayName))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email ?? '—',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(180),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _StatusChip(status: m.status.apiValue),
            const SizedBox(width: 8),
            _RowMenu(
              onView: () => onViewDetails?.call(m),
              onEdit: () => onEdit?.call(m),
              onInvoice: () => onSendInvoice?.call(m),
              onReminder: () => onSendReminder?.call(m),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }
}

/// --- Status chip (Paid/Unpaid/Pending/Frozen etc.) ---
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = _palette(theme, status);
    final displayText = _getStatusTranslation(status);

    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _getStatusTranslation(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('paid')) return 'paid'.tr;
    if (lowerStatus.contains('active')) return 'active'.tr;
    if (lowerStatus.contains('unpaid')) return 'unpaid'.tr;
    if (lowerStatus.contains('overdue')) return 'overdue'.tr;
    if (lowerStatus.contains('suspended')) return 'suspended'.tr;
    if (lowerStatus.contains('pending')) return 'pending'.tr;
    if (lowerStatus.contains('former')) return 'former'.tr;
    return status;
  }

  (Color bg, Color fg) _palette(ThemeData t, String s) {
    final l = s.toLowerCase();
    if (l.contains('paid') || l.contains('active')) {
      return ((Colors.green.shade50), (Colors.green.shade800));
    }
    if (l.contains('unpaid') || l.contains('overdue') || l.contains('suspended')) {
      return ((Colors.red.shade50), (Colors.red.shade800));
    }
    if (l.contains('pending')) {
      return ((Colors.amber.shade50), (Colors.amber.shade900));
    }
    return ((t.colorScheme.surfaceVariant), (t.colorScheme.onSurface));
  }
}

/// --- Row menu (kebab) ---
class _RowMenu extends StatelessWidget {
  const _RowMenu({
    this.onView,
    this.onEdit,
    this.onInvoice,
    this.onReminder,
  });

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onInvoice;
  final VoidCallback? onReminder;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'more'.tr,
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 8),
              Text('view_details'.tr),
            ],
          ),
          onTap: onView,
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text('edit'.tr),
            ],
          ),
          onTap: onEdit,
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              const Icon(Icons.show_chart, size: 18),
              const SizedBox(width: 8),
              Text('send_invoice'.tr),
            ],
          ),
          onTap: onInvoice,
        ),
        PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, size: 18),
              const SizedBox(width: 8),
              Text('reminder'.tr),
            ],
          ),
          onTap: onReminder,
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(Icons.more_vert_rounded),
      ),
    );
  }
}

/// --- Skeleton while loading ---
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withAlpha(153);
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(height: 1, color: base),
      itemBuilder: (_, __) => Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 220, color: base),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 160, color: base),
                ],
              ),
            ),
            Container(height: 28, width: 88, color: base),
            const SizedBox(width: 12),
            const Icon(Icons.more_vert_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

/// --- Simple error with retry ---
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('try_again'.tr),
          )
        ],
      ),
    );
  }
}

/// --- Pagination bar (simple prev/next) ---
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.onPrev,
    required this.theme,
    required this.onNext,
    required this.page,
  });

  final ThemeColors theme;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          style: elevatedButtonStyleRounded10,
          onPressed: page > 1 ? onPrev : null,
          icon: Icon(Icons.chevron_left, color: theme.textColor),
          label: Text('prev'.tr, style: TextStyle(color: theme.textColor)),
        ),
        const SizedBox(width: 12),
        Text('page'.trParams({'page': page.toString()}), style: TextStyle(color: theme.textColor)),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          style: elevatedButtonStyleRounded10,
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: theme.textColor),
          label: Text('next'.tr, style: TextStyle(color: theme.textColor)),
        ),
      ],
    );
  }
}

/// --- Filter button + sheet ---
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.searchCtrl,
    required this.onApply,
    this.initialStatus,
    required this.theme,
  });

  final ThemeColors theme;
  final TextEditingController searchCtrl;
  final String? initialStatus;
  final void Function(String? status, String? search) onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: theme.dashboardContainer,
      ),
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: () async {
          final res = await showModalBottomSheet<(String?, String?)>(
            backgroundColor: theme.adPopBackground,
            context: context,
            isScrollControlled: true,
            builder: (_) => _FilterSheet(
              searchCtrl: searchCtrl,
              initialStatus: initialStatus,
            ),
          );
          if (res != null) onApply(res.$1, res.$2);
        },
        child: Row(
          children: [
            Icon(Icons.filter_list_rounded, color: theme.textColor),
            const SizedBox(width: 6),
            Text('filters'.tr, style: TextStyle(color: theme.textColor)),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.searchCtrl, this.initialStatus});
  final TextEditingController searchCtrl;
  final String? initialStatus;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {


  String? status;

  @override
  void initState() {
    super.initState();
    final init = widget.initialStatus;
    status = (init == null || init.trim().isEmpty || init == 'all') ? null : init;
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    final theme = ref.read(themeColorsProvider);
    final statuses = [
      'active'.tr,
      'pending'.tr,
      'suspended'.tr,
      'former'.tr,
      'paid'.tr,
      'unpaid'.tr,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list_rounded, color: theme.textColor),
                  const SizedBox(width: 8),
                  Text(
                    'filters'.tr,
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
              const SizedBox(height: 12),

              CoreTextField(
                label: 'search'.tr,
                hintText: 'search_name_email'.tr,
                controller: widget.searchCtrl,
                prefixIcon: Icon(Icons.search, color: theme.textColor),
              ),

              const SizedBox(height: 12),

              CoreDropdown<String>(
                label: 'status'.tr,
                hintText: 'any_status'.tr,
                value: status,
                options: statuses,
                onChanged: (v) => setState(() => status = v),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: elevatedButtonStyleRounded10,
                      onPressed: () {
                        widget.searchCtrl.text = '';
                        Navigator.pop(context, (null, ''));
                      },
                      child: Text(
                        'clear'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: buttonStyleRounded10ThemeRedWithPadding15,
                      onPressed: () => Navigator.pop(
                        context,
                        (status, widget.searchCtrl.text.trim()),
                      ),
                      child: Text(
                        'apply'.tr,
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- Extracted body used by both Page and Section ---
class MembershipStatusBody extends ConsumerWidget {
  const MembershipStatusBody({
    super.key,
    this.onManagePayments,
    this.onViewDetails,
    this.onEdit,
    this.onSendInvoice,
    this.onSendReminder,
    this.isWidget = false,
    required this.associationId,
    required this.theme,
    this.isMobile = false,
    this.showHeader = true,
    this.showPaymentsBanner = true,
    this.showPagination = true,
  });

  final bool isWidget;
  final bool isMobile;
  final int associationId;
  final VoidCallback? onManagePayments;
  final void Function(AssociationMemberModel member)? onViewDetails;
  final void Function(AssociationMemberModel member)? onEdit;
  final void Function(AssociationMemberModel member)? onSendInvoice;
  final void Function(AssociationMemberModel member)? onSendReminder;
  final ThemeColors theme;
  final bool showHeader;
  final bool showPaymentsBanner;
  final bool showPagination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(associationMemberFiltersProvider);
    final pageAsync = ref.watch(associationMembersProvider);

    final searchCtrl = TextEditingController(text: filters.search ?? '');

    return Padding(
      padding: isWidget ? const EdgeInsets.all(12) : const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(height: isMobile ? 10 : 0),

          // Header row
          if (isWidget && showHeader)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'membership_status'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.person_add_alt_1_rounded, color: theme.textColor, size: 18),
                  label: Text('add_member'.tr, style: TextStyle(color: theme.textColor, fontSize: 13)),
                  onPressed: () async {
                    final assocId = associationId;

                    final result = await CreateMemberDialog.show(context);

                    if (result != null) {
                      final ctrl = ref.read(createMemberControllerProvider.notifier);
                      try {
                        await ctrl.create(
                          associationId: assocId,
                          userContact: {
                            'name': result.name,
                            if (result.lastName?.isNotEmpty == true)
                              'last_name': result.lastName,
                            if (result.email?.isNotEmpty == true) 'email': result.email,
                            if (result.phonePrefix?.isNotEmpty == true)
                              'phone_number_prefix': result.phonePrefix,
                            if (result.phone?.isNotEmpty == true)
                              'phone_number': result.phone,
                            if (result.gender != null) 'gender': result.gender,
                            if (result.description?.isNotEmpty == true)
                              'description': result.description,
                            if (result.note?.isNotEmpty == true) 'note': result.note,
                          },
                          companyName: result.companyName?.trim().isEmpty == true
                              ? null
                              : result.companyName,
                          phone: result.phone?.trim().isEmpty == true ? null : result.phone,
                          address: result.address?.trim().isEmpty == true ? null : result.address,
                          location: result.location?.trim().isEmpty == true ? null : result.location,
                          status: result.status,
                          history: result.history,
                          notes: result.notes,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('member_created'.tr)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('create_failed'.tr + e.toString())),
                          );
                        }
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  theme: theme,
                  searchCtrl: searchCtrl,
                  initialStatus: filters.status,
                  onApply: (status, search) {
                    final f = ref.read(associationMemberFiltersProvider);
                    ref.read(associationMemberFiltersProvider.notifier).state = f.copyWith(
                      status: status?.isEmpty == true ? null : status,
                      search: search,
                      page: 1,
                    );
                  },
                ),
              ],
            )
          else if (isMobile)
            Row(
              children: [
                Text(
                  'membership_status'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  color: theme.textColor,
                  tooltip: 'filters'.tr,
                  onPressed: () async {
                    final res = await showModalBottomSheet<(String?, String?)>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _FilterSheet(
                        searchCtrl: searchCtrl,
                        initialStatus: filters.status,
                      ),
                    );
                    if (res != null) {
                      final (status, search) = res;
                      final f = ref.read(associationMemberFiltersProvider);
                      ref.read(associationMemberFiltersProvider.notifier).state = f.copyWith(
                        status: status?.isEmpty == true ? null : status,
                        search: search,
                        page: 1,
                      );
                    }
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                // Notifications
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: theme.dashboardContainer,
                  ),
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: () {
                      _push(ref, _associationNotificationsPath(associationId));
                    },
                    child: Row(
                      children: [
                        AppIcons.notification(
                          height: 25,
                          width: 25,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 6),
                        Text('notifications'.tr, style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Applications
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: theme.dashboardContainer,
                  ),
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: () {
                      _push(ref, _associationApplicationsPath(associationId));
                    },
                    child: Row(
                      children: [
                        AppIcons.document(
                          height: 25,
                          width: 25,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 6),
                        Text('membership_requests'.tr, style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Loyalty
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: theme.dashboardContainer,
                  ),
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: () {
                      _push(ref, _associationLoyaltyPath(associationId));
                    },
                    child: Row(
                      children: [
                        AppIcons.document(
                          height: 25,
                          width: 25,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 6),
                        Text('loyalty_program'.tr, style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Add member
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: theme.dashboardContainer,
                  ),
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: () async {
                      final assocId = associationId;

                      final result = await CreateMemberDialog.show(context);

                      if (result != null) {
                        final ctrl = ref.read(createMemberControllerProvider.notifier);
                        try {
                          await ctrl.create(
                            associationId: assocId,
                            userContact: {
                              'name': result.name,
                              if (result.lastName?.isNotEmpty == true)
                                'last_name': result.lastName,
                              if (result.email?.isNotEmpty == true) 'email': result.email,
                              if (result.phonePrefix?.isNotEmpty == true)
                                'phone_number_prefix': result.phonePrefix,
                              if (result.phone?.isNotEmpty == true)
                                'phone_number': result.phone,
                              if (result.gender != null) 'gender': result.gender,
                              if (result.description?.isNotEmpty == true)
                                'description': result.description,
                              if (result.note?.isNotEmpty == true) 'note': result.note,
                            },
                            companyName: result.companyName?.trim().isEmpty == true
                                ? null
                                : result.companyName,
                            phone: result.phone?.trim().isEmpty == true ? null : result.phone,
                            address: result.address?.trim().isEmpty == true ? null : result.address,
                            location: result.location?.trim().isEmpty == true ? null : result.location,
                            status: result.status,
                            history: result.history,
                            notes: result.notes,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('member_created'.tr)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('create_failed'.tr + e.toString())),
                            );
                          }
                        }
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, color: theme.textColor),
                        const SizedBox(width: 6),
                        Text('add_member'.tr, style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                _FilterButton(
                  theme: theme,
                  searchCtrl: searchCtrl,
                  initialStatus: filters.status,
                  onApply: (status, search) {
                    final f = ref.read(associationMemberFiltersProvider);
                    ref.read(associationMemberFiltersProvider.notifier).state = f.copyWith(
                      status: status?.isEmpty == true ? null : status,
                      search: search,
                      page: 1,
                    );
                  },
                ),
              ],
            ),

          const SizedBox(height: 10),

          if (isWidget && showPaymentsBanner) ...[
            _PaymentsBanner(onManage: onManagePayments, theme: theme),
            const SizedBox(height: 16),
          ],

          if (!isWidget) _TableHeader(theme: theme),

          Expanded(
            child: pageAsync.when(
              loading: () => const _SkeletonList(),
              error: (e, _) => _ErrorView(
                message: '${'failed_to_load_members'.tr}\n$e'  ,
                onRetry: () => ref.invalidate(associationMembersProvider),
              ),
              data: (page) => _MembersList(
                theme: theme,
                items: page.results,
                onViewDetails: onViewDetails,
                onEdit: onEdit,
                onSendInvoice: onSendInvoice,
                onSendReminder: onSendReminder,
              ),
            ),
          ),

          if (showPagination)
            _PaginationBar(
              theme: theme,
              onPrev: () {
                if (filters.page > 1) {
                  ref.read(associationMemberFiltersProvider.notifier).state =
                      filters.copyWith(page: filters.page - 1);
                }
              },
              onNext: () {
                ref.read(associationMemberFiltersProvider.notifier).state =
                    filters.copyWith(page: filters.page + 1);
              },
              page: filters.page,
            ),

          SizedBox(height: isMobile ? 60 : 0),
        ],
      ),
    );
  }
}

/// --- Section version for dashboards (no Scaffold) ---
class MembershipStatusSection extends StatelessWidget {
  const MembershipStatusSection({
    super.key,
    this.height = 520,
    this.onManagePayments,
    this.onViewDetails,
    this.onEdit,
    this.onSendInvoice,
    this.onSendReminder,
    required this.associationId,
    required this.theme,
    this.showHeader = true,
    this.showPaymentsBanner = true,
    this.showPagination = true,
  });

  final ThemeColors theme;
  final int associationId;
  final double height;
  final VoidCallback? onManagePayments;
  final void Function(AssociationMemberModel member)? onViewDetails;
  final void Function(AssociationMemberModel member)? onEdit;
  final void Function(AssociationMemberModel member)? onSendInvoice;
  final void Function(AssociationMemberModel member)? onSendReminder;
  final bool showHeader;
  final bool showPaymentsBanner;
  final bool showPagination;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border.all(color: theme.dashboardBoarder),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: MembershipStatusBody(
          theme: theme,
          isWidget: true,
          associationId: associationId,
          onManagePayments: onManagePayments,
          onViewDetails: onViewDetails,
          onEdit: onEdit,
          onSendInvoice: onSendInvoice,
          onSendReminder: onSendReminder,
          showHeader: showHeader,
          showPaymentsBanner: showPaymentsBanner,
          showPagination: showPagination,
        ),
      ),
    );
  }
}

/// Floating vertical buttons for mobile
class MembersMobileVerticalButtons extends ConsumerWidget {
  const MembersMobileVerticalButtons({
    super.key,
    required this.associationId,
    required this.theme,
  });

  final int associationId;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(associationMemberFiltersProvider);
    final searchCtrl = TextEditingController(text: filters.search ?? '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FloatingCircleButton(
          theme: theme,
          icon: Icons.filter_list_rounded,
          tooltip: 'filters'.tr,
          onTap: () async {
            final res = await showModalBottomSheet<(String?, String?)>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _FilterSheet(
                searchCtrl: searchCtrl,
                initialStatus: filters.status,
              ),
            );
            if (res != null) {
              final (status, search) = res;
              final f = ref.read(associationMemberFiltersProvider);
              ref.read(associationMemberFiltersProvider.notifier).state = f.copyWith(
                status: status?.isEmpty == true ? null : status,
                search: search,
                page: 1,
              );
            }
          },
        ),
        const SizedBox(height: 4),

        _FloatingCircleButton(
          theme: theme,
          iconWidget: AppIcons.notification(
            height: 22,
            width: 22,
            color: theme.textColor,
          ),
          tooltip: 'notifications'.tr,
          onTap: () => _push(ref, _associationNotificationsPath(associationId)),
        ),
        const SizedBox(height: 4),

        _FloatingCircleButton(
          theme: theme,
          iconWidget: AppIcons.person(
            height: 22,
            width: 22,
            color: theme.textColor,
          ),
          tooltip: 'membership_requests'.tr,
          onTap: () => _push(ref, _associationApplicationsPath(associationId)),
        ),
        const SizedBox(height: 4),

        _FloatingCircleButton(
          theme: theme,
          iconWidget: AppIcons.paperClip(
            height: 22,
            width: 22,
            color: theme.textColor,
          ),
          tooltip: 'loyalty_program'.tr,
          onTap: () => _push(ref, _associationLoyaltyPath(associationId)),
        ),

        const SizedBox(height: 4),

        _FloatingCircleButton(
          theme: theme,
          icon: Icons.person_add_alt_1_rounded,
          tooltip: 'add_member'.tr,
          onTap: () async {
            final assocId = associationId;

            final result = await CreateMemberDialog.show(context);

            if (result != null) {
              final ctrl = ref.read(createMemberControllerProvider.notifier);
              try {
                await ctrl.create(
                  associationId: assocId,
                  userContact: {
                    'name': result.name,
                    if (result.lastName?.isNotEmpty == true) 'last_name': result.lastName,
                    if (result.email?.isNotEmpty == true) 'email': result.email,
                    if (result.phonePrefix?.isNotEmpty == true) 'phone_number_prefix': result.phonePrefix,
                    if (result.phone?.isNotEmpty == true) 'phone_number': result.phone,
                    if (result.gender != null) 'gender': result.gender,
                    if (result.description?.isNotEmpty == true) 'description': result.description,
                    if (result.note?.isNotEmpty == true) 'note': result.note,
                  },
                  companyName: result.companyName?.trim().isEmpty == true ? null : result.companyName,
                  phone: result.phone?.trim().isNotEmpty == true ? result.phone : null,
                  address: result.address?.trim().isNotEmpty == true ? result.address : null,
                  location: result.location?.trim().isNotEmpty == true ? result.location : null,
                  status: result.status,
                  history: result.history,
                  notes: result.notes,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('member_created'.tr)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('create_failed'.tr + e.toString())),
                  );
                }
              }
            }
          },
        ),
      ],
    );


  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.theme,
    this.icon,
    this.iconWidget,
    required this.tooltip,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  final ThemeColors theme;
  final IconData? icon;
  final Widget? iconWidget;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final childIcon = iconWidget ??
        Icon(
          icon,
          color: theme.textColor,
          size: 22,
        );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 45, 
          width: 45,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10withoutPadding,
            onPressed: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: childIcon,
            ),
          ),
        ),
      ),
    );
  }
}
