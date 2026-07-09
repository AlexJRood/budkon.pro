


// lib/importer/tabs/mapping/enum.dart

/// Tryb wyjścia z regexa
enum OutputMode {
  replaceSource,   // nadpisz kolumnę źródłową
  newColumn,       // nowa kolumna
  existingColumn,  // istniejąca kolumna
}

/// Strategia konfliktów przy istniejącej kolumnie
enum ConflictStrategy {
  overwriteAll,    // zastąp wszystkie wartości
  keepExisting,    // uzupełnij tylko puste
}

enum MapperViewMode {
  list,
  canvas,
}