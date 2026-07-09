import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wall/wall_screen/services/confetti/confetti_service.dart';
import 'package:get/get_utils/get_utils.dart';

class GlobalConfettiOverlay extends ConsumerWidget {
  const GlobalConfettiOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the service to trigger rebuilds when notifyListeners() is called
    final service = ref.watch(confettiServiceProvider);

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: service.controller,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: service.config.particles,
          gravity: service.config.gravity,
          minBlastForce: 5,
          maxBlastForce: 20,
          colors: service.config.colors,
        ),
      ),
    );
  }
}

class ConfettiTestScreen extends ConsumerWidget {
  const ConfettiTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text("Confetti Test".tr)),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ref
                .read(confettiServiceProvider)
                .show(
                  config: const ConfettiConfig(
                    duration: Duration(seconds: 6),
                    particles: 100,
                    gravity: 0.15,
                  ),
                );
          },
          child: Text("${'BIG CELEBRATION'.tr}🚀"),
        ),
      ),
    );
  }
}
