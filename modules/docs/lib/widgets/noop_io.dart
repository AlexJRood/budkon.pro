// modules/docs/lib/widgets/noop_io.dart
// Kompiluje się WYŁĄCZNIE na Web dzięki warunkowemu importowi
class File {
  final String path;
  File(this.path);

  // zwracamy this, żeby ewentualny kod łańcuchowy się nie wysypał
  Future<File> writeAsBytes(List<int> _, {bool flush = false}) async => this;
}
