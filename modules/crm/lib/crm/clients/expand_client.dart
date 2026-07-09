import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/button_style.dart';

/// Custom expandable tile for client rows without using ExpansionTile.
/// - Always-visible header row (name + custom expand button)
/// - Smooth height animation for the details block
/// - Uses your theme colors: textColor, adPopBackground, dashboardContainer, adPopBackground
class ClientExpandableTile extends StatefulWidget {
  final dynamic theme;

  final String title;
  final String? status;
  final String? email;
  final String? phone;

  /// Optional leading widget in the header (e.g., avatar/icon).
  final Widget? leading;

  /// Fired when user taps "View profile"
  final VoidCallback onViewProfile;

  /// Start expanded?
  final bool initiallyExpanded;

  /// Card-like look (background + border)
  final bool useCard;
  final Color? cardColor;
  final Color? cardBorderColor;
  final double cardBorderWidth;
  final double cardBorderRadius;
  final EdgeInsetsGeometry cardPadding;

  /// Secondary/faded text color for details
  final Color? secondaryTextColor;

  const ClientExpandableTile({
    super.key,
    required this.theme,
    required this.title,
    required this.onViewProfile,
    this.status,
    this.email,
    this.phone,
    this.leading,
    this.initiallyExpanded = false,
    this.useCard = true,
    this.cardColor,
    this.cardBorderColor,
    this.cardBorderWidth = 1.5,
    this.cardBorderRadius = 10,
    this.cardPadding = const EdgeInsets.all(12),
    this.secondaryTextColor,
  });

  @override
  State<ClientExpandableTile> createState() => _ClientExpandableTileState();
}

class _ClientExpandableTileState extends State<ClientExpandableTile>
    with TickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final Color textColor = theme.textColor as Color;
    final Color borderColor =
        (widget.cardBorderColor ?? theme.adPopBackground) as Color;

    final faded = widget.secondaryTextColor ?? textColor.withAlpha(170);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ▼▼▼ Details (animated) ▼▼▼
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          child: !_expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Status'.tr,
                        value: widget.status ?? '-',
                        labelColor: faded,
                        valueColor: textColor,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Email'.tr,
                        value: widget.email ?? '-',
                        labelColor: faded,
                        valueColor: textColor,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Phone'.tr,
                        value: widget.phone ?? '-',
                        labelColor: faded,
                        valueColor: textColor,
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 32, color: borderColor),
                      InkWell(
                        onTap: widget.onViewProfile,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_red_eye, color: textColor),
                              const SizedBox(width: 6),
                              Text("View profile".tr,
                                  style: TextStyle(color: textColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ///////// Feature to finish in version 2.0 //////// 



            // const SizedBox(width: 8),
            // _ExpandButton(
            //   expanded: _expanded,
            //   onTap: () => setState(() => _expanded = !_expanded),
            //   color: textColor,
            //   borderColor: borderColor,
            // ),
          ],
        ),
      ],
    );

    if (!widget.useCard) return content;

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor ?? theme.dashboardContainer,
        border: Border.all(
          color: widget.cardBorderColor ?? theme.adPopBackground,
          width: widget.cardBorderWidth,
        ),
        borderRadius: BorderRadius.circular(widget.cardBorderRadius),
      ),
      padding: widget.cardPadding,
      child: content,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    // Label on the left (faded), value on the right (strong)
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: labelColor),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;

  const _ExpandButton({
    required this.expanded,
    required this.onTap,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: ElevatedButton(
          style: elevatedButtonStyleRounded10,
          onPressed: onTap,
            child: AnimatedRotation(
              turns: expanded ? 0.5 : 0.0, // 180°
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(Icons.expand_more, color: color, size: 22),
            ),
        ),
      ),
    );
  }
}
