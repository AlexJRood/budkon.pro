import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:reports/reports/all_report_page/model/report_list_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';

// Class to hold property data
class CompareProperty {
  final String pricing;
  final String pricingPerM2;
  final String floorSize;
  final String neighborhood;
  final String distanceToPublicTransport;
  final bool hasHighwayAccess;
  final String boostProductivity;
  final String bathroom;
  final String rooms;
  final String propertyType;
  final String buildingType;
  final String buildingMaterial;
  final String heatingType;
  final String yearBuilt;
  final String floorLevel;
  final bool hasBalcony;
  final bool hasElevator;
  final bool hasSauna;
  final bool hasParking;
  final bool hasGym;
  final bool hasAirConditioning;
  final bool hasGarden;
  final bool hasBasement;

  CompareProperty({
    required this.pricing,
    required this.pricingPerM2,
    required this.floorSize,
    required this.neighborhood,
    required this.distanceToPublicTransport,
    required this.hasHighwayAccess,
    required this.boostProductivity,
    required this.bathroom,
    required this.rooms,
    required this.propertyType,
    required this.buildingType,
    required this.buildingMaterial,
    required this.heatingType,
    required this.yearBuilt,
    required this.floorLevel,
    required this.hasBalcony,
    required this.hasElevator,
    required this.hasSauna,
    required this.hasParking,
    required this.hasGym,
    required this.hasAirConditioning,
    required this.hasGarden,
    required this.hasBasement,
  });
}

// CompareRow widget
class CompareRow extends StatelessWidget {
  final String label;
  final List<CompareProperty> properties;

  CompareRow({required this.label, required this.properties, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Label column
          Expanded(
            flex: 25,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
                fontSize: 14,
              ),
            ),
          ),
          // Property 1 column
          Expanded(flex: 20, child: _buildCell(context, properties[0], label)),
          // Property 2 column
          Expanded(flex: 20, child: _buildCell(context, properties[1], label)),
          // Property 3 column
          Expanded(flex: 20, child: _buildCell(context, properties[2], label)),
        ],
      ),
    );
  }

Widget _buildCell(
  BuildContext context,
  CompareProperty property,
  String label,
) {
  final pricingLabel = 'pricing'.tr;
  final pricingPerM2Label = 'pricing_per_m2'.tr;
  final floorSizeLabel = 'floor_size'.tr;
  final propertyTypeLabel = 'property_Type'.tr;
  final buildingTypeLabel = 'building_Type'.tr;
  final buildingMaterialLabel = 'building_material'.tr;
  final heatingTypeLabel = 'heating_Type'.tr;
  final yearBuiltLabel = 'year_built'.tr;
  final floorLevelLabel = 'floor_level'.tr;
  final neighborhoodLabel = 'neighborhood'.tr;
  final distanceLabel = 'distance_to_public_transport'.tr;
  final highwayAccessLabel = 'highway_access'.tr;
  final boostProductivityLabel = 'boost_productivity'.tr;
  final bathroomLabel = 'bathroom'.tr;
  final roomsLabel = 'rooms'.tr;
  final balconyLabel = 'balcony'.tr;
  final elevatorLabel = 'elevator'.tr;
  final saunaLabel = 'sauna'.tr;
  final parkingLabel = 'parking'.tr;
  final gymLabel = 'gym'.tr;
  final airConditioningLabel = 'air_conditioning'.tr;
  final gardenLabel = 'garden'.tr;
  final basementLabel = 'basement'.tr;

  if (label == pricingLabel) {
    return _buildTextCell(context, property.pricing);
  } else if (label == pricingPerM2Label) {
    return _buildTextCell(context, property.pricingPerM2);
  } else if (label == floorSizeLabel) {
    return _buildTextCell(context, property.floorSize);
  } else if (label == propertyTypeLabel) {
    return _buildTextCell(context, property.propertyType);
  } else if (label == buildingTypeLabel) {
    return _buildTextCell(context, property.buildingType);
  } else if (label == buildingMaterialLabel) {
    return _buildTextCell(context, property.buildingMaterial);
  } else if (label == heatingTypeLabel) {
    return _buildTextCell(context, property.heatingType);
  } else if (label == yearBuiltLabel) {
    return _buildTextCell(context, property.yearBuilt);
  } else if (label == floorLevelLabel) {
    return _buildTextCell(context, property.floorLevel);
  } else if (label == neighborhoodLabel) {
    return _buildTextCell(context, property.neighborhood);
  } else if (label == distanceLabel) {
    return _buildTextCell(context, property.distanceToPublicTransport);
  } else if (label == highwayAccessLabel) {
    return _buildBoolCell(context, property.hasHighwayAccess);
  } else if (label == boostProductivityLabel) {
    return _buildTextCell(context, property.boostProductivity);
  } else if (label == bathroomLabel) {
    return _buildTextCell(context, property.bathroom);
  } else if (label == roomsLabel) {
    return _buildTextCell(context, property.rooms);
  } else if (label == balconyLabel) {
    return _buildBoolCell(context, property.hasBalcony);
  } else if (label == elevatorLabel) {
    return _buildBoolCell(context, property.hasElevator);
  } else if (label == saunaLabel) {
    return _buildBoolCell(context, property.hasSauna);
  } else if (label == parkingLabel) {
    return _buildBoolCell(context, property.hasParking);
  } else if (label == gymLabel) {
    return _buildBoolCell(context, property.hasGym);
  } else if (label == airConditioningLabel) {
    return _buildBoolCell(context, property.hasAirConditioning);
  } else if (label == gardenLabel) {
    return _buildBoolCell(context, property.hasGarden);
  } else if (label == basementLabel) {
    return _buildBoolCell(context, property.hasBasement);
  }
  
  return const SizedBox.shrink();
}
  Widget _buildTextCell(BuildContext context, String value) {
    final isEmpty = value.isEmpty || value == 'N/A' || value == '—';

    return isEmpty
        ? Icon(
          Icons.close,
          color: Theme.of(context).iconTheme.color?.withAlpha(76),
          size: 18,
        )
        : Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).iconTheme.color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        );
  }

  Widget _buildBoolCell(BuildContext context, bool value) {
    return Icon(
      value ? Icons.check_circle : Icons.cancel,
      color:
          value
              ? Colors.green
              : Theme.of(context).iconTheme.color?.withAlpha(76),
      size: 20,
    );
  }
}

// ComparisonTable widget using a list of ReportsListModel
class ComparisonTable extends ConsumerWidget {
  final List<ReportsListModel> reports;

  const ComparisonTable({super.key, required this.reports});

  // Convert ReportsListModel to CompareProperty for display
  List<CompareProperty> _convertReportsToProperties() {
    return reports.take(3).map((report) {
      return CompareProperty(
        pricing:
            report.valueEstimate != null
                ? '\$${report.valueEstimate!.toStringAsFixed(0)}'
                : '—',
        pricingPerM2:
            report.pricePerSqm != null
                ? '\$${report.pricePerSqm!.toStringAsFixed(0)}'
                : '—',
        floorSize:
            report.floorArea != null
                ? '${report.floorArea!.toStringAsFixed(0)} m²'
                : '—',
        propertyType:
            report.propertyType?.isNotEmpty == true
                ? report.propertyType!
                : '—',
        buildingType:
            report.typeOfBuilding?.isNotEmpty == true
                ? report.typeOfBuilding!
                : '—',
        buildingMaterial:
            report.buildingMaterial?.isNotEmpty == true
                ? report.buildingMaterial!
                : '—',
        heatingType:
            report.heatingType?.isNotEmpty == true ? report.heatingType! : '—',
        yearBuilt: report.yearBuilt != null ? report.yearBuilt.toString() : '—',
        floorLevel: report.floorLevel != 0 ? report.floorLevel.toString() : '—',
        neighborhood:
            report.neighborhood?.isNotEmpty == true
                ? report.neighborhood!
                : '—',
        distanceToPublicTransport:
            report.distanceToPublicTransport?.isNotEmpty == true
                ? report.distanceToPublicTransport!
                : '—',
        hasHighwayAccess: report.hasHighways,
        boostProductivity:
            report.boostProductivity?.isNotEmpty == true
                ? report.boostProductivity!
                : '—',
        bathroom:
            (report.bathrooms == 2147483647)
                ? '—'
                : report.bathrooms.toString(),
        rooms:
            (report.bedrooms == 2147483647) ? '—' : report.bedrooms.toString(),
        hasBalcony: report.hasBalcony,
        hasElevator: report.hasElevator,
        hasSauna: report.hasSauna,
        hasParking: report.hasParking,
        hasGym: report.hasGym,
        hasAirConditioning: report.hasAirConditioning,
        hasGarden: report.hasGarden,
        hasBasement: report.hasBasement,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, ref) {
    // Handle empty reports
    if (reports.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'no_reports_available_for_comparison'.tr,
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(153),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final properties = _convertReportsToProperties();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pricing_information'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
        ),
        Divider(color: CustomColors.secondaryWidgetTextColor(context, ref)),
        SizedBox(height: 10),
        CompareRow(label: 'pricing'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'pricing_per_m2'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'floor_size'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        SizedBox(height: 10),
        Text(
          'property_details'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
        ),
        Divider(color: CustomColors.secondaryWidgetTextColor(context, ref)),
        SizedBox(height: 10),
        CompareRow(label: 'property_Type'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'building_Type'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'building_material'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'heating_Type'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'year_built'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'floor_level'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'bathroom'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label:'rooms'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        SizedBox(height: 10),
        Text(
          'Locations'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
        ),
        Divider(color: CustomColors.secondaryWidgetTextColor(context, ref)),
        SizedBox(height: 10),
        CompareRow(label: 'neighborhood'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(
           label: 'distance_to_public_transport'.tr,
          properties: properties,
        ),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'highway_access'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'boost_productivity'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        SizedBox(height: 10),
        Text(
           'amenities'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
        ),
        Divider(color: CustomColors.secondaryWidgetTextColor(context, ref)),
        SizedBox(height: 10),
        CompareRow(label: 'balcony'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'elevator'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'sauna'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'parking'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'gym'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'air_conditioning'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'garden'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
        CompareRow(label: 'basement'.tr, properties: properties),
        Divider(
          color: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ).withAlpha(76),
        ),
      ],
    );
  }
}

class CompareListTileMobile extends ConsumerWidget {
  final String title;
  final String value;

  const CompareListTileMobile({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Divider(
              color: theme.textColor.withValues(alpha: 0.5),
              height: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class ComparisonTableMobile extends ConsumerWidget {
  final List<ReportsListModel> reports;

  const ComparisonTableMobile({super.key, required this.reports});

  // Convert ReportsListModel to CompareProperty for display
  List<CompareProperty> _convertReportsToProperties() {
    return reports.take(3).map((report) {
      return CompareProperty(
        pricing:
            report.valueEstimate != null
                ? '\$${report.valueEstimate!.toStringAsFixed(0)}'
                : '—',
        pricingPerM2:
            report.pricePerSqm != null
                ? '\$${report.pricePerSqm!.toStringAsFixed(0)}'
                : '—',
        floorSize:
            report.floorArea != null
                ? '${report.floorArea!.toStringAsFixed(0)} m²'
                : '—',
        propertyType:
            report.propertyType?.isNotEmpty == true
                ? report.propertyType!
                : '—',
        buildingType:
            report.typeOfBuilding?.isNotEmpty == true
                ? report.typeOfBuilding!
                : '—',
        buildingMaterial:
            report.buildingMaterial?.isNotEmpty == true
                ? report.buildingMaterial!
                : '—',
        heatingType:
            report.heatingType?.isNotEmpty == true ? report.heatingType! : '—',
        yearBuilt: report.yearBuilt != null ? report.yearBuilt.toString() : '—',
        floorLevel: report.floorLevel != 0 ? report.floorLevel.toString() : '—',
        neighborhood:
            report.neighborhood?.isNotEmpty == true
                ? report.neighborhood!
                : '—',
        distanceToPublicTransport:
            report.distanceToPublicTransport?.isNotEmpty == true
                ? report.distanceToPublicTransport!
                : '—',
        hasHighwayAccess: report.hasHighways,
        boostProductivity:
            report.boostProductivity?.isNotEmpty == true
                ? report.boostProductivity!
                : '—',
        bathroom:
            (report.bathrooms == 2147483647)
                ? '—'
                : report.bathrooms.toString(),
        rooms:
            (report.bedrooms == 2147483647) ? '—' : report.bedrooms.toString(),
        hasBalcony: report.hasBalcony,
        hasElevator: report.hasElevator,
        hasSauna: report.hasSauna,
        hasParking: report.hasParking,
        hasGym: report.hasGym,
        hasAirConditioning: report.hasAirConditioning,
        hasGarden: report.hasGarden,
        hasBasement: report.hasBasement,
      );
    }).toList();
  }

  Widget _buildPropertySection(
    String label,
    List<CompareProperty> properties,
    String Function(CompareProperty) getValue,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Text(
          label,
          style: TextStyle(
            color: CustomColors.secondaryWidgetTextColor(context, ref),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 10),
        ...properties.asMap().entries.map((entry) {
          final index = entry.key;
          final property = entry.value;
          final value = getValue(property);
          final isEmpty = value == '—' || value.isEmpty;

          return CompareListTileMobile(
            title: reports[index].streetAddress!,
            value: isEmpty ? '—' : value,
          );
        }),
      ],
    );
  }

  Widget _buildBooleanSection(
    String label,
    List<CompareProperty> properties,
    bool Function(CompareProperty) getValue,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Text(
          label,
          style: TextStyle(
            color: CustomColors.secondaryWidgetTextColor(context, ref),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 10),
        ...properties.asMap().entries.map((entry) {
          final index = entry.key;
          final property = entry.value;
          final hasFeature = getValue(property);

          return CompareListTileMobile(
            title: reports[index].streetAddress!,
            value: hasFeature ? '✓' : '✗',
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    if (reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
           'no_reports_available_for_comparison'.tr,
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(
                context,
                ref,
              ).withAlpha(153),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final properties = _convertReportsToProperties();

    return Column(
      children: [
        ExpansionTile(
          iconColor: CustomColors.secondaryWidgetTextColor(context, ref),
          collapsedIconColor: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ),
          title: Text(
            'pricing_information'.tr,
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(context, ref),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            _buildPropertySection(
             'pricing'.tr,
              properties,
              (p) => p.pricing,
              context,
              ref,
            ),
            _buildPropertySection(
             'pricing_per_m2'.tr,
              properties,
              (p) => p.pricingPerM2,
              context,
              ref,
            ),
            _buildPropertySection(
              'floor_size'.tr,
              properties,
              (p) => p.floorSize,
              context,
              ref,
            ),
            SizedBox(height: 15),
          ],
        ),
        ExpansionTile(
          iconColor: CustomColors.secondaryWidgetTextColor(context, ref),
          collapsedIconColor: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ),
          title: Text(
             'property_details'.tr,
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(context, ref),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            _buildPropertySection(
              'property_Type'.tr,
              properties,
              (p) => p.propertyType,
              context,
              ref,
            ),
            _buildPropertySection(
              'building_Type'.tr,
              properties,
              (p) => p.buildingType,
              context,
              ref,
            ),
            _buildPropertySection(
              'building_material'.tr,
              properties,
              (p) => p.buildingMaterial,
              context,
              ref,
            ),
            _buildPropertySection(
              'heating_Type'.tr,
              properties,
              (p) => p.heatingType,
              context,
              ref,
            ),
            _buildPropertySection(
              'year_built'.tr,
              properties,
              (p) => p.yearBuilt,
              context,
              ref,
            ),
            _buildPropertySection(
              'floor_level'.tr,
              properties,
              (p) => p.floorLevel,
              context,
              ref,
            ),
            _buildPropertySection(
              'bathroom'.tr,
              properties,
              (p) => p.bathroom,
              context,
              ref,
            ),
            _buildPropertySection(
              'rooms'.tr,
              properties,
              (p) => p.rooms,
              context,
              ref,
            ),
            SizedBox(height: 15),
          ],
        ),
        ExpansionTile(
          iconColor: CustomColors.secondaryWidgetTextColor(context, ref),
          collapsedIconColor: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ),
          title: Text(
            'Locations'.tr,
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(context, ref),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            _buildPropertySection(
              'neighborhood'.tr,
              properties,
              (p) => p.neighborhood,
              context,
              ref,
            ),
            _buildPropertySection(
              'distance_to_public_transport'.tr,
              properties,
              (p) => p.distanceToPublicTransport,
              context,
              ref,
            ),
            _buildBooleanSection(
              'highway_access'.tr,
              properties,
              (p) => p.hasHighwayAccess,
              context,
              ref,
            ),
            _buildPropertySection(
              'boost_productivity'.tr,
              properties,
              (p) => p.boostProductivity,
              context,
              ref,
            ),
            SizedBox(height: 15),
          ],
        ),
        ExpansionTile(
          iconColor: CustomColors.secondaryWidgetTextColor(context, ref),
          collapsedIconColor: CustomColors.secondaryWidgetTextColor(
            context,
            ref,
          ),
          title: Text(
            'amenities'.tr,
            style: TextStyle(
              color: CustomColors.secondaryWidgetTextColor(context, ref),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            _buildBooleanSection(
              'balcony'.tr,
              properties,
              (p) => p.hasBalcony,
              context,
              ref,
            ),
            _buildBooleanSection(
             'elevator'.tr, 
              properties,
              (p) => p.hasElevator,
              context,
              ref,
            ),
            _buildBooleanSection(
              'sauna'.tr,
              properties,
              (p) => p.hasSauna,
              context,
              ref,
            ),
            _buildBooleanSection(
              'parking'.tr,
              properties,
              (p) => p.hasParking,
              context,
              ref,
            ),
            _buildBooleanSection(
              'gym'.tr,
              properties,
              (p) => p.hasGym,
              context,
              ref,
            ),
            _buildBooleanSection(
              'air_conditioning'.tr,
              properties,
              (p) => p.hasAirConditioning,
              context,
              ref,
            ),
            _buildBooleanSection(
              'garden'.tr,
              properties,
              (p) => p.hasGarden,
              context,
              ref,
            ),
            _buildBooleanSection(
              'basement'.tr, 
              properties,
              (p) => p.hasBasement,
              context,
              ref,
            ),
            SizedBox(height: 15),
          ],
        ),
      ],
    );
  }
}
