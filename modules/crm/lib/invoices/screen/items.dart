import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/invoices/models/invoice_item.dart';
import 'package:crm/invoices/providers/invoice_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';

class InvoiceItemPresetsScreen extends ConsumerStatefulWidget {
  const InvoiceItemPresetsScreen({super.key});

  @override
  ConsumerState<InvoiceItemPresetsScreen> createState() =>
      _InvoiceItemPresetsScreenState();
}

class _InvoiceItemPresetsScreenState
    extends ConsumerState<InvoiceItemPresetsScreen> {
  String? _search;

  @override
  Widget build(BuildContext context) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.watch(themeColorsProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      layoutTypePc: LayoutTypePc.row,
      layoutTypeMobile: LayoutTypeMobile.column,
      isChildExpanded: true,
      paddingPc: 16,
      paddingMobile: 12,
      childPc: _DesktopItemPresets(
        theme: theme,
        search: _search,
        onSearchChanged: (v) => setState(() => _search = v),
      ),
      childMobile: _MobileItemPresets(
        theme: theme,
        search: _search,
        onSearchChanged: (v) => setState(() => _search = v),
      ),
    );
  }
}

class _DesktopItemPresets extends ConsumerWidget {
  final ThemeColors theme;
  final String? search;
  final ValueChanged<String> onSearchChanged;

  const _DesktopItemPresets({
    required this.theme,
    required this.search,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPresets = ref.watch(invoiceItemPresetListProvider(search));
    final form = ref.watch(invoiceItemPresetFormProvider);
    final formNotifier =
        ref.read(invoiceItemPresetFormProvider.notifier);

    return Row(
      children: [
        // Left: list
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(242),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: theme.themeColor.withAlpha(51),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'invoice_item_presets_title'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: elevatedButtonStyleRounded10,
                      onPressed: () {
                        formNotifier.reset();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        'New preset',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                CoreTextField(
                  label: 'search_label'.tr,
                  hintText:'search_by_name_description_code_hint'.tr,
                  controller: TextEditingController(text: search ?? '')
                    ..selection = TextSelection.collapsed(
                      offset: (search ?? '').length,
                    ),
                  onChanged: (v) {
                    onSearchChanged(v);
                    ref.invalidate(invoiceItemPresetListProvider);
                  },
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: asyncPresets.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'no_presets_yet'.tr,
                            style: TextStyle(
                              color:
                                  theme.textColor.withAlpha(178),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: theme.dashboardBoarder
                              .withAlpha(102),
                        ),
                        itemBuilder: (context, index) {
                          final preset = list[index];
                          return _PresetTile(
                            preset: preset,
                            theme: theme,
                            onTap: () {
                              formNotifier.loadFromModel(preset);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        '${'error_prefix'.tr} $err',
                        style: const TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 16.w),

        // Right: form
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(230),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: theme.themeColor.withAlpha(51),
              ),
            ),
            child: _PresetForm(
              theme: theme,
              form: form,
              notifier: formNotifier,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileItemPresets extends ConsumerWidget {
  final ThemeColors theme;
  final String? search;
  final ValueChanged<String> onSearchChanged;

  const _MobileItemPresets({
    required this.theme,
    required this.search,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPresets = ref.watch(invoiceItemPresetListProvider(search));
    final formNotifier =
        ref.read(invoiceItemPresetFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 48.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'invoice_item_presets_title'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                formNotifier.reset();
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        CoreTextField(
          label: 'search_label'.tr,
          controller: TextEditingController(text: search ?? ''),
          onChanged: (v) {
            onSearchChanged(v);
            ref.invalidate(invoiceItemPresetListProvider);
          },
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: asyncPresets.when(
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'No presets.',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final preset = list[index];
                  return Card(
                    color: theme.dashboardContainer.withAlpha(242),
                    child: ListTile(
                      title: Text(
                        preset.name,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${preset.unitNetPrice} ${preset.currency} • VAT ${preset.vatRate}%',
                        style: TextStyle(
                          color: theme.textColor.withAlpha(178),
                          fontSize: 11.sp,
                        ),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () {
                        formNotifier.loadFromModel(preset);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            final form =
                                ref.watch(invoiceItemPresetFormProvider);
                            return DraggableScrollableSheet(
                              initialChildSize: 0.8,
                              minChildSize: 0.6,
                              maxChildSize: 0.95,
                              builder: (_, scrollController) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: theme
                                        .dashboardContainer
                                        .withAlpha(250),
                                    borderRadius:
                                        BorderRadius.vertical(
                                      top: Radius.circular(20.r),
                                    ),
                                  ),
                                  padding: EdgeInsets.only(
                                    left: 12.w,
                                    right: 12.w,
                                    top: 8.h,
                                    bottom:
                                        MediaQuery.of(context).viewInsets.bottom +
                                            12.h,
                                  ),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    child: _PresetForm(
                                      theme: theme,
                                      form: form,
                                      notifier: formNotifier,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  final InvoiceItemPresetModel preset;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _PresetTile({
    super.key,
    required this.preset,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = preset.isActive;

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        preset.name,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isActive) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(26),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'inactive_status'.tr,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${preset.unitNetPrice} ${preset.currency} • ${preset.unit} • VAT ${preset.vatRate}%',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                      fontSize: 11.sp,
                    ),
                  ),
                  if (preset.internalCode != null &&
                      preset.internalCode!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '${'code_prefix'.tr} ${preset.internalCode}',
                      style: TextStyle(
                        color: theme.textColor.withAlpha(153),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _PresetForm extends StatelessWidget {
  final ThemeColors theme;
  final InvoiceItemPresetFormState form;
  final InvoiceItemPresetFormNotifier notifier;

  const _PresetForm({
    required this.theme,
    required this.form,
    required this.notifier,
  });

  TextStyle get _labelStyle => TextStyle(
        color: theme.textColor.withAlpha(191),
        fontSize: 12.sp,
      );

  @override
  Widget build(BuildContext context) {
    final spacing = 8.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          form.id == null ? 'new_preset_button'.tr : 'edit_preset_title'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'preset_form_description'.tr,
          style: _labelStyle,
        ),
        SizedBox(height: 12.h),

        // Scope + active
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'scope_label'.tr,
                  labelStyle: TextStyle(color: theme.textColor),
                  filled: true,
                  fillColor: theme.adPopBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: form.scope,
                    isDense: true,
                    dropdownColor: theme.adPopBackground,
                    items: [
                      DropdownMenuItem(
                        value: 'company',
                        child: Text('company_scope'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('user_scope'.tr),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) notifier.setScope(v);
                    },
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Row(
              children: [
                Switch(
                  value: form.isActive,
                  onChanged: notifier.setIsActive,
                  activeColor: theme.themeColor,
                ),
                Text(
                  'active_status'.tr,
                  style: _labelStyle,
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: spacing),

        CoreTextField(
          label: 'name_label'.tr,
          controller: TextEditingController(text: form.name)
            ..selection = TextSelection.collapsed(
              offset: form.name.length,
            ),
          onChanged: notifier.setName,
        ),
        SizedBox(height: spacing),
        CoreTextField(
          label: 'description_optional_label'.tr,
          maxLines: 2,
          controller: TextEditingController(text: form.description)
            ..selection = TextSelection.collapsed(
              offset: form.description.length,
            ),
          onChanged: notifier.setDescription,
        ),

        SizedBox(height: spacing),

        Row(
          children: [
            Expanded(
              child: CoreTextField(
                label: 'unit_label'.tr,
                hintText:'unit_hint'.tr,
                controller: TextEditingController(text: form.unit)
                  ..selection = TextSelection.collapsed(
                    offset: form.unit.length,
                  ),
                onChanged: notifier.setUnit,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: CoreTextField(
                label: 'default_quantity_label'.tr,
                keyboardType: TextInputType.number,
                controller:
                    TextEditingController(text: form.defaultQuantity)
                      ..selection = TextSelection.collapsed(
                        offset: form.defaultQuantity.length,
                      ),
                onChanged: notifier.setDefaultQuantity,
              ),
            ),
          ],
        ),

        SizedBox(height: spacing),

        Row(
          children: [
            Expanded(
              child: CoreTextField(
                label: 'unit_net_price_label'.tr,
                hintText: '100.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller:
                    TextEditingController(text: form.unitNetPrice)
                      ..selection = TextSelection.collapsed(
                        offset: form.unitNetPrice.length,
                      ),
                onChanged: notifier.setUnitNetPrice,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: CoreTextField(
                label:'vat_rate_percent_label'.tr,
                hintText: '23.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: TextEditingController(text: form.vatRate)
                  ..selection = TextSelection.collapsed(
                    offset: form.vatRate.length,
                  ),
                onChanged: notifier.setVatRate,
              ),
            ),
          ],
        ),

        SizedBox(height: spacing),

        Row(
          children: [
            Expanded(
              child: CoreTextField(
                label:'currency_label'.tr,
                controller: TextEditingController(text: form.currency)
                  ..selection = TextSelection.collapsed(
                    offset: form.currency.length,
                  ),
                onChanged: notifier.setCurrency,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: CoreTextField(
                label: 'internal_code_optional_label'.tr,
                controller:
                    TextEditingController(text: form.internalCode)
                      ..selection = TextSelection.collapsed(
                        offset: form.internalCode.length,
                      ),
                onChanged: notifier.setInternalCode,
              ),
            ),
          ],
        ),

        SizedBox(height: spacing * 1.5),

        if (form.errorMessage != null) ...[
          Text(
            form.errorMessage!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8.h),
        ],

        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: elevatedButtonStyleRounded10,
            onPressed: form.isSaving ? null : notifier.save,
            icon: form.isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(
              form.id == null ? 'save_preset_button'.tr : 'save_changes_button'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        ),
      ],
    );
  }
}
