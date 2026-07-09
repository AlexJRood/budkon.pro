import 'package:crm/invoices/providers/template_generator.dart';
import 'package:crm/utils/color_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionResolvedStyle {
  final Color bg;
  final Color text;
  final bool hasBorder;
  final int paddingV;

  const SectionResolvedStyle({
    required this.bg,
    required this.text,
    required this.hasBorder,
    required this.paddingV,
  });
}

SectionResolvedStyle resolveSectionStyle(
  InvoiceSectionConfig section, {
  required Color globalBg,
  required Color globalText,
  required Color globalBorder,
  required int globalSectionSpacing,
}) {
  final bool custom = section.useCustomBranding;

  final bg =
      custom
          ? (section.backgroundColor?.toColor(fallback: globalBg) ?? globalBg)
          : globalBg;

  final text =
      custom
          ? (section.textColor?.toColor(fallback: globalText) ?? globalText)
          : globalText;

  final paddingV = (section.paddingVertical ?? globalSectionSpacing).clamp(
    0,
    128,
  );

  return SectionResolvedStyle(
    bg: bg,
    text: text,
    hasBorder: section.hasBorder,
    paddingV: paddingV,
  );
}

Widget wrapSection({
  required Widget child,
  required int paddingV,
  required bool hasBorder,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      vertical: paddingV.toDouble(),
      horizontal: 8.w,
    ),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.r)),
    child: child,
  );
}
