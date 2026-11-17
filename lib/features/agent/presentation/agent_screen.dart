import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/features/agent/presentation/providers/agent_provider.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AgentScreen extends ConsumerWidget {
  const AgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentState = ref.watch(agentProvider);
    final commandController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Command Agent', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Timeline / Logs View
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: agentState.logs.length,
              itemBuilder: (context, index) {
                final log = agentState.logs[index];
                final isCommand = log.startsWith('> ');
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: isCommand 
                    ? _buildCommandChip(log.substring(2))
                    : _buildReasoningCard(log),
                );
              },
            ),
          ),
          
          if (agentState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Center(
                child: SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: AppColors.primary,
                    minHeight: 2,
                  ),
                ),
              ),
            ).animate().fade(),

          // Glass Terminal Input
          _buildTerminalInput(context, ref, commandController),
        ],
      ),
    );
  }

  Widget _buildCommandChip(String command) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.terminal_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                command,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildReasoningCard(String log) {
    return PremiumGlassCard(
      opacity: 0.03,
      blur: 10,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, size: 18, color: Colors.white54),
                const SizedBox(width: 8),
                Text(
                  'AI Reasoning',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MarkdownBody(
              data: log,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
                code: const TextStyle(
                  backgroundColor: Colors.black26,
                  fontFamily: 'monospace',
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTerminalInput(BuildContext context, WidgetRef ref, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: PremiumGlassCard(
        blur: 40,
        opacity: 0.08,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Enter command...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(agentProvider.notifier).executeCommand(controller.text);
                  controller.clear();
                }
              },
              icon: const Icon(Icons.bolt_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
