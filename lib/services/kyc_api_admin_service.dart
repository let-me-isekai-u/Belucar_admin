import 'dart:convert';

import 'package:http/http.dart' as http;

class KycApiAdminService {
  static const String baseUrl = 'https://xeghepdongduong.com/api/admin';
  static const String _brokerRidesPath = '$baseUrl/broker-rides';

  static Map<String, String> _headers(String token) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> getPendingApprovalBrokerRides({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
  }) {
    final uri = Uri.parse(
      '$_brokerRidesPath/pending-approval?page=$page&pageSize=$pageSize',
    );
    return http.get(uri, headers: _headers(accessToken));
  }

  static Future<http.Response> getBrokerRideDetail({
    required String accessToken,
    required int brokerRideId,
  }) {
    final uri = Uri.parse('$_brokerRidesPath/$brokerRideId');
    return http.get(uri, headers: _headers(accessToken));
  }

  static Future<http.Response> approveBrokerRide({
    required String accessToken,
    required int brokerRideId,
  }) {
    final uri = Uri.parse('$_brokerRidesPath/$brokerRideId/approve');
    return http.post(uri, headers: _headers(accessToken));
  }

  static Future<http.Response> rejectBrokerRide({
    required String accessToken,
    required int brokerRideId,
    required String reason,
  }) {
    final uri = Uri.parse('$_brokerRidesPath/$brokerRideId/reject');
    return http.post(
      uri,
      headers: _headers(accessToken),
      body: jsonEncode(<String, dynamic>{'reason': reason.trim()}),
    );
  }

  static String extractErrorMessage(
    http.Response response, {
    String fallback = 'Có lỗi xảy ra, vui lòng thử lại.',
  }) {
    if (response.body.trim().isEmpty) {
      return fallback;
    }

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return fallback;
      }

      final directMessage = _firstNonEmptyString(<dynamic>[
        decoded['message'],
        decoded['error'],
        decoded['title'],
      ]);
      if (directMessage != null) {
        return directMessage;
      }

      final dynamic data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final dataMessage = _firstNonEmptyString(<dynamic>[
          data['message'],
          data['error'],
          data['title'],
        ]);
        if (dataMessage != null) {
          return dataMessage;
        }
      }

      final dynamic errors = decoded['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }
    } catch (_) {
      return fallback;
    }

    return fallback;
  }

  static String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}
