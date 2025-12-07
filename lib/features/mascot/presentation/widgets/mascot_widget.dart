import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../shared/services/animation_service.dart';

/// Animated mascot widget with talking bubbles and interactions
class MascotWidget extends StatefulWidget {
  final String? message;
  final double size;
  final MascotState mascotState;
  final VoidCallback? onTap;
  final AnimationService animationService;

  const MascotWidget({
    super.key,
    this.size = 80,
    this.message,
    this.mascotState = MascotState.idle,
    this.onTap,
    this.animationService = const ProductionAnimationService(),
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
    
    // Floating animation (subtle gentle bob)
    _floatController = AnimationController(
      duration: const Duration(seconds: 4), // Slower floating
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
    if (!widget.animationService.animationsEnabled) {
      return;
    }
    
    // Start continuous floating
    widget.animationService.startRepeating(_floatController, reverse: true);

    // Random blinking
    _scheduleRandomBlink();

    // Show speech bubble if message exists
    if (widget.message != null) {
      widget.animationService.forward(_bubbleController);
      widget.animationService.scheduleDelayed(const Duration(seconds: 8), () {
        if (mounted) {
          widget.animationService.reverse(_bubbleController);
        }
      });
    }
  }

  void _scheduleRandomBlink() {
    if (!widget.animationService.animationsEnabled) {
      return;
    }
    
    widget.animationService.scheduleDelayed(Duration(seconds: 2 + math.Random().nextInt(4)), () {
      if (mounted) {
        widget.animationService.forward(_blinkController).then((_) {
          widget.animationService.reverse(_blinkController);
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
        widget.animationService.forward(_bubbleController);
      } else {
        widget.animationService.reverse(_bubbleController);
      }
    }
    
    // Handle state changes
    if (widget.mascotState != oldWidget.mascotState) {
      _handleStateChange();
    }
  }

  void _handleStateChange() {
    switch (widget.mascotState) {
      case MascotState.celebrating:
        if (!widget.animationService.animationsEnabled) {
          return;
        }
        
        widget.animationService.startRepeating(_bounceController, reverse: true);
        widget.animationService.scheduleDelayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.animationService.stopAndReset(_bounceController);
          }
        });
        break;
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
        widget.animationService.forward(_bounceController).then((_) {
          widget.animationService.reverse(_bounceController);
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
              final mascot = Transform.scale(
                scale: _bounceAnimation.value,
                child: _buildMascot(),
              );

              return Transform.translate(
                offset: Offset(0, math.sin(_floatAnimation.value * 2 * math.pi) * 3),
                child: mascot,
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
        ],
      ),
    );
  }

  Widget _buildSpeechBubble() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.size * 1.4, // Slightly wider for better readability
        minWidth: widget.size * 0.8,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bubble body
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Bubble tail (centered and pointing down to mascot)
          Positioned(
            bottom: -12,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 12,
                child: CustomPaint(
                  painter: _BubbleTailPainter(),
                ),
              ),
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
          return Image.asset(
            'lingualabs_mascot_manual_crop-removebg-preview.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}

/// Simple bubble tail painter
class _BubbleTailPainter extends CustomPainter {
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
