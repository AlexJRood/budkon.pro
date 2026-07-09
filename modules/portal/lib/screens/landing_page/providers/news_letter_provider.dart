// lib/providers/newsletter_provider.dart
import 'package:flutter/material.dart';
import 'package:portal/portal_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import '../../../models/news_letter_subscription_model.dart';
final newsletterProvider = StateNotifierProvider<NewsletterNotifier, AsyncValue<void>>(
      (ref) => NewsletterNotifier(),
);

class NewsletterNotifier extends StateNotifier<AsyncValue<void>> {
  NewsletterNotifier() : super(const AsyncValue.data(null));

  final emailController = TextEditingController();


  Future<void> subscribeToNewsletter({
    required String email,
    required String source,
    required String language,
  }) async {
    state = const AsyncValue.loading();

    final subscription = NewsletterSubscriptionModel(
      email: email.trim(),
      source: source,
      language: language,
    );

    try {
      final response = await ApiServices.post(
        PortalUrls.newsletterSubscribe,
        hasToken: false,
        data: subscription.toJson(),
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        debugPrint('✅ Newsletter subscription successful');
        clearControllers();
        state = const AsyncValue.data(null);
      } else {
        debugPrint('❌ Newsletter subscription failed: ${response?.statusCode} - ${response?.statusMessage}');
        state = AsyncValue.error(
          'Failed to subscribe to newsletter',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception while subscribing to newsletter: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  void clearControllers() {
    emailController.clear();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}