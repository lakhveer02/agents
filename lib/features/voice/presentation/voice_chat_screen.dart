import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/features/voice/presentation/providers/voice_provider.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class VoiceChatScreen extends ConsumerStatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Voice AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Stack(
        children: [
          // Dynamic Reactive Background
          AnimatedContainer(
            duration: 1.seconds,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: voiceState.isListening 
                  ? [AppColors.primary.withOpacity(0.2), AppColors.background]
                  : [AppColors.secondary.withOpacity(0.1), AppColors.background],
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAIObr(voiceState.isListening, voiceState.isProcessing),
                const SizedBox(height: 60),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    voiceState.isListening ? 'I’m listening...' : 'Hold to speak',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ).animate(target: voiceState.isListening ? 1 : 0)
                   .shimmer(color: Colors.white24),
                ),
                
                const SizedBox(height: 40),
                
                if (voiceState.userText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: PremiumGlassCard(
                      opacity: 0.05,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          voiceState.userText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                        ),
                      ),
                    ),
                  ).animate().fadeIn().scale(),
                  
                const SizedBox(height: 20),
                
                if (voiceState.aiText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      voiceState.aiText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
              ],
            ),
          ),
          
          // Bottom Controller
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onLongPressStart: (_) => ref.read(voiceProvider.notifier).startListening(),
                onLongPressEnd: (_) => ref.read(voiceProvider.notifier).stopListening(),
                child: _buildMicButton(voiceState.isListening),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIObr(bool isListening, bool isProcessing) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double pulse = isListening ? _pulseController.value : 0.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glows
            for (int i = 1; i <= 3; i++)
              Container(
                width: 180 + (i * 30) + (pulse * 40),
                height: 180 + (i * 30) + (pulse * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1 / i),
                    width: 2,
                  ),
                ),
              ),
            
            // Core Orb
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: AppColors.aiGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(_pulseController.value * 2 * math.pi),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 40 + (pulse * 20),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: isProcessing 
                ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 60),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMicButton(bool isListening) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isListening ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isListening ? Colors.red : Colors.white24,
          width: 2,
        ),
      ),
      child: Icon(
        isListening ? Icons.stop_rounded : Icons.mic_rounded,
        color: isListening ? Colors.red : Colors.white,
        size: 32,
      ),
    ).animate(target: isListening ? 1 : 0)
     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2));
  }
}
