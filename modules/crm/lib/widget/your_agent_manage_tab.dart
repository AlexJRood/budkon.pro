import 'package:core/theme/text_field.dart';
import 'package:crm/your_agent/models.dart';
import 'package:crm/your_agent/agent/agent_providers.dart';
import 'package:crm/your_agent/tabs/docs_tab.dart';
import 'package:crm/your_agent/tabs/listing_tab.dart';
import 'package:crm/your_agent/tabs/status_tab.dart';
import 'package:crm/your_agent/tabs/tab.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class YourAgentManageTab extends ConsumerStatefulWidget {
  final AgentTransactionModel transaction;
  final bool isMobile;

  const YourAgentManageTab({
    super.key,
    required this.transaction,
    required this.isMobile,
  });

  @override
  ConsumerState<YourAgentManageTab> createState() => _YourAgentManageTabState();
}

class _YourAgentManageTabState extends ConsumerState<YourAgentManageTab> {
  int _currentSection = 0;

  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _visibleUntilController;

  bool _isEnabled = true;
  bool _canEditListing = true;
  bool _canViewDocuments = true;
  bool _canViewPresentations = true;
  bool _isReadOnly = false;

  bool _isSaving = false;
  bool _isInviteBusy = false;
  int? _reviewingSuggestionId;

  String _syncKey = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _visibleUntilController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _visibleUntilController.dispose();
    super.dispose();
  }

  void _syncForm(AgentPortalManageResponse data) {
    final nextKey = [
      data.hasPortal,
      data.portalUuid,
      data.invitedEmail,
      data.invitedPhone,
      data.visibleUntil,
      data.minVisibleUntil,
      data.isEnabled,
      data.canEditListing,
      data.canViewDocuments,
      data.canViewPresentations,
      data.isReadOnly,
    ].join('|');

    if (_syncKey == nextKey) return;
    _syncKey = nextKey;

    _emailController.text = data.invitedEmail ?? '';
    _phoneController.text = data.invitedPhone ?? '';
    _visibleUntilController.text = data.visibleUntil ?? '';

    _isEnabled = data.isEnabled;
    _canEditListing = data.canEditListing;
    _canViewDocuments = data.canViewDocuments;
    _canViewPresentations = data.canViewPresentations;
    _isReadOnly = data.isReadOnly;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return DateTime.parse(value.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickVisibleUntil(AgentPortalManageResponse data) async {
    final now = DateTime.now();
    final minDate = _parseDate(data.minVisibleUntil) ?? now;
    final currentValue = _parseDate(_visibleUntilController.text);
    final initialDate =
        (currentValue != null && !currentValue.isBefore(minDate))
            ? currentValue
            : minDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime(minDate.year + 10, 12, 31),
      helpText: 'select_visibility_date'.tr,
      cancelText: 'cancel_button'.tr,
      confirmText: 'select_button'.tr,
    );

    if (picked == null || !mounted) return;

    final yyyy = picked.year.toString().padLeft(4, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');

    setState(() {
      _visibleUntilController.text = '$yyyy-$mm-$dd';
    });
  }

  String _formatSuggestionValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'yes_label'.tr : 'no_label'.tr;
    if (value is List) return value.map((e) => e.toString()).join(', ');
    return value.toString();
  }

  Future<void> _save(AgentPortalManageResponse data) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(agentPortalActionsProvider).savePortal(
        transactionId: widget.transaction.id,
        exists: data.hasPortal,
        payload: {
          'invited_email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          'invited_phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'is_enabled': _isEnabled,
          'can_edit_listing': _canEditListing,
          'can_view_documents': _canViewDocuments,
          'can_view_presentations': _canViewPresentations,
          'is_read_only': _isReadOnly,
          'visible_until': _visibleUntilController.text.trim().isEmpty
              ? null
              : _visibleUntilController.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('your_agent_settings_saved'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_saving_settings'.tr} $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resendInvite({required bool regenerateInvite}) async {
    if (_isInviteBusy) return;

    setState(() => _isInviteBusy = true);
    try {
      await ref.read(agentPortalActionsProvider).resendInvite(
            transactionId: widget.transaction.id,
            regenerateInvite: regenerateInvite,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            regenerateInvite
                ? 'new_link_generated_and_invite_sent'.tr
                : 'invite_resent_message'.tr,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_sending_invite'.tr} $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isInviteBusy = false);
      }
    }
  }

  Future<void> _reviewSuggestion(
    AgentPortalSuggestionModel suggestion,
    String action, {
    String? reviewNote,
  }) async {
    setState(() => _reviewingSuggestionId = suggestion.id);

    try {
      await ref.read(agentPortalActionsProvider).reviewSuggestion(
            transactionId: widget.transaction.id,
            suggestionId: suggestion.id,
            action: action,
            reviewNote: reviewNote,
          );

      ref.invalidate(agentPortalSuggestionsProvider(widget.transaction.id));
      ref.invalidate(agentPortalManageProvider(widget.transaction.id));
      ref.invalidate(agentPortalPreviewProvider(widget.transaction.id));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept'
                ? 'suggestion_accepted_message'.tr
                : 'suggestion_rejected_message'.tr
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_prefix'.tr} $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _reviewingSuggestionId = null);
      }
    }
  }

  Future<void> _askRejectReason(AgentPortalSuggestionModel suggestion) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        final theme = ref.watch(themeColorsProvider);

        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          title: Text(
            'reject_suggestion_title'.tr,
            style: TextStyle(color: theme.textColor),
          ),
          content: SizedBox(
            width: 420,
            child: CoreTextField(
              label: 'reason_note_optional_label'.tr,
              controller: controller,
              maxLines: 4,
              minLines: 4,
            ),
          ),
          actions: [
            CoreOutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr),
            ),
            CoreFilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('reject_button'.tr),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await _reviewSuggestion(
      suggestion,
      'reject',
      reviewNote: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final manageAsync =
        ref.watch(agentPortalManageProvider(widget.transaction.id));

    return manageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${'error_loading_your_agent_panel'.tr} $e'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      ),
      data: (data) {
        _syncForm(data);

        final sectionLabels = [
          'settings_tab'.tr,
          'client_preview_tab'.tr,
          '${'approvals_tab'.tr} (${data.pendingSuggestionsCount})'.tr,
          'status_tab'.tr
        ];

        return Padding(
          padding: EdgeInsets.all(widget.isMobile ? 10 : 16),
          child: widget.isMobile
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TopStatusCard(
                        data: data,
                        transaction: widget.transaction,
                        isMobile: widget.isMobile,
                        onCopyInvite: data.inviteUrl == null
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: data.inviteUrl!),
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('link_copied_message'.tr),
                                  ),
                                );
                              },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: ClientPortalTabs(
                        tabs: sectionLabels,
                        currentIndex: _currentSection,
                        onChanged: (i) => setState(() => _currentSection = i),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: IndexedStack(
                        index: _currentSection,
                        children: [
                          _buildSettingsSection(theme, data),
                          _buildPreviewSection(theme, data),
                          _buildApprovalsSection(theme),
                          _buildStatusSection(theme, data),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopStatusCard(
                      data: data,
                      transaction: widget.transaction,
                      isMobile: widget.isMobile,
                      onCopyInvite: data.inviteUrl == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: data.inviteUrl!),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('link_copied_message'.tr),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 12),
                    ClientPortalTabs(
                      tabs: sectionLabels,
                      currentIndex: _currentSection,
                      onChanged: (i) => setState(() => _currentSection = i),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: IndexedStack(
                        index: _currentSection,
                        children: [
                          _buildSettingsSection(theme, data),
                          _buildPreviewSection(theme, data),
                          _buildApprovalsSection(theme),
                          _buildStatusSection(theme, data),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSettingsSection(
    ThemeColors theme,
    AgentPortalManageResponse data,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.hasPortal
                      ? 'client_access_management_title'.tr
                      : 'create_client_portal_button'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                CoreTextField(
                  label: 'invitation_email_label'.tr,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'np. klient@email.com',
                ),
                const SizedBox(height: 12),
                CoreTextField(
                  label: 'invitation_phone_label'.tr,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: 'np. +48 123 456 789',
                ),
                const SizedBox(height: 12),
                CoreTextField(
                  label: 'visible_until_label'.tr,
                  controller: _visibleUntilController,
                  readOnly: true,
                  onTap: () => _pickVisibleUntil(data),
                  hintText: 'YYYY-MM-DD',
                  helperText: data.minVisibleUntil == null
                      ? null
                      : '${'minimum_label'.tr}: ${data.minVisibleUntil}',
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'permissions_and_status_title'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v),
                  title: Text(
                    'portal_active_label'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _canEditListing,
                  onChanged: (v) => setState(() => _canEditListing = v),
                  title: Text(
                    'client_can_suggest_listing_changes'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _canViewDocuments,
                  onChanged: (v) => setState(() => _canViewDocuments = v),
                  title: Text(
                    'client_can_view_documents'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _canViewPresentations,
                  onChanged: (v) => setState(() => _canViewPresentations = v),
                  title: Text(
                    'client_can_view_presentations'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _isReadOnly,
                  onChanged: (v) => setState(() => _isReadOnly = v),
                  title: Text(
                    'read_only_mode_label'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                CoreFilledButton(
                  onPressed: _isSaving ? null : () => _save(data),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSaving) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Icon(Icons.save_outlined, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        data.hasPortal
                            ? 'save_changes_button'.tr
                            : 'create_portal_button'.tr,
                      ),
                    ],
                  ),
                ),
                CoreOutlinedButton(
                  onPressed: (!data.hasPortal || _isInviteBusy)
                      ? null
                      : () => _resendInvite(regenerateInvite: false),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isInviteBusy) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Icon(Icons.send_outlined, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text('resend_button'.tr),
                    ],
                  ),
                ),
                CoreOutlinedButton(
                  onPressed: (!data.hasPortal || _isInviteBusy)
                      ? null
                      : () => _resendInvite(regenerateInvite: true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('new_link_button'.tr),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (data.inviteUrl != null) ...[
            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'client_portal_link_title'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dashboardBoarder),
                    ),
                    child: SelectableText(
                      data.inviteUrl!,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSection(
    ThemeColors theme,
    AgentPortalManageResponse data,
  ) {
    if (!data.hasPortal) {
      return Center(
        child: Text(
          'create_portal_first_to_preview'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    final previewAsync =
        ref.watch(agentPortalPreviewProvider(widget.transaction.id));

    return previewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${'error_loading_preview'.tr} $e'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      ),
      data: (detail) => _AgentClientPreviewPanel(
        detail: detail,
        isMobile: widget.isMobile,
      ),
    );
  }


Widget _buildStatusSection(
  ThemeColors theme,
  AgentPortalManageResponse data,
) {
  if (!data.hasPortal) {
    return Center(
      child: Text(
        'create_portal_first_to_see_status'.tr,
        style: TextStyle(color: theme.textColor),
      ),
    );
  }

  return YourAgentStatusTab(
    transactionId: widget.transaction.id,
  );
}


  Widget _buildApprovalsSection(ThemeColors theme) {
    final suggestionsAsync =
        ref.watch(agentPortalSuggestionsProvider(widget.transaction.id));

    return suggestionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${'error_loading_suggestions'.tr} $e'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      ),
      data: (suggestions) {
        debugPrint(
          '🟣 UI suggestions tx=${widget.transaction.id}: ${suggestions.length}',
        );

        final sortedSuggestions = [...suggestions]
          ..sort((a, b) {
            final aPending = a.status == 'pending' ? 0 : 1;
            final bPending = b.status == 'pending' ? 0 : 1;
            if (aPending != bPending) return aPending.compareTo(bPending);
            return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
          });

        if (sortedSuggestions.isEmpty) {
          return Center(
            child: Text(
              'no_suggestions_to_approve'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          );
        }

        return ListView.separated(
          itemCount: sortedSuggestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final suggestion = sortedSuggestions[index];
            final busy = _reviewingSuggestionId == suggestion.id;

            return _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion.clientName ??
                              suggestion.createdByName ??
                              'client_suggestion_default_title'.tr,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _StatusPill(
                        text: suggestion.status,
                        active: suggestion.status == 'pending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (suggestion.transactionName != null)
                    Text(
                      suggestion.transactionName!,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(180),
                        fontSize: 13,
                      ),
                    ),
                  if (suggestion.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      suggestion.createdAt!,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(150),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (suggestion.diffItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.dashboardContainer.withAlpha(115),
                        border: Border.all(color: theme.dashboardBoarder),
                      ),
                      child: Text(
                        'suggestion_no_diff_data_message'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    )
                  else
                    ...suggestion.diffItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.dashboardContainer.withAlpha(115),
                            border: Border.all(color: theme.dashboardBoarder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${'old_value_prefix'.tr} ${_formatSuggestionValue(item.oldValue)}',
                                style: TextStyle(
                                  color: theme.textColor.withAlpha(190),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${'new_value_prefix'.tr} ${_formatSuggestionValue(item.newValue)}',
                                style: TextStyle(color: theme.textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (suggestion.reviewNote != null &&
                      suggestion.reviewNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${'note_label'.tr}: ${suggestion.reviewNote}',
                      style: TextStyle(
                        color: theme.textColor.withAlpha(210),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (suggestion.status == 'pending') ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        CoreFilledButton(
                          onPressed: busy
                              ? null
                              : () => _reviewSuggestion(suggestion, 'accept'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (busy) ...[
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text('accept_button'.tr),
                            ],
                          ),
                        ),
                        CoreOutlinedButton(
                          onPressed: busy
                              ? null
                              : () => _askRejectReason(suggestion),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.close_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text('reject_button'.tr),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TopStatusCard extends ConsumerWidget {
  final AgentPortalManageResponse data;
  final AgentTransactionModel transaction;
  final bool isMobile;
  final VoidCallback? onCopyInvite;

  const _TopStatusCard({
    required this.data,
    required this.transaction,
    required this.isMobile,
    required this.onCopyInvite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Wrap(
        runSpacing: 10,
        spacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'your_agent_title'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.name ??
                    transaction.transactionName ??
                    'Transakcja #${transaction.id}',
                style: TextStyle(
                  color: theme.textColor.withAlpha(190),
                ),
              ),
            ],
          ),
          _StatusPill(
            text: data.hasPortal ? 'portal_created_status'.tr : 'no_portal_status'.tr,
            active: data.hasPortal,
          ),
          _StatusPill(
            text: data.isEnabled ? 'active_status'.tr : 'disabled_status'.tr,
            active: data.isEnabled,
          ),
          _StatusPill(
            text: data.isBound ? 'linked_to_user_status'.tr : 'unlinked_status'.tr,
            active: data.isBound,
          ),
          _StatusPill(
            text: '${'pending_status'.tr}: ${data.pendingSuggestionsCount}',
            active: data.pendingSuggestionsCount > 0,
          ),
          if (onCopyInvite != null)
            CoreOutlinedButton(
              onPressed: onCopyInvite,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.content_copy_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('copy_link_button'.tr),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends ConsumerWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.textColor.withAlpha(20),
        ),
      ),
      child: child,
    );
  }
}

class _StatusPill extends ConsumerWidget {
  final String text;
  final bool active;

  const _StatusPill({
    required this.text,
    required this.active,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? theme.themeColor.withAlpha(36)
            : theme.dashboardContainer,
        border: Border.all(
          color: active ? theme.themeColor : theme.dashboardBoarder,
        ),
      ),
      child: Text(
        text.tr,
        style: TextStyle(
          color: active ? theme.themeColor : theme.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AgentClientPreviewPanel extends ConsumerStatefulWidget {
  final ClientPortalCaseDetail detail;
  final bool isMobile;

  const _AgentClientPreviewPanel({
    required this.detail,
    required this.isMobile,
  });

  @override
  ConsumerState<_AgentClientPreviewPanel> createState() =>
      _AgentClientPreviewPanelState();
}

class _AgentClientPreviewPanelState
    extends ConsumerState<_AgentClientPreviewPanel> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    final detail = widget.detail;
    final isSeller = detail.isSeller;
    final canViewDocs = detail.canViewDocuments;
    final canViewPres = detail.canViewPresentations;
    final hasDocs = detail.documents.isNotEmpty;

    final portalUuid = detail.portal['uuid']?.toString() ?? '';

    final List<_PreviewTabConfig> tabs = [];

    if (isSeller) {
      tabs.add(
        _PreviewTabConfig(
          label: 'advertisement'.tr,
          builder: () => ListingTab(
            portalId: portalUuid,
            listing: detail.listing,
            transaction: detail.transaction,
            canEdit: false,
          ),
        ),
      );

      if (canViewPres) {
        tabs.add(
          _PreviewTabConfig(
            label: 'presentations_label'.tr,
            builder: () => _PreviewPresentationsTab(
              presentations:
                  (detail.transaction['presentations'] as List?) ?? const [],
            ),
          ),
        );
      }

      if (canViewDocs && hasDocs) {
        tabs.add(
          _PreviewTabConfig(
            label: 'Documents'.tr,
            builder: () => DocumentsTab(documents: detail.documents),
          ),
        );
      }
    } else {
      tabs.add(
        _PreviewTabConfig(
          label: 'proposals_preview_tab'.tr,
          builder: () => Center(
            child: Text(
              'proposals_preview_tab'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ),
      );

      tabs.add(
        _PreviewTabConfig(
          label: 'statuses_preview_tab'.tr,
          builder: () => Center(
            child: Text(
              'statuses_preview_tab'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ),
      );

      if (canViewDocs && hasDocs) {
        tabs.add(
          _PreviewTabConfig(
            label: 'Documents'.tr,
            builder: () => DocumentsTab(documents: detail.documents),
          ),
        );
      }
    }

    if (tabs.isEmpty) {
      return Center(
        child: Text(
          'no_preview_data_message'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    if (_currentTab >= tabs.length) {
      _currentTab = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.themeColor.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.themeColor.withAlpha(60),
            ),
          ),
          child: Text(
            'client_preview_disabled_message'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClientPortalTabs(
          tabs: tabs.map((e) => e.label).toList(),
          currentIndex: _currentTab,
          onChanged: (i) => setState(() => _currentTab = i),
        ),
        const SizedBox(height: 12),
        Expanded(child: tabs[_currentTab].builder()),
      ],
    );
  }
}

class _PreviewTabConfig {
  final String label;
  final Widget Function() builder;

  const _PreviewTabConfig({
    required this.label,
    required this.builder,
  });
}

class _PreviewPresentationsTab extends ConsumerWidget {
  final List<dynamic> presentations;

  const _PreviewPresentationsTab({
    required this.presentations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    if (presentations.isEmpty) {
      return Center(
        child: Text(
          'no_presentations_message'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: presentations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = presentations[i] is Map
            ? (presentations[i] as Map).cast<String, dynamic>()
            : <String, dynamic>{};

        final status = item['status_label']?.toString() ?? 'no_status_label'.tr;
        final lastContact = item['last_contact_at']?.toString();
        final events = (item['events'] as List?) ?? const [];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.dashboardContainer,
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (lastContact != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${'last_contact_label'.tr}: $lastContact',
                  style: TextStyle(color: theme.textColor),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '${'events_count_label'.tr}: ${events.length}',
                style: TextStyle(
                  color: theme.textColor.withAlpha(190),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}