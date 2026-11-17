import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/features/auth/presentation/login_screen.dart';
import 'package:agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:agents/features/rag/presentation/rag_chat_screen.dart';
import 'package:agents/features/voice/presentation/voice_chat_screen.dart';
import 'package:agents/features/agent/presentation/agent_screen.dart';
import 'package:agents/features/persona/presentation/persona_screen.dart';
import 'package:agents/features/ecommerce/presentation/ecommerce_screen.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'AI Super App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Default to dark for premium feel
      home: authState.isAuthenticated ? const MainNavigationWrapper() : const LoginScreen(),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const RagChatScreen(),
    const VoiceChatScreen(),
    const AgentScreen(),
    const PersonaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: PremiumFloatingDock(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        items: const [
          DockItem(icon: Icons.grid_view_rounded, label: 'Home'),
          DockItem(icon: Icons.chat_bubble_rounded, label: 'RAG'),
          DockItem(icon: Icons.mic_rounded, label: 'Voice'),
          DockItem(icon: Icons.terminal_rounded, label: 'Agent'),
          DockItem(icon: Icons.face_rounded, label: 'Persona'),
        ],
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium Background
          Container(
            color: AppColors.background,
            child: Stack(
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
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .blur(begin: const Offset(50, 50), end: const Offset(80, 80), duration: 5.seconds),
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
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .blur(begin: const Offset(40, 40), end: const Offset(70, 70), duration: 7.seconds),
                ),
              ],
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'G’day, User',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideX(),
                            const Text(
                              'Intellisphere AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideX(),
                          ],
                        ),
                        const AIGlowAvatar().animate().scale().fadeIn(),
                      ],
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: PremiumGlassCard(
                      hasGlow: true,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'AI Insights',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your documents were processed successfully. You have 3 new product recommendations based on your recent activity.',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildActionCard(context, 'Shopping', Icons.shopping_cart_rounded, AppColors.accent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EcommerceScreen()));
                      }),
                      _buildActionCard(context, 'History', Icons.history_rounded, Colors.orange, () {}),
                      _buildActionCard(context, 'Training', Icons.model_training_rounded, Colors.purple, () {}),
                      _buildActionCard(context, 'Settings', Icons.tune_rounded, Colors.grey, () {}),
                    ],
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return PremiumGlassCard(
      opacity: 0.05,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().scale(delay: 800.ms);
  }
}
