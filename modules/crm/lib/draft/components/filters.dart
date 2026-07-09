import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/draft/filter_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/text_field.dart';

class DraftAdFilterDialog extends ConsumerStatefulWidget {
  final DraftAdFilter initial;
  final void Function(DraftAdFilter filter) onApply;

  const DraftAdFilterDialog({
    super.key,
    required this.initial,
    required this.onApply,
  });

  @override
  ConsumerState<DraftAdFilterDialog> createState() => _DraftAdFilterDialogState();
}

class _DraftAdFilterDialogState extends ConsumerState<DraftAdFilterDialog> {
  late DraftAdFilter filter;

  late final TextEditingController titleController;
  late final TextEditingController cityController;
  late final TextEditingController statusController;
  late final TextEditingController priceMinController;
  late final TextEditingController priceMaxController;
  late final TextEditingController roomsController;

  @override
  void initState() {
    super.initState();
    filter = DraftAdFilter(
      title: widget.initial.title,
      city: widget.initial.city,
      status: widget.initial.status,
      priceMin: widget.initial.priceMin,
      priceMax: widget.initial.priceMax,
      rooms: widget.initial.rooms,
      balcony: widget.initial.balcony,
      elevator: widget.initial.elevator,
    );

    titleController = TextEditingController(text: filter.title ?? '');
    cityController = TextEditingController(text: filter.city ?? '');
    statusController = TextEditingController(text: filter.status ?? '');
    priceMinController = TextEditingController(
      text: filter.priceMin?.toString() ?? '',
    );
    priceMaxController = TextEditingController(
      text: filter.priceMax?.toString() ?? '',
    );
    roomsController = TextEditingController(
      text: filter.rooms?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    cityController.dispose();
    statusController.dispose();
    priceMinController.dispose();
    priceMaxController.dispose();
    roomsController.dispose();
    super.dispose();
  }

  void _resetControllers() {
    titleController.clear();
    cityController.clear();
    statusController.clear();
    priceMinController.clear();
    priceMaxController.clear();
    roomsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return PopPageManager(
      tag: 'draftfilter',
      isBig: false,
      child: Column(
        spacing: 8,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  CoreTextField(
                    label: 'title_label'.tr,
                    controller: titleController,
                    onChanged: (v) => filter.title = v,
                  ),
                  CoreTextField(
                    label: 'city'.tr,
                    controller: cityController,
                    onChanged: (v) => filter.city = v,
                  ),
                  CoreTextField(
                    label: 'Status'.tr,
                    controller: statusController,
                    onChanged: (v) => filter.status = v,
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: CoreTextField(
                          label: 'price_from'.tr,
                          controller: priceMinController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => filter.priceMin = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CoreTextField(
                          label: 'price_to'.tr,
                          controller: priceMaxController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => filter.priceMax = double.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                  CoreTextField(
                    label: 'number_of_rooms'.tr,
                    controller: roomsController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => filter.rooms = int.tryParse(v),
                  ),
                  SwitchListTile(
                    title: Text(
                      'Balcony'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                    value: filter.balcony ?? false,
                    onChanged: (v) => setState(() => filter.balcony = v),
                    activeTrackColor: theme.themeColor,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Elevator'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                    value: filter.elevator ?? false,
                    onChanged: (v) => setState(() => filter.elevator = v),
                    activeTrackColor: theme.themeColor,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: elevatedButtonStyleRounded10,
                onPressed: () {
                  setState(() {
                    filter = DraftAdFilter();
                    _resetControllers();
                  });
                },
                child: Text(
                  'Reset'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              const SizedBox(width: 25),
              ElevatedButton(
                style: buttonStyleRounded10ThemeRedWithPadding15,
                onPressed: () {
                  ref.read(navigationService).beamPop();
                  widget.onApply(filter);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'filter'.tr,
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}