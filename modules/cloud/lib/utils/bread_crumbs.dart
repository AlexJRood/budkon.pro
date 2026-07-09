import 'package:cloud/models/folder.dart';
import 'package:cloud/models/query_params.dart';
import 'package:cloud/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';





List<CloudFolder> buildPathToRoot(List<CloudFolder> allFolders, String? folderId) {
  final path = <CloudFolder>[];
  String? currentId = folderId;
  while (currentId != null) {
    final foundOpt = allFolders.where((f) => f.id == currentId);
    if (foundOpt.isEmpty) break;
    final found = foundOpt.first;
    path.insert(0, found);
    currentId = found.parent;
  }
  return path;
}

class CloudBreadcrumbs extends ConsumerWidget {
  final bool isClient;
  const CloudBreadcrumbs({super.key, this.isClient = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    final explorerParams = isClient
        ? ref.watch(clientExplorerParamsProvider)
        : ref.watch(cloudExplorerParamsProvider);

    final breadcrumbs = isClient
        ? ref.watch(clientBreadcrumbsProvider)
        : ref.watch(breadcrumbsProvider);

    // Przycisk cofania: cofaj zawsze do parent ostatniego folderu,
    // jeśli tylko jeden w breadcrumbs – cofnij do root!
    Widget? backButton;
    if (breadcrumbs.isNotEmpty) {
      backButton = SizedBox(
        height: 40,
        width: 40,
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10withoutPadding,
          onPressed: () {
            if (breadcrumbs.length == 1) {
              if (isClient) {
                ref.read(clientExplorerParamsProvider.notifier).state = explorerParams.copyWith(parent: null);
              } else {
                ref.read(cloudExplorerParamsProvider.notifier).state = FolderQueryParams();
              }
            } else if (breadcrumbs.length > 1) {
              final newParent = breadcrumbs[breadcrumbs.length - 2].id;
              if (isClient) {
                ref.read(clientExplorerParamsProvider.notifier).state =
                  explorerParams.copyWith(parent: newParent);
              } else {
                ref.read(cloudExplorerParamsProvider.notifier).state =
                  explorerParams.copyWith(parent: newParent, fileType: null, isDeleted: false);
              }
            }
          },
          child: SizedBox(
            height: 25,
            width: 25,
            child: AppIcons.iosArrowLeft(color: theme.textColor),
          ),
        ),
      );
    }

    // Breadcrumbs: root + wszystkie foldery
    List<Widget> crumbs = [
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (isClient) {
              ref.read(clientExplorerParamsProvider.notifier).state = explorerParams.copyWith(parent: null);
            } else {
              ref.read(cloudExplorerParamsProvider.notifier).state = FolderQueryParams();
            }
          },
          child: Text(
            rootFolder.name,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ];

    for (int i = 0; i < breadcrumbs.length; i++) {
      final folder = breadcrumbs[i];
      crumbs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(Icons.chevron_right, size: 18, color: theme.textColor),
        ),
      );
      crumbs.add(
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (isClient) {
                ref.read(clientExplorerParamsProvider.notifier).state =
                  explorerParams.copyWith(parent: folder.id);
              } else {
                ref.read(cloudExplorerParamsProvider.notifier).state =
                  explorerParams.copyWith(parent: folder.id, fileType: null, isDeleted: false);
              }
            },
            child: Text(
              folder.name,
              style: TextStyle(
                color: i == breadcrumbs.length - 1
                    ? theme.textColor
                    : theme.textColor.withAlpha(204),
                fontWeight: i == breadcrumbs.length - 1
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (backButton != null) ...[
          backButton,
          const SizedBox(width: 8),
        ],
        ...crumbs,
      ],
    );
  }
}
