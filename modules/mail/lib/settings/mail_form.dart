import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mail/settings/settings_mail_pc.dart';

/// Controller object for the email account form.
/// Owns TextEditingControllers and FocusNodes and must dispose them.
class EmailAccountFormController {
  final imapHostController = TextEditingController();
  final imapPortController = TextEditingController();
  final smtpHostController = TextEditingController();
  final smtpPortController = TextEditingController();
  final emailController = TextEditingController();
  final emailPasswordController = TextEditingController();
  

  /// Focus nodes used by the custom GradientTextField.
  final List<FocusNode> focusNodes = List.generate(12, (_) => FocusNode());

  void clearAll() {
    imapHostController.clear();
    imapPortController.clear();
    smtpHostController.clear();
    smtpPortController.clear();
    emailController.clear();
    emailPasswordController.clear();
  }

  void dispose() {
    // Dispose focus nodes first
    for (final node in focusNodes) {
      node.dispose();
    }

    // Dispose controllers
    imapHostController.dispose();
    imapPortController.dispose();
    smtpHostController.dispose();
    smtpPortController.dispose();
    emailController.dispose();
    emailPasswordController.dispose();
  }
}

/// AutoDispose so every dialog open gets a fresh controller set.
/// This prevents reusing disposed FocusNodes across dialog lifecycles.
final emailAccountFormProvider =
    Provider.autoDispose<EmailAccountFormController>((ref) {
  final form = EmailAccountFormController();
  ref.onDispose(form.dispose);
  return form;
});
