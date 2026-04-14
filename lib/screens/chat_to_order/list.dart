import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/chat/chat_conversation_dto.dart';
import '../../providers/chat/chat_conversation_list_provider.dart';
import 'chat_detail_screen.dart';

class MessageListScreen extends StatelessWidget {
  final String token;

  const MessageListScreen({super.key, required this.token});

  static const Color beluLightBlue = Colors.lightBlue;
  static const Color beluDarkBlue = Color(0xFF0288D1);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatConversationListProvider(token: token)..initialize(),
      child: const _MessageListView(),
    );
  }
}

class _MessageListView extends StatelessWidget {
  const _MessageListView();

  static const Color beluLightBlue = Colors.lightBlue;
  static const Color beluDarkBlue = Color(0xFF0288D1);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatConversationListProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Tin nhắn khách hàng",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [beluLightBlue, beluDarkBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage ?? 'Đã có lỗi xảy ra',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadConversations(),
                      child: const Text("Thử lại"),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.refreshConversations,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Text(
                      "Chưa có cuộc trò chuyện nào",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refreshConversations,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.conversations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 85,
                color: Color(0xFFEEEEEE),
              ),
              itemBuilder: (context, index) {
                final chat = provider.conversations[index];
                return _buildMessageItem(context, chat, token: provider.token);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    ChatConversationDto chat, {
    required String token,
  }) {
    final hasUnread = chat.unreadCount > 0;
    final name = chat.customerName.trim().isEmpty
        ? 'Khách hàng'
        : chat.customerName.trim();
    final preview = _buildPreview(chat);

    return InkWell(
      onTap: () async {
        final listProvider = context.read<ChatConversationListProvider>();
        final navigator = Navigator.of(context);

        await navigator.push(
          MaterialPageRoute(
            builder: (context) =>
                ChatDetailScreen(token: token, conversation: chat),
          ),
        );

        await listProvider.refreshConversations(silent: true);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: beluLightBlue.withValues(alpha: 0.1),
                  child: Text(
                    _avatarText(name),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: beluDarkBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chat.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? beluDarkBlue : Colors.grey,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if ((chat.customerPhone).trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      chat.customerPhone,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _avatarText(String name) {
    if (name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }

  String _buildPreview(ChatConversationDto chat) {
    switch (chat.lastMessageType) {
      case 3:
        return "[Tạo đơn] ${chat.lastMessagePreview}";
      case 4:
        return "[Cập nhật đơn] ${chat.lastMessagePreview}";
      case 1:
      default:
        return chat.lastMessagePreview.trim().isEmpty
            ? "Chưa có tin nhắn"
            : chat.lastMessagePreview;
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final local = dateTime.toLocal();
    final difference = now.difference(local);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(local);
    } else if (difference.inDays == 1) {
      return "Hôm qua";
    } else {
      return DateFormat('dd/MM').format(local);
    }
  }
}
