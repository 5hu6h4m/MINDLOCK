import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChargingAnimationOverlay extends StatefulWidget {
  final int level;
  final String speedType;
  final VoidCallback onDismiss;

  const ChargingAnimationOverlay({
    super.key,
    required this.level,
    required this.speedType,
    required this.onDismiss,
  });

  @override
  State<ChargingAnimationOverlay> createState() => _ChargingAnimationOverlayState();
}

class _ChargingAnimationOverlayState extends State<ChargingAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _mainController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0, 0.4, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)),
    );

    _mainController.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _mainController.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Liquid Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: LiquidPainter(
                      progress: widget.level / 100,
                      waveValue: _waveController.value,
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                    ),
                  );
                },
              ),
            ),
            
            // Neon Glow Background
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentCyan.withOpacity(0.1),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppTheme.accentCyan,
                        size: 100,
                        shadows: [
                          Shadow(color: AppTheme.accentCyan, blurRadius: 30),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${widget.level}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 84,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.speedType.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        'OPTIMIZING ENERGY FLOW...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dismiss
            Positioned(
              bottom: 40,
              child: GestureDetector(
                onTap: () => _mainController.reverse().then((_) => widget.onDismiss()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CLOSE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiquidPainter extends CustomPainter {
  final double progress;
  final double waveValue;
  final Color color;

  LiquidPainter({
    required this.progress,
    required this.waveValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    final yOffset = size.height * (1 - progress);
    
    path.moveTo(0, yOffset);
    
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        yOffset + math.sin((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) * 15,
      );
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LiquidPainter oldDelegate) => true;
}
