import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated mascot widget with talking bubbles and interactions
class MascotWidget extends StatefulWidget {
  final String? message;
  final VoidCallback? onTap;
  final MascotState mascotState;
  final double size;
  final Widget? overlay;

  const MascotWidget({
    super.key,
    this.message,
    this.onTap,
    this.mascotState = MascotState.idle,
    this.size = 120,
    this.overlay,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _blinkController;
  late AnimationController _bounceController;
  late AnimationController _bubbleController;
  
  late Animation<double> _floatAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _bubbleScaleAnimation;
  late Animation<double> _bubbleOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Floating animation (continuous gentle bob)
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    // Blinking animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    
    // Bounce animation for interactions
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    // Speech bubble animation
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bubbleScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.elasticOut,
    ));
    _bubbleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOut,
    ));
    
    _startAnimations();
  }

  void _startAnimations() {
    // Start continuous floating
    _floatController.repeat(reverse: true);
    
    // Random blinking
    _scheduleRandomBlink();
    
    // Show speech bubble if message exists
    if (widget.message != null) {
      _bubbleController.forward();
    }
  }

  void _scheduleRandomBlink() {
    Future.delayed(Duration(seconds: 2 + math.Random().nextInt(4)), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          _blinkController.reverse();
          _scheduleRandomBlink();
        });
      }
    });
  }

  @override
  void didUpdateWidget(MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle message changes
    if (widget.message != oldWidget.message) {
      if (widget.message != null) {
        _bubbleController.forward();
      } else {
        _bubbleController.reverse();
      }
    }
    
    // Handle state changes
    if (widget.mascotState != oldWidget.mascotState) {
      _handleStateChange();
    }
  }

  void _handleStateChange() {
    switch (widget.mascotState) {
      case MascotState.excited:
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        break;
      case MascotState.celebrating:
        _bounceController.repeat(reverse: true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _bounceController.stop();
            _bounceController.reset();
          }
        });
        break;
      case MascotState.idle:
      default:
        break;
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _blinkController.dispose();
    _bounceController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        widget.onTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Mascot character (background)
          AnimatedBuilder(
            animation: Listenable.merge([_floatAnimation, _bounceAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, math.sin(_floatAnimation.value * 2 * math.pi) * 8),
                child: Transform.scale(
                  scale: _bounceAnimation.value,
                  child: _buildMascot(),
                ),
              );
            },
          ),
          // Speech bubble (middle)
          if (widget.message != null)
            Positioned(
              bottom: widget.size * 1.15, // Move bubble higher above mascot
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: Listenable.merge([_bubbleScaleAnimation, _bubbleOpacityAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bubbleScaleAnimation.value,
                    child: Opacity(
                      opacity: _bubbleOpacityAnimation.value,
                      child: _buildSpeechBubble(),
                    ),
                  );
                },
              ),
            ),
          // Overlay (always on top)
          if (widget.overlay != null)
            Positioned.fill(child: widget.overlay!),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.size * 1.2, // Reduced from 2x to 1.2x
        minWidth: widget.size * 0.8,
      ),
      child: Stack(
        children: [
          // Bubble body
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.message!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Bubble tail
          Positioned(
            bottom: -8,
            left: 30,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: BubbleTailPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: MascotPainter(
              blinkAmount: _blinkAnimation.value,
              mascotState: widget.mascotState,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the mascot character
class MascotPainter extends CustomPainter {
  final double blinkAmount;
  final MascotState mascotState;

  MascotPainter({
    required this.blinkAmount,
    required this.mascotState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Main body (turquoise)
    paint.color = const Color(0xFF4ECDC4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size.height * 0.1),
        width: size.width * 0.7,
        height: size.height * 0.8,
      ),
      paint,
    );
    
    // Head
    paint.color = const Color(0xFF4ECDC4);
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.15),
      size.width * 0.35,
      paint,
    );
    
    // Goggles frame
    paint.color = const Color(0xFF2C5F5D);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.02;
    
    // Left goggle
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.2),
      size.width * 0.12,
      paint,
    );
    
    // Right goggle
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.15, center.dy - size.height * 0.2),
      size.width * 0.12,
      paint,
    );
    
    // Goggle lenses
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF87CEEB);
    
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.2),
      size.width * 0.1,
      paint,
    );
    
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.15, center.dy - size.height * 0.2),
      size.width * 0.1,
      paint,
    );
    
    // Eyes
    paint.color = Colors.black;
    final eyeHeight = size.height * 0.08 * blinkAmount;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.2),
        width: size.width * 0.06,
        height: eyeHeight,
      ),
      paint,
    );
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + size.width * 0.15, center.dy - size.height * 0.2),
        width: size.width * 0.06,
        height: eyeHeight,
      ),
      paint,
    );
    
    // Mouth
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.015;
    paint.strokeCap = StrokeCap.round;
    
    final mouthPath = Path();
    final mouthY = center.dy - size.height * 0.05;
    mouthPath.moveTo(center.dx - size.width * 0.08, mouthY);
    mouthPath.quadraticBezierTo(
      center.dx, mouthY + size.height * 0.05,
      center.dx + size.width * 0.08, mouthY,
    );
    canvas.drawPath(mouthPath, paint);
    
    // Arms
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF4ECDC4);
    
    // Left arm
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - size.width * 0.4, center.dy + size.height * 0.1),
        width: size.width * 0.15,
        height: size.height * 0.3,
      ),
      paint,
    );
    
    // Right arm
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + size.width * 0.4, center.dy + size.height * 0.1),
        width: size.width * 0.15,
        height: size.height * 0.3,
      ),
      paint,
    );
    
    // Tablet/Book
    paint.color = const Color(0xFFFF8C42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: size.width * 0.3,
          height: size.height * 0.2,
        ),
        Radius.circular(size.width * 0.02),
      ),
      paint,
    );
    
    // Tablet screen
    paint.color = const Color(0xFF2C3E50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: size.width * 0.25,
          height: size.height * 0.15,
        ),
        Radius.circular(size.width * 0.01),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) {
    return oldDelegate.blinkAmount != blinkAmount ||
           oldDelegate.mascotState != mascotState;
  }
}

/// Custom painter for speech bubble tail
class BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Enum for different mascot states
enum MascotState {
  idle,
  excited,
  celebrating,
  thinking,
}
