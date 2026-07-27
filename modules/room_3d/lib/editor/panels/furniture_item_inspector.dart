/// Inspector zaznaczonego mebla — prawy panel, widoczny gdy w viewporcie
/// zaznaczono jakiś `RoomPlacedItem` (tryb Meble). Pozycja X/Y i skala
/// commitują się dopiero po puszczeniu (submit / onChangeEnd), nie na każdy
/// keystroke/tick suwaka — inaczej zalałoby to historię undo/redo dziesiątkami
/// wpisów za jedno przeciągnięcie. Link "kup ten mebel" jest celowo bez
/// prawdziwego `url_launcher` — żaden dev-catalog item nie ma jeszcze
/// `purchaseUrl` (Faza 2), więc na razie tylko pokazuje gdzie by prowadził.
library;

import 'package:core/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:furniture_catalog/furniture_catalog.dart';

import '../../actions/room_scene_actions.dart';
import '../../model/room_scene.dart';
import '../../providers/room_scene_provider.dart';

class FurnitureItemInspector extends ConsumerStatefulWidget {
  final String itemId;
  final VoidCallback onDeleted;

  const FurnitureItemInspector({
    super.key,
    required this.itemId,
    required this.onDeleted,
  });

  @override
  ConsumerState<FurnitureItemInspector> createState() => _FurnitureItemInspectorState();
}

class _FurnitureItemInspectorState extends ConsumerState<FurnitureItemInspector> {
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  double? _draggedRotationDeg;
  double? _draggedScale;
  String? _syncedForItemId;

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController();
    _yController = TextEditingController();
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _syncControllers(RoomPlacedItem item) {
    // Only re-sync when the selection changes (or after this widget's own
    // commit round-trips back through state) — not on every rebuild, or
    // typing into the field would fight the controller.
    if (_syncedForItemId == item.id) return;
    _syncedForItemId = item.id;
    _xController.text = item.position.x.toStringAsFixed(2);
    _yController.text = item.position.y.toStringAsFixed(2);
  }

  void _commitPosition(RoomPlacedItem item) {
    final x = double.tryParse(_xController.text.replaceAll(',', '.'));
    final y = double.tryParse(_yController.text.replaceAll(',', '.'));
    if (x == null || y == null) return;

    ref.read(roomSceneActionsProvider).moveItem(
          itemId: item.id,
          position: RoomPoint3(x: x, y: y, z: item.position.z),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final floor = ref.watch(roomSceneProvider).activeFloor;
    final item = floor?.items.where((i) => i.id == widget.itemId).firstOrNull;

    if (item == null) {
      return Center(
        child: Text(
          'Zaznaczony obiekt już nie istnieje.',
          style: TextStyle(color: theme.textColor.withAlpha(170), fontSize: 12),
        ),
      );
    }

    _syncControllers(item);

    final catalog = ref.watch(furnitureCatalogProvider);
    final catalogItem = catalog.where((c) => c.id == item.catalogItemId).firstOrNull;
    final rotationDeg = _draggedRotationDeg ?? item.rotationDeg;
    final scale = _draggedScale ?? item.scale;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            catalogItem?.name ?? item.catalogItemId,
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          if (catalogItem != null)
            Text(
              '${catalogItem.dimensions.widthM.toStringAsFixed(1)}×'
              '${catalogItem.dimensions.depthM.toStringAsFixed(1)}×'
              '${catalogItem.dimensions.heightM.toStringAsFixed(1)} m'
              '${catalogItem.brand != null ? ' • ${catalogItem.brand}' : ''}',
              style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11),
            ),
          const SizedBox(height: 16),

          Text('Pozycja (m)', style: _labelStyle(theme)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  theme: theme,
                  label: 'X',
                  controller: _xController,
                  onSubmitted: (_) => _commitPosition(item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  theme: theme,
                  label: 'Y',
                  controller: _yController,
                  onSubmitted: (_) => _commitPosition(item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text('Rotacja: ${rotationDeg.toStringAsFixed(0)}°', style: _labelStyle(theme)),
          Slider(
            value: rotationDeg % 360,
            min: 0,
            max: 359,
            divisions: 359,
            onChanged: (value) => setState(() => _draggedRotationDeg = value),
            onChangeEnd: (value) {
              ref.read(roomSceneActionsProvider).moveItem(itemId: item.id, rotationDeg: value);
              setState(() => _draggedRotationDeg = null);
            },
          ),
          const SizedBox(height: 8),

          Text('Skala: ${scale.toStringAsFixed(2)}×', style: _labelStyle(theme)),
          Slider(
            value: scale.clamp(0.5, 2.0),
            min: 0.5,
            max: 2.0,
            divisions: 30,
            onChanged: (value) => setState(() => _draggedScale = value),
            onChangeEnd: (value) {
              ref.read(roomSceneActionsProvider).moveItem(itemId: item.id, scale: value);
              setState(() => _draggedScale = null);
            },
          ),
          const SizedBox(height: 16),

          if (catalogItem?.purchaseUrl != null) ...[
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Link partnera: ${catalogItem!.purchaseUrl}')),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Kup ten mebel'),
            ),
            const SizedBox(height: 8),
          ],

          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(roomSceneActionsProvider).removeItem(item.id);
              widget.onDeleted();
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Usuń'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(30),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(dynamic theme) => TextStyle(
        color: theme.textColor.withAlpha(200),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      );
}

class _NumberField extends StatelessWidget {
  final dynamic theme;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _NumberField({
    required this.theme,
    required this.label,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: TextStyle(color: theme.textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      onSubmitted: onSubmitted,
      onTapOutside: (_) => onSubmitted(controller.text),
    );
  }
}
