import 'dart:typed_data';

import 'package:crm/data/add_field/edit_sell_offer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

class Thumbnails extends ConsumerWidget {
  const Thumbnails({
    super.key,
    required this.adId,
    required this.isEditing,
    required this.serverUrls,
    required this.localImages,
    required this.onServerTap,
    required this.onLocalTap,
    this.onServerRemove,
    this.onLocalRemove,
    this.onAddTap,
    this.showAddTile = true,
    this.showDeleteButtons = true,
  });

  final int adId;
  final bool isEditing;
  final List<String> serverUrls;
  final List<Uint8List> localImages;
  final void Function(String url) onServerTap;
  final void Function(int localIndex) onLocalTap;

  /// Optional adapter callback for removing a server image.
  /// If null, old CRM behavior is used.
  final Future<bool> Function(int serverIndex, String url)? onServerRemove;

  /// Optional adapter callback for removing a local image.
  /// If null, old CRM behavior is used.
  final void Function(int localIndex)? onLocalRemove;

  /// Optional adapter callback for adding images.
  /// If null, old CRM behavior is used.
  final Future<void> Function()? onAddTap;

  final bool showAddTile;
  final bool showDeleteButtons;

  Future<bool> _defaultRemoveServer(
    WidgetRef ref,
    BuildContext context,
    int index,
  ) async {
    final prov = crmEditSellOfferProvider(adId);

    final ok = await ref.read(prov.notifier).removeServerImageAt(index);
    final newUrls = ref.read(prov).serverImageUrls;

    final mainProv = adMainImageUrlProvider(adId).notifier;
    final currentMain = ref.read(adMainImageUrlProvider(adId));

    if (!newUrls.contains(currentMain)) {
      ref.read(mainProv).state = newUrls.isNotEmpty ? newUrls.first : '';
    }

    return ok;
  }

  void _defaultRemoveLocal(
    WidgetRef ref,
    int index,
  ) {
    ref.read(crmEditSellOfferProvider(adId).notifier).removeImage(index);
  }

  Future<void> _defaultAdd(
    WidgetRef ref,
  ) async {
    await ref.read(crmEditSellOfferProvider(adId).notifier).pickImage();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isEditing) {
      final totalCount = serverUrls.length + localImages.length;

      return Row(
        children: [
          Expanded(
            child: ListView.builder(
              key: const PageStorageKey('edit_thumbs'),
              addAutomaticKeepAlives: false,
              cacheExtent: 300.0,
              scrollDirection: Axis.horizontal,
              itemCount: totalCount,
              itemBuilder: (context, index) {
                final isServer = index < serverUrls.length;
                final bool isLast = index == totalCount - 1;

                final EdgeInsets pad = EdgeInsets.only(
                  left: index == 0 ? 0 : 10.0,
                  right: isLast ? 0 : 10.0,
                );

                if (isServer) {
                  final url = serverUrls[index];

                  return Padding(
                    key: ValueKey('server_$url'),
                    padding: pad,
                    child: _ThumbTile(
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(
                            child: InkWell(
                              onTap: () => onServerTap(url),
                              child: Image.network(
                                url,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const ThumbFallback(),
                              ),
                            ),
                          ),
                          if (showDeleteButtons)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () async {
                                  final ok = onServerRemove != null
                                      ? await onServerRemove!(index, url)
                                      : await _defaultRemoveServer(
                                          ref,
                                          context,
                                          index,
                                        );

                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..removeCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'failed_to_delete_photo'.tr,
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                  }
                                },
                                child: _DeleteBadge(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final localIndex = index - serverUrls.length;
                final bytes = localImages[localIndex];

                return Padding(
                  key: ValueKey('local_${localIndex}_${bytes.hashCode}'),
                  padding: pad,
                  child: _ThumbTile(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: InkWell(
                            onTap: () => onLocalTap(localIndex),
                            child: Image.memory(
                              bytes,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const ThumbFallback(),
                            ),
                          ),
                        ),
                        if (showDeleteButtons)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () {
                                if (onLocalRemove != null) {
                                  onLocalRemove!(localIndex);
                                } else {
                                  _defaultRemoveLocal(ref, localIndex);
                                }
                              },
                              child: _DeleteBadge(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (showAddTile) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              height: 120,
              child: InkWell(
                onTap: () async {
                  if (onAddTap != null) {
                    await onAddTap!();
                  } else {
                    await _defaultAdd(ref);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.light25,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dark),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: AppColors.dark, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.builder(
      addAutomaticKeepAlives: false,
      cacheExtent: 300.0,
      scrollDirection: Axis.horizontal,
      itemCount: serverUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = serverUrls[index];
        final bool isLast = index == serverUrls.length - 1;

        return GestureDetector(
          onTap: () =>
              ref.read(adMainImageUrlProvider(adId).notifier).state = imageUrl,
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 10.0,
              right: isLast ? 0 : 10.0,
            ),
            child: _ThumbTile(
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ThumbFallback(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}

class _DeleteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppIcons.delete(color: Colors.white),
    );
  }
}

class ThumbFallback extends StatelessWidget {
  const ThumbFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      color: AppColors.light25,
      child: Center(child: AppLottie.noResults()),
    );
  }
}