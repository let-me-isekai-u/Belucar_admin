import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/admin_ride_lookup_model.dart';
import '../models/voucher_statistic_model.dart';

class ApiService {
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

  static Future<http.Response> refreshToken({
    required String refreshToken,
  }) async {
    final url = Uri.parse("$baseUrl/adminapi/refresh-token");

    return await http.post(
      url,
      headers: _getHeaders(null),
      body: jsonEncode({
        "refreshToken": refreshToken,
      }),
    );
  }

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

  static Future<http.Response> getRideDetail({
    required String accessToken,
    required int rideId,
    required int rideSource,
  }) async {
    final url = Uri.parse("$baseUrl/AdminApi/rides/$rideId/$rideSource");

    return await http.get(
      url,
      headers: _getHeaders(accessToken),
    );
  }

  static Future<List<AdminRideLookupModel>> getPendingRideItems({
    required String accessToken,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await getPendingRides(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Không thể tải danh sách chuyến pending: ${response.statusCode}",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((item) => AdminRideLookupModel.fromJson(item))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];

      if (data is List) {
        return data
            .map((item) => AdminRideLookupModel.fromJson(item))
            .toList();
      }

      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List)
            .map((item) => AdminRideLookupModel.fromJson(item))
            .toList();
      }

      if (decoded['items'] is List) {
        return (decoded['items'] as List)
            .map((item) => AdminRideLookupModel.fromJson(item))
            .toList();
      }
    }

    return [];
  }

  static Future<List<AdminRideLookupModel>> getCanceledRideItems({
    required String accessToken,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await getCanceledRides(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Không thể tải danh sách chuyến đã hủy: ${response.statusCode}",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((item) => AdminRideLookupModel.fromJson(item))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];

      if (data is List) {
        return data
            .map((item) => AdminRideLookupModel.fromJson(item))
            .toList();
      }

      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List)
            .map((item) => AdminRideLookupModel.fromJson(item))
            .toList();
      }

      if (decoded['items'] is List) {
        return (decoded['items'] as List)
            .map((item) => AdminRideLookupModel.fromJson(item))
            .toList();
      }
    }

    return [];
  }

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

  static Future<List<VoucherStatisticModel>> getVoucherStatistics({
    required String accessToken,
  }) async {
    final url = Uri.parse("$baseUrl/adminapi/voucher-statistics");

    final response = await http.get(
      url,
      headers: _getHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Không thể tải thống kê voucher: ${response.statusCode}",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((item) => VoucherStatisticModel.fromJson(item))
          .toList();
    }

    if (decoded is List) {
      return decoded
          .map((item) => VoucherStatisticModel.fromJson(item))
          .toList();
    }

    throw Exception("Dữ liệu voucher không hợp lệ");
  }

  static Future<http.Response> testAdminNotification({
    required String accessToken,
    required int adminId,
  }) async {
    final url = Uri.parse("$baseUrl/testnotiapi/admin/$adminId");

    return await http.post(
      url,
      headers: _getHeaders(accessToken),
    );
  }

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