import 'package:cloud/emma/anchors/anchors_cloud.dart';
import 'package:cloud/buttons/add_folder.dart';
import 'package:cloud/components/drag_n_drop.dart';
import 'package:cloud/models/query_params.dart';
import 'package:cloud/providers/providers.dart';
import 'package:cloud/utils/bread_crumbs.dart';
import 'package:cloud/widgets/content.dart';
import 'package:cloud/widgets/flie_drop.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/provider/cloud_selection_controller.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class CloudExplorer extends ConsumerStatefulWidget {
  final FolderQueryParams? params;
  final bool isClient;
  final bool isMobile;

  /// When true, sizes to its content instead of filling/forcing a bounded
  /// height. Use when embedding inside another scrollable (e.g. a mobile
  /// page that scrolls the explorer together with other widgets as one
  /// list) so there is a single scroll region instead of a nested one.
  final bool shrinkWrap;

  const CloudExplorer({
    super.key,
    this.isMobile = false,
    this.params,
    this.isClient = false,
    this.shrinkWrap = false,
  });

  @override
  ConsumerState<CloudExplorer> createState() => _CloudExplorerState();
}

class _CloudExplorerState extends ConsumerState<CloudExplorer> {
  EmmaUiAnchorSpec get _rootAnchor =>
      widget.isClient
          ? CloudEmmaAnchors.clientExplorerRoot
          : CloudEmmaAnchors.explorerRoot;

  EmmaUiAnchorSpec get _dropZoneAnchor =>
      widget.isClient
          ? CloudEmmaAnchors.clientExplorerDropZone
          : CloudEmmaAnchors.explorerDropZone;

  EmmaUiAnchorSpec get _breadcrumbsAnchor =>
      widget.isClient
          ? CloudEmmaAnchors.clientExplorerBreadcrumbs
          : CloudEmmaAnchors.explorerBreadcrumbs;

  EmmaUiAnchorSpec get _emptyStateAnchor =>
      widget.isClient
          ? CloudEmmaAnchors.clientExplorerEmptyState
          : CloudEmmaAnchors.explorerEmptyState;

  EmmaUiAnchorSpec get _addFolderAnchor =>
      widget.isClient
          ? CloudEmmaAnchors.clientExplorerAddFolderCard
          : CloudEmmaAnchors.explorerAddFolderCard;

  EmmaUiAnchorSpec get _contentAnchor =>
      widget.isClient
          ? CloudEmmaAnchors.clientExplorerContent
          : CloudEmmaAnchors.explorerContent;

  @override
  void initState() {
    super.initState();

    if (widget.isClient && widget.params != null) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(clientExplorerParamsProvider.notifier).state = widget.params!;
      });
    }
  }

  @override
  void didUpdateWidget(covariant CloudExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isClient && widget.params != oldWidget.params) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(clientExplorerParamsProvider.notifier).state = widget.params!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveParams =
        widget.isClient
            ? ref.watch(clientExplorerParamsProvider)
            : ref.watch(cloudExplorerParamsProvider);

    final explorerAsync =
        widget.isClient
            ? ref.watch(clientFileExplorerProvider(effectiveParams))
            : ref.watch(cloudExplorerProvider);

    return EmmaUiAnchorTarget(
      anchorKey: _rootAnchor.anchorKey,
      // @emma-backend: _rootAnchor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight =
              constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : MediaQuery.of(context).size.height;

          Widget wrapDropZone({
            required UploadExtra extra,
            required Widget child,
          }) {
            final dropZone = EmmaUiAnchorTarget(
              anchorKey: _dropZoneAnchor.anchorKey,
              // @emma-backend: _dropZoneAnchor,
              child: UniversalFileDropZone(
                isClient: widget.isClient,
                extra: extra,
                child: child,
              ),
            );

            if (widget.shrinkWrap) {
              return SizedBox(width: double.infinity, child: dropZone);
            }

            return SizedBox(
              width: double.infinity,
              height: minHeight,
              child: dropZone,
            );
          }

          return explorerAsync.when(
            loading:
                () => Center(
                  child: AppLottie.loading(size: widget.isMobile ? 200 : 450),
                ),
            error: (err, _) => Center(child: Text('$Error.tr')),
            data: (explorer) {
              final folders = explorer.subfolders;
              final files = explorer.files;

              final uploadExtra = UploadExtra(
                folderId: effectiveParams.parent,
                appLabel: effectiveParams.appLabel,
                model: effectiveParams.model,
                objectId: effectiveParams.objectId,
                relationType: effectiveParams.relationType,
              );

              if (folders.isEmpty && files.isEmpty) {
                final theme = ref.read(themeColorsProvider);

                final isExplorerMode =
                    effectiveParams.parent != null ||
                    (effectiveParams.fileType?.isNotEmpty ?? false) ||
                    (effectiveParams.isDeleted ?? false) ||
                    (effectiveParams.search?.isNotEmpty ?? false);

                final emptyState = EmmaUiAnchorTarget(
                  anchorKey: _emptyStateAnchor.anchorKey,
                  // @emma-backend: _emptyStateAnchor,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppLottie.fileSearch(),
                        const SizedBox(height: 8),
                        EmmaUiAnchorTarget(
                          anchorKey: _addFolderAnchor.anchorKey,
                          // @emma-backend: _addFolderAnchor,
                          child: SizedBox(
                            width: 250,
                            child: AddFolderCard(
                              isClient: widget.isClient,
                              appLabel: effectiveParams.appLabel,
                              model: effectiveParams.model,
                              objectId: effectiveParams.objectId,
                              relationType: effectiveParams.relationType,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                final breadcrumbs = EmmaUiAnchorTarget(
                  anchorKey: _breadcrumbsAnchor.anchorKey,
                  // @emma-backend: _breadcrumbsAnchor,
                  child: CloudBreadcrumbs(isClient: false),
                );

                return wrapDropZone(
                  extra: uploadExtra,
                  child: widget.shrinkWrap
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            breadcrumbs,
                            SizedBox(height: 240, child: emptyState),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  breadcrumbs,
                                  Expanded(child: emptyState),
                                ],
                              ),
                            ),
                          ],
                        ),
                );
              }

              return wrapDropZone(
                extra: uploadExtra,
                child: Focus(
                  autofocus: true,
                  child: Shortcuts(
                    shortcuts: {
                      LogicalKeySet(LogicalKeyboardKey.escape):
                          const EscapeIntent(),
                    },
                    child: Actions(
                      actions: {
                        EscapeIntent: CallbackAction<EscapeIntent>(
                          onInvoke: (_) {
                            final selState = ref.read(cloudSelectionProvider);
                            if (selState.selectionMode) {
                              ref
                                  .read(cloudSelectionProvider.notifier)
                                  .exitSelectionMode();
                            }
                            return null;
                          },
                        ),
                      },
                      child: EmmaUiAnchorTarget(
                        anchorKey: _contentAnchor.anchorKey,
                        // @emma-backend: _contentAnchor,
                        child: CloudExplorerContent(
                          currentFolder: null,
                          currentFolderId: effectiveParams.parent,
                          contentsAsync: explorerAsync,
                          folders: folders,
                          isClient: widget.isClient,
                          isMobile: widget.isMobile,
                          shrinkWrap: widget.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}