class DeviceModel {
  final String registrationId;
  final String type;
  final String name;
  final String user;
  final bool active;
  final String deviceId;

  DeviceModel({
    required this.registrationId,
    required this.type,
    required this.name,
    required this.user,
    required this.active,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'registration_id': registrationId,
        'type': type,
        'name': name,
        'user': user,
        'active': active,
        'device_id': deviceId,
      };

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        registrationId: json['registration_id'] as String,
        type: json['type'] as String,
        name: json['name'] as String,
        user: json['user'] as String,
        active: json['active'] as bool,
        deviceId: json['device_id'] as String,
      );

  DeviceModel copyWith({
    String? registrationId,
    String? type,
    String? name,
    String? user,
    bool? active,
    String? deviceId,
  }) =>
      DeviceModel(
        registrationId: registrationId ?? this.registrationId,
        type: type ?? this.type,
        name: name ?? this.name,
        user: user ?? this.user,
        active: active ?? this.active,
        deviceId: deviceId ?? this.deviceId,
      );
}
