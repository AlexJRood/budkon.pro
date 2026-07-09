import 'package:emma/library/emma_local_model_installer_types.dart';
import 'package:emma/library/emma_local_model_manager_provider.dart';
import 'package:emma/library/emma_local_models_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

class EmmaInstalledModelsPanel extends ConsumerStatefulWidget {
  const EmmaInstalledModelsPanel({
    super.key,
  });

  @override
  ConsumerState<EmmaInstalledModelsPanel> createState() =>
      _EmmaInstalledModelsPanelState();
}

class _EmmaInstalledModelsPanelState
    extends ConsumerState<EmmaInstalledModelsPanel> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(emmaLocalModelManagerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emmaLocalModelManagerProvider);
    final notifier = ref.read(emmaLocalModelManagerProvider.notifier);

    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'local_models_desktop_only'.tr
          ),
        ),
      );
    }

    if (state.isLoading && state.installed.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              Icon(
                state.engineReachable
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: state.engineReachable
                    ? Colors.green.shade600
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.engineReachable
                      ? 'local_engine_running'.tr
                      : 'local_engine_not_responding'.tr,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              IconButton(
                tooltip: 'refresh_tooltip'.tr,
                onPressed: state.isActionRunning
                    ? null
                    : () => notifier.load(),
                icon: const Icon(Icons.refresh_rounded),
              ),
              if (state.runtime.isNotEmpty)
                IconButton(
                  tooltip: 'unload_llm_tooltip'.tr,
                  onPressed: state.isActionRunning || !state.engineReachable
                      ? null
                      : notifier.unloadLlm,
                  icon: const Icon(Icons.power_settings_new_rounded),
                ),
            ],
          ),
        ),
        if (state.error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              state.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: state.installed.isEmpty
              ? const _EmptyInstalledModels()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  children: [
                    _BucketSection(
                      title: 'llm_title'.tr,
                      description: 'llm_description'.tr,
                      items: state.byBucket('llm'),
                    ),
                    const SizedBox(height: 14),
                    _BucketSection(
                      title: 'stt_title'.tr,
                      description: 'stt_description'.tr,
                      items: state.byBucket('stt'),
                    ),
                    const SizedBox(height: 14),
                    _BucketSection(
                      title: 'tts_title'.tr,
                      description: 'tts_description'.tr,
                      items: state.byBucket('tts'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _BucketSection extends StatelessWidget {
  const _BucketSection({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<EmmaLocalInstalledModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _SectionBox(
        child: Row(
          children: [
            const Icon(Icons.folder_off_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text('$title ${'no_installed_models'.tr}'),
            ),
          ],
        ),
      );
    }

    return _SectionBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_rounded),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InstalledModelTile(model: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstalledModelTile extends ConsumerWidget {
  const _InstalledModelTile({
    required this.model,
  });

  final EmmaLocalInstalledModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emmaLocalModelManagerProvider);
    final notifier = ref.read(emmaLocalModelManagerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: model.isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.45)
              : Theme.of(context).dividerColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            model.isActive
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: model.isActive ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.name.isEmpty ? model.modelId : model.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${model.fileName} · ${formatEmmaLocalBytes(model.sizeBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  model.localPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.68),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: state.isActionRunning
                ? null
                : () {
                    notifier.activateModel(
                      model,
                      loadIntoRuntime: model.taskBucket == 'llm',
                    );
                  },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(model.taskBucket == 'llm' ? 'load_button'.tr : 'activate_button'.tr),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'delete_tooltip'.tr,
            onPressed: state.isActionRunning
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: Text('delete_model_title'.tr),
                          content: Text(
                            '${'delete_model_confirmation'.tr} "${model.name}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text('cancel_button'.tr),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text('delete_button'.tr),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed == true) {
                      await notifier.deleteModel(model);
                    }
                  },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.35),
        ),
      ),
      child: child,
    );
  }
}

class _EmptyInstalledModels extends StatelessWidget {
  const _EmptyInstalledModels();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'no_installed_models_message'.tr,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}