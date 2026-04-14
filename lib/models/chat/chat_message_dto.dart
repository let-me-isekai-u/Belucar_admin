import 'dart:convert';

import 'chat_ride_card_dto.dart';

class ChatMessageDto {
  final int id;
  final int conversationId;
  final int senderType; // 1: customer, 2: admin, 3: system
  final int? senderId;
  final String senderName;
  final int messageType; // 1: text, 3: create ride, 4: update/cancel ride
  final String content;
  final String? metadataJson;
  final DateTime? createdAt;

  ChatMessageDto({
    required this.id,
    required this.conversationId,
    required this.senderType,
    this.senderId,
    required this.senderName,
    required this.messageType,
    required this.content,
    this.metadataJson,
    required this.createdAt,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: _toInt(json['id']) ?? 0,
      conversationId: _toInt(json['conversationId']) ?? 0,
      senderType: _toInt(json['senderType']) ?? 0,
      senderId: _toInt(json['senderId']),
      senderName: (json['senderName'] ?? '').toString(),
      messageType: _toInt(json['messageType']) ?? 0,
      content: (json['content'] ?? '').toString(),
      metadataJson: json['metadataJson']?.toString(),
      createdAt: _toDateTime(json['createdAt']),
    );
  }

  /// parse metadataJson -> ChatRideCardDto
  /// chỉ áp dụng cho messageType = 3 hoặc 4
  ChatRideCardDto? get ride {
    if (messageType != 3 && messageType != 4) return null;
    if (metadataJson == null) return null;

    final raw = metadataJson!.trim();
    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ChatRideCardDto.fromJson(decoded);
      }
      if (decoded is Map) {
        return ChatRideCardDto.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}