import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/invoices/models/templates.dart';
import 'package:crm/invoices/providers/template_generator.dart';
import 'package:crm/invoices/providers/template_list.dart';
import 'package:crm/invoices/screen/template_generator.dart';
import 'package:crm/invoices/urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

/// Main screen: list of templates + actions.
class InvoiceTemplateListScreen extends ConsumerWidget {
  const InvoiceTemplateListScreen({super.key});

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
      childPc: _DesktopTemplateList(theme: theme),
      childMobile: _MobileTemplateList(theme: theme),
    );
  }
}

class _DesktopTemplateList extends ConsumerWidget {
  final ThemeColors theme;

  const _DesktopTemplateList({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTemplates = ref.watch(invoiceTemplateListProvider);

Future<void> setDefaultTemplate(InvoiceTemplateModel tpl) async {
  try {
    final url = '${URLsInvoice.invoiceTemplates}${tpl.id}/set-default/';
    await ApiServices.post(
      url,
      data: const {}, // nic nie musimy wysyłać
      hasToken: true,
      ref: ref,
    );

    ref.invalidate(invoiceTemplateListProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('default_template_updated_message'.tr),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'failed_to_set_default_template'.tr} $e'),
      ),
    );
  }
}


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'invoice_templates_title'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: elevatedButtonStyleRounded10,
              onPressed: () {
                // Reset form + open generator in "new" mode.
                ref.read(invoiceTemplateFormProvider.notifier).reset();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InvoiceTemplateGeneratorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(
                'new_template_button'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'template_list_description'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(178),
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.dashboardContainer.withAlpha(230),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: theme.themeColor.withAlpha(51),
              ),
            ),
            child: asyncTemplates.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'no_templates_yet'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(178),
                        fontSize: 13.sp,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dashboardBoarder.withAlpha(102),
                  ),
                  itemBuilder: (context, index) {
                    final tpl = list[index];
                    return _TemplateListTile(
                      template: tpl,
                      theme: theme,
                      onTap: () async {
                        // Load into form & open editor.
                        ref
                            .read(invoiceTemplateFormProvider.notifier)
                            .loadFromModel(tpl);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const InvoiceTemplateGeneratorScreen(),
                          ),
                        );
                      },
                      onSetDefault: () => setDefaultTemplate(tpl),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text(
                  '${'error_loading_templates'.tr} $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileTemplateList extends ConsumerWidget {
  final ThemeColors theme;

  const _MobileTemplateList({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTemplates = ref.watch(invoiceTemplateListProvider);

    Future<void> setDefaultTemplate(InvoiceTemplateModel tpl) async {
      try {
        final url = '${URLsInvoice.invoiceTemplates}${tpl.id}/';
        await ApiServices.patch(
          url,
          data: {'is_default': true},
          hasToken: true,
          ref: ref,
        );
        ref.invalidate(invoiceTemplateListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('default_template_updated_message'.tr),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_to_set_default_template'.tr} $e'),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 48.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'invoice_templates_title'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(invoiceTemplateFormProvider.notifier).reset();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InvoiceTemplateGeneratorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: asyncTemplates.when(
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'no_templates_yet'.tr,                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                      fontSize: 13.sp,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final tpl = list[index];
                  return Card(
                    color: theme.dashboardContainer.withAlpha(242),
                    child: ListTile(
                      title: Text(
                        tpl.name,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${tpl.scope} • '
                        '${tpl.isDefault ? 'default_template_status'.tr: 'default_template_status'.tr}',
                        style: TextStyle(
                          color: theme.textColor.withAlpha(178),
                          fontSize: 11.sp,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: tpl.isDefault
                                ? 'current_default_tooltip'.tr
                                : 'set_as_default_button'.tr,
                            onPressed: tpl.isDefault
                                ? null
                                : () => setDefaultTemplate(tpl),
                            icon: Icon(
                              tpl.isDefault
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        ref
                            .read(invoiceTemplateFormProvider.notifier)
                            .loadFromModel(tpl);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const InvoiceTemplateGeneratorScreen(),
                          ),
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

class _TemplateListTile extends StatelessWidget {
  final InvoiceTemplateModel template;
  final ThemeColors theme;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;

  const _TemplateListTile({
    super.key,
    required this.template,
    required this.theme,
    required this.onTap,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = template.isDefault;
    final scopeLabel =
        template.scope == 'user' ? 'User specific' : 'Company default';

    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isDefault) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.themeColor.withAlpha(38),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'default_badge'.tr,
                            style: TextStyle(
                              color: theme.themeColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$scopeLabel • ${template.paperSize} • ${template.orientation}',
                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: isDefault ? null : onSetDefault,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 32.h),
                  ),
                  icon: Icon(
                    isDefault ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18.sp,
                    color:
                        isDefault ? theme.themeColor : theme.textColor.withAlpha(178),
                  ),
                  label: Text(
                    isDefault ?'default_badge'.tr : 'set_default_button'.tr,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color:
                          isDefault ? theme.themeColor : theme.textColor.withAlpha(204),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                const Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
