import 'package:core/common/chrome/back_button.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm_agent/add_client_form/components/usercontact/add_user_contacts.dart';
import 'package:crm_agent/add_client_form/components/usercontact/contact_list.dart';
import 'package:crm_agent/add_client_form/controllers/buy_controlers.dart';
import 'package:crm_agent/add_client_form/controllers/sell_controlers.dart';
import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:crm_agent/add_client_form/widgets/get_selected_widget.dart';
import 'package:crm_agent/add_client_form/widgets/note_and_submit.dart';
import 'package:crm_agent/add_client_form/widgets/transaction_view_widget.dart';
import 'package:crm_agent/add_client_form/widgets/crm_form_mode_provider.dart';
import 'package:crm_agent/add_client_form/widgets/crm_form_mode_widgets.dart';
import 'package:crm_agent/add_client_form/widgets/crm_progress_indicator.dart';
import 'package:crm_agent/add_client_form/widgets/crm_quick_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm_agent/add_client_form/widgets/crm_tab_bar.dart';

class AddClientFormPc extends ConsumerStatefulWidget {
  final bool isClientView;
  final String? state;
  final bool isNamedRoute;

  const AddClientFormPc({
    super.key,
    this.isNamedRoute = false,
    this.isClientView = false,
    this.state,
  });

  @override
  ConsumerState<AddClientFormPc> createState() => _AddClientFormState();
}

class _AddClientFormState extends ConsumerState<AddClientFormPc> {
  final _viewFormKey = GlobalKey<FormState>();
  final _sellFormKey = GlobalKey<FormState>();
  final _buyFormKey = GlobalKey<FormState>();
  final _clientFormKey = GlobalKey<FormState>();

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
    final nav = ref.read(navigationService);
    final stepsEnabled = ref.watch(crmFormStepsEnabledProvider);
    final progress = ref.watch(crmProgressProvider);
    final step = crmProgressToStep(progress);

    final currentPath = nav.currentPath;
    final isNamedRoute =
        widget.isNamedRoute || ((currentPath ?? '').contains('add-client'));

    final stepLabels = selectedTab == 'SELL'.tr
        ? ['client'.tr, 'property'.tr, 'transaction'.tr]
        : ['client'.tr, selectedTab == 'VIEW'.tr ? 'event'.tr : 'details'.tr];

    bool isLastStep(int s) =>
        selectedTab == 'SELL'.tr ? s >= 2 : s >= 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackButtonHously(isNamedRoute: isNamedRoute),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left column ──────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab bar + mode toggle
                        Row(
                          children: [
                            SizedBox(
                              width: 340,
                              child: CrmTabBar(
                                selectedTab: selectedTab,
                                onTabSelected: (tab) {
                                  ref.read(selectedTabProvider.notifier).state = tab;
                                  crmResetProgress(ref);
                                },
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            CrmModeToggle(stepsEnabled: stepsEnabled),
                          ],
                        ),

                        // Progress indicator (steps mode only)
                        if (stepsEnabled) ...[
                          const SizedBox(height: 16),
                          CrmProgressIndicatorWidget(stepLabels: stepLabels),
                        ],

                        const SizedBox(height: 20),

                        // Title
                        if (selectedTab == 'VIEW'.tr)
                          Text('Create a new user profile'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold))
                        else if (selectedTab == 'SELL'.tr)
                          Text('create_a_new_sell_transaction'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold))
                        else
                          Text('create_a_new_buy_transaction'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 10),

                        if (selectedTab == 'VIEW'.tr)
                          Text('Enter client information and personalize their profile'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 17))
                        else
                          Text('select_client_or_create_new'.tr,
                              style: TextStyle(color: theme.textColor, fontSize: 17)),

                        const SizedBox(height: 20),

                        // ── Content ──────────────────────────────────────
                        if (!stepsEnabled) ...[
                          _buildClientSection(),
                          const SizedBox(height: 20),
                          if (selectedTab == 'VIEW'.tr) ...[
                            TransactionListPicker(),
                            const SizedBox(height: 20),
                          ],
                          GetSelectedWidget(
                            sellFormKey: _sellFormKey,
                            buyFormKey: _buyFormKey,
                            isMobile: false,
                          ),
                        ] else if (step == 0) ...[
                          _buildClientSection(),
                          const SizedBox(height: 20),
                          CrmStepNavRow(step: step, theme: theme),
                        ] else if (selectedTab == 'SELL'.tr && step == 1) ...[
                          const CrmSellQuickStep1(),
                          const SizedBox(height: 20),
                          CrmStepNavRow(step: step, theme: theme, isLastStep: false),
                        ] else if (selectedTab == 'SELL'.tr && step >= 2) ...[
                          CrmSellQuickStep2(isMobile: false),
                          const SizedBox(height: 20),
                          CrmStepNavRow(step: step, theme: theme, isLastStep: true),
                        ] else if (selectedTab == 'BUY'.tr && step == 1) ...[
                          const CrmBuyQuickStep1(),
                          const SizedBox(height: 20),
                          CrmStepNavRow(step: step, theme: theme, isLastStep: false),
                        ] else if (selectedTab == 'BUY'.tr && step >= 2) ...[
                          CrmBuyQuickStep2(isMobile: false),
                          const SizedBox(height: 20),
                          CrmStepNavRow(step: step, theme: theme, isLastStep: true),
                        ] else ...[
                          CrmViewQuickStep1(isMobile: false),
                          const SizedBox(height: 20),
                          CrmStepNavRow(step: step, theme: theme, isLastStep: isLastStep(step)),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 50),

                // ── Right column: note + submit ───────────────────────────
                Expanded(
                  flex: 1,
                  child: NoteAndSubmit(
                    selectedTab: selectedTab,
                    viewFormKey: _viewFormKey,
                    sellFormKey: _sellFormKey,
                    buyFormKey: _buyFormKey,
                    isMobile: false,
                    onSubmit: () async {
                      final navigator = Navigator.of(context);
                      final isCreatingNewUser = ref.read(showUserContactsProvider);
                      final clientOk = isCreatingNewUser
                          ? true
                          : (_clientFormKey.currentState?.validate() ?? false);
                      if (!clientOk) return;

                      if (selectedTab == 'VIEW'.tr) {
                        await addClientProvider.estateViewing(ref);
                        if (!mounted) return;
                        addClientProvider.clearForm();
                        ref.read(selectedClientProvider.notifier).state = null;
                        await ref.read(clientProvider.notifier).refreshClients();
                        if (!mounted) return;
                        ref.read(clientsShouldRefetchProvider.notifier).state = true;
                        navigator.pop();
                      } else if (selectedTab == 'SELL'.tr) {
                        final sellOk = stepsEnabled
                            ? true
                            : (_sellFormKey.currentState?.validate() ?? false);
                        if (!sellOk) return;
                        final ok = await addClientProvider.sellTransAction(ref);
                        if (!mounted || !ok) return;
                        addClientProvider.clearForm();
                        ref.read(sellControllersProvider.notifier).state.clear();
                        ref.read(transactionControllersProvider.notifier).state.clear();
                        ref.read(selectedClientProvider.notifier).state = null;
                        ref.read(pendingNewClientNameProvider.notifier).state = null;
                        navigator.pop();
                      } else if (selectedTab == 'BUY'.tr) {
                        final buyOk = stepsEnabled
                            ? true
                            : (_buyFormKey.currentState?.validate() ?? false);
                        if (!buyOk) return;
                        final ok = await addClientProvider.buyTransAction(ref);
                        if (!mounted || !ok) return;
                        addClientProvider.clearForm();
                        ref.read(buySearchControllersProvider).clear();
                        ref.read(transactionControllersProvider.notifier).state.clear();
                        ref.read(selectedClientProvider.notifier).state = null;
                        ref.read(pendingNewClientNameProvider.notifier).state = null;
                        navigator.pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientSection() {
    if (!ref.watch(showUserContactsProvider)) {
      return Column(
        children: [
          const ClientListAddFormCrm(),
          _ClientRequiredField(formKey: _clientFormKey),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: AddUserContactsCrm(
            viewFormKey: _viewFormKey,
            sellFormKey: _sellFormKey,
            buyFormKey: _buyFormKey,
          ),
        ),
      ],
    );
  }
}

class _ClientRequiredField extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  const _ClientRequiredField({required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedClient = ref.watch(selectedClientProvider);
    final pendingName = ref.watch(pendingNewClientNameProvider);
    final hasClient = selectedClient != null || pendingName != null;

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: FormField<void>(
        validator: (_) => hasClient ? null : 'client_is_required'.tr,
        builder: (state) => state.hasError
            ? Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  'client_is_required'.tr,
                  style: TextStyle(
                    color: theme.themeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
