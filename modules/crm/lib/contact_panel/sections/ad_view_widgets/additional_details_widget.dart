import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/boolean_features_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/financial_registry_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/installations_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/meta_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/offer_estate_building_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/publication_flags_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/utility_infrastructure_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widgets/year_lot_market_country_district_geo_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

class AdditionalDetails extends StatelessWidget {
  const AdditionalDetails({
    super.key,
    required this.isEditing,
    required this.state,
    required this.theme,
  });

  final bool isEditing;
  final dynamic state;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns = constraints.maxWidth >= 980;
        const double spacing = 16;
        final double cardWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'additional_details_title'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'additional_details_subtitle'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(165),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _DetailsAccordionCard(
                    theme: theme,
                    title: 'offer_and_building_title'.tr,
                    subtitle: 'offer_and_building_subtitle'.tr,
                    icon: Icons.home_work_outlined,
                    initiallyExpanded: true,
                    child: OfferEstateBuildingSection(
                      isEditing: isEditing,
                      state: state,
                      theme: theme,
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _DetailsAccordionCard(
                    theme: theme,
                    title: 'location_and_parameters_title'.tr,
                    subtitle: 'location_and_parameters_subtitle'.tr,
                    icon: Icons.location_on_outlined,
                    initiallyExpanded: true,
                    child: YearLotMarketCountryDistrictGeoSection(
                      isEditing: isEditing,
                      state: state,
                      theme: theme,
                    ),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _DetailsAccordionCard(
                    theme: theme,
                    title: 'media_and_installations_title'.tr,
                    subtitle: 'media_and_installations_subtitle'.tr,
                    icon: Icons.bolt_outlined,
                    initiallyExpanded: true,
                    child: Column(
                      children: [
                        UtilityInfrastructureSection(
                          isEditing: isEditing,
                          state: state,
                          theme: theme,
                        ),
                        const SizedBox(height: 14),
                        InstallationsSection(
                          isEditing: isEditing,
                          state: state,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _DetailsAccordionCard(
                    theme: theme,
                    title: 'property_features_title'.tr,
                    subtitle:
                        'property_features_subtitle'.tr,
                    icon: Icons.auto_awesome_outlined,
                    initiallyExpanded: true,
                    child: BooleanFeaturesSection(
                      isEditing: isEditing,
                      state: state,
                      theme: theme,
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _DetailsAccordionCard(
                    theme: theme,
                    title: 'finance_and_legal_title'.tr,
                    subtitle: 'finance_and_legal_subtitle'.tr,
                    icon: Icons.account_balance_wallet_outlined,
                    initiallyExpanded: !isEditing,
                    child: FinancialRegistrySection(
                      isEditing: isEditing,
                      state: state,
                      theme: theme,
                    ),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _DetailsAccordionCard(
                    theme: theme,
                    title: 'publication_and_system_title'.tr,
                    subtitle:
                        'publication_and_system_subtitle'.tr,
                    icon: Icons.settings_outlined,
                    initiallyExpanded: false,
                    child: Column(
                      children: [
                        PublicationFlagsSection(
                          isEditing: isEditing,
                          state: state,
                          theme: theme,
                        ),
                        const SizedBox(height: 14),
                        MetaSection(
                          isEditing: isEditing,
                          state: state,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DetailsAccordionCard extends StatelessWidget {
  const _DetailsAccordionCard({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.initiallyExpanded = true,
  });

  final ThemeColors theme;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.textFieldColor.withAlpha(115),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.themeColor, size: 18),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                color: theme.textColor.withAlpha(155),
                fontSize: 12,
              ),
            ),
          ),
          iconColor: theme.textColor,
          collapsedIconColor: theme.textColor.withAlpha(180),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}