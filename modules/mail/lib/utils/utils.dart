bool containsHtml(String text) {
  // A simple check: looks for HTML closing tags like </p>, </div>, </br>, etc.
  final htmlTagRegex = RegExp(r"</[a-zA-Z]+>");
  return htmlTagRegex.hasMatch(text);
}

String shortenText(String text, int length) {
  if (text.length <= length) {
    return text;
  }
  return '${text.substring(0, length)} ...';
}
