// cloud/api/add_folder.dart

import 'package:cloud/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/theme/text_field.dart'; // ⬅️ dodaj import (dostosuj ścieżkę)

class AddFolderDialog extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  final String? appLabel;
  final String? model;
  final String? objectId;
  final String? relationType;
  final bool isClient;

  const AddFolderDialog({
    super.key,
    required this.onAdded,
    this.appLabel,
    this.model,
    this.objectId,
    this.relationType,
    this.isClient = false,
  });

  @override
  ConsumerState<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends ConsumerState<AddFolderDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  final _relationController = TextEditingController();
  final _modelController = TextEditingController();
  final _objectIdController = TextEditingController();
  final _appLabelController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _appLabelController.text = widget.appLabel ?? "";
    _modelController.text = widget.model ?? "";
    _objectIdController.text = widget.objectId?.toString() ?? "";
    _relationController.text = widget.relationType ?? "";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _relationController.dispose();
    _modelController.dispose();
    _objectIdController.dispose();
    _appLabelController.dispose();
    super.dispose();
  }

  void _showSnack(
      ScaffoldMessengerState messenger,
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    final theme = ref.read(themeColorsProvider);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: isError ? Colors.redAccent : theme.themeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _extractServerDetail(dynamic data) {
    // Try to pull 'detail' first
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }

    // Common DRF validation error formats: {'name': ['This field is required.']}
    if (data is Map) {
      for (final entry in data.entries) {
        final val = entry.value;
        if (val is List && val.isNotEmpty && val.first is String) {
          return '${entry.key}: ${val.first}';
        }
        if (val is String) return '${entry.key}: $val';
      }
    }

    // Fallback to string form
    if (data is String) return data;
    return null;
  }

  String _mapDetailToFriendly(String detail) {
    final lower = detail.toLowerCase();
    if (lower.contains('duplicate key value') ||
        lower.contains('already exists') ||
        lower.contains('unikalny') ||
        lower.contains('unique constraint')) {
      return 'folder_with_this_name_already_exists'.tr;
    }
    if (lower.contains('permission') ||
        lower.contains('forbidden') ||
        lower.contains('brak uprawnień')) {
      return 'permission_denied_to_create_folder'.tr;
    }
    if (lower.contains('not authenticated') || lower.contains('unauthorized')) {
      return 'login_to_create_folder'.tr;
    }
    return detail;
  }

  Future<void> _createFolder() async {
    final ctx = context;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    final name = _controller.text.trim();

    if (name.isEmpty) {
      if (messenger != null) {
        _showSnack(messenger, 'folder_name_cannot_be_empty'.tr, isError: true);
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = <String, dynamic>{'name': name};

      // ✅ IMPORTANT: create inside currently opened folder
      final parentId = widget.isClient
          ? ref.read(clientExplorerParamsProvider).parent
          : ref.read(cloudExplorerParamsProvider).parent;

      if (parentId != null && parentId.isNotEmpty) {
        data['parent'] = parentId;
      }

      if (_appLabelController.text.trim().isNotEmpty) {
        data['app_label'] = _appLabelController.text.trim();
      }
      if (_modelController.text.trim().isNotEmpty) {
        data['model'] = _modelController.text.trim();
      }
      if (_objectIdController.text.trim().isNotEmpty) {
        data['object_id'] = _objectIdController.text.trim();
      }
      if (_relationController.text.trim().isNotEmpty) {
        data['relation_type'] = _relationController.text.trim();
      }

      final resp = await ApiServices.post(
        'https://www.superbee.cloud/storage/folders/',
        hasToken: true,
        data: data,
      );

      if (resp != null && resp.statusCode == 201) {
        if (!mounted) return;

        widget.onAdded();
        Navigator.of(ctx).pop();

        if (messenger != null) {
          _showSnack(messenger, 'folder_created_successfully'.tr);
        }
      } else {
        final detailRaw = _extractServerDetail(resp?.data);
        final detail = detailRaw != null
            ? _mapDetailToFriendly(detailRaw)
            : '${'server_error'.tr}${resp?.statusCode ?? ''}';

        if (messenger != null) {
          _showSnack(messenger, detail, isError: true);
        }

        if (mounted) {
          setState(() => _error = detail);
        }
      }
    } catch (e) {
      if (mounted) {
        if (messenger != null) {
          _showSnack(messenger, e.toString(), isError: true);
        }
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final isMobile = MediaQuery.of(context).size.width <= 800;

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "New folder".tr,
              style: TextStyle(color: theme.textColor, fontSize: 20),
            ),
            const SizedBox(height: 16),
            CoreTextField(
              focusNode: _focusNode,
              label: "Folder name".tr,
              controller: _controller,
              hintText: 'enter_name_hint'.tr,
            ),
            const SizedBox(height: 8),

            // Developer fields (kept commented as in your code)
            // CoreTextField(
            //   label: "App label (np. estate_agent)",
            //   controller: _appLabelController,
            // ),
            // const SizedBox(height: 8),
            // CoreTextField(
            //   label: "Model (np. agenttransaction)",
            //   controller: _modelController,
            // ),
            // const SizedBox(height: 8),
            // CoreTextField(
            //   label: "ID obiektu",
            //   controller: _objectIdController,
            //   keyboardType: TextInputType.number,
            // ),
            // const SizedBox(height: 8),
            // CoreTextField(
            //   label: "Typ relacji (opcjonalnie)",
            //   controller: _relationController,
            // ),
            const SizedBox(height: 20),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: AppLottie.loading(size: 450),
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancel".tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: buttonStyleRounded10ThemeRedWithPadding15,
                  onPressed: _loading ? null : _createFolder,
                  child: Text(
                    "Add".tr,
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      backgroundColor: theme.dashboardContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        "New folder".tr,
        style: TextStyle(color: theme.textColor, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            label: "Folder name".tr,
            controller: _controller,
            hintText: 'enter_name_hint'.tr,
          ),
          const SizedBox(height: 8),

          // Developer fields (kept commented as in your code)
          // CoreTextField(
          //   label: "App label (np. estate_agent)",
          //   controller: _appLabelController,
          // ),
          // const SizedBox(height: 8),
          // CoreTextField(
          //   label: "Model (np. agenttransaction)",
          //   controller: _modelController,
          // ),
          // const SizedBox(height: 8),
          // CoreTextField(
          //   label: "ID obiektu",
          //   controller: _objectIdController,
          //   keyboardType: TextInputType.number,
          // ),
          // const SizedBox(height: 8),
          // CoreTextField(
          //   label: "Typ relacji (opcjonalnie)",
          //   controller: _relationController,
          // ),
        ],
      ),
      actions: [
        if (_loading)
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: SizedBox(
              height: 24,
              width: 24,
              child: AppLottie.loading(size: 450),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text("Cancel".tr, style: TextStyle(color: theme.textColor)),
        ),
        ElevatedButton(
          style: buttonStyleRounded10ThemeRedWithPadding15,
          onPressed: _loading ? null : _createFolder,
          child: Text("Add".tr, style: TextStyle(color: AppColors.white)),
        ),
      ],
    );
  }
}

void showAddFolderDialog(
    BuildContext context,
    ThemeColors theme, {
      bool isClient = false,
      String? appLabel,
      String? model,
      String? objectId,
      String? relationType,
    }) {
  final container = ProviderScope.containerOf(context, listen: false);
  final screenSize = MediaQuery.of(context).size;
  final isDesktop = screenSize.width > 800;

  void handleAdded() {
    container.read(cloudSidebarRefreshTriggerProvider.notifier).state++;
    container.invalidate(cloudExplorerProvider);
    refreshAllCloudDataFromContainer(container);
    final clientParams = container.read(clientExplorerParamsProvider);
    container.invalidate(clientFileExplorerProvider(clientParams));
  }

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: AddFolderDialog(
          isClient: isClient,
          onAdded: handleAdded,
          appLabel: appLabel,
          model: model,
          objectId: objectId,
          relationType: relationType,
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.dashboardContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: AddFolderDialog(
                isClient: isClient,
                onAdded: handleAdded,
                appLabel: appLabel,
                model: model,
                objectId: objectId,
                relationType: relationType,
              ),
            ),
          ),
        ),
      ),
    );
  }
}