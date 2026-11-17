import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated Glow Background
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 10.seconds)
             .blur(begin: const Offset(60, 60), end: const Offset(90, 90)),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AIGlowAvatar(size: 80).animate().scale().fadeIn(duration: 600.ms),
                    const SizedBox(height: 32),
                    const Text(
                      'Intellisphere',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    Text(
                      'Enter the next dimension of AI',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 48),
                    
                    PremiumGlassCard(
                      opacity: 0.05,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: emailController,
                              hint: 'Email Address',
                              icon: Icons.alternate_email_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: passwordController,
                              hint: 'Security Code',
                              icon: Icons.lock_outline_rounded,
                              isObscure: true,
                            ),
                            const SizedBox(height: 32),
                            if (authState.isLoading)
                              const CircularProgressIndicator(color: AppColors.primary)
                            else
                              GestureDetector(
                                onTap: () => ref.read(authProvider.notifier).login(
                                  emailController.text,
                                  passwordController.text,
                                ),
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: AppColors.aiGradient),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Access Intellisphere',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 600.ms).scale(),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                    
                    if (authState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          authState.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ).animate().shake(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
