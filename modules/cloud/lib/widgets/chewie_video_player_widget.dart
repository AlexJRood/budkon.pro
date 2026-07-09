

import 'package:chewie/chewie.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/widgets/error_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';

class ChewieVideoPlayer extends ConsumerWidget {
  final String url;
  const ChewieVideoPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(chewieVideoProvider(url));

    return asyncState.when(
      loading: () {
        debugPrint('younis chewie UI => loading');
        return Center(child: AppLottie.loading());
      },
      error: (e, st) {
        debugPrint('Video error: $e');

        return ErrorBox(
          title: 'video_preview'.tr,
          message: 'Cannot play video. Try downloading instead.',
          url: url,
        );
      },
      data: (s) {
        debugPrint('younis chewie UI => show');
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Chewie(controller: s.chewie),
        );
      },
    );
  }
}
