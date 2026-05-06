import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/chat/chat_conversation_dto.dart';
import '../models/chat/chat_message_page_dto.dart';
import '../models/chat/chat_ride_card_dto.dart';

class ApiChatService {
  static const String baseUrl = "https://xeghepdongduong.com/api/chat/admin";

  /// ================= SAFE DECODE =================
  static dynamic safeDecode(String? body) {
    if (body == null || body.isEmpty) return {};

    try {
      return jsonDecode(body);
    } catch (e) {
      print("!! safeDecode() JSON lỗi: $e !!");
      print("!! raw body: $body");
      return {};
    }
  }

  static Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// ================= 6.1 GET CONVERSATIONS =================
  static Future<List<ChatConversationDto>> getConversations(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/conversations"),
      headers: _headers(token),
    );

    final data = safeDecode(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((e) => ChatConversationDto.fromJson(e))
          .toList();
    }

    throw Exception("Lỗi getConversations");
  }

  /// ================= 6.3 GET MESSAGES =================
  static Future<ChatMessagePageDto> getMessages(
      String token,
      int conversationId, {
        int? beforeMessageId,
        int take = 30,
      }) async {
    final uri = Uri.parse(
      "$baseUrl/conversations/$conversationId/messages",
    ).replace(queryParameters: {
      if (beforeMessageId != null)
        "beforeMessageId": beforeMessageId.toString(),
      "take": take.toString(),
    });

    final res = await http.get(uri, headers: _headers(token));
    final data = safeDecode(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      return ChatMessagePageDto.fromJson(data['data']);
    }

    throw Exception("Lỗi getMessages");
  }

  /// ================= 6.4 SEND MESSAGE =================
  static Future<void> sendMessage(
      String token,
      int conversationId,
      String content,
      ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/$conversationId/messages"),
      headers: _headers(token),
      body: jsonEncode({
        "content": content,
      }),
    );

    final data = safeDecode(res.body);

    if (!(res.statusCode == 200 && data['success'] == true)) {
      throw Exception("Lỗi sendMessage");
    }
  }

  /// ================= 6.5 CREATE RIDE =================
  static Future<ChatRideCardDto> createRide(
      String token,
      int conversationId,
      Map<String, dynamic> body,
      ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/$conversationId/create-ride"),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = safeDecode(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      return ChatRideCardDto.fromJson(data['data']);
    }

    throw Exception("Lỗi createRide");
  }

  /// ================= 6.6 UPDATE RIDE =================
  static Future<ChatRideCardDto> updateRide(
      String token,
      int rideId,
      Map<String, dynamic> body,
      ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/rides/$rideId"),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = safeDecode(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      return ChatRideCardDto.fromJson(data['data']);
    }

    throw Exception("Lỗi updateRide");
  }

  /// ================= 6.7 CANCEL RIDE =================
  static Future<ChatRideCardDto> cancelRide(
      String token,
      int rideId,
      ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/rides/$rideId/cancel"),
      headers: _headers(token),
      body: jsonEncode({}),
    );

    final data = safeDecode(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      return ChatRideCardDto.fromJson(data['data']);
    }

    throw Exception("Lỗi cancelRide");
  }

  /// ================= 6.8 MARK AS READ =================
  static Future<void> markAsRead(
      String token,
      int conversationId,
      ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/$conversationId/mark-read"),
      headers: _headers(token),
    );

    final data = safeDecode(res.body);

    if (!(res.statusCode == 200 && data['success'] == true)) {
      throw Exception("Lỗi markAsRead");
    }
  }
}