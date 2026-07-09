import 'dart:ui' as ui;

import 'package:crm/bars/agent/appbar_crm_with_back.dart';
import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:crm/contact_panel/navigation/sidebar_client_panel.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/client_shimmer.dart';
import 'package:crm/contact_panel/view_changer.dart';
import 'package:crm/crm/finance/features/transactions/columns_transactions.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';

void copyToClipboard(BuildContext context, String listingUrl) async {
  await Clipboard.setData(ClipboardData(text: listingUrl));

  if (!context.mounted) return;

  final successSnackBar = Customsnackbar().showSnackBar(
    'success'.tr,
    'link_copied_to_clipboard'.tr,
    'success',
    () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    },
  );

  ScaffoldMessenger.of(context).showSnackBar(successSnackBar);
}

final activeSectionProvider = StateProvider<String>((ref) => 'dashboard');
final openTransactionIdProvider = StateProvider<String?>((ref) => null);

class NewClientsViewFull extends ConsumerStatefulWidget {
  final String tagClientViewPop;
  final UserContactModel clientViewPop;
  final String activeSection;
  final String activeAd;
  final ContactType contactType;

  const NewClientsViewFull({
    super.key,
    required this.tagClientViewPop,
    required this.clientViewPop,
    required this.activeSection,
    required this.activeAd,
    this.contactType = ContactType.client,
  });

  @override
  ConsumerState<NewClientsViewFull> createState() => _NewClientsViewFullState();
}

class _NewClientsViewFullState extends ConsumerState<NewClientsViewFull> {
  String get _panelBasePath {
    return contactPanelBasePathForContactType(
      type: widget.contactType,
      contactId: widget.clientViewPop.id,
    );
  }

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      debugPrint(widget.clientViewPop.toString());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final shouldNavigate =
          ref.read(isNavigateFromFinanceDraggableProvider).triggered;

      final fallbackSection = widget.activeSection.trim().isEmpty
          ? 'dashboard'
          : widget.activeSection.trim();

      final initialSection =
          shouldNavigate && widget.contactType != ContactType.crmUser
              ? 'transakcje'
              : _normalizeSectionForContactType(fallbackSection);

      ref.read(activeSectionProvider.notifier).state = initialSection;
      ref.read(navigationHistoryProvider.notifier).resetTo(initialSection);
    });
  }

  @override
  void didUpdateWidget(covariant NewClientsViewFull oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.clientViewPop.id;
    final newId = widget.clientViewPop.id;

    final clientChanged = oldId != newId;
    final typeChanged = oldWidget.contactType != widget.contactType;

    if (clientChanged || typeChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resetClientScopedState();
      });
    }
  }

  void _resetClientScopedState() {
    ref.read(activeSectionProvider.notifier).state = 'dashboard';
    ref.read(openTransactionIdProvider.notifier).state = null;
    ref.read(navigationHistoryProvider.notifier).resetTo('dashboard');
  }

  String _normalizeSectionForContactType(String section) {
    if (widget.contactType != ContactType.crmUser) {
      return section;
    }

  const allowedCrmUserSections = {
    'dashboard',
    'tasks',
    'calendar',
    'settlements',
    'docs',
    'komentarze',
    'edit-contact',
    'mail',
  };

    if (allowedCrmUserSections.contains(section)) {
      return section;
    }

    return 'dashboard';
  }

  void openTransactionSection(
    String section,
    AgentTransactionModel transaction,
  ) {
    if (widget.contactType == ContactType.crmUser) {
      return;
    }

    ref.read(activeSectionProvider.notifier).state = section;
    ref.read(openTransactionIdProvider.notifier).state =
        transaction.id.toString();

    updateUrl('$_panelBasePath/$section/${transaction.id}');
  }

  void _changeSection(String section) {
    final normalizedSection = _normalizeSectionForContactType(section);

    ref.read(activeSectionProvider.notifier).state = normalizedSection;
    ref.read(navigationHistoryProvider.notifier).addPage(normalizedSection);

    updateUrl('$_panelBasePath/$normalizedSection');
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = ref.watch(themeColorsProvider);
    final activeSection = ref.watch(activeSectionProvider);
    final openTransaction = ref.watch(openTransactionIdProvider);

    return PieCanvas(
      theme: PieTheme(
        rightClickShowsMenu: true,
        leftClickShowsMenu: false,
        buttonTheme: PieButtonTheme(
          backgroundColor: theme.themeColor.withAlpha(125),
          iconColor: Colors.white,
        ),
        buttonThemeHovered: PieButtonTheme(
          backgroundColor: theme.themeColor,
          iconColor: Colors.white,
        ),
      ),
      child: userAsyncValue.when(
        data: (user) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: theme.adPopBackground.withAlpha(
                      (255 * 0.5).toInt(),
                    ),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 60.0,
                        left: 80,
                      ),
                      child: SizedBox(
                        width: screenWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClientViewContent(
                                activeSection: activeSection,
                                clientViewPop: widget.clientViewPop,
                                activeAd: widget.activeAd,
                                openTransaction: openTransaction,
                                contactType: widget.contactType,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: TopAppBarCRMWithBack(
                          routeName: Routes.proClients,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      left: 0,
                      bottom: 0,
                      child: SidebarClientAgentCrm(
                        onTabSelected: _changeSection,
                        activeSection: activeSection,
                        contactType: widget.contactType,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const ClientShimmer(),
        error: (error, stack) => Center(
          child: Text('${'Error'.tr} $error'.tr),
        ),
      ),
    );
  }
}