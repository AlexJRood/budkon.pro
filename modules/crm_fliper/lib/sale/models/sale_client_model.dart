class SaleClient {
  final int id;
  final int user;
  final String fullName;
  final String email;
  final String phoneNumber;

  SaleClient({
    required this.id,
    required this.user,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory SaleClient.fromJson(Map<String, dynamic> json) {
    return SaleClient(
      id: json['id'] as int,
      user: json['user'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
    );
  }
}
