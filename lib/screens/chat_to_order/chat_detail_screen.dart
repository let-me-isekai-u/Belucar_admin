import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat/chat_conversation_dto.dart';
import '../../providers/chat/chat_detail_provider.dart';
import '../../providers/chat/chat_detail_tab.dart';
import 'chat_page/create_order_screen.dart';
import 'chat_page/text_screen.dart';
import 'chat_page/update_order_screen.dart';

class ChatDetailScreen extends StatelessWidget {
  final String token;
  final ChatConversationDto conversation;

  const ChatDetailScreen({
    super.key,
    required this.token,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatDetailProvider(
        token: token,
        conversation: conversation,
      )..initialize(),
      child: const _ChatDetailView(),
    );
  }
}

class _ChatDetailView extends StatelessWidget {
  const _ChatDetailView();

  static const Color beluLightBlue = Colors.lightBlue;
  static const Color beluDarkBlue = Color(0xFF0288D1);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatDetailProvider>();
    final conversation = provider.conversation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.customerName.trim().isEmpty
                  ? 'Khách hàng'
                  : conversation.customerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (conversation.customerPhone.trim().isNotEmpty)
              Text(
                conversation.customerPhone,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
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
        actions: [
          IconButton(
            icon: Icon(
              provider.currentTab == ChatDetailTab.text
                  ? Icons.assignment_add
                  : Icons.chat,
            ),
            onPressed: () {
              if (provider.currentTab == ChatDetailTab.text) {
                provider.setTab(ChatDetailTab.createOrder);
              } else {
                provider.setTab(ChatDetailTab.text);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabIndicator(context, provider),
          if (provider.errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ),
          Expanded(
            child: _renderBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIndicator(BuildContext context, ChatDetailProvider provider) {
    return Container(
      color: Colors.grey[100],
      child: Row(
        children: [
          _tabButton(
            title: "Tin nhắn",
            tab: ChatDetailTab.text,
            provider: provider,
          ),
          _tabButton(
            title: "Tạo đơn",
            tab: ChatDetailTab.createOrder,
            provider: provider,
          ),
          _tabButton(
            title: "Đơn hiện tại",
            tab: ChatDetailTab.updateOrder,
            provider: provider,
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required ChatDetailTab tab,
    required ChatDetailProvider provider,
  }) {
    final isActive = provider.currentTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => provider.setTab(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderBody(BuildContext context, ChatDetailProvider provider) {
    if (provider.isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (provider.currentTab) {
      case ChatDetailTab.text:
        return TextScreen(
          messages: provider.messages,
          isSending: provider.isSendingMessage,
          hasMore: provider.hasMore,
          isLoadingMore: provider.isLoadingMore,
          onLoadMore: provider.loadMoreMessages,
          onRefresh: provider.refreshMessages,
          onSendMessage: (content) async {
            await provider.sendTextMessage(content);
          },
        );

      case ChatDetailTab.createOrder:
        return CreateOrderScreen(
          token: provider.token,
          currentRide: provider.currentRide,
          canCreateRide: provider.canCreateRide,
          isCreating: provider.isCreatingRide,
          onCreateRide: (data) async {
            final ok = await provider.createRide(data);
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tạo đơn thành công")),
              );
            }
          },
        );

      case ChatDetailTab.updateOrder:
        return UpdateOrderScreen(
          token: provider.token,
          rides: provider.rides,
          latestRideId: provider.currentRide?.rideId,
          currentRide: provider.selectedRide,
          resolvedRideStatus: provider.resolvedRideStatus,
          isCheckingRideStatus: provider.isCheckingRideStatus,
          canUpdateRide: provider.canUpdateRide,
          canCancelRide: provider.canCancelRide,
          isUpdating: provider.isUpdatingRide,
          isCancelling: provider.isCancellingRide,
          onSelectRide: provider.selectRide,
          onUpdateRide: (id, data) async {
            final ok = await provider.updateCurrentRide(data);
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cập nhật đơn thành công")),
              );
            }
          },
          onCancelRide: (id) async {
            final ok = await provider.cancelCurrentRide();
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Huỷ đơn thành công")),
              );
            }
          },
        );
    }
  }
}
