final userDefault = User(
  username: '',
  email: '',
  firstName: '',
  lastName: '',
);

class User {
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;

  User({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map json) {
    final map = Map<String, dynamic>.from(json);

    return User(
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}