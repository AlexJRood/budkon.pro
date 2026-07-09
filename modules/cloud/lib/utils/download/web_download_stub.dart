Future<void> webDownloadUrl(String url, String filename) async => throw UnsupportedError('webDownloadUrl is only supported on Web.');

Future<void> webDownloadBytes(
    List<int> bytes,
    String fileName, {
      String mimeType = 'application/octet-stream',
    }) async {
  throw UnsupportedError('webDownloadBytes is only supported on web');
}