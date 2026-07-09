import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalConfettiService extends ChangeNotifier {
  final ConfettiController _controller;
  ConfettiConfig _config = const ConfettiConfig();

  GlobalConfettiService()
    : _controller = ConfettiController(duration: const Duration(seconds: 3));

  ConfettiController get controller => _controller;

  ConfettiConfig get config => _config;

  void show({ConfettiConfig? config}) {
    if (config != null) {
      _config = config;
    }

    // Stop if already playing and restart
    _controller.stop();
    _controller.play();

    notifyListeners();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

final confettiServiceProvider = ChangeNotifierProvider<GlobalConfettiService>((
  ref,
) {
  return GlobalConfettiService();
});

class ConfettiConfig {
  final Duration duration;
  final List<Color> colors;
  final double gravity;
  final int particles;

  const ConfettiConfig({
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      Colors.green,
      Colors.blue,
      Colors.pink,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
    ],
    this.gravity = 0.1,
    this.particles = 30,
  });
}
