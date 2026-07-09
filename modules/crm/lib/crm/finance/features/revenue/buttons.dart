import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/crm/finance/components/finance_filters_popup.dart';
import 'package:crm/crm/finance/components/side_buttons.dart';
import 'package:crm/crm/finance/dashboard/api_dashboard.dart';
import 'package:crm/crm/finance/dashboard/model_dashboard.dart';
import 'package:crm/crm/finance/providers/finance_company_scope.dart';
import 'package:crm/invoices/form/screen/add_invoice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:crm/crm/finance/providers/finance_filters_provider.dart';

class FinanceButtons extends StatelessWidget {
  final WidgetRef ref;
  final bool isMobile;
  final int? companyId;

  const FinanceButtons({
    super.key,
    required this.ref,
    this.isMobile = false,
    this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: IntrinsicWidth(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 0 : 8),
          child: SizedBox(
            height: isMobile ? 45 : 45.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FinanceStatusActionsButton(
                    ref: ref,
                    isMobile: isMobile,
                  ),
                  const SizedBox(width: 10),
                  FinanceFilterActionsButton(
                    ref: ref,
                    isMobile: isMobile,
                  ),
                  const SizedBox(width: 10),
                  FinanceCreateActionsButton(
                    ref: ref,
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FinanceStatusActionsButton extends StatelessWidget {
  final WidgetRef ref;
  final bool isMobile;

  const FinanceStatusActionsButton({
    super.key,
    required this.ref,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(navigationService);
    final path = nav.currentPath;

    return SideButtonsDashboardDropdown(
      icon: Icons.edit_note_rounded,
      text: 'Edit statuses'.tr,
      items: [
        SideButtonsDropdownItem(
          label: 'Manage Revenues statuses'.tr,
          icon: Icons.trending_up,
          onTap: () {
            ref.read(navigationService).pushNamedScreen(
              '$path/${Routes.statusPopRevenue}',
              data: {'isFilter': false},
            );
          },
        ),
        SideButtonsDropdownItem(
          label: 'Manage Expenses statuses'.tr,
          icon: Icons.trending_down,
          onTap: () {
            ref.read(navigationService).pushNamedScreen(
              '$path/${Routes.statusPopExpenses}',
              data: {'isFilter': false},
            );
          },
        ),
      ],
    );
  }
}

class FinanceFilterActionsButton extends StatelessWidget {
  final WidgetRef ref;
  final bool isMobile;

  const FinanceFilterActionsButton({
    super.key,
    required this.ref,
    this.isMobile = false,
  });

  Future<void> _openFilters(BuildContext context, FinanceTxType type) async {
    final isMobilePopup = MediaQuery.of(context).size.width < 600;

    await PopPageManager.show(
      context,
      tag: type == FinanceTxType.revenue
          ? 'finance-filters-revenue'
          : 'finance-filters-expense',
      child: FinanceFiltersPopup(type: type),
      isBig: false,
      shouldBeADrawer: isMobilePopup,
      autoHeight: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SideButtonsDashboardDropdown(
      icon: Icons.filter_alt_rounded,
      text: 'Filters'.tr,
      items: [
        SideButtonsDropdownItem(
          label: 'Revenues filters'.tr,
          icon: Icons.trending_up,
          onTap: () => _openFilters(context, FinanceTxType.revenue),
        ),
        SideButtonsDropdownItem(
          label: 'Expenses filters'.tr,
          icon: Icons.trending_down,
          onTap: () => _openFilters(context, FinanceTxType.expense),
        ),
      ],
    );
  }
}

class FinanceCreateActionsButton extends StatelessWidget {
  final WidgetRef ref;
  final bool isMobile;

  const FinanceCreateActionsButton({
    super.key,
    required this.ref,
    this.isMobile = false,
  });

  Future<void> _openInvoiceForm(BuildContext context) async {
    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.95,
              child: AddInvoiceScreen(isMobile: true),
            ),
          );
        },
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.875,
            height: MediaQuery.of(context).size.height * 0.875,
            child: AddInvoiceScreen(isMobile: false),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SideButtonsDashboardDropdown(
      icon: Icons.add_rounded,
      text: 'Add'.tr,
      items: [
        SideButtonsDropdownItem(
          label: 'Add revenues'.tr,
          icon: Icons.trending_up,
          onTap: () => _openInvoiceForm(context),
        ),
        SideButtonsDropdownItem(
          label: 'Add expenses'.tr,
          icon: Icons.trending_down,
          onTap: () => _openInvoiceForm(context),
        ),
        SideButtonsDropdownItem(
          label: 'Invoice generator'.tr,
          icon: Icons.receipt_long_rounded,
          onTap: () {
            ref.read(navigationService).pushNamedScreen(
              Routes.invoiceGenerator,
            );
          },
        ),
        SideButtonsDropdownItem(
          label: 'Invoice items'.tr,
          icon: Icons.list_alt_rounded,
          onTap: () {
            ref.read(navigationService).pushNamedScreen(
              Routes.invoiceItems,
            );
          },
        ),
        SideButtonsDropdownItem(
          label: 'Invoice template list'.tr,
          icon: Icons.description_outlined,
          onTap: () {
            ref.read(navigationService).pushNamedScreen(
              Routes.invoiceTemplateList,
            );
          },
        ),
      ],
    );
  }
}





class FinanceCompanyScopeButton extends ConsumerStatefulWidget {
  final bool isMobile;

  /// Optional: prefer this id at start (if exists in chosen scope).
  final int? initialCompanyId;

  /// Optional: prefer this scope kind at start.
  final FinanceScopeKind? initialScopeKind;

  const FinanceCompanyScopeButton({
    super.key,
    this.isMobile = false,
    this.initialCompanyId,
    this.initialScopeKind,
  });

  @override
  ConsumerState<FinanceCompanyScopeButton> createState() =>
      _FinanceCompanyScopeButtonState();
}

class _FinanceCompanyScopeButtonState
    extends ConsumerState<FinanceCompanyScopeButton> {
  bool _didInit = false;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize once when user profile arrives.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.listen<UserModel?>(
        userStateProvider,
        (prev, next) {
          if (_didInit) return;
          if (next == null) return;

          final companies = next.company;
          final associations = next.associations;

          // If already set externally (e.g. route), do nothing.
          final currentId = ref.read(financeCompanyIdProvider);
          if (currentId != null) {
            _didInit = true;
            return;
          }

          // Choose initial scope kind.
          FinanceScopeKind kind =
              widget.initialScopeKind ?? FinanceScopeKind.company;

          // Fallback if chosen list empty.
          if (kind == FinanceScopeKind.company &&
              companies.isEmpty &&
              associations.isNotEmpty) {
            kind = FinanceScopeKind.association;
          }
          if (kind == FinanceScopeKind.association &&
              associations.isEmpty &&
              companies.isNotEmpty) {
            kind = FinanceScopeKind.company;
          }

          ref.read(financeScopeKindProvider.notifier).state = kind;

          final list = kind == FinanceScopeKind.association
              ? associations
              : companies;

          if (list.isEmpty) {
            _didInit = true;
            return;
          }

          final initId = widget.initialCompanyId;
          final selectedId = (initId != null && list.any((c) => c.id == initId))
              ? initId
              : list.first.id;

          ref.read(financeCompanyIdProvider.notifier).state = selectedId;

          // Refresh lists depending on scope.
          ref.invalidate(unifiedTransactionsProvider);
          ref.invalidate(upcomingUnpaidTransactionsProvider);

          _didInit = true;
        },
      );
    });
  }

  void _applySelection({
    required FinanceScopeKind kind,
    required int companyId,
  }) {
    ref.read(financeScopeKindProvider.notifier).state = kind;
    ref.read(financeCompanyIdProvider.notifier).state = companyId;

    ref.invalidate(unifiedTransactionsProvider);
    ref.invalidate(upcomingUnpaidTransactionsProvider);
  }

  void _switchKind(FinanceScopeKind kind, List<CompanyModel> listForKind) {
    ref.read(financeScopeKindProvider.notifier).state = kind;

    final currentId = ref.read(financeCompanyIdProvider);

    // Keep id if still valid in this list, otherwise take first.
    if (currentId != null && listForKind.any((c) => c.id == currentId)) {
      // ok
    } else {
      final nextId = listForKind.isNotEmpty ? listForKind.first.id : null;
      ref.read(financeCompanyIdProvider.notifier).state = nextId;
    }

    ref.invalidate(unifiedTransactionsProvider);
    ref.invalidate(upcomingUnpaidTransactionsProvider);
  }

  Widget _companyAvatar(CompanyModel c, {double size = 22}) {
    final url = c.companyLogo;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(size),
        ),
      );
    }
    return _fallbackAvatar(size);
  }

  Widget _fallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(size),
      ),
      child: Icon(Icons.business, size: size * 0.7),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final theme = ref.read(themeColorsProvider);

    // We need BOTH lists to allow switching between tabs inside picker.
    final user = ref.read(userStateProvider);
    final companies = user?.company ?? const <CompanyModel>[];
    final associations = user?.associations ?? const <CompanyModel>[];

    FinanceScopeKind kind = ref.read(financeScopeKindProvider);
    List<CompanyModel> listForKind =
        kind == FinanceScopeKind.association ? associations : companies;

    Future<void> showPicker(Widget child) async {
      if (widget.isMobile) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.dashboardContainer,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => child,
        );
      } else {
        await showDialog(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          ),
        );
      }
    }

    await showPicker(
      StatefulBuilder(
        builder: (ctx, setLocalState) {
          void setKind(FinanceScopeKind nextKind) {
            kind = nextKind;
            listForKind =
                kind == FinanceScopeKind.association ? associations : companies;

            // Update global providers (scope kind + fallback id)
            _switchKind(kind, listForKind);

            setLocalState(() {});
          }

          return Container(
            width: 420,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select scope'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // // ✅ tabs: Companies / Associations
                // SegmentedButton<FinanceScopeKind>(
                //   segments: <ButtonSegment<FinanceScopeKind>>[
                //     ButtonSegment(
                //       value: FinanceScopeKind.company,
                //       label: Text('Companies'.tr),
                //       icon: const Icon(Icons.apartment),
                //     ),
                //     ButtonSegment(
                //       value: FinanceScopeKind.association,
                //       label: Text('Associations'.tr),
                //       icon: const Icon(Icons.groups),
                //     ),
                //   ],
                //   selected: {kind},
                //   showSelectedIcon: false,
                //   onSelectionChanged: (v) {
                //     final nextKind = v.first;
                //     setKind(nextKind);
                //   },
                // ),

                // const SizedBox(height: 12),

                if (listForKind.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      kind == FinanceScopeKind.association
                          ? 'No associations available'.tr
                          : 'No companies available'.tr,
                      style: TextStyle(color: theme.textColor.withAlpha(160)),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: listForKind.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: theme.textColor.withAlpha(30)),
                      itemBuilder: (_, i) {
                        final c = listForKind[i];
                        return ListTile(
                          leading: _companyAvatar(c, size: 28),
                          title: Text(
                            c.companyName ?? '-',
                            style: TextStyle(color: theme.textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            kind == FinanceScopeKind.association
                                ? 'Association'.tr
                                : 'Company'.tr,
                            style: TextStyle(
                              color: theme.textColor.withAlpha(130),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            _applySelection(kind: kind, companyId: c.id);
                            Navigator.of(ctx).maybePop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final kind = ref.watch(financeScopeKindProvider);
    final selected = ref.watch(financeSelectedCompanyProvider);

    final label = selected?.companyName ??
        (kind == FinanceScopeKind.association
            ? 'Choose association'.tr
            : 'Choose company'.tr);

    return SizedBox(
      height: 45,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: () => _openPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              kind == FinanceScopeKind.association
                  ? Icons.groups
                  : Icons.apartment,
              color: theme.textColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            if (selected != null) ...[
              _companyAvatar(selected, size: 22),
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                style: TextStyle(color: theme.textColor, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: theme.textColor),
          ],
        ),
      ),
    );
  }
}
