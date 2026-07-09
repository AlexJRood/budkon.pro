import 'package:flutter/material.dart';

class Headingtile extends StatelessWidget {
  final double width;
  final String text;
  const Headingtile({
    super.key,
    required this.width,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // Fixed width for heading1
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
