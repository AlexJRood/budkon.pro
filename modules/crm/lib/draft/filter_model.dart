class DraftAdFilter {
  String? title;
  String? city;
  String? status;
  double? priceMin;
  double? priceMax;
  int? rooms;
  bool? balcony;
  bool? elevator;

  DraftAdFilter({
    this.title,
    this.city,
    this.status,
    this.priceMin,
    this.priceMax,
    this.rooms,
    this.balcony,
    this.elevator,
  });

  /// Zamienia na query do URL (tylko wypełnione)
  Map<String, String> toQueryParams() {
    final map = <String, String>{};
    if (title != null && title!.isNotEmpty) map['title'] = title!;
    if (city != null && city!.isNotEmpty) map['city'] = city!;
    if (status != null && status!.isNotEmpty) map['status'] = status!;
    if (priceMin != null) map['price_min'] = priceMin!.toString(); // django-filter domyślnie _0, _1
    if (priceMax != null) map['price_max'] = priceMax!.toString();
    if (rooms != null) map['rooms'] = rooms.toString();
    if (balcony != null) map['balcony'] = balcony.toString();
    if (elevator != null) map['elevator'] = elevator.toString();
    return map;
  }
}
