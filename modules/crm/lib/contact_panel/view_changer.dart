import 'package:crm/shared/models/clients_model.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:cloud/explorer.dart';
import 'package:cloud/models/query_params.dart';
import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:crm/contact_panel/data/invoice_data_provider.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_clientview_content.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_clientview_content_mobile.dart';
import 'package:crm/contact_panel/tabs/edit_contact/contact_detail_view_widget.dart';
import 'package:crm/contact_panel/tabs/invoices/tab.dart';
import 'package:crm/contact_panel/tabs/member_calendar/member_calendar_panel.dart';
import 'package:crm/contact_panel/tabs/member_cloud/member_cloud_panel.dart';
import 'package:crm/contact_panel/tabs/member_tms/member_tms_panel.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/saved_seaches_list.dart';
import 'package:crm/contact_panel/tabs/transactions/transactions_section.dart';
import 'package:crm/contact_panel/tabs/transactions/transactions_section_mobile.dart';
import 'package:crm/crm/finance/features/transactions/columns_transactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mail/components/mail_list.dart';
import 'package:mail/components/mail_list_mobile.dart';

import 'package:crm/contact_panel/tabs/employee_settlements/employee_settlement_dashboard.dart';
import 'tabs/comments/comment_section_pc.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_clientview_content_tablet.dart';

class ClientViewContent extends ConsumerStatefulWidget {
  final String activeSection;
  final UserContactModel clientViewPop;
  final String activeAd;
  final String? openTransaction;
  final bool isMobile;
  final ContactType contactType;
  final bool isTablet;

  const ClientViewContent({
    super.key,
    this.isMobile = false,
    this.contactType = ContactType.client,
    this.isTablet = false,
    required this.activeSection,
    required this.clientViewPop,
    required this.activeAd,
    required this.openTransaction,
  });

  @override
  ConsumerState<ClientViewContent> createState() => _ClientViewContentState();
}

class _ClientViewContentState extends ConsumerState<ClientViewContent> {
  bool get _isCrmUser => widget.contactType == ContactType.crmUser;

  bool get _canUseClientFinancialSections => !_isCrmUser;

  int get _contactId {
    final rawId = widget.clientViewPop.id;

    if (rawId is int) {
      return rawId;
    }

    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  String get _contactIdString => _contactId.toString();

  String? get _contactEmail {
    final email = widget.clientViewPop.email;
    if (email == null) return null;

    final emailString = email.toString().trim();
    if (emailString.isEmpty) return null;

    return emailString;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchForCurrentContact();
    });
  }

  @override
  void didUpdateWidget(covariant ClientViewContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.clientViewPop.id?.toString();
    final newId = widget.clientViewPop.id?.toString();

    final idChanged = oldId != newId;
    final typeChanged = oldWidget.contactType != widget.contactType;

    if ((idChanged || typeChanged) && newId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchForCurrentContact();
      });
    }
  }

  void _fetchForCurrentContact() {
    if (!mounted) return;

    // crm-user nie jest klasycznym klientem, więc nie ładujemy tutaj faktur
    // ani danych invoice powiązanych z UserContact.
    if (!_canUseClientFinancialSections) {
      return;
    }

    ref.read(activeContactProvider.notifier).fetchUserContactData(_contactIdString);
  }

  FolderQueryParams _buildFolderQueryParams() {
    if (_isCrmUser) {
      return FolderQueryParams(
        appLabel: 'user',
        model: 'user',
        objectId: _contactIdString,
        additionalSection: 'crm-user',
      );
    }

    return FolderQueryParams(
      appLabel: 'user_contacts',
      model: 'usercontact',
      objectId: _contactIdString,
      additionalSection: 'assigned',
    );
  }

  Widget _buildDashboard() {
    return Expanded(
      child: ClientDashboardSection(
        clientViewPop: widget.clientViewPop,
        contactType: widget.contactType,
      ),
    );
  }

  Widget _buildComments() {
    return Expanded(
      child: CommentSectionPc(
        id: _contactId,
        isMobile: widget.isMobile,
      ),
    );
  }

  Widget _buildCrmUserSettlements() {
    return EmployeeSettlementDashboardPage(
      employeeId: _contactId,
      isMobile: widget.isMobile,
    );
  }

  Widget _buildTransactions() {
    if (!_canUseClientFinancialSections) {
      return _buildUnavailableSection(
        title: 'Transactions'.tr,
        message: 'transactions_only_for_client'.tr,
      );
    }

    final isFromFinanceDraggable = ref.watch(
      isNavigateFromFinanceDraggableProvider,
    );

    final activeAd = isFromFinanceDraggable.triggered
        ? isFromFinanceDraggable.id.toString()
        : widget.activeAd;

    if (widget.isMobile) {
      return Expanded(
        child: TransactionSectionMobile(
          id: _contactId,
          activeSection: widget.activeSection,
          selectedTransactionId: widget.openTransaction,
          activeAd: activeAd,
        ),
      );
    }

    return Expanded(
      child: TransactionSectionPc(
        isMobile: widget.isMobile,
        id: _contactId,
        activeSection: widget.activeSection,
        selectedTransactionId: widget.openTransaction,
        activeAd: activeAd,
      ),
    );
  }

  Widget _buildDocs() {
    final topPadding = widget.isMobile ? TopAppBarSize.resolve(context) + 10 : 0.0;

    final bottomPadding = widget.isMobile
        ? BottomBarSize.resolve(context) + 10
        : 0.0;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: topPadding,
          bottom: bottomPadding,
        ),
        child: _isCrmUser
            ? MemberCloudPanel(
                memberId: _contactId,
                isMobile: widget.isMobile,
              )
            : CloudExplorer(
                isMobile: widget.isMobile,
                isClient: true,
                params: _buildFolderQueryParams(),
              ),
      ),
    );
  }

  Widget _buildEditContact() {
    if (!widget.isMobile) {
      return const Expanded(
        child: ContactDetailViewWidget(),
      );
    }

    return const Expanded(
      child: ContactDetailViewWidget(),
    );
  }

  Widget _buildMail() {
    final email = _contactEmail;

    if (widget.isMobile) {
      return Expanded(
        child: EmailListWithPreviewMobile(
          isMobile: true,
          email: email,
          lead: widget.clientViewPop,
        ),
      );
    }

    return Expanded(
      child: EmailListWithPreview(
        email: email,
        lead: widget.clientViewPop,
        enableBulkSelection: false,
      ),
    );
  }

  Widget _buildSavedSearches() {
    if (!_canUseClientFinancialSections) {
      return _buildUnavailableSection(
        title: 'saved_searches_title'.tr,
        message: 'saved_searches_only_for_client'.tr,
      );
    }

    return Expanded(
      child: SaveSearchByClientListViewWidget(
        clientId: _contactId,
      ),
    );
  }

  Widget _buildInvoices() {
    if (!_canUseClientFinancialSections) {
      return _buildUnavailableSection(
        title: 'Bills'.tr,
        message: 'invoices_only_for_client'.tr,
      );
    }

    return Expanded(
      child: ClientInvoicesPage(
        clientId: _contactId,
        isMobile: widget.isMobile,
      ),
    );
  }

  Widget _buildCrmUserTasks() {
    if (_contactId <= 0) {
      return _buildUnavailableSection(
        title: 'tasks_title'.tr,
        message: 'section_unavailable_message'.tr,
      );
    }

    return Expanded(
      child: MemberTmsPanel(
        memberId: _contactId,
        isMobile: widget.isMobile,
      ),
    );
  }

  Widget _buildCrmUserCalendar() {
    if (_contactId <= 0) {
      return _buildUnavailableSection(
        title: 'member_calendar_title'.tr,
        message: 'section_unavailable_message'.tr,
      );
    }

    return Expanded(
      child: MemberCalendarPanel(
        memberId: _contactId,
        isMobile: widget.isMobile,
      ),
    );
  }

  Widget _buildPlaceholderSection({
    required String title,
    required String message,
  }) {
    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  message.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableSection({
    required String title,
    required String message,
  }) {
    return _buildPlaceholderSection(
      title: title,
      message: message,
    );
  }

  Widget _buildUnknownSection() {
    return _buildPlaceholderSection(
      title: 'section_unavailable_title'.tr,
      message: 'section_unavailable_message'.tr,
    );
  }

  Widget _buildSection() {
    return switch (ContactPanelSection.fromRoute(widget.activeSection)) {
      ContactPanelSection.dashboard    => _buildDashboard(),
      ContactPanelSection.settlements  => _isCrmUser ? _buildCrmUserSettlements() : _buildUnknownSection(),
      ContactPanelSection.comments     => _buildComments(),
      ContactPanelSection.transactions => _buildTransactions(),
      ContactPanelSection.docs         => _buildDocs(),
      ContactPanelSection.editContact  => _buildEditContact(),
      ContactPanelSection.mail         => _buildMail(),
      ContactPanelSection.savedSearches => _buildSavedSearches(),
      ContactPanelSection.invoices     => _buildInvoices(),
      ContactPanelSection.tasks        => _isCrmUser ? _buildCrmUserTasks() : _buildUnknownSection(),
      ContactPanelSection.calendar     => _isCrmUser ? _buildCrmUserCalendar() : _buildUnknownSection(),
      ContactPanelSection.unknown      => _buildUnknownSection(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final section = _buildSection();

    // if (!widget.isMobile) {
    //   return Column(
    //     children: [
    //       section,
    //     ],
    //   );
    // }

    return Column(
      children: [
        // SizedBox(height: TopAppBarSize.resolve(context)),
        section,
        // SizedBox(height: BottomBarSize.resolve(context)),
      ],
    );
  }
}