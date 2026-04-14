class ChatConversationDto {
  final int id;
  final int? status;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final int? handlingAdminId;
  final String? handlingAdminName;
  final int? rideId;
  final String lastMessagePreview;
  final int? lastMessageSenderType;
  final int? lastMessageType;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatConversationDto({
    required this.id,
    this.status,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.handlingAdminId,
    this.handlingAdminName,
    this.rideId,
    required this.lastMessagePreview,
    this.lastMessageSenderType,
    this.lastMessageType,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversationDto.fromJson(Map<String, dynamic> json) {
    return ChatConversationDto(
      id: _toInt(json['id']) ?? 0,
      status: _toInt(json['status']),
      customerId: _toInt(json['customerId']) ?? 0,
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      handlingAdminId: _toInt(json['handlingAdminId']),
      handlingAdminName: json['handlingAdminName']?.toString(),
      rideId: _toInt(json['rideId']),
      lastMessagePreview: (json['lastMessagePreview'] ?? '').toString(),
      lastMessageSenderType: _toInt(json['lastMessageSenderType']),
      lastMessageType: _toInt(json['lastMessageType']),
      lastMessageAt: _toDateTime(json['lastMessageAt']),
      unreadCount: _toInt(json['unreadCount']) ?? 0,
    );
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