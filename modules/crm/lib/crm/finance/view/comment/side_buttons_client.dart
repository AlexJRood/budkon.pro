import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/navigation_service.dart';

class SideButtonsClient extends StatelessWidget {
  final WidgetRef ref;

  const SideButtonsClient({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IntrinsicWidth(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.popAndPushNamed(
                  context,
                  '/pro/add/client',
                );
              },
              child: AppIcons.add(),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(navigationService)
                    .pushNamedScreen(Routes.proAddClient);
              },
              child: const Icon(Icons.manage_search),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(navigationService)
                    .pushNamedScreen(Routes.proAddClient);
              },
              child: const Icon(Icons.abc),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(navigationService)
                    .pushNamedScreen(Routes.proAddClient);
              },
              child: const Icon(Icons.abc),
            ),
          ],
        ),
      ),
    );
  }
}
