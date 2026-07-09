import 'package:crm_agent/add_client_form/widgets/crm_form_mode_provider.dart';
import 'package:crm_agent/add_client_form/widgets/crm_form_mode_widgets.dart';
import 'package:crm_agent/add_client_form/widgets/crm_progress_indicator.dart';
import 'package:crm_agent/add_client_form/widgets/crm_quick_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:crm/data/clients/client_provider.dart';
import 'package:crm_agent/add_client_form/components/usercontact/add_user_contacts.dart';
import 'package:crm_agent/add_client_form/components/usercontact/contact_list.dart';
import 'package:crm_agent/add_client_form/controllers/buy_controlers.dart';
import 'package:crm_agent/add_client_form/controllers/sell_controlers.dart';
import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/widgets/get_selected_widget.dart';
import 'package:crm_agent/add_client_form/widgets/note_and_submit_mobile.dart';
import 'package:crm_agent/add_client_form/widgets/crm_tab_bar.dart';
import 'package:crm_agent/add_client_form/widgets/transaction_view_widget.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';

class AddClientFormMobile extends ConsumerStatefulWidget {
  final bool isClientView;
  final String? state;
  final ScrollController? sheetScrollController;
  const AddClientFormMobile({
    super.key,
    this.isClientView = false,
    this.sheetScrollController,
    this.state,
  });

  @override
  ConsumerState<AddClientFormMobile> createState() =>
      _AddClientFormMobileState();
}

class _AddClientFormMobileState extends ConsumerState<AddClientFormMobile> {
  final _viewFormKey = GlobalKey<FormState>();
  final _sellFormKey = GlobalKey<FormState>();
  final _buyFormKey = GlobalKey<FormState>();

  String? _resolveTabFromState(String? raw) {
    if (raw == null) return null;
    final v = raw.trim().toUpperCase();
    if (v == 'VIEW' || v == 'VIEWING') return 'VIEW'.tr;
    if (v == 'SELL' || v == 'SELLING') return 'SELL'.tr;
    if (v == 'BUY' || v == 'BUYING') return 'BUY'.tr;
    final candidates = {'VIEW'.tr, 'SELL'.tr, 'BUY'.tr};
    if (candidates.contains(raw)) return raw;
    return null;
  }

  @override
  void initState() {
    super.initState();
    final tab = _resolveTabFromState(widget.state);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tab != null) ref.read(selectedTabProvider.notifier).state = tab;
      crmResetProgress(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);
    final addClientProvider = ref.read(addClientFormProvider.notifier);
    final theme = ref.watch(themeColorsProvider);
    final stepsEnabled = ref.watch(crmFormStepsEnabledProvider);
    final progress = ref.watch(crmProgressProvider);
    final step = crmProgressToStep(progress);

    final stepLabels = selectedTab == 'SELL'.tr
        ? ['client'.tr, 'property'.tr, 'transaction'.tr]
        : ['client'.tr, selectedTab == 'VIEW'.tr ? 'event'.tr : 'details'.tr];

    bool isLastStep(int s) =>
        selectedTab == 'SELL'.tr ? s >= 2 : s >= 1;
    final showNextButton = stepsEnabled && !isLastStep(step);

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                // ── Fixed header (tab bar + optional progress indicator) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CrmTabBar(
                        selectedTab: selectedTab,
                        onTabSelected: (tab) {
                          ref.read(selectedTabProvider.notifier).state = tab;
                          crmResetProgress(ref);
                        },
                        theme: theme,
                      ),
                      if (stepsEnabled) ...[
                        const SizedBox(height: 12),
                        CrmProgressIndicatorWidget(stepLabels: stepLabels),
                      ],
                    ],
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    controller: widget.sheetScrollController,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        if (selectedTab == 'BUY'.tr)
                          Text('create_a_new_buy_transaction'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold))
                        else if (selectedTab == 'SELL'.tr)
                          Text('create_a_new_sell_transaction'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold))
                        else
                          Text('create_a_new_contact'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 8),

                        if (selectedTab == 'BUY'.tr || selectedTab == 'SELL'.tr)
                          Text('select_client_or_create_new'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 17))
                        else
                          Text('Enter client information and personalize their profile'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 17)),

                        const SizedBox(height: 20),

                        // Content
                        if (!stepsEnabled) ...[
                          _buildClientSection(),
                          const SizedBox(height: 20),
                          _buildDetailsSection(selectedTab),
                        ] else if (step == 0) ...[
                          _buildClientSection(),
                        ] else ...[
                          _buildQuickStepContent(selectedTab, step),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating bottom bar ──────────────────────────────────────
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: showNextButton
                ? SizedBox(
                    height: 45,
                    child: CrmStepNextButton(
                      theme: theme,
                      onNext: () =>
                          ref.read(crmProgressProvider.notifier).state += 1,
                    ),
                  )
                : NoteAndSubmitMobile(
                    selectedTab: selectedTab,
                    viewFormKey: _viewFormKey,
                    sellFormKey: _sellFormKey,
                    buyFormKey: _buyFormKey,
                    isMobile: true,
                    onSubmit: () async {
                      final nav = ref.read(navigationService);

                      if (selectedTab == 'VIEW'.tr) {
                        await addClientProvider.estateViewing(ref);
                        if (!mounted) return;
                        final err = ref.read(addClientFormProvider).errorMessage;
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
                          );
                          return;
                        }
                        addClientProvider.clearForm();
                        ref.read(selectedClientProvider.notifier).state = null;
                        ref.read(pendingNewClientNameProvider.notifier).state = null;
                        await ref.read(clientProvider.notifier).refreshClients();
                        ref.read(clientsShouldRefetchProvider.notifier).state = true;
                        nav.beamPop();
                      } else if (selectedTab == 'SELL'.tr) {
                        final ok = await addClientProvider.sellTransAction(ref);
                        if (!mounted) return;
                        if (!ok) {
                          final err = ref.read(addClientFormProvider).errorMessage;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err ?? 'error'.tr), backgroundColor: Colors.red.shade700),
                          );
                          return;
                        }
                        addClientProvider.clearForm();
                        ref.read(sellControllersProvider.notifier).state.clear();
                        ref.read(transactionControllersProvider.notifier).state.clear();
                        ref.read(selectedClientProvider.notifier).state = null;
                        ref.read(pendingNewClientNameProvider.notifier).state = null;
                        nav.beamPop();
                      } else if (selectedTab == 'BUY'.tr) {
                        final ok = await addClientProvider.buyTransAction(ref);
                        if (!mounted) return;
                        if (!ok) {
                          final err = ref.read(addClientFormProvider).errorMessage;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err ?? 'error'.tr), backgroundColor: Colors.red.shade700),
                          );
                          return;
                        }
                        addClientProvider.clearForm();
                        ref.read(buySearchControllersProvider).clear();
                        ref.read(transactionControllersProvider.notifier).state.clear();
                        ref.read(selectedClientProvider.notifier).state = null;
                        ref.read(pendingNewClientNameProvider.notifier).state = null;
                        nav.beamPop();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection() {
    if (!ref.watch(showUserContactsProvider)) {
      return const ClientListAddFormCrm();
    }
    return AddUserContactsCrm(
      viewFormKey: _viewFormKey,
      sellFormKey: _sellFormKey,
      buyFormKey: _buyFormKey,
      isMobile: true,
    );
  }

  Widget _buildQuickStepContent(String selectedTab, int step) {
    if (selectedTab == 'SELL'.tr) {
      if (step == 1) return const CrmSellQuickStep1();
      return const CrmSellQuickStep2(isMobile: true);
    }
    if (selectedTab == 'BUY'.tr) {
      if (step == 1) return const CrmBuyQuickStep1();
      return const CrmBuyQuickStep2(isMobile: true);
    }
    return const CrmViewQuickStep1(isMobile: true);
  }

  Widget _buildDetailsSection(String selectedTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedTab == 'VIEW'.tr) ...[
          TransactionListPicker(),
          const SizedBox(height: 20),
        ],
        GetSelectedWidget(
          sellFormKey: _sellFormKey,
          buyFormKey: _buyFormKey,
          isMobile: true,
        ),
      ],
    );
  }
}
