import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../models/role_1/ride_detail.dart';

class RideDetailRole1Service {
  static const String baseUrl = "https://xeghepdongduong.com/api";

  static Map<String, String> _getHeaders(String? token) {
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  static Future<http.Response> getRideDetailRole1({
    required String accessToken,
    required int rideId,
    required int rideSource,
  }) async {
    final url = Uri.parse("$baseUrl/AdminApi/rides/$rideId/$rideSource");

    debugPrint('📡 [RideDetailService] GET $url');
    debugPrint('📡 [RideDetailService] rideId=$rideId | rideSource=$rideSource');
    debugPrint('📡 [RideDetailService] token=${accessToken.isNotEmpty ? accessToken.substring(0, accessToken.length.clamp(0, 20))+'...' : '❌ TRỐNG'}');

    final response = await http.get(
      url,
      headers: _getHeaders(accessToken),
    );

    debugPrint('📡 [RideDetailService] Status: ${response.statusCode}');
    debugPrint('📡 [RideDetailService] Body: ${response.body}');

    return response;
  }

  static Future<RideDetail> getRideDetailRole1Item({
    required String accessToken,
    required int rideId,
    required int rideSource,
  }) async {
    final response = await getRideDetailRole1(
      accessToken: accessToken,
      rideId: rideId,
      rideSource: rideSource,
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Không thể tải chi tiết chuyến: ${response.statusCode}",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];

      if (data is Map<String, dynamic>) {
        return RideDetail.fromJson(data);
      }
    }

    throw Exception("Dữ liệu chi tiết chuyến không hợp lệ");
  }
}