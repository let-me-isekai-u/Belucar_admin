import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/chat/chat_message_dto.dart';

class TextScreen extends StatefulWidget {
  final List<ChatMessageDto> messages;
  final bool isSending;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String content) onSendMessage;

  const TextScreen({
    super.key,
    required this.messages,
    required this.onSendMessage,
    required this.onLoadMore,
    required this.onRefresh,
    this.isSending = false,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color beluDarkBlue = Color(0xFF0288D1);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant TextScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldLastId = oldWidget.messages.isNotEmpty ? oldWidget.messages.last.id : null;
    final newLastId = widget.messages.isNotEmpty ? widget.messages.last.id : null;

    if (newLastId != null && newLastId != oldLastId) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScrollLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollLoadMore() {
    if (!_scrollController.hasClients) return;
    if (!widget.hasMore || widget.isLoadingMore) return;
    if (_scrollController.position.pixels <= 80) {
      widget.onLoadMore();
    }
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    _controller.clear();
    await widget.onSendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent + 80;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC), // Nền xám rất nhạt cho toàn app
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: widget.messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text("Chưa có tin nhắn nào", style: TextStyle(color: Colors.grey, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: widget.messages.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final adjustedIndex = widget.isLoadingMore ? index - 1 : index;
        final message = widget.messages[adjustedIndex];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(ChatMessageDto message) {
    if (message.messageType == 3 || message.messageType == 4) {
      return _buildRideCard(message);
    }
    return _buildTextMessage(message);
  }

  Widget _buildTextMessage(ChatMessageDto message) {
    final isAdmin = message.senderType == 2;
    final isSystem = message.senderType == 3;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
          child: Text(message.content, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
        ),
      );
    }

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(message.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAdmin ? beluDarkBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                  bottomRight: Radius.circular(isAdmin ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(fontSize: 15, color: isAdmin ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      DateFormat('HH:mm').format(
                        message.createdAt?.toLocal() ?? DateTime.now(),
                      ),
                    style: TextStyle(fontSize: 10, color: isAdmin ? Colors.white70 : Colors.black38),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(ChatMessageDto message) {
    final ride = message.ride;
    if (ride == null) return const SizedBox.shrink();

    final isCancelled = ride.status == 5;
    final accentColor = isCancelled ? Colors.red : beluDarkBlue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header của Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(isCancelled ? Icons.cancel : Icons.local_taxi, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  isCancelled ? "ĐƠN ĐÃ HỦY" : "ĐƠN HÀNG #${ride.code}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor),
                ),
                const Spacer(),
                Text(DateFormat('HH:mm').format(
                  message.createdAt?.toLocal() ?? DateTime.now(),
                ), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _rideInfoRow(Icons.radio_button_checked, Colors.green, "Từ: ${ride.fromAddress}"),
                const Padding(padding: EdgeInsets.only(left: 10), child: SizedBox(height: 10, child: VerticalDivider(thickness: 1))),
                _rideInfoRow(Icons.location_on, Colors.red, "Đến: ${ride.toAddress}"),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _rideInfoItem(Icons.people_outline, "${ride.quantity} khách"),
                    _rideInfoItem(Icons.access_time, DateFormat('HH:mm dd/MM').format(ride.pickupTime!.toLocal())),
                    Text(_formatMoney(ride.finalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: beluDarkBlue, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideInfoRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _rideInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: widget.isSending ? null : _handleSend,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: beluDarkBlue,
                child: widget.isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double value) => NumberFormat('#,###', 'vi_VN').format(value) + ' đ';
}
