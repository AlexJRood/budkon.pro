import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floor_plan/providers/floor_plan_api_service.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'dart:async';

class FloorPlanProjectsPage extends ConsumerWidget {
  final String? targetObjectId;
  final String? targetAppLabel;
  final String? targetModel;
  final String title;

  FloorPlanProjectsPage({
    super.key,
    this.targetObjectId,
    this.targetAppLabel,
    this.targetModel,
    this.title = 'Plany nieruchomości',
  });

  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isChildExpanded: true,
      enableScrool: true,
      // isTopAppBarHoveroverUI: true,
      isTopAppBarOff: true,
      isTopAppBarOffMobile: false,
      isTopAppBarHoveroverUI: false,
      
      isBottomBarOff: true,
      layoutTypePc: LayoutTypePc.stack,
      layoutTypeTablet: LayoutTypeTablet.stack,
      layoutTypeMobile: LayoutTypeMobile.stack,
      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      childPc: FloorPlanProjectsConnectedView(
        targetObjectId: targetObjectId,
        targetAppLabel: targetAppLabel,
        targetModel: targetModel,
        title: title,
      ),
      childTablet: FloorPlanProjectsConnectedView(
        targetObjectId: targetObjectId,
        targetAppLabel: targetAppLabel,
        targetModel: targetModel,
        title: title,
      ),
      childMobile: Builder(
        builder: (context) {
          final topPadding = TopAppBarSize.resolve(context) - 60;
          return Column(
            children: [
              SizedBox(height: topPadding),
              Expanded(
                child: FloorPlanProjectsConnectedView(
                  targetObjectId: targetObjectId,
                  targetAppLabel: targetAppLabel,
                  targetModel: targetModel,
                  title: title,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FloorPlanProjectsConnectedView extends ConsumerStatefulWidget {
  final String? targetObjectId;
  final String? targetAppLabel;
  final String? targetModel;
  final String title;

  const FloorPlanProjectsConnectedView({
    super.key,
    this.targetObjectId,
    this.targetAppLabel,
    this.targetModel,
    required this.title,
  });

  @override
  ConsumerState<FloorPlanProjectsConnectedView> createState() =>
      _FloorPlanProjectsConnectedViewState();
}

class _FloorPlanProjectsConnectedViewState
    extends ConsumerState<FloorPlanProjectsConnectedView> {
  bool _isLoading = true;
  bool _isCreating = false;

  String? _error;
  String _search = '';

  List<FloorPlanProjectDto> _projects = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProjects);
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(floorPlanApiServiceProvider);

      final projects = await api.listProjects(
        ref: ref,
        targetObjectId: widget.targetObjectId,
      );

      if (!mounted) return;

      setState(() {
        _projects = projects;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  List<FloorPlanProjectDto> get _filteredProjects {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return _projects;
    }

    return _projects.where((project) {
      final title = project.title.toLowerCase();
      final id = project.id.toLowerCase();
      final status = project.status.toLowerCase();
      final sourceType = project.sourceType.toLowerCase();
      final targetObjectId = project.targetObjectId?.toLowerCase() ?? '';

      return title.contains(query) ||
          id.contains(query) ||
          status.contains(query) ||
          sourceType.contains(query) ||
          targetObjectId.contains(query);
    }).toList();
  }

     Future<void> _createNewPlan() async {
           if (_isCreating) return;
           if (!mounted) return;
           final result = await _showCreatePlanDialog();
           
           if (!mounted) return;
           if (result == null) return;
           final cleanTitle = result.trim().isEmpty ? 'new_plan_button'.tr : result.trim();
         
           if (!mounted) return;
         
           setState(() {
             _isCreating = true;
             _error = null;
           });
         
           try {
             final api = ref.read(floorPlanApiServiceProvider);
         
             final createdProject = await api.createProject(
               ref: ref,
               title: cleanTitle,
               sourceType: 'manual',
               targetObjectId: widget.targetObjectId,
               targetAppLabel: widget.targetAppLabel,
               targetModel: widget.targetModel,
               metadata: {
                 'created_from': 'floor_plan_projects_page',
               },
             );
         
             if (!mounted) return;
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted) {
                 _openEditor(createdProject);
               }
             });
           } catch (e) {
             if (!mounted) return;
         
             setState(() {
               _error = e.toString();
             });
         
             if (mounted) {
               ref.read(navigationService).showSnackbar(
                 SnackBar(
                   content: Text('${'failed_to_create_plan'.tr} $e'),
                 ),
               );
             }
           } finally {
             if (mounted) {
               setState(() {
                 _isCreating = false;
               });
             }
           }
        }

            Future<String?> _showCreatePlanDialog() async {
           if (!mounted) return null;
           
           final theme = ref.read(themeColorsProvider);
           final completer = Completer<String?>();
           
           TextEditingController? controller;
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (!mounted) {
               if (!completer.isCompleted) completer.complete(null);
               return;
             }
             
             controller = TextEditingController(
               text: widget.title == 'Plany nieruchomości'
                   ? 'new_property_plan_default_name'.tr
                   : widget.title,
             );
             
             showDialog<String>(
               context: context,
               barrierDismissible: true,
               builder: (dialogContext) {
                 return AlertDialog(
                   backgroundColor: theme.dashboardContainer,
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(6),
                   ),
                   title: Text(
                     'create_new_plan_title'.tr,
                     style: TextStyle(
                       color: theme.textColor,
                       fontWeight: FontWeight.w900,
                     ),
                   ),
                   content: TextField(
                     controller: controller,
                     cursorColor: theme.textColor,
                     autofocus: true,
                     style: TextStyle(
                       color: theme.textColor,
                       fontWeight: FontWeight.w700,
                     ),
                     decoration: InputDecoration(
                       labelText: 'plan_name_label'.tr,
                       hintText: 'plan_name_hint'.tr,
                        filled: true,
                        fillColor: theme.adPopBackground,
                        hintStyle: TextStyle(color: theme.textColor),
                        border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(6.0),
                         borderSide: BorderSide.none,
                       ),
                       enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(6.0),
                         borderSide: BorderSide.none,
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(6.0),
                         borderSide: BorderSide.none,
                       ),
                     ),
                     
                     onSubmitted: (value) {
                       Navigator.of(dialogContext).pop(value);
                     },
                   ),
                   actions: [
                     TextButton(
                       onPressed: () {
                         Navigator.of(dialogContext).pop(null);
                       },
                       child: Text('cancel_button'.tr, style: TextStyle(color: theme.textColor)),
                     ),
                     FilledButton.icon(
                       onPressed: () {
                         Navigator.of(dialogContext).pop(controller?.text);
                       },
                       style:FilledButton.styleFrom(
                            backgroundColor: theme.themeColor,
                          ),
                       icon: const Icon(Icons.add),
                       label: Text('create_button'.tr, style: TextStyle(color: theme.themeColorText)),
                     ),
                   ],
                 );
               },
             ).then((result) {
               Future.delayed(const Duration(milliseconds: 100), () {
                 controller?.dispose();
                 if (!completer.isCompleted) {
                   completer.complete(result);
                 }
               });
             }).catchError((error) {
               controller?.dispose();
               if (!completer.isCompleted) {
                 completer.complete(null);
               }
             });
           });
           
           return completer.future;
         }


  void _openEditor(FloorPlanProjectDto project) {
    final projectId = project.id.trim();

    if (projectId.isEmpty) {
      setState(() {
        _error = 'project_missing_id_error'.tr;
      });
      return;
    }

    final targetObjectId = widget.targetObjectId?.trim().isNotEmpty == true
        ? widget.targetObjectId!.trim()
        : project.targetObjectId;

    ref.read(navigationService).pushNamedScreen(
      Routes.floorPlanBuilder,
      data: {
        'projectId': projectId,
        'targetObjectId': targetObjectId,
        'targetAppLabel': widget.targetAppLabel,
        'targetModel': widget.targetModel,
        'title': project.title.trim().isEmpty
            ? 'property_plan_title'.tr
            : project.title.trim(),
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'no_date_label'.tr;

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'draft_status'.tr;
      case 'active':
        return 'active_status'.tr;
      case 'archived':
        return 'archived_status'.tr;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final projects = _filteredProjects;

    return Container(
      color: theme.dashboardContainer,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProjects,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final crossAxisCount = width >= 1200
                  ? 4
                  : width >= 900
                      ? 3
                      : width >= 620
                          ? 2
                          : 1;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _FloorPlanProjectsHeader(
                      title: widget.title,
                      isCreating: _isCreating,
                      onCreate: _createNewPlan,
                      onRefresh: _loadProjects,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _search = value;
                          });
                        },
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.textColor.withAlpha(160),
                          ),
                          hintText: 'search_plan_hint'.tr,
                          hintStyle: TextStyle(
                            color: theme.textColor.withAlpha(130),
                          ),
                          filled: true,
                          fillColor: theme.dashboardContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: theme.dashboardBoarder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: theme.dashboardBoarder,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _FloorPlanProjectsError(
                          error: _error!,
                          onClose: () {
                            setState(() {
                              _error = null;
                            });
                          },
                        ),
                      ),
                    ),
                  if (_isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (projects.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FloorPlanProjectsEmptyState(
                        hasSearch: _search.trim().isNotEmpty,
                        isCreating: _isCreating,
                        onCreate: _createNewPlan,
                        onRefresh: _loadProjects,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio:
                              crossAxisCount == 1 ? 1.85 : 1.45,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final project = projects[index];

                            return _FloorPlanProjectCard(
                              project: project,
                              statusLabel: _statusLabel(project.status),
                              updatedAtLabel: _formatDate(project.updatedAt),
                              createdAtLabel: _formatDate(project.createdAt),
                              onTap: () => _openEditor(project),
                            );
                          },
                          childCount: projects.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FloorPlanProjectsHeader extends ConsumerWidget {
  final String title;
  final bool isCreating;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  const _FloorPlanProjectsHeader({
    required this.title,
    required this.isCreating,
    required this.onCreate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dashboardBoarder,
                  ),
                ),
                child: Icon(
                  Icons.architecture,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'refresh_tooltip'.tr,
                icon: Icon(
                  Icons.refresh,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: isCreating ? null : onCreate,
                icon: isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text('new_plan_button'.tr),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Text(
              'select_or_create_plan_subtitle'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(150),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorPlanProjectCard extends ConsumerWidget {
  final FloorPlanProjectDto project;
  final String statusLabel;
  final String updatedAtLabel;
  final String createdAtLabel;
  final VoidCallback onTap;

  const _FloorPlanProjectCard({
    required this.project,
    required this.statusLabel,
    required this.updatedAtLabel,
    required this.createdAtLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final versionNumber = project.latestVersion?.versionNumber;

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dashboardBoarder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.dashboardBoarder,
                      ),
                    ),
                    child: Icon(
                      Icons.home_work_outlined,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.textColor.withAlpha(150),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    label: statusLabel,
                    icon: Icons.circle_outlined,
                  ),
                  if (versionNumber != null)
                    _MiniBadge(
                      label: 'v$versionNumber',
                      icon: Icons.history,
                    ),
                  _MiniBadge(
                    label: project.sourceType,
                    icon: Icons.edit_note,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProjectMetaLine(
                icon: Icons.update,
                label: 'updated_label'.tr,
                value: updatedAtLabel,
              ),
              const SizedBox(height: 6),
              _ProjectMetaLine(
                icon: Icons.add_circle_outline,
                label: 'created_label'.tr,
                value: createdAtLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends ConsumerWidget {
  final String label;
  final IconData icon;

  const _MiniBadge({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: theme.textColor.withAlpha(160),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(180),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMetaLine extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProjectMetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: theme.textColor.withAlpha(130),
        ),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: TextStyle(
            color: theme.textColor.withAlpha(130),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _FloorPlanProjectsEmptyState extends ConsumerWidget {
  final bool hasSearch;
  final bool isCreating;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  const _FloorPlanProjectsEmptyState({
    required this.hasSearch,
    required this.isCreating,
    required this.onCreate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.architecture,
              size: 48,
              color: theme.textColor.withAlpha(170),
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch ? 'no_plans_found'.tr : 'no_plans_yet'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'change_search_or_refresh'.tr
                  : 'create_first_plan_message'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: Text('refresh_button'.tr),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: isCreating ? null : onCreate,
                  icon: isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text('new_plan_button'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorPlanProjectsError extends ConsumerWidget {
  final String error;
  final VoidCallback onClose;

  const _FloorPlanProjectsError({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withAlpha(120),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[700],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}