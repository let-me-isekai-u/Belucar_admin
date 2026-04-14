import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher_statistic_model.dart';
import '../models/ride_count_models.dart';
import '../models/admin_ride_lookup_model.dart';

class ApiService {
  static const String baseUrl = "https://belucar.com/api/adminapi";

  // Header chung cho các yêu cầu JSON
  static Map<String, String> _getHeaders(String? token) {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // 1. API ĐĂNG NHẬP (POST)
  static Future<http.Response> login({
    required String phone,
    required String password,
    String? deviceToken,
  }) async {
    final url = Uri.parse("$baseUrl/login");
    final body = jsonEncode({
      "phone": phone,
      "password": password,
      "deviceToken": deviceToken ?? "",
    });

    return await http.post(url, headers: _getHeaders(null), body: body);
  }

  // 2. API LẤY DANH SÁCH CHUYẾN CHƯA CÓ TÀI XẾ (Pending - Status 1)
  static Future<http.Response> getPendingRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse("$baseUrl/rides/pending?page=$page&pageSize=$pageSize");
    return await http.get(url, headers: _getHeaders(accessToken));
  }

  // 3. API LẤY DANH SÁCH CHUYẾN ĐÃ CÓ TÀI XẾ NHẬN (Accept - Status 2)
  static Future<http.Response> getAcceptedRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse("$baseUrl/rides/accept?page=$page&pageSize=$pageSize");
    return await http.get(url, headers: _getHeaders(accessToken));
  }

  // 4. API LẤY DANH SÁCH CHUYẾN ĐANG DI CHUYỂN (Process - Status 3)
  static Future<http.Response> getProcessingRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse("$baseUrl/rides/process?page=$page&pageSize=$pageSize");
    return await http.get(url, headers: _getHeaders(accessToken));
  }

  // 5. API LẤY DANH SÁCH CHUYẾN ĐÃ HOÀN THÀNH (Success - Status 4)
  static Future<http.Response> getCompletedRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse("$baseUrl/rides/success?page=$page&pageSize=$pageSize");
    return await http.get(url, headers: _getHeaders(accessToken));
  }

  // 6. API LẤY DANH SÁCH CHUYẾN ĐÃ HỦY (Cancel - Status 5)
  static Future<http.Response> getCanceledRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse("$baseUrl/rides/cancel?page=$page&pageSize=$pageSize");
    return await http.get(url, headers: _getHeaders(accessToken));
  }

  static Future<http.Response> getStatisticalDay({required String date}) async {
    // Nếu Postman của bạn không có chữ /api/, hãy xóa nó đi ở dưới
    final url = Uri.parse('https://belucar.com/api/adminapi/statistical-day?date=$date');
    return await http.get(url);
  }

  // 9. Thống kê theo tháng (Không Token)
  static Future<http.Response> getStatisticalMonth({required int month, required int year}) async {
    final url = Uri.parse('https://belucar.com/api/adminapi/statistical-month?month=$month&year=$year');
    return await http.get(url);
  }

  // 10. Thống kê theo năm (Không Token)
  static Future<http.Response> getStatisticalYear({required int year}) async {
    final url = Uri.parse('https://belucar.com/api/adminapi/statistical-year?year=$year');
    return await http.get(url);
  }

  // 12. Lấy danh sách các yêu cầu rút tiền (KẾ TOÁN)
  static Future<http.Response> getWithdrawalRequest({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse("https://belucar.com/api/adminapi/withdrawals?page=$page&pageSize=$pageSize");
    return await http.get(url, headers: _getHeaders(accessToken));
  }

  //13. Lấy lịch sử duyệt rút tiền
  static Future<http.Response> getWithdrawalConfirmHistory({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse("https://belucar.com/api/adminapi/withdrawal/history?page=$page&pageSize=$pageSize");
    return await http.get(url, headers: _getHeaders(accessToken));
  }

  //14. Xác nhận yêu cầu rút tiền
  static Future<http.Response> acceptWithdrawalRequest({
    required String accessToken,
    required int withdrawalId,
  }) async {
    final url = Uri.parse(
      "https://belucar.com/api/adminapi/withdrawal/accept/$withdrawalId",
    );

    return await http.post(
      url,
      headers: _getHeaders(accessToken),
    );
  }

  // 15. Từ chối yêu cầu rút tiền
  static Future<http.Response> rejectWithdrawalRequest({
    required String accessToken,
    required int withdrawalId,
    required String reasonCancel,
  }) async {
    final url = Uri.parse(
      "https://belucar.com/api/adminapi/withdrawal/reject/$withdrawalId",
    );

    return await http.post(
      url,
      headers: _getHeaders(accessToken),
      body: jsonEncode({
        "reasonCancel": reasonCancel,
      }),
    );
  }

  //lấy danh sách voucher Tết được dùng
  static Future<List<VoucherStatisticModel>> getVoucherStatistics() async {
    const url = 'https://belucar.com/api/adminapi/voucher-statistics';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return (body['data'] as List)
          .map((e) => VoucherStatisticModel.fromJson(e))
          .toList();
    } else {
      throw Exception(
        'Lỗi :${response.statusCode}',
      );
    }
  }

  // lấy danh sách tỉnh/thành
  static Future<List<ProvinceRideCountDto>> getRideCountByProvince(String token) async {
    final url = Uri.parse("https://belucar.com/api/provinceapi/active");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.body.trim().isEmpty) {
        print("⚠️ getRideCountByProvince empty body");
        return [];
      }

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data is List) {
        return data
            .map((e) => ProvinceRideCountDto.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      print("⚠️ getRideCountByProvince fail: ${res.statusCode} - ${res.body}");
      return [];
    } catch (e) {
      print("🔥 getRideCountByProvince ERROR: $e");
      return [];
    }
  }

// lấy danh sách quận/huyện theo tỉnh
  static Future<List<DistrictRideCountDto>> getRideCountByDistrict(
      String token,
      int provinceId,
      ) async {
    final url = Uri.parse(
      "https://belucar.com/api/provinceapi/district/$provinceId",
    );

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.body.trim().isEmpty) {
        print("⚠️ getRideCountByDistrict empty body");
        return [];
      }

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data is List) {
        return data
            .map((e) => DistrictRideCountDto.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      print("⚠️ getRideCountByDistrict fail: ${res.statusCode} - ${res.body}");
      return [];
    } catch (e) {
      print("🔥 getRideCountByDistrict ERROR: $e");
      return [];
    }
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

    if (response.body.trim().isEmpty) return [];

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => AdminRideLookupModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
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

    if (response.body.trim().isEmpty) return [];

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => AdminRideLookupModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return [];
  }

}