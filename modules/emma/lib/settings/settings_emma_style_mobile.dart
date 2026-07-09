import 'dart:async';
import 'package:core/settings/settings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:emma/settings/emma_style_profile_service.dart';
import 'package:emma/settings/emma_style_profile_provider.dart';
import 'package:core/theme/apptheme.dart';

class EmmaStyleSettingsMobile extends ConsumerStatefulWidget {
  const EmmaStyleSettingsMobile({super.key});

  @override
  ConsumerState<EmmaStyleSettingsMobile> createState() =>
      _EmmaStyleSettingsMobileState();
}

class _EmmaStyleSettingsMobileState
    extends ConsumerState<EmmaStyleSettingsMobile> {
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
      styleText:
          _controller.text.trim().isEmpty ? null : _controller.text.trim(),
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
          'Nowe ogłoszenia będą opisywane w domyślnym stylu Emmy.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Anuluj'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Resetuj'.tr,
                style: const TextStyle(color: Colors.red)),
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

    return Scaffold(
      body: Column(
        children: [
          MobileSettingsAppbar(
            title: 'Styl pisania Emmy'.tr,
            onPressed: () => ref.read(navigationService).beamPop(),
          ),
          Expanded(
            child: profileAsync.when(
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
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _startPolling());
                } else if (!profile.isGenerating && _pollTimer != null) {
                  _stopPolling();
                }

                if (!_editing && _controller.text != (profile.styleText ?? '')) {
                  _controller.text = profile.styleText ?? '';
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Emma napisze opisy ogłoszeń w Twoim stylu.'.tr,
                              style: textTheme.bodyMedium?.copyWith(
                                  color: theme.textColor.withAlpha(180)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: profile.status),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (profile.isGenerating)
                        _InfoTile(
                          icon: Icons.hourglass_top,
                          color: Colors.orange,
                          text: 'Emma analizuje Twoje opisy… Odśwież za chwilę.'.tr,
                          textColor: theme.textColor,
                        )
                      else if (profile.canGenerate)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generating ? null : () => _generate(profile),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: Text(
                              profile.isReady
                                  ? 'Wygeneruj ponownie'.tr
                                  : 'Naucz Emmę mojego stylu'.tr,
                            ),
                          ),
                        )
                      else
                        _InfoTile(
                          icon: Icons.info_outline,
                          color: Colors.grey,
                          text:
                              'Potrzebujesz co najmniej 3 ogłoszeń z opisami (masz ${profile.adsAvailable}).'
                                  .tr,
                          textColor: theme.textColor,
                        ),

                      const SizedBox(height: 24),

                      Text(
                        'Profil stylu'.tr,
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textColor),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        enabled: _editing,
                        maxLines: null,
                        minLines: 5,
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          hintText: profile.isReady
                              ? null
                              : 'Wygeneruj automatycznie lub wpisz opis swojego stylu.'.tr,
                          hintStyle: TextStyle(
                              color: theme.textColor.withAlpha(120)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: theme.bordercolor.withAlpha(100)),
                          ),
                          filled: !_editing,
                          fillColor: theme.filterPageColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_editing)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text('Zapisz'.tr),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() {
                                  _editing = false;
                                  _controller.text = profile.styleText ?? '';
                                }),
                                child: Text('Anuluj'.tr),
                              ),
                            ),
                          ],
                        )
                      else if (profile.isReady)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _editing = true),
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text('Edytuj profil ręcznie'.tr),
                          ),
                        ),

                      if (profile.isReady || profile.isFailed) ...[
                        const SizedBox(height: 32),
                        Center(
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
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Color textColor;
  const _InfoTile(
      {required this.icon,
      required this.color,
      required this.text,
      required this.textColor});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: textColor))),
        ],
      );
}
