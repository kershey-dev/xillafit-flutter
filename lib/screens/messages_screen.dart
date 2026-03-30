import 'package:flutter/material.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';

/// Placeholder for Messages / Chat — UI only, no backend.
class MessagesScreen extends StatelessWidget {
  static const routeName = '/messages';

  const MessagesScreen({super.key, this.embeddedInShell = false});

  /// When true, content is shown inside [MainShell] without extra scaffold chrome.
  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'MESSAGES',
          style: AppTextStyles.title.copyWith(fontSize: 24, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Text(
          'Chat with XILLAFIT about your order or design.',
          style: AppTextStyles.caption.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.goldDark),
              const SizedBox(height: 12),
              Text(
                'No conversations yet',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Start a thread from an order or tap support when ordering goes live.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );

    if (embeddedInShell) return body;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: body,
    );
  }
}
