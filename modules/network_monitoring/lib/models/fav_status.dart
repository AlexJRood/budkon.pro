// ---- Favorite meta (opcjonalne) ----


num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) {
    final s = v.replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(',', '.').trim();
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }
  return null;
}


int? _asInt(dynamic v) => _asNum(v)?.toInt();
String? _asString(dynamic v) => v == null ? null : v.toString();





class FavStatusRef {
  final int id;
  final String label;
  const FavStatusRef({required this.id, required this.label});

  factory FavStatusRef.fromJson(Map<String, dynamic> j) {
    return FavStatusRef(
      id: _asInt(j['id']) ?? 0,
      label: _asString(j['label']) ?? '',
    );
  }
}

class FavoriteTxLink {
  final int transactionId;
  final FavStatusRef? status;
  final String? note;
  final DateTime? createdAt;

  const FavoriteTxLink({
    required this.transactionId,
    this.status,
    this.note,
    this.createdAt,
  });

  factory FavoriteTxLink.fromJson(Map<String, dynamic> j) {
    FavStatusRef? st;
    final rawStatus = j['status'];
    if (rawStatus is Map<String, dynamic>) {
      st = FavStatusRef.fromJson(rawStatus);
    }
    DateTime? dt;
    final rawDt = j['created_at'];
    if (rawDt is String) {
      dt = DateTime.tryParse(rawDt);
    }
    return FavoriteTxLink(
      transactionId: _asInt(j['transaction_id']) ?? 0,
      status: st,
      note: _asString(j['note']),
      createdAt: dt,
    );
  }
}

class FavoriteMeta {
  final int favoriteId;
  final int? clientId;
  final int? boardId;
  final int? savedSearchId;
  final FavStatusRef? status;      // status „scope’owy”: global/client/board
  final DateTime? addedAt;
  final List<FavoriteTxLink> transactions;

  const FavoriteMeta({
    required this.favoriteId,
    this.clientId,
    this.boardId,
    this.savedSearchId,
    this.status,
    this.addedAt,
    this.transactions = const [],
  });

  factory FavoriteMeta.fromJson(Map<String, dynamic> j) {
    FavStatusRef? st;
    final rawStatus = j['status'];
    if (rawStatus is Map<String, dynamic>) {
      st = FavStatusRef.fromJson(rawStatus);
    }
    DateTime? added;
    final rawAdded = j['added_at'];
    if (rawAdded is String) {
      added = DateTime.tryParse(rawAdded);
    }

    final txRaw = j['transactions'];
    final List<FavoriteTxLink> tx = [];
    if (txRaw is List) {
      for (final item in txRaw) {
        if (item is Map<String, dynamic>) {
          tx.add(FavoriteTxLink.fromJson(item));
        }
      }
    }

    return FavoriteMeta(
      favoriteId: _asInt(j['favorite_id']) ?? 0,
      clientId: _asInt(j['client_id']),
      boardId: _asInt(j['board_id']),
      savedSearchId: _asInt(j['saved_search_id']),
      status: st,
      addedAt: added,
      transactions: tx,
    );
  }
}
