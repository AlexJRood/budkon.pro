import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart'; // Assuming this contains themeColorsProvider
import 'dart:math' as math;

class PropertyTile extends ConsumerWidget {
  // Changed to ConsumerWidget to access the provider
  final String imageUrl;
  final String address;
  final String price;
  final bool isSelected;

  const PropertyTile({
    super.key,
    required this.imageUrl,
    required this.address,
    required this.price,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider); // Access the theme provider
    final screenWidth = MediaQuery.of(context).size.width;

    final double dialogHeight =
        screenWidth <= 1920
            ? 600
            : math.min(1200, 700 + (screenWidth - 1920) * 0.1);
    return Container(
      height: screenWidth <= 1920 ? 70 : 70 + dialogHeight * 0.01,
      decoration: BoxDecoration(
        color: theme.settingstile,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.cyan, width: 1.5) : null,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Image.network(
                  imageUrl,
                  width:  screenWidth <= 1920 ? 70 : 70 + dialogHeight * 0.01,
                  height:  screenWidth <= 1920 ? 70 : 70 + dialogHeight * 0.01,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Icon(
                        Icons.error,
                        color:
                            theme
                                .themeTextColor, // Use theme text color for error icon
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address,
                        style: TextStyle(
                          color: Colors.white, // Use theme text color
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          color: Colors.white, // Use theme text color
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isSelected)
            Positioned(
              top: -2,
              right: 0,

              child: TriangleCornerBadge(
                sideLength: 50,
                backgroundColor: Colors.cyan,
                icon: Icons.check,
                rotate: 270,
              ),
            ),
        ],
      ),
    );
  }
}

class TriangleCornerBadge extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final double sideLength;
  final Color backgroundColor;
  final double borderRadius;
  final double rotate; // NEW: rotation in degrees

  const TriangleCornerBadge({
    Key? key,
    required this.icon,
    this.iconSize = 20,
    this.iconColor = Colors.black,
    this.sideLength = 66,
    this.backgroundColor = Colors.cyan,
    this.borderRadius = 0,
    this.rotate = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sideLength,
      height: sideLength,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotate * math.pi / 180, // Convert degrees to radians(
            child: ClipPath(
              clipper: _RightAngleTriangleClipper(borderRadius: borderRadius),
              child: Container(color: backgroundColor),
            ),
          ),
          Positioned(
            left: 30,
            top: 10,
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _RightAngleTriangleClipper extends CustomClipper<Path> {
  final double borderRadius;

  _RightAngleTriangleClipper({required this.borderRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = borderRadius.clamp(0.0, size.shortestSide / 2);

    path.moveTo(0, size.height - radius);

    if (radius > 0) {
      path.quadraticBezierTo(0, size.height, radius, size.height);
    }

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_RightAngleTriangleClipper oldClipper) =>
      oldClipper.borderRadius != borderRadius;
}
