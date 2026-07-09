import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';


import 'published_ad_network_link.dart';
import 'published_ad_network_links_provider.dart';
import 'published_ad_network_links_overlay.dart';

class PublicationPortalSelectionConfig {
  const PublicationPortalSelectionConfig({
    this.selectAllByDefault = false,
    this.defaultSelectedChannelIds = const {},
    this.defaultSelectedChannelCodes = const {},
    this.defaultSelectedChannelNames = const {},
    this.requireConfirmation = true,
  });

  /// Select all external portals after loading channels.
  ///
  /// Hously is always selected by default regardless of this value.
  final bool selectAllByDefault;

  /// Example: {'1', '2', '17'}
  final Set<String> defaultSelectedChannelIds;

  /// Example: {'otodom', 'morizon', 'gratka'}
  final Set<String> defaultSelectedChannelCodes;

  /// Example: {'Otodom', 'Morizon'}
  final Set<String> defaultSelectedChannelNames;

  /// Show confirmation dialog before publish / unpublish actions.
  final bool requireConfirmation;
}

class FloatingActions extends ConsumerWidget {
  const FloatingActions({
    super.key,
    required this.adId,
    required this.isEditing,
    required this.theme,
    required this.onEnterEdit,
    required this.onSave,
    required this.onCancel,
    required this.adFeedPop,
    this.isClientPortal = false,
    this.canEdit = true,
    this.portalExportsBasePath = 'https://www.superbee.cloud/portal-exports/',
    this.publicationSettingsRoute = '/portal-exports/settings',
    this.onOpenPublicationSettings,
    this.contentTypeAppLabel = 'portal',
    this.contentTypeModel = 'draftadvertisement',
    this.portalSelectionConfig = const PublicationPortalSelectionConfig(),
  });

  final bool canEdit;
  final bool isClientPortal;
  final Object adId;
  final bool isEditing;
  final ThemeColors theme;
  final Future<void> Function() onEnterEdit;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;
  final dynamic adFeedPop;

  /// Backend base path:
  /// https://www.superbee.cloud/portal-exports/
  final String portalExportsBasePath;

  /// Frontend route to publication settings.
  final String? publicationSettingsRoute;

  /// Optional custom navigation callback.
  final VoidCallback? onOpenPublicationSettings;

  /// Django ContentType payload for PublicationExportJobViewSet.create_for_object.
  ///
  /// If your draft model has a different ContentType, pass correct values
  /// where you use FloatingActions.
  final String contentTypeAppLabel;
  final String contentTypeModel;

  /// Fallback config if backend settings endpoint fails.
  final PublicationPortalSelectionConfig portalSelectionConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isEditing && canEdit) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 40,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10,
              onPressed: onEnterEdit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcons.pencil(color: theme.textColor),
                  const SizedBox(width: 10),
                  Text(
                    'Edit'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ],
              ),
            ),
          ),
          if (!isClientPortal) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                style: elevatedButtonStyleRounded10,
                onPressed: () {
                  final isMobile = MediaQuery.of(context).size.width < 600;

                  if (isMobile) {
                    PublicationManagerDialog.showAsSheet(
                      context,
                      adId: adId,
                      adFeedPop: adFeedPop,
                      theme: theme,
                      portalExportsBasePath: portalExportsBasePath,
                      publicationSettingsRoute: publicationSettingsRoute,
                      onOpenPublicationSettings: onOpenPublicationSettings,
                      contentTypeAppLabel: contentTypeAppLabel,
                      contentTypeModel: contentTypeModel,
                      portalSelectionConfig: portalSelectionConfig,
                    );
                    return;
                  }

                  showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) {
                      return PublicationManagerDialog(
                        adId: adId,
                        adFeedPop: adFeedPop,
                        theme: theme,
                        portalExportsBasePath: portalExportsBasePath,
                        publicationSettingsRoute: publicationSettingsRoute,
                        onOpenPublicationSettings: onOpenPublicationSettings,
                        contentTypeAppLabel: contentTypeAppLabel,
                        contentTypeModel: contentTypeModel,
                        portalSelectionConfig: portalSelectionConfig,
                      );
                    },
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcons.sendAbove(color: theme.textColor),
                    const SizedBox(width: 10),
                    Text(
                      'Publication'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: onSave,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcons.check(color: theme.textColor),
                const SizedBox(width: 10),
                Text(
                  'Save'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: onCancel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcons.close(color: theme.textColor),
                const SizedBox(width: 10),
                Text(
                  'Cancel'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PUBLICATION MANAGER DIALOG
// ============================================================================

class PublicationManagerDialog extends ConsumerStatefulWidget {
  const PublicationManagerDialog({
    super.key,
    required this.adId,
    required this.adFeedPop,
    required this.theme,
    required this.portalExportsBasePath,
    this.publicationSettingsRoute,
    this.onOpenPublicationSettings,
    this.contentTypeAppLabel = 'portal',
    this.contentTypeModel = 'draftadvertisement',
    this.portalSelectionConfig = const PublicationPortalSelectionConfig(),
    this.asBottomSheet = false,
  });

  final Object adId;
  final dynamic adFeedPop;
  final ThemeColors theme;
  final String portalExportsBasePath;
  final String? publicationSettingsRoute;
  final VoidCallback? onOpenPublicationSettings;
  final String contentTypeAppLabel;
  final String contentTypeModel;
  final PublicationPortalSelectionConfig portalSelectionConfig;

  /// Render as a draggable bottom sheet instead of a centered dialog.
  ///
  /// Use [showAsSheet] on mobile so the panel can be dragged and takes
  /// the full available width instead of squeezing content sideways.
  final bool asBottomSheet;

  /// Opens the publication manager as a draggable scrollable bottom sheet.
  ///
  /// Preferred entry point on mobile/narrow screens.
  static Future<void> showAsSheet(
    BuildContext context, {
    required Object adId,
    required dynamic adFeedPop,
    required ThemeColors theme,
    required String portalExportsBasePath,
    String? publicationSettingsRoute,
    VoidCallback? onOpenPublicationSettings,
    String contentTypeAppLabel = 'portal',
    String contentTypeModel = 'draftadvertisement',
    PublicationPortalSelectionConfig portalSelectionConfig =
        const PublicationPortalSelectionConfig(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return PublicationManagerDialog(
          adId: adId,
          adFeedPop: adFeedPop,
          theme: theme,
          portalExportsBasePath: portalExportsBasePath,
          publicationSettingsRoute: publicationSettingsRoute,
          onOpenPublicationSettings: onOpenPublicationSettings,
          contentTypeAppLabel: contentTypeAppLabel,
          contentTypeModel: contentTypeModel,
          portalSelectionConfig: portalSelectionConfig,
          asBottomSheet: true,
        );
      },
    );
  }

  @override
  ConsumerState<PublicationManagerDialog> createState() =>
      _PublicationManagerDialogState();
}

class _PublicationManagerDialogState
    extends ConsumerState<PublicationManagerDialog> {
  bool _isLoadingSettings = false;
  bool _isLoadingChannels = false;
  bool _isLoadingHistory = false;
  bool _isRunningAction = false;
  bool _didApplyDefaultSelection = false;

  PublicationPortalSelectionConfig _resolvedSelectionConfig =
      const PublicationPortalSelectionConfig();

  List<_PublicationChannel> _channels = const [];
  List<_PublicationHistoryEntry> _history = const [];

  final Set<String> _selectedChannelKeys = <String>{};

  String? _error;

  Object get _draftId {
    try {
      final dynamic id = widget.adFeedPop?.id;
      if (id != null) return id;
    } catch (_) {
      // Ignore invalid dynamic object.
    }

    return widget.adId;
  }

  String get _exportsBasePath {
    final raw = widget.portalExportsBasePath.trim();

    if (raw.endsWith('/')) {
      return raw.substring(0, raw.length - 1);
    }

    return raw;
  }

  String get _siteBaseUrl {
    final uri = Uri.tryParse(_exportsBasePath);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'https://www.superbee.cloud';
    }

    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  String get _houslyPublishEndpoint {
    return '$_siteBaseUrl/portal/draft/publish/$_draftId/';
  }

  String get _channelsEndpoint {
    return '$_exportsBasePath/channels/';
  }

  String get _historyEndpoint {
    return '$_exportsBasePath/logs/?object_id=${Uri.encodeComponent(_draftId.toString())}';
  }

  String get _publicationSettingsEndpoint {
    return '$_exportsBasePath/settings/me/';
  }

  String get _createPublicationJobEndpoint {
    return '$_exportsBasePath/jobs/create-for-object/';
  }

  String _runPublicationJobEndpoint(Object jobId) {
    return '$_exportsBasePath/jobs/$jobId/run/';
  }

  List<_PublicationChannel> get _selectedChannels {
    return _channels
        .where((channel) => _selectedChannelKeys.contains(channel.selectionKey))
        .toList();
  }

  List<_PublicationChannel> get _selectedExternalChannels {
    return _selectedChannels.where((channel) => !channel.isHously).toList();
  }

  bool get _hasSelectedChannels => _selectedChannelKeys.isNotEmpty;

  bool get _hasSelectedExternalChannels => _selectedExternalChannels.isNotEmpty;

  bool get _allChannelsSelected {
    if (_channels.isEmpty) return false;

    return _channels.every(
      (channel) => _selectedChannelKeys.contains(channel.selectionKey),
    );
  }

  @override
  void initState() {
    super.initState();
    _resolvedSelectionConfig = widget.portalSelectionConfig;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchPublicationSettings();

    await Future.wait([
      _fetchChannels(),
      _fetchHistory(),
    ]);
  }

  Future<void> _fetchPublicationSettings() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSettings = true;
    });

    try {
      final response = await ApiServices.get(
        _publicationSettingsEndpoint,
        ref: ref,
        hasToken: true,
      );

      if (!mounted) return;

      if (!_isSuccessResponse(response)) {
        setState(() {
          _resolvedSelectionConfig = widget.portalSelectionConfig;
        });
        return;
      }

      final data = _extractMap(response?.data);

      final rawCodes = data['default_selected_channel_codes'];
      final codes = <String>{};

      if (rawCodes is List) {
        for (final item in rawCodes) {
          final code = item?.toString().trim().toLowerCase();

          if (code != null && code.isNotEmpty) {
            codes.add(code);
          }
        }
      }

      final rawIds = data['default_selected_channel_ids'];
      final ids = <String>{};

      if (rawIds is List) {
        for (final item in rawIds) {
          final id = item?.toString().trim();

          if (id != null && id.isNotEmpty) {
            ids.add(id);
          }
        }
      }

      final rawNames = data['default_selected_channel_names'];
      final names = <String>{};

      if (rawNames is List) {
        for (final item in rawNames) {
          final name = item?.toString().trim().toLowerCase();

          if (name != null && name.isNotEmpty) {
            names.add(name);
          }
        }
      }

      setState(() {
        _resolvedSelectionConfig = PublicationPortalSelectionConfig(
          selectAllByDefault: data['select_all_by_default'] == true,
          defaultSelectedChannelIds: ids,
          defaultSelectedChannelCodes: codes,
          defaultSelectedChannelNames: names,
          requireConfirmation: data['require_confirmation'] != false,
        );
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _resolvedSelectionConfig = widget.portalSelectionConfig;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _fetchChannels() async {
    if (!mounted) return;

    setState(() {
      _isLoadingChannels = true;
      _error = null;
    });

    try {
      final response = await ApiServices.get(
        _channelsEndpoint,
        ref: ref,
        hasToken: true,
      );

      if (!mounted) return;

      if (!_isSuccessResponse(response)) {
        final fallbackChannels = const <_PublicationChannel>[
          _PublicationChannel.hously(),
        ];

        setState(() {
          _channels = fallbackChannels;
          _applyDefaultSelectionIfNeeded(fallbackChannels);
          _error =
              '${'Could not load publication channels'.tr}: HTTP ${response?.statusCode ?? 0}';
        });
        return;
      }

      final list = _extractList(response?.data);

      final externalChannels = list
          .whereType<Map>()
          .map(
            (item) => _PublicationChannel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.id.toString().trim().isNotEmpty)
          .where((item) => item.isEnabled)
          .toList();

      final channels = <_PublicationChannel>[
        const _PublicationChannel.hously(),
        ...externalChannels,
      ];

      setState(() {
        _channels = channels;
        _applyDefaultSelectionIfNeeded(channels);
      });
    } catch (e) {
      if (!mounted) return;

      final fallbackChannels = const <_PublicationChannel>[
        _PublicationChannel.hously(),
      ];

      setState(() {
        _channels = fallbackChannels;
        _applyDefaultSelectionIfNeeded(fallbackChannels);
        _error = '${'Could not load publication channels'.tr}: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingChannels = false;
      });
    }
  }





  Future<void> _findAndShowNmLinksOverlay() async {
    final scope = PublishedAdNetworkLinksScope(
      appLabel: widget.contentTypeAppLabel,
      model: widget.contentTypeModel,
      objectId: _draftId.toString(),
    );

    final notifier = ref.read(publishedAdNetworkLinksProvider(scope).notifier);

    await notifier.loadSettings();

    final settings = ref.read(publishedAdNetworkLinksProvider(scope)).settings;

    if (settings == null) return;
    if (!settings.enabled) return;
    if (!settings.autoFindAfterPublish) return;

    await notifier.findCandidates();

    final state = ref.read(publishedAdNetworkLinksProvider(scope));

    if (!mounted) return;

    if (state.canShowOverlay) {
      await PublishedAdNetworkLinksOverlay.show(
        context: context,
        scope: scope,
      );
    }
  }






  void _applyDefaultSelectionIfNeeded(List<_PublicationChannel> channels) {
    if (_didApplyDefaultSelection) return;

    _didApplyDefaultSelection = true;
    _selectedChannelKeys.clear();

    final config = _resolvedSelectionConfig;

    final selectedIds = config.defaultSelectedChannelIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    final selectedCodes = config.defaultSelectedChannelCodes
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    final selectedNames = config.defaultSelectedChannelNames
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    for (final channel in channels) {
      final shouldSelect = channel.isHously ||
          config.selectAllByDefault ||
          selectedIds.contains(channel.id.toString()) ||
          selectedCodes.contains(channel.code.toLowerCase()) ||
          selectedNames.contains(channel.name.toLowerCase());

      if (shouldSelect) {
        _selectedChannelKeys.add(channel.selectionKey);
      }
    }
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final response = await ApiServices.get(
        _historyEndpoint,
        ref: ref,
        hasToken: true,
      );

      if (!mounted) return;

      if (!_isSuccessResponse(response)) {
        setState(() {
          _history = const [];
        });
        return;
      }

      final list = _extractList(response?.data);

      final history = list
          .whereType<Map>()
          .map(
            (item) => _PublicationHistoryEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      setState(() {
        _history = history;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _history = const [];
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  void _toggleChannel(_PublicationChannel channel, bool selected) {
    setState(() {
      if (selected) {
        _selectedChannelKeys.add(channel.selectionKey);
      } else {
        _selectedChannelKeys.remove(channel.selectionKey);
      }
    });
  }

  void _selectAllChannels() {
    setState(() {
      _selectedChannelKeys
        ..clear()
        ..addAll(_channels.map((channel) => channel.selectionKey));
    });
  }

  void _clearSelectedChannels() {
    setState(() {
      _selectedChannelKeys.clear();
    });
  }

  Future<void> _publishSelectedPortals() async {
    final selected = _selectedChannels;

    if (selected.isEmpty) {
      _showSnack('Select at least one target first.'.tr);
      return;
    }

    final confirmed = await _confirmChannelsAction(
      title: 'Send selected targets'.tr,
      message: 'Do you want to publish this advertisement to selected targets?'
          .tr,
      confirmLabel: 'Send selected'.tr,
      channels: selected,
      isDanger: false,
    );

    if (!confirmed) return;

    await _runBulkPublicationJobs(
      channels: selected,
      action: 'insert',
      successMessage:
          '${'Publication started for selected targets'.tr}: ${selected.length}',
    );
  }

  Future<void> _unpublishSelectedPortals() async {
    final selected = _selectedExternalChannels;

    if (selected.isEmpty) {
      _showSnack('Select at least one external portal first.'.tr);
      return;
    }

    final confirmed = await _confirmChannelsAction(
      title: 'Remove from selected portals'.tr,
      message:
          'Do you want to remove this advertisement from selected external portals?'
              .tr,
      confirmLabel: 'Remove selected'.tr,
      channels: selected,
      isDanger: true,
    );

    if (!confirmed) return;

    await _runBulkPublicationJobs(
      channels: selected,
      action: 'delete',
      successMessage:
          '${'Unpublication started for selected portals'.tr}: ${selected.length}',
    );
  }

  Future<void> _publishToPortal(_PublicationChannel channel) async {
    final confirmed = await _confirmChannelsAction(
      title: channel.isHously ? 'Publish to Hously'.tr : 'Send to portal'.tr,
      message: channel.isHously
          ? 'Do you want to publish this advertisement to Hously?'.tr
          : 'Do you want to send this advertisement to this portal?'.tr,
      confirmLabel: channel.isHously ? 'Publish'.tr : 'Send'.tr,
      channels: [channel],
      isDanger: false,
    );

    if (!confirmed) return;

    if (channel.isHously) {
      final ok = await _publishToHouslyWithoutConfirm();

      if (!ok) return;

      _showSnack('Advertisement published to Hously'.tr);
      await _fetchHistory();
      return;
    }

    final ok = await _createAndRunPublicationJob(
      channel: channel,
      action: 'insert',
      shouldManageLoadingState: true,
    );

    if (!ok) return;

    _showSnack('${'Publication started for'.tr} ${channel.name}');
    await _fetchHistory();
    await _findAndShowNmLinksOverlay();
  }

  Future<void> _unpublishFromPortal(_PublicationChannel channel) async {
    if (channel.isHously) {
      _showSnack('Hously unpublish is not available yet.'.tr);
      return;
    }

    final confirmed = await _confirmChannelsAction(
      title: 'Remove from portal'.tr,
      message: 'Do you want to remove this advertisement from this portal?'.tr,
      confirmLabel: 'Remove'.tr,
      channels: [channel],
      isDanger: true,
    );

    if (!confirmed) return;

    final ok = await _createAndRunPublicationJob(
      channel: channel,
      action: 'delete',
      shouldManageLoadingState: true,
    );

    if (!ok) return;

    _showSnack('${'Unpublication started for'.tr} ${channel.name}');
    await _fetchHistory();
  }

  Future<void> _runBulkPublicationJobs({
    required List<_PublicationChannel> channels,
    required String action,
    required String successMessage,
  }) async {
    if (_isRunningAction) return;

    setState(() {
      _isRunningAction = true;
      _error = null;
    });

    final errors = <String>[];

    try {
      for (final channel in channels) {
        if (channel.isHously) {
          if (action != 'insert') {
            continue;
          }

          final ok = await _publishHouslyInsideBulk();

          if (!ok) {
            errors.add(channel.name);
          }

          continue;
        }

        final ok = await _createAndRunPublicationJob(
          channel: channel,
          action: action,
          shouldManageLoadingState: false,
        );

        if (!ok) {
          errors.add(channel.name);
        }
      }

      if (!mounted) return;

      if (errors.isNotEmpty) {
        setState(() {
          _error = '${'Some targets failed'.tr}: ${errors.join(', ')}';
        });
      } else {
        _showSnack(successMessage);
      }

      await _fetchHistory();

      if (action == 'insert') {
      await _findAndShowNmLinksOverlay();
    }

    } finally {
      if (!mounted) return;

      setState(() {
        _isRunningAction = false;
      });
    }
  }

  Future<bool> _publishToHouslyWithoutConfirm() async {
    if (_isRunningAction) return false;

    setState(() {
      _isRunningAction = true;
      _error = null;
    });

    try {
      final response = await ApiServices.post(
        _houslyPublishEndpoint,
        hasToken: true,
        data: const <String, dynamic>{},
      );

      if (!mounted) return false;

      if (!_isSuccessResponse(response)) {
        setState(() {
          _error = '${'Action failed'.tr}: HTTP ${response?.statusCode ?? 0}';
        });
        return false;
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      setState(() {
        _error = '${'Action failed'.tr}: $e';
      });

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isRunningAction = false;
        });
      }
    }
  }

  Future<bool> _publishHouslyInsideBulk() async {
    try {
      final response = await ApiServices.post(
        _houslyPublishEndpoint,
        hasToken: true,
        data: const <String, dynamic>{},
      );

      if (!mounted) return false;

      return _isSuccessResponse(response);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _createAndRunPublicationJob({
    required _PublicationChannel channel,
    required String action,
    bool shouldManageLoadingState = true,
  }) async {
    if (channel.isHously) {
      if (action != 'insert') return false;

      if (shouldManageLoadingState) {
        return _publishToHouslyWithoutConfirm();
      }

      return _publishHouslyInsideBulk();
    }

    if (shouldManageLoadingState) {
      if (_isRunningAction) return false;

      setState(() {
        _isRunningAction = true;
        _error = null;
      });
    }

    try {
      final createResponse = await ApiServices.post(
        _createPublicationJobEndpoint,
        hasToken: true,
        data: {
          'channel_id': channel.id,
          'app_label': widget.contentTypeAppLabel,
          'model': widget.contentTypeModel,
          'object_id': _draftId.toString(),
          'action': action,
        },
      );

      if (!mounted) return false;

      if (!_isSuccessResponse(createResponse)) {
        _setActionError(
          '${'Could not create publication job'.tr}: HTTP ${createResponse?.statusCode ?? 0}',
          shouldManageLoadingState: shouldManageLoadingState,
        );
        return false;
      }

      final jobMap = _extractMap(createResponse?.data);
      final jobId = jobMap['id'] ?? jobMap['pk'];

      if (jobId == null || jobId.toString().trim().isEmpty) {
        _setActionError(
          'Publication job was created, but response has no job id'.tr,
          shouldManageLoadingState: shouldManageLoadingState,
        );
        return false;
      }

      final runResponse = await ApiServices.post(
        _runPublicationJobEndpoint(jobId),
        hasToken: true,
        data: const {
          'upload': true,
          'async': true,
        },
      );

      if (!mounted) return false;

      if (!_isSuccessResponse(runResponse)) {
        _setActionError(
          '${'Could not run publication job'.tr}: HTTP ${runResponse?.statusCode ?? 0}',
          shouldManageLoadingState: shouldManageLoadingState,
        );
        return false;
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      _setActionError(
        '${'Publication action failed'.tr}: $e',
        shouldManageLoadingState: shouldManageLoadingState,
      );

      return false;
    } finally {
      if (mounted && shouldManageLoadingState) {
        setState(() {
          _isRunningAction = false;
        });
      }
    }
  }

  void _setActionError(
    String message, {
    required bool shouldManageLoadingState,
  }) {
    if (!mounted) return;

    if (shouldManageLoadingState) {
      setState(() {
        _error = message;
      });
    }
  }

  Future<bool> _confirmChannelsAction({
    required String title,
    required String message,
    required String confirmLabel,
    required List<_PublicationChannel> channels,
    required bool isDanger,
  }) async {
    if (!_resolvedSelectionConfig.requireConfirmation) return true;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            final theme = widget.theme;

            return AlertDialog(
              backgroundColor: theme.dashboardContainer,
              title: Text(
                title,
                style: TextStyle(color: theme.textColor),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(color: theme.textColor),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.textFieldColor.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: channels.map((channel) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(
                                  channel.isHously
                                      ? Icons.home_work_outlined
                                      : Icons.language,
                                  size: 16,
                                  color: theme.textColor.withAlpha(190),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    channel.name,
                                    style: TextStyle(
                                      color: theme.textColor.withAlpha(210),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text('Cancel'.tr),
                ),
                ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    confirmLabel,
                    style: TextStyle(
                      color: isDanger ? Colors.red : theme.textColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  bool _isSuccessResponse(dynamic response) {
    final statusCode = response?.statusCode;

    if (statusCode is int) {
      return statusCode >= 200 && statusCode < 300;
    }

    return response != null;
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openSettings() {
    Navigator.of(context).maybePop();

    if (widget.onOpenPublicationSettings != null) {
      widget.onOpenPublicationSettings!();
      return;
    }

    final route = widget.publicationSettingsRoute;

    if (route != null && route.trim().isNotEmpty) {
      Get.toNamed(route);
    }
  }

  dynamic _decodeDynamic(dynamic data) {
    if (data == null) return null;

    if (data is List<int>) {
      try {
        return json.decode(utf8.decode(data));
      } catch (_) {
        return data;
      }
    }

    if (data is String) {
      try {
        return json.decode(data);
      } catch (_) {
        return data;
      }
    }

    return data;
  }

  List<dynamic> _extractList(dynamic data) {
    final decoded = _decodeDynamic(data);

    if (decoded == null) return const [];

    if (decoded is List) return decoded;

    if (decoded is Map) {
      final results = decoded['results'];
      if (results is List) return results;

      final items = decoded['items'];
      if (items is List) return items;

      final dataList = decoded['data'];
      if (dataList is List) return dataList;

      return [decoded];
    }

    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    final decoded = _decodeDynamic(data);

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return const <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    if (widget.asBottomSheet) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: theme.dashboardContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.textColor.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _buildHeader(theme),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: _buildBody(theme),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 920,
          maxHeight: 820,
        ),
        child: Material(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildBody(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          _buildErrorBox(theme, _error!),
          const SizedBox(height: 12),
        ],
        _buildPortalsSection(theme),
        const SizedBox(height: 16),
        _buildHistorySection(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeColors theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.themeColor,
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: theme.themeTextColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Publication manager'.tr,
              style: TextStyle(
                color: theme.themeTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_isLoadingSettings)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.themeTextColor,
                ),
              ),
            ),
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Publication settings'.tr,
            icon: Icon(
              Icons.settings_outlined,
              color: theme.themeTextColor,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Close'.tr,
            icon: Icon(
              Icons.close,
              color: theme.themeTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(ThemeColors theme, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalsSection(ThemeColors theme) {
    return _PublicationSection(
      theme: theme,
      title: 'Publication targets'.tr,
      subtitle: 'Select Hously and external portals for this advertisement.'.tr,
      trailing: IconButton(
        onPressed: _isLoadingChannels ? null : _fetchChannels,
        tooltip: 'Refresh'.tr,
        icon: Icon(Icons.refresh, color: theme.textColor),
      ),
      child: Builder(
        builder: (context) {
          if (_isLoadingChannels) {
            return _buildLoadingRow(theme, 'Loading portals'.tr);
          }

          if (_channels.isEmpty) {
            return _buildEmptyState(
              theme,
              'No publication channels configured yet.'.tr,
              actionLabel: 'Open settings'.tr,
              onAction: _openSettings,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPortalSelectionToolbar(theme),
              const SizedBox(height: 12),
              ..._channels.map((channel) {
                final selected =
                    _selectedChannelKeys.contains(channel.selectionKey);

                return _PortalPublicationTile(
                  theme: theme,
                  channel: channel,
                  selected: selected,
                  isRunningAction: _isRunningAction,
                  onSelectedChanged: (value) {
                    _toggleChannel(channel, value);
                  },
                  onPublish: () => _publishToPortal(channel),
                  onUnpublish: channel.isHously
                      ? null
                      : () => _unpublishFromPortal(channel),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPortalSelectionToolbar(ThemeColors theme) {
    final selectedCount = _selectedChannelKeys.length;
    final totalCount = _channels.length;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.textColor.withAlpha(20)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _allChannelsSelected,
                onChanged: (_) {
                  if (_allChannelsSelected) {
                    _clearSelectedChannels();
                  } else {
                    _selectAllChannels();
                  }
                },
              ),
              Text(
                '${'Selected'.tr}: $selectedCount / $totalCount',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _selectAllChannels,
            child: Text('Select all'.tr),
          ),
          TextButton(
            onPressed: _clearSelectedChannels,
            child: Text('Clear'.tr),
          ),
          _PublicationActionButton(
            theme: theme,
            isLoading: _isRunningAction,
            icon: Icons.upload_outlined,
            label: 'Send selected'.tr,
            onPressed: _hasSelectedChannels ? _publishSelectedPortals : null,
          ),
          _PublicationActionButton(
            theme: theme,
            isLoading: _isRunningAction,
            isDanger: true,
            icon: Icons.remove_circle_outline,
            label: 'Remove selected'.tr,
            onPressed:
                _hasSelectedExternalChannels ? _unpublishSelectedPortals : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(ThemeColors theme) {
    return _PublicationSection(
      theme: theme,
      title: 'Publication history'.tr,
      subtitle: 'History for this advertisement.'.tr,
      trailing: IconButton(
        onPressed: _isLoadingHistory ? null : _fetchHistory,
        tooltip: 'Refresh'.tr,
        icon: Icon(Icons.refresh, color: theme.textColor),
      ),
      child: Builder(
        builder: (context) {
          if (_isLoadingHistory) {
            return _buildLoadingRow(theme, 'Loading history'.tr);
          }

          if (_history.isEmpty) {
            return _buildEmptyState(
              theme,
              'No publication history for this advertisement yet.'.tr,
            );
          }

          return Column(
            children: _history.map((entry) {
              return _PublicationHistoryTile(
                theme: theme,
                entry: entry,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildLoadingRow(ThemeColors theme, String text) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.themeColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: theme.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    ThemeColors theme,
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.textColor.withAlpha(170),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: theme.textColor.withAlpha(210)),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// SMALL UI COMPONENTS
// ============================================================================

class _PublicationSection extends StatelessWidget {
  const _PublicationSection({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final ThemeColors theme;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.textFieldColor.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textColor.withAlpha(24)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(165),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PublicationActionButton extends StatelessWidget {
  const _PublicationActionButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
  });

  final ThemeColors theme;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final fg = isDanger ? Colors.red : theme.textColor;

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              ),
            ] else ...[
              Icon(icon, color: fg, size: 18),
            ],
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }
}

class _PortalPublicationTile extends StatelessWidget {
  const _PortalPublicationTile({
    required this.theme,
    required this.channel,
    required this.selected,
    required this.isRunningAction,
    required this.onSelectedChanged,
    required this.onPublish,
    required this.onUnpublish,
  });

  final ThemeColors theme;
  final _PublicationChannel channel;
  final bool selected;
  final bool isRunningAction;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onPublish;
  final VoidCallback? onUnpublish;

  @override
  Widget build(BuildContext context) {
    final isHously = channel.isHously;

    final avatarAndText = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: selected,
          onChanged: (value) => onSelectedChanged(value ?? false),
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 18,
          backgroundColor: isHously
              ? theme.themeColor.withAlpha(65)
              : theme.themeColor.withAlpha(35),
          child: Icon(
            isHously ? Icons.home_work_outlined : Icons.language,
            color: theme.textColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => onSelectedChanged(!selected),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        channel.name,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isHously)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.themeColor.withAlpha(45),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: theme.themeColor.withAlpha(120),
                            ),
                          ),
                          child: Text(
                            'Default'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    channel.description.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                  if (channel.code.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      channel.code,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(110),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final actionButtons = Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        _PublicationActionButton(
          theme: theme,
          isLoading: isRunningAction,
          icon: isHously ? Icons.public : Icons.upload_outlined,
          label: isHously ? 'Publish'.tr : 'Send'.tr,
          onPressed: onPublish,
        ),
        if (onUnpublish != null)
          _PublicationActionButton(
            theme: theme,
            isLoading: isRunningAction,
            isDanger: true,
            icon: Icons.remove_circle_outline,
            label: 'Remove'.tr,
            onPressed: onUnpublish,
          ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            selected ? theme.themeColor.withAlpha(20) : theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? theme.themeColor.withAlpha(120)
              : theme.textColor.withAlpha(20),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Below this width, name + both buttons can't fit on one line
          // without squeezing the Expanded text column to near zero,
          // which makes Flutter wrap the text one letter per line.
          final isNarrow = constraints.maxWidth < 480;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                avatarAndText,
                const SizedBox(height: 8),
                actionButtons,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: avatarAndText),
              const SizedBox(width: 10),
              actionButtons,
            ],
          );
        },
      ),
    );
  }
}

class _PublicationHistoryTile extends StatelessWidget {
  const _PublicationHistoryTile({
    required this.theme,
    required this.entry,
  });

  final ThemeColors theme;
  final _PublicationHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusLower = entry.status.toLowerCase();

    final isError = statusLower.contains('error') ||
        statusLower.contains('failed') ||
        statusLower.contains('failure');

    final isPending = statusLower.contains('pending') ||
        statusLower.contains('queued') ||
        statusLower.contains('running');

    final icon = isError
        ? Icons.error_outline
        : isPending
            ? Icons.hourglass_empty
            : Icons.check_circle_outline;

    final iconColor = isError
        ? Colors.red
        : isPending
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.textColor.withAlpha(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.message.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (entry.createdAt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.createdAt,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(120),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DATA HELPERS
// ============================================================================

class _PublicationChannel {
  const _PublicationChannel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.isEnabled,
    this.isHously = false,
  });

  const _PublicationChannel.hously()
      : id = '__hously__',
        code = 'hously',
        name = 'Hously',
        description = 'Publish inside your own Hously portal.',
        isEnabled = true,
        isHously = true;

  final Object id;
  final String code;
  final String name;
  final String description;
  final bool isEnabled;
  final bool isHously;

  String get selectionKey => id.toString();

  factory _PublicationChannel.fromJson(Map<String, dynamic> json) {
    final portalDefinition = json['portal_definition'];

    Map<String, dynamic> portalDefinitionMap = const {};

    if (portalDefinition is Map) {
      portalDefinitionMap = Map<String, dynamic>.from(portalDefinition);
    }

    final id = json['id'] ?? json['pk'] ?? '';

    final code = _readString(
      json['code'] ??
          portalDefinitionMap['code'] ??
          json['portal_code'] ??
          '',
    );

    final rawName = _readString(
      json['name'] ??
          json['title'] ??
          portalDefinitionMap['name'] ??
          portalDefinitionMap['title'] ??
          '',
    );

    final name = rawName.isNotEmpty
        ? rawName
        : code.isNotEmpty
            ? code
            : 'Portal';

    final rawDescription = _readString(
      json['description'] ??
          portalDefinitionMap['description'] ??
          portalDefinitionMap['code'] ??
          '',
    );

    final description = rawDescription.isNotEmpty
        ? rawDescription
        : code.isNotEmpty
            ? code
            : 'Publication channel';

    final enabled = _readBool(
      json['is_enabled'] ??
          json['enabled'] ??
          json['is_active'] ??
          json['active'] ??
          true,
    );

    return _PublicationChannel(
      id: id,
      code: code,
      name: name,
      description: description,
      isEnabled: enabled,
    );
  }
}

class _PublicationHistoryEntry {
  const _PublicationHistoryEntry({
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String title;
  final String message;
  final String status;
  final String createdAt;

  factory _PublicationHistoryEntry.fromJson(Map<String, dynamic> json) {
    final channel = json['channel'];
    final job = json['job'];
    final run = json['run'];

    Map<String, dynamic> channelMap = const {};
    Map<String, dynamic> jobMap = const {};
    Map<String, dynamic> runMap = const {};

    if (channel is Map) {
      channelMap = Map<String, dynamic>.from(channel);
    }

    if (job is Map) {
      jobMap = Map<String, dynamic>.from(job);
    }

    if (run is Map) {
      runMap = Map<String, dynamic>.from(run);
    }

    final portal = _readString(
      json['portal_name'] ??
          json['channel_name'] ??
          json['channel_name'] ??
          channelMap['name'] ??
          channelMap['code'] ??
          'Publication',
    );

    final action = _readString(
      json['action'] ??
          json['event'] ??
          jobMap['action'] ??
          runMap['action'] ??
          '',
    );

    final status = _readString(
      json['status'] ??
          json['state'] ??
          runMap['status'] ??
          jobMap['status'] ??
          '',
    );

    final message = _readString(
      json['message'] ??
          json['log'] ??
          json['details'] ??
          json['error_message'] ??
          '',
    );

    final createdAt = _readString(
      json['created_at'] ??
          json['created'] ??
          json['timestamp'] ??
          json['date'] ??
          runMap['created_at'] ??
          jobMap['created_at'] ??
          '',
    );

    final titleParts = <String>[
      portal,
      if (action.isNotEmpty) action,
      if (status.isNotEmpty) '($status)',
    ];

    return _PublicationHistoryEntry(
      title: titleParts.join(' '),
      message: message,
      status: status,
      createdAt: createdAt,
    );
  }
}

String _readString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

bool _readBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value.toString().trim().toLowerCase();

  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'y' ||
      normalized == 'on';
}