import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/features/messages/data/messages_repository.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  static const routeName = '/messages';

  const MessagesScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<SupportMessage> _messages = const [];
  List<SupportProfile> _supportProfiles = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _load();
      _subscribe();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    final channel = _channel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(messagesRepositoryProvider);
      final profiles = await repo.fetchActiveSupportProfiles();
      final messages = await repo.fetchMessages();
      if (!mounted) return;

      setState(() {
        _supportProfiles = profiles;
        _messages = messages;
        _loading = false;
      });

      await _markReadForCurrentThread();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyMessagesError(error);
      });
    }
  }

  void _subscribe() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final channel = Supabase.instance.client
        .channel('client-messages-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_profile_id',
            value: userId,
          ),
          callback: (payload) async {
            await _load();
          },
        )
        .subscribe();

    _channel = channel;
  }

  SupportProfile? get _defaultRecipient {
    if (_supportProfiles.isEmpty) return null;
    return _supportProfiles.first;
  }

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  String? get _replyTargetId {
    final userId = _currentUserId;
    if (userId == null) return _defaultRecipient?.id;

    for (final message in _messages.reversed) {
      if (message.senderProfileId != userId &&
          _supportProfiles.any((profile) => profile.id == message.senderProfileId)) {
        return message.senderProfileId;
      }
    }
    return _defaultRecipient?.id;
  }

  Future<void> _markReadForCurrentThread() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final senderId = _replyTargetId;
    if (senderId == null) return;
    await ref.read(messagesRepositoryProvider).markConversationRead(senderId: senderId);
  }

  Future<void> _send() async {
    final receiverId = _replyTargetId;
    final message = _controller.text.trim();
    if (receiverId == null || message.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(messagesRepositoryProvider).sendMessage(
            receiverProfileId: receiverId,
            message: message,
          );
      _controller.clear();
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyMessagesError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: AppTextStyles.heading.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chat with XILLAFIT support about your order or design.',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body,
                        ),
                      ),
                    )
                  : _messages.isEmpty
                      ? ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
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
                                    'Send a message and our team will respond shortly.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final mine = message.senderProfileId == userId;
                            final hasImage = message.hasImage;
                            final hasText = message.hasText;
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 280),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: EdgeInsets.fromLTRB(
                                  hasImage ? 8 : 14,
                                  hasImage ? 8 : 10,
                                  hasImage ? 8 : 14,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: mine ? AppColors.gold : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(mine ? 18 : 6),
                                    bottomRight: Radius.circular(mine ? 6 : 18),
                                  ),
                                  border: Border.all(
                                    color: mine ? AppColors.gold : AppColors.border,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (hasImage)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 220,
                                            minHeight: 96,
                                            maxHeight: 220,
                                          ),
                                          child: Image.network(
                                            message.imageUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, progress) {
                                              if (progress == null) return child;
                                              return Container(
                                                width: 220,
                                                height: 140,
                                                color: mine
                                                    ? Colors.white.withValues(alpha: 0.28)
                                                    : const Color(0xFFF8F8F8),
                                                alignment: Alignment.center,
                                                child: const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              );
                                            },
                                            errorBuilder: (_, _, _) => Container(
                                              width: 220,
                                              height: 140,
                                              color: mine
                                                  ? Colors.white.withValues(alpha: 0.28)
                                                  : const Color(0xFFF8F8F8),
                                              alignment: Alignment.center,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Image unavailable',
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: const Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (hasImage && hasText) const SizedBox(height: 8),
                                    if (hasText)
                                      Text(
                                        message.messageContent,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(message.sentAt),
                                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sending ? null : _send(),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.gold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.text,
                    minimumSize: const Size(52, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedInShell) return body;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: body),
    );
  }
}

String _formatTime(DateTime? value) {
  if (value == null) return '-';
  final localValue = value.isUtc ? value.toLocal() : value;
  final hour =
      localValue.hour == 0 ? 12 : (localValue.hour > 12 ? localValue.hour - 12 : localValue.hour);
  final minute = localValue.minute.toString().padLeft(2, '0');
  final suffix = localValue.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _friendlyMessagesError(Object error) {
  final text = error.toString().trim();
  final lower = text.toLowerCase();

  if (lower.contains('product id or custom design id is required')) {
    return 'Unable to send your message right now. Please try again in a moment.';
  }
  if (lower.contains('not authenticated') || lower.contains('sign in')) {
    return 'Please sign in again to continue chatting with support.';
  }
  if (lower.contains('failed to fetch') ||
      lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('timeout')) {
    return 'Support chat is temporarily unavailable. Check your connection and try again.';
  }
  return 'Something went wrong in support chat. Please try again.';
}
