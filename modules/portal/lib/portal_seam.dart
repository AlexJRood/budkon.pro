import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:articles/components/article_card.dart'
    show articlePieActionsProvider;

import 'pie_menu/feed.dart';

/// Installs portal's article pie-menu actions into the shared article card's
/// seam, so `shared_utils` renders them without importing portal. Spread into
/// every entrypoint's overrides.
final List<Override> portalSeamOverrides = [
  articlePieActionsProvider.overrideWith((ref) => buildPieMenuActions),
];
