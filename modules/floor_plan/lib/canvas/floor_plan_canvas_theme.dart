part of 'floor_plan_canvas.dart';

class FloorPlanCanvasTheme {
  final Color background;
  final Color gridMinor;
  final Color gridMajor;

  final Color wall;
  final Color selectedWall;
  final Color virtualWall;

  final Color roomFill;
  final Color roomBorder;
  final Color selectedRoomFill;
  final Color selectedRoomBorder;

  final Color door;
  final Color window;
  final Color garageDoor;

  final Color assetFill;
  final Color assetBorder;
  final Color selectedAssetFill;
  final Color selectedAssetBorder;

  final Color guide;
  final Color accent;
  final Color warning;

  final Color labelBackground;
  final Color labelBorder;
  final Color labelText;
  final Color mutedText;

  final Color handleFill;
  final Color handleBorder;

  const FloorPlanCanvasTheme({
    required this.background,
    required this.gridMinor,
    required this.gridMajor,
    required this.wall,
    required this.selectedWall,
    required this.virtualWall,
    required this.roomFill,
    required this.roomBorder,
    required this.selectedRoomFill,
    required this.selectedRoomBorder,
    required this.door,
    required this.window,
    required this.garageDoor,
    required this.assetFill,
    required this.assetBorder,
    required this.selectedAssetFill,
    required this.selectedAssetBorder,
    required this.guide,
    required this.accent,
    required this.warning,
    required this.labelBackground,
    required this.labelBorder,
    required this.labelText,
    required this.mutedText,
    required this.handleFill,
    required this.handleBorder,
  });

  factory FloorPlanCanvasTheme.fromAppTheme(dynamic appTheme) {
    final themeColor = _tryReadColor(
      appTheme,
      'themeColor',
      const Color(0xFF2563EB),
    );

    final textColor = _tryReadColor(
      appTheme,
      'textColor',
      const Color(0xFF111827),
    );

    final container = _tryReadColor(
      appTheme,
      'dashboardContainer',
      const Color(0xFFF6F7F9),
    );

    final border = _tryReadColor(
      appTheme,
      'dashboardBoarder',
      const Color(0xFFE0E3E7),
    );

    final isDark = _estimateIsDark(container);

    final background = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7F9);

    return FloorPlanCanvasTheme(
      background: background,
      gridMinor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE3E6EA),
      gridMajor: isDark ? const Color(0xFF334155) : const Color(0xFFD2D7DE),

      wall: isDark ? const Color(0xFFE5E7EB) : textColor,
      selectedWall: themeColor,
      virtualWall: themeColor.withOpacity(0.75),

      roomFill: themeColor.withOpacity(isDark ? 0.16 : 0.08),
      roomBorder: themeColor.withOpacity(isDark ? 0.42 : 0.28),
      selectedRoomFill: themeColor.withOpacity(isDark ? 0.24 : 0.14),
      selectedRoomBorder: themeColor.withOpacity(0.70),

      door: themeColor,
      window: const Color(0xFF0891B2),
      garageDoor: const Color(0xFFD97706),

      assetFill: const Color(0xFF10B981).withOpacity(isDark ? 0.18 : 0.10),
      assetBorder: const Color(0xFF059669),
      selectedAssetFill: themeColor.withOpacity(isDark ? 0.22 : 0.15),
      selectedAssetBorder: themeColor,

      guide: const Color(0xFF7C3AED),
      accent: themeColor,
      warning: const Color(0xFFF59E0B),

      labelBackground: isDark
          ? const Color(0xFF111827).withOpacity(0.94)
          : Colors.white.withOpacity(0.94),
      labelBorder: border.withOpacity(0.75),
      labelText: textColor,
      mutedText: textColor.withOpacity(0.62),

      handleFill: isDark ? const Color(0xFF0F172A) : Colors.white,
      handleBorder: textColor,
    );
  }

  static bool _estimateIsDark(Color color) {
    return color.computeLuminance() < 0.35;
  }

  static Color _tryReadColor(
    dynamic source,
    String fieldName,
    Color fallback,
  ) {
    try {
      final dynamic value = switch (fieldName) {
        'themeColor' => source.themeColor,
        'textColor' => source.textColor,
        'dashboardContainer' => source.dashboardContainer,
        'dashboardBoarder' => source.dashboardBoarder,
        _ => null,
      };

      if (value is Color) return value;
    } catch (e) {
      assert(() {
        debugPrint('FloorPlanCanvasTheme: failed to read $fieldName: $e');
        return true;
      }());
    }

    return fallback;
  }
}