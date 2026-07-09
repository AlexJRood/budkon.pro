
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/material.dart';

class TimeStampEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'timeStamp';

  @override
  String toPlainText(Embed node) {
    final data = node.value.data;
    if (data == null) return '';
    return data.toString();
  }

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    try {
      final data = embedContext.node.value.data;
      if (data == null) {
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 16),
            SizedBox(width: 4),
            Text('Invalid timestamp'),
          ],
        );
      }

      final text = data.toString();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 16),
          const SizedBox(width: 4),
          Text(text.isEmpty ? 'N/A' : text),
        ],
      );
    } catch (e) {
      debugPrint('Error building timestamp embed: $e');
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, size: 16),
          SizedBox(width: 4),
          Text('Error'),
        ],
      );
    }
  }
}
