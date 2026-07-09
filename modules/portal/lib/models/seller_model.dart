import 'package:core/platform/url.dart';

import 'package:get/get_utils/get_utils.dart';

// Model danych użytkownika (sprzedającego)
class Seller {
  final String userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? avatarUrl;

  const Seller({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.avatarUrl,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    String? avatarPath = json['avatar'];
    String? fullAvatarUrl;

    if (avatarPath != null) {
      if (avatarPath.startsWith('/media/avatars')) {
        fullAvatarUrl = '${URLs.baseUrl}$avatarPath';
      } else {
        fullAvatarUrl = avatarPath.replaceFirst('/media/', '');
      }
    }

    return Seller(
      userId: json['id'].toString(),
      username: json['username'] ?? 'Nieznany',
      email: json['email'] ?? 'brak@email.com',
      firstName: json['first_name'] ?? 'Imię',
      lastName: json['last_name'] ?? 'Nazwisko'.tr,
      phoneNumber: json['phone_number'] ?? 'brak numeru',
      avatarUrl: fullAvatarUrl,
    );
  }
}
