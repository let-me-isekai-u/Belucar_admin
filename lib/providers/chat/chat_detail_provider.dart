import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/admin_ride_lookup_model.dart';
import '../../models/chat/chat_conversation_dto.dart';
import '../../models/chat/chat_message_dto.dart';
import '../../models/chat/chat_message_page_dto.dart';
import '../../models/chat/chat_ride_card_dto.dart';
import '../../services/api_chat_service.dart';
import '../../services/api_service.dart';
import '../../services/signalr_service.dart';
import 'chat_detail_tab.dart';

class ChatDetailProvider extends ChangeNotifier {
  static const String _chatHubUrl = 'https://belucar.com/hubs/chat';
  static const String _joinConversationMethod = 'JoinConversation';
  static const String _newMessageEventName = 'chat.message.created';
  static const String _conversationChangedEventName =
      'chat.conversation.changed';

  final String token;
  final ChatConversationDto conversation;
  final SignalRService _signalRService = SignalRService();

  ChatDetailProvider({required this.token, required this.conversation});

  /// ================= STATE =================
  ChatDetailTab _currentTab = ChatDetailTab.text;
  ChatDetailTab get currentTab => _currentTab;

  final List<ChatMessageDto> _messages = [];
  List<ChatMessageDto> get messages => List.unmodifiable(_messages);

  ChatRideCardDto? _currentRide;
  ChatRideCardDto? get currentRide => _currentRide;

  bool _isInitialLoading = false;
  bool get isInitialLoading => _isInitialLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  bool _isCreatingRide = false;
  bool get isCreatingRide => _isCreatingRide;

  bool _isUpdatingRide = false;
  bool get isUpdatingRide => _isUpdatingRide;

  bool _isCancellingRide = false;
  bool get isCancellingRide => _isCancellingRide;

  bool _isMarkingRead = false;
  bool get isMarkingRead => _isMarkingRead;

  bool _isCheckingRideStatus = false;
  bool get isCheckingRideStatus => _isCheckingRideStatus;
  bool _isRealtimeConnecting = false;
  bool get isRealtimeConnecting => _isRealtimeConnecting;
  bool _isRealtimeConnected = false;
  bool get isRealtimeConnected => _isRealtimeConnected;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  int? _nextBeforeMessageId;
  int? get nextBeforeMessageId => _nextBeforeMessageId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _hasRegisteredRealtimeListeners = false;
  bool _hasRegisteredRealtimeLifecycleListeners = false;
  bool _isSyncingRealtimeSnapshot = false;
  bool _isDisposed = false;
  Timer? _snapshotPollingTimer;

  bool get hasMessages => _messages.isNotEmpty;

  int get conversationId => conversation.id;

  /// Trạng thái ride đã được đối soát lại từ 2 API admin list
  int? _resolvedRideStatus;
  int? get resolvedRideStatus => _resolvedRideStatus;

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Ride active theo rule backend thực tế hiện tại chỉ cần:
  /// - status 1: pending
  /// - status 5: cancelled
  ///
  /// nhưng vẫn giữ fallback từ currentRide nếu chưa resolve được
  bool get hasActiveRide {
    final status = _resolvedRideStatus ?? _currentRide?.status;
    if (status == null) return false;
    return status == 1;
  }

  bool get canCreateRide {
    final ride = _currentRide;
    final status = _resolvedRideStatus ?? ride?.status;

    if (ride == null) return true;
    return status == 5;
  }

  bool get canUpdateRide {
    final ride = _currentRide;
    if (ride == null) return false;

    final status = _resolvedRideStatus ?? ride.status;
    return status == 1;
  }

  bool get canCancelRide {
    final ride = _currentRide;
    if (ride == null) return false;

    final status = _resolvedRideStatus ?? ride.status;
    return status == 1;
  }

  /// ================= TAB =================
  void setTab(ChatDetailTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    safeNotify();
  }

  /// ================= INIT =================
  Future<void> initialize() async {
    _errorMessage = null;
    _isInitialLoading = true;
    safeNotify();

    try {
      _startSnapshotPolling();

      final page = await ApiChatService.getMessages(
        token,
        conversation.id,
        take: 30,
      );

      _replaceMessages(page);
      _updateCurrentRideFromMessages();

      await _refreshResolvedRideStatus();

      if (_isDisposed) return;

      _isInitialLoading = false;
      safeNotify();

      await markAsRead();
      if (_isDisposed) return;
      await _connectRealtime();
    } catch (e) {
      _isInitialLoading = false;
      _errorMessage = e.toString();
      safeNotify();
    }
  }

  /// ================= LOAD MESSAGES =================
  Future<void> refreshMessages({bool silent = false}) async {
    if (!silent) {
      _errorMessage = null;
      safeNotify();
    }

    try {
      final previousLastMessageId = _messages.isNotEmpty
          ? _messages.last.id
          : null;

      final page = await ApiChatService.getMessages(
        token,
        conversation.id,
        take: 30,
      );

      _replaceMessages(page);
      _updateCurrentRideFromMessages();

      await _refreshResolvedRideStatus();

      final latestLastMessageId = _messages.isNotEmpty
          ? _messages.last.id
          : null;

      if (latestLastMessageId != null &&
          latestLastMessageId != previousLastMessageId) {
        await markAsRead(silent: true);
      }

      if (!silent) {
        safeNotify();
      } else if (!_isDisposed) {
        safeNotify();
      }
    } catch (e) {
      if (!silent) {
        _errorMessage = e.toString();
        safeNotify();
      }
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _nextBeforeMessageId == null) return;

    _isLoadingMore = true;
    _errorMessage = null;
    safeNotify();

    try {
      final page = await ApiChatService.getMessages(
        token,
        conversation.id,
        beforeMessageId: _nextBeforeMessageId,
        take: 30,
      );

      final existingIds = _messages.map((message) => message.id).toSet();
      final olderItems = page.items
          .where((message) => !existingIds.contains(message.id))
          .toList();

      _messages.insertAll(0, olderItems);

      _hasMore = page.hasMore;
      _nextBeforeMessageId = page.nextBeforeMessageId;

      _updateCurrentRideFromMessages();

      await _refreshResolvedRideStatus();

      _isLoadingMore = false;
      safeNotify();
    } catch (e) {
      _isLoadingMore = false;
      _errorMessage = e.toString();
      safeNotify();
    }
  }

  /// ================= SEND MESSAGE =================
  Future<bool> sendTextMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty) return false;
    if (_isSendingMessage) return false;

    _isSendingMessage = true;
    _errorMessage = null;
    safeNotify();

    try {
      await ApiChatService.sendMessage(token, conversation.id, text);

      await refreshMessages();

      _isSendingMessage = false;
      safeNotify();
      return true;
    } catch (e) {
      _isSendingMessage = false;
      _errorMessage = e.toString();
      safeNotify();
      return false;
    }
  }

  /// ================= CREATE RIDE =================
  Future<bool> createRide(Map<String, dynamic> body) async {
    if (_isCreatingRide) return false;

    _isCreatingRide = true;
    _errorMessage = null;
    safeNotify();

    try {
      await ApiChatService.createRide(token, conversation.id, body);

      await refreshMessages();
      await _refreshResolvedRideStatus();

      setTab(ChatDetailTab.updateOrder);

      _isCreatingRide = false;
      safeNotify();
      return true;
    } catch (e) {
      _isCreatingRide = false;
      _errorMessage = e.toString();
      safeNotify();
      return false;
    }
  }

  /// ================= UPDATE RIDE =================
  Future<bool> updateCurrentRide(Map<String, dynamic> body) async {
    final ride = _currentRide;
    if (ride == null) {
      _errorMessage = "Không tìm thấy đơn để cập nhật";
      safeNotify();
      return false;
    }

    if (_isUpdatingRide) return false;

    _isUpdatingRide = true;
    _errorMessage = null;
    safeNotify();

    try {
      await ApiChatService.updateRide(token, ride.rideId, body);

      await refreshMessages();
      await _refreshResolvedRideStatus();

      setTab(ChatDetailTab.updateOrder);

      _isUpdatingRide = false;
      safeNotify();
      return true;
    } catch (e) {
      _isUpdatingRide = false;
      _errorMessage = e.toString();
      safeNotify();
      return false;
    }
  }

  /// ================= CANCEL RIDE =================
  Future<bool> cancelCurrentRide() async {
    final ride = _currentRide;
    if (ride == null) {
      _errorMessage = "Không tìm thấy đơn để huỷ";
      safeNotify();
      return false;
    }

    if (_isCancellingRide) return false;

    _isCancellingRide = true;
    _errorMessage = null;
    safeNotify();

    try {
      await ApiChatService.cancelRide(token, ride.rideId);

      /// refresh messages trước
      await refreshMessages();

      /// đối soát lại status thật sự từ admin lists
      await _refreshResolvedRideStatus();

      /// nếu đã hủy rồi thì vẫn để ở tab update để user nhìn thấy thông tin,
      /// hoặc bạn có thể chuyển về text nếu muốn
      setTab(ChatDetailTab.updateOrder);

      _isCancellingRide = false;
      safeNotify();
      return true;
    } catch (e) {
      _isCancellingRide = false;
      _errorMessage = e.toString();
      safeNotify();
      return false;
    }
  }

  /// ================= MARK READ =================
  Future<void> markAsRead({bool silent = false}) async {
    if (_isMarkingRead) return;

    _isMarkingRead = true;
    if (!silent) {
      safeNotify();
    }

    try {
      await ApiChatService.markAsRead(token, conversation.id);
    } catch (_) {
      /// không block UI nếu mark read lỗi
    } finally {
      _isMarkingRead = false;
      if (!silent) {
        safeNotify();
      }
    }
  }

  /// ================= HELPERS =================
  void clearError() {
    _errorMessage = null;
    safeNotify();
  }

  void _replaceMessages(ChatMessagePageDto page) {
    _messages
      ..clear()
      ..addAll(page.items);

    _hasMore = page.hasMore;
    _nextBeforeMessageId = page.nextBeforeMessageId;
  }

  void _addIncomingMessage(ChatMessageDto incoming) {
    if (incoming.conversationId != conversation.id) {
      return;
    }

    final exists = _messages.any((m) => m.id == incoming.id);
    if (exists) return;

    _messages.add(incoming);
    _messages.sort((a, b) => a.id.compareTo(b.id));
    _updateCurrentRideFromMessages();
    safeNotify();
  }

  Future<void> _connectRealtime() async {
    if (_isDisposed || _isRealtimeConnected || _isRealtimeConnecting) return;

    _isRealtimeConnecting = true;
    safeNotify();

    try {
      _signalRService.ensureConnection(hubUrl: _chatHubUrl, accessToken: token);

      if (!_hasRegisteredRealtimeLifecycleListeners) {
        _registerRealtimeLifecycleListeners();
        _hasRegisteredRealtimeLifecycleListeners = true;
      }

      if (!_hasRegisteredRealtimeListeners) {
        _registerRealtimeListeners();
        _hasRegisteredRealtimeListeners = true;
      }

      await _signalRService.connect(hubUrl: _chatHubUrl, accessToken: token);

      if (_isDisposed) {
        await _signalRService.disconnect();
        return;
      }

      await _signalRService.invoke(
        _joinConversationMethod,
        args: [conversation.id],
      );

      _isRealtimeConnected = true;
      _isRealtimeConnecting = false;
      safeNotify();
    } catch (e) {
      _isRealtimeConnected = false;
      _isRealtimeConnecting = false;
      debugPrint('ChatDetailProvider connectRealtime error: $e');
      safeNotify();
    }
  }

  void _registerRealtimeLifecycleListeners() {
    _signalRService.onReconnecting(({error}) {
      _isRealtimeConnected = false;
      _isRealtimeConnecting = true;
      safeNotify();
    });

    _signalRService.onReconnected(({connectionId}) async {
      if (_isDisposed) return;
      try {
        await _signalRService.invoke(
          _joinConversationMethod,
          args: [conversation.id],
        );
        _isRealtimeConnected = true;
        _isRealtimeConnecting = false;
        safeNotify();

        await refreshMessages(silent: true);
      } catch (e) {
        _isRealtimeConnected = false;
        _isRealtimeConnecting = false;
        debugPrint('ChatDetailProvider reconnected error: $e');
        safeNotify();
      }
    });

    _signalRService.onClose(({error}) {
      _isRealtimeConnected = false;
      _isRealtimeConnecting = false;
      safeNotify();
    });
  }

  void _registerRealtimeListeners() {
    _signalRService.off(_newMessageEventName);
    _signalRService.off(_conversationChangedEventName);

    _signalRService.on(_newMessageEventName, (arguments) async {
      if (_isDisposed || arguments == null || arguments.isEmpty) return;

      final raw = arguments.first;
      final parsedMessage = _tryParseRealtimeMessage(raw);

      if (parsedMessage == null) {
        await _syncRealtimeSnapshot();
        return;
      }

      _addIncomingMessage(parsedMessage);

      if (parsedMessage.messageType == 3 || parsedMessage.messageType == 4) {
        await _refreshResolvedRideStatus();
      }

      if (parsedMessage.conversationId == conversation.id) {
        await markAsRead();
      }
    });

    _signalRService.on(_conversationChangedEventName, (arguments) async {
      if (_isDisposed) return;
      await refreshMessages(silent: true);
    });
  }

  ChatMessageDto? _tryParseRealtimeMessage(dynamic raw) {
    dynamic decoded = raw;

    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        return null;
      }
    }

    if (decoded is! Map) return null;

    final rootMap = Map<String, dynamic>.from(decoded);
    final candidates = <Map<String, dynamic>>[
      rootMap,
      if (rootMap['data'] is Map)
        Map<String, dynamic>.from(rootMap['data'] as Map),
      if (rootMap['message'] is Map)
        Map<String, dynamic>.from(rootMap['message'] as Map),
    ];

    for (final candidate in candidates) {
      try {
        final message = ChatMessageDto.fromJson(candidate);
        if (message.id > 0 && message.conversationId > 0) {
          return message;
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> _syncRealtimeSnapshot() async {
    if (_isDisposed || _isSyncingRealtimeSnapshot) return;

    _isSyncingRealtimeSnapshot = true;
    try {
      await refreshMessages(silent: true);
    } finally {
      _isSyncingRealtimeSnapshot = false;
    }
  }

  void _startSnapshotPolling() {
    _snapshotPollingTimer?.cancel();
    _snapshotPollingTimer = Timer.periodic(const Duration(seconds: 3), (
      _,
    ) async {
      if (_isDisposed ||
          _isInitialLoading ||
          _isLoadingMore ||
          _isSendingMessage ||
          _isCreatingRide ||
          _isUpdatingRide ||
          _isCancellingRide ||
          _isSyncingRealtimeSnapshot) {
        return;
      }

      await _syncRealtimeSnapshot();
    });
  }

  Future<void> disconnectRealtime() async {
    try {
      _signalRService.off(_newMessageEventName);
      _signalRService.off(_conversationChangedEventName);
      await _signalRService.disconnect();
    } catch (_) {}

    _hasRegisteredRealtimeListeners = false;
    _hasRegisteredRealtimeLifecycleListeners = false;
    _isRealtimeConnected = false;
    _isRealtimeConnecting = false;
    safeNotify();
  }

  void _updateCurrentRideFromMessages() {
    _currentRide = _extractLatestRide(_messages);
  }

  ChatRideCardDto? _extractLatestRide(List<ChatMessageDto> messages) {
    for (final message in messages.reversed) {
      if ((message.messageType == 3 || message.messageType == 4) &&
          message.ride != null) {
        return message.ride;
      }
    }
    return null;
  }

  Future<void> _refreshResolvedRideStatus() async {
    final ride = _currentRide;

    if (ride == null) {
      _resolvedRideStatus = null;
      return;
    }

    _isCheckingRideStatus = true;
    safeNotify();

    try {
      final pendingItems = await ApiService.getPendingRideItems(
        accessToken: token,
        page: 1,
        pageSize: 100,
      );

      final pendingMatch = _findRideInLookupList(
        rideId: ride.rideId,
        code: ride.code,
        items: pendingItems,
      );

      if (pendingMatch != null) {
        _resolvedRideStatus = 1;
        _isCheckingRideStatus = false;
        safeNotify();
        return;
      }

      final cancelledItems = await ApiService.getCanceledRideItems(
        accessToken: token,
        page: 1,
        pageSize: 100,
      );

      final cancelledMatch = _findRideInLookupList(
        rideId: ride.rideId,
        code: ride.code,
        items: cancelledItems,
      );

      if (cancelledMatch != null) {
        _resolvedRideStatus = 5;
      } else {
        /// fallback nếu chưa dò thấy
        _resolvedRideStatus = ride.status;
      }
    } catch (_) {
      _resolvedRideStatus = ride.status;
    } finally {
      _isCheckingRideStatus = false;
      safeNotify();
    }
  }

  AdminRideLookupModel? _findRideInLookupList({
    required int rideId,
    required String code,
    required List<AdminRideLookupModel> items,
  }) {
    for (final item in items) {
      if (item.rideId == rideId) return item;
      if (code.isNotEmpty && item.code == code) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _snapshotPollingTimer?.cancel();
    disconnectRealtime();
    super.dispose();
  }
}
