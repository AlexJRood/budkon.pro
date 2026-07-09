// lib/utils/link_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:core/platform/navigation_service.dart';

class LinkHandler {
  static bool isInternalLink(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      return host.endsWith('hously.pro') || host.endsWith('hously.ai');
    } catch (_) {
      return false;
    }
  }

  static void handleLinkPress(
      String url,
      WidgetRef ref,
      BuildContext context, {
        bool fromDisposableWidget = false,
      }) {
    // Check if context is still valid
    if (!context.mounted) return;

    try {
      final uri = Uri.parse(url);

      if (isInternalLink(url)) {
        // Extract the path and query parameters
        String path = uri.path;
        if (path.isEmpty) {
          path = '/';
        }

        // If there are query parameters, append them
        if (uri.query.isNotEmpty) {
          path = '$path?${uri.query}';
        }

        debugPrint('Navigating to internal path: $path');

        // Store the path in a variable to avoid closure issues
        final targetPath = path;

        // FIX: Use a more robust approach - check if we can safely access ref
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          try {
            // Try to check if the provider scope is still valid
            // We'll use a try-catch specifically for the ref access
            final navigationServices = ref.read(navigationService);
            navigationServices.pushNamedScreen(targetPath);
          } catch (e) {
            // If we get a provider error, log it
            debugPrint('Navigation error - provider might be disposed: $e');

            // Alternative: try to use GoRouter or Navigator directly
            // if you have a global navigator key
            if (context.mounted) {
              // Fallback to direct navigation if possible
              Navigator.of(context).pushNamed(targetPath);
            }
          }
        });
      } else {
        // External links open in browser
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error handling link: $e');
    }
  }

  static void copyLinkToClipboard(String url, BuildContext context) {
    Clipboard.setData(ClipboardData(text: url));

    // Check if context is mounted before showing snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link skopiowany do schowka'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }
}

// Update the buildLinkPieActions function
List<PieAction> buildLinkPieActions({
  required String url,
  required WidgetRef ref,
  required BuildContext context,
  required ThemeColors theme,
}) {
  return [
    PieAction(
      tooltip: Text(
        'open_link'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () {
        // Store values before any async operations
        final urlToHandle = url;
        final localRef = ref;

        // Use post frame callback to avoid build phase issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          // Small delay to ensure we're out of build phase
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!context.mounted) return;

            LinkHandler.handleLinkPress(
              urlToHandle,
              localRef,
              context,
            );
          });
        });
      },
      child: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare),
    ),
    PieAction(
      tooltip: Text(
        'Copy link'.tr,
        style: TextStyle(color: theme.textColor),
      ),
      onSelect: () => LinkHandler.copyLinkToClipboard(url, context),
      child: const FaIcon(FontAwesomeIcons.copy),
    ),
  ];
}