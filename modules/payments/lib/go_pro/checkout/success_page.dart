import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payments/emma/anchores/payments_emma_anchors.dart';
import 'package:core/platform/route_constant.dart';
import 'package:payments/go_pro/checkout/components/checkout_components.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

class PaymentSuccessPage extends ConsumerStatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  ConsumerState<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends ConsumerState<PaymentSuccessPage> {
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _playSuccessSound();
  }

  Future<void> _playSuccessSound() async {
    if (!_hasPlayed) {
      _hasPlayed = true;
      _confettiController.play();
      await _audioPlayer.play(AssetSource('audio/payment_success.mp3'));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final colorscheme = ref.watch(colorSchemeProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      childPc: Stack(
        children: [
          EmmaUiAnchorTarget(
            anchorKey: PaymentsEmmaAnchors.paymentSuccessPage.anchorKey,

            spec: PaymentsEmmaAnchors.paymentSuccessPage,
            runtimeMode: PaymentsEmmaAnchors.paymentSuccessPage.runtimeMode,
            tapMode: PaymentsEmmaAnchors.paymentSuccessPage.tapMode,
            child: Container(
              color: theme.popupcontainercolor,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                               width: 400,
                                height: 400,
                                child: Lottie.asset(
                                  width: 400,height: 400,
                                  'assets/lottie/success_payment.json',
                                  repeat: true,
                                  animate: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Payment Successful!".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: theme.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Congratulations! Welcome to HOUSLY Pro.".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: theme.textColor,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: 400,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: EmmaUiAnchorTarget(
                                        anchorKey: PaymentsEmmaAnchors.goToDashboardButton.anchorKey,

                                        spec: PaymentsEmmaAnchors.goToDashboardButton,
                                        runtimeMode: PaymentsEmmaAnchors.goToDashboardButton.runtimeMode,
                                        tapMode: PaymentsEmmaAnchors.goToDashboardButton.tapMode,
                                        child: Successpagebutton(
                                          buttonheight: 40,
                                          onTap: () {
                                            ref
                                                .read(navigationService)
                                                .pushNamedScreen(Routes.entry);
                                          },
                                          text: 'Go to Dashboard'.tr,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Confetti widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              minBlastForce: 5,
              maxBlastForce: 20,
              colors: [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
      childMobile: Stack(
        children: [
          Container(
            color: theme.popupcontainercolor,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                             SizedBox(
                             width: 300,
                              height: 300,
                              child: Lottie.asset(
                                width: 300,height: 300,
                                'assets/lottie/success_payment.json',
                                repeat: true,
                                animate: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Payment Successful!".tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: theme.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Congratulations! Welcome to HOUSLY Pro.".tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: theme.textColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 400,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Successpagebutton(
                                      buttonheight: 40,
                                      onTap: () {
                                        ref
                                            .read(navigationService)
                                            .pushNamedScreen(Routes.entry);
                                      },
                                      text: 'Go to Dashboard'.tr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Confetti widget for mobile
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              minBlastForce: 5,
              maxBlastForce: 20,
              colors: [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }
}