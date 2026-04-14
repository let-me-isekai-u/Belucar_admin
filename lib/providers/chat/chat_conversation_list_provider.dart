import 'package:flutter/foundation.dart';

import '../../models/chat/chat_conversation_dto.dart';
import '../../services/api_chat_service.dart';
import '../../services/signalr_service.dart';

class ChatConversationListProvider extends ChangeNotifier {
  static const String _chatHubUrl = 'https://belucar.com/hubs/chat';
  static const String _newMessageEventName = 'chat.message.created';
  static const String _conversationChangedEventName =
      'chat.conversation.changed';

  final String token;
  final SignalRService _signalRService = SignalRService();

  ChatConversationListProvider({required this.token});

  final List<ChatConversationDto> _conversations = [];
  List<ChatConversationDto> get conversations =>
      List.unmodifiable(_conversations);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRealtimeConnecting = false;
  bool get isRealtimeConnecting => _isRealtimeConnecting;

  bool _isRealtimeConnected = false;
  bool get isRealtimeConnected => _isRealtimeConnected;

  bool _hasRegisteredRealtimeListeners = false;
  bool _hasRegisteredRealtimeLifecycleListeners = false;
  bool _isSyncingRealtimeSnapshot = false;
  bool _isDisposed = false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    await loadConversations();
    await connectRealtime();
  }

  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      safeNotify();
    }

    try {
      final data = await ApiChatService.getConversations(token);

      _conversations
        ..clear()
        ..addAll(data);

      _isLoading = false;
      safeNotify();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      safeNotify();
    }
  }

  Future<void> refreshConversations({bool silent = false}) async {
    await loadConversations(silent: silent);
  }

  Future<void> connectRealtime() async {
    if (_isRealtimeConnected || _isRealtimeConnecting) {
      return;
    }

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

      _isRealtimeConnected = true;
      _isRealtimeConnecting = false;
      safeNotify();
    } catch (e) {
      _isRealtimeConnected = false;
      _isRealtimeConnecting = false;
      _errorMessage = e.toString();
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

      _isRealtimeConnected = true;
      _isRealtimeConnecting = false;
      safeNotify();

      await _syncRealtimeSnapshot();
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
      if (_isDisposed) return;
      await _syncRealtimeSnapshot();
    });

    _signalRService.on(_conversationChangedEventName, (arguments) async {
      if (_isDisposed) return;
      await _syncRealtimeSnapshot();
    });
  }

  Future<void> _syncRealtimeSnapshot() async {
    if (_isDisposed || _isSyncingRealtimeSnapshot) return;

    _isSyncingRealtimeSnapshot = true;
    try {
      await loadConversations(silent: true);
    } finally {
      _isSyncingRealtimeSnapshot = false;
    }
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

  void clearError() {
    _errorMessage = null;
    safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    disconnectRealtime();
    super.dispose();
  }
}
