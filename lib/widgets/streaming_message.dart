import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:agents/widgets/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StreamingMessageBubble extends StatefulWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;
  final List<String>? sources;

  const StreamingMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.isStreaming = false,
    this.sources,
  });

  @override
  State<StreamingMessageBubble> createState() => _StreamingMessageBubbleState();
}

class _StreamingMessageBubbleState extends State<StreamingMessageBubble> {
  bool _showCopyButton = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: MouseRegion(
        onEnter: (_) => setState(() => _showCopyButton = true),
        onExit: (_) => setState(() => _showCopyButton = false),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: widget.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              PremiumGlassCard(
                opacity: widget.isUser ? 0.1 : 0.05,
                blur: 10,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
                  bottomRight: Radius.circular(widget.isUser ? 4 : 20),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message content with streaming cursor
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MarkdownBody(
                                  data: widget.content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                    code: const TextStyle(
                                      backgroundColor: Colors.black26,
                                      fontFamily: 'monospace',
                                      color: AppColors.accent,
                                      fontSize: 14,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.isStreaming) ...[
                                const SizedBox(width: 4),
                                const StreamingCursor(),
                              ],
                            ],
                          ),
                          
                          // Source citations if available
                          if (widget.sources != null && widget.sources!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.sources!.map((source) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.link,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _truncateSource(source),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Copy button
                    if (_showCopyButton && !widget.isStreaming)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          color: Colors.white54,
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.content),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ).animate().fadeIn(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
  }

  String _truncateSource(String source) {
    final uri = Uri.tryParse(source);
    if (uri != null) {
      return uri.host.isNotEmpty ? uri.host : source;
    }
    return source.length > 30 ? '${source.substring(0, 30)}...' : source;
  }
}

// Code Block with Copy Button
class CodeBlockWithCopy extends StatelessWidget {
  final String code;
  final String language;

  const CodeBlockWithCopy({
    super.key,
    required this.code,
    this.language = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isEmpty ? 'code' : language,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Colors.white54,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: AppColors.accent,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
