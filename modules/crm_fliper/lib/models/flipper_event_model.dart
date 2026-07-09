class Client {
  final int id;
  final String name;

  Client({required this.id, required this.name});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class FlipperEvent {
  final int id;
  final int? transaction;
  final Client? client;
  final String title;
  final String? description;
  final String startTime;
  final String endTime;
  final String? location;

  FlipperEvent({
    required this.id,
    this.transaction,
    this.client,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
  });

  factory FlipperEvent.fromJson(Map<String, dynamic> json) {
    return FlipperEvent(
      id: json['id'],
      transaction: json['transaction'],
      client: json['client'] != null ? Client.fromJson(json['client']) : null,
      title: json['title'],
      description: json['description'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction': transaction,
    'client': client?.toJson(),
    'title': title,
    'description': description,
    'start_time': startTime,
    'end_time': endTime,
    'location': location,
  };
}

class FlipperEventResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FlipperEvent> results;

  FlipperEventResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FlipperEventResponse.fromJson(Map<String, dynamic> json) {
    return FlipperEventResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results:
      (json['results'] as List)
          .map((e) => FlipperEvent.fromJson(e))
          .toList(),
    );
  }
}
