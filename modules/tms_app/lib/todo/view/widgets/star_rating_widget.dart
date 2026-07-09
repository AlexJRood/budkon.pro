import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating; // Current rating (out of 5)
  final int maxRating; // Maximum rating (default 5)
  final Color filledColor;
  final Color unfilledColor;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.filledColor = Colors.amber,
    this.unfilledColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border, // Filled or outlined star
          color: index < rating ? filledColor : unfilledColor,
        );
      }),
    );
  }
}