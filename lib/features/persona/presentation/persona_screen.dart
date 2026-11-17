import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/features/persona/presentation/providers/persona_provider.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PersonaScreen extends ConsumerWidget {
  const PersonaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personaState = ref.watch(personaProvider);
    final textController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Persona AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Persona Selection Horizontal Scroll
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPersonaAvatar(ref, 'mentor', 'Mentor', 'https://api.dicebear.com/7.x/bottts/png?seed=mentor'),
                _buildPersonaAvatar(ref, 'jethalal', 'Jetha', 'https://api.dicebear.com/7.x/bottts/png?seed=jetha'),
                _buildPersonaAvatar(ref, 'kapil_sharma', 'Kapil', 'https://api.dicebear.com/7.x/bottts/png?seed=kapil'),
                _buildPersonaAvatar(ref, 'coach', 'Coach', 'https://api.dicebear.com/7.x/bottts/png?seed=coach'),
                _buildPersonaAvatar(ref, 'teacher', 'Teacher', 'https://api.dicebear.com/7.x/bottts/png?seed=teacher'),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: personaState.messages.length,
                itemBuilder: (context, index) {
                  final msg = personaState.messages[index];
                  final isUser = msg['role'] == 'user';
                  return _buildMessageBubble(msg['content']!, isUser);
                },
              ),
            ),
          ),
          
          if (personaState.isLoading) const LinearProgressIndicator(minHeight: 1),
          
          _buildInputArea(context, ref, textController),
        ],
      ),
    );
  }

  Widget _buildPersonaAvatar(WidgetRef ref, String id, String name, String url) {
    final current = ref.watch(personaProvider).selectedPersona;
    final isSelected = current == id;

    return GestureDetector(
      onTap: () => ref.read(personaProvider.notifier).selectPersona(id),
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? const LinearGradient(colors: AppColors.aiGradient) : null,
                border: !isSelected ? Border.all(color: Colors.white10) : null,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.card,
                backgroundImage: NetworkImage(url),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0)
     .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1));
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        child: PremiumGlassCard(
          opacity: isUser ? 0.1 : 0.03,
          blur: 10,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.4),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: isUser ? 0.1 : -0.1);
  }

  Widget _buildInputArea(BuildContext context, WidgetRef ref, TextEditingController controller) {
    return Container(
      color: AppColors.surface.withOpacity(0.5),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: PremiumGlassCard(
        opacity: 0.05,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Say something...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(personaProvider.notifier).sendMessage(controller.text);
                  controller.clear();
                }
              },
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
