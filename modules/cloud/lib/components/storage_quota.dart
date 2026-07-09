import 'package:cloud/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class StorageQuotaWidget extends ConsumerWidget {
  final double used;
  final double total;

  const StorageQuotaWidget({
    super.key,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final fraction = (used / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'Storage'.tr}: ${used.toStringAsFixed(2)} GB ${'used from'.tr} ${total.toStringAsFixed(0)} GB',
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final usedWidth = totalWidth * fraction;
            final compressedWidth = usedWidth * 0.45;
            final imagesWidth = usedWidth * 0.35;
            final othersWidth = usedWidth - compressedWidth - imagesWidth;

            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (compressedWidth > 0)
                      Container(width: compressedWidth, color: Colors.blue),
                    if (imagesWidth > 0)
                      Container(width: imagesWidth, color: Colors.lightGreen),
                    if (othersWidth > 0)
                      Container(width: othersWidth, color: Colors.teal),
                    Expanded(
                      child: Container(color: theme.textColor.withAlpha(30)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 16,
              height: 4,
              color: Colors.blue,
              margin: const EdgeInsets.only(right: 4),
            ),
            Text(
              'Sprężony',
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
              ),
            ),
            Container(
              width: 16,
              height: 4,
              color: Colors.lightGreen,
              margin: const EdgeInsets.fromLTRB(8, 0, 4, 0),
            ),
            Text(
              'Obrazy',
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
              ),
            ),
            Container(
              width: 16,
              height: 4,
              color: Colors.teal,
              margin: const EdgeInsets.fromLTRB(8, 0, 4, 0),
            ),
            Text(
              'Inni',
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StorageQuotaWidgetConnected extends ConsumerWidget {
  const StorageQuotaWidgetConnected({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final storageQuotaAsync = ref.watch(storageQuotaProvider);

    return storageQuotaAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Text(
        '${'Error loading quota:'.tr} $err',
        style: TextStyle(color: theme.textColor),
      ),
      data: (quota) {
        final usedGB = quota.usedBytes / (1024 * 1024 * 1024);
        final totalGB = quota.quotaBytes / (1024 * 1024 * 1024);
        return StorageQuotaWidget(used: usedGB, total: totalGB);
      },
    );
  }
}
