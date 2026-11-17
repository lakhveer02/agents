import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'dart:async';

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final bool hasGlow;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.08,
    this.borderRadius,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          if (hasGlow)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 2,
            ),
        ],
      ),
      child: GlassContainer(
        blur: blur,
        opacity: opacity,
        shadowStrength: 0,
        shape: BoxShape.rectangle,
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
        child: child,
      ),
    );
  }
}

class AIGlowAvatar extends StatelessWidget {
  final double size;
  const AIGlowAvatar({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size + 20,
          height: size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: AppColors.aiGradient,
            ),
          ),
        ).animate(onPlay: (controller) => controller.repeat())
         .rotate(duration: 3.seconds),
        Container(
          width: size + 15,
          height: size + 15,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage('https://api.dicebear.com/7.x/bottts/png?seed=AI'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumFloatingDock extends StatelessWidget {
  final List<DockItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const PremiumFloatingDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
      child: PremiumGlassCard(
        blur: 30,
        opacity: 0.12,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = selectedIndex == index;
              return GestureDetector(
                onTap: () => onItemSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[index].icon,
                      color: isSelected ? Colors.white : Colors.white38,
                      size: 28,
                    ).animate(target: isSelected ? 1 : 0)
                     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                     .shimmer(color: Colors.white24),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ).animate().fade().scale(),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class DockItem {
  final IconData icon;
  final String label;
  const DockItem({required this.icon, required this.label});
}

// Streaming Text Widget with typewriter effect
class StreamingTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;

  const StreamingTextWidget({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 30),
  });

  @override
  State<StreamingTextWidget> createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<StreamingTextWidget> {
  String _displayedText = '';
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(StreamingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _currentIndex = _displayedText.length;
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}

// Shimmer Loading Card
class ShimmerLoadingCard extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoadingCard({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: 1500.ms,
      color: Colors.white.withOpacity(0.1),
    );
  }
}

// Chat Bubble with Avatar
class ChatBubbleWithAvatar extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? avatarUrl;

  const ChatBubbleWithAvatar({
    super.key,
    required this.message,
    required this.isUser,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? const Icon(Icons.auto_awesome, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUser
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.glassBorder,
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.person, size: 16, color: Colors.white),
          ),
        ],
      ],
    );
  }
}

// Premium Floating Action Button with glow
class PremiumFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;

  const PremiumFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.glow(color ?? AppColors.primary),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: color ?? AppColors.primary,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

// Animated Gradient Background
class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).blur(
            begin: const Offset(50, 50),
            end: const Offset(90, 90),
            duration: 8.seconds,
          ),
        ),
        Positioned(
          bottom: 100,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.1),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).blur(
            begin: const Offset(40, 40),
            end: const Offset(70, 70),
            duration: 10.seconds,
          ),
        ),
        child,
      ],
    );
  }
}
