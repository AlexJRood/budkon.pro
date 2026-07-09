// mail/models/email_account_model.dart


class EmailAccount {
  final int id;
  final String emailAddress;

  EmailAccount({
    required this.id,
    required this.emailAddress,
  });

  factory EmailAccount.fromJson(Map<String, dynamic> json) {
    return EmailAccount(
      id: int.tryParse(json['id'].toString()) ?? 0,
      emailAddress: (json['email_address'] ?? '').toString(),
    );
  }
}
