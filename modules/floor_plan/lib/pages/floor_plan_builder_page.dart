import 'dart:math' as math;

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floor_plan/canvas/floor_plan_canvas.dart';
import 'package:floor_plan/generation/floor_plan_generate_dialog.dart';
import 'package:floor_plan/generation/floor_plan_generation_models.dart';
import 'package:floor_plan/models/floor_plan_document.dart';
import 'package:floor_plan/providers/floor_plan_api_service.dart';
import 'package:floor_plan/providers/floor_plan_collaboration_provider.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';

class FloorPlanBuilderCrmPage extends ConsumerWidget {
  final String? projectId;
  final String? targetObjectId;
  final String? targetAppLabel;
  final String? targetModel;
  final String title;

  FloorPlanBuilderCrmPage({
    super.key,
    this.projectId,
    this.targetObjectId,
    this.targetAppLabel,
    this.targetModel,
    this.title = 'Plan nieruchomości',
  });

  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isChildExpanded: true,
      enableScrool:true,
      isTopAppBarOff: true,
      isTopAppBarOffMobile: false,
      isBottomBarOff: true,
      isTopAppBarHoveroverUI: true,
      // isTopAppBarHoveroverUI: true,
      layoutTypePc: LayoutTypePc.stack,
      layoutTypeTablet: LayoutTypeTablet.stack,
      layoutTypeMobile: LayoutTypeMobile.stack,
      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      childPc: FloorPlanBuilderConnectedView(
        projectId: projectId,
        targetObjectId: targetObjectId,
        targetAppLabel: targetAppLabel,
        targetModel: targetModel,
        title: title,
      ),
      childTablet: FloorPlanBuilderConnectedView(
        projectId: projectId,
        targetObjectId: targetObjectId,
        targetAppLabel: targetAppLabel,
        targetModel: targetModel,
        title: title,
      ),
      childMobile: Builder(
        builder: (context) {
          final topPadding = TopAppBarSize.resolve(context);
          return Column(
            children: [
              SizedBox(height: topPadding),
              Expanded(
                child: FloorPlanBuilderConnectedView(
                  projectId: projectId,
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

class FloorPlanBuilderConnectedView extends ConsumerStatefulWidget {
  final String? projectId;
  final String? targetObjectId;
  final String? targetAppLabel;
  final String? targetModel;
  final String title;

  const FloorPlanBuilderConnectedView({
    super.key,
    this.projectId,
    this.targetObjectId,
    this.targetAppLabel,
    this.targetModel,
    required this.title,
  });

  @override
  ConsumerState<FloorPlanBuilderConnectedView> createState() =>
      _FloorPlanBuilderConnectedViewState();
}

class _FloorPlanBuilderConnectedViewState
    extends ConsumerState<FloorPlanBuilderConnectedView> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _isApplyingRemoteDocument = false;

  int _lastAppliedLiveDocumentSerial = 0;
  int _lastAppliedLiveSaveSerial = 0;

  String? _projectId;
  String? _error;

  FloorPlanProjectDto? _project;
  FloorPlanVersionDto? _latestVersion;
  FloorPlanDocument _document = FloorPlanDocument.empty();

  FloorPlanBackgroundImage? _backgroundImage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    final projectId = _projectId;

    if (projectId != null) {
      try {
        ref.read(floorPlanCollaborationProvider(projectId).notifier).disconnect();
      } catch (_) {}
    }

    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(floorPlanApiServiceProvider);

      if (widget.projectId != null && widget.projectId!.trim().isNotEmpty) {
        await _loadProjectById(api, widget.projectId!.trim());
        return;
      }

      if (widget.targetObjectId != null &&
          widget.targetObjectId!.trim().isNotEmpty) {
        final loaded = await _tryLoadProjectByTarget(api);

        if (loaded) {
          return;
        }
      }

      await _createProject(api);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProjectById(
    FloorPlanApiService api,
    String projectId,
  ) async {
    final project = await api.getProject(
      ref: ref,
      projectId: projectId,
    );

    final latest = await _safeGetLatestVersion(
      api: api,
      project: project,
    );

    if (!mounted) return;

    setState(() {
      _project = project;
      _projectId = project.id;
      _latestVersion = latest;
      _document = latest?.document ?? FloorPlanDocument.empty();
      _isDirty = false;
    });
  }

  Future<bool> _tryLoadProjectByTarget(FloorPlanApiService api) async {
    final projects = await api.listProjects(
      ref: ref,
      targetObjectId: widget.targetObjectId,
    );

    if (projects.isEmpty) return false;

    final project = projects.first;

    final latest = await _safeGetLatestVersion(
      api: api,
      project: project,
    );

    if (!mounted) return true;

    setState(() {
      _project = project;
      _projectId = project.id;
      _latestVersion = latest;
      _document = latest?.document ?? FloorPlanDocument.empty();
      _isDirty = false;
    });

    return true;
  }

  Future<void> _createProject(FloorPlanApiService api) async {
    final createdProject = await api.createProject(
      ref: ref,
      title: widget.title,
      sourceType: 'manual',
      targetObjectId: widget.targetObjectId,
      targetAppLabel: widget.targetAppLabel,
      targetModel: widget.targetModel,
      metadata: {
        'created_from': 'crm_floor_plan_builder',
      },
    );

    final latest = createdProject.latestVersion;

    if (!mounted) return;

    setState(() {
      _project = createdProject;
      _projectId = createdProject.id;
      _latestVersion = latest;
      _document = latest?.document ?? FloorPlanDocument.empty();
      _isDirty = false;
    });
  }

  Future<FloorPlanVersionDto?> _safeGetLatestVersion({
    required FloorPlanApiService api,
    required FloorPlanProjectDto project,
  }) async {
    try {
      return await api.getLatestVersion(
        ref: ref,
        projectId: project.id,
      );
    } catch (e, st) {
      debugPrint('Failed to fetch latest floor plan version: $e\n$st');
      return project.latestVersion;
    }
  }

  void _openIn3d() {
    final projectId = _projectId;

    if (projectId == null || projectId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisz plan, zanim otworzysz go w trybie 3D.')),
      );
      return;
    }

    ref.read(navigationService).pushNamedScreen(
      Routes.room3dEditor,
      data: {
        'floorPlanProjectId': projectId,
        'title': 'Tryb 3D',
      },
    );
  }

  Future<void> _openGeneratePlanDialog() async {
    final result = await FloorPlanGenerateDialog.show(context);

    if (result == null) return;

    _applyGeneratedPlan(result);
  }

  void _applyGeneratedPlan(FloorPlanGenerationApplyResult result) {
    final draft = result.draft;
    final generatedWalls = draft.toWalls();

    final nextDocument = _documentWithGeneratedPlan(
      document: _document,
      generatedWalls: generatedWalls,
      pixelsPerMeter: draft.pixelsPerMeter,
      imageWidth: draft.imageWidth,
      imageHeight: draft.imageHeight,
      replaceExistingWalls: result.replaceExistingWalls,
    );

    setState(() {
      if (result.useImageAsBackground) {
        _backgroundImage = draft.toBackgroundImage();
      }

      _document = nextDocument;
      _isDirty = true;
    });

    _onDocumentChanged(nextDocument);
  }

  FloorPlanDocument _documentWithGeneratedPlan({
    required FloorPlanDocument document,
    required List<FloorWall> generatedWalls,
    required double pixelsPerMeter,
    required int imageWidth,
    required int imageHeight,
    required bool replaceExistingWalls,
  }) {
    final newWidth =
        math.max(document.canvas.width, imageWidth + 400.0);
    final newHeight =
        math.max(document.canvas.height, imageHeight + 400.0);

    final walls = replaceExistingWalls
        ? generatedWalls
        : [...document.walls, ...generatedWalls];

    return document.copyWith(
      scale: document.scale.copyWith(pixelsPerMeter: pixelsPerMeter),
      canvas: document.canvas.copyWith(
        width: newWidth,
        height: newHeight,
      ),
      walls: walls,
    );
  }

  void _ensureLiveConnected({
    required String projectId,
    required FloorPlanCollaborationState liveState,
  }) {
    if (liveState.hasStarted ||
        liveState.isConnecting ||
        liveState.isConnected) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(floorPlanCollaborationProvider(projectId).notifier).connect();
    });
  }

  void _handleLiveStateChange(
    FloorPlanCollaborationState? previous,
    FloorPlanCollaborationState next,
  ) {
    if (!mounted) return;

    if (next.error != null && next.error != previous?.error) {
      setState(() {
        _error = next.error;
      });
    }

    if (next.documentEventSerial != _lastAppliedLiveDocumentSerial &&
        next.remoteDocument != null) {
      _lastAppliedLiveDocumentSerial = next.documentEventSerial;

      final eventType = next.lastDocumentEventType;

      _isApplyingRemoteDocument = true;

      setState(() {
        _document = next.remoteDocument!;

        if (eventType == 'state.initial') {
          _isDirty = false;
        } else {
          _isDirty = true;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _isApplyingRemoteDocument = false;
      });
    }

    if (next.saveEventSerial != _lastAppliedLiveSaveSerial) {
      _lastAppliedLiveSaveSerial = next.saveEventSerial;

      setState(() {
        _isDirty = false;
        _error = null;
      });
    }
  }

  Future<void> _reloadWithConfirm() async {
    if (_isSaving || _isLoading) return;

    if (_isDirty && mounted) {
      final shouldReload = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = ref.read(themeColorsProvider);

          return AlertDialog(
            backgroundColor: theme.dashboardContainer,
            title: Text(
              'refresh_plan_question'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'unsaved_changes_refresh_warning'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(190),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel_button'.tr),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.refresh),
                label: Text('refresh_button'.tr),
              ),
            ],
          );
        },
      );

      if (shouldReload != true) return;
    }

    await _bootstrap();

    final projectId = _projectId;
    if (projectId == null) return;

    final notifier = ref.read(
      floorPlanCollaborationProvider(projectId).notifier,
    );

    await notifier.disconnect();
    await notifier.connect();
  }

  Future<void> _save() async {
    final projectId = _projectId;
    if (projectId == null || projectId.trim().isEmpty) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final liveNotifier = ref.read(
        floorPlanCollaborationProvider(projectId).notifier,
      );

      final liveState = ref.read(
        floorPlanCollaborationProvider(projectId),
      );

      if (liveState.isConnected) {
        await liveNotifier.saveVersion(_document);
      } else {
        await _saveViaRest(projectId);
      }

      if (!mounted) return;

      setState(() {
        _isDirty = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('plan_saved_message'.tr),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'failed_to_save_plan'.tr} $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveViaRest(String projectId) async {
    final api = ref.read(floorPlanApiServiceProvider);

    final version = await api.createVersion(
      ref: ref,
      projectId: projectId,
      document: _document,
      changeNote: 'Manual save from CRM Floor Plan Builder',
      metadata: {
        'saved_from': 'crm_floor_plan_builder_rest_fallback',
      },
    );

    if (!mounted) return;

    setState(() {
      _latestVersion = version;
      _isDirty = false;
    });
  }

  void _onDocumentChanged(FloorPlanDocument nextDocument) {
    setState(() {
      _document = nextDocument;
      _isDirty = true;
    });

    if (_isApplyingRemoteDocument) return;

    final projectId = _projectId;
    if (projectId == null) return;

    final liveState = ref.read(
      floorPlanCollaborationProvider(projectId),
    );

    if (!liveState.isConnected) return;

    ref
        .read(floorPlanCollaborationProvider(projectId).notifier)
        .queueDocumentReplace(nextDocument);
  }

  void _sendLiveSelection(FloorPlanCanvasSelectionSnapshot selection) {
    final projectId = _projectId;
    if (projectId == null) return;

    final liveState = ref.read(
      floorPlanCollaborationProvider(projectId),
    );

    if (!liveState.isConnected) return;

    ref
        .read(floorPlanCollaborationProvider(projectId).notifier)
        .sendSelectionUpdate(selection.toJson());
  }

  void _acquireLiveObjectLock({
    required String objectType,
    required String objectId,
  }) {
    final projectId = _projectId;
    if (projectId == null) return;

    final liveState = ref.read(
      floorPlanCollaborationProvider(projectId),
    );

    if (!liveState.isConnected) return;

    ref.read(floorPlanCollaborationProvider(projectId).notifier).acquireLock(
          objectType: objectType,
          objectId: objectId,
        );
  }

  void _releaseLiveObjectLock({
    required String objectType,
    required String objectId,
  }) {
    final projectId = _projectId;
    if (projectId == null) return;

    final liveState = ref.read(
      floorPlanCollaborationProvider(projectId),
    );

    if (!liveState.isConnected) return;

    ref.read(floorPlanCollaborationProvider(projectId).notifier).releaseLock(
          objectType: objectType,
          objectId: objectId,
        );
  }

  bool _isObjectLockedByOther({
    required String objectType,
    required String objectId,
  }) {
    final projectId = _projectId;
    if (projectId == null) return false;

    final liveState = ref.read(
      floorPlanCollaborationProvider(projectId),
    );

    return liveState.isLockedByOther(
      objectType: objectType,
      objectId: objectId,
    );
  }

  String? _objectLockOwnerLabel({
    required String objectType,
    required String objectId,
  }) {
    final projectId = _projectId;
    if (projectId == null) return null;

    final liveState = ref.read(
      floorPlanCollaborationProvider(projectId),
    );

    return liveState.lockOwnerLabel(
      objectType: objectType,
      objectId: objectId,
    );
  }

  void _showLockedObjectMessage({
    required String objectType,
    required String objectId,
    String? ownerLabel,
  }) {
    final label = ownerLabel ?? 'another_user_label'.tr;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${'object_being_edited_by_other'.tr} $label',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectId = _projectId;

    FloorPlanCollaborationState? liveState;

    if (projectId != null && !_isLoading) {
      final watchedLiveState = ref.watch(
        floorPlanCollaborationProvider(projectId),
      );

      liveState = watchedLiveState;

      ref.listen<FloorPlanCollaborationState>(
        floorPlanCollaborationProvider(projectId),
        _handleLiveStateChange,
      );

      _ensureLiveConnected(
        projectId: projectId,
        liveState: watchedLiveState,
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _projectId == null) {
      return _FloorPlanErrorState(
        error: _error!,
        onRetry: _bootstrap,
      );
    }

    final latestVersionNumber =
        liveState?.lastSavedVersionNumber ?? _latestVersion?.versionNumber;

    final saveStatusLabel = liveState?.isConnected == true
        ? latestVersionNumber == null
            ? 'live_status'.tr
            : '${'live_status'.tr} v$latestVersionNumber'
        : latestVersionNumber == null
            ? 'offline_status'.tr
            : 'v$latestVersionNumber';

    final isSaving = _isSaving || (liveState?.isSavingVersion ?? false);

    return Stack(
      children: [
        Positioned.fill(
          child: FloorPlanCanvas(
            document: _document,
            onChanged: _onDocumentChanged,
            isSaving: isSaving,
            isDirty: _isDirty,
            saveStatusLabel: saveStatusLabel,
            backgroundImage: _backgroundImage,
            onGeneratePlan: _openGeneratePlanDialog,
            onSave: _save,
            onReload: _reloadWithConfirm,
            onOpen3d: _openIn3d,
            onSelectionChanged: _sendLiveSelection,
            onAcquireObjectLock: _acquireLiveObjectLock,
            onReleaseObjectLock: _releaseLiveObjectLock,
            isObjectLockedByOther: _isObjectLockedByOther,
            objectLockOwnerLabel: _objectLockOwnerLabel,
            onLockedObjectTap: _showLockedObjectMessage,
          ),
        ),
        if (liveState != null)
          Positioned(
            top: 84,
            left: 14,
            child: _FloorPlanLiveStatusBadge(
              liveState: liveState,
            ),
          ),
        if (_error != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FloorPlanInlineError(
              error: _error!,
              onClose: () {
                setState(() {
                  _error = null;
                });
              },
            ),
          ),
      ],
    );
  }
}

class _FloorPlanLiveStatusBadge extends ConsumerWidget {
  final FloorPlanCollaborationState liveState;

  const _FloorPlanLiveStatusBadge({
    required this.liveState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final isLive = liveState.isConnected;
    final isConnecting = liveState.isConnecting;

    final label = isLive
        ? 'live_status'.tr
        : isConnecting
            ? 'connecting_status'.tr
            : 'offline_status'.tr;

    final color = isLive
        ? Colors.green
        : isConnecting
            ? Colors.orange
            : Colors.red;

    return IgnorePointer(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(999),
        color: theme.dashboardContainer.withAlpha(235),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.withAlpha(120),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              if (liveState.users.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '${liveState.users.length}',
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Icon(
                  Icons.people_alt_outlined,
                  color: theme.textColor.withAlpha(170),
                  size: 15,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloorPlanInlineError extends ConsumerWidget {
  final String error;
  final VoidCallback onClose;

  const _FloorPlanInlineError({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: theme.dashboardContainer,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withAlpha(120)),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: theme.textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorPlanErrorState extends ConsumerWidget {
  final String error;
  final VoidCallback onRetry;

  const _FloorPlanErrorState({
    required this.error,
    required this.onRetry,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: Colors.red[700],
            ),
            const SizedBox(height: 12),
            Text(
              'failed_to_start_plan_wizard'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('try_again_button'.tr),
            ),
          ],
        ),
      ),
    );
  }
}