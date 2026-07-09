import 'package:flutter/material.dart';

class Buttontile extends StatelessWidget {
  final void Function()? onPressed;
  final Color buttoncolor;
  final String buttontext;
  const Buttontile(
      {super.key,
      required this.onPressed,
      required this.buttoncolor,
      required this.buttontext});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(buttoncolor),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  10) // Makes the corners sharp (rectangle)
              ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        buttontext,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
