import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

// PopPage
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:crm_agent/add_client_form/widgets/crm_form_mode_provider.dart';
import 'package:crm_agent/add_client_form/widgets/crm_form_mode_widgets.dart';
import 'package:core/theme/icons.dart'; // <-- keep only once
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class NoteAndSubmitMobile extends ConsumerStatefulWidget {
  final VoidCallback onSubmit;
  final String? selectedTab;
  final GlobalKey<FormState>? viewFormKey;
  final GlobalKey<FormState>? sellFormKey;
  final GlobalKey<FormState>? buyFormKey;
  final bool isMobile;

  const NoteAndSubmitMobile({
    super.key,
    required this.onSubmit,
    this.selectedTab,
    this.viewFormKey,
    this.sellFormKey,
    this.buyFormKey,
    required this.isMobile,
  });

  @override
  NoteAndSubmitMobileState createState() => NoteAndSubmitMobileState();
}

class NoteAndSubmitMobileState extends ConsumerState<NoteAndSubmitMobile> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Open note editor in bottom sheet via PopPage
  Future<void> _openNoteSheet(BuildContext context, WidgetRef ref) async {
    final theme        = ref.read(themeColorsProvider);
    final addClientForm= ref.read(addClientFormProvider);

    await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: theme.dashboardContainer,
                    builder: (_) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.85,
                        minChildSize: 0.45,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (ctx, scrollController) {
                          return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Row(
              children: [

            const SizedBox(width: 15),
                Icon(Icons.edit_note_rounded, color: theme.textColor),
                const SizedBox(width: 8),
                Text('Notes'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            _buildNoteContainer(addClientForm, theme),
          ],
        );
                        },
                      );
                    },
    );
  }

  void _handleSubmit(WidgetRef ref) {
    final clientId = ref.watch(addClientFormProvider).selectedClientId;
    final String? st = widget.selectedTab;
    final bool isViewTab = st == 'VIEW'.tr || st == 'VIEWER'.tr;

    final bool isViewFormValid =
        (widget.viewFormKey?.currentState?.validate() ?? false) || clientId != null;
    final bool isSellFormValid =
        (widget.sellFormKey?.currentState?.validate() ?? false) || clientId != null;
    final bool isBuyFormValid =
        (widget.buyFormKey?.currentState?.validate() ?? false) || clientId != null;

    final txCache = ref.read(agentTransactionCacheProvider.notifier);

    if (isViewTab && isViewFormValid) {
      txCache.addTransactionData('is_seller', false);
      txCache.addTransactionData('is_buyer', false);
      widget.onSubmit.call();
    } else if (st == 'SELL'.tr && isSellFormValid && isViewFormValid) {
      txCache.addTransactionData('is_seller', true);
      txCache.addTransactionData('is_buyer', false);
      widget.onSubmit.call();
    } else if (st == 'BUY'.tr && isBuyFormValid && isViewFormValid) {
      txCache.addTransactionData('is_buyer', true);
      txCache.addTransactionData('is_seller', false);
      widget.onSubmit.call();
    } else {
      if (kDebugMode) {
        debugPrint('❌ Form validation failed! Please fill in all required fields.');
      }
      // ⑥ Pokaż użytkownikowi co jest wymagane
      if (mounted) {
        final clientId = ref.read(addClientFormProvider).selectedClientId;
        final formState = ref.read(addClientFormProvider);
        final hasPendingName = formState.clientNameController.text.trim().isNotEmpty;

        String msg;
        if (clientId == null && !hasPendingName) {
          msg = 'select_client_or_create_new'.tr;
        } else {
          msg = 'fill_required_fields'.tr;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final addClientForm = ref.watch(addClientFormProvider);
    final theme         = ref.watch(themeColorsProvider);

    if (widget.isMobile) {
      final stepsEnabled = ref.watch(crmFormStepsEnabledProvider);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // MODE TOGGLE
              CrmModeToggle(stepsEnabled: stepsEnabled),
              const SizedBox(width: 8),

              // NOTE button (blurred glass)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                    child: Container(
                      height: 45,
                      // półprzezroczyste tło, żeby BackdropFilter „złapał” rozmycie
                      decoration: BoxDecoration(
                        color: theme.dashboardContainer.withAlpha(89),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.textColor.withAlpha(64),
                          width: 1,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: () => _openNoteSheet(context, ref),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.transparent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Note'.tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (addClientForm.clientNoteController.text.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.dashboardContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcons.check(color: theme.textColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'note_added'.tr,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // SUBMIT button
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    style: buttonStyleRounded10ThemeRed,
                    onPressed: () => _handleSubmit(ref),
                    child:  Center(
                      child: Text(
                        'submit'.tr,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Desktop/tablet fallback (jak było)
    final addClientFormState = addClientForm; // alias tylko po to, żeby nazwa była jasna
    return Column(
      children: [
        Expanded(child: _buildNoteContainer(addClientFormState, theme)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: buttonStyleRounded10ThemeRed,
          onPressed: () => _handleSubmit(ref),
          child:SizedBox(
            height: 45,
            child: Center(
              child: Text(
                'submit'.tr,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // Reusable note editor
  Widget _buildNoteContainer(AddClientFormState addClientForm, ThemeColors theme) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: TextField(
          controller: addClientForm.clientNoteController,
          focusNode: _focusNode,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.edit_calendar_rounded, color: theme.textColor),
            fillColor: theme.dashboardContainer,
            hintText: 'Notes...'.tr,
            hintStyle: TextStyle(color: theme.textColor, fontSize: 16),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          maxLines: null,
          minLines: 4,
          keyboardType: TextInputType.multiline,
        ),
      ),
    );
  }
}
