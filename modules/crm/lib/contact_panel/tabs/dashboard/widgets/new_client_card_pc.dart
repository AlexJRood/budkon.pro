import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mail/send_mail/send_mail.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:url_launcher/url_launcher.dart';

class NewClientCardPc extends ConsumerWidget {
  final int id;
  final VoidCallback onTap;
  final String avatar;
  final String name;
  final String lastName;
  final String email;
  final String phoneNumber;

  const NewClientCardPc({
    super.key,
    required this.onTap,
    required this.id,
    required this.avatar,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  bool _isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 800;
  }

  String _cleanPhoneNumber(String value) {
    return value.trim().replaceAll(RegExp(r'[^\d+]'), '');
  }

  void _showSnack(
    BuildContext context,
    String message,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMissingEmailTap(BuildContext context) {
    onTap();

    Future.microtask(() {
      if (!context.mounted) return;
      _showSnack(context, 'Add e-mail in client details'.tr);
    });
  }

  void _handleMissingPhoneTap(BuildContext context) {
    onTap();

    Future.microtask(() {
      if (!context.mounted) return;
      _showSnack(context, 'Add phone number in client details'.tr);
    });
  }

  Future<void> _handleEmailTap(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      _handleMissingEmailTap(context);
      return;
    }

    showEmailOverlay(
      context,
      ref,
      leadId: id,
      initialEmails: [cleanEmail],
    );
  }

  Future<void> _handlePhoneTap(
    BuildContext context,
  ) async {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);

    if (cleanPhone.isEmpty) {
      _handleMissingPhoneTap(context);
      return;
    }

    if (_isMobile(context)) {
      final uri = Uri(
        scheme: 'tel',
        path: cleanPhone,
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showSnack(context, 'Could not open phone app'.tr);
      }

      return;
    }

    await Clipboard.setData(
      ClipboardData(text: cleanPhone),
    );

    if (context.mounted) {
      _showSnack(context, '${'Copied phone number'.tr}: $cleanPhone');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;

    double itemWidth = screenWidth / 1920 * 150;
    itemWidth = max(90.0, min(itemWidth, 135.0));

    final fullName = '$name $lastName'.trim();
    final safeAvatar = avatar.trim();
    final safeEmail = email.trim();
    final safePhoneNumber = phoneNumber.trim();

    final bool hasEmail = safeEmail.isNotEmpty;
    final bool hasPhone = _cleanPhoneNumber(safePhoneNumber).isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenWidth;

        final rawInfoWidth = availableWidth - itemWidth - 20;
        final infoWidth = max(
          180.0,
          min(rawInfoWidth, 620.0),
        );

        final contactTextMaxWidth = max(
          100.0,
          min(infoWidth * 0.48, 260.0),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: itemWidth,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: safeAvatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(safeAvatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: theme.textFieldColor,
                    ),
                    child: safeAvatar.isEmpty
                        ? Icon(
                            Icons.person_outline,
                            color: theme.textColor.withAlpha(160),
                            size: 36,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: infoWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 75),
                    Text(
                      fullName.isEmpty ? 'No name'.tr : fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.interMedium18.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 15,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ContactAction(
                          icon: hasEmail ? Icons.email_outlined : Icons.add,
                          text: hasEmail ? safeEmail : 'Add e-mail'.tr,
                          color: hasEmail ? theme.textColor : theme.themeColor,
                          isMissing: !hasEmail,
                          maxTextWidth: contactTextMaxWidth,
                          onTap: () {
                            _handleEmailTap(context, ref);
                          },
                        ),
                        _ContactAction(
                          icon: hasPhone ? Icons.phone_outlined : Icons.add,
                          text: hasPhone ? safePhoneNumber : 'Add phone'.tr,
                          color: hasPhone ? theme.textColor : theme.themeColor,
                          isMissing: !hasPhone,
                          maxTextWidth: contactTextMaxWidth,
                          onTap: () {
                            _handlePhoneTap(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactAction extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isMissing;
  final double maxTextWidth;
  final VoidCallback onTap;

  const _ContactAction({
    required this.icon,
    required this.text,
    required this.color,
    required this.maxTextWidth,
    required this.onTap,
    this.isMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: isMissing ? 16 : 15,
              ),
              const SizedBox(width: 3),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxTextWidth,
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interLight16.copyWith(
                    fontSize: 12,
                    fontWeight:
                        isMissing ? FontWeight.w600 : FontWeight.normal,
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color.withAlpha(160),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}