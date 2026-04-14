import 'chat_message_dto.dart';

class ChatMessagePageDto {
  final List<ChatMessageDto> items;
  final bool hasMore;
  final int? nextBeforeMessageId;

  ChatMessagePageDto({
    required this.items,
    required this.hasMore,
    this.nextBeforeMessageId,
  });

  factory ChatMessagePageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return ChatMessagePageDto(
      items: rawItems is List
          ? rawItems
          .map((e) => ChatMessageDto.fromJson(
        Map<String, dynamic>.from(e as Map),
      ))
          .toList()
          : <ChatMessageDto>[],
      hasMore: _toBool(json['hasMore']),
      nextBeforeMessageId: _toInt(json['nextBeforeMessageId']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    final text = value.toString().toLowerCase().trim();
    return text == 'true' || text == '1';
  }
}