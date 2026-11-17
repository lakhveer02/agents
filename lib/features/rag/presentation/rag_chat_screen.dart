import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/features/rag/presentation/providers/rag_provider.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:agents/widgets/streaming_message.dart';
import 'package:agents/widgets/animations.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/core/api/websocket_client.dart' as ws;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

class RagChatScreen extends ConsumerWidget {
  const RagChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ragState = ref.watch(ragProvider);
    final textController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RAG Engine', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Connection state indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ragState.connectionState == ws.ConnectionState.connected
                      ? AppColors.accent
                      : ragState.connectionState == ws.ConnectionState.reconnecting
                          ? Colors.orange
                          : Colors.red,
                  boxShadow: ragState.connectionState == ws.ConnectionState.connected
                      ? AppShadows.glow(AppColors.accent)
                      : null,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result != null) {
                ref.read(ragProvider.notifier).uploadPdf(File(result.files.single.path!));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_link_rounded, color: AppColors.accent),
            onPressed: () => _showUrlDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ragState.messages.isEmpty && !ragState.isStreaming
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    itemCount: ragState.messages.length + (ragState.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show existing messages
                      if (index < ragState.messages.length) {
                        final msg = ragState.messages[index];
                        final isUser = msg['role'] == 'user';
                        
                        if (isUser) {
                          return ChatBubbleWithAvatar(
                            message: msg['content'] as String,
                            isUser: true,
                          );
                        } else {
                          return StreamingMessageBubble(
                            content: msg['content'] as String,
                            isUser: false,
                            isStreaming: false,
                            sources: msg['sources'] != null
                                ? List<String>.from(msg['sources'])
                                : null,
                          );
                        }
                      }
                      
                      // Show streaming message
                      if (ragState.isStreaming) {
                        if (ragState.currentStreamingMessage.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: TypingIndicator(),
                          );
                        } else {
                          return StreamingMessageBubble(
                            content: ragState.currentStreamingMessage,
                            isUser: false,
                            isStreaming: true,
                            sources: ragState.currentSources,
                          );
                        }
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
          ),
          
          // Loading indicator
          if (ragState.isLoading && !ragState.isStreaming)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ).animate().fade(),
          
          // Stop button during streaming
          if (ragState.isStreaming)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: () => ref.read(ragProvider.notifier).stopStreaming(),
                icon: const Icon(Icons.stop_circle, color: Colors.red),
                label: const Text('Stop Generating', style: TextStyle(color: Colors.red)),
              ),
            ).animate().fadeIn(),
          
          // Input bar
          _buildInputBar(context, ref, textController, ragState.isStreaming),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.aiGradient,
              ),
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.white,
            ),
          ).animate().scale().fadeIn(),
          const SizedBox(height: 24),
          Text(
            'Start a Conversation',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'Upload PDFs or ingest URLs to chat with your documents',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withOpacity(0.5),
            ),
          ).animate(delay: 400.ms).fadeIn(),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Upload a PDF', Icons.picture_as_pdf_rounded),
              _buildSuggestionChip('Add a URL', Icons.link_rounded),
              _buildSuggestionChip('Ask a question', Icons.question_answer_rounded),
            ],
          ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        child: PremiumGlassCard(
          opacity: isUser ? 0.15 : 0.05,
          blur: 10,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildInputBar(BuildContext context, WidgetRef ref, TextEditingController controller, bool isStreaming) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: PremiumGlassCard(
        blur: 30,
        opacity: 0.1,
        borderRadius: BorderRadius.circular(32),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isStreaming,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: isStreaming ? 'Generating...' : 'Ask your documents...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            IconButton(
              onPressed: isStreaming ? null : () {
                if (controller.text.isNotEmpty) {
                  ref.read(ragProvider.notifier).query(controller.text);
                  controller.clear();
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isStreaming ? Colors.grey : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ingest URL', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(ragProvider.notifier).ingestUrl(urlController.text);
              Navigator.pop(context);
            },
            child: const Text('Ingest'),
          ),
        ],
      ),
    );
  }
}
