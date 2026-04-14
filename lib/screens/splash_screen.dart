import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'accountant/withdrawal_confirm_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Cấu hình thời gian hiển thị tối thiểu giống bên User
  static const Duration _minDisplayDuration = Duration(seconds: 3);
  late final DateTime _splashStart;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _splashStart = DateTime.now(); // Ghi lại thời điểm bắt đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  // Hàm đảm bảo splash hiện đủ thời gian mới chuyển màn
  Future<void> _ensureMinDisplay() async {
    final elapsed = DateTime.now().difference(_splashStart);
    if (elapsed < _minDisplayDuration) {
      await Future.delayed(_minDisplayDuration - elapsed);
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final int role = prefs.getInt('role') ?? 1;

    // 1. Không có token -> Đợi đủ thời gian rồi về Login
    if (accessToken == null || accessToken.isEmpty) {
      await _ensureMinDisplay();
      _goLogin();
      return;
    }

    // 2. Có token -> Verify bằng API
    try {
      final res = await ApiService.getPendingRides(
        accessToken: accessToken,
        page: 1,
        pageSize: 1,
      );

      if (!mounted || _navigated) return;

      if (res.statusCode == 200) {
        // Token hợp lệ -> Đợi đủ thời gian rồi điều hướng theo Role
        await _ensureMinDisplay();
        _goHomeByRole(role);
        return;
      } else {
        // Token hết hạn
        await _clearToken();
      }
    } catch (_) {
      // Lỗi kết nối
    }

    // Mặc định nếu có lỗi hoặc token hỏng thì về Login
    await _ensureMinDisplay();
    _goLogin();
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('role');
  }

  void _goHomeByRole(int role) {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => role == 2
            ? const WithdrawalConfirmList() // Kế toán
            : const HomeScreen(),           // Admin
      ),
    );
  }

  void _goLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng ảnh asset toàn màn hình giống User
      body: SizedBox.expand(
        child: Image.asset(
          'lib/assets/belucar_summer_splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}