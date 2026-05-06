import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher_statistic_model.dart';

class ApiService {
  static const String baseUrl = "https://xeghepdongduong.com/api";

  // ================= HEADER =================
  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  // ================= AUTH =================
  static Future<http.Response> login({
    required String phone,
    required String password,
    String? deviceToken,
  }) async {
    final url = Uri.parse("$baseUrl/adminapi/login");

    return await http.post(
      url,
      headers: _getHeaders(null),
      body: jsonEncode({
        "phone": phone,
        "password": password,
        "deviceToken": deviceToken ?? "",
      }),
    );
  }

  // ================= RIDES =================
  static Future<http.Response> getPendingRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/rides/pending?page=$page&pageSize=$pageSize",
    );

    return await http.get(url, headers: _getHeaders(accessToken));
  }

  static Future<http.Response> getAcceptedRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/rides/accept?page=$page&pageSize=$pageSize",
    );

    return await http.get(url, headers: _getHeaders(accessToken));
  }

  static Future<http.Response> getProcessingRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/rides/process?page=$page&pageSize=$pageSize",
    );

    return await http.get(url, headers: _getHeaders(accessToken));
  }

  static Future<http.Response> getCompletedRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/rides/success?page=$page&pageSize=$pageSize",
    );

    return await http.get(url, headers: _getHeaders(accessToken));
  }

  static Future<http.Response> getCanceledRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/rides/cancel?page=$page&pageSize=$pageSize",
    );

    return await http.get(url, headers: _getHeaders(accessToken));
  }

  // ================= STATISTICS =================

  static Future<http.Response> getStatisticalDay({
    required String accessToken,
    required String date,
  }) async {
    final url = Uri.parse("$baseUrl/adminapi/statistical-day?date=$date");

    return await http.get(
      url,
      headers: _getHeaders(accessToken),
    );
  }

  static Future<http.Response> getStatisticalMonth({
    required String accessToken,
    required int month,
    required int year,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/statistical-month?month=$month&year=$year",
    );

    return await http.get(
      url,
      headers: _getHeaders(accessToken),
    );
  }

  static Future<http.Response> getStatisticalYear({
    required String accessToken,
    required int year,
  }) async {
    final url = Uri.parse("$baseUrl/adminapi/statistical-year?year=$year");

    return await http.get(
      url,
      headers: _getHeaders(accessToken),
    );
  }

  // ================= VOUCHER =================
  static Future<List<VoucherStatisticModel>> getVoucherStatistics() async {
    final url = Uri.parse("$baseUrl/adminapi/voucher/statistics");

    final response = await http.get(
      url,
      headers: _getHeaders(null),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((item) => VoucherStatisticModel.fromJson(item))
            .toList();
      }

      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((item) => VoucherStatisticModel.fromJson(item))
            .toList();
      }

      throw Exception("Dữ liệu voucher không hợp lệ");
    } else {
      throw Exception("Không thể tải thống kê voucher: ${response.statusCode}");
    }
  }

  // ================= WITHDRAW =================

  static Future<http.Response> getWithdrawalRequest({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/withdrawals?page=$page&pageSize=$pageSize",
    );

    return await http.get(url, headers: _getHeaders(accessToken));
  }

  static Future<http.Response> getWithdrawalConfirmHistory({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/withdrawal/history?page=$page&pageSize=$pageSize",
    );

    return await http.get(url, headers: _getHeaders(accessToken));
  }

  static Future<http.Response> acceptWithdrawalRequest({
    required String accessToken,
    required int withdrawalId,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/withdrawal/accept/$withdrawalId",
    );

    return await http.post(
      url,
      headers: _getHeaders(accessToken),
    );
  }

  static Future<http.Response> rejectWithdrawalRequest({
    required String accessToken,
    required int withdrawalId,
    required String reasonCancel,
  }) async {
    final url = Uri.parse(
      "$baseUrl/adminapi/withdrawal/reject/$withdrawalId",
    );

    return await http.post(
      url,
      headers: _getHeaders(accessToken),
      body: jsonEncode({
        "reasonCancel": reasonCancel,
      }),
    );
  }

  // ================= PROVINCE =================

  static Future<http.Response> getRideCountByProvince({
    required String accessToken,
  }) async {
    final url = Uri.parse("$baseUrl/provinceapi/active");

    return await http.get(
      url,
      headers: _getHeaders(accessToken),
    );
  }

  static Future<http.Response> getRideCountByDistrict({
    required String accessToken,
    required int provinceId,
  }) async {
    final url = Uri.parse("$baseUrl/provinceapi/district/$provinceId");

    return await http.get(
      url,
      headers: _getHeaders(accessToken),
    );
  }
}