/// Firmowy kot (faza 2) — współdzielony pet wędrujący po ekranach userów.
///
/// Mount app-wide: dodaj `const CompanyCatMount()` do Stacka w shellu.
/// Overlay renderuje się gdy kot jest u ciebie i ekran nie jest high-stakes
/// (`catSuppressedProvider`). Mount pełni też presence heartbeat.
library;

export 'provider/cat_gift_provider.dart';
export 'provider/cat_prefs_provider.dart';
export 'provider/cat_profile_provider.dart';
export 'provider/company_cat_provider.dart';
export 'widgets/cat_cosmetics_sheet.dart';
export 'widgets/cat_profile_sheet.dart';
export 'widgets/cat_send_pat_sheet.dart';
export 'widgets/cat_settings_sheet.dart';
export 'widgets/cat_visual.dart';
export 'widgets/company_cat_mount.dart';
export 'widgets/company_cat_overlay.dart';
