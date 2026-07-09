import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

import 'package:portal/screens/feed/provider/feed_pop/ad_provider.dart';

class AdComparisonBlockDefinition extends EmmaBlockDefinition {
  const AdComparisonBlockDefinition();

  @override
  String get key => 'advertisement_comparison';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.advertisementComparison;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _AdComparisonBlock(block: block, maxWidth: maxWidth);
  }
}

class _AdComparisonBlock extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _AdComparisonBlock({required this.block, required this.maxWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = block.raw;
    final comparisonRaw = raw['comparison'];
    final items = comparisonRaw is List
        ? comparisonRaw
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList()
        : <Map<String, dynamic>>[];

    const accent = Color(0xFF6EC6A0);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porównanie nieruchomości',
            style: const TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Brak danych do porównania',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _AdComparisonColumn(
                      item: entry.value,
                      index: entry.key,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdComparisonColumn extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const _AdComparisonColumn({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final adRaw = item['ad'];
    final ad = adRaw is Map
        ? Map<String, dynamic>.from(adRaw)
        : <String, dynamic>{};

    final highlights = item['highlights'] is List
        ? (item['highlights'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final slug = (ad['slug'] ?? '').toString();
    final title = (ad['title'] ?? 'Ogłoszenie ${index + 1}').toString();
    final price = (ad['price'] ?? '').toString();
    final currency = (ad['currency'] ?? 'PLN').toString();
    final city = (ad['city'] ?? '').toString();
    final district = (ad['district'] ?? '').toString();
    final rooms = int.tryParse((ad['rooms'] ?? '0').toString()) ?? 0;
    final sqm =
        double.tryParse((ad['square_footage'] ?? '0').toString()) ?? 0.0;
    final floor = int.tryParse((ad['floor'] ?? '0').toString()) ?? 0;
    final totalFloors =
        int.tryParse((ad['total_floors'] ?? '0').toString()) ?? 0;
    final buildYear =
        int.tryParse((ad['build_year'] ?? '0').toString()) ?? 0;

    final featuresRaw = ad['features'];
    final features = featuresRaw is Map
        ? Map<String, dynamic>.from(featuresRaw)
        : <String, dynamic>{};

    const accent = Color(0xFF6EC6A0);
    final columnColors = [
      const Color(0xFF6EC6A0),
      const Color(0xFF6B9EF4),
      const Color(0xFFFF8C69),
      const Color(0xFFD4A5FF),
    ];
    final accentColor = columnColors[index % columnColors.length];

    final locationParts = [
      if (city.isNotEmpty) city,
      if (district.isNotEmpty) district,
    ];

    return Container(
      width: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (price.isNotEmpty) ...[
            Text(
              '$price $currency',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
          ],
          ...[
            if (locationParts.isNotEmpty)
              _row(Icons.location_on_outlined, locationParts.join(', ')),
            if (rooms > 0) _row(Icons.bed_outlined, '$rooms ${'rooms'.tr}'),
            if (sqm > 0)
              _row(Icons.straighten, '${sqm.toStringAsFixed(0)} m²'),
            if (floor > 0 || totalFloors > 0)
              _row(Icons.layers_outlined, '$floor/$totalFloors ${'floor'.tr}'),
            if (buildYear > 0)
              _row(Icons.calendar_today_outlined, '$buildYear'),
            if (features['balcony'] == true)
              _featureBadge('balcony'.tr, accentColor),
            if (features['elevator'] == true)
              _featureBadge('elevator'.tr, accentColor),
            if (features['garage'] == true)
              _featureBadge('garage'.tr, accentColor),
            if (features['garden'] == true)
              _featureBadge('garden'.tr, accentColor),
          ],
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 6),
            ...highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star_outline, size: 10, color: accentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        h,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: slug.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdFetcher(feedAdSlug: slug, tag: 'emma'),
                      ),
                    ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 10, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    'open'.tr,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: Colors.white38),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureBadge(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
