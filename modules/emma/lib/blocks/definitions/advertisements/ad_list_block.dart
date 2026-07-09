import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

import 'package:portal/screens/feed/provider/feed_pop/ad_provider.dart';

class AdListBlockDefinition extends EmmaBlockDefinition {
  const AdListBlockDefinition();

  @override
  String get key => 'advertisement_list';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.advertisementList;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _AdListBlock(block: block, maxWidth: maxWidth);
  }
}

class _AdListBlock extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _AdListBlock({required this.block, required this.maxWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = block.raw;
    final title = (raw['title'] ?? 'Ogłoszenia').toString();
    final adsRaw = raw['ads'];
    final ads = adsRaw is List
        ? adsRaw.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList()
        : <Map<String, dynamic>>[];

    const accent = Color(0xFF6EC6A0);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (ads.isEmpty)
            const Text(
              'Brak wyników',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ads.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _AdTile(
                  ad: ads[i],
                  onTap: () {
                    final slug = (ads[i]['slug'] ?? '').toString();
                    if (slug.isEmpty) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdFetcher(feedAdSlug: slug, tag: 'emma'),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdTile extends StatelessWidget {
  final Map<String, dynamic> ad;
  final VoidCallback onTap;

  const _AdTile({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (ad['title'] ?? 'Nieruchomość').toString();
    final price = (ad['price'] ?? '').toString();
    final currency = (ad['currency'] ?? 'PLN').toString();
    final city = (ad['city'] ?? '').toString();
    final rooms = int.tryParse((ad['rooms'] ?? '0').toString()) ?? 0;
    final sqm =
        double.tryParse((ad['square_footage'] ?? '0').toString()) ?? 0.0;

    final imagesRaw = ad['images'];
    final images = imagesRaw is List
        ? imagesRaw.map((e) => e.toString()).toList()
        : <String>[];

    const accent = Color(0xFF6EC6A0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: images.isNotEmpty
                  ? Image.network(
                      images.first,
                      height: 80,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.isEmpty ? '—' : '$price $currency',
                    style: const TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (city.isNotEmpty) city,
                      if (rooms > 0) '$rooms ${'rooms'.tr}',
                      if (sqm > 0) '${sqm.toStringAsFixed(0)} m²',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 80,
      width: 160,
      color: Colors.white.withAlpha(8),
      child: const Icon(Icons.home_outlined, size: 24, color: Colors.white24),
    );
  }
}
