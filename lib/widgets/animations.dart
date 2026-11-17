import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'dart:math' as math;

// Voice Waveform Widget
class VoiceWaveformWidget extends StatefulWidget {
  final bool isActive;
  final Color color;
  final int barCount;

  const VoiceWaveformWidget({
    super.key,
    required this.isActive,
    this.color = AppColors.primary,
    this.barCount = 5,
  });

  @override
  State<VoiceWaveformWidget> createState() => _VoiceWaveformWidgetState();
}

class _VoiceWaveformWidgetState extends State<VoiceWaveformWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (index * 100)),
      ),
    );

    if (widget.isActive) {
      for (var controller in _controllers) {
        controller.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(VoiceWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        for (var controller in _controllers) {
          controller.repeat(reverse: true);
        }
      } else {
        for (var controller in _controllers) {
          controller.stop();
          controller.value = 0;
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.barCount,
        (index) => AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: widget.isActive
                  ? 20 + (_controllers[index].value * 30)
                  : 10,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Pulse Orb Widget - AI thinking indicator
class PulseOrbWidget extends StatelessWidget {
  final double size;
  final Color color;
  final bool isActive;

  const PulseOrbWidget({
    super.key,
    this.size = 60,
    this.color = AppColors.primary,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse rings
        for (int i = 0; i < 3; i++)
          Container(
            width: size + (i * 20.0),
            height: size + (i * 20.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2 / (i + 1)),
                width: 2,
              ),
            ),
          ).animate(
            onPlay: isActive ? (c) => c.repeat() : null,
          ).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.2, 1.2),
            duration: Duration(milliseconds: 1500 + (i * 300)),
          ).fade(
            begin: 0.8,
            end: 0.0,
          ),
        
        // Core orb
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withOpacity(0.6),
              ],
            ),
            boxShadow: AppShadows.glow(color),
          ),
        ).animate(
          onPlay: isActive ? (c) => c.repeat(reverse: true) : null,
        ).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 1.seconds,
        ),
      ],
    );
  }
}

// Floating Particles - Background ambient animation
class FloatingParticles extends StatelessWidget {
  final int particleCount;
  final Color color;

  const FloatingParticles({
    super.key,
    this.particleCount = 20,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(
        particleCount,
        (index) {
          final left = random.nextDouble() * size.width;
          final top = random.nextDouble() * size.height;
          final particleSize = 2.0 + random.nextDouble() * 4;
          final duration = 3 + random.nextInt(5);

          return Positioned(
            left: left,
            top: top,
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ).animate(
              onPlay: (c) => c.repeat(reverse: true),
            ).moveY(
              begin: 0,
              end: -50 - random.nextDouble() * 50,
              duration: Duration(seconds: duration),
            ).fade(
              begin: 0.3,
              end: 0.0,
            ),
          );
        },
      ),
    );
  }
}

// Streaming Cursor - Blinking cursor for typing effect
class StreamingCursor extends StatelessWidget {
  final Color color;

  const StreamingCursor({
    super.key,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 16,
      color: color,
    ).animate(
      onPlay: (c) => c.repeat(),
    ).fade(
      begin: 1.0,
      end: 0.0,
      duration: 600.ms,
    );
  }
}

// Page Transition Builder
class PageTransitions {
  static PageRouteBuilder slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppDurations.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder fadeIn(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppDurations.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder scaleUp(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppDurations.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.8;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

// Typing Indicator Widget
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ).animate(
          onPlay: (c) => c.repeat(),
        ).fade(
          begin: 0.3,
          end: 1.0,
          duration: 600.ms,
          delay: Duration(milliseconds: index * 200),
        ),
      ),
    );
  }
}
