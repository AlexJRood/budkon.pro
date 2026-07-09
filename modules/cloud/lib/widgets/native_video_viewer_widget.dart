

import 'package:cloud/providers/providers.dart';
import 'package:cloud/widgets/error_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/lottie.dart';
import 'package:video_player/video_player.dart';

class NativeVideoViewer extends ConsumerWidget {
  final String url;
  const NativeVideoViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(videoViewerProvider(url));

    return asyncState.when(
      loading: () {
        debugPrint('younis _NativeVideoViewer UI => loading');
        return Center(child: AppLottie.loading());
      },
      error: (e, st) {
        debugPrint('younis _NativeVideoViewer UI => error=$e');
        debugPrint('younis _NativeVideoViewer UI => stack=$st');
        return ErrorBox(
          title: 'Podgląd wideo',
          message: e.toString(),
          url: url,
        );
      },
      data: (s) {
        if (!s.isInitialized || !s.controller.value.isInitialized) {
          debugPrint('younis _NativeVideoViewer UI => not initialized yet');
          return Center(child: AppLottie.loading());
        }

        debugPrint(
          'younis _NativeVideoViewer UI => initialized playing=${s.controller.value.isPlaying}',
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: s.controller.value.aspectRatio == 0
                  ? 16 / 9
                  : s.controller.value.aspectRatio,
              child: VideoPlayer(s.controller),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: InkWell(
                onTap: () => ref
                    .read(videoViewerProvider(url).notifier)
                    .togglePlay(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    s.controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
