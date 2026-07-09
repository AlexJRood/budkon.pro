import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/your_agent/providers.dart';
import 'package:crm/your_agent/tabs/docs_tab.dart';
import 'package:crm/your_agent/tabs/listing_tab.dart';
import 'package:crm/your_agent/tabs/presentation_tab.dart';
import 'package:crm/your_agent/tabs/tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_model.dart';
import 'package:core/user/user/user_provider.dart';


class _PortalTabConfig {
  final String label;
  final String? trackEventType;
  final Widget Function() builder;

  const _PortalTabConfig({
    required this.label,
    required this.builder,
    this.trackEventType,
  });
}

class ClientPortalCasesListScreen extends ConsumerWidget {
  const ClientPortalCasesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      appModule: AppModule.portal,
      sideMenuKey: sideMenuKey,
      isTopAppBarHoveroverUI: false,
      childPc: _ClientPortalCasesListBody(theme: theme),
      childMobile: _ClientPortalCasesListBody(theme: theme, isMobile: true),
    );
  }
}

class _ClientPortalCasesListBody extends ConsumerWidget {
  final ThemeColors theme;
  final bool isMobile;

  const _ClientPortalCasesListBody({
    required this.theme,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portals = ref.watch(clientPortalsProvider);

    if (portals.isEmpty) {
      return Center(
        child: Text(
          'no_cases_in_your_agent'.tr,
          style: AppTextStyles.interRegular.copyWith(
            color: theme.textColor,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: isMobile
          ? EdgeInsets.only(
              top: TopAppBarSize.resolve(context),
              bottom: BottomBarSize.resolve(context),
              left: 16,
              right: 16,
            )
          : const EdgeInsets.all(16),
      itemCount: portals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = portals[index];

        return _ClientPortalCaseCard(
          portal: p,
          theme: theme,
          onTap: () {
            ref.read(navigationService).pushNamedScreen(
                  '${Routes.yourAgent}/${p.uuid}',
                );
          },
        );
      },
    );
  }
}

class _ClientPortalCaseCard extends StatelessWidget {
  final ClientPortalModel portal;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _ClientPortalCaseCard({
    required this.portal,
    required this.theme,
    required this.onTap,
  });

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final title = portal.caseTitle ??
        portal.propertyTitle ??
        '${'case_default_title'.tr} #${portal.transactionId}';

    final subtitle = portal.caseSubtitle ??
        portal.propertyAddress ??
        '${'transaction_default_subtitle'.tr} #${portal.transactionId}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.textColor.withOpacity(0.08),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLogo(
                  logoUrl: portal.companyLogo,
                  companyName: portal.companyName,
                  theme: theme,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.interMedium14.copyWith(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.interRegular.copyWith(
                          color: theme.textColor.withOpacity(0.78),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_hasText(portal.companyName))
                            _MetaChip(
                              icon: Icons.business_rounded,
                              label: portal.companyName!,
                              theme: theme,
                            ),
                          if (_hasText(portal.agentName))
                            _MetaChip(
                              icon: Icons.person_rounded,
                              label: portal.agentName!,
                              theme: theme,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    _AgentAvatar(
                      avatarUrl: portal.agentAvatar,
                      agentName: portal.agentName,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.textColor.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeColors theme;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.themeColor.withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.themeColor,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.interRegular.copyWith(
                color: theme.textColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String? logoUrl;
  final String? companyName;
  final ThemeColors theme;

  const _CompanyLogo({
    required this.logoUrl,
    required this.companyName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;
    final fallbackLetter = (companyName != null && companyName!.trim().isNotEmpty)
        ? companyName!.trim()[0].toUpperCase()
        : 'C';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.themeColor.withOpacity(0.10),
        border: Border.all(
          color: theme.textColor.withOpacity(0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _LogoFallback(
                letter: fallbackLetter,
                theme: theme,
              ),
            )
          : _LogoFallback(
              letter: fallbackLetter,
              theme: theme,
            ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String letter;
  final ThemeColors theme;

  const _LogoFallback({
    required this.letter,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: AppTextStyles.interMedium14.copyWith(
          color: theme.themeColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? agentName;
  final ThemeColors theme;

  const _AgentAvatar({
    required this.avatarUrl,
    required this.agentName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final fallbackLetter = (agentName != null && agentName!.trim().isNotEmpty)
        ? agentName!.trim()[0].toUpperCase()
        : 'A';

    return CircleAvatar(
      radius: 22,
      backgroundColor: theme.themeColor.withOpacity(0.12),
      foregroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: hasAvatar
          ? null
          : Text(
              fallbackLetter,
              style: AppTextStyles.interMedium14.copyWith(
                color: theme.themeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class ClientPortalCaseScreen extends ConsumerWidget {
  final String portalId;

  const ClientPortalCaseScreen({
    super.key,
    required this.portalId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      appModule: AppModule.portal,
      sideMenuKey: sideMenuKey,
      childPc: _ClientPortalCaseBody(
        portalId: portalId,
        isMobile: false,
        theme: theme,
      ),
      childMobile: _ClientPortalCaseBody(
        portalId: portalId,
        isMobile: true,
        theme: theme,
      ),
    );
  }
}

class _ClientPortalCaseBody extends ConsumerStatefulWidget {
  final String portalId;
  final bool isMobile;
  final ThemeColors theme;

  const _ClientPortalCaseBody({
    super.key,
    required this.portalId,
    required this.isMobile,
    required this.theme,
  });

  @override
  ConsumerState<_ClientPortalCaseBody> createState() =>
      _ClientPortalCaseBodyState();
}

class _ClientPortalCaseBodyState extends ConsumerState<_ClientPortalCaseBody> {
  int _currentTab = 0;

  bool _didTrackPortalVisit = false;
  String? _lastTrackedTabEvent;

  Future<void> _trackEvent(
    String eventType, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await ref.read(clientPortalActionsProvider).trackEvent(
            portalId: widget.portalId,
            eventType: eventType,
            metadata: metadata,
          );
    } catch (_) {}
  }

  void _ensureInitialTracking(List<_PortalTabConfig> tabsConfig) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (!_didTrackPortalVisit) {
        _didTrackPortalVisit = true;
        await _trackEvent(
          ClientPortalEventTypes.portalVisit,
          metadata: {
            'portal_uuid': widget.portalId,
            'source': 'client_case_screen',
          },
        );
      }

      if (_currentTab < tabsConfig.length) {
        final eventType = tabsConfig[_currentTab].trackEventType;
        if (eventType != null && _lastTrackedTabEvent != eventType) {
          _lastTrackedTabEvent = eventType;
          await _trackEvent(
            eventType,
            metadata: {
              'portal_uuid': widget.portalId,
              'source': 'client_initial_tab',
            },
          );
        }
      }
    });
  }

  Future<void> _onTabChanged(
    int index,
    List<_PortalTabConfig> tabsConfig,
  ) async {
    setState(() => _currentTab = index);

    if (index >= tabsConfig.length) return;

    final eventType = tabsConfig[index].trackEventType;
    if (eventType == null) return;

    if (_lastTrackedTabEvent == eventType) return;

    _lastTrackedTabEvent = eventType;

    await _trackEvent(
      eventType,
      metadata: {
        'portal_uuid': widget.portalId,
        'source': 'client_tab_change',
        'tab_index': index,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final detailAsync =
        ref.watch(clientPortalCaseDetailProvider(widget.portalId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${'error_loading_case'.tr} $e',
          style: TextStyle(color: theme.textColor),
        ),
      ),
      data: (detail) {
        final isSeller = detail.isSeller;
        final canViewDocs = detail.canViewDocuments;
        final canViewPres = detail.canViewPresentations;
        final canEdit = detail.canEditListing;
        final hasDocs = detail.documents.isNotEmpty;

        final List<_PortalTabConfig> tabsConfig = [];

        if (isSeller) {
          tabsConfig.add(
            _PortalTabConfig(
              label: 'listing_tab'.tr,
              trackEventType: ClientPortalEventTypes.listingView,
              builder: () => ListingTab(
                portalId: widget.portalId,
                listing: detail.listing,
                transaction: detail.transaction,
                canEdit: canEdit,
              ),
            ),
          );

          if (canViewPres) {
            tabsConfig.add(
              _PortalTabConfig(
                label: 'presentations_tab'.tr,
                trackEventType: ClientPortalEventTypes.presentationsView,
                builder: () => SellerPresentationsTab(
                  transactionId: detail.transactionId,
                  isMobile: widget.isMobile,
                  portalId: widget.portalId,
                ),
              ),
            );
          }

          if (canViewDocs && hasDocs) {
            tabsConfig.add(
              _PortalTabConfig(
                label: 'documents_tab'.tr,
                trackEventType: ClientPortalEventTypes.documentsView,
                builder: () => DocumentsTab(
                  documents: detail.documents,
                ),
              ),
            );
          }
        } else {
          tabsConfig.add(
            _PortalTabConfig(
              label: 'proposals_preview_tab'.tr,
              builder: () => Center(
                child: Text(
                  'proposals_tab_placeholder'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );

          tabsConfig.add(
            _PortalTabConfig(
              label: 'statuses_preview_tab'.tr,
              builder: () => Center(
                child: Text(
                  'statuses_tab_placeholder'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );

          if (canViewDocs && hasDocs) {
            tabsConfig.add(
              _PortalTabConfig(
                label: 'documents_tab'.tr,
                trackEventType: ClientPortalEventTypes.documentsView,
                builder: () => DocumentsTab(
                  documents: detail.documents,
                ),
              ),
            );
          }
        }

        if (tabsConfig.isEmpty) {
          return Center(
            child: Text(
              'no_data_available_message'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          );
        }

        if (_currentTab >= tabsConfig.length) {
          _currentTab = 0;
        }

        _ensureInitialTracking(tabsConfig);

        final tabLabels = tabsConfig.map((t) => t.label).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isMobile) SizedBox(height: TopAppBarSize.resolve(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClientPortalTabs(
                tabs: tabLabels,
                currentIndex: _currentTab,
                onChanged: (i) => _onTabChanged(i, tabsConfig),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: tabsConfig[_currentTab].builder(),
            ),
            if (widget.isMobile)
              SizedBox(height: BottomBarSize.resolve(context)),
          ],
        );
      },
    );
  }
}