import 'package:core/platform/url.dart';

/// feedback feature API endpoints, decentralized out of core's URLs God-package.
class FeedbackUrls {
  const FeedbackUrls._();

static final feedback = URLs.appendBaseUrl('/feedback/');
static final feedbackProblems = URLs.appendBaseUrl('/feedback/problems/');
}
