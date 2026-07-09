import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/add_offer/provider/add_offer_provider.dart';
import 'package:core/theme/apptheme.dart';

class OfferImagesUploadStatusBar extends ConsumerWidget {
  final bool compact;
  final bool showWhenComplete;

  const OfferImagesUploadStatusBar({
    super.key,
    this.compact = false,
    this.showWhenComplete = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addOfferProvider);
    final theme = ref.watch(themeColorsProvider);

    if (!state.hasAnyImages) {
      return const SizedBox.shrink();
    }

    if (!showWhenComplete &&
        !state.hasPendingUploads &&
        !state.hasFailedUploads) {
      return const SizedBox.shrink();
    }

    final total = state.totalImagesCount;
    final uploaded = state.uploadedImagesCount;
    final pending = state.pendingUploadsCount;
    final failed = state.failedUploadsCount;
    final progress = state.uploadProgressValue.clamp(0.0, 1.0);

    late final Color accentColor;
    late final IconData icon;
    late final String title;
    late final String subtitle;

if (failed > 0) {
  accentColor = Colors.redAccent;
  icon = Icons.error_outline;
  title = 'photo_upload_requires_attention'.tr;
  subtitle = '$uploaded / $total ${"uploaded".tr} • $failed ${"Failed".tr}';
} else if (pending > 0) {
  accentColor = Colors.orangeAccent;
  icon = Icons.cloud_upload_outlined;
  title = 'uploading_photos_in_background'.tr;
  subtitle = '$uploaded / $total ${"uploaded".tr} • $pending ${"in progress".tr}';
} else {
  accentColor = Colors.greenAccent;
  icon = Icons.check_circle_outline;
  title = 'all_photos_uploaded'.tr;
  subtitle = '$uploaded / $total ${"uploaded".tr}';
}

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withAlpha(85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: compact ? 18 : 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  compact ? subtitle : title,
                  style: TextStyle(
                    color: theme.primaryBackgroundTextColor,
                    fontSize: compact ? 12.5 : 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: theme.primaryBackgroundTextColor,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: compact ? 6 : 8,
              backgroundColor: Colors.white.withAlpha(35),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.primaryBackgroundTextColor.withAlpha(220),
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}