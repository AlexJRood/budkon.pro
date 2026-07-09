
class NewsletterSubscriptionModel {
  final String email;
  final String source;
  final String language;

  NewsletterSubscriptionModel({
    required this.email,
    required this.source,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'source': source,
      'language': language,
    };
  }

  factory NewsletterSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return NewsletterSubscriptionModel(
      email: json['email'],
      source: json['source'],
      language: json['language'],
    );
  }

  @override
  String toString() {
    return '''
NewsletterSubscriptionModel {
  email: $email,
  source: $source,
  language: $language
}
''';
  }
}