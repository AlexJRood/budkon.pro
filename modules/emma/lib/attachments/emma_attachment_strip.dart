import 'package:flutter/material.dart';

import 'emma_attachment.dart';

/// Poziomy pasek miniatur/chipów załączników nad polem wejściowym czatu.
class EmmaAttachmentStrip extends StatelessWidget {
  final List<EmmaAttachment> attachments;
  final void Function(String id) onRemove;

  const EmmaAttachmentStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _AttachmentChip(
          attachment: attachments[i],
          onRemove: () => onRemove(attachments[i].id),
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final EmmaAttachment attachment;
  final VoidCallback onRemove;

  const _AttachmentChip({required this.attachment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    final radius = BorderRadius.circular(10);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Container(
            width: a.isImage ? 60 : 150,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(14),
              borderRadius: radius,
              border: Border.all(
                color: a.hasError
                    ? const Color(0xFFE5484D).withAlpha(150)
                    : Colors.white.withAlpha(30),
              ),
            ),
            child: a.isImage ? _imageContent(a) : _documentContent(a),
          ),
        ),
        if (a.isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                borderRadius: radius,
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(40)),
              ),
              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageContent(EmmaAttachment a) {
    if (a.previewBytes != null) {
      return Image.memory(a.previewBytes!, fit: BoxFit.cover);
    }
    return const Icon(Icons.image_outlined, color: Colors.white54, size: 22);
  }

  Widget _documentContent(EmmaAttachment a) {
    final color = a.hasError ? const Color(0xFFE5484D) : const Color(0xFF9B6BFF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(
            a.hasError ? Icons.error_outline_rounded : Icons.description_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.hasError
                      ? (a.errorText ?? 'Błąd')
                      : a.isReady
                          ? '${((a.chars ?? 0) / 1000).toStringAsFixed(1)}k znaków'
                          : 'Wczytywanie…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(140),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
