import 'package:flutter/foundation.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

class NoteAndSubmit extends ConsumerStatefulWidget {
  final Future<void> Function() onSubmit;
  final String? selectedTab;
  final GlobalKey<FormState>? viewFormKey;
  final GlobalKey<FormState>? sellFormKey;
  final GlobalKey<FormState>? buyFormKey;
  final bool isMobile;

  const NoteAndSubmit({
    super.key,
    required this.onSubmit,
    this.selectedTab,
    this.viewFormKey,
    this.sellFormKey,
    this.buyFormKey,
    required this.isMobile,
  });

  @override
  NoteAndSubmitState createState() => NoteAndSubmitState();
}

class NoteAndSubmitState extends ConsumerState<NoteAndSubmit> {
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

void _debugPrintFormErrors() {
  debugPrint('=== DEBUGGING FORM VALIDATION ===');
  debugPrint('Selected Tab: ${widget.selectedTab}');
  
  if (widget.selectedTab == 'VIEW'.tr) {
    final formState = widget.viewFormKey?.currentState;
    if (formState == null) {
      debugPrint('VIEW Form state is NULL');
    } else {
      debugPrint('VIEW Form validation result: ${formState.validate()}');
    }
  } else if (widget.selectedTab == 'SELL'.tr) {
    final formState = widget.sellFormKey?.currentState;
    if (formState == null) {
      debugPrint('SELL Form state is NULL');
    } else {
      debugPrint('SELL Form validation result: ${formState.validate()}');
    }
  } else if (widget.selectedTab == 'BUY'.tr) {
    final formState = widget.buyFormKey?.currentState;
    if (formState == null) {
      debugPrint('BUY Form state is NULL');
    } else {
      debugPrint('BUY Form validation result: ${formState.validate()}');
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final addClientForm = ref.watch(addClientFormProvider);
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        widget.isMobile
            ? SizedBox(
                height: 400,
                child: _buildNoteContainer(addClientForm, theme),
              )
            : Expanded(child: _buildNoteContainer(addClientForm, theme)),
        const SizedBox(height: 20),
       ElevatedButton(
  style: buttonStyleRounded10ThemeRed,
  onPressed: _isSubmitting ? null : () async {
    setState(() => _isSubmitting = true);
    
    try {
      final String? selectedTab = widget.selectedTab;
      
      final txCache = ref.read(agentTransactionCacheProvider.notifier);
     _debugPrintFormErrors();
      if (selectedTab == 'VIEW'.tr) {
        txCache.addTransactionData('is_seller', false);
        txCache.addTransactionData('is_buyer', false);

        if (widget.viewFormKey != null) {
          final isValid = widget.viewFormKey!.currentState?.validate() ?? false;
          if (!isValid) {
            setState(() => _isSubmitting = false);
            return;
          }
        }
        await widget.onSubmit();
        
      } else if (selectedTab == 'SELL'.tr) {
        txCache.addTransactionData('is_seller', true);
        txCache.addTransactionData('is_buyer', false);
        
        if (widget.sellFormKey != null) {
          final isValid = widget.sellFormKey!.currentState?.validate() ?? false;
          if (!isValid) {
            _debugPrintSellFormErrors();
            setState(() => _isSubmitting = false);
            return;
          }
        } else {
          debugPrint('WARNING: sellFormKey is null!');
        }
        await widget.onSubmit();  
        
      } else if (selectedTab == 'BUY'.tr) {
        txCache.addTransactionData('is_buyer', true);
        txCache.addTransactionData('is_seller', false);
        
        if (widget.buyFormKey != null) {
          final isValid = widget.buyFormKey!.currentState?.validate() ?? false;
          if (!isValid) {
            setState(() => _isSubmitting = false);
            return;
          }
        } else {
          debugPrint('WARNING: buyFormKey is null!');
        }
        await widget.onSubmit();  
        
      } else {
        await widget.onSubmit();  
      }
      
    } catch (e, stackTrace) {
      debugPrint('ERROR during submission: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
      setState(() => _isSubmitting = false);
    }
    } finally {
      // Only re-enable after the async operation completes
      // The await above ensures this runs AFTER onSubmit finishes
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  },
  child: Container(
    height: 50,
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    child: Center(
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'submit'.tr,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
    ),
  ),
)
      ],
    );
  }

  void _debugPrintSellFormErrors() {
    debugPrint('=== DEBUGGING SELL FORM VALIDATION ===');
    final sellFormState = widget.sellFormKey?.currentState;
    if (sellFormState == null) {
      debugPrint('Sell form state is null');
      return;
    }
    
    // Try to access individual fields - you may need to cast to your specific form state type
    debugPrint('Checking sell form fields...');
    debugPrint('- Title field validation status');
    debugPrint('- Description field validation status');
    debugPrint('- Price field validation status');
    debugPrint('- Street address field validation status');
    debugPrint('- Client selection validation status');
  }

  Widget _buildNoteContainer(
    AddClientFormState addClientForm,
    ThemeColors theme,
  ) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNode);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.adPopBackground.withAlpha(125),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: TextField(
          controller: addClientForm.clientNoteController,
          focusNode: _focusNode,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.edit_calendar_rounded,
              color: theme.textColor,
            ),
            fillColor: Colors.transparent,
            hintText: 'Notes...'.tr,
            hintStyle: TextStyle(color: theme.textColor, fontSize: 16),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
            disabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
          ),
          maxLines: null,
          minLines: 1,
          keyboardType: TextInputType.multiline,
        ),
      ),
    );
  }
}