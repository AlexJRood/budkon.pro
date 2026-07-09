import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/kernel/kernel.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/professional_credential_model.dart';

import 'widgets/professional_license_sheet.dart';

class _ProfileGatewayImpl implements ProfileGateway {
  @override
  Widget licenseCard(dynamic credential, dynamic theme) =>
      ProfessionalLicenseCard(
        credential: credential as ProfessionalCredentialModel,
        theme: theme as ThemeColors?,
      );

  @override
  Widget licenseButton(
    List<dynamic> credentials,
    dynamic theme, {
    bool compact = false,
  }) =>
      ProfessionalLicenseButton(
        credentials: credentials.cast<ProfessionalCredentialModel>(),
        theme: theme as ThemeColors?,
        compact: compact,
      );

  @override
  Future<void> showLicenseSheet(
    BuildContext context,
    List<dynamic> credentials,
    dynamic theme,
  ) =>
      showProfessionalLicenseSheet(
        context: context,
        credentials: credentials.cast<ProfessionalCredentialModel>(),
        theme: theme as ThemeColors?,
      );
}

/// Installs the profile implementation of [profileGatewayProvider]. Spread into
/// every entrypoint's overrides.
final List<Override> profileSeamOverrides = [
  profileGatewayProvider.overrideWith((ref) => _ProfileGatewayImpl()),
];
