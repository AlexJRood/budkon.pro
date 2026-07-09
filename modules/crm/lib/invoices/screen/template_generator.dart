// lib/invoices/screens/invoice_template_generator_screen.dart
// Main screen for invoice template builder.

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/invoices/components/logo_url_drop_field.dart';
import 'package:crm/invoices/components/preview.dart';
import 'package:crm/invoices/providers/template_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/text_field.dart';

class InvoiceTemplateGeneratorScreen extends ConsumerWidget {
  const InvoiceTemplateGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      paddingTablet: 14,
      childPc: _DesktopContent(theme: theme),
      childTablet: _TabletContent(theme: theme),
      childMobile: _MobileContent(theme: theme),
    );
  }
}

class _DesktopContent extends ConsumerWidget {
  final ThemeColors theme;

  const _DesktopContent({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(invoiceTemplateFormProvider);
    final notifier = ref.read(invoiceTemplateFormProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel – editor (scrollable)
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(217),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: theme.themeColor.withAlpha(51),
                width: 1,
              ),
            ),
            child: DefaultTextStyle(
              style: TextStyle(color: theme.textColor, fontSize: 13.sp),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _EditorForm(
                        theme: theme,
                        form: form,
                        notifier: notifier,
                        isDesktop: true,
                        isTablet: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        SizedBox(width: 16.w),
        // Right panel – preview
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(166),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.themeColor.withAlpha(64)),
            ),
            child: InvoiceTemplateLivePreview(
              form: form,
              theme: theme,
              notifier: notifier,
              onDownloadSample: () => notifier.downloadSampleInvoice(),
            ),
          ),
        ),
      ],
    );
  }
}
class _TabletContent extends ConsumerWidget {
  final ThemeColors theme;

  const _TabletContent({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(invoiceTemplateFormProvider);
    final notifier = ref.read(invoiceTemplateFormProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT PANEL — EDITOR
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(217),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: theme.themeColor.withAlpha(51),
                width: 1,
              ),
            ),
            child: DefaultTextStyle(
              style: TextStyle(color: theme.textColor, fontSize: 11.sp),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _EditorForm(
                        theme: theme,
                        form: form,
                        notifier: notifier,
                        isDesktop: false,
                        isTablet:true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // RIGHT PANEL — PREVIEW
        Expanded(
          flex: 5,
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(166),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.themeColor.withAlpha(64)),
            ),
            child: InvoiceTemplateLivePreview(
              form: form,
              theme: theme,
              notifier: notifier,
              onDownloadSample: () => notifier.downloadSampleInvoice(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileContent extends ConsumerWidget {
  final ThemeColors theme;

  const _MobileContent({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(invoiceTemplateFormProvider);
    final notifier = ref.read(invoiceTemplateFormProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 64.h, left: 8.w, right: 8.w, bottom: 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(230),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: theme.themeColor.withAlpha(51)),
            ),
            child: DefaultTextStyle(
              style: TextStyle(color: theme.textColor, fontSize: 13.sp),
              child: _EditorForm(
                theme: theme,
                form: form,
                notifier: notifier,
                isDesktop: false,
                isTablet: false,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(178),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: theme.themeColor.withAlpha(64)),
            ),
            child: SizedBox(
              height: 500.h,
              child: InvoiceTemplateLivePreview(
                form: form,
                theme: theme,
                notifier: notifier,
                onDownloadSample: () => notifier.downloadSampleInvoice(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorForm extends StatelessWidget {
  final ThemeColors theme;
  final InvoiceTemplateFormState form;
  final InvoiceTemplateFormNotifier notifier;
  final bool isDesktop;
  final bool isTablet;

  const _EditorForm({
    required this.theme,
    required this.form,
    required this.notifier,
    required this.isDesktop,
    required this.isTablet
  });

  TextStyle get _sectionTitleStyle => TextStyle(
    color: theme.textColor,
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
  );

  TextStyle get _labelStyle =>
      TextStyle(color: theme.textColor.withAlpha(191), fontSize: 12.sp);

  @override
  Widget build(BuildContext context) {
    final spacing = 10.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + Save
        Row(
          children: [
            Expanded(
              child: Text(
                'Invoice Template Generator'.tr,
                style: _sectionTitleStyle.copyWith(fontSize: 18.sp),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              style: elevatedButtonStyleRounded10,
              onPressed: form.isSaving ? null : () => notifier.saveTemplate(),
              icon:
                  form.isSaving
                      ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined, size: 18),
              label: Text(
                form.id == null ? 'Save new'.tr : 'Save changes'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Po lewej edytujesz, po prawej masz live podgląd faktury.',
          style: _labelStyle,
        ),

        SizedBox(height: 16.h),

        // BASIC SETTINGS SECTION
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(102),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: theme.themeColor.withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Basic settings'.tr, style: _sectionTitleStyle),
              SizedBox(height: spacing),
              CoreTextField(
                label: 'Template name'.tr,
                controller: TextEditingController(text: form.name)
                  ..selection = TextSelection.collapsed(
                    offset: form.name.length,
                  ),
                onChanged: notifier.setName,
              ),
              SizedBox(height: spacing),
              isTablet?
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  // Scope
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Scope'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.scope,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(
                              value: 'company',
                              child: Text('Company'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User'.tr),
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
                  SizedBox(width: 8.w),
                  // Paper size
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Paper size'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.paperSize,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(value: 'A4', child: Text('A4')),
                            DropdownMenuItem(
                              value: 'Letter',
                              child: Text('Letter'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setPaperSize(v);
                          },
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Orientation
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Orientation'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.orientation,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(
                              value: 'portrait',
                              child: Text('Portrait'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'landscape',
                              child: Text('Landscape'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setOrientation(v);
                          },
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              :Row(
                children: [
                  // Scope
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Scope'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.scope,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(
                              value: 'company',
                              child: Text('Company'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User'.tr),
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
                  SizedBox(width: 8.w),
                  // Paper size
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Paper size'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.paperSize,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(value: 'A4', child: Text('A4')),
                            DropdownMenuItem(
                              value: 'Letter',
                              child: Text('Letter'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setPaperSize(v);
                          },
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Orientation
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Orientation'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.orientation,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(
                              value: 'portrait',
                              child: Text('Portrait'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'landscape',
                              child: Text('Landscape'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setOrientation(v);
                          },
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // GENERAL BRANDING + MARGINS SECTION
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(102),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: theme.themeColor.withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General branding & margins'.tr, style: _sectionTitleStyle),
              SizedBox(height: spacing),
              isTablet
                  ?Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Logo position'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.logoPosition,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(
                              value: 'left',
                              child: Text('Left of title'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'right',
                              child: Text('Right side'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'center',
                              child: Text('Centered above'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setLogoPosition(v);
                          },
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CoreTextField(
                      label: 'Section spacing (px)'.tr,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: form.sectionSpacing.toString(),
                      )
                        ..selection = TextSelection.collapsed(
                          offset: form.sectionSpacing.toString().length,
                        ),
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? form.sectionSpacing;
                        final clamped = n.clamp(4, 64);
                        notifier.setSectionSpacing(clamped);
                      },
                    ),
                  ),
                ],
              )
                  :Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Logo position'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.logoPosition,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(
                              value: 'left',
                              child: Text('Left of title'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'right',
                              child: Text('Right side'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'center',
                              child: Text('Centered above'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setLogoPosition(v);
                          },
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CoreTextField(
                      label: 'Section spacing (px)'.tr,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: form.sectionSpacing.toString(),
                        )
                        ..selection = TextSelection.collapsed(
                          offset: form.sectionSpacing.toString().length,
                        ),
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? form.sectionSpacing;
                        final clamped = n.clamp(4, 64);
                        notifier.setSectionSpacing(clamped);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: _coreLikeDecoration('Logo placement'.tr),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: form.logoPlacement,
                          isDense: true,
                          dropdownColor: theme.adPopBackground,
                          items:  [
                            DropdownMenuItem(
                              value: 'header',
                              child: Text('In header'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'footer',
                              child: Text('In footer'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'none',
                              child: Text('Hidden'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setLogoPlacement(v);
                          },
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              DesktopDropWrapper(
                onDropFiles: (files) async {
                  if (files.isEmpty) return;
                  final f = files.first;
                  String pickedPath = '';

                  try {
                    final p = (f as dynamic).path;
                    if (p is String && p.isNotEmpty) pickedPath = p;
                  } catch (_) {}
                  if (pickedPath.isEmpty) {
                    try {
                      final n = (f as dynamic).name;
                      if (n is String && n.isNotEmpty) pickedPath = n;
                    } catch (_) {}
                  }
                  if (pickedPath.isNotEmpty) {
                    notifier.setLogoUrl(pickedPath);
                  }
                },
                child: CoreTextField(
                  label: 'Logo URL (optional)'.tr,
                  hintText: 'https://.../logo.png',
                  controller: TextEditingController(text: form.logoUrl ?? '')
                    ..selection = TextSelection.collapsed(
                      offset: (form.logoUrl ?? '').length,
                    ),
                  onChanged: notifier.setLogoUrl,
                ),
              ),

              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: ColorPickerField(
                      label: 'Primary color'.tr,
                      value: form.primaryColor,
                      onChanged: notifier.setPrimaryColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ColorPickerField(
                      label: 'Secondary color'.tr,
                      value: form.secondaryColor,
                      onChanged: notifier.setSecondaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: ColorPickerField(
                      label: 'Accent color'.tr,
                      value: form.accentColor,
                      onChanged: notifier.setAccentColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CoreTextField(
                      label: 'Font family'.tr,
                      controller: TextEditingController(text: form.fontFamily)
                        ..selection = TextSelection.collapsed(
                          offset: form.fontFamily.length,
                        ),
                      onChanged: notifier.setFontFamily,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Text(
                'Margins (mm)'.tr,
                style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: CoreTextField(
                      label: 'Top'.tr,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: form.marginTop.toString(),
                        )
                        ..selection = TextSelection.collapsed(
                          offset: form.marginTop.toString().length,
                        ),
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? form.marginTop;
                        notifier.setMargins(top: n);
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CoreTextField(
                      label: 'Bottom'.tr,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: form.marginBottom.toString(),
                        )
                        ..selection = TextSelection.collapsed(
                          offset: form.marginBottom.toString().length,
                        ),
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? form.marginBottom;
                        notifier.setMargins(bottom: n);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: CoreTextField(
                      label: 'Left'.tr,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: form.marginLeft.toString(),
                        )
                        ..selection = TextSelection.collapsed(
                          offset: form.marginLeft.toString().length,
                        ),
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? form.marginLeft;
                        notifier.setMargins(left: n);
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CoreTextField(
                      label: 'Right'.tr,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: form.marginRight.toString(),
                        )
                        ..selection = TextSelection.collapsed(
                          offset: form.marginRight.toString().length,
                        ),
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? form.marginRight;
                        notifier.setMargins(right: n);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // SECTIONS LAYOUT + PER-SECTION DETAILS
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(102),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: theme.themeColor.withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sections layout'.tr, style: _sectionTitleStyle),
              SizedBox(height: spacing / 2),
              Text(
                'Ustaw kolejność, widoczność oraz szczegóły każdej sekcji. Kliknij sekcję, aby edytować ustawienia poniżej.',
                style: _labelStyle,
              ),
              SizedBox(height: spacing),
              SizedBox(
                height: 180.h,
                child: ReorderableListView(
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.zero,
                  onReorder: notifier.reorderSections,
                  children: [
                    for (int i = 0; i < form.sections.length; i++)
                      _buildSectionRow(
                        context,
                        form.sections[i],
                        i,
                        notifier,
                        isActive: form.activeSectionId == form.sections[i].id,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      () => _openAddSectionDialog(context, form, notifier),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj sekcję'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.themeColor,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              _buildSectionDetailsPanel(form, notifier),
            ],
          ),
        ),

        if (form.errorMessage != null) ...[
          SizedBox(height: 12.h),
          Text(
            form.errorMessage!,
            style: TextStyle(color: Colors.redAccent, fontSize: 12.sp),
          ),
        ],

        SizedBox(height: isDesktop ? 8.h : 24.h),
      ],
    );
  }

  // Dropdown decoration similar to CoreTextField.
  InputDecoration _coreLikeDecoration(String label) {
    final borderColor = theme.textColor.withAlpha((255 * 0.5).toInt());
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.textColor),
      floatingLabelStyle: TextStyle(color: theme.textColor.withAlpha(120)),
      filled: true,
      fillColor: theme.adPopBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: theme.themeColor, width: 1.5),
      ),
    );
  }

  Widget _columnChip(String key, String label) {
    final isSelected = form.columns.contains(key);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.white : theme.textColor,
          fontSize: 12.sp,
        ),
      ),
      selected: isSelected,
      selectedColor: theme.themeColor,
      backgroundColor: theme.adPopBackground.withAlpha(178),
      onSelected: (_) => notifier.toggleColumn(key),
    );
  }

  Widget _buildSectionRow(
    BuildContext context,
    InvoiceSectionConfig section,
    int index,
    InvoiceTemplateFormNotifier notifier, {
    required bool isActive,
  }) {
    final isSystem = section.type == 'system';

    return Container(
      key: ValueKey<String>('section_row_${section.id}'),
      margin: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color:
            isActive
                ? theme.themeColor.withAlpha(46)
                : theme.adPopBackground.withAlpha(242),
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: () => notifier.setActiveSection(section.id),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18.sp,
                      color: theme.textColor.withAlpha(178),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.label,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isSystem ? 'System section'.tr : 'Custom section'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(153),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: section.visible,
                  onChanged: (v) => notifier.setSectionVisible(section.id, v),
                  activeThumbColor: theme.themeColor,
                ),
                if (!isSystem)
                  IconButton(
                    tooltip: 'Remove section'.tr,
                    onPressed: () => notifier.removeSection(section.id),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18.sp,
                      color: Colors.redAccent.withAlpha(230),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDetailsPanel(
    InvoiceTemplateFormState form,
    InvoiceTemplateFormNotifier notifier,
  ) {
    if (form.sections.isEmpty) {
      return Text('No sections defined.', style: _labelStyle);
    }

    String activeId = form.activeSectionId ?? form.sections.first.id;
    final section = form.sections.firstWhere(
      (s) => s.id == activeId,
      orElse: () => form.sections.first,
    );

    final spacing = 8.h;

    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(217),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: theme.themeColor.withAlpha(64)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Section details – ${section.label}',
            style: _sectionTitleStyle.copyWith(fontSize: 14.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tutaj konfigurujesz branding i logikę tej sekcji.',
            style: _labelStyle.copyWith(fontSize: 11.sp),
          ),
          SizedBox(height: spacing),

          // Border toggle
          SwitchListTile(
            value: section.hasBorder,
            title: Text(
              'Show border/frame for this section'.tr,
              style: _labelStyle,
            ),
            activeThumbColor: theme.themeColor,
            contentPadding: EdgeInsets.zero,
            onChanged:
                (v) => notifier.updateSectionBranding(section.id, hasBorder: v),
          ),

          // Per-section branding toggles
          SwitchListTile(
            value: section.useCustomBranding,
            title: Text(
              'Use custom branding for this section'.tr,
              style: _labelStyle,
            ),
            activeThumbColor: theme.themeColor,
            contentPadding: EdgeInsets.zero,
            onChanged:
                (v) => notifier.updateSectionBranding(
                  section.id,
                  useCustomBranding: v,
                ),
          ),
          if (section.useCustomBranding) ...[
            SizedBox(height: spacing / 2),
            Row(
              children: [
                Expanded(
                  child: ColorPickerField(
                    label: 'Background color'.tr,
                    value: section.backgroundColor ?? form.accentColor,
                    onChanged:
                        (hex) => notifier.updateSectionBranding(
                          section.id,
                          backgroundColor: hex,
                        ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ColorPickerField(
                    label: 'Text color'.tr,
                    value: section.textColor ?? form.primaryColor,
                    onChanged:
                        (hex) => notifier.updateSectionBranding(
                          section.id,
                          textColor: hex,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            CoreTextField(
              label: 'Vertical padding (px)'.tr,
              keyboardType: TextInputType.number,
              controller: TextEditingController(
                  text:
                      (section.paddingVertical ?? form.sectionSpacing)
                          .toString(),
                )
                ..selection = TextSelection.collapsed(
                  offset:
                      (section.paddingVertical ?? form.sectionSpacing)
                          .toString()
                          .length,
                ),
              onChanged: (v) {
                final n =
                    int.tryParse(v) ??
                    (section.paddingVertical ?? form.sectionSpacing);
                final clamped = n.clamp(0, 128);
                notifier.updateSectionBranding(
                  section.id,
                  paddingVertical: clamped,
                );
              },
            ),
            SizedBox(height: spacing),
          ],

          // Section-specific logic / fields
          _buildSectionSpecificControls(section, notifier, spacing),
        ],
      ),
    );
  }

  Widget _buildSectionSpecificControls(
    InvoiceSectionConfig section,
    InvoiceTemplateFormNotifier notifier,
    double spacing,
  ) {
    switch (section.id) {
      case 'header':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Header options'.tr,
              style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing / 2),
            SwitchListTile(
              value: form.showLogo,
              title: Text('Show logo box'.tr, style: _labelStyle),
              activeThumbColor: theme.themeColor,
              contentPadding: EdgeInsets.zero,
              onChanged: notifier.toggleShowLogo,
            ),
          ],
        );

      case 'parties':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parties section'.tr,
              style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing / 2),
            Text(
              'Seller & buyer boxes są generowane automatycznie. W kolejnej wersji dodamy więcej opcji dla pól adresowych.'.tr,
              style: _labelStyle.copyWith(fontSize: 11.sp),
            ),
          ],
        );

      case 'items':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items table options'.tr,
              style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing / 2),
            Text('Columns in items table'.tr, style: _labelStyle),
            SizedBox(height: 4.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _columnChip('name', 'Name'),
                _columnChip('quantity', 'Quantity'),
                _columnChip('unit_net_price', 'Net unit price'),
                _columnChip('vat', 'VAT'),
                _columnChip('line_gross_amount', 'Gross'),
              ],
            ),
          ],
        );

      case 'payments':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments & bank options',
              style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing / 2),
            SwitchListTile(
              value: form.showPaymentTerms,
              title: Text('Show payment terms block', style: _labelStyle),
              activeThumbColor: theme.themeColor,
              contentPadding: EdgeInsets.zero,
              onChanged: notifier.toggleShowPaymentTerms,
            ),
            SwitchListTile(
              value: form.showBankAccount,
              title: Text('Show bank account block', style: _labelStyle),
              activeThumbColor: theme.themeColor,
              contentPadding: EdgeInsets.zero,
              onChanged: notifier.toggleShowBankAccount,
            ),
            SizedBox(height: spacing),
            CoreTextField(
              label: 'Payment terms label',
              controller: TextEditingController(text: form.paymentTermsLabel)
                ..selection = TextSelection.collapsed(
                  offset: form.paymentTermsLabel.length,
                ),
              onChanged: notifier.setPaymentTermsLabel,
            ),
          ],
        );

      case 'footer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Footer & notes',
              style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing),
            CoreTextField(
              label: 'Footer text',
              maxLines: 2,
              controller: TextEditingController(text: form.footerText)
                ..selection = TextSelection.collapsed(
                  offset: form.footerText.length,
                ),
              onChanged: notifier.setFooterText,
            ),
            SizedBox(height: spacing),
            CoreTextField(
              label: 'Extra notes label',
              controller: TextEditingController(text: form.extraNotesLabel)
                ..selection = TextSelection.collapsed(
                  offset: form.extraNotesLabel.length,
                ),
              onChanged: notifier.setExtraNotesLabel,
            ),
          ],
        );

      default:
        // Custom section
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom section content',
              style: _labelStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing),
            CoreTextField(
              label: 'Section label (editor only)',
              controller: TextEditingController(text: section.label)
                ..selection = TextSelection.collapsed(
                  offset: section.label.length,
                ),
              onChanged:
                  (value) => notifier.updateSectionLabel(section.id, value),
            ),
            SizedBox(height: spacing),
            CoreTextField(
              label: 'Content text (displayed on invoice)',
              maxLines: 3,
              controller: TextEditingController(text: section.customText ?? '')
                ..selection = TextSelection.collapsed(
                  offset: (section.customText ?? '').length,
                ),
              onChanged:
                  (value) =>
                      notifier.updateSectionCustomText(section.id, value),
            ),
          ],
        );
    }
  }

  void _openAddSectionDialog(
    BuildContext context,
    InvoiceTemplateFormState form,
    InvoiceTemplateFormNotifier notifier,
  ) {
    final existingIds = form.sections.map((s) => s.id).toSet();

    final options = <Map<String, String>>[
      if (!existingIds.contains('header')) {'id': 'header', 'label': 'Header'},
      if (!existingIds.contains('parties'))
        {'id': 'parties', 'label': 'Seller & buyer'},
      if (!existingIds.contains('items'))
        {'id': 'items', 'label': 'Items table'},
      if (!existingIds.contains('payments'))
        {'id': 'payments', 'label': 'Payments & bank'},
      if (!existingIds.contains('footer'))
        {'id': 'footer', 'label': 'Footer / notes'},
      {'id': 'custom', 'label': 'Custom section'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Dodaj sekcję'),
          content: SizedBox(
            width: 320,
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final opt = options[index];
                return ListTile(
                  title: Text(opt['label']!),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    notifier.addSection(opt['id']!);
                  },
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: options.length,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

/// TextField + color preview + dialog with palette picker.
/// Keeps HEX string (e.g. "#RRGGBB") so it matches API.
class ColorPickerField extends ConsumerStatefulWidget {
  final String label;
  final String value; // HEX: #RRGGBB
  final ValueChanged<String> onChanged;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  ConsumerState<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends ConsumerState<ColorPickerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant ColorPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _hexToColorSafe(String hex) {
    var value = hex.trim();
    if (!value.startsWith('#')) value = '#$value';
    if (value.length == 4) {
      final r = value[1];
      final g = value[2];
      final b = value[3];
      value = '#$r$r$g$g$b$b';
    }
    try {
      if (value.length == 7) {
        return Color(int.parse(value.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}
    return Colors.black;
  }

  void _openPicker() async {
    final baseColor = _hexToColorSafe(_controller.text);
    Color selected = baseColor;

    final theme = ref.read(themeColorsProvider);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          title: Text(widget.label, style: TextStyle(color: theme.textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlockPicker(
                  pickerColor: baseColor,
                  onColorChanged: (c) => selected = c,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: theme.textColor)),
            ),
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(6),
                ),
              ),

              onPressed: () {
                Navigator.of(ctx).pop();
                final hex =
                    '#${selected.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                _controller.text = hex;
                widget.onChanged(hex);
              },
              child: Text('OK', style: TextStyle(color: theme.themeColorText)),
            ),
          ],
        );
      },
    ).then((_) {
      // Force rebuild of suffix color preview.
      setState(() {});
    });

    // Optional: update on picker open to ensure preview matches text.
    ref.read(themeColorsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexToColorSafe(_controller.text);
    final theme = ref.read(themeColorsProvider);

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
        floatingLabelStyle: TextStyle(color: theme.textColor),
        isDense: true,
        filled: true,
        fillColor: theme.adPopBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.themeColor, width: 1),
        ),

        suffixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        suffixIcon: GestureDetector(
          onTap: _openPicker,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.dashboardBoarder),
            ),
          ),
        ),
      ),
    );
  }
}
