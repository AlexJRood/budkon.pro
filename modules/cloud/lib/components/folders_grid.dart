
import 'package:cloud/buttons/add_folder.dart';
import 'package:cloud/cards/folder_card.dart';
import 'package:cloud/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud/models/folder.dart';
import "package:cloud/api/move.dart";
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

final singleFolderProvider = Provider.family<CloudFolder?, String>((ref, id) {
  final explorer = ref.watch(cloudExplorerProvider).asData?.value;
  final folders = explorer?.subfolders ?? [];
  try {
    return folders.firstWhere((f) => f.id == id);
  } catch (_) {
    return null;
  }
});

// class FolderCard extends ConsumerWidget {
//   final String id;
//   final void Function(CloudFile file)? onFileDropped;
//   final void Function(CloudFolder movedFolder)? onFolderDropped;

//   const FolderCard({
//     super.key,
//     required this.id,
//     this.onFileDropped,
//     this.onFolderDropped,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = ref.read(themeColorsProvider);
//     final bool isMobile = MediaQuery.of(context).size.width < 600;

//     final folder = ref.watch(singleFolderProvider(id));
//     if (folder == null) return const SizedBox();

//   final explorer = ref.watch(cloudExplorerProvider).asData?.value;
//   final folders = explorer?.subfolders ?? [];

//     return PieMenu(
//       onPressedWithDevice: (kind) {
//         if (kind == PointerDeviceKind.mouse ||
//             kind == PointerDeviceKind.touch) {
//         }
//       },
//         child: DragTarget<Object>(
//         onWillAccept: (data) {
//           if (data is CloudFile) return data.folderId != folder.id;
//           if (data is CloudFolder) {
//             final target = folders.firstWhere(
//               (f) => f.id == folder.id,
//               orElse: () => folder,
//             );
//             final isRejected = isDescendant(data, target, folders);
//             return !isRejected;
//           }
//           return false;
//         },
//         onAccept: (data) {
//           if (data is CloudFile && onFileDropped != null) onFileDropped!(data);
//           if (data is CloudFolder && onFolderDropped != null)
//             onFolderDropped!(data);
//         },
//         builder: (context, candidateData, rejectedData) =>
//           Draggable<CloudFolder>(
//             data: folder,
//             feedback: Material(
//               color: Colors.transparent,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.amber.withAlpha(230),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: theme.dashboardBoarder,
//                     width: 2,
//                   ),
//                   boxShadow: const [
//                     BoxShadow(color: Colors.black26, blurRadius: 8),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     AppIcons.folder(color: theme.textColor),
//                     const SizedBox(width: 10),
//                     Text(
//                       folder.name,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             childWhenDragging: Opacity(
//               opacity: 0.5,
//               child: _folderCardInner(isMobile, theme, folder, isHovered: false),
//             ),
//             child: _folderCardInner(
//               isMobile,
//               theme,
//               folder,
//               isHovered: candidateData.isNotEmpty,
//               onTap: () {
//                 // ------ TU OTWIERASZ FOLDER! ------
//                 // Breadcrumbs logic
//                 final currentPath = ref.read(selectedFolderPathProvider);
//                 int alreadyInPath = currentPath.indexWhere((f) => f.id == folder.id);
//                 if (alreadyInPath != -1) {
//                   ref.read(selectedFolderPathProvider.notifier).state =
//                       currentPath.sublist(0, alreadyInPath + 1);
//                 } else {
//                   ref.read(selectedFolderPathProvider.notifier).state = [
//                     ...currentPath,
//                     folder,
//                   ];
//                 }
//                 // Explorer update!
//                 ref.read(cloudExplorerParamsProvider.notifier).state =
//                     ref.read(cloudExplorerParamsProvider.notifier).state.copyWith(parent: folder.id);
//               },
//             ),
//           ),
//             ),
//       );
//   }

//   Widget _folderCardInner(
//     bool isMobile,
//     ThemeColors theme,
//     CloudFolder folder, {
//     bool isHovered = false,
//     VoidCallback? onTap,
//   }) => Card(
//     color: isHovered ? theme.dashboardBoarder : theme.dashboardContainer,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(10),
//       side: BorderSide(color: theme.dashboardBoarder, width: isHovered ? 3 : 2),
//     ),
//     elevation: isHovered ? 2 : 0,
//     child: InkWell(
//       borderRadius: BorderRadius.circular(10),
//       onTap: onTap,
//       child: SizedBox(
//         width: 220,
//         height: 64,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               AppIcons.folder(color: theme.textColor),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   folder.name,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: theme.textColor,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               if (!isMobile)
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: theme.dashboardBoarder,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     folder.filesCount.toString(),
//                     style: TextStyle(
//                       color: theme.textColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               const SizedBox(width: 6),
//               Icon(Icons.more_vert, color: theme.textColor),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

class FoldersGridConnected extends ConsumerWidget {
  const FoldersGridConnected({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerAsync = ref.watch(cloudExplorerProvider);
    return explorerAsync.when(
      loading: () => Center(child: AppLottie.loading(size: 450)),
      error: (err, stack) => Center(child: AddFolderCard()),
      data: (explorer) {
        final folders = explorer.subfolders;
        if (folders.isEmpty) {
          return Center(child: AddFolderCard());
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isMobile = MediaQuery.of(context).size.width < 600;
            final int crossAxisCount =
                isMobile ? 2 : (width ~/ 240).clamp(2, 8);
            final double spacing = isMobile ? 0 : 12;
            final double tileHeight = 70;
            final double tileWidth = width / crossAxisCount - spacing;
            final double childAspectRatio = tileWidth / tileHeight;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ...folders.map(
                  (folder) => SizedBox(
                    height: tileHeight,
                    child: FolderCard(
                      name: folder.name,
                      folder: folder,
                      count: folder.filesCount!,
                      allFolders: folders,
                      id: folder.id,
                      onFileDropped:
                          (file) =>
                              moveFileToFolder(ref, file, folder),
                      onFolderDropped:
                          (movedFolder) => moveFolderToFolder(
                            ref,
                            movedFolder,
                            folder,
                          ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class FoldersSection extends ConsumerWidget {
  const FoldersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Górny pasek z nagłówkiem, opisem i przyciskiem
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Teksty po lewej
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Folders".tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Documents that you save on our storage".tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textColor.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48, child: AddFolderCard()),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid z folderami
        const FoldersGridConnected(),
      ],
    );
  }
}
