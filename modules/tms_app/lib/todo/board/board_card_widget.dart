import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:core/common/extensions/context_extension.dart';

class BoardCardWidget extends StatelessWidget {
  final String title;
  final String imageUrl;
  final int notificationCount;
  final List<String> comments;
  final int id;

  /// Optional runtime anchor.
  /// Use only for a specific card instance, e.g. first visible card,
  /// to avoid multiple widgets registering the same anchor key.
  final String? emmaAnchorKey;

  const BoardCardWidget({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.notificationCount,
    required this.comments,
    required this.id,
    this.emmaAnchorKey,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 440,
      width: 540,
      color: Colors.transparent,
      child: Stack(
        children: [
          Container(
            height: 400,
            margin: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withAlpha(120),
              image: imageUrl.trim().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha((255 * 0.6).toInt()),
                        Colors.black.withAlpha((255 * 0.3).toInt()),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (notificationCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: comments
                        .map(
                          (comment) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    comment,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 30,
            child: Container(
              height: 35,
              width: 25,
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  id.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.isDesktop ? 18 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (emmaAnchorKey == null) {
      return card;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsBoardCardWidgetRoot
      anchorKey: emmaAnchorKey!,
      child: card,
    );
  }
}