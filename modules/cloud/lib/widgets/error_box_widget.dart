
import 'package:cloud/platforms/view_registry_stub.dart'
if (dart.library.html) 'package:cloud/platforms/view_registry_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class ErrorBox extends ConsumerWidget {
  final String title;
  final String message;
  final String url;

  const ErrorBox({
    required this.title,
    required this.message,
    required this.url,
  });

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    debugPrint('younis _ErrorBox build title="$title" message="$message"');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 42, color: Colors.red.shade400),
            const SizedBox(height: 10),
            Text(title, style:  TextStyle(fontSize: 16,color: theme.textColor)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon:  Icon(Icons.open_in_new,color: theme.textColor),
              label: Text('Open in browser'.tr,
              style: TextStyle(
                color: theme.textColor
              ),),
              onPressed: () {
                debugPrint('younis _ErrorBox openInNewTab url=$url');
                openInNewTab(url);
              },
            ),
          ],
        ),
      ),
    );
  }
}
