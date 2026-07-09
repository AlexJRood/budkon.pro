import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:emma/settings/emma_style_profile_service.dart';
import 'package:emma/settings/emma_style_profile_provider.dart';
import 'package:core/theme/apptheme.dart';

class EmmaStyleSettingsPc extends ConsumerStatefulWidget {
  const EmmaStyleSettingsPc({super.key});

  @override
  ConsumerState<EmmaStyleSettingsPc> createState() =>
      _EmmaStyleSettingsPcState();
}

class _EmmaStyleSettingsPcState extends ConsumerState<EmmaStyleSettingsPc> {
  final _controller = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _generating = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _controller.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(emmaStyleProfileProvider);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _generate(EmmaStyleProfile profile) async {
    setState(() => _generating = true);
    final ok = await EmmaStyleProfileService.generate(ref);
    if (!mounted) return;
    if (ok) {
      ref.invalidate(emmaStyleProfileProvider);
      _startPolling();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się uruchomić generowania.'.tr)),
      );
    }
    setState(() => _generating = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = await EmmaStyleProfileService.update(
      ref: ref,
      styleText: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
    );
    if (!mounted) return;
    if (updated != null) {
      _editing = false;
      ref.invalidate(emmaStyleProfileProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać.'.tr)),
      );
    }
    setState(() => _saving = false);
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resetuj profil stylu'.tr),
        content: Text(
          'To usunie profil stylu Emmy. Nowe ogłoszenia będą opisywane w domyślnym stylu.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Anuluj'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Resetuj'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await EmmaStyleProfileService.reset(ref);
    if (!mounted) return;
    _editing = false;
    _controller.clear();
    _stopPolling();
    ref.invalidate(emmaStyleProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final textTheme = Theme.of(context).textTheme;
    final profileAsync = ref.watch(emmaStyleProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Błąd ładowania profilu.'.tr,
            style: TextStyle(color: theme.textColor)),
      ),
      data: (profile) {
        if (profile == null) {
          return Center(
            child: Text('Nie udało się załadować profilu.'.tr,
                style: TextStyle(color: theme.textColor)),
          );
        }

        if (profile.isGenerating && _pollTimer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling());
        } else if (!profile.isGenerating && _pollTimer != null) {
          _stopPolling();
        }

        if (!_editing && _controller.text != (profile.styleText ?? '')) {
          _controller.text = profile.styleText ?? '';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.themeColor, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Styl pisania Emmy'.tr,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(status: profile.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Emma nauczy się pisać opisy ogłoszeń w Twoim stylu na podstawie Twoich istniejących opisów.'.tr,
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textColor.withAlpha(180),
                ),
              ),
              const SizedBox(height: 28),

              if (!profile.isReady || _editing == false) ...[
                _SectionCard(
                  title: 'Automatyczna analiza stylu'.tr,
                  theme: theme,
                  textTheme: textTheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.canGenerate
                            ? 'Emma przeanalizuje ${profile.adsAvailable} Twoich opisów i stworzy profil stylu.'
                            : 'Potrzebujesz co najmniej 3 ogłoszeń z opisami (masz ${profile.adsAvailable}).'.tr,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: theme.textColor),
                      ),
                      const SizedBox(height: 14),
                      if (profile.isGenerating)
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text('Emma analizuje Twoje opisy…'.tr,
                                style: TextStyle(color: theme.textColor)),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: profile.canGenerate && !_generating
                              ? () => _generate(profile)
                              : null,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            profile.isReady
                                ? 'Wygeneruj ponownie'.tr
                                : 'Naucz Emmę mojego stylu'.tr,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _SectionCard(
                title: 'Profil stylu'.tr,
                theme: theme,
                textTheme: textTheme,
                trailing: profile.isReady && !_editing
                    ? TextButton.icon(
                        onPressed: () => setState(() => _editing = true),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text('Edytuj'.tr),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!profile.isReady && !_editing)
                      Text(
                        'Profil zostanie tu pokazany po wygenerowaniu.'.tr,
                        style: TextStyle(color: theme.textColor.withAlpha(150)),
                      )
                    else
                      TextField(
                        controller: _controller,
                        enabled: _editing,
                        maxLines: null,
                        minLines: 6,
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          hintText:
                              'Opisz swój styl pisania lub wygeneruj go automatycznie…'.tr,
                          hintStyle: TextStyle(
                              color: theme.textColor.withAlpha(120)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: theme.bordercolor.withAlpha(100)),
                          ),
                          filled: !_editing,
                          fillColor: theme.filterPageColor,
                        ),
                      ),
                    if (_editing) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('Zapisz'.tr),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () => setState(() {
                              _editing = false;
                              _controller.text = profile.styleText ?? '';
                            }),
                            child: Text('Anuluj'.tr),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (profile.isReady || profile.isFailed) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _reset,
                    child: Text(
                      'Resetuj profil stylu'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'ready' => ('Aktywny'.tr, Colors.green),
      'generating' => ('Generowanie…'.tr, Colors.orange),
      'failed' => ('Błąd'.tr, Colors.red),
      _ => ('Nieaktywny'.tr, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final ThemeColors theme;
  final TextTheme textTheme;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.theme,
    required this.textTheme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.settingstile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
