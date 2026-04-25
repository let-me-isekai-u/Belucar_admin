import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/firebase_notification_service.dart';
import 'home_screen.dart';

import 'accountant/withdrawal_confirm_screen.dart';
import 'broker_rides/broker_ride_approval_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Lấy FCM Token thực tế từ Firebase
      String? fcmToken = await FirebaseNotificationService.getDeviceToken();
      debugPrint("🚀 FCM Token gửi lên server: $fcmToken");

      // 3. Gọi API Login với token thật (nếu fcmToken null thì gửi chuỗi rỗng)
      final response = await ApiService.login(
        phone: phone,
        password: password,
        deviceToken: fcmToken ?? "",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int role = data['role'] ?? 1;

        // Lưu thông tin vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['accessToken'] ?? '');
        await prefs.setString('fullName', data['fullName'] ?? '');
        await prefs.setInt('userId', data['id'] ?? 0);
        await prefs.setInt('role', role);

        // Lưu cả fcmToken vào máy nếu bạn cần dùng sau này (tùy chọn)
        if (fcmToken != null) {
          await prefs.setString('fcmToken', fcmToken);
        }

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => role == 2
                ? const WithdrawalConfirmList()
                : role == 3
                ? const BrokerRideApprovalListScreen()
                : const HomeScreen(),
          ),
          (route) => false,
        );
      } else {
        // Có thể backend trả về lỗi cụ thể trong body, bạn có thể decode để hiện chính xác hơn
        _showSnackBar("Số điện thoại hoặc mật khẩu không đúng", Colors.red);
      }
    } catch (e) {
      debugPrint("🔥 Lỗi đăng nhập: $e");
      _showSnackBar("Đã xảy ra lỗi kết nối", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... Các hàm _showSnackBar và build giữ nguyên ...
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  "Belucar Admin",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Số điện thoại",
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "ĐĂNG NHẬP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
