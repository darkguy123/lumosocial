import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/services/onesignal_service.dart';

class OneSignalVerificationSheet extends StatefulWidget {
  const OneSignalVerificationSheet({super.key});

  static void show() {
    if (Get.context != null) {
      showModalBottomSheet(
        context: Get.context!,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) => const OneSignalVerificationSheet(),
      );
    }
  }

  @override
  State<OneSignalVerificationSheet> createState() => _OneSignalVerificationSheetState();
}

class _OneSignalVerificationSheetState extends State<OneSignalVerificationSheet> with TickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];
  bool _isCelebrating = false;

  @override
  void initState() {
    super.initState();

    // 3D Icon Pop & Pulse Animation Controller
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.10).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: -4, end: 5).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeInOut),
    );

    // Confetti Animation Controller
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _generateConfetti();
  }

  void _generateConfetti() {
    final random = Random();
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFF40E378), // LUMO Green
      const Color(0xFFFF3B30), // Coral Red
      const Color(0xFF007AFF), // Azure Blue
      const Color(0xFFAF52DE), // Purple
      const Color(0xFFFF9500), // Orange
    ];

    for (int i = 0; i < 60; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 260 + 90;
      _particles.add(ConfettiParticle(
        x: 0,
        y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 140,
        color: colors[random.nextInt(colors.length)],
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * 2 * pi,
        vRot: (random.nextDouble() - 0.5) * 10,
      ));
    }
  }

  void _onGotItTapped() async {
    if (_isCelebrating) return;

    setState(() {
      _isCelebrating = true;
    });

    // Start Confetti Explosion
    _confettiController.forward(from: 0);

    // Trigger OneSignal Push Permission Prompt
    OneSignalService.requestPermission();

    // Wait for celebration confetti then slide down and close
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Slide up dark glassmorphic container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          decoration: const BoxDecoration(
            color: Color(0xFF151B28),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 30,
                spreadRadius: 10,
                offset: Offset(0, -10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Indicator handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // 3D Popping & Glowing Notification Icon
              AnimatedBuilder(
                animation: _popController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF40E378), Color(0xFF188241)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF40E378).withOpacity(0.45),
                              blurRadius: 26,
                              spreadRadius: 6,
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 46,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Verification Title
              const Text(
                "Your OneSignal SDK integration is complete!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Verification Description
              const Text(
                "You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 30),

              // Action Button ("Got it")
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onGotItTapped,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40E378),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF40E378).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Got it",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Confetti Explosion Layer
        if (_isCelebrating)
          Positioned(
            bottom: 120,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(300, 300),
                    painter: ConfettiPainter(
                      progress: _confettiController.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ConfettiParticle {
  double x, y;
  final double vx, vy;
  final Color color;
  final double size;
  double rotation;
  final double vRot;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.vRot,
  });
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gravity = 420.0 * progress;

    for (var particle in particles) {
      final t = progress;
      final px = center.dx + particle.vx * t;
      final py = center.dy + particle.vy * t + 0.5 * gravity * t * t;
      final rot = particle.rotation + particle.vRot * t;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
