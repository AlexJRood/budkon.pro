import 'package:flutter_quill/flutter_quill.dart';

class StyleExtractor {
  static Map<String, dynamic> extractStyle(QuillController controller) {
    final attrs = controller.getSelectionStyle().attributes;

    final Map<String, dynamic> style = {};
    for (final entry in attrs.entries) {
      style[entry.key] = entry.value.value;
    }

    return style;
  }
}
