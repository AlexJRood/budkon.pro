import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/professional_credential_model.dart';

Future<void> showProfessionalLicenseSheet({
  required BuildContext context,
  required List<ProfessionalCredentialModel> credentials,
  ThemeColors? theme,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controller) {
          final activeTheme = theme;
          return Container(
            decoration: BoxDecoration(
              color: activeTheme?.dashboardContainer ?? Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 30,
                  offset: Offset(0, -10),
                  color: Colors.black26,
                ),
              ],
            ),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(24.w, 12, 24.w, 32),
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: (activeTheme?.textColor ?? Colors.white).withAlpha(80),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: activeTheme?.textColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'professional_license'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: activeTheme?.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: activeTheme?.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (credentials.isEmpty)
                  _EmptyLicenseCard(theme: activeTheme)
                else
                  ...credentials.map(
                    (credential) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ProfessionalLicenseCard(
                        credential: credential,
                        theme: activeTheme,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class ProfessionalLicenseButton extends StatelessWidget {
  final List<ProfessionalCredentialModel> credentials;
  final ThemeColors? theme;
  final bool compact;

  const ProfessionalLicenseButton({
    super.key,
    required this.credentials,
    this.theme,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = credentials.isNotEmpty ? credentials.first : null;
    final isVerified = primary?.isVerified ?? false;
    final label = primary == null
        ? 'add_license'.tr
        : isVerified
            ? '${'license_verified'.tr}: ${primary.displayNumber}'
            : '${'license'.tr}: ${primary.displayNumber}';

    return InkWell(
      onTap: () => showProfessionalLicenseSheet(
        context: context,
        credentials: credentials,
        theme: theme,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isVerified
                ? Colors.green.withAlpha(180)
                : (theme?.textColor ?? Colors.white).withAlpha(80),
          ),
          color: isVerified
              ? Colors.green.withAlpha(20)
              : (theme?.textColor ?? Colors.white).withAlpha(10),
        ),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.verified_rounded : Icons.badge_outlined,
              color: isVerified ? Colors.green : theme?.textColor,
              size: compact ? 18 : 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme?.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: theme?.textColor?.withAlpha(160),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessionalLicenseCard extends StatelessWidget {
  final ProfessionalCredentialModel credential;
  final ThemeColors? theme;

  const ProfessionalLicenseCard({
    super.key,
    required this.credential,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = theme?.textColor ?? Theme.of(context).colorScheme.onSurface;
    final statusColor = credential.isVerified
        ? Colors.green
        : credential.isPending
            ? Colors.orange
            : credential.isExpired
                ? Colors.redAccent
                : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: textColor.withAlpha(10),
        border: Border.all(color: textColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withAlpha(28),
                ),
                child: Icon(
                  credential.isVerified
                      ? Icons.verified_rounded
                      : Icons.badge_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.displayName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'license_number'.tr}: ${credential.displayNumber}',
                      style: TextStyle(
                        color: textColor.withAlpha(170),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                text: _statusLabel(credential),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoGrid(
            theme: theme,
            rows: [
              _InfoRow('valid_until'.tr, credential.displayValidUntil),
              _InfoRow('company'.tr, credential.displayCompany),
              _InfoRow('insurance'.tr, credential.data.insuranceCompany),
              _InfoRow('insurance_valid_until'.tr, credential.data.insuranceValidUntil),
              _InfoRow('insurance_sum'.tr, credential.data.insuranceSum),
              _InfoRow('association'.tr, credential.data.associationName),
            ],
          ),
          const SizedBox(height: 14),
          _LinksBlock(credential: credential, theme: theme),
        ],
      ),
    );
  }

  String _statusLabel(ProfessionalCredentialModel credential) {
    if (credential.isVerified) return 'verified'.tr;
    if (credential.isPending) return 'pending'.tr;
    if (credential.isExpired) return 'expired'.tr;
    if (credential.status == 'not_found') return 'not_found'.tr;
    if (credential.status == 'mismatch') return 'mismatch'.tr;
    return credential.status.isEmpty ? 'unknown'.tr : credential.status.tr;
  }
}

class _InfoRow {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoRow> rows;
  final ThemeColors? theme;

  const _InfoGrid({required this.rows, this.theme});

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.where((row) => (row.value ?? '').trim().isNotEmpty).toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: visibleRows.map((row) {
        return Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: (theme?.textColor ?? Colors.white).withAlpha(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: TextStyle(
                  color: theme?.textColor?.withAlpha(150),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                row.value ?? '',
                style: TextStyle(
                  color: theme?.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LinksBlock extends StatelessWidget {
  final ProfessionalCredentialModel credential;
  final ThemeColors? theme;

  const _LinksBlock({required this.credential, this.theme});

  @override
  Widget build(BuildContext context) {
    final links = <String, String>{};

    void add(String label, String? url) {
      final value = url?.trim();
      if (value == null || value.isEmpty) return;
      links[label] = value;
    }

    add('federation_profile'.tr, credential.federationUrl);
    add('company_profile'.tr, credential.companyFederationUrl);
    add('company_website'.tr, credential.companyWebsiteUrl);
    add('association'.tr, credential.data.associationUrl);

    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'links'.tr,
          style: TextStyle(
            color: theme?.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...links.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SelectableText(
              '${entry.key}: ${entry.value}',
              style: TextStyle(
                color: theme?.textColor?.withAlpha(190),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withAlpha(26),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyLicenseCard extends StatelessWidget {
  final ThemeColors? theme;

  const _EmptyLicenseCard({this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (theme?.textColor ?? Colors.white).withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(Icons.badge_outlined, size: 38, color: theme?.textColor),
          const SizedBox(height: 10),
          Text(
            'no_license_added_yet'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme?.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
