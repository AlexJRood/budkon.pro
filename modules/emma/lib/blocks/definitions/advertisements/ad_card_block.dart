import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

import 'package:portal/screens/feed/provider/feed_pop/ad_provider.dart';

class AdCardBlockDefinition extends EmmaBlockDefinition {
  const AdCardBlockDefinition();

  @override
  String get key => 'advertisement_card';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.advertisementCard;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _AdCardBlock(block: block, maxWidth: maxWidth);
  }
}

class _AdCardPayload {
  final Map<String, dynamic> ad;
  final String slug;
  final String title;
  final String price;
  final String currency;
  final String city;
  final String district;
  final int rooms;
  final double sqm;
  final int floor;
  final int totalFloors;
  final Map<String, dynamic> features;
  final List<String> images;
  final bool isPremium;

  const _AdCardPayload({
    required this.ad,
    required this.slug,
    required this.title,
    required this.price,
    required this.currency,
    required this.city,
    required this.district,
    required this.rooms,
    required this.sqm,
    required this.floor,
    required this.totalFloors,
    required this.features,
    required this.images,
    required this.isPremium,
  });

  factory _AdCardPayload.fromBlock(EmmaBlockDescriptor block) {
    final raw = block.raw;
    final ad = raw['ad'] is Map
        ? Map<String, dynamic>.from(raw['ad'] as Map)
        : <String, dynamic>{};

    final featuresRaw = ad['features'];
    final features = featuresRaw is Map
        ? Map<String, dynamic>.from(featuresRaw)
        : <String, dynamic>{};

    final imagesRaw = ad['images'];
    final images = imagesRaw is List
        ? imagesRaw.map((e) => e.toString()).toList()
        : <String>[];

    return _AdCardPayload(
      ad: ad,
      slug: (ad['slug'] ?? '').toString(),
      title: (ad['title'] ?? 'Nieruchomość').toString(),
      price: (ad['price'] ?? '').toString(),
      currency: (ad['currency'] ?? 'PLN').toString(),
      city: (ad['city'] ?? '').toString(),
      district: (ad['district'] ?? '').toString(),
      rooms: int.tryParse((ad['rooms'] ?? '0').toString()) ?? 0,
      sqm: double.tryParse((ad['square_footage'] ?? '0').toString()) ?? 0,
      floor: int.tryParse((ad['floor'] ?? '0').toString()) ?? 0,
      totalFloors: int.tryParse((ad['total_floors'] ?? '0').toString()) ?? 0,
      features: features,
      images: images,
      isPremium: ad['is_premium'] == true,
    );
  }
}

class _AdCardBlock extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _AdCardBlock({required this.block, required this.maxWidth});

  void _openAd(BuildContext context, String slug) {
    if (slug.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdFetcher(feedAdSlug: slug, tag: 'emma'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = _AdCardPayload.fromBlock(block);
    const accent = Color(0xFF6EC6A0);

    final locationParts = [
      if (p.city.isNotEmpty) p.city,
      if (p.district.isNotEmpty) p.district,
    ];
    final location = locationParts.join(', ');

    final floorInfo = p.floor > 0 || p.totalFloors > 0
        ? '${p.floor}/${p.totalFloors} ${'floor'.tr}'
        : '';

    final activeFeatures = <String>[];
    if (p.features['balcony'] == true) activeFeatures.add('balcony'.tr);
    if (p.features['garage'] == true) activeFeatures.add('garage'.tr);
    if (p.features['elevator'] == true) activeFeatures.add('elevator'.tr);
    if (p.features['garden'] == true) activeFeatures.add('garden'.tr);
    if (p.features['parking_space'] == true) activeFeatures.add('parking'.tr);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: p.isPremium ? const Color(0xFFFFD700) : accent,
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image or placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: p.images.isNotEmpty
                ? Image.network(
                    p.images.first,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium badge + price
                Row(
                  children: [
                    if (p.isPremium) ...[
                      EmmaTag(
                        label: 'Premium',
                        color: const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        p.price.isEmpty
                            ? '—'
                            : '${_formatPrice(p.price)} ${p.currency}',
                        style: const TextStyle(
                          color: Color(0xFF6EC6A0),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Stats row
                Wrap(
                  spacing: 10,
                  children: [
                    if (p.rooms > 0)
                      _stat(Icons.bed_outlined, '${p.rooms} ${'rooms'.tr}'),
                    if (p.sqm > 0)
                      _stat(Icons.straighten,
                          '${p.sqm.toStringAsFixed(0)} m²'),
                    if (floorInfo.isNotEmpty)
                      _stat(Icons.layers_outlined, floorInfo),
                  ],
                ),
                if (activeFeatures.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: activeFeatures
                        .map((f) => EmmaTag(label: f, color: accent))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    EmmaActionPill(
                      label: 'open'.tr,
                      icon: Icons.open_in_new,
                      onTap: p.slug.isNotEmpty
                          ? () => _openAd(context, p.slug)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.white.withAlpha(8),
      child: const Icon(Icons.home_outlined, size: 36, color: Colors.white24),
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  String _formatPrice(String raw) {
    final n = double.tryParse(raw);
    if (n == null) return raw;
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(2)} mln';
    }
    if (n >= 1000) {
      final thousands = (n / 1000).toStringAsFixed(0);
      return '${thousands} tys.';
    }
    return n.toStringAsFixed(0);
  }
}
