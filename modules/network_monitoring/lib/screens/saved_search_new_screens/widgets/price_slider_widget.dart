import 'package:flutter/material.dart';

class PriceSliderWidget extends StatefulWidget {
  const PriceSliderWidget({super.key});

  @override
  PriceSliderWidgetState createState() => PriceSliderWidgetState();
}

class PriceSliderWidgetState extends State<PriceSliderWidget> {
  double _currentValue = 150000;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            thumbColor: Colors.blue,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey[600],
            valueIndicatorColor: const Color.fromRGBO(90, 90, 90, 1),
            showValueIndicator: ShowValueIndicator.always,
            trackHeight: 4,
          ),
          child: Stack(
            children: [
              Slider(
                value: _currentValue,
                min: 0,
                max: 500000,
                onChanged: (value) {
                  setState(() {
                    _currentValue = value;
                  });
                },
                label: '\$${(_currentValue ~/ 1000)}k',
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$0',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              '\$500k+',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
