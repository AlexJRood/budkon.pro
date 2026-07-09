import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/cat_prefs_provider.dart';
import '../provider/company_cat_provider.dart';

/// Ustawienia kota: preferencje usera (DND, mute) + ustawienia firmowe
/// (on/off, częstość wędrówki) + zmiana imienia.
class CatSettingsSheet extends ConsumerWidget {
  const CatSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(catPrefsProvider);
    final settings = ref.watch(catSettingsProvider);
    final cat = ref.watch(companyCatProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Text(cat.moodEmoji, style: const TextStyle(fontSize: 24)),
            title: Text(cat.name),
            subtitle: Text('Głaskań: ${cat.totalPets} · Humor: ${cat.happiness}'),
            trailing: TextButton(
              onPressed: () => _rename(context, ref),
              child: const Text('Zmień imię'),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('Nie przeszkadzać'),
            subtitle: const Text('Kot nie będzie do mnie przychodził'),
            value: prefs.dnd,
            onChanged: (v) => ref.read(catPrefsProvider.notifier).setDnd(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_off_outlined),
            title: const Text('Wycisz reakcje'),
            subtitle: const Text('Bez bąbelków 🔔 / 📋 / 💬'),
            value: prefs.muteReactions,
            onChanged: (v) =>
                ref.read(catPrefsProvider.notifier).setMuteReactions(v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.pets_outlined),
            title: const Text('Kot w firmie'),
            subtitle: const Text('Włącz / wyłącz kota dla całej firmy'),
            value: settings.enabled,
            onChanged: (v) =>
                ref.read(catSettingsProvider.notifier).setEnabled(v),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Częstość wędrówki'),
            trailing: Text('${settings.roamMinutes} min'),
          ),
          Slider(
            min: 1,
            max: 30,
            divisions: 29,
            value: settings.roamMinutes.clamp(1, 30).toDouble(),
            label: '${settings.roamMinutes} min',
            onChanged: (v) =>
                ref.read(catSettingsProvider.notifier).setRoamMinutes(v.round()),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bedtime_outlined),
            title: const Text('Cisza nocna'),
            subtitle: const Text('Kot śpi w nocy (22-7) i nie wędruje'),
            value: settings.quietEnabled,
            onChanged: (v) =>
                ref.read(catSettingsProvider.notifier).setQuietEnabled(v),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _rename(BuildContext context, WidgetRef ref) {
    final controller =
        TextEditingController(text: ref.read(companyCatProvider).name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Imię kota'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              ref.read(companyCatProvider.notifier).rename(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}
