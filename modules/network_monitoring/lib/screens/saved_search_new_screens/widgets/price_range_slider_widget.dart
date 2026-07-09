import 'package:flutter/material.dart';

class PriceRangeSliderWidget extends StatefulWidget {
  const PriceRangeSliderWidget({super.key});

  @override
  PriceRangeSliderWidgetState createState() => PriceRangeSliderWidgetState();
}

class PriceRangeSliderWidgetState extends State<PriceRangeSliderWidget> {
  RangeValues _currentRange = const RangeValues(1, 240);

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
          child: RangeSlider(
            values: _currentRange,
            min: 1,
            max: 240,
            divisions: 239, // Ensures step-by-step movement
            labels: RangeLabels(
              '${_currentRange.start.toInt()}',
              '${_currentRange.end.toInt()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _currentRange = values;
              });
            },
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 40,
              width: 116,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color.fromRGBO(166, 215, 227, 1).withAlpha((255 * 0.25).toInt()),
                    const Color.fromRGBO(87, 148, 221, 1).withAlpha((255 * 0.25).toInt()),
                  ]),
                  borderRadius: const BorderRadius.all(Radius.circular(6))),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    '120 m² ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(233, 233, 233, 1)),
                  ),
                ),
              ),
            ),
            Container(
              height: 40,
              width: 116,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color.fromRGBO(166, 215, 227, 1).withAlpha((255 * 0.25).toInt()),
                    const Color.fromRGBO(87, 148, 221, 1).withAlpha((255 * 0.25).toInt()),
                  ]),
                  borderRadius: const BorderRadius.all(Radius.circular(6))),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    '240 m² ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(233, 233, 233, 1)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
