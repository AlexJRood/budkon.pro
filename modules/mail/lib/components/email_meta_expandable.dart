// email_meta_expandable.dart
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Rozwijana sekcja meta do maila:
/// - na dole ZAWSZE widoczny wiersz z nadawcą
/// - po prawej przycisk do rozwijania
/// - po rozwinięciu pokazuje się blok "Od / Do" oraz data
/// ✅ NOW: shows CC and BCC (if provided) under "Do"
class EmailMetaExpandable extends StatefulWidget {
  final String sender;
  final String senderDisplayName;
  final List<String> recipients;

  /// ✅ NEW
  final List<String> cc;

  /// ✅ NEW
  final List<String> bcc;

  final String? sentAt; // ISO lub już sformatowane
  final String? receivedAt; // ISO lub już sformatowane

  /// Twój theme (wystarczy, że ma textColor / dashboardBoarder itd.)
  final dynamic theme;

  /// startowo rozwinięte?
  final bool initiallyExpanded;

  /// Jeśli podasz — ma pierwszeństwo nad sentAt/receivedAt
  final String? dateOverride;

  /// --- Opcjonalna "karta" (tło + ramka) dla czytelności na jasnym tle ---
  final bool useCard;
  final Color? cardColor;
  final Color? cardBorderColor;
  final double cardBorderWidth;
  final double cardBorderRadius;
  final EdgeInsetsGeometry cardPadding;

  /// Kolor tekstu w sekcji rozwijanej (domyślnie lekko przygaszony)
  final Color? secondaryTextColor;

  const EmailMetaExpandable({
    super.key,
    required this.sender,
    required this.senderDisplayName,
    required this.recipients,
    required this.theme,
    this.cc = const [],
    this.bcc = const [],
    this.sentAt,
    this.receivedAt,
    this.initiallyExpanded = false,
    this.dateOverride,
    this.useCard = true,
    this.cardColor,
    this.cardBorderColor,
    this.cardBorderWidth = 1.5,
    this.cardBorderRadius = 10,
    this.cardPadding = const EdgeInsets.all(8),
    this.secondaryTextColor,
  });

  @override
  State<EmailMetaExpandable> createState() => _EmailMetaExpandableState();
}

class _EmailMetaExpandableState extends State<EmailMetaExpandable>
    with TickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    // Check if ISO-like string
    final looksIso = RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw);
    if (!looksIso) return raw;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    // ✅ THIS is the key line
    final local = parsed.toLocal();

    return
      '${local.day.toString().padLeft(2, '0')}.'
          '${local.month.toString().padLeft(2, '0')}.'
          '${local.year} '
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
  }


  Widget _line({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textColor = theme.textColor as Color;

    // MOCNIEJSZY domyślny kolor dla sekcji rozwijanej (ok. 70% krycia)
    final faded = widget.secondaryTextColor ?? textColor.withAlpha(180);
    final borderColor = (widget.cardBorderColor ?? theme.dashboardBoarder) as Color;

    final dateStr =
    (widget.dateOverride != null && widget.dateOverride!.isNotEmpty)
        ? _formatDateTime(widget.dateOverride)
        : _formatDateTime(widget.sentAt ?? widget.receivedAt);

    final visibleName =
    widget.senderDisplayName.isNotEmpty ? widget.senderDisplayName : widget.sender;

    final hasCc = widget.cc.isNotEmpty;
    final hasBcc = widget.bcc.isNotEmpty;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ▼▼▼ Sekcja ROZWIJANA ▼▼▼
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          child: _expanded
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('${"From".tr}: ', style: TextStyle(color: faded)),
                              Text(widget.sender, style: TextStyle(color: faded)),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // ✅ Do
                          _line(
                            label: '${"To:".tr} ',
                            value: widget.recipients.join(', '),
                            color: faded,
                          ),

                          // ✅ CC (only if exists)
                          if (hasCc) ...[
                            const SizedBox(height: 6),
                            _line(
                              label: '${"Cc:".tr} ',
                              value: widget.cc.join(', '),
                              color: faded,
                            ),
                          ],

                          // ✅ BCC (only if exists)
                          if (hasBcc) ...[
                            const SizedBox(height: 6),
                            _line(
                              label: '${"Bcc:".tr} ',
                              value: widget.bcc.join(', '),
                              color: faded,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(dateStr, style: TextStyle(color: faded)),
                  ],
                ),
                Divider(height: 32, color: borderColor),
              ],
            ),
          )
              : const SizedBox.shrink(),
        ),

        // ▼▼▼ Wiersz ZAWSZE widoczny + przycisk po prawej ▼▼▼
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                visibleName,
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.senderDisplayName.isNotEmpty ? 16 : 12,
                  fontWeight: widget.senderDisplayName.isNotEmpty
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _ExpandButton(
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
              color: textColor,
              borderColor: borderColor,
            ),
          ],
        ),
      ],
    );

    if (!widget.useCard) return content;

    // KARTA dla czytelności na jasnym tle
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.cardColor ?? theme.dashboardContainer,
        border: Border.all(
          color: widget.cardBorderColor ?? theme.dashboardBoarder,
          width: widget.cardBorderWidth,
        ),
        borderRadius: BorderRadius.circular(widget.cardBorderRadius),
      ),
      child: Padding(
        padding: widget.cardPadding,
        child: content,
      ),
    );
  }
}

/// Mały przycisk po prawej ze strzałką
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
      height: 36,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: AnimatedRotation(
              turns: expanded ? 0.5 : 0.0, // 180° po rozwinięciu
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(Icons.expand_more, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
